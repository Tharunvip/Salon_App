import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../design_system.dart';

/// Renders a bundled markdown document (Privacy Policy / Terms of Service)
/// as an in-app page so users can read the legal text without a website.
class LegalPage extends StatefulWidget {
  final String title;
  final String assetPath;

  const LegalPage({super.key, required this.title, required this.assetPath});

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  String _markdown = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await rootBundle.loadString(widget.assetPath);
      if (!mounted) return;
      setState(() {
        _markdown = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: isDark ? DS.gradientDarkBg : DS.gradientBg),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _render(isDark),
        ),
      ),
    );
  }

  Widget _render(bool isDark) {
    return Markdown(
      data: _markdown,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: TextStyle(fontSize: 14, height: 1.6, color: isDark ? DS.darkInk : DS.ink),
        h1: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.4, color: isDark ? DS.darkInk : DS.ink),
        h2: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.4, color: isDark ? DS.darkInk : DS.ink),
        listBullet: const TextStyle(color: DS.primary),
      ),
    );
  }
}
