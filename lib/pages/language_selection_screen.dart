import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design_system.dart';
import '../language_provider.dart';
import '../widgets/premium_button.dart';
import 'onboarding_screen.dart';

class Language {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const Language(this.code, this.name, this.nativeName, this.flag);
}

const List<Language> languages = [
  Language('en', 'English', 'English', '🇺🇸'),
  Language('hi', 'Hindi', 'हिन्दी', '🇮🇳'),
  Language('te', 'Telugu', 'తెలుగు', '🇮🇳'),
  Language('ta', 'Tamil', 'தமிழ்', '🇮🇳'),
  Language('kn', 'Kannada', 'ಕನ್ನಡ', '🇮🇳'),
  Language('ml', 'Malayalam', 'മലയാളം', '🇮🇳'),
  Language('mr', 'Marathi', 'मराठी', '🇮🇳'),
  Language('bn', 'Bengali', 'বাংলা', '🇮🇳'),
];

class LanguageSelectionScreen extends StatefulWidget {
  final bool isFirstLaunch;
  const LanguageSelectionScreen({super.key, this.isFirstLaunch = true});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: DS.fast,
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: DS.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Language> get _filtered {
    if (_searchQuery.isEmpty) return languages;
    final q = _searchQuery.toLowerCase();
    return languages.where((l) =>
        l.name.toLowerCase().contains(q) ||
        l.nativeName.toLowerCase().contains(q) ||
        l.code.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LanguageProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: DS.gradientSplash),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),
              FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  children: [
                    Text(
                      widget.isFirstLaunch
                          ? (lp.initialized
                              ? lp.locale.languageCode == 'en'
                                  ? 'Choose Your Language'
                                  : 'अपनी भाषा चुनें'
                              : 'Choose Your Language')
                          : 'Language',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.isFirstLaunch
                          ? 'Select your preferred language'
                          : 'Select your preferred language for the app',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 15),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
              Expanded(
                flex: 5,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: DS.md),
                  decoration: BoxDecoration(
                    color: DS.surfaceC(context),
                    borderRadius: BorderRadius.circular(DS.rXxl),
                    boxShadow: [DS.shadowLg],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(DS.md, DS.md, DS.md, DS.sm),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: TextStyle(color: DS.inkC(context)),
                          decoration: DS.inputDecoration(context).copyWith(
                            hintText: 'Search language...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: DS.fast,
                          child: _filtered.isEmpty
                              ? Center(
                                  child: Text(
                                    'No languages found',
                                    style: TextStyle(color: DS.mutedC(context)),
                                  ),
                                )
                              : ListView.separated(
                                  key: ValueKey(_searchQuery),
                                  padding: const EdgeInsets.symmetric(horizontal: DS.sm, vertical: DS.xs),
                                  itemCount: _filtered.length,
                                  separatorBuilder: (_, _) =>
                                      Divider(height: 1, indent: 72, color: DS.borderC(context)),
                                  itemBuilder: (context, index) {
                                    final lang = _filtered[index];
                                    final selected = lp.currentCode == lang.code;
                                    return ListTile(
                                      leading: Text(lang.flag,
                                          style: const TextStyle(fontSize: 28)),
                                      title: Text(lang.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text(lang.nativeName,
                                          style: TextStyle(color: DS.mutedC(context))),
                                      trailing: selected
                                          ? const Icon(Icons.check_circle,
                                              color: DS.primary)
                                          : Icon(Icons.radio_button_off,
                                              color: DS.mutedC(context)),
                                      onTap: () {
                                        lp.setLanguage(lang.code);
                                        if (widget.isFirstLaunch) {
                                          Navigator.of(context)
                                              .pushReplacement(MaterialPageRoute(
                                                  builder: (_) =>
                                                      const OnboardingScreen()));
                                        } else {
                                          Navigator.of(context).pop();
                                        }
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                      if (widget.isFirstLaunch)
                        Padding(
                          padding: const EdgeInsets.all(DS.md),
                          child: PButton(
                            text: 'Continue',
                            icon: Icons.arrow_forward,
                            onPressed: () {
                              lp.setLanguage(lp.currentCode);
                              Navigator.of(context)
                                  .pushReplacement(MaterialPageRoute(
                                      builder: (_) =>
                                          const OnboardingScreen()));
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
