import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../language_provider.dart';
import '../pages/language_selection_screen.dart';

class LanguageBottomSheet extends StatelessWidget {
  const LanguageBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LanguageBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  'Select Language',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: languages.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final lang = languages[index];
                final selected = lp.currentCode == lang.code;
                return ListTile(
                  leading: Text(lang.flag,
                      style: const TextStyle(fontSize: 28)),
                  title: Text(lang.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(lang.nativeName),
                  trailing: selected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.radio_button_off,
                          color: Colors.grey),
                  onTap: () {
                    lp.setLanguage(lang.code);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
