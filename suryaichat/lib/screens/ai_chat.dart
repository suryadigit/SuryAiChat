import 'dart:async';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlighting/themes/github.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isExpanded = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

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
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
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
              duration: const Duration(milliseconds: 100),
              child: _isExpanded ? _buildExpandedInput() : _buildFab(),
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
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _textController,
                    maxLines: null,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Kirim sebuah pesan',
                      hintStyle: const TextStyle(fontFamily: 'Monospace'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 12.0),
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
            bottom: 8,
            right: 8,
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
                  icon: Icon(
                    _chatService.isListening
                        ? PhosphorIconsFill.microphone
                        : PhosphorIconsFill.microphoneSlash,
                  ),
                  color: Colors.grey,
                ),
                IconButton(
                  onPressed: (_isLoading || _textController.text.trim().isEmpty)
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
                      ? const SizedBox(
                          height: 23.0,
                          width: 23.0,
                          child: CircularProgressIndicator(
                            color: Colors.blue,
                            strokeWidth: 2.0,
                          ),
                        )
                      : Container(
                          height: 36.0,
                          width: 36.0,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                          child: const Icon(
                            PhosphorIconsFill.paperPlaneRight,
                            size: 21.0,
                            color: Colors.white,
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

  Widget _buildFab() {
    return Padding(
      padding: EdgeInsets.only(bottom: 6, right: _isExpanded ? 12.0 : 0),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.only(
            right: _isExpanded ? 12.0 : 0,
          ),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = true;
              });
            },
            onTapDown: (_) {
              _fabAnimationController.forward();
            },
            onTapCancel: () {
              _fabAnimationController.reverse();
            },
            onTapUp: (_) {
              _fabAnimationController.reverse();
            },
            child: AnimatedBuilder(
              animation: _fabAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 - (_fabAnimation.value * 0.15),
                  child: Container(
                    width: 56.0 + (_fabAnimation.value * 18.0),
                    height: 58.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: const Center(
                      child: Icon(
                        PhosphorIconsFill.chatsTeardrop,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
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
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Ops Dalam Pengembangan!'),
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
        _isExpanded = false;
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
        _isExpanded = false;
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
      _isExpanded = true;
    });
  }
}

class UserChatMessage extends StatelessWidget {
  final Map<String, dynamic> message;
  final VoidCallback onLongPress;

  const UserChatMessage({
    required this.message,
    required this.onLongPress,
    super.key,
  });

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

  const AIChat({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String content = message['content'];
    final List<TextSpan> spans = _buildContentSpans(content);

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
          color: Color.fromARGB(255, 238, 237, 237),
         borderRadius: BorderRadius.only(
            topRight: Radius.circular(12.0),
            bottomRight: Radius.circular(12.0),
            topLeft: Radius.circular(0),
            bottomLeft: Radius.circular(12.0),
          ),
      ),
      child: RichText(
        text: TextSpan(
          children: spans,
          style: const TextStyle(
            fontSize: 15.0,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildContentSpans(String content) {
    final RegExp urlRegex = RegExp(
      r'((http|https):\/\/)?[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(\/\S*)?',
    );

    final List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    urlRegex.allMatches(content).forEach((match) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: content.substring(lastMatchEnd, match.start)));
      }

      final String url = content.substring(match.start, match.end);
      spans.add(
        TextSpan(
          text: url,
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _launchURL(url),
        ),
      );

      lastMatchEnd = match.end;
    });

    if (lastMatchEnd < content.length) {
      spans.add(TextSpan(text: content.substring(lastMatchEnd)));
    }

    return spans;
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class CodeMessage extends StatelessWidget {
  final Map<String, dynamic> message;

  const CodeMessage({
    required this.message,
    super.key,
  });

  String _extractLanguage(String content) {
    final startIndex = content.indexOf('```') + 3;
    final endIndex = content.indexOf('\n', startIndex);
    if (startIndex != -1 && endIndex != -1) {
      return content.substring(startIndex, endIndex).trim();
    }
    return '';
  }

  String _extractCode(String content) {
    final startIndex = content.indexOf('\n') + 1;
    final endIndex = content.lastIndexOf('```');
    if (startIndex != -1 && endIndex != -1) {
      return content.substring(startIndex, endIndex).trim();
    }
    return content.replaceAll('```', '').trim();
  }

  String _extractTextBeforeCode(String content) {
    final codeStartIndex = content.indexOf('```');
    if (codeStartIndex != -1) {
      return content.substring(0, codeStartIndex).trim();
    }
    return '';
  }

  String _extractTextAfterCode(String content) {
    final codeEndIndex = content.lastIndexOf('```') + 3;
    if (codeEndIndex != -1 && codeEndIndex < content.length) {
      return content.substring(codeEndIndex).trim();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final language = _extractLanguage(message['content']);
    final code = _extractCode(message['content']);
    final textBeforeCode = _extractTextBeforeCode(message['content']);
    final textAfterCode = _extractTextAfterCode(message['content']);

    return Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (textBeforeCode.isNotEmpty)
              Text(
                textBeforeCode,
                style: const TextStyle(color: Colors.black),
              ),
            const SizedBox(height: 8.0),
            GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kode disalin!')),
                );
              },
              child: HighlightView(
                code,
                language: language,
                theme: githubTheme,
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.0,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.0,
                    color: Colors.grey,
                  ),
                ),
               
               Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Salin kode',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.0,
                        color: Colors.blue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        PhosphorIconsBold.clipboardText,
                        color: Colors.blue,
                        size: 16,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kode disalin!')),
                        );
                      },
                    ),
                  ],
                ),

              ],
            ),
            if (textAfterCode.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  textAfterCode,
                  style: const TextStyle(color: Colors.black),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
