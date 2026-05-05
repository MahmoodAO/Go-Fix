import 'package:flutter/material.dart';
import 'package:homemate/theme/app_theme.dart';

class FiltersScreen extends StatefulWidget {
  static const screenRoute = '/filters';

  final void Function(Map<String, bool>) saveFilters;
  final Map<String, bool> currentFilters;
  const FiltersScreen(this.currentFilters, this.saveFilters, {super.key});

  @override
  State<FiltersScreen> createState() => FiltersScreenState();
}

class FiltersScreenState extends State<FiltersScreen> {
  var _irbid = false;
  var _amman = false;
  var _aqaba = false;

  @override
  initState() {
    _irbid = widget.currentFilters['Irbid'] ?? false;
    _amman = widget.currentFilters['Amman'] ?? false;
    _aqaba = widget.currentFilters['Aqaba'] ?? false;
    super.initState();
  }

  Widget _buildFilterTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.getPrimary(isDark);
    final surfaceColor = AppTheme.getSurface(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textHint = AppTheme.getTextHint(isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: value ? AppTheme.buttonShadow : AppTheme.premiumShadow(isDark),
        border: value
            ? Border.all(color: primary.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        secondary: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: value
                ? primary.withOpacity(0.1)
                : AppTheme.getElevatedSurface(isDark),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(
            icon,
            color: value ? primary : textHint,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'ElMessiri',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: value ? primary : textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'ElMessiri',
            fontSize: 13,
            color: textHint,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppTheme.getPrimary(isDark);
    final textPrimary = AppTheme.getTextPrimary(isDark);
    final textSecondary = AppTheme.getTextSecondary(isDark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الفلترة'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    colors: [AppTheme.darkElevated, AppTheme.darkSurface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextButton.icon(
              onPressed: () {
                final selectedFilters = {
                  'Irbid': _irbid,
                  'Amman': _amman,
                  'Aqaba': _aqaba,
                };
                widget.saveFilters(selectedFilters);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حفظ الفلاتر')),
                );
              },
              icon: const Icon(Icons.check_rounded, color: Colors.white),
              label: const Text(
                'حفظ',
                style: TextStyle(
                  fontFamily: 'ElMessiri',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.getScaffoldBg(isDark),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const SizedBox(height: 8),
            Text(
              'اختر المدن',
              style: TextStyle(
                fontFamily: 'ElMessiri',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'حدد المدن التي تريد عرض خدماتها',
              style: TextStyle(
                fontFamily: 'ElMessiri',
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            // Filter tiles
            _buildFilterTile(
              title: 'إربد',
              subtitle: 'عرض الخدمات في إربد',
              icon: Icons.location_city_rounded,
              value: _irbid,
              onChanged: (newValue) {
                setState(() => _irbid = newValue);
              },
            ),
            _buildFilterTile(
              title: 'عمان',
              subtitle: 'عرض الخدمات في عمان',
              icon: Icons.location_city_rounded,
              value: _amman,
              onChanged: (newValue) {
                setState(() => _amman = newValue);
              },
            ),
            _buildFilterTile(
              title: 'العقبة',
              subtitle: 'عرض الخدمات في العقبة',
              icon: Icons.location_city_rounded,
              value: _aqaba,
              onChanged: (newValue) {
                setState(() => _aqaba = newValue);
              },
            ),
          ],
        ),
      ),
    );
  }
}
