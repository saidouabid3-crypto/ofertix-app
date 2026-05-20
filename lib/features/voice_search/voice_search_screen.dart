import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';

import 'voice_search_provider.dart';

class VoiceSearchScreen extends StatelessWidget {
  const VoiceSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VoiceSearchProvider(),

      child: Consumer<VoiceSearchProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: AppColors.background,

            appBar: AppBar(
              backgroundColor: Colors.transparent,

              title: const Text('Voice Search'),
            ),

            body: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),

                    width: provider.isListening ? 180 : 140,

                    height: provider.isListening ? 180 : 140,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      color: provider.isListening
                          ? Colors.redAccent
                          : AppColors.orange,

                      boxShadow: [
                        BoxShadow(
                          color:
                              (provider.isListening
                                      ? Colors.redAccent
                                      : AppColors.orange)
                                  .withValues(alpha: 0.5),

                          blurRadius: 40,

                          spreadRadius: 8,
                        ),
                      ],
                    ),

                    child: const Icon(Icons.mic, size: 70, color: Colors.white),
                  ),

                  const SizedBox(height: 40),

                  Text(
                    provider.isListening ? 'Listening...' : 'Tap to speak',

                    style: const TextStyle(
                      color: Colors.white,

                      fontSize: 24,

                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    provider.recognizedText.isEmpty
                        ? 'Your voice search will appear here.'
                        : provider.recognizedText,

                    textAlign: TextAlign.center,

                    style: const TextStyle(color: AppColors.gray, height: 1.5),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,

                        foregroundColor: Colors.white,

                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),

                      onPressed: provider.isListening
                          ? null
                          : provider.startListening,

                      icon: const Icon(Icons.mic),

                      label: Text(
                        provider.isListening
                            ? 'Listening...'
                            : 'Start Voice Search',
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
