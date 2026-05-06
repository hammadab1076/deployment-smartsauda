import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app_colors.dart';

class PreferencesDialog extends StatefulWidget {
  const PreferencesDialog({super.key});

  @override
  State<PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<PreferencesDialog> {
  bool _notifications = true;
  bool _darkMode = false;
  final String _language = "English";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: const Text("Preferences", style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text("Notifications"),
            subtitle: const Text("Enable push notifications"),
            value: _notifications,
            onChanged: (val) => setState(() => _notifications = val),
            activeThumbColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text("Dark Mode"),
            subtitle: const Text("Toggle app theme"),
            value: _darkMode,
            onChanged: (val) => setState(() => _darkMode = val),
            activeThumbColor: AppColors.primary,
          ),
          ListTile(
            title: const Text("Language"),
            subtitle: Text(_language),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Language selection logic
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
