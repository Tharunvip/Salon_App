import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../design_system.dart';
import '../firebase_service.dart';
import '../models.dart';
import 'dashboard_widgets.dart';

String _formatTs(dynamic ts) {
  if (ts is Timestamp) {
    return DateFormat('d MMM yyyy, h:mm a').format(ts.toDate().toLocal());
  }
  return '';
}

(String, Color) _statusStyle(String status, {required bool isDark}) {
  switch (status) {
    case 'open':
      return ('Open', DS.accent);
    case 'in_progress':
      return ('In Progress', DS.primary);
    case 'waiting_for_customer':
      return ('Waiting for Customer', DS.purple);
    case 'resolved':
      return ('Resolved', DS.success);
    case 'closed':
      return ('Closed', isDark ? DS.darkMuted : DS.muted);
    default:
      return (status, isDark ? DS.darkMuted : DS.muted);
  }
}

class MyTicketsSection extends StatefulWidget {
  final AppUser user;
  const MyTicketsSection({super.key, required this.user});
  @override
  State<MyTicketsSection> createState() => _MyTicketsSectionState();
}

class _MyTicketsSectionState extends State<MyTicketsSection> {
  final svc = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.db.collection('support_tickets')
          .where('userId', isEqualTo: widget.user.uid)
          .limit(100)
          .snapshots(),
      builder: (c, snap) {
        if (snap.hasError) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text('Could not load issues. Please try again later.', style: TextStyle(fontSize: 13)),
          );
        }
        if (snap.connectionState == ConnectionState.waiting && snap.data == null) {
          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)));
        }
        final docs = snap.data?.docs.toList() ?? [];
        docs.sort((a, b) {
          final ta = a.data()['createdAt'];
          final tb = b.data()['createdAt'];
          return (tb is Timestamp ? tb.millisecondsSinceEpoch : 0).compareTo(ta is Timestamp ? ta.millisecondsSinceEpoch : 0);
        });
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(children: [
              const Icon(Icons.assignment_outlined, size: 18, color: DS.primary),
              const SizedBox(width: 8),
              Text('Reported Issues', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: DS.inkC(context))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: DS.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Text('${docs.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: DS.primary)),
              ),
            ]),
          ),
          if (docs.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text('No issues reported yet. Report one from Customer Support above.', style: TextStyle(fontSize: 13)),
            )
          else
            ...docs.map((d) => _ticketTile(d.data(), d.id)),
        ]);
      },
    );
  }

  Widget _ticketTile(Map<String, dynamic> t, String id) {
    final isDark = DS.isDark(context);
    final status = (t['status'] ?? 'open').toString();
    final (label, color) = _statusStyle(status, isDark: isDark);
    final subject = t['subject'] ?? 'Reported Issue';
    final message = (t['message'] ?? '').toString();
    final reply = (t['adminReply'] ?? '').toString();
    final repliedBy = (t['repliedBy'] ?? 'App Owner').toString();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xCC16213E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: reply.isNotEmpty
              ? DS.success.withValues(alpha: 0.35)
              : (isDark ? const Color(0x4D2A2A4A) : const Color(0x26FFFFFF)),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: DS.inkC(context)))),
          const SizedBox(width: 8),
          StatusBadge(label: label, color: color),
        ]),
        const SizedBox(height: 2),
        if (_formatTs(t['createdAt']).isNotEmpty)
          Text('Reported ${_formatTs(t['createdAt'])}', style: TextStyle(fontSize: 11, color: DS.mutedC(context))),
        const SizedBox(height: 6),
        Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, height: 1.4, color: DS.inkC(context))),
        if (reply.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: DS.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.reply, size: 12, color: DS.success),
                const SizedBox(width: 4),
                Text('Admin Reply', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DS.success)),
              ]),
              const SizedBox(height: 4),
              Text(reply, style: TextStyle(fontSize: 13, height: 1.4, color: DS.inkC(context))),
              if (_formatTs(t['repliedAt']).isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('$repliedBy \u00B7 ${_formatTs(t['repliedAt'])}', style: TextStyle(fontSize: 10, color: DS.mutedC(context))),
              ],
            ]),
          ),
        ],
      ]),
    );
  }
}
