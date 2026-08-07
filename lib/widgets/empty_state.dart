import 'package:flutter/material.dart';
import '../design_system.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DS.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: DS.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(DS.rXxl)),
            child: Icon(icon, size: 56, color: DS.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: DS.lg),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: DS.inkC(context), letterSpacing: -0.3)),
          const SizedBox(height: DS.sm),
          Text(subtitle, style: TextStyle(color: DS.mutedC(context), fontSize: 14, height: 1.5), textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: DS.lg),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DS.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rLg)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  final String? message;
  const LoadingState({super.key, this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(DS.xl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 32, width: 32, child: CircularProgressIndicator(strokeWidth: 3)),
        if (message != null) ...[const SizedBox(height: DS.md), Text(message!, style: TextStyle(color: DS.mutedC(context), fontSize: 13))],
      ]),
    ),
  );
}
