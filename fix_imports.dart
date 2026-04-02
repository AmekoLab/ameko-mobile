import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('lib directory not found');
    return;
  }

  libDir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      fixImports(entity);
    }
  });
}

void fixImports(File file) {
  final lines = file.readAsLinesSync();
  bool modified = false;
  final newLines = <String>[];

  // Calculate current file depth relative to lib
  final relativePath = file.path.replaceFirst('lib${Platform.pathSeparator}', '');
  final parts = relativePath.split(Platform.pathSeparator);
  // ignore the filename itself
  final depth = parts.length - 1;

  for (var line in lines) {
    if (line.trim().startsWith('import ') || line.trim().startsWith('export ')) {
      final match = RegExp(r'''(import|export)\s+['"](\.\.?\/[^'"]+)['"]''').firstMatch(line);
      if (match != null) {
        final type = match.group(1);
        final path = match.group(2)!;
        
        final absolutePath = resolvePath(file.path, path);
        if (absolutePath != null) {
          final packageImport = 'package:ameko_app/${absolutePath.replaceFirst('lib/', '').replaceAll('\\', '/')}';
          line = line.replaceFirst(path, packageImport);
          modified = true;
        }
      }
    }
    newLines.add(line);
  }

  if (modified) {
    file.writeAsStringSync(newLines.join('\n') + '\n');
    print('Fixed imports in: ${file.path}');
  }
}

String? resolvePath(String currentFilePath, String relativePath) {
  final currentDir = File(currentFilePath).parent.path;
  final segments = relativePath.split('/');
  final dirSegments = currentDir.split(Platform.pathSeparator);

  for (final segment in segments) {
    if (segment == '.') {
      continue;
    } else if (segment == '..') {
      if (dirSegments.isNotEmpty) {
        dirSegments.removeLast();
      }
    } else {
      dirSegments.add(segment);
    }
  }

  final resolved = dirSegments.join('/');
  // Find where 'lib' starts
  final libIndex = resolved.indexOf('/lib/');
  if (libIndex != -1) {
      return resolved.substring(libIndex + 1);
  }
  // Try backslash
  final libIndexWin = resolved.indexOf('\\lib\\');
  if (libIndexWin != -1) {
       return resolved.substring(libIndexWin + 1).replaceAll('\\', '/');
  }
  
  // If it's just 'lib/...'
  if (resolved.startsWith('lib/')) return resolved;

  return null;
}
