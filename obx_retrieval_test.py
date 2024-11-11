
from cmd import Cmd
from objectbox import Entity, Float32Vector, HnswIndex, Id, Store, String, VectorDistanceType
import ollama
import time
import csv
import os
import json

query_embeddings = ollama.embed(model='mxbai-embed-large', input='Talk me about the Third Republic of France? Who was Napoleone?')
query_embeddings = query_embeddings['embeddings'][0]
print("mxbai-embed-large embeddings length:", len(query_embeddings))

@Entity()
class MyDocumentEntity:
    internalId = Id()
    id = String()
    metadata = String()
    content = String()
    embedding = Float32Vector(index=HnswIndex(dimensions=1024, distance_type=VectorDistanceType.COSINE))


def _main():
    store = Store(directory="./obx-db", model_json_file="./lib/objectbox-model.json")
    box = store.box(MyDocumentEntity)
    print(f"DB size: {box.count()}")
    
    results = box.query(
        MyDocumentEntity.embedding.nearest_neighbor(query_embeddings, 5)
    ).build().find_with_scores()
    for i, (document, score) in enumerate(results):
        metadata = json.loads(document.metadata)
        print(f"{score:.3f} - {metadata['name']}")
        if i == 0:
            print(document.content)
    

if __name__ == '__main__':
    _main()
