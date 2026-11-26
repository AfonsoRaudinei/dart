import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../utils/app_logger.dart';
import 'report_photo_links.dart';
import 'relatorio_html_renderer.dart';

const _slidePhotoMaxDimension = 1024;

/// Top-level para rodar em isolate via `compute`.
Uint8List? _compressForSlide(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final oriented = img.bakeOrientation(decoded);
  final resized = img.copyResize(
    oriented,
    width: oriented.width >= oriented.height ? _slidePhotoMaxDimension : null,
    height: oriented.height > oriented.width ? _slidePhotoMaxDimension : null,
    interpolation: img.Interpolation.average,
  );
  return Uint8List.fromList(img.encodeJpg(resized, quality: 78));
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
    final logoBytes = await _loadLogoBytes();

    final slideBodies = <_SlideBody>[];
    slideBodies.add(
      _SlideBody(
        kind: _SlideKind.cover,
        title: coverTitle,
        body: coverContext,
      ),
    );

    for (final section in sections) {
      final text = section.bodyText.trim();
      if (text.isEmpty && section.title.toLowerCase().contains('fotográf')) {
        continue;
      }
      if (text.isEmpty) continue;
      slideBodies.add(
        _SlideBody(
          kind: _SlideKind.section,
          title: section.title,
          body: text,
        ),
      );
    }

    for (final photo in photos) {
      final bytes = await _photoBytes(photo);
      if (bytes == null || bytes.isEmpty) continue;
      slideBodies.add(
        _SlideBody(
          kind: _SlideKind.photo,
          title: photo.caption ?? 'Foto ${photo.index + 1}',
          imageBytes: bytes,
          imageExt: 'jpeg',
        ),
      );
    }

    slideBodies.add(
      _SlideBody(
        kind: _SlideKind.brand,
        title: 'SoloForte',
        imageBytes: logoBytes,
        imageExt: 'png',
      ),
    );

    return _packArchive(slideBodies);
  }

  Future<Uint8List?> _photoBytes(ReportPhoto photo) async {
    try {
      if (photo.isDataUri) {
        final raw = photo.decodeBytes();
        if (raw == null) return null;
        return await compute(_compressForSlide, raw);
      }
      if (photo.isNetwork) {
        final inlined = await RelatorioHtmlRenderer.resolvePhotoSrcForExport(
          photo.src,
        );
        if (!inlined.startsWith('data:image/')) return null;
        final raw = UriData.parse(inlined).contentAsBytes();
        return await compute(_compressForSlide, raw);
      }
    } catch (e) {
      AppLogger.warning(
        'PPTX: foto ${photo.index + 1} ignorada (dados inválidos)',
        tag: 'ReportPptxBuilder',
        error: e,
      );
    }
    return null;
  }

  Future<Uint8List> _loadLogoBytes() async {
    final data = await rootBundle.load(RelatorioHtmlRenderer.soloForteLogoAsset);
    return data.buffer.asUint8List();
  }

  Uint8List _packArchive(List<_SlideBody> slides) {
    final archive = Archive();
    final media = <int, _MediaEntry>{};
    var mediaIndex = 1;

    for (var i = 0; i < slides.length; i++) {
      final slide = slides[i];
      if (slide.imageBytes != null) {
        final ext = slide.imageExt ?? 'jpeg';
        final name = 'image$mediaIndex.$ext';
        media[i + 1] = _MediaEntry(name: name, bytes: slide.imageBytes!);
        mediaIndex++;
      }
    }

    archive.addFile(
      ArchiveFile(
        '[Content_Types].xml',
        0,
        utf8.encode(_contentTypesXml(slides.length, media.isNotEmpty)),
      ),
    );
    archive.addFile(
      ArchiveFile(
        '_rels/.rels',
        0,
        utf8.encode(_packageRelsXml()),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'docProps/core.xml',
        0,
        utf8.encode(_corePropsXml()),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'docProps/app.xml',
        0,
        utf8.encode(_appPropsXml(slides.length)),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'ppt/presentation.xml',
        0,
        utf8.encode(_presentationXml(slides.length)),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'ppt/_rels/presentation.xml.rels',
        0,
        utf8.encode(_presentationRelsXml(slides.length)),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'ppt/slideMasters/slideMaster1.xml',
        0,
        utf8.encode(_slideMasterXml()),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'ppt/slideMasters/_rels/slideMaster1.xml.rels',
        0,
        utf8.encode(_slideMasterRelsXml()),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'ppt/slideLayouts/slideLayout1.xml',
        0,
        utf8.encode(_slideLayoutXml()),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'ppt/slideLayouts/_rels/slideLayout1.xml.rels',
        0,
        utf8.encode(_slideLayoutRelsXml()),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'ppt/theme/theme1.xml',
        0,
        utf8.encode(_themeXml()),
      ),
    );

    for (var i = 0; i < slides.length; i++) {
      final slideNum = i + 1;
      final slide = slides[i];
      final relMedia = media[slideNum];
      archive.addFile(
        ArchiveFile(
          'ppt/slides/slide$slideNum.xml',
          0,
          utf8.encode(_slideXml(slide, relMedia != null)),
        ),
      );
      archive.addFile(
        ArchiveFile(
          'ppt/slides/_rels/slide$slideNum.xml.rels',
          0,
          utf8.encode(_slideRelsXml(slideNum, relMedia?.name)),
        ),
      );
    }

    for (final entry in media.values) {
      archive.addFile(
        ArchiveFile('ppt/media/${entry.name}', entry.bytes.length, entry.bytes),
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
      list.add(_HtmlSection(title: title, bodyText: _stripTags(withoutImg)));
    }
    return list;
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

  String _xmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  String _contentTypesXml(int slideCount, bool hasMedia) {
    final overrides = StringBuffer()
      ..writeln(
        '<Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>',
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
      overrides.writeln(
        '<Default Extension="jpeg" ContentType="image/jpeg"/>',
      );
      overrides.writeln(
        '<Default Extension="png" ContentType="image/png"/>',
      );
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
      sldIds.writeln(
        '<p:sldId id="${256 + i}" r:id="rId${i + 2}"/>',
      );
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
</p:sldMaster>''';
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
<a:fmtScheme name="SoloForte"><a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:fillStyleLst><a:lnStyleLst><a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln></a:lnStyleLst></a:fmtScheme>
</a:themeElements>
</a:theme>''';
  }

  String _slideRelsXml(int slideNum, String? mediaName) {
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
    final title = _xmlEscape(slide.title);
    final body = _xmlEscape(slide.body);
    final titleShape = _textShape(id: 2, x: 457200, y: 274320, cx: 8229600, cy: 914400, text: title, bold: true, size: 2800);
    final bodyShape = body.isEmpty
        ? ''
        : _textShape(id: 3, x: 457200, y: 1371600, cx: 8229600, cy: 4572000, text: body, bold: false, size: 2000);
    final imageShape = hasImage && slide.imageBytes != null
        ? _pictureShape(id: 4, rId: 'rId2')
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
    required String text,
    required bool bold,
    required int size,
  }) {
    return '''<p:sp>
<p:nvSpPr><p:cNvPr id="$id" name="Text $id"/><p:cNvSpPr txBox="1"/><p:nvPr/></p:nvSpPr>
<p:spPr><a:xfrm><a:off x="$x" y="$y"/><a:ext cx="$cx" cy="$cy"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr>
<p:txBody><a:bodyPr wrap="square" rtlCol="0"/><a:lstStyle/>
<a:p><a:r><a:rPr lang="pt-BR" sz="$size" b="${bold ? 1 : 0}"/><a:t>$text</a:t></a:r></a:p>
</p:txBody>
</p:sp>''';
  }

  String _pictureShape({required int id, required String rId}) {
    return '''<p:pic>
<p:nvPicPr><p:cNvPr id="$id" name="Picture $id"/><p:cNvPicPr/><p:nvPr/></p:nvPicPr>
<p:blipFill><a:blip r:embed="$rId"/><a:stretch><a:fillRect/></a:stretch></p:blipFill>
<p:spPr><a:xfrm><a:off x="1143000" y="1828800"/><a:ext cx="6858000" cy="4572000"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr>
</p:pic>''';
  }
}

enum _SlideKind { cover, section, photo, brand }

class _SlideBody {
  const _SlideBody({
    required this.kind,
    required this.title,
    this.body = '',
    this.imageBytes,
    this.imageExt,
  });

  final _SlideKind kind;
  final String title;
  final String body;
  final Uint8List? imageBytes;
  final String? imageExt;
}

class _HtmlSection {
  const _HtmlSection({required this.title, required this.bodyText});

  final String title;
  final String bodyText;
}

class _MediaEntry {
  const _MediaEntry({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}