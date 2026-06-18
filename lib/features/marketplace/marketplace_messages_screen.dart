import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/marketplace_conversation.dart';
import '../../services/marketplace_service.dart';
import 'marketplace_conversation_screen.dart';

/// Unified WhatsApp-style inbox: exactly one row per other user.
///
/// The backend now returns one canonical conversation per participant pair.
/// Flutter applies a client-side safety dedup as a belt-and-suspenders guard
/// during the migration rollout period.
///
/// Removed in Batch 16F-D:
///   - InboxParticipantGroup / InboxGroupResult / groupInboxByParticipant
///   - _ConversationPickerSheet (select conversation bottom sheet)
///   - Context chips ("2 Listings · 1 Reel") on inbox rows
class MarketplaceMessagesScreen extends StatefulWidget {
  const MarketplaceMessagesScreen({super.key, this.initialConversationId});

  /// When set (e.g. from a notification tap), the inbox auto-opens this
  /// conversation after the first load completes.
  final String? initialConversationId;

  @override
  State<MarketplaceMessagesScreen> createState() =>
      _MarketplaceMessagesScreenState();
}

class _MarketplaceMessagesScreenState extends State<MarketplaceMessagesScreen> {
  List<MarketplaceConversation> _conversations = const [];
  bool _loading = true;
  String? _error;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    if (_uid.isEmpty) {
      setState(() {
        _loading = false;
        _conversations = const [];
        _error = 'mkt.messages.loginRequired'.tr();
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await MarketplaceService.instance.fetchInbox();
      // Safety-net client dedup (canonical dedup already done on backend)
      final result = dedupeInboxConversations(raw, _uid);
      debugPrint(
        '[16F-D] inbox_load before=${result.before} '
        'after=${result.after} hidden_self=${result.hiddenSelf}',
      );
      if (!mounted) return;
      setState(() {
        _conversations = result.conversations;
        _loading = false;
      });

      // Auto-open conversation from notification deep-link (first load only)
      final pendingId = widget.initialConversationId;
      if (pendingId != null && pendingId.isNotEmpty && mounted) {
        final match = result.conversations.where((c) => c.id == pendingId).firstOrNull;
        if (match != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openConversation(match);
          });
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'mkt.messages.serviceUnavailable'.tr();
      });
    }
  }

  Future<void> _openConversation(MarketplaceConversation conversation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MarketplaceConversationScreen(conversation: conversation),
      ),
    );
    if (mounted) _loadInbox();
  }

  Future<void> _archiveConversation(MarketplaceConversation conv) async {
    final idx = _conversations.indexOf(conv);
    setState(() {
      _conversations = [
        ..._conversations.where((c) => c.id != conv.id),
      ];
    });
    try {
      await MarketplaceService.instance.archiveConversation(conv.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('mkt.inbox.archived'.tr())),
        );
      }
    } catch (_) {
      if (mounted) {
        final updated = List<MarketplaceConversation>.from(_conversations);
        if (idx >= 0 && idx <= updated.length) {
          updated.insert(idx, conv);
        } else {
          updated.add(conv);
        }
        setState(() => _conversations = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('mkt.inbox.actionFailed'.tr())),
        );
      }
    }
  }

  Future<void> _deleteConversation(MarketplaceConversation conv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('mkt.inbox.deleteConfirmTitle'.tr()),
        content: Text('mkt.inbox.deleteConfirmBody'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'mkt.inbox.deleteForMe'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final idx = _conversations.indexOf(conv);
    setState(() {
      _conversations = [
        ..._conversations.where((c) => c.id != conv.id),
      ];
    });
    try {
      await MarketplaceService.instance.deleteConversationForMe(conv.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('mkt.inbox.deleted'.tr())),
        );
      }
    } catch (_) {
      if (mounted) {
        final updated = List<MarketplaceConversation>.from(_conversations);
        if (idx >= 0 && idx <= updated.length) {
          updated.insert(idx, conv);
        } else {
          updated.add(conv);
        }
        setState(() => _conversations = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('mkt.inbox.actionFailed'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final text = isDark ? AppColors.text : AppColors.lightText;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'mkt.messages.title'.tr(),
          style: TextStyle(color: text, fontWeight: FontWeight.w900),
        ),
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }
    if (_error != null) {
      return _InboxState(
        icon: Icons.cloud_off_outlined,
        title: _error!,
        subtitle: _uid.isEmpty ? null : 'mkt.messages.honestFallback'.tr(),
        action: _uid.isEmpty ? null : _loadInbox,
      );
    }
    if (_conversations.isEmpty) {
      return _InboxState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'mkt.messages.noConversations'.tr(),
        subtitle: 'mkt.messages.emptyHint'.tr(),
      );
    }
    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: _loadInbox,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final conv = _conversations[index];
          return Dismissible(
            key: ValueKey(conv.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              await _deleteConversation(conv);
              return false;
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            ),
            child: _ConversationTile(
              conversation: conv,
              currentUserId: _uid,
              isDark: isDark,
              onTap: () => _openConversation(conv),
              onArchive: () => _archiveConversation(conv),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single-conversation inbox tile (WhatsApp-style)
// ---------------------------------------------------------------------------

class _ConversationTile extends StatelessWidget {
  final MarketplaceConversation conversation;
  final String currentUserId;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.isDark,
    required this.onTap,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    final avatar = conversation.otherUserPhoto(currentUserId);
    final name = conversation.otherUserName(currentUserId);
    final unread = conversation.unreadFor(currentUserId);
    final timestamp = conversation.lastMessageAt == null
        ? ''
        : DateFormat.MMMd(context.locale.languageCode)
            .add_Hm()
            .format(conversation.lastMessageAt!.toLocal());

    return Material(
      color: isDark ? AppColors.card : AppColors.lightCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        onLongPress: onArchive,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white12 : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              // Profile avatar
              ClipOval(
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: avatar.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: avatar,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _AvatarPlaceholder(),
                        )
                      : _AvatarPlaceholder(),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + timestamp
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.isNotEmpty
                                ? name
                                : conversation.otherUserId(currentUserId),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (timestamp.isNotEmpty)
                          Text(
                            timestamp,
                            style: TextStyle(color: muted, fontSize: 9),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Last message + unread badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage.isEmpty
                                ? 'mkt.messages.startConversation'.tr()
                                : conversation.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unread > 0 ? text : muted,
                              fontSize: 12,
                              fontWeight: unread > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unread',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.orange.withValues(alpha: .1),
        child: const Icon(
          Icons.person_outline_rounded,
          color: AppColors.orange,
        ),
      );
}

// ---------------------------------------------------------------------------
// Empty / error state
// ---------------------------------------------------------------------------

class _InboxState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? action;

  const _InboxState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.orange, size: 52),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 7),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: action,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('mkt.messages.retry'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
