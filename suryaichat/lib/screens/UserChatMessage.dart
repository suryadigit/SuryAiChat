// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserChatMessage extends StatefulWidget {
  final Map<String, dynamic> message;
  final VoidCallback onLongPress;

  const UserChatMessage({
    required this.message,
    required this.onLongPress,
    super.key,
  });

  @override
  _UserChatMessageState createState() => _UserChatMessageState();
}

class _UserChatMessageState extends State<UserChatMessage> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(10.0),
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
          widget.message['content'],
          style: const TextStyle(color: Colors.white, fontSize: 12.5),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset position =
        button.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy - 50,
          position.dx + button.size.height - 12.0, position.dy),
      items: <PopupMenuEntry>[
        PopupMenuItem(
          child: ListTile(
            leading: Icon(PhosphorIcons.clipboard()),
            title: const Text('Salin'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.message['content']));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pesan disalin ke clipboard')),
              );
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: Icon(PhosphorIcons.pen()),
            title: const Text('Edit'),
            onTap: () {
              Navigator.of(context).pop();
              widget.onLongPress();
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
              leading: Icon(PhosphorIcons.textAa()),
              title: const Text('Pilih Teks'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 300),
                      transitionsBuilder: (BuildContext context,
                          Animation<double> animation,
                          Animation<double> secondaryAnimation,
                          Widget child) {
                        var begin = const Offset(1.0, 0.0);
                        var end = Offset.zero;
                        var curve = Curves.ease;

                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                      pageBuilder: (BuildContext context,
                          Animation<double> animation,
                          Animation<double> secondaryAnimation) {
                        return TextSelectionPage(widget.message['content']);
                      },
                    ));
              }),
        ),
      ],
    );
  }
}

class TextSelectionPage extends StatelessWidget {
  final String text;

  const TextSelectionPage(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Teks', style: TextStyle(
        fontSize: 16.0,fontWeight: FontWeight.w500
        ),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SelectableText(
          text,
          style: const TextStyle(fontSize: 14.0),
          toolbarOptions: const ToolbarOptions(
            copy: true,
            selectAll: true,
          ),
          showCursor: true,
          cursorColor: Colors.black,
          cursorWidth: 2.0,
        ),
      ),
    );
  }
}
