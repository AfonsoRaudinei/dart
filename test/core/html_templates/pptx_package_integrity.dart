import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

const _relsNs =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

/// Resultado da auditoria estrutural de um pacote PPTX (OOXML / OPC).
class PptxPackageAuditResult {
  PptxPackageAuditResult({
    this.partsWithoutContentType = const [],
    this.orphanRelationships = const [],
    this.brokenEmbeds = const [],
    this.malformedXml = const [],
    this.duplicateShapeIds = const [],
  });

  final List<String> partsWithoutContentType;
  final List<String> orphanRelationships;
  final List<String> brokenEmbeds;
  final List<String> malformedXml;
  final List<String> duplicateShapeIds;

  bool get isOk =>
      partsWithoutContentType.isEmpty &&
      orphanRelationships.isEmpty &&
      brokenEmbeds.isEmpty &&
      malformedXml.isEmpty &&
      duplicateShapeIds.isEmpty;

  String get summary {
    final buf = StringBuffer();
    if (partsWithoutContentType.isNotEmpty) {
      buf.writeln(
        'Partes sem content type (${partsWithoutContentType.length}):',
      );
      for (final p in partsWithoutContentType) {
        buf.writeln('  - $p');
      }
    }
    if (orphanRelationships.isNotEmpty) {
      buf.writeln(
        'Relacionamentos órfãos (${orphanRelationships.length}):',
      );
      for (final r in orphanRelationships) {
        buf.writeln('  - $r');
      }
    }
    if (brokenEmbeds.isNotEmpty) {
      buf.writeln('r:embed inválidos (${brokenEmbeds.length}):');
      for (final e in brokenEmbeds) {
        buf.writeln('  - $e');
      }
    }
    if (malformedXml.isNotEmpty) {
      buf.writeln('XML mal-formado (${malformedXml.length}):');
      for (final m in malformedXml) {
        buf.writeln('  - $m');
      }
    }
    if (duplicateShapeIds.isNotEmpty) {
      buf.writeln(
        'Ids duplicados em spTree (${duplicateShapeIds.length}):',
      );
      for (final d in duplicateShapeIds) {
        buf.writeln('  - $d');
      }
    }
    return buf.toString().trim();
  }
}

/// Lê entradas do ZIP pelos cabeçalhos locais (não confia só no `archive`).
class ZipLocalEntry {
  ZipLocalEntry({
    required this.name,
    required this.uncompressedSizeInHeader,
    required this.compressedSizeInHeader,
    required this.data,
    required this.compressionMethod,
  });

  final String name;
  final int uncompressedSizeInHeader;
  final int compressedSizeInHeader;
  final Uint8List data;
  final int compressionMethod;
}

List<ZipLocalEntry> parseZipLocalHeaders(Uint8List zipBytes) {
  const localSig = 0x04034b50;
  final entries = <ZipLocalEntry>[];
  var offset = 0;
  while (offset + 30 <= zipBytes.length) {
    final sig = ByteData.sublistView(
      zipBytes,
      offset,
      offset + 4,
    ).getUint32(0, Endian.little);
    if (sig != localSig) break;
    final view = ByteData.sublistView(zipBytes, offset);
    final compressionMethod = view.getUint16(8, Endian.little);
    final compressedSize = view.getUint32(18, Endian.little);
    final uncompressedSize = view.getUint32(22, Endian.little);
    final nameLen = view.getUint16(26, Endian.little);
    final extraLen = view.getUint16(28, Endian.little);
    final nameStart = offset + 30;
    final nameEnd = nameStart + nameLen;
    if (nameEnd > zipBytes.length) break;
    final name = utf8.decode(zipBytes.sublist(nameStart, nameEnd));
    final dataStart = nameEnd + extraLen;
    final dataEnd = dataStart + compressedSize;
    if (dataEnd > zipBytes.length) break;
    final data = Uint8List.fromList(zipBytes.sublist(dataStart, dataEnd));
    entries.add(
      ZipLocalEntry(
        name: name,
        uncompressedSizeInHeader: uncompressedSize,
        compressedSizeInHeader: compressedSize,
        data: data,
        compressionMethod: compressionMethod,
      ),
    );
    offset = dataEnd;
  }
  return entries;
}

Set<String> _archivePartNames(Archive archive) {
  return archive.files
      .where((f) => f.isFile && !f.name.endsWith('/'))
      .map((f) => f.name.replaceAll('\\', '/'))
      .toSet();
}

String? _readUtf8(Archive archive, String name) {
  final matches = archive.files.where((f) => f.name == name);
  if (matches.isEmpty) return null;
  return utf8.decode(matches.first.content as List<int>);
}

String _extensionLower(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) return '';
  return path.substring(dot + 1).toLowerCase();
}

/// Resolve `Target` relativo ao diretório da parte dona do `.rels`.
String resolveOoxmlPartPath(String ownerPartDir, String target) {
  final normalizedTarget = target.replaceAll('\\', '/');
  if (normalizedTarget.startsWith('/')) {
    return normalizedTarget.substring(1);
  }
  final base =
      ownerPartDir.isEmpty
          ? <String>[]
          : ownerPartDir.split('/').where((s) => s.isNotEmpty).toList();
  final out = [...base];
  for (final seg in normalizedTarget.split('/')) {
    if (seg.isEmpty || seg == '.') continue;
    if (seg == '..') {
      if (out.isEmpty) {
        throw ArgumentError('path sobe acima da raiz: $target');
      }
      out.removeLast();
    } else {
      out.add(seg);
    }
  }
  return out.join('/');
}

/// Dono do `.rels` e diretório base para resolver targets.
({String ownerPart, String ownerDir}) _relsOwner(String relsPath) {
  final normalized = relsPath.replaceAll('\\', '/');
  if (normalized == '_rels/.rels') {
    return (ownerPart: '', ownerDir: '');
  }
  final m = RegExp(r'^(.*)/_rels/([^/]+)\.rels$').firstMatch(normalized);
  if (m == null) {
    return (ownerPart: normalized, ownerDir: _dirName(normalized));
  }
  final dir = m.group(1)!;
  final partFile = m.group(2)!;
  final owner = dir.isEmpty ? partFile : '$dir/$partFile';
  return (ownerPart: owner, ownerDir: _dirName(owner));
}

String _dirName(String partPath) {
  final i = partPath.lastIndexOf('/');
  if (i < 0) return '';
  return partPath.substring(0, i);
}

String _relsPathForPart(String partPath) {
  final dir = _dirName(partPath);
  final base = partPath.substring(partPath.lastIndexOf('/') + 1);
  if (dir.isEmpty) {
    return '_rels/$base.rels';
  }
  return '$dir/_rels/$base.rels';
}

bool _isImageRelationshipType(String? type) {
  if (type == null) return false;
  return type == '$_relsNs/image' || type.endsWith('/relationships/image');
}

Map<String, String> _loadContentTypeIndex(String contentTypesXml) {
  final doc = XmlDocument.parse(contentTypesXml);
  final overrides = <String, String>{};
  for (final el in doc.findAllElements('Override')) {
    final part = el.getAttribute('PartName');
    final ct = el.getAttribute('ContentType');
    if (part != null && ct != null) {
      overrides[part] = ct;
    }
  }
  final defaults = <String, String>{};
  for (final el in doc.findAllElements('Default')) {
    final ext = el.getAttribute('Extension');
    final ct = el.getAttribute('ContentType');
    if (ext != null && ct != null) {
      defaults[ext.toLowerCase()] = ct;
    }
  }
  return {
    for (final e in overrides.entries) 'override:${e.key}': e.value,
    for (final e in defaults.entries) 'default:${e.key}': e.value,
  };
}

String? _contentTypeForPart(
  String partName,
  Map<String, String> rawIndex,
) {
  final overrideKey = 'override:/$partName';
  if (rawIndex.containsKey(overrideKey)) {
    return rawIndex[overrideKey];
  }
  final ext = _extensionLower(partName);
  if (ext.isEmpty) return null;
  return rawIndex['default:$ext'];
}

List<String> _auditContentTypes(
  Archive archive,
  Set<String> partNames,
  Map<String, String> ctIndex,
) {
  final missing = <String>[];
  for (final name in partNames) {
    if (_contentTypeForPart(name, ctIndex) == null) {
      missing.add(name);
    }
  }
  missing.sort();
  return missing;
}

List<String> _auditRelationships(
  Archive archive,
  Set<String> partNames,
) {
  final orphans = <String>[];
  final relsFiles =
      partNames.where((n) => n.endsWith('.rels')).toList()..sort();
  for (final relsPath in relsFiles) {
    final text = _readUtf8(archive, relsPath);
    if (text == null) continue;
    XmlDocument doc;
    try {
      doc = XmlDocument.parse(text);
    } on Object catch (e) {
      orphans.add('$relsPath: não parseável ($e)');
      continue;
    }
    final owner = _relsOwner(relsPath);
    for (final rel in doc.findAllElements('Relationship')) {
      final targetMode = rel.getAttribute('TargetMode');
      if (targetMode == 'External') continue;
      final target = rel.getAttribute('Target');
      final id = rel.getAttribute('Id') ?? '?';
      if (target == null) {
        orphans.add('$relsPath Id=$id: Target ausente');
        continue;
      }
      String resolved;
      try {
        resolved = resolveOoxmlPartPath(owner.ownerDir, target);
      } on Object catch (e) {
        orphans.add('$relsPath Id=$id: $e');
        continue;
      }
      if (!partNames.contains(resolved)) {
        orphans.add(
          '$relsPath Id=$id → $resolved (ausente no ZIP; target="$target")',
        );
      }
    }
  }
  return orphans;
}

String? _relationshipEmbedId(XmlElement node) {
  for (final attr in node.attributes) {
    if (attr.name.local == 'embed' &&
        attr.name.namespaceUri == _relsNs &&
        attr.value.isNotEmpty) {
      return attr.value;
    }
  }
  final prefixed = node.getAttribute('r:embed');
  if (prefixed != null && prefixed.isNotEmpty) return prefixed;
  return null;
}

List<String> _collectEmbedIds(XmlDocument doc) {
  final ids = <String>[];
  void walk(XmlNode node) {
    if (node is XmlElement) {
      final embed = _relationshipEmbedId(node);
      if (embed != null) {
        ids.add(embed);
      }
      for (final child in node.children) {
        walk(child);
      }
    }
  }
  walk(doc.rootElement);
  return ids;
}

List<String> _auditEmbeds(Archive archive, Set<String> partNames) {
  final broken = <String>[];
  final xmlParts =
      partNames
          .where(
            (n) =>
                n.endsWith('.xml') &&
                (n.startsWith('ppt/slides/') ||
                    n.startsWith('ppt/slideLayouts/') ||
                    n.startsWith('ppt/slideMasters/') ||
                    n.startsWith('ppt/notesSlides/') ||
                    n.startsWith('ppt/notesMasters/')),
          )
          .toList()
        ..sort();

  for (final partPath in xmlParts) {
    final text = _readUtf8(archive, partPath);
    if (text == null) continue;
    XmlDocument doc;
    try {
      doc = XmlDocument.parse(text);
    } on Object catch (e) {
      broken.add('$partPath: XML inválido ($e)');
      continue;
    }
    final embedIds = _collectEmbedIds(doc);
    if (embedIds.isEmpty) continue;

    final relsPath = _relsPathForPart(partPath);
    final relsText = _readUtf8(archive, relsPath);
    if (relsText == null) {
      for (final id in embedIds) {
        broken.add(
          '$partPath r:embed="$id": $relsPath ausente',
        );
      }
      continue;
    }
    XmlDocument relsDoc;
    try {
      relsDoc = XmlDocument.parse(relsText);
    } on Object catch (e) {
      for (final embedId in embedIds) {
        broken.add('$relsPath: não parseável ($e) [r:embed="$embedId"]');
      }
      continue;
    }
    final relsById = {
      for (final rel in relsDoc.findAllElements('Relationship'))
        if (rel.getAttribute('Id') != null) rel.getAttribute('Id')!: rel,
    };
    final ownerDir = _dirName(partPath);

    for (final embedId in embedIds) {
      final rel = relsById[embedId];
      if (rel == null) {
        broken.add('$partPath r:embed="$embedId": Id ausente em $relsPath');
        continue;
      }
      final type = rel.getAttribute('Type');
      if (!_isImageRelationshipType(type)) {
        broken.add(
          '$partPath r:embed="$embedId": Type não é imagem ($type)',
        );
        continue;
      }
      final target = rel.getAttribute('Target');
      if (target == null) {
        broken.add('$partPath r:embed="$embedId": Target ausente');
        continue;
      }
      if (rel.getAttribute('TargetMode') == 'External') {
        broken.add('$partPath r:embed="$embedId": TargetMode External');
        continue;
      }
      String resolved;
      try {
        resolved = resolveOoxmlPartPath(ownerDir, target);
      } on Object catch (e) {
        broken.add('$partPath r:embed="$embedId": $e');
        continue;
      }
      if (!partNames.contains(resolved)) {
        broken.add(
          '$partPath r:embed="$embedId" → $resolved (ausente no ZIP)',
        );
        continue;
      }
      if (!resolved.startsWith('ppt/media/')) {
        broken.add(
          '$partPath r:embed="$embedId" → $resolved (fora de ppt/media/)',
        );
      }
    }
  }
  return broken;
}

List<String> _auditWellFormedXml(Archive archive, Set<String> partNames) {
  final bad = <String>[];
  final targets =
      partNames.where((n) => n.endsWith('.xml') || n.endsWith('.rels')).toList()
        ..sort();
  for (final name in targets) {
    final text = _readUtf8(archive, name);
    if (text == null) continue;
    try {
      XmlDocument.parse(text);
    } on Object catch (e) {
      bad.add('$name: $e');
    }
  }
  return bad;
}

List<String> _auditUniqueShapeIds(Archive archive, Set<String> partNames) {
  final dups = <String>[];
  final spTreeParts =
      partNames
          .where(
            (n) =>
                n.endsWith('.xml') &&
                (n.startsWith('ppt/slides/') ||
                    n.startsWith('ppt/slideLayouts/') ||
                    n.startsWith('ppt/slideMasters/')),
          )
          .toList()
        ..sort();

  for (final partPath in spTreeParts) {
    final text = _readUtf8(archive, partPath);
    if (text == null) continue;
    XmlDocument doc;
    try {
      doc = XmlDocument.parse(text);
    } on Object {
      continue;
    }
    if (doc.findAllElements('p:spTree').isEmpty) continue;

    final seen = <String, int>{};
    void collectId(String? id) {
      if (id == null || id.isEmpty) return;
      seen[id] = (seen[id] ?? 0) + 1;
    }

    for (final spTree in doc.findAllElements('p:spTree')) {
      for (final cnv in spTree.findAllElements('p:cNvPr')) {
        collectId(cnv.getAttribute('id'));
      }
      for (final grp in spTree.findAllElements('p:cNvGrpSpPr')) {
        collectId(grp.getAttribute('id'));
      }
    }

    final duplicated = seen.entries.where((e) => e.value > 1).map((e) => e.key);
    for (final id in duplicated) {
      dups.add('$partPath: id="$id" repetido ${seen[id]}× no mesmo spTree');
    }
  }
  return dups;
}

/// Auditoria completa de integridade OOXML do pacote PPTX.
PptxPackageAuditResult auditPptxPackage(Archive archive) {
  final partNames = _archivePartNames(archive);
  final ctXml = _readUtf8(archive, '[Content_Types].xml');
  if (ctXml == null) {
    return PptxPackageAuditResult(
      malformedXml: ['[Content_Types].xml ausente'],
    );
  }

  Map<String, String> ctIndex;
  try {
    ctIndex = _loadContentTypeIndex(ctXml);
  } on Object catch (e) {
    return PptxPackageAuditResult(
      malformedXml: ['[Content_Types].xml: $e'],
    );
  }

  return PptxPackageAuditResult(
    partsWithoutContentType: _auditContentTypes(archive, partNames, ctIndex),
    orphanRelationships: _auditRelationships(archive, partNames),
    brokenEmbeds: _auditEmbeds(archive, partNames),
    malformedXml: _auditWellFormedXml(archive, partNames),
    duplicateShapeIds: _auditUniqueShapeIds(archive, partNames),
  );
}

/// Falha o teste com mensagem agregada se o pacote não passar na auditoria.
void assertPptxPackageIntegrity(Archive archive) {
  final result = auditPptxPackage(archive);
  if (!result.isOk) {
    fail(result.summary);
  }
}