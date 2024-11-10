import './RAGWithObjectBox.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_community/langchain_community.dart';
import 'package:langchain_ollama/langchain_ollama.dart';

// RAG with langchain:
// - https://python.langchain.com/docs/tutorials/rag/
// - https://pub.dev/packages/langchain

void main() async {
  runApp(
    MaterialApp(
      theme: ThemeData(),
      home: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  RAGWithObjectBox? ragWithObjectBox;
  bool loading = false;
  List<ChatMessage> history = [];

  void initRAG() async {
    ragWithObjectBox =
        await RAGWithObjectBox.create(docsDir: "./data", dbDir: "./obx-db");
    setState(() {});
  }

  void sendMessage(String msg) async {
    ragWithObjectBox!.invoke(msg, history).then(
          (_) => setState(
            () {
              loading = false;
              _scrollController.jumpTo(_scrollController.positions.last.pixels);
            },
          ),
        );
    setState(() {
      loading = true;
      _scrollController.jumpTo(_scrollController.positions.last.pixels);
    });
  }

  @override
  void initState() {
    super.initState();
    initRAG();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF1b1815),
        appBar: PreferredSize(
          preferredSize: Size(MediaQuery.of(context).size.width, 200.0),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 1.0, color: Color(0xFF333333)),
              ),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundImage: NetworkImage(
                    "https://static.wikia.nocookie.net/starwars/images/c/cc/Star-wars-logo-new-tall.jpg/revision/latest?cb=20190313021755"),
              ),
              title: const Text(
                "Star Wars Expert",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: loading
                  ? const Text(
                      "typing...",
                      style: TextStyle(color: Colors.white60),
                    )
                  : ragWithObjectBox != null
                      ? const Text(
                          "online",
                          style: TextStyle(color: Colors.white60),
                        )
                      : null,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  reverse: true,
                  controller: _scrollController,
                  children: [
                    for (var message in history.reversed)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            if (message is HumanChatMessage)
                              const Spacer(
                                flex: 3,
                              ),
                            Expanded(
                              flex: 2,
                              child: ChatBubble(message.contentAsString,
                                  message is AIChatMessage),
                            ),
                            if (message is AIChatMessage)
                              const Spacer(
                                flex: 3,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Write your Message",
                        hintStyle: TextStyle(
                          color: Color(0xFF919191),
                        ),
                      ),
                      onSubmitted: (msg) {
                        sendMessage(msg);
                        _textController.clear();
                      },
                    ),
                  ),
                  IconButton(
                    color: const Color(0xFF919191),
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      sendMessage(_textController.text);
                      _textController.clear();
                    },
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble(this.text, this.ai, {super.key});

  final String text;
  final bool ai;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: ai
                ? [const Color(0xFF17a6a6), const Color(0xFF006e70)]
                : [const Color(0xFF4b4b4b), const Color(0xFF4b4b4b)]),
        border: Border.all(color: Colors.black, width: 2.0),
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodyMedium!
            .copyWith(color: Colors.white),
      ),
    );
  }
}
