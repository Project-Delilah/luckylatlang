import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/birth_profile.dart';
import '../../providers/profile_provider.dart';
import 'widgets/birth_place_search.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtr = TextEditingController();
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  BirthPlaceResult? _birthPlace;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(profileProvider);
    if (existing != null) _prefill(existing);
  }

  void _prefill(BirthProfile p) {
    _nameCtr.text = p.name;
    _birthDate = p.birthDateTime;
    _birthTime = TimeOfDay.fromDateTime(p.birthDateTime);
    _birthPlace = BirthPlaceResult(
      id: p.cityId,
      name: p.cityName,
      countryCode: p.countryCode,
      latitude: p.latitude,
      longitude: p.longitude,
    );
  }

  @override
  void dispose() {
    _nameCtr.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _birthTime ?? const TimeOfDay(hour: 12, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthTime = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_birthDate == null) {
      _showError('Select your birth date');
      return;
    }
    if (_birthPlace == null) {
      _showError('Select your birth city');
      return;
    }

    setState(() => _saving = true);

    final time = _birthTime ?? const TimeOfDay(hour: 12, minute: 0);
    final dt = DateTime(
      _birthDate!.year, _birthDate!.month, _birthDate!.day,
      time.hour, time.minute,
    );

    final profile = BirthProfile(
      name: _nameCtr.text.trim().isEmpty ? 'You' : _nameCtr.text.trim(),
      birthDateTime: dt,
      cityId: _birthPlace!.id,
      cityName: _birthPlace!.name,
      countryCode: _birthPlace!.countryCode,
      latitude: _birthPlace!.latitude,
      longitude: _birthPlace!.longitude,
    );

    await ref.read(profileProvider.notifier).save(profile);
    if (mounted) context.go(Routes.map);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (existing != null) ...[
                  _ReuseProfileCard(profile: existing, onReuse: () => context.go(Routes.map)),
                  const SizedBox(height: 32),
                  Text('Or update your details', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                  const SizedBox(height: 16),
                ] else ...[
                  Text('Your birth details', style: AppTextStyles.displayMd),
                  const SizedBox(height: 8),
                  Text(
                    'We use these to calculate your astrocartography — the map of lucky places on Earth.',
                    style: AppTextStyles.bodyMd,
                  ),
                  const SizedBox(height: 32),
                ],

                // Name
                Text('Your name (optional)', style: AppTextStyles.caption.copyWith(letterSpacing: 0.8)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtr,
                  decoration: const InputDecoration(hintText: 'Name'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 24),

                // Birth date
                Text('Birth date', style: AppTextStyles.caption.copyWith(letterSpacing: 0.8)),
                const SizedBox(height: 8),
                _PickerTile(
                  icon: Icons.calendar_today_outlined,
                  label: _birthDate != null
                      ? DateFormat('d MMMM yyyy').format(_birthDate!)
                      : 'Select date',
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),

                // Birth time
                Text('Birth time (optional)', style: AppTextStyles.caption.copyWith(letterSpacing: 0.8)),
                const SizedBox(height: 8),
                _PickerTile(
                  icon: Icons.access_time_outlined,
                  label: _birthTime != null
                      ? _birthTime!.format(context)
                      : 'Select time (improves accuracy)',
                  onTap: _pickTime,
                  muted: _birthTime == null,
                ),
                const SizedBox(height: 24),

                // Birth place
                Text('Birth city', style: AppTextStyles.caption.copyWith(letterSpacing: 0.8)),
                const SizedBox(height: 8),
                BirthPlaceSearch(
                  initial: _birthPlace,
                  onSelected: (r) => setState(() => _birthPlace = r),
                ),
                const SizedBox(height: 40),

                // CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Show my map'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReuseProfileCard extends StatelessWidget {
  final BirthProfile profile;
  final VoidCallback onReuse;
  const _ReuseProfileCard({required this.profile, required this.onReuse});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back', style: AppTextStyles.caption.copyWith(color: AppColors.primary, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Text(profile.name, style: AppTextStyles.titleLg),
          Text(
            '${DateFormat('d MMM yyyy').format(profile.birthDateTime)} · ${profile.cityName}',
            style: AppTextStyles.bodyMd,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onReuse,
              child: const Text('Use this profile'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool muted;
  const _PickerTile({required this.icon, required this.label, required this.onTap, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: muted ? AppColors.muted : AppColors.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMd.copyWith(
                  color: muted ? AppColors.muted : AppColors.ink,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
