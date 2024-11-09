import './RAGWithObjectBox.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_community/langchain_community.dart';
import 'package:langchain_ollama/langchain_ollama.dart';

// RAG with langchain:
// - https://python.langchain.com/docs/tutorials/rag/
// - https://pub.dev/packages/langchain

late RAGWithObjectBox ragWithObjectBox;

void main() async {
  ragWithObjectBox =
      await RAGWithObjectBox.create(docsDir: "./data", dbDir: "./obx-db");

  List<ChatMessage> chatHistory = [];
  String answer;

  answer = await ragWithObjectBox.invoke("Who is Luke Skywalker?", chatHistory);
  print(answer);
  answer = await ragWithObjectBox.invoke("Who was his sister?", chatHistory);
  print(answer);
  answer = await ragWithObjectBox.invoke("Did she die? When?", chatHistory);
  print(answer);

  print("Running the application...");
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  List<ChatMessage> history = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      body: Center(
        child: Column(children: <Widget>[
          const TextField(
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter a search query")),
          ElevatedButton(
              child: const Text('Submit'),
              onPressed: () {
                print("Submit!");
              })
        ]),
      ),
    ));
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Text(text),
    );
  }
}
