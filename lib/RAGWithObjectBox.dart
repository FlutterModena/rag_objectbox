import 'dart:math';

import 'package:objectbox/objectbox.dart' as objectbox;
import 'package:langchain/langchain.dart';
import 'package:langchain_community/langchain_community.dart';
import 'package:langchain_ollama/langchain_ollama.dart';

import './DirectoryLoader.dart';
import './MyObjectBoxVectorStore.dart';

Iterable<List<T>> splitListInChunks<T>(List<T> list, int chunkSize) sync* {
  for (int i = 0; i < list.length; i += chunkSize) {
    yield list.sublist(i, min(i + chunkSize, list.length));
  }
}

// Conversational RAG:
// - https://python.langchain.com/docs/tutorials/qa_chat_history/

class RAGWithObjectBox {
  final String docsDir;
  final String dbDir;
  late DirectoryLoader _documentLoader;
  late Embeddings _embeddings;
  late MyObjectBoxVectorStore
      _objectBox; // Custom class for ObjectBoxVectorStore (exposing store variable)
  late VectorStoreRetriever _retriever;
  late ChatOllama _llm;

  late RunnableSequence<Map<String, dynamic>, List<Document>>
      _historyAwareRetrieverChain;
  late RunnableSequence<Map<String, dynamic>, String> _qaChain;
  late RunnableSequence<Map<String, dynamic>, String> _ragChain;

  RAGWithObjectBox._({required this.docsDir, required this.dbDir}) {
    print("[RAGWithObjectBox] Documents directory: $docsDir");
    print("[RAGWithObjectBox] DB directory: $dbDir");

    _documentLoader = DirectoryLoader(docsDir);

    // Initialize the embeddings model
    print("[RAGWithObjectBox] Initializing the embeddings model...");
    _embeddings = OllamaEmbeddings(model: "mxbai-embed-large");

    // Initialize the LLM model
    print("[RAGWithObjectBox] Initializing the LLM model...");
    _llm =
        ChatOllama(defaultOptions: const ChatOllamaOptions(model: "phi3:14b"));

    // Initialize ObjectBox (the vector store)
    print("[RAGWithObjectBox] Initializing ObjectBox...");
    _objectBox = MyObjectBoxVectorStore(
        embeddings: _embeddings,
        dimensions:
            512, // The dimension of OllamaEmbeddings (model mxbai-embed-large)
        directory: dbDir);
    _retriever = VectorStoreRetriever(vectorStore: _objectBox);
  }

  /// Tell whether documents shall be loaded from disk and stored in ObjectBox.
  bool _shouldStoreDocuments() {
    objectbox.Box<ObjectBoxDocument> box =
        MyObjectBoxVectorStore.store!.box<ObjectBoxDocument>();
    int numDocuments = box.count();
    if (numDocuments > 0) {
      print("[RAGWithObjectBox] DB found with $numDocuments documents");
      return false;
    } else {
      return true;
    }
  }

  Future<void> _loadAndStoreDocuments() async {
    print("[RAGWithObjectBox] Storing documents in the Vector DB...");

    objectbox.Box<ObjectBoxDocument> box =
        MyObjectBoxVectorStore.store!.box<ObjectBoxDocument>();
    int numRemoved = box.removeAll();
    if (numRemoved > 0) {
      print(
          "[RAGWithObjectBox] Cleared $numRemoved previously inserted documents...");
    }

    // Load the documents from the dataset directory
    List<Document> documents = await _documentLoader.load();
    print("[RAGWithObjectBox] ${documents.length} documents loaded");

    // Split the documents into smaller chunks to better fit the model's context
    TextSplitter textSplitter = const RecursiveCharacterTextSplitter(
        chunkSize: 2000, chunkOverlap: 200);
    documents = textSplitter.splitDocuments(documents);
    print(
        "[RAGWithObjectBox] ${documents.length} documents generated after splitting");

    // Store the splits in ObjectBox
    print(
        "[RAGWithObjectBox] Embedding and storing documents (might take a while)...");

    const int chunkSize = 100;
    int numAdded = 0;
    Stopwatch stopwatch = Stopwatch()..start();
    for (final chunk in splitListInChunks(documents, chunkSize)) {
      await _objectBox.addDocuments(documents: chunk);
      numAdded += chunkSize;
      double elapsedSeconds = stopwatch.elapsedMilliseconds.toDouble() / 1000.0;
      print(
          "[RAGWithObjectBox] Added $numAdded/${documents.length} in ${elapsedSeconds.toStringAsFixed(1)}s");
      stopwatch.reset();
    }
  }

  /// Input: chat_history, input
  _setupHistoryAwareRetrieverChain() {
    const promptText = """Given a chat history and the latest user question
which might reference context in the chat history,
formulate a standalone question which can be understood
without the chat history. Do NOT answer the question,
just reformulate it if needed and otherwise return it as is.
""";
    final prompt = ChatPromptTemplate.fromPromptMessages([
      ChatMessagePromptTemplate.system(promptText),
      ChatMessagePromptTemplate.messagesPlaceholder("chat_history"),
      ChatMessagePromptTemplate.human(
        "input",
      )
    ]);
    const outputParser = StringOutputParser<ChatResult>();
    _historyAwareRetrieverChain =
        prompt.pipe(_llm).pipe(outputParser).pipe(_retriever);
  }

  /// Input: chat_history, input, context
  _setupQAChain() {
    const promptText = """You are an assistant for question-answering tasks.
Use the following pieces of retrieved context to answer
the question. If you don't know the answer, say that you
don't know. Use three sentences maximum and keep the
"answer concise.

{context}
""";
    final prompt = ChatPromptTemplate.fromPromptMessages([
      ChatMessagePromptTemplate.system(promptText),
      ChatMessagePromptTemplate.messagesPlaceholder("chat_history"),
      ChatMessagePromptTemplate.human("{input}")
    ]);
    const outputParser = StringOutputParser<ChatResult>();
    _qaChain = prompt.pipe(_llm).pipe(outputParser);
  }

  /// Input: chat_history, input
  _setupChain() {
    final historyAwareRetriever = Runnable.fromMap<Map<String, dynamic>>({
      'context': _historyAwareRetrieverChain.pipe(Runnable.mapInput(
          (List<Document> docs) =>
              docs.map((document) => document.pageContent).join("\n"))),
      'chat_history': Runnable.getItemFromMap('chat_history'),
      'input': Runnable.getItemFromMap('input')
    });
    _ragChain = historyAwareRetriever.pipe(_qaChain);
  }

  Future<String> invoke(String input, List<ChatMessage> chatHistory) async {
    String output =
        await _ragChain.invoke({'chat_history': chatHistory, 'input': input});
    chatHistory.add(ChatMessage.humanText(input));
    chatHistory.add(ChatMessage.ai(output));
    return output;
  }

  static Future<RAGWithObjectBox> create(
      {required String docsDir, required String dbDir}) async {
    RAGWithObjectBox instance =
        RAGWithObjectBox._(docsDir: docsDir, dbDir: dbDir);
    if (instance._shouldStoreDocuments()) {
      await instance._loadAndStoreDocuments();
    }
    instance._setupHistoryAwareRetrieverChain();
    instance._setupQAChain();
    instance._setupChain();
    return instance;
  }
}
