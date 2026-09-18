import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emergencyContactNameCtrl = TextEditingController();
  final _emergencyContactPhoneCtrl = TextEditingController();
  String _role = 'victim';

  Timer? _usernameDebounce;
  int _usernameCheckToken = 0;
  bool _checkingUsername = false;
  bool? _usernameAvailable;

  static const _roles = [
    (
      value: 'victim',
      title: 'Utilisateur mobile',
      desc: "Declencher une alerte d'urgence en cas de besoin.",
    ),
    (
      value: 'responder',
      title: 'Repondant',
      desc: 'Recevoir les alertes (via l\'interface web).',
    ),
    (
      value: 'both',
      title: 'Les deux',
      desc: 'Declencher et recevoir des alertes.',
    ),
  ];

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _emergencyContactNameCtrl.dispose();
    _emergencyContactPhoneCtrl.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    setState(() => _usernameAvailable = null);

    final candidate = value.trim().toLowerCase();
    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(candidate)) return;

    _usernameDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _checkUsernameAvailability(candidate),
    );
  }

  Future<void> _checkUsernameAvailability(String candidate) async {
    final token = ++_usernameCheckToken;
    setState(() => _checkingUsername = true);
    bool? available;
    try {
      available = await context.read<AuthProvider>().authService
          .isUsernameAvailable(candidate);
    } catch (_) {
      // Impossible de verifier (reseau) : on ne bloque pas la saisie, la
      // verification faite par le serveur au moment de l'inscription reste
      // la garantie finale.
      available = null;
    }
    if (!mounted || token != _usernameCheckToken) return;
    setState(() {
      _checkingUsername = false;
      _usernameAvailable = available;
    });
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_usernameAvailable == false) return;
    FocusScope.of(context).unfocus();
    final email = _emailCtrl.text.trim();
    final success = await auth.register(
      fullName: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim().toLowerCase(),
      email: email,
      password: _passwordCtrl.text,
      role: _role,
      phone: _phoneCtrl.text.trim(),
      emergencyContactName: _emergencyContactNameCtrl.text.trim(),
      emergencyContactPhone: _emergencyContactPhoneCtrl.text.trim(),
    );
    if (!success || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        icon: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.ok500,
          size: 40,
        ),
        title: const Text('Compte cree'),
        content: const Text(
          'Votre compte a bien ete cree. Connectez-vous avec vos identifiants '
          'pour continuer.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );

    if (mounted) Navigator.of(context).pop(email);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Creer un compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Nom requis'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameCtrl,
                  autocorrect: false,
                  onChanged: _onUsernameChanged,
                  decoration: InputDecoration(
                    labelText: "Nom d'utilisateur",
                    prefixText: '@',
                    suffixIcon: _checkingUsername
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _usernameAvailable == true
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.ok500,
                          )
                        : _usernameAvailable == false
                        ? const Icon(
                            Icons.cancel_rounded,
                            color: AppColors.brand500,
                          )
                        : null,
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return "Nom d'utilisateur requis";
                    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(v)) {
                      return '3-20 caracteres : lettres, chiffres, _';
                    }
                    if (_usernameAvailable == false) {
                      return "Ce nom d'utilisateur est deja pris.";
                    }
                    return null;
                  },
                ),
                if (_usernameAvailable == false) ...[
                  const SizedBox(height: 6),
                  const Text(
                    "Ce nom d'utilisateur est deja pris.",
                    style: TextStyle(color: AppColors.brand400, fontSize: 12.5),
                  ),
                ] else if (_usernameAvailable == true) ...[
                  const SizedBox(height: 6),
                  const Text(
                    "Nom d'utilisateur disponible.",
                    style: TextStyle(color: AppColors.ok500, fontSize: 12.5),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => (value == null || !value.contains('@'))
                      ? 'Email invalide'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telephone (optionnel)',
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Contact d'urgence",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Une personne a prevenir en cas d\'urgence. Visible par le '
                  'repondant qui prend en charge votre alerte.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emergencyContactNameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Nom du contact d'urgence",
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Nom requis'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emergencyContactPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Telephone du contact d'urgence",
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Telephone requis'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  validator: (value) => (value == null || value.length < 6)
                      ? '6 caracteres minimum'
                      : null,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Role',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ..._roles.map((role) {
                  final selected = _role == role.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _role = role.value),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.brand500.withValues(alpha: 0.1)
                              : AppColors.surface2,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppColors.brand500
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selected
                                  ? AppColors.brand500
                                  : AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    role.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    role.desc,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 8),
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
                      auth.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.brand400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Creer mon compte',
                  loading: auth.loading,
                  onPressed: _usernameAvailable == false
                      ? null
                      : () => _submit(auth),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
