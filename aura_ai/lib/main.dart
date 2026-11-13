import 'package:flutter/material.dart';
import 'controllers/auth_controller.dart';
import 'controllers/settings_controller.dart';
import 'core/store.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell/app_shell.dart';
import 'widgets/ai_orb.dart';
import 'widgets/aurora_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const AuraApp());
}

class AuraApp extends StatefulWidget {
  const AuraApp({super.key});

  @override
  State<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends State<AuraApp> {
  final auth = AuthController();
  final settings = SettingsController();
  bool _onboarded = Store.read('onboarded') == '1';

  @override
  void initState() {
    super.initState();
    settings.load();
    auth.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aura AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark.copyWith(scaffoldBackgroundColor: Colors.transparent),
      builder: (context, child) => ListenableBuilder(
        listenable: settings,
        builder: (_, __) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(settings.textScale)),
          child: AuroraBackground(child: child!),
        ),
      ),
      home: !_onboarded
          ? OnboardingScreen(onDone: () {
              Store.write('onboarded', '1');
              setState(() => _onboarded = true);
            })
          : ListenableBuilder(
              listenable: auth,
              builder: (context, _) {
                if (!auth.ready) {
                  return const Scaffold(body: Center(child: AiOrb(size: 140)));
                }
                if (auth.user == null) return AuthScreen(auth: auth);
                return AppShell(
                    key: ValueKey(auth.user!.id),
                    auth: auth,
                    settings: settings);
              },
            ),
    );
  }
}