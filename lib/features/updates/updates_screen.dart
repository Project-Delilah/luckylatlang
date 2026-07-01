import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/ota_provider.dart';
import '../../services/ota_service.dart';

class UpdatesScreen extends ConsumerWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info   = ref.watch(packageInfoProvider);
    final check  = ref.watch(otaCheckProvider);
    final dl     = ref.watch(otaDownloadProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.onDark,
        title: Text('Updates',
            style: AppTextStyles.titleMd.copyWith(color: AppColors.onDark)),
        elevation: 0,
        actions: [
          if (!check.isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Check again',
              onPressed: () {
                ref.invalidate(otaCheckProvider);
                ref.read(otaDownloadProvider.notifier).reset();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Current version ───────────────────────────────────────────────
          _card(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lucky Lat·Lang',
                        style: AppTextStyles.titleSm.copyWith(color: AppColors.onDark)),
                    info.when(
                      data: (i) => Text('v${i.version} (build ${i.buildNumber})',
                          style: AppTextStyles.caption.copyWith(color: AppColors.onDarkSoft)),
                      loading: () => Text('Loading…',
                          style: AppTextStyles.caption.copyWith(color: AppColors.onDarkSoft)),
                      error: (e, _) => Text('Could not read version',
                          style: AppTextStyles.caption.copyWith(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Update status ─────────────────────────────────────────────────
          _card(child: _StatusBody(check: check, dl: dl, ref: ref)),
        ],
      ),
    );
  }

  static Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDarkElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: child,
      );
}

// ── Status body ───────────────────────────────────────────────────────────────

class _StatusBody extends StatelessWidget {
  final AsyncValue<OtaResult?> check;
  final OtaDownloadState dl;
  final WidgetRef ref;
  const _StatusBody({required this.check, required this.dl, required this.ref});

  @override
  Widget build(BuildContext context) {
    return check.when(
      loading: () => const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
          SizedBox(width: 12),
          Text('Checking for updates…',
              style: TextStyle(color: AppColors.onDark)),
        ],
      ),

      // Error state — shown on the page so the user (and dev) can see what failed
      error: (e, st) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Text('Check failed',
                style: AppTextStyles.titleSm.copyWith(color: Colors.redAccent)),
          ]),
          const SizedBox(height: 8),
          Text('$e',
              style: AppTextStyles.caption.copyWith(color: AppColors.onDarkSoft)),
          const SizedBox(height: 4),
          Text('$st',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.onDarkSoft, fontSize: 10),
              maxLines: 6,
              overflow: TextOverflow.ellipsis),
        ],
      ),

      data: (result) {
        if (result == null) {
          return Row(children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Colors.greenAccent, size: 18),
            const SizedBox(width: 10),
            Text("You're up to date",
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onDark)),
          ]);
        }

        final isRollback = result.isRollback;
        final accentColor = isRollback ? Colors.orangeAccent : AppColors.primary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(
                isRollback ? Icons.history_rounded : Icons.system_update_rounded,
                color: accentColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isRollback
                    ? 'Rollback to v${result.target.version} recommended'
                    : 'v${result.target.version} available',
                style: AppTextStyles.titleSm.copyWith(color: AppColors.onDark),
              ),
            ]),
            if (result.target.changelog.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(result.target.changelog,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.onDarkSoft)),
            ],
            const SizedBox(height: 16),
            _DownloadControl(dl: dl, target: result.target, accent: accentColor, ref: ref),
          ],
        );
      },
    );
  }
}

// ── Download / install control ────────────────────────────────────────────────

class _DownloadControl extends StatelessWidget {
  final OtaDownloadState dl;
  final OtaRelease target;
  final Color accent;
  final WidgetRef ref;
  const _DownloadControl(
      {required this.dl, required this.target, required this.accent, required this.ref});

  @override
  Widget build(BuildContext context) {
    return switch (dl.status) {
      OtaStatus.idle => FilledButton.icon(
          onPressed: () => ref.read(otaDownloadProvider.notifier).start(target),
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Download & Install'),
          style: FilledButton.styleFrom(backgroundColor: accent),
        ),
      OtaStatus.downloading => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: dl.progress > 0 ? dl.progress : null,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(accent),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              dl.progress > 0
                  ? 'Downloading… ${(dl.progress * 100).toStringAsFixed(0)}%'
                  : 'Connecting…',
              style: AppTextStyles.caption.copyWith(color: AppColors.onDarkSoft),
            ),
          ],
        ),
      OtaStatus.installing => Text(
          'Download complete — installer should open now.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.onDark),
        ),
      OtaStatus.failed => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Download failed. Check your connection and try again.',
                style: AppTextStyles.bodySm.copyWith(color: Colors.redAccent)),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => ref.read(otaDownloadProvider.notifier).start(target),
              style: FilledButton.styleFrom(backgroundColor: accent),
              child: const Text('Retry'),
            ),
          ],
        ),
    };
  }
}
