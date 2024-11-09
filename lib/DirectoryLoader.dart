import 'dart:io';
import 'package:path/path.dart';
import 'package:langchain_core/document_loaders.dart';
import 'package:langchain_core/documents.dart';

/// A document loader that loads [Document] from a directory.
class DirectoryLoader extends BaseDocumentLoader {
  final String directoryPath;

  const DirectoryLoader(this.directoryPath);

  Document _loadFile(File file) {
    final fileName = basename(file.path);
    final fileSize = file.lengthSync();
    final fileLastModified = file.lastModifiedSync();
    final fileContent = file.readAsStringSync();

    return Document(
      pageContent: fileContent,
      metadata: {
        'source': file.path,
        'name': fileName,
        'size': fileSize,
        'lastModified': fileLastModified.millisecondsSinceEpoch,
      },
    );
  }

  @override
  Stream<Document> lazyLoad() async* {
    Directory directory = Directory(directoryPath);
    yield* directory.list().where((file) {
      return file is File;
    }).map((file) {
      return _loadFile(file as File);
    });
  }
}
