import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_exception.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl = TextEditingController(
    text: widget.initialEmail,
  );
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Erreur reseau. Reessayez.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _sendCode() => _run(() async {
    final service = context.read<AuthProvider>().authService;
    await service.forgotPassword(_emailCtrl.text.trim());
    if (mounted) setState(() => _codeSent = true);
  });

  Future<void> _reset() => _run(() async {
    final service = context.read<AuthProvider>().authService;
    await service.resetPassword(
      email: _emailCtrl.text.trim(),
      code: _codeCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mot de passe modifie. Connectez-vous.')),
    );
    Navigator.of(context).pop();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublie')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _codeSent
                      ? 'Un code a 6 chiffres a ete envoye a ${_emailCtrl.text.trim()} (s\'il correspond a un compte). Saisissez-le avec votre nouveau mot de passe.'
                      : 'Saisissez votre email pour recevoir un code de reinitialisation.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailCtrl,
                  enabled: !_codeSent,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Email invalide' : null,
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Code a 6 chiffres',
                      counterText: '',
                    ),
                    validator: (v) => (v == null || !RegExp(r'^\d{6}$').hasMatch(v.trim()))
                        ? 'Le code doit contenir 6 chiffres'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Au moins 6 caracteres'
                        : null,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.brand500.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppColors.brand500.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.brand400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _codeSent ? 'Changer le mot de passe' : 'Envoyer le code',
                  loading: _loading,
                  onPressed: _codeSent ? _reset : _sendCode,
                ),
                if (_codeSent)
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() {
                        _codeSent = false;
                        _error = null;
                      }),
                      child: const Text('Renvoyer un code'),
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
