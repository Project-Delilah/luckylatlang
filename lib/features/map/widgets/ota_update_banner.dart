import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/ota_provider.dart';
import '../../../services/ota_service.dart';

/// Dismissible top banner that appears when an OTA update (or forced rollback) is available.
/// Tapping it opens a download + install dialog.
class OtaUpdateBanner extends ConsumerWidget {
  const OtaUpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final check   = ref.watch(otaCheckProvider);
    final dismissed = ref.watch(otaDismissedProvider);

    final result = check.valueOrNull;
    if (result == null || dismissed) return const SizedBox.shrink();

    final label = result.isRollback
        ? 'Rollback to v${result.target.version} recommended'
        : 'v${result.target.version} available';
    final icon  = result.isRollback ? Icons.history_rounded : Icons.system_update_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: result.isRollback ? Colors.orangeAccent.withValues(alpha: 0.5) : Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: result.isRollback ? Colors.orangeAccent : AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.onDark)),
          ),
          GestureDetector(
            onTap: () => _showUpdateDialog(context, ref, result),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: result.isRollback ? Colors.orangeAccent : AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(result.isRollback ? 'Fix' : 'Update',
                  style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ref.read(otaDismissedProvider.notifier).state = true,
            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, WidgetRef ref, OtaResult result) {
    // Reset any previous download state before showing
    ref.read(otaDownloadProvider.notifier).reset();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OtaDialog(result: result),
    );
  }
}

class _OtaDialog extends ConsumerWidget {
  final OtaResult result;
  const _OtaDialog({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dl = ref.watch(otaDownloadProvider);

    final title = result.isRollback
        ? 'Rollback to v${result.target.version}'
        : 'Update to v${result.target.version}';

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1C1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style: AppTextStyles.titleLg.copyWith(color: AppColors.onDark)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.target.changelog.isNotEmpty) ...[
            Text(result.target.changelog,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.mutedSoft)),
            const SizedBox(height: 16),
          ],
          _StatusBody(dl: dl, target: result.target),
        ],
      ),
      actions: _actions(context, ref, dl, result.target),
    );
  }

  List<Widget> _actions(BuildContext ctx, WidgetRef ref, OtaDownloadState dl, OtaRelease target) {
    switch (dl.status) {
      case OtaStatus.idle:
        return [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Later', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () => ref.read(otaDownloadProvider.notifier).start(target),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Download'),
          ),
        ];
      case OtaStatus.downloading:
        return []; // no actions while downloading
      case OtaStatus.installing:
        return [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: AppColors.muted)),
          ),
        ];
      case OtaStatus.failed:
        return [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () => ref.read(otaDownloadProvider.notifier).start(target),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Retry'),
          ),
        ];
    }
  }
}

class _StatusBody extends StatelessWidget {
  final OtaDownloadState dl;
  final OtaRelease target;
  const _StatusBody({required this.dl, required this.target});

  @override
  Widget build(BuildContext context) {
    return switch (dl.status) {
      OtaStatus.idle => Text(
          'Tap Download to fetch the update (arch-specific APK, ~75 MB).',
          style: AppTextStyles.caption.copyWith(color: AppColors.mutedSoft),
        ),
      OtaStatus.downloading => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: dl.progress > 0 ? dl.progress : null,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              dl.progress > 0
                  ? 'Downloading… ${(dl.progress * 100).toStringAsFixed(0)}%'
                  : 'Connecting…',
              style: AppTextStyles.caption.copyWith(color: AppColors.mutedSoft),
            ),
          ],
        ),
      OtaStatus.installing => Text(
          'Download complete. The installer should open now.',
          style: AppTextStyles.caption.copyWith(color: AppColors.onDark),
        ),
      OtaStatus.failed => Text(
          'Download failed or file verification did not pass. Check your connection and try again.',
          style: AppTextStyles.caption.copyWith(color: Colors.redAccent),
        ),
    };
  }
}
