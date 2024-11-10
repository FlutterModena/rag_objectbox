import 'dart:convert';

import 'package:langchain_core/documents.dart';
import 'package:objectbox/objectbox.dart';
import 'package:langchain_community/langchain_community.dart';
import 'objectbox.g.dart';

// We need to create a custom vector store for the following reasons:
// - have access to the underlying ObjectBox store
// - customize the HnswIndex distanceType to cosine
@Entity()
class MyDocumentEntity {
  MyDocumentEntity({
    required this.id,
    required this.content,
    required this.metadata,
    required this.embedding,
  });
  @Id()
  int internalId = 0;

  String id;

  String content;

  String metadata;

  // Embeddings configuration for Ollama's mxbai-embed-large
  @HnswIndex(
    dimensions: 1024,
    distanceType: VectorDistanceType.cosine,
  )
  @Property(type: PropertyType.floatVector)
  List<double> embedding;
  factory MyDocumentEntity.fromModel(
    Document doc,
    List<double> embedding,
  ) =>
      MyDocumentEntity(
        id: '',
        content: doc.pageContent,
        metadata: jsonEncode(doc.metadata),
        embedding: embedding,
      );

  Document toModel() => Document(
        id: id,
        pageContent: content,
        metadata: jsonDecode(metadata),
      );
}

class MyObjectBoxVectorStore
    extends BaseObjectBoxVectorStore<MyDocumentEntity> {
  MyObjectBoxVectorStore({
    required super.embeddings,
    required Store store,
  }) : super(
          box: store.box<MyDocumentEntity>(),
          createEntity: (
            String id,
            String content,
            String metadata,
            List<double> embedding,
          ) =>
              MyDocumentEntity(
            id: id,
            content: content,
            metadata: metadata,
            embedding: embedding,
          ),
          createDocument: (MyDocumentEntity docDto) => docDto.toModel(),
          getIdProperty: () => MyDocumentEntity_.id,
          getEmbeddingProperty: () => MyDocumentEntity_.embedding,
        );
}
