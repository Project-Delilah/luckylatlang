import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/city_provider.dart';

class BirthPlaceResult {
  final int id;
  final String name;
  final String countryCode;
  final double latitude;
  final double longitude;
  BirthPlaceResult({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
  });
}

class BirthPlaceSearch extends ConsumerStatefulWidget {
  final BirthPlaceResult? initial;
  final ValueChanged<BirthPlaceResult> onSelected;

  const BirthPlaceSearch({super.key, this.initial, required this.onSelected});

  @override
  ConsumerState<BirthPlaceSearch> createState() => _BirthPlaceSearchState();
}

class _BirthPlaceSearchState extends ConsumerState<BirthPlaceSearch> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _ctrl.text = '${widget.initial!.name}, ${widget.initial!.countryCode}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() { _results = []; _showDropdown = false; });
      return;
    }
    setState(() => _searching = true);
    final db = ref.read(cityDbProvider).valueOrNull;
    if (db == null) return;
    final rows = await db.searchCities(query);
    if (mounted) {
      setState(() {
        _results = rows;
        _showDropdown = rows.isNotEmpty;
        _searching = false;
      });
    }
  }

  void _select(Map<String, dynamic> row) {
    final result = BirthPlaceResult(
      id: row['id'] as int,
      name: row['name'] as String,
      countryCode: row['country_code'] as String,
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
    );
    _ctrl.text = '${result.name}, ${result.countryCode}';
    setState(() { _results = []; _showDropdown = false; });
    _focus.unfocus();
    widget.onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _ctrl,
          focusNode: _focus,
          decoration: InputDecoration(
            hintText: 'Search birth city…',
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  )
                : const Icon(Icons.search, color: AppColors.muted, size: 20),
          ),
          onChanged: _search,
          validator: (v) => v == null || v.trim().isEmpty ? 'Select a birth city' : null,
        ),
        if (_showDropdown)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              border: Border.all(color: AppColors.hairline),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (ctx, idx) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final row = _results[i];
                final pop = (row['population'] as int?) ?? 0;
                final popStr = pop > 0 ? _fmtPop(pop) : '';
                return InkWell(
                  onTap: () => _select(row),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(row['name'] as String, style: AppTextStyles.titleSm),
                              Text(row['country_code'] as String, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        if (popStr.isNotEmpty)
                          Text(popStr, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _fmtPop(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }
}
