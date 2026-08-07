import 'dart:async';
import 'package:flutter/material.dart';
import 'package:salon_app/l10n/app_localizations.dart';

import '../design_system.dart';
import '../firebase_service.dart';
import '../models.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_card.dart';
import '../widgets/shimmer.dart';
import '../widgets/section_header.dart';

class OwnerQueuePage extends StatefulWidget {
  final String ownerId;
  final String userName;
  final int chairCount;
  final int notificationThreshold;
  const OwnerQueuePage({super.key, required this.ownerId, required this.userName, required this.chairCount, required this.notificationThreshold});

  @override
  State<OwnerQueuePage> createState() => _OwnerQueuePageState();
}

class _OwnerQueuePageState extends State<OwnerQueuePage> with TickerProviderStateMixin {
  final svc = FirebaseService();
  List<Chair> _chairs = [];
  List<Booking> _waiting = [];
  bool _loading = true;
  Timer? _ticker;
  final Set<int> _notifiedTokens = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    bool changed = false;
    for (int i = 0; i < _chairs.length; i++) {
      final c = _chairs[i];
      if (c.status == 'in_service') {
        final remaining = c.effectiveRemainingSeconds;
        if (remaining != c.remainingSeconds) {
          _chairs[i] = c.copyWith(remainingSeconds: remaining);
          changed = true;
        }
        _checkAutoComplete(c);
        _checkNotificationThreshold(c);
      }
    }
    if (changed && mounted) setState(() {});
  }

  void _checkAutoComplete(Chair chair) {
    if (chair.effectiveRemainingSeconds <= 0 && chair.currentToken != null) {
      svc.completeChairService(widget.ownerId, chair.chairNumber);
    }
  }

  void _checkNotificationThreshold(Chair chair) {
    if (chair.currentToken == null) return;
    final threshold = widget.notificationThreshold * 60;
    if (_notifiedTokens.contains(chair.currentToken)) return;
    if (chair.effectiveRemainingSeconds > threshold) return;

    final next = _waiting.isNotEmpty ? _waiting.first : null;
    if (next == null) return;

    _notifiedTokens.add(chair.currentToken!);
    svc.markChairNotificationSent(widget.ownerId, chair.chairNumber);
    svc.sendCustomerNotification(
      customerId: next.customerId,
      ownerId: widget.ownerId,
      title: 'Your turn is coming!',
      body: 'Please leave now and reach the salon. Your service will begin soon.',
    );
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      await Future.wait([_loadChairs(), _loadWaiting()]);
    } catch (_) {
      // queries may fail (e.g. missing composite index) — show UI with empty data
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadChairs() async {
    try {
      final snap = await svc.db.collection('chairs')
          .where('ownerId', isEqualTo: widget.ownerId)
          .orderBy('chairNumber')
          .get();
      _chairs = snap.docs.map((d) => Chair.fromMap(d.id, d.data())).toList();
      if (mounted) setState(() {});
    } catch (_) {
      _chairs = [];
    }
    svc.db.collection('chairs')
        .where('ownerId', isEqualTo: widget.ownerId)
        .orderBy('chairNumber')
        .snapshots().listen((s) {
      if (mounted) setState(() => _chairs = s.docs.map((d) => Chair.fromMap(d.id, d.data())).toList());
    });
  }

  Future<void> _loadWaiting() async {
    try {
      final snap = await svc.db.collection('bookings')
          .where('ownerId', isEqualTo: widget.ownerId)
          .where('status', isEqualTo: 'confirmed')
          .where('chairNumber', isNull: true)
          .orderBy('token', descending: false)
          .get();
      _waiting = snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
    } catch (_) {
      _waiting = [];
    }
    if (mounted) setState(() {});
    svc.db.collection('bookings')
        .where('ownerId', isEqualTo: widget.ownerId)
        .snapshots().listen((s) {
      final all = s.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
      _waiting = all.where((b) => b.status == 'confirmed' && b.chairNumber == null).toList();
      _waiting.sort((a, b) => a.token.compareTo(b.token));
      if (mounted) setState(() {});
    });
  }

  Future<void> _startService(Chair chair) async {
    await svc.startChairService(widget.ownerId, chair.chairNumber, chair.durationMinutes);
  }

  Future<void> _pauseService(Chair chair) async {
    await svc.pauseChairService(widget.ownerId, chair.chairNumber);
  }

  Future<void> _resumeService(Chair chair) async {
    await svc.resumeChairService(widget.ownerId, chair.chairNumber);
  }

  Future<void> _completeChair(int chairNumber) async {
    final amt = await _askServiceAmount();
    if (amt == null) return;
    await svc.completeChairService(widget.ownerId, chairNumber, amount: amt);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Service completed. Collect Rs $amt from the customer.'), behavior: SnackBarBehavior.floating, backgroundColor: DS.success));
    }
  }

  Future<int?> _askServiceAmount() async {
    final cnt = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (c) {
        final isDark = Theme.of(c).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rXxl)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: DS.primaryVeryLight, borderRadius: BorderRadius.circular(DS.rLg)), child: const Icon(Icons.currency_rupee, color: DS.primary, size: 32)),
              const SizedBox(height: 16),
              Text('Service Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? DS.darkInk : DS.ink)),
              const SizedBox(height: 4),
              Text('Enter total service charge', style: TextStyle(color: isDark ? DS.darkMuted : DS.muted, fontSize: 13)),
              const SizedBox(height: 20),
              TextField(controller: cnt, keyboardType: TextInputType.number, style: TextStyle(color: DS.inkC(c)), decoration: DS.inputDecoration(c).copyWith(labelText: 'Total Amount (Rs)', prefixIcon: const Icon(Icons.currency_rupee, size: 18))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: DS.accentLight, borderRadius: BorderRadius.circular(DS.rMd)),
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 16, color: DS.accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Customer will pay this amount after service via UPI, Card or Cash.', style: TextStyle(fontSize: 12, color: DS.accent.withValues(alpha: 0.8), height: 1.4))),
                ]),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: PButton(text: 'Cancel', icon: Icons.close, onPressed: () => Navigator.pop(c), isOutlined: true)),
                const SizedBox(width: 12),
                Expanded(child: PButton(text: 'Confirm', icon: Icons.check, onPressed: () {
                  final amt = int.tryParse(cnt.text.trim());
                  if (amt == null || amt < 50) return;
                  Navigator.pop(c, amt);
                }, isGold: true)),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _releaseChair(Chair chair) async {
    await svc.releaseChair(widget.ownerId, chair.chairNumber);
  }

  Future<void> _assignNextAndStart(Chair chair) async {
    final assigned = await svc.assignNextToChair(widget.ownerId, chair.chairNumber);
    if (assigned != null && mounted) {
      await svc.startChairService(widget.ownerId, chair.chairNumber, assigned.durationMinutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = DS.isDark(context);
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.queueManagement, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3)), leading: const BackButton(), centerTitle: false),
      body: _loading
          ? const Padding(padding: EdgeInsets.all(16), child: ShimmerBox(height: 160))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _buildStatsBar(l),
                  const SizedBox(height: 20),
                  ..._chairs.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ChairCard(
                      chair: c,
                      waitingCount: _waiting.length,
                      onStart: () => _startService(c),
                      onPause: () => _pauseService(c),
                      onResume: () => _resumeService(c),
                      onComplete: () => _completeChair(c.chairNumber),
                      onRelease: () => _releaseChair(c),
                      onAssignNext: () => _assignNextAndStart(c),
                    ),
                  )),
                  const SizedBox(height: 8),
                  _buildWaitingList(isDark, l),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsBar(AppLocalizations l) {
    final inService = _chairs.where((c) => c.status == 'in_service').length;
    final waiting = _chairs.where((c) => c.status == 'waiting_to_start').length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: DS.gradientPrimary,
        borderRadius: BorderRadius.circular(DS.rXl),
        boxShadow: [DS.shadowPrimary],
      ),
      child: Row(children: [
        Expanded(child: _statItem(Icons.chair_alt, '${_chairs.length}', l.chairs, Colors.white)),
        Expanded(child: _statItem(Icons.build, '$inService', l.inService, const Color(0xFF81C784))),
        Expanded(child: _statItem(Icons.hourglass_top, '$waiting', l.waitingToStart, const Color(0xFFA78BFA))),
        Expanded(child: _statItem(Icons.people, '${_waiting.length}', l.waitingQueue, const Color(0xFFFCD34D))),
      ]),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color valueColor) {
    return Column(children: [
      Icon(icon, size: 22, color: Colors.white.withValues(alpha: 0.9)),
      const SizedBox(height: 6),
      FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: valueColor, letterSpacing: -0.5))),
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildWaitingList(bool isDark, AppLocalizations l) {
    if (_waiting.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: l.waitingQueue, subtitle: '${_waiting.length} customer${_waiting.length != 1 ? 's' : ''}'),
      const SizedBox(height: 12),
      ..._waiting.take(10).map((b) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: DS.surfaceC(context),
          borderRadius: BorderRadius.circular(DS.rLg),
          border: Border.all(color: DS.borderC(context).withValues(alpha: 0.5)),
          boxShadow: [DS.shadowSm],
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: DS.primaryLight,
              borderRadius: BorderRadius.circular(DS.rMd),
            ),
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(l.tokenNumber(b.token), style: const TextStyle(color: DS.primary, fontWeight: FontWeight.w900, fontSize: 16))),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.customerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: DS.inkC(context))),
              Text(b.serviceName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? DS.darkMuted : DS.muted, fontSize: 12)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: DS.primaryLight,
              borderRadius: BorderRadius.circular(DS.rSm),
            ),
            child: FittedBox(fit: BoxFit.scaleDown, child: Text('${b.durationMinutes}${l.minutes}', style: const TextStyle(color: DS.primary, fontWeight: FontWeight.w700, fontSize: 12))),
          ),
        ]),
      )),
      if (_waiting.length > 10) Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('+${_waiting.length - 10} more', style: TextStyle(color: isDark ? DS.darkMuted : DS.muted, fontSize: 13)),
      ),
    ]);
  }
}

class _ChairCard extends StatelessWidget {
  final Chair chair;
  final int waitingCount;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onComplete;
  final VoidCallback onRelease;
  final VoidCallback onAssignNext;

  const _ChairCard({
    required this.chair,
    required this.waitingCount,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onComplete,
    required this.onRelease,
    required this.onAssignNext,
  });

  Color get _statusColor {
    switch (chair.status) {
      case 'available': return DS.success;
      case 'waiting_to_start': return DS.purple;
      case 'in_service': return DS.info;
      case 'paused': return DS.warning;
      case 'completed': return DS.muted;
      default: return DS.error;
    }
  }

  IconData get _statusIcon {
    switch (chair.status) {
      case 'available': return Icons.check_circle;
      case 'waiting_to_start': return Icons.hourglass_top;
      case 'in_service': return Icons.build;
      case 'paused': return Icons.pause_circle;
      case 'completed': return Icons.check_circle_outline;
      default: return Icons.error;
    }
  }

  String get _remainingDisplay {
    if (chair.status != 'in_service') return '';
    final m = chair.effectiveRemainingSeconds ~/ 60;
    final s = chair.effectiveRemainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (chair.status != 'in_service' || chair.durationMinutes <= 0) return 0;
    final total = chair.durationMinutes * 60;
    final remaining = chair.effectiveRemainingSeconds;
    return remaining / total;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final token = chair.currentToken ?? chair.nextAssignedToken;
    final isDark = DS.isDark(context);

    String statusLabel;
    switch (chair.status) {
      case 'available': statusLabel = l.available; break;
      case 'waiting_to_start': statusLabel = l.waitingToStart; break;
      case 'in_service': statusLabel = l.inService; break;
      case 'paused': statusLabel = l.paused; break;
      case 'completed': statusLabel = l.completed; break;
      default: statusLabel = l.unavailable; break;
    }

    return PremiumCard(
      padding: EdgeInsets.zero,
      borderColor: _statusColor.withValues(alpha: 0.3),
      shadows: [BoxShadow(color: _statusColor.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(DS.rXl)),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(DS.rMd),
              ),
              child: Center(child: Text('${chair.chairNumber}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _statusColor))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${l.chair} ${chair.chairNumber}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: DS.inkC(context), letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(_statusIcon, size: 14, color: _statusColor),
                  const SizedBox(width: 4),
                  Text(statusLabel, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _statusColor)),
                ]),
              ]),
            ),
            if (chair.status == 'in_service')
              Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: DS.surfaceC(context),
                    borderRadius: BorderRadius.circular(DS.rMd),
                    border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _remainingDisplay,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: _statusColor,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: DS.borderC(context),
                      valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                      minHeight: 4,
                    ),
                  ),
                ),
              ]),
          ]),
        ),
        if (token != null || chair.customerName != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: DS.primaryLight,
                  borderRadius: BorderRadius.circular(DS.rLg),
                ),
                child: Center(
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(l.tokenNumber(token!), style: const TextStyle(color: DS.primary, fontWeight: FontWeight.w900, fontSize: 18))),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(chair.customerName ?? chair.customerNameDisplay ?? l.customer, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: DS.inkC(context))),
                  if (chair.serviceName != null) Text(chair.serviceName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? DS.darkMuted : DS.muted, fontSize: 13)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: DS.primaryLight, borderRadius: BorderRadius.circular(DS.rSm)),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text('${chair.durationMinutes}${l.minutes}', style: const TextStyle(color: DS.primary, fontWeight: FontWeight.w700, fontSize: 12))),
              ),
            ]),
          ),
        ],
        if (chair.status == 'in_service')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              Expanded(child: _actionBtn(Icons.pause, l.pauseService, DS.warning, onPause)),
              const SizedBox(width: 8),
              Expanded(child: _actionBtn(Icons.check_circle, l.completeService, DS.success, onComplete)),
            ]),
          ),
        if (chair.status == 'paused')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              Expanded(child: _actionBtn(Icons.play_arrow, l.resumeService, DS.info, onResume)),
              const SizedBox(width: 8),
              Expanded(child: _actionBtn(Icons.check_circle, l.completeService, DS.success, onComplete)),
            ]),
          ),
        if (chair.status == 'waiting_to_start')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _actionBtnFull(Icons.play_arrow, l.startService, DS.info, onStart),
          ),
        if (chair.status == 'completed')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _actionBtnFull(
              Icons.restart_alt,
              waitingCount > 0 ? l.assignNext : l.releaseChair,
              DS.success,
              waitingCount > 0 ? onAssignNext : onRelease,
            ),
          ),
        if (chair.status == 'available' && waitingCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _actionBtnFull(Icons.person_add, 'Start Next', DS.info, onAssignNext),
          ),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DS.rMd),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color))),
        ]),
      ),
    );
  }

  Widget _actionBtnFull(IconData icon, String label, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
          borderRadius: BorderRadius.circular(DS.rLg),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white, letterSpacing: 0.3))),
        ]),
      ),
    );
  }
}
