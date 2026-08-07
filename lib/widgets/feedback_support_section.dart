import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system.dart';
import '../firebase_service.dart';
import '../models.dart';
import '../theme_provider.dart';
import 'premium_button.dart';

const String kSupportEmail = 'support@vipsinfinity.com';
const String kSupportPhone = '+919876543210';

class FeedbackSupportSection extends StatelessWidget {
  final AppUser user;
  const FeedbackSupportSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _tile(
        context,
        icon: Icons.dark_mode_outlined,
        color: DS.primary,
        title: 'Dark Mode',
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
        context,
        icon: Icons.rate_review_outlined,
        color: DS.accent,
        title: 'Feedback',
        subtitle: 'Share your experience with us',
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showFeedbackSheet(context),
      ),
      _tile(
        context,
        icon: Icons.support_agent,
        color: DS.success,
        title: 'Customer Support',
        subtitle: 'Call, email or report an issue',
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showSupportSheet(context),
      ),
    ]);
  }

  Widget _tile(BuildContext context, {required IconData icon, required Color color, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DS.rMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: DS.inkC(context))),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: DS.mutedC(context))),
              ],
            ]),
          ),
          const SizedBox(width: 8),
          ?trailing,
        ]),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context) {
    final rating = ValueNotifier<int>(0);
    final msg = TextEditingController();
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
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: DS.disabled.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Share Feedback', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: DS.inkC(c), letterSpacing: -0.3)),
            const SizedBox(height: 6),
            Text('Your feedback helps us improve the app.', style: TextStyle(fontSize: 13, color: DS.mutedC(c))),
            const SizedBox(height: 20),
            ValueListenableBuilder<int>(
              valueListenable: rating,
              builder: (c, r, _) => Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(
                        i <= r ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 36,
                        color: i <= r ? DS.gold : DS.mutedC(c),
                      ),
                      onPressed: () => rating.value = i,
                    ),
                ]),
                Text(r == 0 ? 'Tap a star to rate' : r <= 2 ? 'Not great' : r == 3 ? 'Okay' : r == 4 ? 'Good' : 'Excellent!',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: DS.primary)),
              ]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: msg,
              maxLines: 4,
              maxLength: 500,
              style: TextStyle(color: DS.inkC(c)),
              decoration: DS.inputDecoration(c).copyWith(
                labelText: 'Your message (optional)',
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(builder: (c, setSheet) => PButton(
              text: submitting ? 'Submitting...' : 'Submit Feedback',
              icon: Icons.send,
              loading: submitting,
              onPressed: () async {
                if (rating.value == 0 && msg.text.trim().isEmpty) {
                  ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Please add a rating or a message'), behavior: SnackBarBehavior.floating));
                  return;
                }
                setSheet(() => submitting = true);
                try {
                  await FirebaseService().submitFeedback(
                    userId: user.uid, name: user.name, role: user.role,
                    rating: rating.value, message: msg.text.trim(),
                  );
                  if (c.mounted) {
                    Navigator.pop(c);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your feedback!'), backgroundColor: DS.success, behavior: SnackBarBehavior.floating));
                  }
                } catch (e) {
                  setSheet(() => submitting = false);
                  if (c.mounted) {
                    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('Failed to submit: $e'), backgroundColor: DS.error, behavior: SnackBarBehavior.floating));
                  }
                }
              },
            )),
          ])),
        ),
      ),
    );
  }

  void _showSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: DS.surfaceC(c),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: DS.disabled.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: DS.gradientPrimary, borderRadius: BorderRadius.circular(DS.rMd), boxShadow: [DS.shadowPrimary]),
              child: const Icon(Icons.support_agent, color: Colors.white, size: 24)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Customer Support', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: DS.inkC(c), letterSpacing: -0.3)),
              const SizedBox(height: 2),
              Text('We\'re here to help you 24/7', style: TextStyle(fontSize: 13, color: DS.mutedC(c))),
            ]),
          ]),
          const SizedBox(height: 20),
          _supportButton(c, Icons.call, 'Call Support', DS.success, () => _launch('tel:$kSupportPhone')),
          const SizedBox(height: 10),
          _supportButton(c, Icons.email_outlined, 'Email Us', DS.primary, () => _launch('mailto:$kSupportEmail')),
          const SizedBox(height: 16),
          PButton(text: 'Report an Issue', icon: Icons.assignment_outlined, onPressed: () => _showTicketSheet(context), isOutlined: true),
        ])),
      ),
    );
  }

  Widget _supportButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: DS.inkC(context))),
        ]),
      ),
    );
  }

  void _showTicketSheet(BuildContext context) {
    final subject = TextEditingController();
    final msg = TextEditingController();
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
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: DS.disabled.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Report an Issue', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: DS.inkC(c), letterSpacing: -0.3)),
            const SizedBox(height: 6),
            Text('Describe your issue and we\'ll get back to you soon.', style: TextStyle(fontSize: 13, color: DS.mutedC(c))),
            const SizedBox(height: 20),
            TextField(
              controller: subject,
              style: TextStyle(color: DS.inkC(c)),
              decoration: DS.inputDecoration(c).copyWith(labelText: 'Subject', prefixIcon: const Icon(Icons.title, size: 20)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: msg,
              maxLines: 4,
              style: TextStyle(color: DS.inkC(c)),
              decoration: DS.inputDecoration(c).copyWith(labelText: 'Describe your issue', alignLabelWithHint: true, prefixIcon: const Icon(Icons.edit_outlined, size: 20)),
            ),
            const SizedBox(height: 20),
            StatefulBuilder(builder: (c, setSheet) => PButton(
              text: submitting ? 'Submitting...' : 'Report Issue',
              icon: Icons.send,
              loading: submitting,
              onPressed: () async {
                if (subject.text.trim().isEmpty || msg.text.trim().isEmpty) {
                  ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Please fill in subject and message'), behavior: SnackBarBehavior.floating));
                  return;
                }
                setSheet(() => submitting = true);
                try {
                  await FirebaseService().submitSupportTicket(
                    userId: user.uid, name: user.name, role: user.role,
                    subject: subject.text.trim(), message: msg.text.trim(),
                  );
                  if (c.mounted) {
                    Navigator.pop(c);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Issue reported! We\'ll contact you soon.'), backgroundColor: DS.success, behavior: SnackBarBehavior.floating));
                  }
                } catch (e) {
                  setSheet(() => submitting = false);
                  if (c.mounted) {
                    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('Failed to submit: $e'), backgroundColor: DS.error, behavior: SnackBarBehavior.floating));
                  }
                }
              },
            )),
          ])),
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
