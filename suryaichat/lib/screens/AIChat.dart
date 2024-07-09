// ignore_for_file: file_names

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

    return GestureDetector(
      onLongPress: () => _showOptions(context, content),
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(10.0),
        decoration: const BoxDecoration(
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
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              _launchURL(url);
            },
        ),
      );

      lastMatchEnd = match.end;
    });

    if (lastMatchEnd < content.length) {
      spans.add(TextSpan(text: content.substring(lastMatchEnd)));
    }

    return spans;
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  void _showOptions(BuildContext context, String content) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Salin'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: content));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pesan disalin ke clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Bagikan'),
              onTap: () {
                Share.share(content);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
