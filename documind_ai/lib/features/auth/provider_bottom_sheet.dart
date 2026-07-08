import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/ai_provider.dart';
import '../../core/models/ai_provider_config.dart';
import 'package:go_router/go_router.dart';

class ProviderBottomSheet extends ConsumerStatefulWidget {
  const ProviderBottomSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProviderBottomSheet(),
    );
  }

  @override
  ConsumerState<ProviderBottomSheet> createState() => _ProviderBottomSheetState();
}

class _ProviderBottomSheetState extends ConsumerState<ProviderBottomSheet> {
  final _keyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  
  String _selectedProvider = 'OpenAI';
  bool _isLoading = false;
  String? _error;

  final List<String> _providers = ['OpenAI', 'Gemini', 'Anthropic', 'Groq', 'OpenRouter'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentConfig();
    });
  }

  void _loadCurrentConfig() {
    final currentConfig = ref.read(aiProviderConfigProvider).value;
    if (currentConfig != null) {
      setState(() {
        _selectedProvider = currentConfig.provider;
        _keyController.text = currentConfig.apiKey;
        _baseUrlController.text = currentConfig.baseUrl ?? '';
        _modelController.text = currentConfig.modelName ?? '';
      });
    } else {
      _updateDefaultsForProvider('OpenAI');
    }
  }

  void _updateDefaultsForProvider(String provider) {
    if (provider == 'OpenAI') {
      _baseUrlController.text = ''; // Uses dart_openai default
      _modelController.text = 'gpt-4o-mini';
    } else if (provider == 'Groq') {
      _baseUrlController.text = 'https://api.groq.com/openai';
      _modelController.text = 'llama-3.1-8b-instant';
    } else if (provider == 'OpenRouter') {
      _baseUrlController.text = 'https://openrouter.ai/api';
      _modelController.text = 'meta-llama/llama-3.1-8b-instruct:free';
    } else if (provider == 'Gemini') {
      _baseUrlController.text = '';
      _modelController.text = 'gemini-1.5-flash';
    } else if (provider == 'Anthropic') {
      _baseUrlController.text = '';
      _modelController.text = 'claude-3-haiku-20240307';
    }
  }

  Future<void> _saveConfig() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'API Key cannot be empty');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final config = AIProviderConfig(
      provider: _selectedProvider,
      apiKey: key,
      baseUrl: _baseUrlController.text.trim().isEmpty ? null : _baseUrlController.text.trim(),
      modelName: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
    );

    final success = await ref.read(aiProviderConfigProvider.notifier).validateAndSaveConfig(config);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _error = 'Invalid API Key or connection failed.');
      }
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 32,
      ),
      decoration: BoxDecoration(
        color: AppTheme.amoledBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.vpn_key_rounded, size: 48, color: AppTheme.electricBlue),
              const SizedBox(height: 16),
              const Text(
                'AI Provider Setup',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a provider and enter your API key to power PersonalAI Hub agents.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Provider Dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedProvider,
                    isExpanded: true,
                    dropdownColor: Colors.grey[900],
                    items: _providers.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedProvider = newValue;
                          _updateDefaultsForProvider(newValue);
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _keyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Enter your $_selectedProvider key',
                  prefixIcon: const Icon(Icons.key, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              if (_selectedProvider != 'Gemini') ...[
                TextField(
                  controller: _baseUrlController,
                  decoration: InputDecoration(
                    labelText: 'Base URL (Optional)',
                    hintText: 'Leave empty for default',
                    prefixIcon: const Icon(Icons.link, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              TextField(
                controller: _modelController,
                decoration: InputDecoration(
                  labelText: 'Model Name',
                  hintText: 'e.g. gpt-4o-mini',
                  prefixIcon: const Icon(Icons.smart_toy_rounded, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : () {
                  HapticFeedback.lightImpact();
                  _saveConfig();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save & Connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/api-guide');
                },
                child: const Text('How to get a Free API Key?', style: TextStyle(color: AppTheme.electricBlue)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
