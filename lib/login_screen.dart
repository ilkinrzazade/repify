import 'package:flutter/material.dart';

import 'api_client.dart';
import 'app_theme.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'workout_store.dart';

/// Signature of the function that logs in or creates an account.
/// Tests pass a fake one, the app uses the real server.
typedef AuthenticateFn = Future<void> Function(
  String email,
  String password, {
  required bool createAccount,
});

Future<void> _authenticateWithServer(
  String email,
  String password, {
  required bool createAccount,
}) async {
  if (createAccount) {
    await ApiClient.instance.register(email, password);
  } else {
    await ApiClient.instance.login(email, password);
  }
  await WorkoutStore.instance.onLoggedIn();
}

class LoginScreen extends StatefulWidget {
  final AuthenticateFn? authenticate;

  const LoginScreen({super.key, this.authenticate});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool hidePassword = true;
  bool createAccount = false;
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: Colors.red),
    );
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      showError('Please fill in both fields');
      return;
    }
    setState(() => loading = true);
    try {
      final authenticate = widget.authenticate ?? _authenticateWithServer;
      await authenticate(email, password, createAccount: createAccount);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      showError(e is ApiException ? e.message : 'Something went wrong: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Neon glow in the top corner.
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.lime.withAlpha(55), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: limeCardDecoration(radius: 26),
                            child: const Icon(
                              Icons.fitness_center,
                              size: 46,
                              color: AppColors.onLime,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Repify',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Track every rep. See your progress.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, fontSize: 14),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                createAccount ? 'Create account' : 'Welcome!',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                createAccount
                                    ? 'Your workouts are saved on the server'
                                    : 'Log in to continue',
                                style: const TextStyle(color: AppColors.muted),
                              ),
                              const SizedBox(height: 22),
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: AppColors.text),
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.alternate_email),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: passwordController,
                                obscureText: hidePassword,
                                style: const TextStyle(color: AppColors.text),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  helperText: createAccount ? 'At least 6 characters' : null,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      hidePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        hidePassword = !hidePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: loading ? null : submit,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 17),
                                ),
                                child: loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.lime,
                                        ),
                                      )
                                    : Text(
                                        createAccount ? 'Create account' : 'Log In',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: loading
                                    ? null
                                    : () => setState(() => createAccount = !createAccount),
                                child: Text(
                                  createAccount
                                      ? 'Already have an account? Log in'
                                      : 'No account? Create one',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.dns_outlined, color: AppColors.muted),
                    tooltip: 'Server address',
                    onPressed: () => showServerUrlDialog(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
