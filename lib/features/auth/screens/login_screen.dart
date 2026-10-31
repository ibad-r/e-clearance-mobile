import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/repositories.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'ahsan.khan@demo.riphah.edu');
  final _password = TextEditingController(text: 'Password@123');
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AppState>().login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateEmail(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.verified_user_outlined,
                      color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'E-Clearance',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Riphah International University · Faculty of Computing. '
                      'Sign in to track your employee clearance.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 28),
                const _Label('Email'),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.mail_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                const _Label('Password'),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: _validatePassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                        content: Text('Not available in this demo'))),
                    child: const Text('Forgot password?',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          color: AppTheme.danger, fontSize: 13),
                    ),
                  ),
                PrimaryButton(
                  label: 'Log in',
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 14),
                const Center(
                  child: Text(
                    'Use your university-issued email. Contact IT support '
                        'if you cannot sign in.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.infoBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD3DEF8)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified_user_outlined,
                          size: 16, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Prototype using demo employee data. Not connected '
                              'to real university systems.',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.primary),
                        ),
                      ),
                    ],
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      ),
    );
  }
}