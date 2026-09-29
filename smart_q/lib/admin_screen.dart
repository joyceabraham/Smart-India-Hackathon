import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final String baseUrl = 'https://dashboard.render.com/web/srv-datrv2g93c1s73bq6lug';
  WebSocketChannel? _channel;
  List<dynamic> tokens = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchTokens();
    initWebSocket();
  }

  // Fetch all tokens from FastAPI backend
  Future<void> fetchTokens() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tokens'));
      if (response.statusCode == 200) {
        setState(() {
          tokens = jsonDecode(response.body);
          isLoading = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to connect to backend: $e';
        isLoading = false;
      });
    }
  }

  // Connect to WebSocket for live updates when tokens are created or modified
  void initWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://127.0.0.1:8000/ws/queue'),
      );

      _channel!.stream.listen(
        (message) {
          debugPrint("Admin WS Event Received: $message");
          // Re-fetch tokens whenever any event is broadcasted
          fetchTokens();
        },
        onError: (error) {
          debugPrint("WebSocket Error: $error");
        },
        onDone: () {
          debugPrint("WebSocket Connection Closed");
        },
      );
    } catch (e) {
      debugPrint("WebSocket initialization failed: $e");
    }
  }

  // Call the next waiting token in line
  Future<void> callNextToken(String deptId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/queue/call-next/$deptId'),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Called next token successfully!')),
        );
        fetchTokens();
      } else {
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['detail'] ?? 'No waiting tokens.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calling next token: $e')),
      );
    }
  }

  // Mark an active token as served
  Future<void> updateTokenStatus(String tokenId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/tokens/$tokenId/status?status=$status'),
      );
      if (response.statusCode == 200) {
        fetchTokens();
      }
    } catch (e) {
      debugPrint('Error updating token status: $e');
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'serving':
        return Colors.green;
      case 'waiting':
        return Colors.orange;
      case 'completed':
      case 'served':
        return Colors.blue;
      case 'cancelled':
      case 'skipped':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin / Staff Management Portal'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Queue',
            onPressed: fetchTokens,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Action Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.indigo.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'General Enquiries (Counter 01)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => callNextToken('dept-1'),
                  icon: const Icon(Icons.campaign),
                  label: const Text('Call Next Token'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Body Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(errorMessage, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: fetchTokens,
                              child: const Text('Retry Connection'),
                            ),
                          ],
                        ),
                      )
                    : tokens.isEmpty
                        ? const Center(
                            child: Text(
                              'No tokens in the queue.',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: tokens.length,
                            itemBuilder: (context, index) {
                              final token = tokens[index];
                              final status = token['status'] ?? 'waiting';

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 2,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: getStatusColor(status),
                                    foregroundColor: Colors.white,
                                    child: Text(
                                      '${token['tokenNumber'] ?? index + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    '${token['formattedToken']} — ${token['userName']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Dept: ${token['departmentName']} | Time: ${token['bookedTime'] ?? 'N/A'}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: getStatusColor(status).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: getStatusColor(status),
                                          ),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: getStatusColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      if (status == 'serving') ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.check_circle, color: Colors.green),
                                          tooltip: 'Mark Completed',
                                          onPressed: () => updateTokenStatus(
                                              token['id'], 'completed'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}