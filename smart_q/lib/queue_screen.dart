import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  // Connect to the WebSocket broadcast endpoint
  final WebSocketChannel channel = WebSocketChannel.connect(
    Uri.parse('ws://127.0.0.1:8000/ws/queue'),
  );

  List<dynamic> tokens = [];

  @override
  void initState() {
    super.initState();
    listenToQueueUpdates();
  }

  void listenToQueueUpdates() {
    channel.stream.listen((message) {
      final eventData = jsonDecode(message);
      // Automatically refresh token list or update state when an event occurs
      print("Real-time update received: ${eventData['event']}");
      setState(() {
        // Handle instant UI update
      });
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Queue Monitor')),
      body: const Center(child: Text('Listening for real-time changes...')),
    );
  }
}
















