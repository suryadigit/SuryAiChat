import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlighting/themes/github.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import '../services/chat_service.dart';

class UserChat extends StatefulWidget {
  const UserChat({Key? key}) : super(key: key);

  @override
  State<UserChat> createState() => _UserChatState();
}

class _UserChatState extends State<UserChat> {
  final List<Map<String, dynamic>> _conversations = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final ChatService _chatService = ChatService();

  bool _isLoading = false;
  String _typingMessage = '';
  bool _isTyping = false;
  Timer? _typingTimer;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _chatService.loadApiKey();
    _chatService.initializeSpeech().then((_) {
      if (!_chatService.isSpeechAvailable) {}
    });
    _addGreetingMessage();
    _textController.addListener(_updateSendButtonState);
  }

  void _addGreetingMessage() {
    setState(() {
      _conversations.add({
        'role': 'ai',
        'content': 'Selamat datang di suryaichat! Siap membantu tugasmu 😊',
        'isCode': false,
      });
    });
  }

  void _updateSendButtonState() {
    setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'suryaichat🚀',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 21,
            fontFamily: 'Monospace',
          ),
        ),
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 23.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 36.0),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _conversations.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _conversations.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: AIChat(
                      message: {'content': _typingMessage, 'isCode': false},
                      onLongPress:
                          () {}, // dummy function or null, adjust as needed
                    ),
                  );
                }
                final message = _conversations[index];
                return Align(
                  alignment: message['role'] == 'user'
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: message['role'] == 'ai'
                      ? (message['isCode']
                          ? CodeMessage(message: message)
                          : AIChat(
                              message: message,
                              onLongPress: () {
                                _editMessage(index);
                              },
                            ))
                      : UserChatMessage(
                          message: message,
                          onLongPress: () {
                            _editMessage(index);
                          },
                        ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.1,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        reverse: true,
                        child: TextFormField(
                          controller: _textController,
                          maxLines: null,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Kirim sebuah pesan',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 50),
                          ),
                          onFieldSubmitted: (value) {
                            if (value.isNotEmpty) {
                              if (_editingIndex != null) {
                                _submitEditedMessage();
                              } else {
                                _submitForm();
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_chatService.isListening) {
                                _chatService.stopListening();
                              } else {
                                startListening();
                              }
                            },
                            icon: Icon(_chatService.isListening
                                ? Icons.mic_off
                                : Icons.mic),
                            color: Colors.grey,
                          ),
                          IconButton(
                            onPressed: (_isLoading ||
                                    _textController.text.trim().isEmpty)
                                ? null
                                : () {
                                    if (_textController.text.isNotEmpty) {
                                      if (_editingIndex != null) {
                                        _submitEditedMessage();
                                      } else {
                                        _submitForm();
                                      }
                                    }
                                  },
                            icon: _isLoading
                                ? const CircularProgressIndicator()
                                : Icon(
                                    PhosphorIcons.paperPlaneRight(),
                                    size: 21.0,
                                    color: Colors.blue[400],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void startListening() {
    if (_chatService.isSpeechAvailable) {
      try {
        _chatService.startListening((recognizedWords) {
          setState(() {
            _textController.text = recognizedWords;
          });
        });
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Gagal mendengar suara, ada yang error kayaknya: $error'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Perangkat kamu tidak mendukung.'),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_isLoading || _textController.text.trim().isEmpty) return;
    String userInput = _textController.text.trim();
    _textController.clear();

    setState(() {
      _conversations
          .add({'role': 'user', 'content': userInput, 'isCode': false});
      _isLoading = true;
    });

    try {
      final aiResponse = await _chatService.sendMessage(userInput);
      _simulateTyping(aiResponse);
    } catch (error) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Gagal mendapatkan respons dari server.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _submitEditedMessage() async {
    if (_isLoading ||
        _textController.text.trim().isEmpty ||
        _editingIndex == null) return;

    String editedMessage = _textController.text.trim();
    _textController.clear();

    setState(() {
      _isLoading = true;
    });

    try {
      final aiResponse = await _chatService.sendMessage(editedMessage);
      _conversations[_editingIndex!] = {
        'role': 'user',
        'content': editedMessage,
        'isCode': false,
      };
      _simulateTyping(aiResponse, isEditing: true);
    } catch (error) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Gagal mendapatkan respons dari server.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        _isLoading = false;
        _editingIndex = null;
      });
    }

    _scrollToBottom();
  }

  void _simulateTyping(String message, {bool isEditing = false}) {
    setState(() {
      _isTyping = true;
      _typingMessage = '';
    });

    int charIndex = 0;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (charIndex < message.length) {
        setState(() {
          _typingMessage += message[charIndex];
          charIndex++;
        });
        _scrollToBottom();
      } else {
        timer.cancel();
        setState(() {
          if (_typingMessage.isNotEmpty) {
            if (isEditing) {
              _conversations.last['content'] = _typingMessage;
            } else {
              _conversations.add({
                'role': 'ai',
                'content': _typingMessage,
                'isCode': false,
              });
            }
          }
          _isTyping = false;
          _typingMessage = '';
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _editMessage(int index) {
    setState(() {
      _textController.text = _conversations[index]['content'];
      _editingIndex = index;
    });
  }
}

class UserChatMessage extends StatelessWidget {
  final Map<String, dynamic> message;
  final VoidCallback onLongPress;

  const UserChatMessage({
    required this.message,
    required this.onLongPress,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: const BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12.0),
            bottomLeft: Radius.circular(12.0),
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(12.0),
          ),
        ),
        child: Text(
          message['content'],
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class AIChat extends StatelessWidget {
  final Map<String, dynamic> message;
  final VoidCallback onLongPress;

  const AIChat({
    required this.message,
    required this.onLongPress,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 238, 237, 237),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(12.0),
            bottomRight: Radius.circular(12.0),
            topLeft: Radius.circular(0),
            bottomLeft: Radius.circular(12.0),
          ),
        ),
        child: Text(
          message['content'],
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}

class CodeMessage extends StatelessWidget {
  final Map<String, dynamic> message;

  const CodeMessage({
    required this.message,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 12,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: HighlightView(
                message['content'].replaceAll('```', ''),
                language: '',
                theme: githubTheme,
                textStyle:
                    const TextStyle(fontFamily: 'monospace', fontSize: 12.0),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.copy, color: Colors.blue, size: 16),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: message['content'].replaceAll('```', '')),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kode disalin!')),
              );
            },
          ),
        ),
      ],
    );
  }
}
 