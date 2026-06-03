import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../core/errors/app_exception.dart';
import '../core/theme/app_theme.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';

/// Self-contained Daily AI Hunt section for the Home screen.
///
/// * Deferred load: uses [addPostFrameCallback] so Home renders
///   instantly before the AI request fires.
/// * Isolated failure: any exception sets an error state and never
///   propagates to the parent widget tree.
/// * No fake data: only displays what the backend returns.
class DailyAiHuntSection extends StatefulWidget {
  const DailyAiHuntSection({super.key});

  @override
  State<DailyAiHuntSection> createState() => _DailyAiHuntSectionState();
}

enum _HuntStatus { idle, loading, loaded, empty, notConfigured, unavailable }

class _DailyAiHuntSectionState extends State<DailyAiHuntSection> {
  final AiService _ai = AiService.instance;
  final SettingsService _settings = SettingsService.instance;

  _HuntStatus _status = _HuntStatus.idle;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    // Defer so Home product feed renders first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    if (_status == _HuntStatus.loading) return;
    if (mounted) setState(() => _status = _HuntStatus.loading);
    try {
      final country = await _settings.getCountry();
      final currency = await _settings.getCurrency();
      final language = await _settings.getLanguage();
      final result = await _ai.dailyHunt(
        countryCode: country,
        currency: currency,
        language: language,
      );
      if (!mounted) return;
      if (result.dailyHunt.isEmpty) {
        setState(() => _status = _HuntStatus.empty);
      } else {
        setState(() {
          _items = result.dailyHunt;
          _status = _HuntStatus.loaded;
        });
      }
    } on PaymentRequiredException {
      // Treat quota issues as unavailable — don't surface payment flows here.
      if (mounted) setState(() => _status = _HuntStatus.unavailable);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _status = e.code == 'AI_NOT_CONFIGURED'
          ? _HuntStatus.notConfigured
          : _HuntStatus.unavailable);
    } catch (_) {
      if (mounted) setState(() => _status = _HuntStatus.unavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hide section entirely when idle or not configured to keep Home clean.
    if (_status == _HuntStatus.idle ||
        _status == _HuntStatus.notConfigured) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(onRetry: _canRetry ? _load : null),
        const SizedBox(height: 10),
        _body(),
        const SizedBox(height: 4),
      ],
    );
  }

  bool get _canRetry =>
      _status == _HuntStatus.unavailable || _status == _HuntStatus.empty;

  Widget _body() {
    switch (_status) {
      case _HuntStatus.loading:
        return const _LoadingRow();
      case _HuntStatus.loaded:
        return _HuntList(items: _items);
      case _HuntStatus.empty:
        return _StateBox(
          icon: Icons.search_off_rounded,
          text: 'home.aiHunt.empty'.tr(),
          canRetry: true,
          onRetry: _load,
        );
      case _HuntStatus.unavailable:
        return _StateBox(
          icon: Icons.cloud_off_rounded,
          text: 'home.aiHunt.unavailable'.tr(),
          canRetry: true,
          onRetry: _load,
        );
      case _HuntStatus.idle:
      case _HuntStatus.notConfigured:
        return const SizedBox.shrink();
    }
  }
}

// ─── Section header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final VoidCallback? onRetry;

  const _SectionHeader({this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: AppColors.logoGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'home.aiHunt.title'.tr(),
                style: const TextStyle(
                  color: Color(0xFF1E2022),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (onRetry != null)
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'home.aiHunt.retry'.tr(),
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECEF)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 120,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'home.aiHunt.loading'.tr(),
                    style: const TextStyle(
                      color: Color(0xFF9AA1AA),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hunt item list ───────────────────────────────────────────────────────────

class _HuntList extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _HuntList({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _HuntCard(item: items[index]),
      ),
    );
  }
}

class _HuntCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _HuntCard({required this.item});

  String get _title {
    final t = item['title']?.toString().trim() ?? '';
    return t.isNotEmpty ? t : (item['name']?.toString().trim() ?? '—');
  }

  String get _summary {
    final s = item['summary']?.toString().trim() ?? '';
    if (s.isNotEmpty) return s;
    return item['brutalTruth']?.toString().trim() ?? '';
  }

  String get _verdict => item['verdict']?.toString().trim() ?? '';

  int get _score {
    final v = item['score'];
    if (v is int) return v.clamp(0, 100);
    if (v is num) return v.round().clamp(0, 100);
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  Color get _verdictColor {
    switch (_verdict) {
      case 'buy_now':
      case 'hidden_gem':
        return const Color(0xFF16A34A);
      case 'avoid':
      case 'fake_discount':
        return const Color(0xFFDC2626);
      default:
        return AppColors.orange;
    }
  }

  String get _verdictLabel {
    final keys = {
      'buy_now': 'ai.badge.buyNow',
      'wait': 'ai.badge.wait',
      'avoid': 'ai.badge.avoid',
      'fake_discount': 'ai.badge.fakeDiscount',
      'hidden_gem': 'ai.badge.hiddenGem',
      'watch_price': 'ai.badge.watchPrice',
      'better_alternative': 'ai.badge.betterAlternative',
    };
    final key = keys[_verdict];
    if (key == null) return _verdict.replaceAll('_', ' ').toUpperCase();
    return key.tr().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _verdictColor;
    final score = _score;
    final summary = _summary;

    return Container(
      width: 210,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verdict badge + score
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _verdictLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (score > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '$score',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
              const Spacer(),
              const Icon(Icons.psychology_alt_rounded, color: AppColors.orange, size: 14),
            ],
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            _title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1E2022),
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          // Summary (if available)
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7C848E),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ] else
            const Spacer(),
        ],
      ),
    );
  }
}

// ─── State box (empty / unavailable) ─────────────────────────────────────────

class _StateBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool canRetry;
  final VoidCallback? onRetry;

  const _StateBox({
    required this.icon,
    required this.text,
    required this.canRetry,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9AA1AA), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF7C848E),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (canRetry && onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'home.aiHunt.retry'.tr(),
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
