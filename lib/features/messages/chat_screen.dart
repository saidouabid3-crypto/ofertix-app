import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../models/chat_message_model.dart';
import '../../services/auth_service.dart';
import '../../services/message_service.dart';

class ChatScreen extends StatefulWidget {
  ChatScreen({
    super.key,
    required this.baseUrl,
    required this.recipientId,
    required this.recipientName,
    this.recipientAvatarUrl = '',
    this.conversationId,
    this.sourceReelId = '',
    this.sourceReelTitle = '',
    this.sourceReelThumbnailUrl = '',
  });

  final String baseUrl;
  final String recipientId;
  final String recipientName;
  final String recipientAvatarUrl;
  final String? conversationId;
  final String sourceReelId;
  final String sourceReelTitle;
  final String sourceReelThumbnailUrl;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final MessageService service;
  final AuthService auth = AuthService.instance;
  final TextEditingController controller = TextEditingController();

  String? conversationId;
  List<ChatMessageModel> messages = [];
  bool loading = false;
  bool sending = false;
  String? error;

  @override
  void initState() {
    super.initState();
    service = MessageService(baseUrl: widget.baseUrl);
    conversationId = widget.conversationId;
    if (conversationId != null && conversationId!.isNotEmpty) {
      loadMessages();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> loadMessages() async {
    final id = conversationId;
    if (id == null || id.isEmpty) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await service.getConversation(id);
      await service.markConversationRead(id);
      if (!mounted) return;
      setState(() {
        messages = data;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'No se pudieron cargar los mensajes';
      });
    }
  }

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;

    setState(() => sending = true);

    try {
      if (conversationId == null || conversationId!.isEmpty) {
        final conversation = await service.startConversation(
          receiverId: widget.recipientId,
          receiverName: widget.recipientName,
          receiverPhotoUrl: widget.recipientAvatarUrl,
          text: text,
          reelId: widget.sourceReelId,
          reelTitle: widget.sourceReelTitle,
          reelThumbnailUrl: widget.sourceReelThumbnailUrl,
        );

        conversationId = conversation?.id;
        controller.clear();
        await loadMessages();
      } else {
        final message = await service.sendMessage(
          conversationId: conversationId!,
          text: text,
        );
        controller.clear();

        if (message != null && mounted) {
          setState(() {
            messages.add(message);
          });
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auto.messages_chat_screen.no_se_pudo_enviar_el_mensaje'.tr(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUserId ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white12,
              backgroundImage: widget.recipientAvatarUrl.startsWith('http')
                  ? CachedNetworkImageProvider(widget.recipientAvatarUrl)
                  : null,
              child: widget.recipientAvatarUrl.startsWith('http')
                  ? null
                  : Icon(Icons.person_rounded, color: Colors.white, size: 18),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.recipientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (widget.sourceReelTitle.isNotEmpty)
            _SourceReelCard(
              title: widget.sourceReelTitle,
              thumbnailUrl: widget.sourceReelThumbnailUrl,
            ),
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : error != null
                ? Center(
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, 18),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final mine = msg.senderId == uid;
                      return _MessageBubble(message: msg, mine: mine);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Color(0xFF080808),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: TextStyle(color: Colors.white),
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'auto.messages_chat_screen.escribe_un_mensaje'.tr()
                            .tr(),
                        hintStyle: TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 9),
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      onPressed: sending ? null : send,
                      icon: sending
                          ? SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Icon(Icons.send_rounded, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceReelCard extends StatelessWidget {
  _SourceReelCard({required this.title, required this.thumbnailUrl});

  final String title;
  final String thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(12, 6, 12, 8),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 48,
              height: 56,
              child: thumbnailUrl.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(color: Colors.white10),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  _MessageBubble({required this.message, required this.mine});

  final ChatMessageModel message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? Colors.white : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 5),
            bottomRight: Radius.circular(mine ? 5 : 18),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: mine ? Colors.black : Colors.white,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}
