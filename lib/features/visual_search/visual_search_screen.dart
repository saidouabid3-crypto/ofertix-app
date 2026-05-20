import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';

import 'visual_search_provider.dart';

class VisualSearchScreen extends StatelessWidget {
  const VisualSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VisualSearchProvider(),

      child: Consumer<VisualSearchProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: AppColors.background,

            appBar: AppBar(
              backgroundColor: Colors.transparent,

              title: const Text('Visual Search'),
            ),

            body: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [
                  Container(
                    height: 260,

                    width: double.infinity,

                    decoration: BoxDecoration(
                      color: AppColors.card,

                      borderRadius: BorderRadius.circular(28),

                      border: Border.all(color: AppColors.orange),
                    ),

                    child: provider.selectedImage.isEmpty
                        ? const Center(
                            child: Icon(
                              Icons.image_search,

                              size: 90,

                              color: AppColors.orange,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(28),

                            child: Image.network(
                              provider.selectedImage,

                              fit: BoxFit.cover,

                              errorBuilder: (c, e, s) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image,

                                    color: Colors.redAccent,

                                    size: 60,
                                  ),
                                );
                              },
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,

                        foregroundColor: Colors.white,

                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),

                      onPressed: provider.isLoading
                          ? null
                          : () {
                              provider.search('https://picsum.photos/400');
                            },

                      icon: const Icon(Icons.search),

                      label: Text(
                        provider.isLoading
                            ? 'Searching...'
                            : 'Search Similar Products',
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Expanded(
                    child: provider.results.isEmpty
                        ? const Center(
                            child: Text(
                              'No visual results yet',

                              style: TextStyle(color: AppColors.gray),
                            ),
                          )
                        : ListView.builder(
                            itemCount: provider.results.length,

                            itemBuilder: (context, index) {
                              final item = provider.results[index];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),

                                padding: const EdgeInsets.all(16),

                                decoration: BoxDecoration(
                                  color: AppColors.card,

                                  borderRadius: BorderRadius.circular(20),
                                ),

                                child: Text(
                                  item.toString(),

                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            },
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
