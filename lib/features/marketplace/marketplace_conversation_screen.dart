import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/marketplace_conversation.dart';
import '../../models/marketplace_item.dart';
import '../../services/marketplace_service.dart';
import 'marketplace_item_detail_screen.dart';
import 'marketplace_profile_navigation.dart';

class MarketplaceConversationScreen extends StatefulWidget {
  final MarketplaceConversation conversation;

  /// Non-null when opened directly from a listing detail page.
  /// Shows a compact listing banner at the top of the chat.
  final MarketplaceItem? initialItem;

  const MarketplaceConversationScreen({
    super.key,
    required this.conversation,
    this.initialItem,
  });

  @override
  State<MarketplaceConversationScreen> createState() =>
      _MarketplaceConversationScreenState();
}

class _MarketplaceConversationScreenState
    extends State<MarketplaceConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late MarketplaceConversation _conversation;
  List<MarketplaceMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  bool _offerDialogOpen = false;
  bool _reviewDialogOpen = false;
  String? _error;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final thread = await MarketplaceService.instance.fetchConversation(
        _conversation.id,
      );
      if (!mounted) return;
      setState(() {
        _conversation = thread.conversation;
        _messages = thread.messages;
        _loading = false;
      });
      try {
        await MarketplaceService.instance.markConversationRead(
          _conversation.id,
        );
      } catch (e) {
        debugPrint('[16F-D] mark_read failed: $e');
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'mkt.messages.conversationUnavailable'.tr();
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (_sending || text.isEmpty || text.length > 1000) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _sending = true);
    try {
      final message = await MarketplaceService.instance.sendMessage(
        _conversation.id,
        text,
      );
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _messages = [..._messages, message];
        _sending = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('mkt.messages.messageFailed'.tr())),
      );
    }
  }

  Future<void> _showOffer() async {
    if (_offerDialogOpen || _sending) return;
    setState(() => _offerDialogOpen = true);

    final amountController = TextEditingController();
    double? amount;
    try {
      String? errorText;
      amount = await showDialog<double>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text('mkt.messages.makeOffer'.tr()),
              content: TextField(
                controller: amountController,
                autofocus: false,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'mkt.messages.offerAmount'.tr(),
                  suffixText: _conversation.listingCurrency,
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('common.cancel'.tr()),
                ),
                FilledButton(
                  onPressed: () {
                    final parsed = double.tryParse(
                      amountController.text.trim().replaceAll(',', '.'),
                    );
                    if (parsed == null || parsed <= 0) {
                      setDialogState(
                        () => errorText =
                            'mkt.messages.invalidOfferAmount'.tr(),
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop(parsed);
                  },
                  child: Text('mkt.messages.sendOffer'.tr()),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      amountController.dispose();
    }

    if (mounted) setState(() => _offerDialogOpen = false);
    if (amount == null) return;
    if (!mounted) return;

    setState(() => _sending = true);
    try {
      final offer = await MarketplaceService.instance.sendOffer(
        _conversation.id,
        amount: amount,
        currency: _conversation.listingCurrency,
      );
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, offer];
        _sending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('mkt.messages.offerSent'.tr())),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    } catch (e) {
      debugPrint('[16F-D] offer_failed: $e');
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('mkt.messages.offerFailed'.tr())),
      );
    }
  }

  Future<void> _showReview() async {
    if (_reviewDialogOpen) return;
    final revieweeId = _conversation.otherUserId(_uid);
    if (revieweeId.isEmpty || _conversation.listingId.isEmpty) return;

    setState(() => _reviewDialogOpen = true);
    int rating = 5;
    final commentController = TextEditingController();
    int? submittedRating;
    try {
      submittedRating = await showDialog<int>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text('mkt.profile.writeReview'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return IconButton(
                      icon: Icon(
                        starValue <= rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AppColors.orange,
                      ),
                      onPressed: () =>
                          setDialogState(() => rating = starValue),
                    );
                  }),
                ),
                TextField(
                  controller: commentController,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'mkt.messages.startConversation'.tr(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('common.cancel'.tr()),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(rating),
                child: Text('mkt.profile.writeReview'.tr()),
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _reviewDialogOpen = false);
    }

    if (submittedRating == null || !mounted) {
      commentController.dispose();
      return;
    }

    try {
      await MarketplaceService.instance.submitReview(
        listingId: _conversation.listingId,
        conversationId: _conversation.id,
        revieweeId: revieweeId,
        rating: submittedRating,
        comment: commentController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('mkt.profile.reviewSubmitted'.tr())),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('mkt.profile.reviewFailed'.tr())),
      );
    } finally {
      commentController.dispose();
    }
  }

  Future<void> _openListing() async {
    try {
      final item =
          widget.initialItem ??
          await MarketplaceService.instance.fetchItemById(
            _conversation.listingId,
          );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MarketplaceItemDetailScreen(item: item),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('mkt.messages.listingUnavailable'.tr())),
      );
    }
  }

  Future<void> _openParticipantProfile() async {
    final otherUserId = _conversation.otherUserId(_uid);
    await openMarketplacePublicProfile(
      context: context,
      source: 'conversation',
      userId: otherUserId,
    );
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final canOffer = _uid.isNotEmpty && _uid == _conversation.buyerId;
    final canReview =
        _uid.isNotEmpty &&
        _conversation.listingId.isNotEmpty &&
        _messages.isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        titleSpacing: 0,
        title: _ParticipantHeader(
          conversation: _conversation,
          currentUserId: _uid,
          isDark: isDark,
          onTap: _openParticipantProfile,
        ),
        actions: [
          IconButton(
            tooltip: 'mkt.profile.open'.tr(),
            onPressed: _openParticipantProfile,
            icon: const Icon(Icons.person_outline_rounded),
          ),
          if (canOffer)
            IconButton(
              tooltip: 'mkt.messages.makeOffer'.tr(),
              onPressed: (_sending || _offerDialogOpen) ? null : _showOffer,
              icon: const Icon(Icons.local_offer_outlined),
            ),
          if (canReview)
            IconButton(
              tooltip: 'mkt.profile.writeReview'.tr(),
              onPressed: _reviewDialogOpen ? null : _showReview,
              icon: const Icon(Icons.star_outline_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          // Compact listing banner — only when opened from a listing detail page
          // or when this is an active marketplace conversation with a known listing.
          // Per spec: not a giant card pinned permanently at top for all contexts.
          if (_shouldShowListingBanner)
            _ListingBanner(
              conversation: _conversation,
              isDark: isDark,
              onTap: _openListing,
            ),
          Expanded(child: _buildMessages(isDark)),
          _Composer(
            controller: _controller,
            sending: _sending,
            isDark: isDark,
            onChanged: (_) => setState(() {}),
            onSend: _send,
          ),
        ],
      ),
    );
  }

  /// Show the listing banner when:
  ///   a) opened directly from a listing detail (initialItem provided), OR
  ///   b) this conversation was created from a marketplace listing (listingId set)
  ///      and it's still showing a real title (not empty/unavailable).
  bool get _shouldShowListingBanner =>
      widget.initialItem != null ||
      (_conversation.listingId.isNotEmpty &&
          _conversation.listingTitle.isNotEmpty);

  Widget _buildMessages(bool isDark) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      );
    }
    if (_error != null) {
      return _MessageState(
        icon: Icons.cloud_off_outlined,
        message: _error!,
        action: _load,
      );
    }
    if (_messages.isEmpty) {
      return _MessageState(
        icon: Icons.chat_bubble_outline_rounded,
        message: 'mkt.messages.startConversation'.tr(),
      );
    }
    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: _load,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
        itemCount: _messages.length,
        itemBuilder: (_, index) => _MessageBubble(
          message: _messages[index],
          isMine: _messages[index].senderId == _uid,
          isDark: isDark,
          onContextTap: _messages[index].context.isListing
              ? _openListing
              : null,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App bar participant header
// ---------------------------------------------------------------------------

class _ParticipantHeader extends StatelessWidget {
  final MarketplaceConversation conversation;
  final String currentUserId;
  final bool isDark;
  final VoidCallback onTap;

  const _ParticipantHeader({
    required this.conversation,
    required this.currentUserId,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherName = conversation.otherUserName(currentUserId).trim();
    final avatar = conversation.otherUserPhoto(currentUserId).trim();
    final displayName = otherName.isNotEmpty
        ? otherName
        : (currentUserId == conversation.sellerId
              ? 'mkt.messages.buyer'.tr()
              : 'mkt.messages.seller'.tr());
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.orange.withValues(alpha: .16),
              backgroundImage: avatar.startsWith('http')
                  ? CachedNetworkImageProvider(avatar)
                  : null,
              child: avatar.startsWith('http')
                  ? null
                  : const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.orange,
                      size: 19,
                    ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: isDark ? AppColors.gray : AppColors.lightGray,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact listing banner — shown only when conversation has a known listing
// ---------------------------------------------------------------------------

class _ListingBanner extends StatelessWidget {
  final MarketplaceConversation conversation;
  final bool isDark;
  final VoidCallback onTap;

  const _ListingBanner({
    required this.conversation,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.card : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white12 : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                width: 44,
                height: 44,
                child: conversation.listingImage.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: conversation.listingImage,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const _ListingIcon(),
                      )
                    : const _ListingIcon(),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.listingTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  if (conversation.listingPrice > 0)
                    Text(
                      '${conversation.listingPrice.toStringAsFixed(conversation.listingPrice % 1 == 0 ? 0 : 2)} ${conversation.listingCurrency}',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: muted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingIcon extends StatelessWidget {
  const _ListingIcon();

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.orange.withValues(alpha: .1),
    child: const Icon(Icons.shopping_bag_outlined, color: AppColors.orange, size: 20),
  );
}

// ---------------------------------------------------------------------------
// Message bubble with optional inline context card
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final MarketplaceMessage message;
  final bool isMine;
  final bool isDark;
  final VoidCallback? onContextTap;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isDark,
    this.onContextTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherBubble = isDark ? AppColors.card : AppColors.lightCard;
    final otherText = isDark ? AppColors.text : AppColors.lightText;
    final time = message.createdAt == null
        ? ''
        : DateFormat.Hm(context.locale.languageCode)
            .format(message.createdAt!.toLocal());

    return Align(
      alignment: isMine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .78,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Inline context card sits above the message it belongs to
            if (message.context.isPresent)
              _MessageContextCard(
                context: message.context,
                isMine: isMine,
                isDark: isDark,
                onTap: onContextTap,
              ),
            Container(
              margin: EdgeInsets.only(
                bottom: message.context.isPresent ? 6 : 8,
                top: message.context.isPresent ? 2 : 0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: message.isOffer
                    ? AppColors.orange.withValues(alpha: isMine ? .95 : .14)
                    : (isMine ? AppColors.orange : otherBubble),
                borderRadius: BorderRadius.circular(17),
                border: message.isOffer && !isMine
                    ? Border.all(
                        color: AppColors.orange.withValues(alpha: .45),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isOffer) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_offer_rounded,
                          size: 15,
                          color: isMine ? Colors.white : AppColors.orange,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'mkt.messages.offer'.tr(),
                          style: TextStyle(
                            color: isMine ? Colors.white : AppColors.orange,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${message.offerAmount!.toStringAsFixed(2)} ${message.offerCurrency}',
                      style: TextStyle(
                        color: isMine ? Colors.white : otherText,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ] else
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isMine ? Colors.white : otherText,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      time,
                      style: TextStyle(
                        color: isMine
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

// ---------------------------------------------------------------------------
// Compact inline context card (listing or reel attached to a message)
// ---------------------------------------------------------------------------

class _MessageContextCard extends StatelessWidget {
  final MessageContext context;
  final bool isMine;
  final bool isDark;
  final VoidCallback? onTap;

  const _MessageContextCard({
    required this.context,
    required this.isMine,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext buildContext) {
    final muted = isDark ? AppColors.gray : AppColors.lightGray;
    final cardBg = isDark
        ? AppColors.card.withValues(alpha: .9)
        : AppColors.lightCard.withValues(alpha: .9);
    final borderColor = isDark ? Colors.white12 : AppColors.lightBorder;

    final isListing = context.isListing;
    final sourceLabel = isListing
        ? 'mkt.inbox.contextListing'.tr()
        : 'mkt.inbox.contextReel'.tr();
    final sourceColor = isListing ? AppColors.orange : Colors.purple;
    final sourceIcon = isListing
        ? Icons.shopping_bag_outlined
        : Icons.play_circle_outline_rounded;

    final titleText = context.contextTitle.isNotEmpty
        ? context.contextTitle
        : sourceLabel;
    final thumbUrl = context.contextThumbnailUrl;
    final price = context.contextPrice;
    final currency = context.contextCurrency;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail or icon
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                width: 36,
                height: 36,
                child: thumbUrl.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: thumbUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            _ContextIconPlaceholder(icon: sourceIcon, color: sourceColor),
                      )
                    : _ContextIconPlaceholder(icon: sourceIcon, color: sourceColor),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source label chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: sourceColor.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      sourceLabel,
                      style: TextStyle(
                        color: sourceColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    titleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? AppColors.text : AppColors.lightText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isListing && price != null && price > 0)
                    Text(
                      '${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)} $currency',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: muted, size: 15),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContextIconPlaceholder extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _ContextIconPlaceholder({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    color: color.withValues(alpha: .1),
    child: Icon(icon, color: color, size: 18),
  );
}

// ---------------------------------------------------------------------------
// Composer
// ---------------------------------------------------------------------------

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  const _Composer({
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
                maxLength: 1000,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'mkt.messages.typeMessage'.tr(),
                  counterText: '',
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

// ---------------------------------------------------------------------------
// Loading / error state
// ---------------------------------------------------------------------------

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? action;

  const _MessageState({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.orange, size: 46),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
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
