import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';

import 'country_selection_provider.dart';

class CountrySelectionScreen extends StatelessWidget {
  const CountrySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CountrySelectionProvider(),

      child: Consumer<CountrySelectionProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: AppColors.background,

            appBar: AppBar(
              backgroundColor: Colors.transparent,

              elevation: 0,

              centerTitle: true,

              title: const Text('Select Country'),
            ),

            body: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [
                  const SizedBox(height: 10),

                  const Text(
                    'Choose your country',

                    style: TextStyle(
                      fontSize: 28,

                      fontWeight: FontWeight.w900,

                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'This helps Ofertix show local deals and correct currency.',

                    textAlign: TextAlign.center,

                    style: TextStyle(color: AppColors.gray, height: 1.5),
                  ),

                  const SizedBox(height: 30),

                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.countries.length,

                      itemBuilder: (context, index) {
                        final item = provider.countries[index];

                        final selected =
                            provider.selectedCountry == item['country'];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),

                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),

                            onTap: () {
                              provider.select(
                                country: item['country']!,

                                currency: item['currency']!,
                              );
                            },

                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),

                              padding: const EdgeInsets.all(18),

                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.orange
                                    : AppColors.card,

                                borderRadius: BorderRadius.circular(22),

                                border: Border.all(
                                  color: selected
                                      ? AppColors.orange
                                      : Colors.white10,
                                ),
                              ),

                              child: Row(
                                children: [
                                  Text(
                                    item['flag']!,

                                    style: const TextStyle(fontSize: 30),
                                  ),

                                  const SizedBox(width: 16),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        Text(
                                          item['name']!,

                                          style: const TextStyle(
                                            color: Colors.white,

                                            fontSize: 18,

                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          '${item['country']} • ${item['currency']}',

                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white
                                                : AppColors.gray,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (selected)
                                    const Icon(
                                      Icons.check_circle,

                                      color: Colors.white,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,

                        foregroundColor: Colors.white,

                        padding: const EdgeInsets.symmetric(vertical: 16),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),

                      onPressed: () async {
                        await provider.save();

                        if (!context.mounted) {
                          return;
                        }

                        Navigator.pushReplacementNamed(context, '/home');
                      },

                      child: const Text('Continue'),
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
