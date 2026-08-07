import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design_system.dart';
import '../widgets/premium_card.dart';
import '../widgets/premium_button.dart';
import '../firebase_service.dart';
import '../language_provider.dart';
import '../login_registration.dart';
import '../models.dart';
import '../l10n/app_localizations.dart';
import '../widgets/delete_account_tile.dart';
import '../widgets/language_bottom_sheet.dart';
import '../widgets/feedback_support_section.dart';
import '../widgets/my_tickets_section.dart';

class CustomerProfilePage extends StatefulWidget {
  final AppUser user;
  const CustomerProfilePage({super.key, required this.user});
  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final svc = FirebaseService();
  final nameCnt = TextEditingController();
  final mobileCnt = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameCnt.text = widget.user.name;
    mobileCnt.text = widget.user.mobile;
  }

  @override
  void dispose() { nameCnt.dispose(); mobileCnt.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;
    final lp = context.watch<LanguageProvider>();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: isDark ? DS.gradientDarkBg : DS.gradientBg),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 20),
              Center(
                child: Column(children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      gradient: DS.gradientPrimary,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: DS.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Center(
                      child: Text(
                        widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(widget.user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: DS.inkC(context), letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(widget.user.email, style: TextStyle(color: DS.mutedC(context), fontSize: 14)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: DS.primaryVeryLight, borderRadius: BorderRadius.circular(8)),
                    child: Text(widget.user.role.toUpperCase(), style: const TextStyle(color: DS.primary, fontWeight: FontWeight.w700, fontSize: 11)),
                  ),
                  const SizedBox(height: 24),
                  Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 4, children: [
                    const Icon(Icons.star, color: DS.gold, size: 16),
                    Text(l.goldMember, style: const TextStyle(fontWeight: FontWeight.w700, color: DS.gold, fontSize: 14)),
                    const SizedBox(width: 4),
                    Icon(Icons.verified, color: DS.primary, size: 16),
                    Text(l.verified, style: const TextStyle(fontWeight: FontWeight.w700, color: DS.primary, fontSize: 14)),
                  ]),
                ]),
              ),
              const SizedBox(height: 32),
              GlassCard(
                child: Column(children: [
                  _sectionHeader(l.personalInformation, Icons.person_outline),
                  const Divider(height: 1),
                  _infoTile(l.name, widget.user.name, Icons.person),
                  _infoTile(l.email, widget.user.email, Icons.email),
                  _infoTile(l.mobile, widget.user.mobile, Icons.phone),
                  _infoTile(l.role, widget.user.role, Icons.badge),
                ]),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(children: [
                  _sectionHeader(l.account, Icons.settings_outlined),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: DS.primaryVeryLight, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.edit_outlined, color: DS.primary, size: 20)),
                    title: Text(l.editProfile, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showEditSheet(),
                  ),
                  ListTile(
                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: DS.primaryVeryLight, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.language, color: DS.primary, size: 20)),
                    title: Text(l.language, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(lp.currentCode.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? DS.darkMuted : DS.muted, fontSize: 13)),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right),
                    ]),
                    onTap: () => LanguageBottomSheet.show(context),
                  ),
                  ListTile(
                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: DS.primaryVeryLight, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.logout, color: DS.error, size: 20)),
                    title: Text(l.logout, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: DS.error)),
                    trailing: const Icon(Icons.chevron_right, color: DS.error),
                    onTap: () async {
                      await svc.logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
                    },
                  ),
                  DeleteAccountTile(email: widget.user.email),
                ]),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(children: [
                  _sectionHeader('Support & Feedback', Icons.support_agent),
                  const Divider(height: 1),
                  FeedbackSupportSection(user: widget.user),
                  const Divider(height: 1),
                  MyTicketsSection(user: widget.user),
                ]),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(children: [
        Icon(icon, color: DS.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: DS.inkC(context)))),
      ]),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, color: DS.mutedC(context), size: 18),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: DS.mutedC(context), fontSize: 14))),
        const SizedBox(width: 8),
        Flexible(child: Text(value, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: DS.inkC(context)))),
      ]),
    );
  }

  void _showEditSheet() {
    final nameC = TextEditingController(text: widget.user.name);
    final mobC = TextEditingController(text: widget.user.mobile);
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? DS.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: DS.disabled, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Text(l.editProfile, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: DS.inkC(context))),
              const SizedBox(height: 20),
              TextField(controller: nameC, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: l.name, prefixIcon: const Icon(Icons.person_outline, size: 20))),
              const SizedBox(height: 16),
              TextField(controller: mobC, style: TextStyle(color: DS.inkC(context)), decoration: DS.inputDecoration(context).copyWith(labelText: l.mobile, prefixIcon: const Icon(Icons.phone_outlined, size: 20)), keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              PButton(text: l.save, icon: Icons.check, onPressed: () async {
                if (nameC.text.trim().isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                final uid = svc.currentUser?.uid;
                if (uid != null) {
                  await svc.db.collection('users').doc(uid).update({'name': nameC.text.trim(), 'mobile': mobC.text.trim()});
                }
                if (!c.mounted) return;
                Navigator.pop(c);
                messenger.showSnackBar(SnackBar(content: Text(l.profileUpdated), backgroundColor: DS.success, behavior: SnackBarBehavior.floating));
                setState(() {});
              }),
            ]),
          ),
        ),
      ),
    );
  }
}
