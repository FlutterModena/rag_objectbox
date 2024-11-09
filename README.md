# Using ObjectBox to build a local RAG application

## Install OLLAMA (local LLM)

See instructions at https://ollama.com/download

```
ollama pull phi3
ollama pull znbang/bge:small-en-v1.5-f32
```

## Setup your flutter project

```
flutter pub add langchain
flutter pub add langchain_community
flutter pub add langchain_ollama
flutter pub add objectbox objectbox_flutter_libs:any
```
