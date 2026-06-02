import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_theme.dart';
import '../../models/ai_brain_model.dart';
import '../../services/ai_brain_service.dart';

class AIDealBrainScreen extends StatefulWidget {
  AIDealBrainScreen({
    super.key,
    this.initialQuery,
    this.initialTitle,
    this.initialStore,
    this.initialCurrentPrice,
    this.initialOldPrice,
    this.initialSpecs,
  });

  final String? initialQuery;
  final String? initialTitle;
  final String? initialStore;
  final double? initialCurrentPrice;
  final double? initialOldPrice;
  final String? initialSpecs;

  @override
  State<AIDealBrainScreen> createState() => _AIDealBrainScreenState();
}

class _AIDealBrainScreenState extends State<AIDealBrainScreen> {
  final queryController = TextEditingController();
  final titleController = TextEditingController();
  final storeController = TextEditingController();
  final currentController = TextEditingController();
  final oldController = TextEditingController();
  final specsController = TextEditingController();

  bool loading = false;
  String? aiErrorKey;
  AIBrainResponseModel? result;

  @override
  void initState() {
    super.initState();
    queryController.text = widget.initialQuery ?? '';
    titleController.text = widget.initialTitle ?? '';
    storeController.text = widget.initialStore ?? '';
    currentController.text = widget.initialCurrentPrice == null
        ? ''
        : widget.initialCurrentPrice!.toStringAsFixed(2);
    oldController.text = widget.initialOldPrice == null
        ? ''
        : widget.initialOldPrice!.toStringAsFixed(2);
    specsController.text = widget.initialSpecs ?? '';
  }

  void _refreshInputState() {
    // WHY: Keep the input widget decoupled from the private State class and
    // avoid calling protected setState from a child widget.
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    queryController.dispose();
    titleController.dispose();
    storeController.dispose();
    currentController.dispose();
    oldController.dispose();
    specsController.dispose();
    super.dispose();
  }

  double? _money(String value) {
    var raw = value
        .trim()
        .replaceAll('€', '')
        .replaceAll(r'$', '')
        .replaceAll('EUR', '')
        .replaceAll('USD', '')
        .replaceAll(' ', '');
    if (raw.contains(',') && raw.contains('.')) {
      raw = raw.replaceAll('.', '').replaceAll(',', '.');
    } else {
      raw = raw.replaceAll(',', '.');
    }
    return double.tryParse(raw);
  }

  double get _currentPrice => _money(currentController.text) ?? 0;
  double get _oldPrice => _money(oldController.text) ?? 0;

  double get _discountPercent {
    final current = _currentPrice;
    final old = _oldPrice;
    if (old <= 0 || current <= 0 || current >= old) return 0;
    return ((old - current) / old) * 100;
  }

  String get _autoQuery {
    final query = queryController.text.trim();
    if (query.isNotEmpty) return query;
    final title = titleController.text.trim();
    if (title.isNotEmpty)
      return 'Analyze this deal and tell me if I should buy, wait, or avoid: $title';
    return '';
  }

  bool get _canAnalyze =>
      !loading &&
      (_autoQuery.isNotEmpty || titleController.text.trim().isNotEmpty);

  void _fillExample(_BrainExample example) {
    setState(() {
      queryController.text = example.query;
      titleController.text = example.title;
      currentController.text = example.currentPrice;
      oldController.text = example.oldPrice;
      storeController.text = example.store;
      specsController.text = example.specs;
      result = null;
      aiErrorKey = null;
    });
  }

  Future<void> _ask() async {
    if (!_canAnalyze) return;
    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      aiErrorKey = null;
    });

    try {
      final response = await AIBrainService.instance.analyzeDeal(
        query: _autoQuery,
        title: titleController.text.trim().isEmpty
            ? null
            : titleController.text.trim(),
        store: storeController.text.trim().isEmpty
            ? null
            : storeController.text.trim(),
        currentPrice: _money(currentController.text),
        oldPrice: _money(oldController.text),
        specs: specsController.text.trim().isEmpty
            ? null
            : specsController.text.trim(),
      );
      if (!mounted) return;
      setState(() => result = response);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        result = null;
        aiErrorKey = 'ai.error.notConfigured';
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.lightBackground;
    final text = isDark ? AppColors.text : AppColors.lightText;
    final muted = isDark ? AppColors.gray : AppColors.lightGray;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'auto.ai_brain_ai_deal_brain_screen.ai_deal_brain_pro'.tr(),
          style: TextStyle(fontWeight: FontWeight.w900, color: text),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(18, 12, 18, 120),
        children: [
          _HeroBrainCard(discount: _discountPercent),
          SizedBox(height: 14),
          _TrustRow(
            discount: _discountPercent,
            current: _currentPrice,
            old: _oldPrice,
          ),
          SizedBox(height: 16),
          Text(
            'auto.ai_brain_ai_deal_brain_screen.quick_tests'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: text,
            ),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _examples
                .map(
                  (e) => ActionChip(
                    label: Text(e.label),
                    onPressed: () => _fillExample(e),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 16),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  icon: Icons.shopping_bag_rounded,
                  title: 'aiBrain.dealDetails'.tr(),
                  subtitle: 'aiBrain.dealDetailsSubtitle'.tr(),
                ),
                SizedBox(height: 12),
                _Input(
                  controller: queryController,
                  label: 'aiBrain.question'.tr(),
                  hint: 'Example: Is this offer good or fake?',
                  maxLines: 2,
                  onChanged: _refreshInputState,
                ),
                SizedBox(height: 10),
                _Input(
                  controller: titleController,
                  label: 'aiBrain.productTitle'.tr(),
                  hint: 'iPhone 15 128GB / Sneakers / Air fryer',
                  onChanged: _refreshInputState,
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _Input(
                        controller: currentController,
                        label: 'product.currentPrice'.tr(),
                        hint: '699',
                        keyboardType: TextInputType.number,
                        onChanged: _refreshInputState,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _Input(
                        controller: oldController,
                        label:
                            'auto.community_user_generated_deals_screen.old_price'
                                .tr(),
                        hint: '849',
                        keyboardType: TextInputType.number,
                        onChanged: _refreshInputState,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                _Input(
                  controller: storeController,
                  label: 'aiBrain.store'.tr(),
                  hint: 'aiBrain.storeHint'.tr(),
                  onChanged: _refreshInputState,
                ),
                SizedBox(height: 10),
                _Input(
                  controller: specsController,
                  label: 'aiBrain.specsNotes'.tr(),
                  hint: '128GB, warranty, material, size, model...',
                  maxLines: 2,
                  onChanged: _refreshInputState,
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _canAnalyze ? _ask : null,
              icon: loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.auto_awesome_rounded),
              label: Text(
                loading
                    ? 'aiBrain.analyzing'.tr()
                    : 'aiBrain.analyzeLikePro'.tr(),
              ),
            ),
          ),
          if (!_canAnalyze && !loading) ...[
            SizedBox(height: 8),
            Text(
              'auto.ai_brain_ai_deal_brain_screen.add_a_question_or_product_title_to_sta'
                  .tr()
                  .tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
          ],
          if (aiErrorKey != null) ...[
            SizedBox(height: 12),
            _NoticeCard(text: aiErrorKey!.tr()),
          ],
          if (result != null) ...[
            SizedBox(height: 18),
            _ResultCard(result: result!),
          ],
        ],
      ),
    );
  }
}

class _HeroBrainCard extends StatelessWidget {
  _HeroBrainCard({required this.discount});
  final double discount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.logoGradient,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology_alt_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          SizedBox(height: 18),
          Text(
            'auto.ai_brain_ai_deal_brain_screen.ask_before_buying'.tr(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'auto.ai_brain_ai_deal_brain_screen.fake_discount_check_buy_wait_avoid_spe'
                .tr()
                .tr(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
          if (discount > 0) ...[
            SizedBox(height: 14),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Detected discount: ${discount.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  _TrustRow({required this.discount, required this.current, required this.old});
  final double discount;
  final double current;
  final double old;

  @override
  Widget build(BuildContext context) {
    final discountText = discount > 0
        ? '${discount.toStringAsFixed(0)}%'
        : 'Add prices';
    final priceText = current > 0 && old > 0
        ? '${(old - current).toStringAsFixed(2)}€ saved'
        : 'No price data';
    return Row(
      children: [
        Expanded(
          child: _MiniMetric(
            icon: Icons.percent_rounded,
            label: 'aiBrain.discount'.tr(),
            value: discountText,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MiniMetric(
            icon: Icons.savings_rounded,
            label: 'aiBrain.saving'.tr(),
            value: priceText,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MiniMetric(
            icon: Icons.verified_user_rounded,
            label: 'aiBrain.check'.tr(),
            value: 'aiBrain.riskTrust'.tr(),
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  _MiniMetric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : AppColors.lightCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.border : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.gray : AppColors.lightGray,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? AppColors.text : AppColors.lightText,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : AppColors.lightCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.border : AppColors.lightBorder,
        ),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: isDark ? AppColors.text : AppColors.lightText,
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: isDark ? AppColors.gray : AppColors.lightGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Input extends StatelessWidget {
  _Input({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback onChanged;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: isDark ? AppColors.input : AppColors.lightCard2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: isDark ? AppColors.border : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  _NoticeCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_rounded, color: AppColors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  _ResultCard({required this.result});
  final AIBrainResponseModel result;

  Color get _color {
    final verdict = result.verdict.toLowerCase();
    if (verdict.contains('buy')) return AppColors.green;
    if (verdict.contains('wait') ||
        verdict.contains('compare') ||
        verdict.contains('verify'))
      return AppColors.orange;
    if (verdict.contains('avoid')) return AppColors.red;
    return AppColors.primary;
  }

  IconData get _icon {
    final verdict = result.verdict.toLowerCase();
    if (verdict.contains('buy')) return Icons.check_circle_rounded;
    if (verdict.contains('avoid')) return Icons.dangerous_rounded;
    if (verdict.contains('wait')) return Icons.schedule_rounded;
    return Icons.manage_search_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.text : AppColors.lightText;
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.card : AppColors.lightCard,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _color.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.10),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: _color, size: 30),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.verdict.toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _color,
                      ),
                    ),
                    Text(
                      result.bestAction,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.gray : AppColors.lightGray,
                      ),
                    ),
                  ],
                ),
              ),
              _ScoreRing(score: result.score, color: _color),
            ],
          ),
          SizedBox(height: 14),
          Text(
            result.summary,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              height: 1.4,
              color: text,
            ),
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill('Confidence ${result.confidence}%'),
              _Pill('Risk ${result.riskLevel}'),
              _Pill('Fake discount ${result.fakeDiscountRisk}'),
              _Pill('Price ${result.priceSignal}'),
              if (result.savingsEstimate > 0)
                _Pill('Save ${result.savingsEstimate.toStringAsFixed(2)}€'),
            ],
          ),
          SizedBox(height: 16),
          _ListBlock(title: 'aiBrain.whyVerdict'.tr(), items: result.reasons),
          _ListBlock(
            title: 'aiBrain.nextSteps'.tr(),
            items: result.suggestions,
          ),
          if (result.alternatives.isNotEmpty)
            _ListBlock(
              title: 'aiBrain.alternatives'.tr(),
              items: result.alternatives,
            ),
          if (result.specsExplained.isNotEmpty)
            _ListBlock(
              title: 'aiBrain.specsExplained'.tr(),
              items: result.specsExplained,
            ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  _ScoreRing({required this.score, required this.color});
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: (score.clamp(0, 100)) / 100,
            strokeWidth: 6,
            color: color,
            backgroundColor: color.withValues(alpha: 0.14),
          ),
          Text(
            '$score',
            style: TextStyle(fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  _Pill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

class _ListBlock extends StatelessWidget {
  _ListBlock({required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: isDark ? AppColors.text : AppColors.lightText,
            ),
          ),
          SizedBox(height: 8),
          ...items.map((s) => _Bullet(s)),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: isDark ? AppColors.gray : AppColors.lightGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrainExample {
  _BrainExample({
    required this.label,
    required this.query,
    required this.title,
    required this.currentPrice,
    required this.oldPrice,
    required this.store,
    required this.specs,
  });
  final String label;
  final String query;
  final String title;
  final String currentPrice;
  final String oldPrice;
  final String store;
  final String specs;
}

final _examples = <_BrainExample>[
  _BrainExample(
    label: 'iPhone deal',
    query: 'Is this iPhone deal real or should I wait?',
    title: 'iPhone 15 128GB',
    currentPrice: '699',
    oldPrice: '849',
    store: 'Amazon',
    specs: '128GB, new, warranty included',
  ),
  _BrainExample(
    label: 'DHgate product',
    query: 'Is this marketplace product safe to buy?',
    title: 'Sneakers Korean version',
    currentPrice: '18.95',
    oldPrice: '43.35',
    store: 'DHgate',
    specs: 'No brand warranty, international shipping',
  ),
  _BrainExample(
    label: 'Small discount',
    query: 'Should I buy now or wait?',
    title: 'Air fryer 5L',
    currentPrice: '74.99',
    oldPrice: '89.99',
    store: 'MediaMarkt',
    specs: '5L, 1500W, 2 years warranty',
  ),
];
