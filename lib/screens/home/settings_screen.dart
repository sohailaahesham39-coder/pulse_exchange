import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/AppConstants.dart';
import '../../services/AuthService.dart';
import '../../widget/common/CustomButton.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationEnabled = true;
  String _language = 'English';
  String _theme = 'System';
  int _syncInterval = 15;
  bool _isLoading = false;

  final List<String> _languages = ['English', 'Arabic', 'Spanish', 'French'];
  final List<String> _themes = ['System', 'Light', 'Dark'];
  final List<int> _syncIntervals = [15, 30, 60, 120, 240];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _locationEnabled = prefs.getBool('location_enabled') ?? true;
        _language = prefs.getString(AppConstants.languagePreferenceKey) ??
            AppConstants.defaultLanguage;
        _theme = prefs.getString(AppConstants.themePreferenceKey) ??
            AppConstants.defaultTheme;
        _syncInterval = prefs.getInt('sync_interval') ??
            AppConstants.defaultSyncInterval;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('location_enabled', _locationEnabled);
      await prefs.setString(AppConstants.languagePreferenceKey, _language);
      await prefs.setString(AppConstants.themePreferenceKey, _theme);
      await prefs.setInt('sync_interval', _syncInterval);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } catch (e) {
      debugPrint('Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        await Future.delayed(const Duration(seconds: 2));
        await authService.logout();

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
                (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Error deleting account: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting account: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Privacy'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Location Services'),
                    subtitle: const Text('Enable location for nearby medication searches'),
                    value: _locationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _locationEnabled = value;
                      });
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Data Sharing'),
                    subtitle: const Text('Manage how your data is shared'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data sharing settings not implemented')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Appearance'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Language'),
                    subtitle: Text(_language),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showLanguageSelectionDialog();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Theme'),
                    subtitle: Text(_theme),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showThemeSelectionDialog();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Data'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Sync Interval'),
                    subtitle: Text('$_syncInterval minutes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showSyncIntervalSelectionDialog();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Export Data'),
                    subtitle: const Text('Export your health data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data export not implemented')),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Clear Data'),
                    subtitle: const Text('Delete all locally stored data'),
                    trailing: const Icon(Icons.delete_outline),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear Data'),
                          content: const Text(
                              'Are you sure you want to delete all locally stored data?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true && mounted) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Local data cleared')),
                        );
                        _loadSettings();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Account'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Change Password'),
                    subtitle: const Text('Update your account password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Change password not implemented')),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Logout'),
                    subtitle: const Text('Sign out of your account'),
                    trailing: const Icon(Icons.logout),
                    onTap: () async {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      await authService.logout();
                      if (mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                              (route) => false,
                        );
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Delete Account'),
                    subtitle: const Text('Permanently remove your account and data'),
                    trailing: const Icon(Icons.delete_forever, color: Colors.red),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('About'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('App Version'),
                    subtitle: Text(AppConstants.appVersion),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Terms of Service'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terms of service not implemented')),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy policy not implemented')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                label: 'Save Settings',
                onPressed: _saveSettings,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languages.map((language) {
              return RadioListTile<String>(
                title: Text(language),
                value: language,
                groupValue: _language,
                onChanged: (value) {
                  setState(() {
                    _language = value!;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showThemeSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _themes.map((theme) {
              return RadioListTile<String>(
                title: Text(theme),
                value: theme,
                groupValue: _theme,
                onChanged: (value) {
                  setState(() {
                    _theme = value!;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSyncIntervalSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Interval'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _syncIntervals.map((interval) {
              return RadioListTile<int>(
                title: Text('$interval minutes'),
                value: interval,
                groupValue: _syncInterval,
                onChanged: (value) {
                  setState(() {
                    _syncInterval = value!;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}