import 'package:flutter/material.dart';

import '../design_system.dart';
import '../firebase_service.dart';
import '../login_registration.dart';
import '../services/offline_guard.dart';

/// Red "Delete Account" row with password confirmation. Works for every role.
class DeleteAccountTile extends StatelessWidget {
  const DeleteAccountTile({super.key, required this.email});

  final String email;

  Future<void> _confirm(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final password = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Account'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('This permanently deletes your account and all associated data. This cannot be undone. Enter your password to confirm.'),
          const SizedBox(height: 16),
          TextField(
            controller: password,
            obscureText: true,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: DS.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || password.text.isEmpty) return;
    try {
      await FirebaseService().deleteAccount(email: email, password: password.text);
      messenger.showSnackBar(const SnackBar(content: Text('Account deleted.'), backgroundColor: DS.success, behavior: SnackBarBehavior.floating));
      navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e)), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: DS.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.delete_forever, color: DS.error, size: 20),
      ),
      title: Text('Delete Account', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: DS.error)),
      trailing: const Icon(Icons.chevron_right, color: DS.error),
      onTap: () => _confirm(context),
    );
  }
}
