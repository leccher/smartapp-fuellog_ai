import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_key_service.dart';
import 'package:easy_localization/easy_localization.dart';

class ApiKeySettingsScreen extends StatefulWidget {
  const ApiKeySettingsScreen({super.key});

  @override
  State<ApiKeySettingsScreen> createState() => _ApiKeySettingsScreenState();
}

class _ApiKeySettingsScreenState extends State<ApiKeySettingsScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingKey();
  }

  Future<void> _loadExistingKey() async {
    final currentKey = await ApiKeyService.getActiveApiKey();
    if (currentKey != null && mounted) {
      _controller.text = currentKey;
    }
  }

  Future<void> _saveKey() async {
    final key = _controller.text.trim();
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
      
      Navigator.pop(context, true);
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('google_api_key_config'.tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'google_api_key_description'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'google_api_key_instructions'.tr(),
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _openGoogleAIStudio,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text('google_api_key_action'.tr()),
              style: TextButton.styleFrom(alignment: Alignment.centerLeft),
            ),
            const Divider(height: 32),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'google_api_key_name'.tr(),
                border: const OutlineInputBorder(),
                hintText: 'google_api_key_sample'.tr(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveKey,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator.adaptive()
                  : Text('google_api_key_save'.tr(), style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}