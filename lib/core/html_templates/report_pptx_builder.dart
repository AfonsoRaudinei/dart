import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../utils/app_logger.dart';
import 'report_photo_links.dart';
import 'relatorio_html_renderer.dart';

const _slidePhotoMaxDimension = 1024;

/// Máximo de fotos incluídas no `.pptx`; as demais são descartadas.
@visibleForTesting
const int kPptxMaxPhotos = 40;

/// Teto da soma dos JPEGs (bytes) incluídos no `.pptx`.
@visibleForTesting
const int kPptxMaxMediaBytes = 25 * 1024 * 1024;

/// Estimativa conservadora de caracteres por linha (corpo a 20 pt, 9").
@visibleForTesting
const int kPptxCharsPerLine = 60;

/// Linhas de corpo por slide (caixa de 5" a 20 pt).
@visibleForTesting
const int kPptxSlideBodyMaxLines = 12;

/// Teto de caracteres de corpo por slide de texto.
@visibleForTesting
const int kPptxSlideBodyMaxChars = kPptxCharsPerLine * kPptxSlideBodyMaxLines;

// Geometria dos slides (EMU). Slide 4:3 = 9144000 x 6858000.
const int _slideMarginX = 457200;
const int _titleY = 274320;
const int _titleHeight = 914400;
const int _bodyY = 1371600;
const int _bodyHeight = 4572000;
const int _contentWidth = 8229600;
const int _pictureAreaY = _bodyY;
const int _pictureAreaHeight = 6858000 - _bodyY - _slideMarginX;

/// 96 dpi: nunca exibir a imagem maior que seu tamanho natural.
const int _emuPerPixel = 9525;

/// Fallback para logo que não decodifica (quadrado, sem distorcer).
const int _fallbackLogoSide = 2743200;

/// JPEG já reduzido (nunca ampliado) com suas dimensões reais em pixels.
class _SlideImage {
  const _SlideImage({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Top-level para rodar em isolate via `compute`.
///
/// Devolve `null` se os bytes não são uma imagem decodificável — nunca bytes
/// crus rotulados como JPEG. Só reduz quando `max(w, h) > 1024`.
_SlideImage? _compressForSlide(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final oriented = img.bakeOrientation(decoded);
  final longest = oriented.width >= oriented.height
      ? oriented.width
      : oriented.height;
  final output = longest > _slidePhotoMaxDimension
      ? img.copyResize(
          oriented,
          width: oriented.width >= oriented.height
              ? _slidePhotoMaxDimension
              : null,
          height: oriented.height > oriented.width
              ? _slidePhotoMaxDimension
              : null,
          interpolation: img.Interpolation.average,
        )
      : oriented;
  final jpg = Uint8List.fromList(img.encodeJpg(output, quality: 78));
  return _SlideImage(bytes: jpg, width: output.width, height: output.height);
}

/// Gera `.pptx` (OOXML) a partir do HTML editorial de relatório.
class ReportPptxBuilder {
  const ReportPptxBuilder();

  static const _slideMime =
      'application/vnd.openxmlformats-officedocument.presentationml.slide+xml';
  static const _relsMime =
      'application/vnd.openxmlformats-package.relationships+xml';

  Future<Uint8List> build({
    required String reportTitle,
    required String html,
  }) async {
    final coverTitle = _stripTags(
      _extractFirstGroup(
            html,
            RegExp(
              r'<h1[^>]*class="sf-title"[^>]*>([\s\S]*?)</h1>',
              caseSensitive: false,
            ),
          ) ??
          reportTitle,
    );
    final coverContext = _stripTags(
      _extractFirstGroup(
            html,
            RegExp(
              r'<p[^>]*class="sf-subtitle"[^>]*>([\s\S]*?)</p>',
              caseSensitive: false,
            ),
          ) ??
          '',
    );

    final sections = _parseSections(html);
    final photos = ReportPhotoLinks.extractPhotos(html);
    final logo = await _loadLogo();

    final textSlides = <_SlideBody>[
      _SlideBody(
        title: coverTitle,
        paragraphs: coverContext.isEmpty ? const [] : [coverContext],
      ),
    ];

    for (final section in sections) {
      if (section.paragraphs.isEmpty) continue;
      final pages = _paginate(section.paragraphs);
      for (var i = 0; i < pages.length; i++) {
        textSlides.add(
          _SlideBody(
            title: i == 0
                ? section.title
                : '${section.title} (${i + 1}/${pages.length})',
            paragraphs: pages[i],
          ),
        );
      }
    }

    final photoSlides = <_SlideBody>[];
    var mediaBytes = 0;
    var limitReached = false;
    var droppedByLimit = 0;
    for (final photo in photos) {
      final image = await _photoBytes(photo);
      if (image == null || image.bytes.isEmpty) continue;
      if (!limitReached &&
          (photoSlides.length >= kPptxMaxPhotos ||
              mediaBytes + image.bytes.length > kPptxMaxMediaBytes)) {
        limitReached = true;
      }
      if (limitReached) {
        droppedByLimit++;
        continue;
      }
      mediaBytes += image.bytes.length;
      photoSlides.add(
        _SlideBody(
          title: photo.caption ?? 'Foto ${photo.index + 1}',
          image: image,
          imageExt: 'jpeg',
        ),
      );
    }

    if (droppedByLimit > 0) {
      AppLogger.warning(
        'PPTX: $droppedByLimit foto(s) fora do arquivo '
        '(limite: $kPptxMaxPhotos fotos / $kPptxMaxMediaBytes bytes)',
        tag: 'ReportPptxBuilder',
      );
      final notice = droppedByLimit == 1
          ? '+1 foto não incluída (limite do arquivo)'
          : '+$droppedByLimit fotos não incluídas (limite do arquivo)';
      final last = textSlides.last;
      if (_linesOf(last.paragraphs) + 1 <= kPptxSlideBodyMaxLines) {
        textSlides[textSlides.length - 1] = _SlideBody(
          title: last.title,
          paragraphs: [...last.paragraphs, notice],
        );
      } else {
        textSlides.add(_SlideBody(title: 'Fotos', paragraphs: [notice]));
      }
    }

    return _packArchive([
      ...textSlides,
      ...photoSlides,
      _SlideBody(title: 'SoloForte', image: logo, imageExt: 'png'),
    ]);
  }

  static int _linesOf(List<String> paragraphs) {
    var lines = 0;
    for (final p in paragraphs) {
      lines += (p.length + kPptxCharsPerLine - 1) ~/ kPptxCharsPerLine;
    }
    return lines;
  }

  /// Divide parágrafos em páginas dentro do orçamento de linhas; parágrafo
  /// maior que o teto é quebrado por palavra.
  List<List<String>> _paginate(List<String> paragraphs) {
    final pages = <List<String>>[];
    var current = <String>[];
    var currentLines = 0;
    for (final paragraph in paragraphs) {
      for (final piece in _splitParagraph(paragraph)) {
        final lines = _linesOf([piece]);
        if (current.isNotEmpty &&
            currentLines + lines > kPptxSlideBodyMaxLines) {
          pages.add(current);
          current = <String>[];
          currentLines = 0;
        }
        current.add(piece);
        currentLines += lines;
      }
    }
    if (current.isNotEmpty) pages.add(current);
    return pages;
  }

  List<String> _splitParagraph(String paragraph) {
    if (paragraph.length <= kPptxSlideBodyMaxChars) return [paragraph];
    final pieces = <String>[];
    var buffer = StringBuffer();
    var length = 0;
    void flush() {
      if (length > 0) pieces.add(buffer.toString());
      buffer = StringBuffer();
      length = 0;
    }

    for (var word in paragraph.split(' ')) {
      if (word.isEmpty) continue;
      // Palavra sozinha maior que o teto (ex.: URL): quebra por caractere.
      while (word.length > kPptxSlideBodyMaxChars) {
        flush();
        pieces.add(word.substring(0, kPptxSlideBodyMaxChars));
        word = word.substring(kPptxSlideBodyMaxChars);
      }
      final extra = length == 0 ? word.length : word.length + 1;
      if (length + extra > kPptxSlideBodyMaxChars) flush();
      if (length > 0) buffer.write(' ');
      buffer.write(word);
      length += length == 0 ? word.length : word.length + 1;
    }
    flush();
    return pieces;
  }

  Future<_SlideImage?> _photoBytes(ReportPhoto photo) async {
    try {
      Uint8List? raw;
      if (photo.isDataUri) {
        raw = photo.decodeBytes();
      } else if (photo.isNetwork) {
        final inlined = await RelatorioHtmlRenderer.resolvePhotoSrcForExport(
          photo.src,
        );
        if (!inlined.startsWith('data:image/')) return null;
        raw = UriData.parse(inlined).contentAsBytes();
      }
      if (raw == null || raw.isEmpty) return null;
      final image = await compute(_compressForSlide, raw);
      if (image == null) {
        AppLogger.warning(
          'PPTX: foto ${photo.index + 1} ignorada (formato não decodificável)',
          tag: 'ReportPptxBuilder',
        );
      }
      return image;
    } catch (e, st) {
      AppLogger.warning(
        'PPTX: foto ${photo.index + 1} ignorada (dados inválidos)\n$st',
        tag: 'ReportPptxBuilder',
        error: e,
      );
    }
    return null;
  }

  Future<_SlideImage> _loadLogo() async {
    final data = await rootBundle.load(
      RelatorioHtmlRenderer.soloForteLogoAsset,
    );
    final bytes = data.buffer.asUint8List();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return _SlideImage(bytes: bytes, width: 0, height: 0);
    }
    return _SlideImage(
      bytes: bytes,
      width: decoded.width,
      height: decoded.height,
    );
  }

  Uint8List _packArchive(List<_SlideBody> slides) {
    final archive = Archive();
    final media = <int, _MediaEntry>{};
    var mediaIndex = 1;

    for (var i = 0; i < slides.length; i++) {
      final slide = slides[i];
      if (slide.image != null) {
        final ext = slide.imageExt ?? 'jpeg';
        final name = 'image$mediaIndex.$ext';
        media[i + 1] = _MediaEntry(name: name, bytes: slide.image!.bytes);
        mediaIndex++;
      }
    }

    void addUtf8(String name, String xml) {
      archive.addFile(ArchiveFile.bytes(name, utf8.encode(xml)));
    }

    addUtf8(
      '[Content_Types].xml',
      _contentTypesXml(slides.length, media.isNotEmpty),
    );
    addUtf8('_rels/.rels', _packageRelsXml());
    addUtf8('docProps/core.xml', _corePropsXml());
    addUtf8('docProps/app.xml', _appPropsXml(slides.length));
    addUtf8('ppt/presentation.xml', _presentationXml(slides.length));
    addUtf8(
      'ppt/_rels/presentation.xml.rels',
      _presentationRelsXml(slides.length),
    );
    addUtf8('ppt/presProps.xml', _presPropsXml());
    addUtf8('ppt/viewProps.xml', _viewPropsXml());
    addUtf8('ppt/tableStyles.xml', _tableStylesXml());
    addUtf8('ppt/slideMasters/slideMaster1.xml', _slideMasterXml());
    addUtf8(
      'ppt/slideMasters/_rels/slideMaster1.xml.rels',
      _slideMasterRelsXml(),
    );
    addUtf8('ppt/slideLayouts/slideLayout1.xml', _slideLayoutXml());
    addUtf8(
      'ppt/slideLayouts/_rels/slideLayout1.xml.rels',
      _slideLayoutRelsXml(),
    );
    addUtf8('ppt/theme/theme1.xml', _themeXml());

    for (var i = 0; i < slides.length; i++) {
      final slideNum = i + 1;
      final slide = slides[i];
      final relMedia = media[slideNum];
      addUtf8(
        'ppt/slides/slide$slideNum.xml',
        _slideXml(slide, relMedia != null),
      );
      addUtf8(
        'ppt/slides/_rels/slide$slideNum.xml.rels',
        _slideRelsXml(relMedia?.name),
      );
    }

    for (final entry in media.values) {
      archive.addFile(
        ArchiveFile.bytes('ppt/media/${entry.name}', entry.bytes),
      );
    }

    final zip = ZipEncoder().encode(archive);
    return Uint8List.fromList(zip);
  }

  List<_HtmlSection> _parseSections(String html) {
    final pattern = RegExp(
      r'<h2[^>]*class="sf-section-title"[^>]*>(?:<span[^>]*>[\s\S]*?</span>)?([^<]*)</h2>([\s\S]*?)(?=<h2[^>]*class="sf-section-title"|</main>|$)',
      caseSensitive: false,
    );
    final list = <_HtmlSection>[];
    for (final match in pattern.allMatches(html)) {
      final title = _stripTags(match.group(1) ?? 'Seção');
      final raw = match.group(2) ?? '';
      final withoutFigures = raw.replaceAll(
        RegExp(r'<figure[\s\S]*?</figure>', caseSensitive: false),
        '',
      );
      final withoutImg = withoutFigures.replaceAll(
        RegExp(r'<img\b[^>]*>', caseSensitive: false),
        '',
      );
      list.add(
        _HtmlSection(title: title, paragraphs: _toParagraphs(withoutImg)),
      );
    }
    return list;
  }

  static final _blockBoundary = RegExp(
    r'</(?:p|div|li|tr|h[1-6]|ul|ol|table|section|blockquote)\s*>|<br\s*/?>',
    caseSensitive: false,
  );

  /// Quebra o HTML em parágrafos nas fronteiras de bloco (`</p>`, `<br>`…).
  List<String> _toParagraphs(String html) {
    final marked = html.replaceAll(_blockBoundary, '\n');
    final noTags = marked.replaceAll(RegExp(r'<[^>]+>'), ' ');
    return _decodeHtmlEntities(noTags)
        .split('\n')
        .map((p) => p.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  String? _extractFirstGroup(String html, RegExp pattern) {
    final match = pattern.firstMatch(html);
    return match?.group(1);
  }

  String _stripTags(String html) {
    final noTags = html.replaceAll(RegExp(r'<[^>]+>'), ' ');
    return _decodeHtmlEntities(noTags).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static final _entityPattern = RegExp(
    r'&(#[xX][0-9a-fA-F]+|#[0-9]+|amp|lt|gt|quot|apos|nbsp);',
  );

  /// Decodifica entidades HTML comuns em uma única passada (sem dupla
  /// decodificação); o escape XML acontece depois, em [_xmlEscape].
  String _decodeHtmlEntities(String text) {
    return text.replaceAllMapped(_entityPattern, (m) {
      final name = m.group(1)!;
      switch (name) {
        case 'amp':
          return '&';
        case 'lt':
          return '<';
        case 'gt':
          return '>';
        case 'quot':
          return '"';
        case 'apos':
          return "'";
        case 'nbsp':
          return ' ';
      }
      final isHex = name.startsWith('#x') || name.startsWith('#X');
      final code = int.tryParse(
        name.substring(isHex ? 2 : 1),
        radix: isHex ? 16 : 10,
      );
      if (code == null || !_isValidXmlCodePoint(code)) return '';
      return String.fromCharCode(code);
    });
  }

  bool _isValidXmlCodePoint(int c) {
    return c == 0x9 ||
        c == 0xA ||
        c == 0xD ||
        (c >= 0x20 && c <= 0xD7FF) ||
        (c >= 0xE000 && c <= 0xFFFD) ||
        (c >= 0x10000 && c <= 0x10FFFF);
  }

  /// Caracteres de controle ilegais em XML 1.0 (o PowerPoint pede "reparar").
  static final _illegalXmlChars = RegExp(
    r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\uFFFE\uFFFF]',
  );

  /// Todo texto que entra no XML passa por aqui.
  String _xmlEscape(String value) {
    return value
        .replaceAll(_illegalXmlChars, '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  String _contentTypesXml(int slideCount, bool hasMedia) {
    final overrides = StringBuffer()
      ..writeln(
        '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>',
      )
      ..writeln(
        '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>',
      )
      ..writeln(
        '<Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>',
      )
      ..writeln(
        '<Override PartName="/ppt/presProps.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presProps+xml"/>',
      )
      ..writeln(
        '<Override PartName="/ppt/viewProps.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.viewProps+xml"/>',
      )
      ..writeln(
        '<Override PartName="/ppt/tableStyles.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.tableStyles+xml"/>',
      )
      ..writeln(
        '<Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>',
      )
      ..writeln(
        '<Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>',
      )
      ..writeln(
        '<Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>',
      );
    for (var i = 1; i <= slideCount; i++) {
      overrides.writeln(
        '<Override PartName="/ppt/slides/slide$i.xml" ContentType="$_slideMime"/>',
      );
    }
    if (hasMedia) {
      overrides.writeln('<Default Extension="jpeg" ContentType="image/jpeg"/>');
      overrides.writeln('<Default Extension="png" ContentType="image/png"/>');
    }
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="$_relsMime"/>
<Default Extension="xml" ContentType="application/xml"/>
$overrides
</Types>''';
  }

  String _packageRelsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';
  }

  String _corePropsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<dc:title>SoloForte</dc:title>
<dc:creator>SoloForte</dc:creator>
</cp:coreProperties>''';
  }

  String _appPropsXml(int slideCount) {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
<Application>SoloForte</Application>
<Slides>$slideCount</Slides>
</Properties>''';
  }

  String _presentationXml(int slideCount) {
    final sldIds = StringBuffer();
    for (var i = 0; i < slideCount; i++) {
      sldIds.writeln('<p:sldId id="${256 + i}" r:id="rId${i + 2}"/>');
    }
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" saveSubsetFonts="1">
<p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>
<p:sldIdLst>
$sldIds
</p:sldIdLst>
<p:sldSz cx="9144000" cy="6858000" type="screen4x3"/>
<p:notesSz cx="6858000" cy="9144000"/>
</p:presentation>''';
  }

  String _presentationRelsXml(int slideCount) {
    final rels = StringBuffer()
      ..writeln(
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>',
      );
    for (var i = 0; i < slideCount; i++) {
      rels.writeln(
        '<Relationship Id="rId${i + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide${i + 1}.xml"/>',
      );
    }
    final base = slideCount + 2;
    rels
      ..writeln(
        '<Relationship Id="rId$base" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/presProps" Target="presProps.xml"/>',
      )
      ..writeln(
        '<Relationship Id="rId${base + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/viewProps" Target="viewProps.xml"/>',
      )
      ..writeln(
        '<Relationship Id="rId${base + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/tableStyles" Target="tableStyles.xml"/>',
      );
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
$rels
</Relationships>''';
  }

  String _slideMasterRelsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>
</Relationships>''';
  }

  String _slideMasterXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
<p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld>
<p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>
<p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rId1"/></p:sldLayoutIdLst>
<p:txStyles>
<p:titleStyle><a:lvl1pPr algn="ctr" rtl="0" eaLnBrk="1" latinLnBrk="0" hangingPunct="1"><a:defRPr sz="4400" kern="1200"><a:solidFill><a:schemeClr val="tx1"/></a:solidFill><a:latin typeface="+mj-lt"/><a:ea typeface="+mj-ea"/><a:cs typeface="+mj-cs"/></a:defRPr></a:lvl1pPr></p:titleStyle>
<p:bodyStyle><a:lvl1pPr marL="342900" marR="0" lvl="0" algn="l" defTabSz="914400" rtl="0" eaLnBrk="1" latinLnBrk="0" hangingPunct="1"><a:defRPr sz="3200" kern="1200"><a:solidFill><a:schemeClr val="tx1"/></a:solidFill><a:latin typeface="+mn-lt"/><a:ea typeface="+mn-ea"/><a:cs typeface="+mn-cs"/></a:defRPr></a:lvl1pPr></p:bodyStyle>
<p:otherStyle><a:defPPr lvl="0" algn="l"/><a:lvl1pPr marL="342900" marR="0" lvl="0" algn="l" defTabSz="914400" rtl="0" eaLnBrk="1" latinLnBrk="0" hangingPunct="1"><a:defRPr sz="1800" kern="1200"><a:solidFill><a:schemeClr val="tx1"/></a:solidFill><a:latin typeface="+mn-lt"/><a:ea typeface="+mn-ea"/><a:cs typeface="+mn-cs"/></a:defRPr></a:lvl1pPr></p:otherStyle>
</p:txStyles>
</p:sldMaster>''';
  }

  String _presPropsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:presentationPr xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
<p:showPr loop="0" showNarration="0" showAnimation="1" useTimings="1"/>
</p:presentationPr>''';
  }

  String _viewPropsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:viewPr xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
<p:normalViewPr>
<p:restoredLeft sz="15620"/>
<p:restoredTop sz="94660"/>
</p:normalViewPr>
<p:slideViewPr>
<p:cSldViewPr>
<p:cViewPr var="1"/>
<p:guideLst/>
</p:cSldViewPr>
</p:slideViewPr>
<p:notesTextViewPr/>
<p:gridSpacing cx="78028800" cy="78028800"/>
</p:viewPr>''';
  }

  String _tableStylesXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:tblStyleLst xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" def="{5C22544A-7BC6-43B2-948B-7B34887676DD}"/>''';
  }

  String _slideLayoutRelsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>
</Relationships>''';
  }

  String _slideLayoutXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" type="title" preserve="1">
<p:cSld name="Title"><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld>
<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sldLayout>''';
  }

  String _themeXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="SoloForte">
<a:themeElements>
<a:clrScheme name="SoloForte"><a:dk1><a:sysClr val="windowText" lastClr="000000"/></a:dk1><a:lt1><a:sysClr val="window" lastClr="FFFFFF"/></a:lt1><a:dk2><a:srgbClr val="2C5564"/></a:dk2><a:lt2><a:srgbClr val="F5F5F7"/></a:lt2><a:accent1><a:srgbClr val="1428A0"/></a:accent1><a:accent2><a:srgbClr val="2C5564"/></a:accent2><a:accent3><a:srgbClr val="059669"/></a:accent3><a:accent4><a:srgbClr val="E8A317"/></a:accent4><a:accent5><a:srgbClr val="D93025"/></a:accent5><a:accent6><a:srgbClr val="6E6E73"/></a:accent6><a:hlink><a:srgbClr val="1428A0"/></a:hlink><a:folHlink><a:srgbClr val="2C5564"/></a:folHlink></a:clrScheme>
<a:fontScheme name="SoloForte"><a:majorFont><a:latin typeface="Calibri Light"/></a:majorFont><a:minorFont><a:latin typeface="Calibri"/></a:minorFont></a:fontScheme>
<a:fmtScheme name="SoloForte"><a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:gradFill rotWithShape="1"><a:gsLst><a:gs pos="0"><a:schemeClr val="phClr"><a:tint val="50000"/></a:schemeClr></a:gs><a:gs pos="100000"><a:schemeClr val="phClr"><a:shade val="10000"/></a:schemeClr></a:gs></a:gsLst><a:lin ang="5400000" scaled="0"/></a:gradFill></a:fillStyleLst><a:lnStyleLst><a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln><a:ln w="25400"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln><a:ln w="38100"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln></a:lnStyleLst><a:effectStyleLst><a:effectStyle><a:effectLst><a:outerShdw blurRad="40000" dist="20000" dir="5400000" rotWithShape="0"><a:srgbClr val="000000"><a:alpha val="38000"/></a:srgbClr></a:outerShdw></a:effectLst></a:effectStyle><a:effectStyle><a:effectLst><a:outerShdw blurRad="40000" dist="23000" dir="5400000" rotWithShape="0"><a:srgbClr val="000000"><a:alpha val="35000"/></a:srgbClr></a:outerShdw></a:effectLst></a:effectStyle><a:effectStyle><a:effectLst><a:outerShdw blurRad="40000" dist="23000" dir="5400000" rotWithShape="0"><a:srgbClr val="000000"><a:alpha val="35000"/></a:srgbClr></a:outerShdw></a:effectLst><a:scene3d><a:camera prst="orthographicFront"/><a:lightRig rig="threePt" dir="t"><a:rot lat="0" lon="0" rev="1200000"/></a:lightRig></a:scene3d><a:sp3d extrusionH="25400" contourW="12700" prstMaterial="plastic"/></a:effectStyle></a:effectStyleLst><a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:gradFill rotWithShape="1"><a:gsLst><a:gs pos="0"><a:schemeClr val="phClr"><a:tint val="40000"/></a:schemeClr></a:gs><a:gs pos="50000"><a:schemeClr val="phClr"><a:shade val="99000"/></a:schemeClr></a:gs><a:gs pos="100000"><a:schemeClr val="phClr"><a:shade val="20000"/></a:schemeClr></a:gs></a:gsLst><a:path path="circle"><a:fillToRect l="50000" t="-80000" r="50000" b="180000"/></a:path></a:gradFill><a:blipFill rotWithShape="1"><a:blip/><a:tile tx="0" ty="0" sx="100000" sy="100000" flip="none" algn="tl"/></a:blipFill></a:bgFillStyleLst></a:fmtScheme>
</a:themeElements>
</a:theme>''';
  }

  String _slideRelsXml(String? mediaName) {
    final rels = StringBuffer()
      ..writeln(
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>',
      );
    if (mediaName != null) {
      rels.writeln(
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/$mediaName"/>',
      );
    }
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
$rels
</Relationships>''';
  }

  String _slideXml(_SlideBody slide, bool hasImage) {
    final titleShape = _textShape(
      id: 2,
      x: _slideMarginX,
      y: _titleY,
      cx: _contentWidth,
      cy: _titleHeight,
      paragraphs: [slide.title],
      bold: true,
      size: 2800,
    );
    final bodyShape = slide.paragraphs.isEmpty
        ? ''
        : _textShape(
            id: 3,
            x: _slideMarginX,
            y: _bodyY,
            cx: _contentWidth,
            cy: _bodyHeight,
            paragraphs: slide.paragraphs,
            bold: false,
            size: 2000,
          );
    final imageShape = hasImage && slide.image != null
        ? _pictureShape(id: 4, rId: 'rId2', image: slide.image!)
        : '';
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
<p:cSld><p:spTree>
<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/>
$titleShape
$bodyShape
$imageShape
</p:spTree></p:cSld>
</p:sld>''';
  }

  String _textShape({
    required int id,
    required int x,
    required int y,
    required int cx,
    required int cy,
    required List<String> paragraphs,
    required bool bold,
    required int size,
  }) {
    final runs = StringBuffer();
    for (final paragraph in paragraphs) {
      runs.writeln(
        '<a:p><a:r><a:rPr lang="pt-BR" sz="$size" b="${bold ? 1 : 0}"/><a:t>${_xmlEscape(paragraph)}</a:t></a:r></a:p>',
      );
    }
    return '''<p:sp>
<p:nvSpPr><p:cNvPr id="$id" name="Text $id"/><p:cNvSpPr txBox="1"/><p:nvPr/></p:nvSpPr>
<p:spPr><a:xfrm><a:off x="$x" y="$y"/><a:ext cx="$cx" cy="$cy"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr>
<p:txBody><a:bodyPr wrap="square" rtlCol="0"><a:normAutofit/></a:bodyPr><a:lstStyle/>
$runs</p:txBody>
</p:sp>''';
  }

  /// Ajusta a imagem à área útil (sem distorcer, sem ampliar além do tamanho
  /// natural a 96 dpi) e centraliza.
  String _pictureShape({
    required int id,
    required String rId,
    required _SlideImage image,
  }) {
    final int cx;
    final int cy;
    if (image.width <= 0 || image.height <= 0) {
      cx = _fallbackLogoSide;
      cy = _fallbackLogoSide;
    } else {
      final fit = [
        _contentWidth / image.width,
        _pictureAreaHeight / image.height,
        _emuPerPixel.toDouble(),
      ].reduce((a, b) => a < b ? a : b);
      cx = (image.width * fit).round().clamp(1, _contentWidth);
      cy = (image.height * fit).round().clamp(1, _pictureAreaHeight);
    }
    final x = _slideMarginX + (_contentWidth - cx) ~/ 2;
    final y = _pictureAreaY + (_pictureAreaHeight - cy) ~/ 2;
    return '''<p:pic>
<p:nvPicPr><p:cNvPr id="$id" name="Picture $id"/><p:cNvPicPr/><p:nvPr/></p:nvPicPr>
<p:blipFill><a:blip r:embed="$rId"/><a:stretch><a:fillRect/></a:stretch></p:blipFill>
<p:spPr><a:xfrm><a:off x="$x" y="$y"/><a:ext cx="$cx" cy="$cy"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr>
</p:pic>''';
  }
}

class _SlideBody {
  const _SlideBody({
    required this.title,
    this.paragraphs = const [],
    this.image,
    this.imageExt,
  });

  final String title;
  final List<String> paragraphs;
  final _SlideImage? image;
  final String? imageExt;
}

class _HtmlSection {
  const _HtmlSection({required this.title, required this.paragraphs});

  final String title;
  final List<String> paragraphs;
}

class _MediaEntry {
  const _MediaEntry({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}
