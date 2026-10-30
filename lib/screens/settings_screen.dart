import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/api_key_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  bool _isApiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final currentKey = await ApiKeyService.getActiveApiKey();
    if (currentKey != null && mounted) {
      _apiKeyController.text = currentKey;
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('google_api_key_request'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiKeyService.saveApiKey(key);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('google_api_key_saved'.tr())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openGoogleAIStudio() async {
    final Uri url = Uri.parse('google_api_key_page_link'.tr());
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('google_api_key_page_not_available'.tr())),
        );
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings_title'.tr()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // SEZIONE LINGUA
          Text(
            'select_language'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                /*
                RadioListTile<Locale>(
                  title: const Text('Italiano'),
                  subtitle: const Text('🇮🇹 IT'),
                  value: const Locale('it', 'IT'),
                  groupValue: context.locale,
                  onChanged: (locale) {
                    if (locale != null) context.setLocale(locale);
                  },
                ),
                RadioListTile<Locale>(
                  title: const Text('English'),
                  subtitle: const Text('🇬🇧 EN'),
                  value: const Locale('en', 'US'),
                  groupValue: context.locale,
                  onChanged: (locale) {
                    if (locale != null) context.setLocale(locale);
                  },
                ),
                RadioListTile<Locale>(
                  title: const Text('Deutsch'),
                  subtitle: const Text('🇩🇪 DE'),
                  value: const Locale('de', 'DE'),
                  groupValue: context.locale,
                  onChanged: (locale) {
                    if (locale != null) context.setLocale(locale);
                  },
                ),
                */
                RadioGroup<Locale>(
                  groupValue: context.locale,
                  onChanged: (Locale? locale) {
                    if (locale != null) {
                      context.setLocale(locale);
                    }
                  },
                  child: Column(
                    children: [
                      RadioListTile<Locale>(
                        title: const Text('Italiano'),
                        subtitle: const Text('🇮🇹 IT'),
                        value: const Locale('it', 'IT'),
                      ),
                      RadioListTile<Locale>(
                        title: const Text('English'),
                        subtitle: const Text('🇬🇧 EN'),
                        value: const Locale('en', 'US'),
                      ),
                      RadioListTile<Locale>(
                        title: const Text('Deutsch'),
                        subtitle: const Text('🇩🇪 DE'),
                        value: const Locale('de', 'DE'),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SEZIONE API KEY
          Text(
            'google_api_key_config'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'google_api_key_description'.tr(),
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'google_api_key_instructions'.tr(),
                    style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _openGoogleAIStudio,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text('google_api_key_action'.tr()),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const Divider(height: 24),
                  TextField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: 'google_api_key_name'.tr(),
                      border: const OutlineInputBorder(),
                      hintText: 'google_api_key_sample'.tr(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isApiKeyVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isApiKeyVisible = !_isApiKeyVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_isApiKeyVisible,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveApiKey,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator.adaptive()
                          : Text('google_api_key_save'.tr(), style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}