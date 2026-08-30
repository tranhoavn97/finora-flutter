import 'package:flutter/material.dart';

import '../data/services/auth_repository.dart';
import 'theme.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        await AuthRepository().signUpWithEmail(
            _email.text.trim(), _password.text, _name.text.trim());
      } else {
        await AuthRepository()
            .signInWithEmail(_email.text.trim(), _password.text);
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _error = 'Không thể đăng nhập. Hãy kiểm tra lại thông tin.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      color: FinoraTheme.lime,
                      borderRadius: BorderRadius.circular(15)),
                  child:
                      const Icon(Icons.bolt_rounded, color: FinoraTheme.ink)),
              const SizedBox(width: 12),
              const Text('FINORA',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2)),
            ]),
            const SizedBox(height: 68),
            Text(
                _register
                    ? 'Tạo không gian\ntài chính của bạn.'
                    : 'Tiền bạc,\nnhưng dễ hiểu.',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontSize: 42)),
            const SizedBox(height: 14),
            Text('Một nơi để nhìn rõ dòng tiền, kế hoạch và tương lai.',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: .58),
                    fontSize: 16,
                    height: 1.5)),
            const SizedBox(height: 38),
            if (_register) ...[
              TextField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Tên của bạn')),
              const SizedBox(height: 12)
            ],
            TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(
                controller: _password,
                obscureText: true,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(labelText: 'Mật khẩu')),
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!,
                      style: const TextStyle(color: FinoraTheme.coral))),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_register ? 'Tạo tài khoản' : 'Đăng nhập')),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      try {
                        await AuthRepository().signInWithGoogle();
                      } catch (_) {}
                    },
              icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
              label: const Text('Tiếp tục với Google'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  foregroundColor: dark ? Colors.white : FinoraTheme.ink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18))),
            ),
            const SizedBox(height: 18),
            Center(
                child: TextButton(
                    onPressed: () => setState(() => _register = !_register),
                    child: Text(_register
                        ? 'Đã có tài khoản? Đăng nhập'
                        : 'Chưa có tài khoản? Đăng ký'))),
          ]),
        ),
      ),
    );
  }
}
