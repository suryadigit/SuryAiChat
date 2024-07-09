// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlighting/themes/github.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

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

    return GestureDetector(
      onLongPress: () => _showOptions(context, code),
      child: Container(
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
                SelectableText(
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
                  child: SelectableText(
                    textAfterCode,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, String code) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Salin'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kode disalin ke clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Bagikan'),
              onTap: () {
                Share.share(code);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
