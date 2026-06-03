import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/global_deal_model.dart';
import '../services/ai_brain_api_service.dart';
import 'widgets/discount_truth_card.dart';
import 'widgets/global_alternative_card.dart';
import 'widgets/human_specs_card.dart';
import 'widgets/negotiation_bottom_sheet.dart';
import 'widgets/verdict_card.dart';

class AiResultDashboard extends StatefulWidget {
  final AiBrainApiService apiService;
  final ProductInput product;
  final UserContext user;
  final String? productUrl;
  const AiResultDashboard({
    super.key,
    required this.apiService,
    required this.product,
    required this.user,
    this.productUrl,
  });
  @override
  State<AiResultDashboard> createState() => _AiResultDashboardState();
}

class _AiResultDashboardState extends State<AiResultDashboard> {
  bool _loading = true;
  String? _error;
  GlobalDealAnalysis? _analysis;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result =
          widget.productUrl != null && widget.productUrl!.trim().isNotEmpty
          ? await widget.apiService.analyzeUrl(
              url: widget.productUrl!.trim(),
              userCountry: widget.user.country,
              userCurrency: widget.user.currency,
              language: widget.user.language,
            )
          : await widget.apiService.analyzeGlobal(
              product: widget.product,
              user: widget.user,
            );
      if (!mounted) return;
      setState(() {
        _analysis = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openNegotiator(GlobalDealAnalysis analysis) async {
    String script = analysis.negotiation.script;
    try {
      script = await widget.apiService.generateNegotiationScript(
        product: widget.product,
        analysis: analysis,
      );
    } catch (_) {}
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => NegotiationBottomSheet(
        script: script,
        sellerLanguage: analysis.negotiation.sellerLanguage,
        targetPrice: analysis.negotiation.targetPrice.format(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  product: widget.product,
                  loading: _loading,
                  onRetry: _load,
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(error: _error!, onRetry: _load),
                )
              else if (_analysis != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      VerdictCard(data: _analysis!.verdictCard),
                      const SizedBox(height: 14),
                      DiscountTruthCard(data: _analysis!.discountCurrencyCard),
                      const SizedBox(height: 14),
                      HumanSpecsCard(data: _analysis!.humanSpecsCard),
                      const SizedBox(height: 14),
                      GlobalAlternativeCard(
                        data: _analysis!.globalAlternativeCard,
                      ),
                      if (_analysis!.negotiation.shouldShowButton) ...[
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () => _openNegotiator(_analysis!),
                          icon: const Icon(Icons.handshake_rounded),
                          label: Text('auto_sweep.screens_ai_result_dashboard.get_a_better_deal'.tr()),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ProductInput product;
  final bool loading;
  final VoidCallback onRetry;
  const _Header({
    required this.product,
    required this.loading,
    required this.onRetry,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF111827), Color(0xFF1F2937)],
      ),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('auto.ai_brain_ai_deal_brain_screen.ai_deal_brain_pro'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: loading ? null : onRetry,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          product.title.isEmpty ? 'Global deal analysis' : product.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${product.store} · ${product.currentPrice.toStringAsFixed(2)} ${product.baseCurrency}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .78),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.black38),
        const SizedBox(height: 16),
        Text('auto_sweep.screens_ai_result_dashboard.could_not_analyze_this_deal'.tr(),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, height: 1.45),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text('auto_sweep.screens_ai_result_dashboard.try_again'.tr()),
        ),
      ],
    ),
  );
}
