import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/premium_upgrade_bottom_sheet.dart';
import '../../models/product.dart';
import '../product_details/product_details_screen.dart';
import 'ai_assistant_provider.dart';

class AIAssistantScreen extends StatefulWidget {
  AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final List<String> promptKeys = [
    'aiAssistant.prompts.iphoneCheap',
    'aiAssistant.prompts.bestValueHeadphones',
    'aiAssistant.prompts.gamingLaptop',
    'aiAssistant.prompts.cheapSmartwatch',
    'aiAssistant.prompts.compareStores',
    'aiAssistant.prompts.nearbyStores',
  ];

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> search(BuildContext context, String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    controller.clear();

    try {
      await context.read<AIAssistantProvider>().search(query);
      _scrollToBottom();
    } on PaymentRequiredException catch (e) {
      if (!context.mounted) return;
      await PremiumUpgradeBottomSheet.show(
        context,
        message: e.message,
        dailyLimit: e.limit,
        used: e.used,
        resetsAt: e.resetsAt,
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> openProduct(BuildContext context, Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
    );
  }

  Future<void> openVoiceSearch(BuildContext context) async {
    final result = await Navigator.pushNamed(context, '/voice-search');
    if (!context.mounted) return;

    if (result is String && result.trim().isNotEmpty) {
      await search(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AIAssistantProvider(),
      child: Consumer<AIAssistantProvider>(
        builder: (context, provider, child) {
          final ui = _AiUi.of(context);

          return Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: ui.background,
            body: Container(
              decoration: BoxDecoration(gradient: ui.gradient),
              child: SafeArea(
                child: Column(
                  children: [
                    _CompactHeader(
                      ui: ui,
                      hasMessages: provider.hasMessages,
                      onClear: provider.clear,
                    ),
                    _PromptStrip(
                      ui: ui,
                      promptKeys: promptKeys,
                      onTap: (promptKey) => search(context, promptKey.tr()),
                    ),
                    Expanded(
                      child: provider.messages.isEmpty
                          ? _EmptyState(
                              ui: ui,
                              onExampleTap: (value) => search(context, value),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                14,
                                18,
                                18,
                              ),
                              itemCount:
                                  provider.messages.length +
                                  (provider.isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (provider.isLoading &&
                                    index == provider.messages.length) {
                                  return _ThinkingBubble(ui: ui);
                                }

                                final message = provider.messages[index];
                                return _MessageBubble(
                                  ui: ui,
                                  message: message,
                                  onSuggestionTap: (value) =>
                                      search(context, value),
                                  onProductTap: (product) =>
                                      openProduct(context, product),
                                );
                              },
                            ),
                    ),
                    _BottomComposer(
                      ui: ui,
                      controller: controller,
                      isLoading: provider.isLoading,
                      onSend: () => search(context, controller.text),
                      onSubmitted: (value) => search(context, value),
                      onVoiceTap: () => openVoiceSearch(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AiUi {
  final bool isDark;
  final Color background;
  final Color surface;
  final Color surfaceSoft;
  final Color text;
  final Color muted;
  final Color border;
  final Color shadow;
  final LinearGradient gradient;

  const _AiUi({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceSoft,
    required this.text,
    required this.muted,
    required this.border,
    required this.shadow,
    required this.gradient,
  });

  factory _AiUi.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _AiUi(
      isDark: isDark,
      background: isDark ? AppColors.background : const Color(0xFFF8FBFA),
      surface: isDark ? AppColors.card : Colors.white,
      surfaceSoft: isDark ? AppColors.card2 : const Color(0xFFF4F8F7),
      text: isDark ? AppColors.white : const Color(0xFF071318),
      muted: isDark ? AppColors.gray : const Color(0xFF667085),
      border: isDark ? Colors.white10 : const Color(0xFFE5ECEF),
      shadow: isDark
          ? Colors.black.withValues(alpha: 0.22)
          : Colors.black.withValues(alpha: 0.075),
      gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
    );
  }
}

class _CompactHeader extends StatelessWidget {
  final _AiUi ui;
  final bool hasMessages;
  final VoidCallback onClear;

  const _CompactHeader({
    required this.ui,
    required this.hasMessages,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: AppColors.logoGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Ofertix ',
                        style: TextStyle(
                          color: ui.text,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const TextSpan(
                        text: 'AI',
                        style: TextStyle(
                          color: AppColors.orange,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'auto.ai_assistant_ai_assistant_screen.tu_asistente_inteligente_de_compras'
                      .tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ui.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: hasMessages ? onClear : () => Navigator.maybePop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ui.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ui.border),
                boxShadow: [
                  BoxShadow(
                    color: ui.shadow,
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                hasMessages
                    ? Icons.cleaning_services_rounded
                    : Icons.arrow_back_rounded,
                color: ui.muted,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptStrip extends StatelessWidget {
  final _AiUi ui;
  final List<String> promptKeys;
  final void Function(String promptKey) onTap;

  const _PromptStrip({
    required this.ui,
    required this.promptKeys,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: promptKeys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final promptKey = promptKeys[index];
          return GestureDetector(
            onTap: () => onTap(promptKey),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              decoration: BoxDecoration(
                color: ui.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: ui.border),
                boxShadow: [
                  BoxShadow(
                    color: ui.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.orange,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    promptKey.tr(),
                    style: TextStyle(
                      color: ui.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.1,
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

class _EmptyState extends StatelessWidget {
  final _AiUi ui;
  final void Function(String value) onExampleTap;

  const _EmptyState({required this.ui, required this.onExampleTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: ui.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.orange.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: ui.shadow,
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.logoGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withValues(alpha: 0.20),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ai.askBeforeBuying.title'.tr(),
                      style: TextStyle(
                        color: ui.text,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'ai.askBeforeBuying.subtitle'.tr(),
                      style: TextStyle(
                        color: ui.muted,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _TipCard(ui: ui),
        const SizedBox(height: 14),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children:
              [
                'aiAssistant.examples.iphoneWorth',
                'aiAssistant.examples.laptopBudget',
                'aiAssistant.examples.compareStores',
              ].map((itemKey) {
                return GestureDetector(
                  onTap: () => onExampleTap(itemKey.tr()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.orange.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      itemKey.tr(),
                      style: TextStyle(
                        color: ui.text,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final _AiUi ui;

  const _TipCard({required this.ui});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ui.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ui.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.tips_and_updates_outlined,
              color: AppColors.orange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'aiAssistant.askContextTip'.tr(),
              style: TextStyle(
                color: ui.muted,
                fontSize: 13.2,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _AiUi ui;
  final AIChatMessage message;
  final void Function(String value) onSuggestionTap;
  final void Function(Product product) onProductTap;

  const _MessageBubble({
    required this.ui,
    required this.message,
    required this.onSuggestionTap,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          margin: const EdgeInsets.only(bottom: 12, left: 46),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          decoration: BoxDecoration(
            gradient: AppColors.orangeGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            message.text.startsWith('ai.') ? message.text.tr() : message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.30,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 6),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: ui.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ui.border),
          boxShadow: [
            BoxShadow(
              color: ui.shadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.text.trim().isNotEmpty)
              _AnswerText(ui: ui, text: message.text),
            if (message.buyingTips.isNotEmpty) ...[
              const SizedBox(height: 12),
              _BuyingTips(ui: ui, items: message.buyingTips),
            ],
            if (message.suggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Suggestions(
                ui: ui,
                items: message.suggestions.take(6).toList(),
                onTap: onSuggestionTap,
              ),
            ],
            if (message.products.isNotEmpty) ...[
              const SizedBox(height: 14),
              _ProductsStrip(
                ui: ui,
                products: message.products.take(8).toList(),
                onTap: onProductTap,
              ),
            ] else if (message.expectedProducts) ...[
              const SizedBox(height: 12),
              _NoProductsCompact(ui: ui),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnswerText extends StatelessWidget {
  final _AiUi ui;
  final String text;

  const _AnswerText({required this.ui, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.orange,
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text.startsWith('ai.') ? text.tr() : text,
            style: TextStyle(
              color: ui.text,
              fontSize: 14,
              height: 1.42,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _BuyingTips extends StatelessWidget {
  final _AiUi ui;
  final List<String> items;

  const _BuyingTips({required this.ui, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ui.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ui.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.orange,
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                'aiAssistant.buyingTips'.tr(),
                style: TextStyle(
                  color: ui.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ...items
              .take(4)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: ui.muted,
                            fontSize: 13,
                            height: 1.32,
                            fontWeight: FontWeight.w700,
                          ),
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

class _Suggestions extends StatelessWidget {
  final _AiUi ui;
  final List<String> items;
  final void Function(String value) onTap;

  const _Suggestions({
    required this.ui,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return GestureDetector(
          onTap: () => onTap(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              item,
              style: TextStyle(
                color: ui.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProductsStrip extends StatelessWidget {
  final _AiUi ui;
  final List<Product> products;
  final void Function(Product product) onTap;

  const _ProductsStrip({
    required this.ui,
    required this.products,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 164,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final product = products[index];
          return _MiniProductCard(
            ui: ui,
            product: product,
            onTap: () => onTap(product),
          );
        },
      ),
    );
  }
}

class _MiniProductCard extends StatelessWidget {
  final _AiUi ui;
  final Product product;
  final VoidCallback onTap;

  const _MiniProductCard({
    required this.ui,
    required this.product,
    required this.onTap,
  });

  String get _price {
    final currency = product.currency.trim().isEmpty ? '€' : product.currency;
    final price = product.newPrice <= 0
        ? ''
        : product.newPrice.toStringAsFixed(2);
    if (price.isEmpty) return '';
    if (currency.toUpperCase() == 'EUR') return '$price €';
    if (currency.toUpperCase() == 'USD') return '\$$price';
    return '$price $currency';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 138,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: ui.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ui.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: double.infinity,
                  color: ui.surfaceSoft,
                  child: product.image.trim().isEmpty
                      ? const Icon(
                          Icons.image_outlined,
                          color: AppColors.orange,
                        )
                      : Image.network(
                          product.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.orange,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ui.text,
                fontSize: 11.5,
                height: 1.12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (product.discount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '-${product.discount}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoProductsCompact extends StatelessWidget {
  final _AiUi ui;

  const _NoProductsCompact({required this.ui});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.orange, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'auto.ai_assistant_ai_assistant_screen.no_encontre_productos_exactos_prueba_c'
                  .tr(),
              style: TextStyle(
                color: ui.text,
                fontSize: 12.8,
                height: 1.30,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  final _AiUi ui;

  const _ThinkingBubble({required this.ui});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ui.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ui.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'auto.ai_assistant_ai_assistant_screen.buscando'.tr(),
              style: TextStyle(color: ui.muted, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomComposer extends StatelessWidget {
  final _AiUi ui;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onVoiceTap;

  const _BottomComposer({
    required this.ui,
    required this.controller,
    required this.isLoading,
    required this.onSend,
    required this.onSubmitted,
    required this.onVoiceTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom > 0 ? 8.0 : 14.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 8, 14, bottom),
      child: Container(
        height: 64,
        padding: const EdgeInsets.fromLTRB(8, 7, 7, 7),
        decoration: BoxDecoration(
          color: ui.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
              color: ui.shadow,
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                maxLines: 1,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  color: ui.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText:
                      'auto.ai_assistant_ai_assistant_screen.pregunta_que_quieres_comprar'
                          .tr(),
                  hintStyle: TextStyle(
                    color: ui.muted,
                    fontWeight: FontWeight.w700,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            IconButton(
              onPressed: isLoading ? null : onVoiceTap,
              icon: const Icon(Icons.mic_rounded, color: AppColors.orange),
            ),
            GestureDetector(
              onTap: isLoading ? null : onSend,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isLoading ? null : AppColors.logoGradient,
                  color: isLoading ? ui.surfaceSoft : null,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isLoading
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.orange.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.orange,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
