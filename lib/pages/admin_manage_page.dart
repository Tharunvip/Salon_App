import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../design_system.dart';
import '../firebase_service.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_nav.dart';

const _ticketStatuses = ['open', 'in_progress', 'waiting_for_customer', 'resolved', 'closed'];

String _formatTs(dynamic ts) {
  if (ts is Timestamp) {
    return DateFormat('d MMM yyyy, h:mm a').format(ts.toDate().toLocal());
  }
  return '';
}

int _tsMillis(Map<String, dynamic> m) {
  final ts = m['createdAt'];
  return ts is Timestamp ? ts.millisecondsSinceEpoch : 0;
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

class AdminManagePage extends StatelessWidget {
  const AdminManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = DS.isDark(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: isDark ? DS.gradientDarkBg : DS.gradientBg),
            child: SafeArea(
              child: Column(children: [
                FloatingAppBar(
                  title: 'Feedback & Support',
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: isDark ? DS.darkInk : DS.ink),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                TabBar(
                indicatorColor: DS.primary,
                indicatorWeight: 3,
                labelColor: DS.primary,
                unselectedLabelColor: isDark ? DS.darkMuted : DS.muted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: 'Feedback'),
                  Tab(text: 'Reported Issues'),
                ],
              ),
              Expanded(
                child: TabBarView(children: const [
                  _FeedbackTab(),
                  _TicketsTab(),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FEEDBACK TAB
// ═══════════════════════════════════════════════════════════════

class _FeedbackTab extends StatefulWidget {
  const _FeedbackTab();
  @override
  State<_FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends State<_FeedbackTab> {
  final svc = FirebaseService();
  final _searchC = TextEditingController();
  int _ratingFilter = 0;
  bool _newestFirst = true;

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: svc.watchFeedback(),
      builder: (c, snap) {
        final all = snap.data ?? [];
        final waiting = snap.connectionState == ConnectionState.waiting && snap.data == null;
        if (waiting) return const DashboardLoading();

        final query = _searchC.text.trim().toLowerCase();
        final filtered = all.where((f) {
          final name = (f['name'] ?? '').toString().toLowerCase();
          final message = (f['message'] ?? '').toString().toLowerCase();
          final role = (f['role'] ?? '').toString().toLowerCase();
          final rating = (f['rating'] as num?)?.toInt() ?? 0;
          final matchQuery = query.isEmpty || name.contains(query) || message.contains(query) || role.contains(query);
          final matchRating = _ratingFilter == 0 || rating == _ratingFilter;
          return matchQuery && matchRating;
        }).toList();
        if (!_newestFirst) filtered.sort((a, b) => _tsMillis(a).compareTo(_tsMillis(b)));

        return Column(children: [
          if (all.isNotEmpty) _statsCard(all),
          _controls(),
          Expanded(
            child: filtered.isEmpty
                ? const DashboardEmptyState(message: 'No feedback found')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _feedbackTile(filtered[i]),
                  ),
          ),
        ]);
      },
    );
  }

  Widget _statsCard(List<Map<String, dynamic>> all) {
    final isDark = DS.isDark(context);
    final total = all.length;
    final unreviewed = all.where((f) => f['reviewed'] != true).length;
    final ratings = all.map((f) => (f['rating'] as num?)?.toInt() ?? 0).toList();
    final sum = ratings.fold<int>(0, (s, r) => s + r);
    final avg = total == 0 ? 0.0 : sum / total;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xCC16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0x4D2A2A4A) : const Color(0x26FFFFFF)),
        boxShadow: isDark ? null : [DS.shadowSm],
      ),
      child: Column(children: [
        Row(children: [
          _statTile(Icons.rate_review_outlined, 'Total', '$total', DS.primary),
          const SizedBox(width: 10),
          _statTile(Icons.fiber_new_outlined, 'Unreviewed', '$unreviewed', DS.accent),
          const SizedBox(width: 10),
          _statTile(Icons.star_rounded, 'Avg Rating', avg.toStringAsFixed(1), DS.gold),
        ]),
        const SizedBox(height: 14),
        for (int r = 5; r >= 1; r--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              SizedBox(width: 30, child: Text('$r\u2605', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? DS.darkMuted : DS.muted))),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : ratings.where((x) => x == r).length / total,
                    minHeight: 6,
                    backgroundColor: isDark ? const Color(0x332A2A4A) : const Color(0xFFFFE4B5),
                    valueColor: AlwaysStoppedAnimation<Color>(DS.gold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 24, child: Text('${ratings.where((x) => x == r).length}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? DS.darkInk : DS.ink))),
            ]),
          ),
      ]),
    );
  }

  Widget _statTile(IconData icon, String label, String value, Color color) {
    final isDark = DS.isDark(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? DS.darkInk : DS.ink)),
          const SizedBox(height: 1),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? DS.darkMuted : DS.muted)),
        ]),
      ),
    );
  }

  Widget _controls() {
    final isDark = DS.isDark(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _searchC,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: isDark ? DS.darkInk : DS.ink),
              decoration: DS.inputDecoration(context).copyWith(
                hintText: 'Search by name, role or message',
                hintStyle: TextStyle(fontSize: 13, color: isDark ? DS.darkMuted : DS.muted),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchC.text.isEmpty
                    ? null
                    : IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _searchC.clear())),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: _newestFirst ? 'Sort: Newest first' : 'Sort: Oldest first',
            child: IconButton(
              onPressed: () => setState(() => _newestFirst = !_newestFirst),
              icon: Icon(_newestFirst ? Icons.south : Icons.north, color: DS.primary),
              style: IconButton.styleFrom(
                backgroundColor: DS.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _filterChip('All', _ratingFilter == 0, () => setState(() => _ratingFilter = 0)),
            for (int r = 5; r >= 1; r--)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _filterChip('$r\u2605', _ratingFilter == r, () => setState(() => _ratingFilter = r)),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    final isDark = DS.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DS.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? DS.primary : (isDark ? const Color(0xCC16213E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? DS.primary : (isDark ? const Color(0x4D2A2A4A) : const Color(0x26FFFFFF))),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : (isDark ? DS.darkMuted : DS.muted))),
      ),
    );
  }

  Widget _feedbackTile(Map<String, dynamic> f) {
    final isDark = DS.isDark(context);
    final id = f['id'] ?? '';
    final name = f['name'] ?? 'Unknown';
    final role = f['role'] ?? '';
    final message = (f['message'] ?? '').toString();
    final rating = (f['rating'] as num?)?.toInt() ?? 0;
    final reviewed = f['reviewed'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xCC16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reviewed
              ? (isDark ? const Color(0x4D2A2A4A) : const Color(0x26FFFFFF))
              : DS.accent.withValues(alpha: 0.4),
        ),
        boxShadow: isDark ? null : [DS.shadowSm],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [DS.primary, DS.primaryLight]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? DS.darkInk : DS.ink))),
                if (role.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(role, style: TextStyle(fontSize: 11, color: isDark ? DS.darkMuted : DS.muted)),
                ],
                if (!reviewed) ...[
                  const SizedBox(width: 8),
                  const StatusBadge(label: 'New', color: DS.accent),
                ],
              ]),
              const SizedBox(height: 2),
              Row(children: [
                for (int i = 1; i <= 5; i++)
                  Icon(i <= rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 14, color: i <= rating ? DS.gold : (isDark ? DS.darkMuted : DS.disabled)),
                if (_formatTs(f['createdAt']).isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(_formatTs(f['createdAt']), style: TextStyle(fontSize: 11, color: isDark ? DS.darkMuted : DS.muted)),
                ],
              ]),
            ]),
          ),
        ]),
        if (message.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(message, style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? DS.darkInk : DS.ink)),
        ],
        const SizedBox(height: 10),
        Row(children: [
          if (!reviewed)
            SizedBox(
              height: 32,
              child: PButton(
                text: 'Mark Reviewed',
                icon: Icons.done_all,
                height: 32,
                horizontalPadding: 14,
                expanded: false,
                onPressed: () => _markReviewed(id),
              ),
            ),
          const Spacer(),
          ActionChipBtn(
            label: 'Delete',
            icon: Icons.delete_outline,
            color: Colors.redAccent,
            onTap: () => _confirmDeleteFeedback(f, id),
          ),
        ]),
      ]),
    );
  }

  Future<void> _markReviewed(String id) async {
    try {
      await svc.markFeedbackReviewed(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback marked as reviewed'), backgroundColor: DS.success, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: DS.error, behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _confirmDeleteFeedback(Map<String, dynamic> f, String id) async {
    final isDark = DS.isDark(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rXxl)),
        title: const Text('Delete Feedback', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Delete feedback from "${f['name'] ?? 'Unknown'}"? This cannot be undone.', style: TextStyle(color: isDark ? DS.darkInk : DS.ink)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: isDark ? DS.darkMuted : DS.muted))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await svc.deleteFeedback(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback deleted'), backgroundColor: DS.success, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: DS.error, behavior: SnackBarBehavior.floating));
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// SUPPORT TICKETS TAB
// ═══════════════════════════════════════════════════════════════

class _TicketsTab extends StatefulWidget {
  const _TicketsTab();
  @override
  State<_TicketsTab> createState() => _TicketsTabState();
}

class _TicketsTabState extends State<_TicketsTab> {
  final svc = FirebaseService();
  final _searchC = TextEditingController();
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: svc.watchSupportTickets(),
      builder: (c, snap) {
        final all = snap.data ?? [];
        final waiting = snap.connectionState == ConnectionState.waiting && snap.data == null;
        if (waiting) return const DashboardLoading();

        final query = _searchC.text.trim().toLowerCase();
        final filtered = all.where((t) {
          final subject = (t['subject'] ?? '').toString().toLowerCase();
          final message = (t['message'] ?? '').toString().toLowerCase();
          final name = (t['name'] ?? '').toString().toLowerCase();
          final matchQuery = query.isEmpty || subject.contains(query) || message.contains(query) || name.contains(query);
          final matchStatus = _statusFilter == 'all' || (t['status'] ?? 'open') == _statusFilter;
          return matchQuery && matchStatus;
        }).toList();

        return Column(children: [
          _controls(),
          Expanded(
            child: filtered.isEmpty
                ? const DashboardEmptyState(message: 'No reported issues found')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _ticketTile(filtered[i]),
                  ),
          ),
        ]);
      },
    );
  }

  Widget _controls() {
    final isDark = DS.isDark(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(children: [
        TextField(
          controller: _searchC,
          onChanged: (_) => setState(() {}),
          style: TextStyle(color: isDark ? DS.darkInk : DS.ink),
          decoration: DS.inputDecoration(context).copyWith(
            hintText: 'Search by subject, message or name',
            hintStyle: TextStyle(fontSize: 13, color: isDark ? DS.darkMuted : DS.muted),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchC.text.isEmpty
                ? null
                : IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _searchC.clear())),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _statusChip('All', _statusFilter == 'all', () => setState(() => _statusFilter = 'all')),
            for (final s in _ticketStatuses)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _statusChip(_statusStyle(s, isDark: isDark).$1, _statusFilter == s, () => setState(() => _statusFilter = s)),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _statusChip(String label, bool selected, VoidCallback onTap) {
    final isDark = DS.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DS.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? DS.primary : (isDark ? const Color(0xCC16213E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? DS.primary : (isDark ? const Color(0x4D2A2A4A) : const Color(0x26FFFFFF))),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : (isDark ? DS.darkMuted : DS.muted))),
      ),
    );
  }

  Widget _ticketTile(Map<String, dynamic> t) {
    final isDark = DS.isDark(context);
    final status = (t['status'] ?? 'open').toString();
    final (label, color) = _statusStyle(status, isDark: isDark);
    final name = t['name'] ?? 'Unknown';
    final role = t['role'] ?? '';
    final subject = t['subject'] ?? 'No subject';
    final message = (t['message'] ?? '').toString();
    final hasReply = (t['adminReply'] ?? '').toString().isNotEmpty;

    return GestureDetector(
      onTap: () => _showTicketDetail(t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xCC16213E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: status == 'open'
                ? DS.accent.withValues(alpha: 0.4)
                : (isDark ? const Color(0x4D2A2A4A) : const Color(0x26FFFFFF)),
          ),
          boxShadow: isDark ? null : [DS.shadowSm],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [DS.purple, const Color(0xFF9F67FF)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.support_agent, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? DS.darkInk : DS.ink)),
                const SizedBox(height: 2),
                Row(children: [
                  Flexible(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? DS.darkMuted : DS.muted))),
                  if (role.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text('\u00B7 $role', style: TextStyle(fontSize: 12, color: isDark ? DS.darkMuted : DS.muted)),
                  ],
                ]),
              ]),
            ),
            const SizedBox(width: 8),
            StatusBadge(label: label, color: color),
          ]),
          const SizedBox(height: 10),
          Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? DS.darkInk : DS.ink)),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.schedule, size: 12, color: isDark ? DS.darkMuted : DS.muted),
            const SizedBox(width: 4),
            Text(_formatTs(t['createdAt']).isEmpty ? 'Just now' : _formatTs(t['createdAt']), style: TextStyle(fontSize: 11, color: isDark ? DS.darkMuted : DS.muted)),
            const Spacer(),
            if (hasReply) ...[
              const Icon(Icons.reply, size: 12, color: DS.success),
              const SizedBox(width: 4),
              Text('Replied', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DS.success)),
            ],
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, size: 16, color: DS.primary),
          ]),
        ]),
      ),
    );
  }

  void _showTicketDetail(Map<String, dynamic> initial) {
    final isDark = DS.isDark(context);
    final replyC = TextEditingController();
    bool replying = false;
    var ticket = Map<String, dynamic>.from(initial);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => StatefulBuilder(
        builder: (c, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: isDark ? DS.darkBg : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? DS.darkBorder : DS.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: DS.gradientPrimary, borderRadius: BorderRadius.circular(DS.rMd)),
                  child: const Icon(Icons.support_agent, color: Colors.white, size: 24)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ticket['subject'] ?? 'No subject', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? DS.darkInk : DS.ink)),
                  const SizedBox(height: 2),
                  Text('${ticket['name'] ?? 'Unknown'}${(ticket['role'] ?? '').toString().isNotEmpty ? ' \u00B7 ${ticket['role']}' : ''} \u00B7 ${_formatTs(ticket['createdAt'])}',
                      style: TextStyle(fontSize: 12, color: isDark ? DS.darkMuted : DS.muted)),
                ])),
                const SizedBox(width: 8),
                StatusBadge(label: _statusStyle((ticket['status'] ?? 'open').toString(), isDark: isDark).$1, color: _statusStyle((ticket['status'] ?? 'open').toString(), isDark: isDark).$2),
              ]),
              const SizedBox(height: 16),
              Text('Issue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? DS.darkMuted : DS.muted)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xCC16213E) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text((ticket['message'] ?? '').toString(), style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? DS.darkInk : DS.ink)),
              ),
              if ((ticket['adminReply'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Your Reply', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? DS.darkMuted : DS.muted)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DS.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DS.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text((ticket['adminReply'] ?? '').toString(), style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? DS.darkInk : DS.ink)),
                    const SizedBox(height: 6),
                    Text('Replied by ${ticket['repliedBy'] ?? 'App Owner'} \u00B7 ${_formatTs(ticket['repliedAt'])}',
                        style: TextStyle(fontSize: 11, color: isDark ? DS.darkMuted : DS.muted)),
                  ]),
                ),
              ],
              const SizedBox(height: 18),
              Text('Change Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? DS.darkMuted : DS.muted)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in _ticketStatuses)
                  GestureDetector(
                    onTap: () async {
                      await svc.updateTicketStatus(ticket['id'], s);
                      setSheet(() => ticket = Map<String, dynamic>.from({...ticket, 'status': s, 'updatedAt': Timestamp.now()}));
                      if (c.mounted) {
                        ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('Status updated to ${_statusStyle(s, isDark: isDark).$1}'), backgroundColor: DS.success, behavior: SnackBarBehavior.floating));
                      }
                    },
                    child: AnimatedContainer(
                      duration: DS.fast,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: (ticket['status'] ?? 'open') == s ? _statusStyle(s, isDark: isDark).$2 : (isDark ? const Color(0xCC16213E) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusStyle(s, isDark: isDark).$2.withValues(alpha: 0.5)),
                      ),
                      child: Text(_statusStyle(s, isDark: isDark).$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: (ticket['status'] ?? 'open') == s ? Colors.white : _statusStyle(s, isDark: isDark).$2)),
                    ),
                  ),
              ]),
              const SizedBox(height: 18),
              TextField(
                controller: replyC,
                maxLines: 3,
                style: TextStyle(color: isDark ? DS.darkInk : DS.ink),
                decoration: DS.inputDecoration(c).copyWith(
                  labelText: 'Reply to customer',
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.reply, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: PButton(
                    text: 'Send Reply',
                    icon: Icons.send,
                    loading: replying,
                    onPressed: () async {
                      if (replyC.text.trim().isEmpty) {
                        ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Type a reply first'), backgroundColor: DS.error, behavior: SnackBarBehavior.floating));
                        return;
                      }
                      setSheet(() => replying = true);
                      try {
                        final replyText = replyC.text.trim();
                        final repliedBy = svc.currentUser?.displayName ?? 'App Owner';
                        await svc.replyToTicket(ticket['id'], adminReply: replyText, repliedBy: repliedBy);
                        replyC.clear();
                        setSheet(() {
                          replying = false;
                          ticket = Map<String, dynamic>.from({
                            ...ticket,
                            'status': 'in_progress',
                            'adminReply': replyText,
                            'repliedBy': repliedBy,
                            'repliedAt': Timestamp.now(),
                          });
                        });
                        if (c.mounted) {
                          ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Reply sent to customer'), backgroundColor: DS.success, behavior: SnackBarBehavior.floating));
                        }
                      } catch (e) {
                        setSheet(() => replying = false);
                        if (c.mounted) {
                          ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: DS.error, behavior: SnackBarBehavior.floating));
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ActionChipBtn(
                  label: 'Close',
                  icon: Icons.check_circle_outline,
                  color: DS.success,
                  onTap: () => _confirmCloseTicket(c, ticket),
                ),
              ]),
            ])),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCloseTicket(BuildContext sheetCtx, Map<String, dynamic> ticket) async {
    final isDark = DS.isDark(sheetCtx);
    final confirmed = await showDialog<bool>(
      context: sheetCtx,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rXxl)),
        title: const Text('Close Issue', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Close this issue? The customer can still report a new one.', style: TextStyle(color: isDark ? DS.darkInk : DS.ink)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: isDark ? DS.darkMuted : DS.muted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Close', style: TextStyle(color: DS.success, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await svc.closeTicket(ticket['id']);
      if (sheetCtx.mounted) {
        Navigator.pop(sheetCtx);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Issue closed'), backgroundColor: DS.success, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: DS.error, behavior: SnackBarBehavior.floating));
      }
    }
  }
}
