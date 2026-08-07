import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _key = 'app_locale';
  static const String defaultLocale = 'en';

  final Map<String, String> _deviceLocaleMap = {
    'hi': 'hi', 'te': 'te', 'ta': 'ta', 'kn': 'kn',
    'ml': 'ml', 'mr': 'mr', 'bn': 'bn',
  };

  Locale _locale = const Locale(defaultLocale);
  bool _initialized = false;
  bool _firstLaunch = false;

  Locale get locale => _locale;
  bool get initialized => _initialized;
  bool get firstLaunch => _firstLaunch;
  String get currentCode => _locale.languageCode;

  static const List<Locale> supportedLocales = [
    Locale('en'), Locale('hi'), Locale('te'), Locale('ta'),
    Locale('kn'), Locale('ml'), Locale('mr'), Locale('bn'),
  ];

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);

    if (saved != null && saved.isNotEmpty) {
      _locale = Locale(saved);
      _firstLaunch = false;
    } else {
      final deviceLocale = PlatformDispatcher.instance.locale.languageCode;
      final matched = _deviceLocaleMap[deviceLocale];
      if (matched != null) {
        _locale = Locale(matched);
      }
      _firstLaunch = true;
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    final changed = code != _locale.languageCode;
    _locale = Locale(code);
    _firstLaunch = false;
    if (changed) notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'language': code});
      } catch (_) {}
    }
  }

  Future<void> syncFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final lang = doc.data()?['language'] as String?;
        if (lang != null && lang.isNotEmpty && lang != _locale.languageCode) {
          _locale = Locale(lang);
          _firstLaunch = false;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_key, lang);
          notifyListeners();
        }
      }
    } catch (_) {}
  }
}
