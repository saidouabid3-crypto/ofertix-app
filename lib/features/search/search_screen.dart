import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../widgets/ai_search_bar.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/product_grid_card.dart';
import '../product_details/product_details_screen.dart';
import 'search_provider.dart';

class SearchScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialCategoryLabel;
  final String? initialQuery;
  final List<Product> initialResults;

  const SearchScreen({
    super.key,
    this.initialCategory,
    this.initialCategoryLabel,
    this.initialQuery,
    this.initialResults = const [],
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  static const List<String> _trendingFallback = [
    'iPhone', 'Gaming Laptop', 'AirPods', 'Smart TV', 'Nike', 'PlayStation', 'Smartwatch',
  ];

  static const List<String> _categoryChips = [
    '🔥 Trending', '📱 Tech', '🎮 Gaming', '👟 Fashion', '🏠 Home', '💄 Beauty', '🛒 Market',
  ];

  SearchProvider? _provider;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery ?? '';
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    _provider?.onQueryChanged(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _doSearch(BuildContext context, String query) {
    if (query.trim().isEmpty) return;
    context.read<SearchProvider>().search(query);
  }

  void _onChipTap(BuildContext context, String term) {
    _controller.text = term;
    _doSearch(context, term);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final p = SearchProvider();
        p.setInitialResults(widget.initialResults);
        if (widget.initialCategory != null) {
          p.selectedCategory = widget.initialCategory;
        }
        _provider = p;
        return p;
      },
      child: Consumer<SearchProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Header ──────────────────────────────────────────
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'search.smartTitle'.tr(),
                                style: const TextStyle(
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'search.headlineTitle'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Search bar ───────────────────────────────────────
                        AISearchBar(
                          controller: _controller,
                          onSubmitted: (v) => _doSearch(context, v),
                          onAiTap: () => _doSearch(context, _controller.text),
                        ),
                        const SizedBox(height: 14),

                        // ── Category chips ───────────────────────────────────
                        SizedBox(
                          height: 46,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categoryChips.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (_, i) => CategoryChip(
                              category: _categoryChips[i],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ── Suggestions ──────────────────────────────────────
                        if (provider.suggestions.isNotEmpty) ...[
                          Text(
                            'search.suggestions'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: provider.suggestions.map((s) {
                              return _SearchChip(
                                label: s,
                                icon: Icons.search_rounded,
                                color: AppColors.orange,
                                onTap: () => _onChipTap(context, s),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ── Recent searches ──────────────────────────────────
                        if (provider.recentSearches.isNotEmpty &&
                            _controller.text.trim().isEmpty) ...[
                          Row(
                            children: [
                              Text(
                                'search.recentSearches'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: provider.clearRecentSearches,
                                child: Text(
                                  'search.clearRecent'.tr(),
                                  style: const TextStyle(
                                    color: AppColors.gray,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: provider.recentSearches.map((s) {
                              return _SearchChip(
                                label: s,
                                icon: Icons.history_rounded,
                                onTap: () => _onChipTap(context, s),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ]

                        // ── Trending fallback ────────────────────────────────
                        else if (provider.results.isEmpty &&
                            !provider.isLoading &&
                            provider.suggestions.isEmpty) ...[
                          Row(
                            children: [
                              Text(
                                'search.trendingSearches'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_trendingFallback.length} hot',
                                style: const TextStyle(color: AppColors.gray),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _trendingFallback.map((s) {
                              return _SearchChip(
                                label: s,
                                icon: Icons.local_fire_department_rounded,
                                color: AppColors.redOrange,
                                onTap: () => _onChipTap(context, s),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // ── Filter bar ───────────────────────────────────────
                        if (provider.results.isNotEmpty) ...[
                          _FilterBar(provider: provider),
                          const SizedBox(height: 14),
                        ],

                        // ── Results header ───────────────────────────────────
                        Row(
                          children: [
                            Text(
                              'search.resultsHeader'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            if (provider.results.isNotEmpty)
                              Text(
                                'search.resultsFound'
                                    .tr(namedArgs: {'total': provider.results.length.toString()}),
                                style: const TextStyle(
                                  color: AppColors.gray,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ]),
                    ),
                  ),

                  // ── Loading ─────────────────────────────────────────────
                  if (provider.isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.orange),
                      ),
                    )

                  // ── Error ───────────────────────────────────────────────
                  else if (provider.isError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wifi_off_rounded,
                                  color: AppColors.gray, size: 44),
                              const SizedBox(height: 14),
                              Text(
                                'search.searchFailed'.tr(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.gray,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )

                  // ── Empty (searched, no results) ────────────────────────
                  else if (provider.results.isEmpty && _controller.text.trim().isNotEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off_rounded,
                                  color: AppColors.gray, size: 44),
                              const SizedBox(height: 14),
                              Text(
                                'search.noResultsTitle'.tr(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'search.noResultsSubtitle'.tr(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.gray,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )

                  // ── Empty (no search yet) ───────────────────────────────
                  else if (provider.results.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            'search.placeholderSmart'.tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.gray,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    )

                  // ── Results grid ────────────────────────────────────────
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = provider.results[index];
                            return ProductGridCard(
                              product: product,
                              isFavorite: false,
                              onFavorite: () {},
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailsScreen(product: product),
                                ),
                              ),
                            );
                          },
                          childCount: provider.results.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.68,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Search chip ─────────────────────────────────────────────────────────────

class _SearchChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SearchChip({
    required this.label,
    required this.icon,
    this.color = const Color(0xFF7C848E),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final SearchProvider provider;

  const _FilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Trusted only toggle
          _FilterChip(
            label: 'search.trustedOnly'.tr(),
            icon: Icons.verified_rounded,
            active: provider.trustedOnly,
            onTap: () => provider.setTrustedOnly(!provider.trustedOnly),
          ),
          const SizedBox(width: 8),
          // Min discount 30%+
          _FilterChip(
            label: 'search.minDiscount30'.tr(),
            icon: Icons.local_offer_rounded,
            active: (provider.minDiscount ?? 0) >= 30,
            onTap: () => provider.setMinDiscount(
              (provider.minDiscount ?? 0) >= 30 ? null : 30,
            ),
          ),
          const SizedBox(width: 8),
          // Sort: discount
          _FilterChip(
            label: 'search.sortDiscount'.tr(),
            icon: Icons.arrow_downward_rounded,
            active: provider.sortMode == 'discount_desc',
            onTap: () => provider.setSortMode(
              provider.sortMode == 'discount_desc' ? 'smart' : 'discount_desc',
            ),
          ),
          const SizedBox(width: 8),
          // Sort: price low to high
          _FilterChip(
            label: 'search.sortPriceAsc'.tr(),
            icon: Icons.euro_rounded,
            active: provider.sortMode == 'price_asc',
            onTap: () => provider.setSortMode(
              provider.sortMode == 'price_asc' ? 'smart' : 'price_asc',
            ),
          ),
          const SizedBox(width: 8),
          // Clear all
          if (provider.trustedOnly ||
              provider.minDiscount != null ||
              provider.sortMode != 'smart')
            _FilterChip(
              label: 'search.clearFilters'.tr(),
              icon: Icons.clear_rounded,
              active: false,
              onTap: provider.clearFilters,
              danger: true,
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool danger;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = danger
        ? Colors.red.withValues(alpha: 0.12)
        : active
            ? AppColors.orange.withValues(alpha: 0.18)
            : AppColors.card;
    final fg = danger
        ? Colors.red
        : active
            ? AppColors.orange
            : AppColors.gray;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.orange.withValues(alpha: 0.40) : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
