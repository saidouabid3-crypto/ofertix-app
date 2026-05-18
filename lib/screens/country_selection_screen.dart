import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';

class CountrySelectionScreen extends StatelessWidget {
  const CountrySelectionScreen({super.key});

  Future<void> saveCountry(
    BuildContext context,
    String countryCode,
    String countryName,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // 💡 هنا ولينا كنحفظو الكود والاسم كامل باش الـ ProfileScreen يقراهوم ديريكت
    await prefs.setString('country', countryCode);
    await prefs.setString('country_name', countryName);

    if (!context.mounted) return;

    // حيدنا const من هنا باش يلا كانت الـ HomeScreen كتستقبل شي حاجة ما تفركعش الكود
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('countries')
              .where('enabled', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Firebase error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            final countries = snapshot.data?.docs ?? [];

            if (countries.isEmpty) {
              return const Center(
                child: Text(
                  'No countries found',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(22),
              children: [
                const SizedBox(height: 24),

                Image.asset('assets/images/logo.png', height: 90),

                const SizedBox(height: 26),

                const Text(
                  'Choose your country',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Select your country to see local deals',
                  style: TextStyle(color: AppColors.gray, fontSize: 16),
                ),

                const SizedBox(height: 28),

                ...countries.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final name = data['name']?.toString() ?? '';
                  final flag = data['flag']?.toString() ?? '🌍';
                  final currency = data['currency']?.toString() ?? '';

                  return GestureDetector(
                    onTap: () {
                      // ممررين الـ doc.id كـ كود (مثلا ES) والـ name كإسم (Spain)
                      saveCountry(context, doc.id, name);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(flag, style: const TextStyle(fontSize: 34)),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currency,
                                  style: const TextStyle(color: AppColors.gray),
                                ),
                              ],
                            ),
                          ),

                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 18,
                            color: AppColors.gray,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
