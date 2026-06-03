import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../models/conversation_model.dart';
import '../../services/auth_service.dart';
import '../../services/message_service.dart';
import 'chat_screen.dart';

class MessagesInboxScreen extends StatefulWidget {
  MessagesInboxScreen({super.key, required this.baseUrl});

  final String baseUrl;

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  late final MessageService service;
  final AuthService auth = AuthService.instance;

  List<ConversationModel> items = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    service = MessageService(baseUrl: widget.baseUrl);
    loadInbox();
  }

  Future<void> loadInbox() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await service.getInbox();
      if (!mounted) return;
      setState(() {
        items = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'No se pudo cargar la bandeja';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUserId ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('auto.messages_messages_inbox_screen.mensajes'.tr(),
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadInbox,
        color: Colors.white,
        child: loading
            ? Center(child: CircularProgressIndicator(color: Colors.white))
            : error != null
            ? ListView(
                children: [
                  SizedBox(height: 180),
                  Center(
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              )
            : items.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: 180),
                  Icon(
                    Icons.mark_chat_unread_outlined,
                    color: Colors.white24,
                    size: 70,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text('auto.messages_messages_inbox_screen.todavia_no_tienes_mensajes'.tr()
                          .tr(),
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: EdgeInsets.fromLTRB(14, 8, 14, 110),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final c = items[index];
                  final otherName = c.otherUserName(uid);
                  final otherPhoto = c.otherUserPhoto(uid);
                  final unread = c.unreadFor(uid);

                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 2,
                    ),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white12,
                      backgroundImage: otherPhoto.startsWith('http')
                          ? CachedNetworkImageProvider(otherPhoto)
                          : null,
                      child: otherPhoto.startsWith('http')
                          ? null
                          : Icon(Icons.person_rounded, color: Colors.white),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              unread.toString(),
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      c.lastMessage.isEmpty ? 'Nuevo mensaje' : c.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unread > 0 ? Colors.white : Colors.white54,
                        fontWeight: unread > 0
                            ? FontWeight.w900
                            : FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white38,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            baseUrl: widget.baseUrl,
                            conversationId: c.id,
                            recipientId: c.otherUserId(uid),
                            recipientName: otherName,
                            recipientAvatarUrl: otherPhoto,
                          ),
                        ),
                      ).then((_) => loadInbox());
                    },
                  );
                },
              ),
      ),
    );
  }
}
