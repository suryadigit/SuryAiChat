// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:suryaichat/screens/AIChat.dart';
import 'package:suryaichat/screens/CodeMessage.dart';
import 'package:suryaichat/screens/UserChatMessage.dart';
import '../services/chat_service.dart';

class UserChat extends StatefulWidget {
  const UserChat({Key? key}) : super(key: key);

  @override
  State<UserChat> createState() => _UserChatState();
}

class _UserChatState extends State<UserChat> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _conversations = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final ChatService _chatService = ChatService();

  bool _isLoading = false;
  String _typingMessage = '';
  bool _isTyping = false;
  Timer? _typingTimer;
  int? _editingIndex;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _chatService.loadApiKey();
    _chatService.initializeSpeech().then((_) {
      if (!_chatService.isSpeechAvailable) {}
    });
    _addGreetingMessage();
    _textController.addListener(_updateSendButtonState);

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _addGreetingMessage() {
    setState(() {
      _conversations.add({
        'role': 'ai',
        'content':
            'Selamat datang di suryaichat! Siap membantu tugasmu 😎 sampai mampus tanpa batas!',
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
    _fabAnimationController.dispose();
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 50),
              child: _buildExpandedInput(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildExpandedInput() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      key: const ValueKey('expandedInput'),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _textController,
                    maxLines: null,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Kirim sebuah pesan',
                      hintStyle: const TextStyle(fontFamily: 'Monospace'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12.0),
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
              ],
            ),
          ),
          Positioned(
            bottom: 2,
            right: 5,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (_chatService.isListening) {
                        _chatService.stopListening();
                      } else {
                        _isTyping = false;
                        startListening();
                      }
                    });
                  },
                  icon: Icon(
                    _chatService.isListening
                        ? PhosphorIconsFill.microphone
                        : PhosphorIconsFill.microphoneSlash,
                    size: 24.0,
                  ),
                  color: _chatService.isListening ? Colors.blue : Colors.grey,
                ),
                IconButton(
                  onPressed: (_isTyping || _textController.text.trim().isEmpty)
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
                  icon: _isTyping
                      ? SizedBox(
                          child: LoadingAnimationWidget.staggeredDotsWave(
                            color: Colors.grey,
                            size: 24.0,
                          ),
                        )
                      : Container(
                          height: 33.0,
                          width: 33.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _textController.text.trim().isEmpty
                                ? Colors.grey
                                : Colors.blue,
                          ),
                          child: Icon(
                            PhosphorIconsFill.paperPlaneRight,
                            size: 22.0,
                            color: _textController.text.trim().isEmpty
                                ? Colors.white
                                : Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

//fitur microphone
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
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Ops, fitur suara tidak tersedia.'),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_isTyping || _textController.text.trim().isEmpty) return;
    String userInput = _textController.text.trim();
    _textController.clear();

    setState(() {
      _conversations
          .add({'role': 'user', 'content': userInput, 'isCode': false});
      _isTyping = true;
    });

    try {
      final aiResponse = await _chatService.sendMessage(userInput,);
      _simulateTyping(aiResponse, isCode: aiResponse.contains('```'));
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
        _isTyping = true;
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
      _isTyping = true;
    });

    try {
      final aiResponse = await _chatService.sendMessage(editedMessage);
      aiResponse.contains('```');
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

  void _simulateTyping(String message,
      {bool isEditing = false, bool isCode = false}) {
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
                'isCode': isCode,
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
