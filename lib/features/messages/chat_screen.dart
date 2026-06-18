import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/chat_message_model.dart';
import '../../services/auth_service.dart';
import '../../services/message_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
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
  final AuthService auth = AuthService.instance;
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late final MessageService service;

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
    scrollController.dispose();
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'mkt.messages.conversationUnavailable'.tr();
      });
    }
  }

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;

    FocusManager.instance.primaryFocus?.unfocus();
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
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('mkt.messages.messageFailed'.tr())),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void _scrollToEnd() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUserId ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final text = isDark ? AppColors.text : AppColors.lightText;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        titleSpacing: 0,
        title: _RecipientHeader(
          name: widget.recipientName,
          avatarUrl: widget.recipientAvatarUrl,
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages(uid, isDark)),
          _LegacyComposer(
            controller: controller,
            sending: sending,
            isDark: isDark,
            onChanged: (_) => setState(() {}),
            onSend: send,
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(String uid, bool isDark) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }
    if (error != null) {
      return _ChatState(
        icon: Icons.cloud_off_outlined,
        message: error!,
        isDark: isDark,
        action: loadMessages,
      );
    }
    if (messages.isEmpty) {
      return _ChatState(
        icon: Icons.chat_bubble_outline_rounded,
        message: 'mkt.messages.startConversation'.tr(),
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: loadMessages,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_showsDateSeparator(index))
                _ChatDateSeparator(
                  label: _dateSeparatorLabel(message.createdAt),
                  isDark: isDark,
                ),
              _LegacyMessageBubble(
                message: message,
                mine: message.senderId == uid,
                isDark: isDark,
              ),
            ],
          );
        },
      ),
    );
  }

  bool _showsDateSeparator(int index) {
    final current = messages[index].createdAt?.toLocal();
    if (current == null) return index == 0;
    if (index == 0) return true;
    final previous = messages[index - 1].createdAt?.toLocal();
    if (previous == null) return true;
    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }

  String _dateSeparatorLabel(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(local.year, local.month, local.day);
    if (messageDay == today) return 'mkt.messages.today'.tr();
    if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'mkt.messages.yesterday'.tr();
    }
    return DateFormat.yMMMd(context.locale.languageCode).format(local);
  }
}

class _RecipientHeader extends StatelessWidget {
  final String name;
  final String avatarUrl;

  const _RecipientHeader({required this.name, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.orange.withValues(alpha: .16),
          backgroundImage: avatarUrl.startsWith('http')
              ? CachedNetworkImageProvider(avatarUrl)
              : null,
          child: avatarUrl.startsWith('http')
              ? null
              : const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.orange,
                  size: 19,
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _ChatDateSeparator extends StatelessWidget {
  final String label;
  final bool isDark;

  const _ChatDateSeparator({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? AppColors.card2 : AppColors.lightCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDark ? Colors.white10 : AppColors.lightBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.gray : AppColors.lightGray,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LegacyMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool mine;
  final bool isDark;

  const _LegacyMessageBubble({
    required this.message,
    required this.mine,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final otherBubble = isDark ? AppColors.card : AppColors.lightCard;
    final otherText = isDark ? AppColors.text : AppColors.lightText;
    final time = message.createdAt == null
        ? ''
        : DateFormat.Hm(
            context.locale.languageCode,
          ).format(message.createdAt!.toLocal());

    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .78,
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (message.hasContext)
              _LegacyContextCard(message: message, isDark: isDark),
            Container(
              margin: EdgeInsets.only(
                bottom: message.hasContext ? 6 : 8,
                top: message.hasContext ? 2 : 0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: mine ? AppColors.orange : otherBubble,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: const Radius.circular(18),
                  topEnd: const Radius.circular(18),
                  bottomStart: Radius.circular(mine ? 18 : 5),
                  bottomEnd: Radius.circular(mine ? 5 : 18),
                ),
                border: mine
                    ? null
                    : Border.all(
                        color: isDark ? Colors.white10 : AppColors.lightBorder,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: mine ? Colors.white : otherText,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      time,
                      style: TextStyle(
                        color: mine
                            ? Colors.white70
                            : (isDark ? AppColors.gray : AppColors.lightGray),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyContextCard extends StatelessWidget {
  final ChatMessageModel message;
  final bool isDark;

  const _LegacyContextCard({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isListing = message.contextType == 'marketplace_listing';
    final sourceLabel = isListing
        ? 'mkt.inbox.contextListing'.tr()
        : 'mkt.inbox.contextReel'.tr();
    final sourceColor = isListing ? AppColors.orange : Colors.deepPurpleAccent;
    final sourceIcon = isListing
        ? Icons.shopping_bag_outlined
        : Icons.play_circle_outline;
    final title = message.contextTitle.isNotEmpty
        ? message.contextTitle
        : 'mkt.messages.contentUnavailable'.tr();

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: SizedBox(
              width: 36,
              height: 36,
              child: message.contextThumbnailUrl.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: message.contextThumbnailUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _ContextIconFallback(
                        icon: sourceIcon,
                        color: sourceColor,
                      ),
                    )
                  : _ContextIconFallback(icon: sourceIcon, color: sourceColor),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sourceLabel,
                  style: TextStyle(
                    color: sourceColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppColors.text : AppColors.lightText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextIconFallback extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _ContextIconFallback({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    color: color.withValues(alpha: .12),
    child: Icon(icon, color: color, size: 18),
  );
}

class _LegacyComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  const _LegacyComposer({
    required this.controller,
    required this.sending,
    required this.isDark,
    required this.onChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final canSend = controller.text.trim().isNotEmpty && !sending;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.card : AppColors.lightCard,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white12 : AppColors.lightBorder,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'mkt.messages.typeMessage'.tr(),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.background
                      : AppColors.lightBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: sending
                  ? 'mkt.messages.sending'.tr()
                  : 'mkt.messages.send'.tr(),
              onPressed: canSend ? onSend : null,
              style: IconButton.styleFrom(backgroundColor: AppColors.orange),
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatState extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isDark;
  final VoidCallback? action;

  const _ChatState({
    required this.icon,
    required this.message,
    required this.isDark,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.text : AppColors.lightText;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.orange, size: 44),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: text, fontWeight: FontWeight.w800),
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: action,
                child: Text('mkt.messages.retry'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
