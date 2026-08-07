import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system.dart';
import '../firebase_service.dart';
import '../login_registration.dart';
import '../models.dart';
import '../theme_provider.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/delete_account_tile.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_card.dart';

const String _kSupportEmail = 'support@vipsinfinity.com';
const String _kSupportPhone = '+919876543210';

class PartnerAccountPage extends StatefulWidget {
  final AppUser user;
  final String partnerCode;
  const PartnerAccountPage({super.key, required this.user, required this.partnerCode});
  @override
  State<PartnerAccountPage> createState() => _PartnerAccountPageState();
}

class _PartnerAccountPageState extends State<PartnerAccountPage> {
  final svc = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSettingsCard(),
          const SizedBox(height: 16),
          _buildSupportCard(),
          const SizedBox(height: 16),
          _buildMyRequestsSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return PremiumHeroCard(
      icon: Icons.person,
      title: widget.user.name.isEmpty ? 'Partner' : widget.user.name,
      subtitle: widget.user.email,
      avatar: Container(
        height: 54, width: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [DS.accent, Color(0xFFB8962E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2.5),
        ),
        child: Center(
          child: Text(
            widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'P',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
      ),
      gradient: DS.gradientGold,
      trailing: widget.partnerCode.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.vpn_key, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(widget.partnerCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
              ]),
            ),
    );
  }

  Widget _buildSettingsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.settings_outlined, size: 18, color: DS.inkC(context)),
          const SizedBox(width: 8),
          Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: DS.inkC(context))),
        ]),
        const SizedBox(height: 16),
        _tile(
          icon: Icons.dark_mode_outlined,
          color: DS.primary,
          title: 'Dark Theme',
          subtitle: 'Switch between light and dark appearance',
          trailing: Consumer<ThemeProvider>(
            builder: (c, tp, _) => Switch(
              value: tp.mode == ThemeMode.dark,
              activeThumbColor: DS.primary,
              activeTrackColor: DS.primary.withValues(alpha: 0.3),
              onChanged: (_) => tp.toggle(),
            ),
          ),
          onTap: null,
        ),
        _tile(
          icon: Icons.person_outline,
          color: DS.accent,
          title: 'Profile',
          subtitle: widget.user.email,
          onTap: null,
        ),
        _tile(
          icon: Icons.logout,
          color: DS.error,
          title: 'Sign Out',
          onTap: () async {
            await svc.logout();
            if (!mounted) return;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
          },
        ),
        DeleteAccountTile(email: widget.user.email),
      ]),
    );
  }

  Widget _buildSupportCard() {
    final isDark = DS.isDark(context);
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(gradient: DS.gradientPrimary, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.support_agent, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Customer Support', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: isDark ? DS.darkInk : DS.ink)),
          ),
        ]),
        const SizedBox(height: 6),
        Text('Request a change to your partner account. The admin will review and apply it.',
            style: TextStyle(fontSize: 13, color: isDark ? DS.darkMuted : DS.muted)),
        const SizedBox(height: 16),
        _tile(
          icon: Icons.person_outline,
          color: DS.primary,
          title: 'Request Name Change',
          subtitle: widget.user.name,
          onTap: () => _showRequestSheet(
            field: 'name', title: 'Change Name', icon: Icons.person_outline,
            currentValue: widget.user.name, hint: 'Enter your new name',
          ),
        ),
        _tile(
          icon: Icons.phone_outlined,
          color: DS.success,
          title: 'Request Mobile Change',
          subtitle: widget.user.mobile,
          onTap: () => _showRequestSheet(
            field: 'mobile', title: 'Change Mobile Number', icon: Icons.phone_outlined,
            currentValue: widget.user.mobile, hint: 'Enter your new mobile number',
          ),
        ),
        _tile(
          icon: Icons.email_outlined,
          color: DS.accent,
          title: 'Request Email Change',
          subtitle: widget.user.email,
          onTap: () => _showRequestSheet(
            field: 'email', title: 'Change Email', icon: Icons.email_outlined,
            currentValue: widget.user.email, hint: 'Enter your new email',
          ),
        ),
        _tile(
          icon: Icons.lock_outline,
          color: DS.purple,
          title: 'Request Password Change',
          subtitle: 'A new password will be set once approved',
          onTap: () => _showRequestSheet(
            field: 'password', title: 'Change Password', icon: Icons.lock_outline,
            currentValue: '', hint: 'Enter a new password (min 8 characters, with uppercase, lowercase, number & special)',
            obscure: true,
          ),
        ),
        _tile(
          icon: Icons.vpn_key,
          color: const Color(0xFFF97316),
          title: 'Request Partner Code Change',
          subtitle: widget.partnerCode.isEmpty ? 'No code yet' : widget.partnerCode,
          onTap: () => _showRequestSheet(
            field: 'partnerCode', title: 'Change Partner Code', icon: Icons.vpn_key,
            currentValue: widget.partnerCode, hint: 'Enter your new partner code',
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _launch('tel:$_kSupportPhone'),
              icon: const Icon(Icons.call, size: 18),
              label: const Text('Call'),
              style: OutlinedButton.styleFrom(foregroundColor: DS.success, side: BorderSide(color: DS.success.withValues(alpha: 0.5))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _launch('mailto:$_kSupportEmail'),
              icon: const Icon(Icons.email_outlined, size: 18),
              label: const Text('Email'),
              style: OutlinedButton.styleFrom(foregroundColor: DS.primary, side: BorderSide(color: DS.primary.withValues(alpha: 0.5))),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildMyRequestsSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: svc.watchMyPartnerEditRequests(widget.user.uid),
      builder: (c, snap) {
        final requests = snap.data ?? [];
        return SectionCard(
          icon: Icons.request_page_outlined,
          title: 'My Requests',
          count: requests.length,
          accentColor: DS.primary,
          child: snap.connectionState == ConnectionState.waiting
              ? const DashboardLoading()
              : requests.isEmpty
                  ? const DashboardEmptyState(message: 'No requests yet. Use Customer Support above to request a change.')
                  : Column(children: requests.map((r) => _requestTile(r)).toList()),
        );
      },
    );
  }

  Widget _requestTile(Map<String, dynamic> r) {
    final isDark = DS.isDark(context);
    final field = _fieldMeta(r['field'] ?? '');
    final status = (r['status'] ?? 'pending').toString();
    final (label, color) = status == 'applied'
        ? ('Applied', DS.success)
        : status == 'rejected'
            ? ('Rejected', DS.error)
            : ('Pending', DS.accent);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xCC16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: isDark ? null : [DS.shadowSm],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: field.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(field.icon, size: 16, color: field.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(field.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? DS.darkInk : DS.ink)),
          ),
          StatusBadge(label: label, color: color),
        ]),
        const SizedBox(height: 10),
        Text(
          '${r['currentValue'] ?? ''} \u2192 ${r['appliedValue'] ?? r['requestedValue'] ?? ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color == DS.accent ? DS.primary : isDark ? DS.darkMuted : DS.muted),
        ),
      ]),
    );
  }

  ({String title, IconData icon, Color color}) _fieldMeta(String field) {
    switch (field) {
      case 'name':
        return (title: 'Name', icon: Icons.person_outline, color: DS.primary);
      case 'mobile':
        return (title: 'Mobile Number', icon: Icons.phone_outlined, color: DS.success);
      case 'email':
        return (title: 'Email', icon: Icons.email_outlined, color: DS.accent);
      case 'password':
        return (title: 'Password', icon: Icons.lock_outline, color: DS.purple);
      case 'partnerCode':
        return (title: 'Partner Code', icon: Icons.vpn_key, color: const Color(0xFFF97316));
      default:
        return (title: field, icon: Icons.edit_outlined, color: DS.muted);
    }
  }

  Widget _tile({required IconData icon, required Color color, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    final isDark = DS.isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DS.rMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? DS.darkInk : DS.ink)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? DS.darkMuted : DS.muted)),
              ],
            ]),
          ),
          const SizedBox(width: 8),
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right, size: 20) : const SizedBox()),
        ]),
      ),
    );
  }

  void _showRequestSheet({
    required String field,
    required String title,
    required IconData icon,
    required String currentValue,
    required String hint,
    bool obscure = false,
  }) {
    final valueC = TextEditingController();
    final noteC = TextEditingController();
    bool submitting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: DS.surfaceC(c),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: DS.disabled.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(gradient: DS.gradientPrimary, borderRadius: BorderRadius.circular(DS.rMd)),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: DS.inkC(c))),
                  const SizedBox(height: 2),
                  Text('The admin will review and apply this request.', style: TextStyle(fontSize: 12, color: DS.mutedC(c))),
                ])),
              ]),
              const SizedBox(height: 20),
              Text('Current: ${currentValue.isEmpty ? 'Not set' : currentValue}', style: TextStyle(fontSize: 13, color: DS.mutedC(c))),
              const SizedBox(height: 12),
              TextField(
                controller: valueC,
                obscureText: obscure,
                style: TextStyle(color: DS.inkC(c)),
                decoration: DS.inputDecoration(c).copyWith(labelText: 'New $title'.replaceAll('New Change ', 'New '), hintText: hint, prefixIcon: Icon(icon, size: 20)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteC,
                maxLines: 2,
                style: TextStyle(color: DS.inkC(c)),
                decoration: DS.inputDecoration(c).copyWith(labelText: 'Reason (optional)', hintText: 'Why do you want this change?', prefixIcon: const Icon(Icons.notes_outlined, size: 20)),
              ),
              const SizedBox(height: 20),
              StatefulBuilder(builder: (c, setSheet) => PButton(
                text: submitting ? 'Submitting...' : 'Submit Request',
                icon: Icons.send,
                loading: submitting,
                isGold: true,
                onPressed: () async {
                  final newValue = valueC.text.trim();
                  if (newValue.isEmpty) {
                    ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Please enter the new value'), behavior: SnackBarBehavior.floating));
                    return;
                  }
                  setSheet(() => submitting = true);
                  try {
                    await svc.createPartnerEditRequest(
                      partnerUid: widget.user.uid,
                      partnerName: widget.user.name,
                      partnerCode: widget.partnerCode,
                      mobile: widget.user.mobile,
                      field: field,
                      currentValue: currentValue,
                      requestedValue: newValue,
                      note: noteC.text.trim(),
                    );
                    if (c.mounted) {
                      Navigator.pop(c);
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted! The admin will review it.'), backgroundColor: DS.success, behavior: SnackBarBehavior.floating));
                    }
                  } catch (e) {
                    setSheet(() => submitting = false);
                    if (c.mounted) {
                      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('Failed to submit: $e'), backgroundColor: DS.error, behavior: SnackBarBehavior.floating));
                    }
                  }
                },
              )),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
