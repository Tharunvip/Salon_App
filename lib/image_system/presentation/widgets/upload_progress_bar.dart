import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../utils/file_utils.dart';
import '../cubit/upload_state.dart';

class UploadProgressBar extends StatelessWidget {
  final UploadState state;

  const UploadProgressBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (!state.isUploading && state.files.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceColor(context),
        borderRadius: BorderRadius.circular(DesignSystem.radiusLg),
        border: Border.all(color: DesignSystem.borderColor(context)),
        boxShadow: [DesignSystem.shadowSm],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Icon(
            state.isUploading ? Icons.cloud_upload : Icons.check_circle,
            size: 18,
            color: state.isUploading ? DesignSystem.info : DesignSystem.success,
          ),
          const SizedBox(width: 8),
          Text(
            state.isUploading ? 'Uploading...' : 'Upload complete',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: DesignSystem.inkColor(context)),
          ),
          const Spacer(),
          if (state.isUploading)
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: DesignSystem.info),
            )
          else
            Icon(Icons.check_circle, size: 16, color: DesignSystem.success),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: state.overallProgress,
            minHeight: 6,
            backgroundColor: DesignSystem.borderColor(context),
            valueColor: AlwaysStoppedAnimation<Color>(DesignSystem.primary),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Text(
            '${state.completedFiles}/${state.totalFiles} files',
            style: TextStyle(fontSize: 12, color: DesignSystem.muted, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            '${(state.overallProgress * 100).toInt()}%',
            style: TextStyle(fontSize: 12, color: DesignSystem.primary, fontWeight: FontWeight.w700),
          ),
        ]),
        if (state.failedFiles > 0) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.error_outline, size: 14, color: DesignSystem.error),
            const SizedBox(width: 6),
            Text(
              '${state.failedFiles} failed',
              style: TextStyle(fontSize: 12, color: DesignSystem.error, fontWeight: FontWeight.w600),
            ),
          ]),
        ],
      ]),
    );
  }
}

class UploadTaskTile extends StatelessWidget {
  final UploadTaskFile file;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const UploadTaskTile({
    super.key,
    required this.file,
    this.onRetry,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = DesignSystem.isDark(context);
    Color statusColor;
    IconData statusIcon;
    switch (file.status) {
      case UploadStatus.compressing:
        statusColor = DesignSystem.warning;
        statusIcon = Icons.compress;
      case UploadStatus.uploading:
        statusColor = DesignSystem.info;
        statusIcon = Icons.cloud_upload;
      case UploadStatus.completed:
        statusColor = DesignSystem.success;
        statusIcon = Icons.check_circle;
      case UploadStatus.failed:
        statusColor = DesignSystem.error;
        statusIcon = Icons.error;
      default:
        statusColor = DesignSystem.muted;
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(DesignSystem.radiusMd),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
          ),
          child: Center(child: Icon(statusIcon, size: 18, color: statusColor)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: DesignSystem.inkColor(context))),
            const SizedBox(height: 2),
            Text(
              file.status == UploadStatus.failed
                  ? (file.error ?? 'Upload failed')
                  : '${FileUtils.formatBytes(file.fileSize)} · ${(file.progress * 100).toInt()}%',
              style: TextStyle(fontSize: 11, color: file.status == UploadStatus.failed ? DesignSystem.error : DesignSystem.muted),
            ),
          ]),
        ),
        if (file.status == UploadStatus.failed && onRetry != null)
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DesignSystem.errorLight,
                borderRadius: BorderRadius.circular(DesignSystem.radiusSm),
              ),
              child: Text('Retry', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DesignSystem.error)),
            ),
          ),
        if (file.status == UploadStatus.uploading || file.status == UploadStatus.compressing)
          SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: statusColor),
          ),
        if (onCancel != null)
          GestureDetector(
            onTap: onCancel,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(Icons.close, size: 16, color: DesignSystem.muted),
            ),
          ),
      ]),
    );
  }
}
