import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/mystery_box_model.dart';
import '../../services/mystery_box_service.dart';

class MysteryBoxScreen extends StatefulWidget {
  MysteryBoxScreen({super.key});

  @override
  State<MysteryBoxScreen> createState() => _MysteryBoxScreenState();
}

class _MysteryBoxScreenState extends State<MysteryBoxScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  MysteryBoxModel? box;
  MysteryRewardModel? reward;
  bool loading = true;
  bool opening = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await MysteryBoxService.instance.today();
      if (!mounted) return;
      setState(() {
        box = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _openBox() async {
    if (opening) return;
    setState(() => opening = true);
    HapticFeedback.heavyImpact();
    await _controller.forward(from: 0);
    try {
      final data = await MysteryBoxService.instance.open(unlockMethod: 'shake');
      await HapticFeedback.vibrate();
      if (!mounted) return;
      setState(() {
        reward = data;
        opening = false;
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => opening = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _claim() async {
    final r = reward;
    if (r == null) return;
    await MysteryBoxService.instance.claim(r.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('auto.mystery_box_mystery_box_screen.reward_claimed'.tr(),
        ),
      ),
    );
  }

  Future<void> _openDeal() async {
    final url = reward?.dealUrl ?? '';
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Color(0xFFF8F9FA),
        title: Text('auto.mystery_box_mystery_box_screen.blind_deal_box'.tr(),
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(18, 12, 18, 120),
                children: [
                  _Hero(box: box),
                  SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final shake =
                          math.sin(_controller.value * math.pi * 10) * 8;
                      return Transform.translate(
                        offset: Offset(shake, 0),
                        child: child,
                      );
                    },
                    child: _BoxCard(
                      opening: opening,
                      opened: box?.isOpened == true || reward != null,
                    ),
                  ),
                  SizedBox(height: 18),
                  if (error != null)
                    _InfoCard(text: error!, icon: Icons.error_outline_rounded),
                  if (reward == null) ...[
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: (box?.canOpen == true && !opening)
                            ? _openBox
                            : null,
                        icon: Icon(
                          opening
                              ? Icons.hourglass_top_rounded
                              : Icons.vibration_rounded,
                        ),
                        label: Text(
                          opening
                              ? 'Opening...'
                              : box?.isOpened == true
                              ? 'Already opened today'
                              : 'Shake / Open today',
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.security_rounded,
                      text:
                          'One secured reward per day. Server decides the reward, not the app.',
                    ),
                  ] else ...[
                    _RewardCard(reward: reward!),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _claim,
                            icon: Icon(Icons.check_circle_rounded),
                            label: Text('auto.mystery_box_mystery_box_screen.claim'.tr(),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openDeal,
                            icon: Icon(Icons.open_in_new_rounded),
                            label: Text('auto.mystery_box_mystery_box_screen.open'.tr(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(
                          text: reward!.shareText.isEmpty
                              ? reward!.title
                              : reward!.shareText,
                          subject: reward!.title,
                        ),
                      ),
                      icon: Icon(Icons.ios_share_rounded),
                      label: Text('auto.mystery_box_mystery_box_screen.share_my_box'.tr(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _Hero extends StatelessWidget {
  _Hero({required this.box});
  final MysteryBoxModel? box;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF141414), Color(0xFF37220F), Color(0xFFFF7A1A)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.inventory_2_rounded, color: Colors.white, size: 44),
          SizedBox(height: 12),
          Text(
            box?.title ?? 'Blind Deal Box',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            box?.subtitle ?? 'Tu hamza secreta diaria.',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Daily streak: ${box?.streak ?? 0} 🔥',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _BoxCard extends StatelessWidget {
  _BoxCard({required this.opening, required this.opened});
  final bool opening;
  final bool opened;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              opened ? Icons.lock_open_rounded : Icons.card_giftcard_rounded,
              color: AppColors.orange,
              size: opening ? 86 : 96,
            ),
            SizedBox(height: 14),
            Text(
              opened ? 'Box revealed' : 'Secret deal inside',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 5),
            Text('auto.mystery_box_mystery_box_screen.open_once_per_day'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  _RewardCard({required this.reward});
  final MysteryRewardModel reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('auto.mystery_box_mystery_box_screen.you_got'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 6),
          Text(
            reward.title,
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            reward.description,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10),
          Text(
            reward.valueLabel,
            style: TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (reward.couponCode.isNotEmpty) ...[
            SizedBox(height: 10),
            SelectableText(
              'Code: ${reward.couponCode}',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  _InfoCard({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
