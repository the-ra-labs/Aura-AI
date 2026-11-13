import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../core/theme/app_colors.dart';
import '../widgets/ai_orb.dart';
import '../widgets/buttons.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass_container.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.auth});
  final AuthController auth;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _signup = false, _hide = true, _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final a = widget.auth;
    a.clearError();
    setState(() => _busy = true);
    _signup
        ? await a.signUp(_name.text, _email.text, _pass.text)
        : await a.signIn(_email.text, _pass.text);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _forgot() async {
    final email = await promptText(context,
        title: 'Reset password', hint: 'Apna registered email');
    if (email == null || email.isEmpty || !mounted) return;
    String? pass;
    if (!widget.auth.useFirebase) {
      pass = await promptText(context,
          title: 'Naya password (min 6)', hint: 'New password', obscure: true);
      if (pass == null || pass.length < 6 || !mounted) return;
    }
    final ok = await widget.auth.resetPassword(email, newPass: pass);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? (widget.auth.useFirebase
                ? 'Reset link email par bhej diya'
                : 'Password change ho gaya')
            : (widget.auth.error ?? 'Yeh email registered nahi'))));
  }

  Widget _brand() => ShaderMask(
        shaderCallback: (r) => const LinearGradient(
                colors: [AppColors.cyan, AppColors.violet, AppColors.pink])
            .createShader(r),
        child: const Text('Aura',
            style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.white)),
      );

  Widget _tab(String t, bool sel, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(t,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.textSecondary)),
            ),
          ),
        ),
      );

  Widget _toggle() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18)),
        child: Stack(children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: _signup ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.brand,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.violet.withOpacity(0.5), blurRadius: 16)
                  ],
                ),
              ),
            ),
          ),
          Row(children: [
            _tab('Sign in', !_signup, () => setState(() => _signup = false)),
            _tab('Sign up', _signup, () => setState(() => _signup = true)),
          ]),
        ]),
      );

  Widget _formCard() => GlassContainer(
        radius: 32,
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _toggle(),
            const SizedBox(height: 20),
            if (_signup) ...[
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Full name', prefixIcon: Icon(Icons.person_rounded)),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Naam likhein' : null,
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email', prefixIcon: Icon(Icons.email_rounded)),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Sahi email likhein' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pass,
              obscureText: _hide,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_hide
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Kam az kam 6 characters' : null,
            ),
            if (!_signup)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: _forgot, child: const Text('Forgot password?')),
              ),
            ListenableBuilder(
              listenable: widget.auth,
              builder: (_, __) => widget.auth.error == null
                  ? const SizedBox(height: 14)
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(widget.auth.error!,
                          style: const TextStyle(color: AppColors.pink)),
                    ),
            ),
            GradientButton(
              label: _signup ? 'Create account' : 'Sign in',
              loading: _busy,
              onTap: _submit,
            ),
            if (widget.auth.useFirebase) ...[
              const SizedBox(height: 12),
              GlassContainer(
                radius: 18,
                padding: const EdgeInsets.symmetric(vertical: 13),
                onTap: _busy ? null : () => widget.auth.signInWithGoogle(),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.g_mobiledata_rounded, size: 28),
                  SizedBox(width: 6),
                  Text('Continue with Google',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final formCol = Column(mainAxisSize: MainAxisSize.min, children: [
      _formCard(),
      const SizedBox(height: 8),
      TextButton(
          onPressed: widget.auth.guest, child: const Text('Continue as guest')),
    ]);

    final hero = Column(mainAxisSize: MainAxisSize.min, children: [
      AiOrb(size: wide ? 380 : 190),
      _brand(),
      const SizedBox(height: 4),
      const Text('Your intelligent companion',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
    ]);

    return Scaffold(
      body: SafeArea(
        child: wide
            ? Row(children: [
                Expanded(child: Center(child: hero)),
                SizedBox(
                  width: 500,
                  child: Center(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(28), child: formCol),
                  ),
                ),
              ])
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      hero,
                      const SizedBox(height: 22),
                      formCol,
                    ]),
                  ),
                ),
              ),
      ),
    );
  }
}