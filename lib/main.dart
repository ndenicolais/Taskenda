// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'core/routing/app_router.dart';
import 'core/routing/home_widget_launch_handler.dart';
import 'core/routing/shared_text_launch_handler.dart';
import 'core/routing/notification_launch_handler.dart';
import 'core/routing/start_section_launcher.dart';
import 'l10n/l10n.dart';
import 'providers/auth_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/core_providers.dart';
import 'providers/crypto_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/reminders_actions.dart';
import 'providers/push_provider.dart';
import 'providers/sharing_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/settings/locale_provider.dart';
import 'providers/settings/settings_sync.dart';
import 'providers/settings/theme_provider.dart';
import 'providers/settings/ui_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/boot_error_screen.dart';
import 'screens/crypto/crypto_gate.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_spacing.dart';
import 'theme/app_theme.dart';
import 'utils/app_bootstrap.dart';
import 'utils/widget_service.dart';
import 'widgets/shared/app_logo.dart';
import 'widgets/sync_status_listener.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppBootstrap.installErrorHandlers();
  _start();
}

Future<void> _start() async {
  try {
    final prefs = await AppBootstrap.init();
    runApp(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const NotesApp(),
      ),
    );
  } catch (e, st) {
    if (kDebugMode) debugPrint('Bootstrap failed: $e\n$st');
    runApp(BootErrorApp(error: e, onRetry: _start));
  }
}

class NotesApp extends ConsumerWidget {
  const NotesApp({super.key});

  static final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);

    // Keep the Android home-screen widgets in sync whenever notes, tasks or
    // events change — otherwise they stay on their placeholder values forever.
    ref.listen(activeNotesProvider, (_, _) => _syncHomeWidget(ref));
    ref.listen(activeTasksProvider, (_, _) => _syncHomeWidget(ref));
    ref.listen(activeEventsProvider, (_, _) => _syncHomeWidget(ref));
    // The widget labels are in the UI language.
    ref.listen(appLanguageProvider, (_, _) => _syncHomeWidget(ref));
    // The list widgets follow the app theme.
    ref.listen(themeModeProvider, (_, _) => _syncHomeWidget(ref));
    // Reminders live on the device: rebuild them from the account once its
    // data can be read (keys unlocked, also on a cold start) and cancel them
    // after a sign-out, so another account's reminders never fire.
    // Preferences follow the account too (SettingsSync).
    ref.listen(itemCipherProvider, (previous, cipher) {
      if (cipher != null && previous == null) {
        ref.read(remindersActionsProvider).resync();
      }
    });
    ref.listen(currentUidProvider, (previous, uid) {
      final reminders = ref.read(remindersActionsProvider);
      final settings = ref.read(settingsSyncProvider);
      if (uid.isNotEmpty) {
        settings.start(uid);
        // So that items shared with this user reach this device as pushes.
        ref.read(pushMessagingProvider).register(uid);
      } else if (previous != null && previous.isNotEmpty) {
        settings.stop();
        reminders.cancelAll();
        // Signed out: drop the sections pushed over the root (drawer, start
        // section), or they would stay on top of the login screen.
        _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });
    // Keep the user's email → uid entry current, so other users can share
    // notes with them by email. Best effort: retried at the next sign-in.
    ref.listen(currentShareMemberProvider, (previous, me) {
      if (me == null || me == previous) return;
      ref
          .read(userDirectoryProvider)
          .register(me)
          .catchError((Object e) => debugPrint('Directory not updated: $e'));
    });

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Taskenda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,
      // Null follows the device; English comes first in supportedLocales, so
      // an unsupported device language falls back to it.
      locale: ref.watch(appLanguageProvider).locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        // DateFormat calls without an explicit locale follow the UI language.
        Intl.defaultLocale = Localizations.localeOf(context).languageCode;
        return SyncStatusListener(child: child!);
      },
      home: authState.when(
        loading: () => const _SplashScreen(),
        error: (_, __) => const LoginScreen(),
        data:
            (user) =>
                user != null
                    // With end-to-end encryption, the app only once the
                    // keys are unlocked.
                    ? (ref.watch(e2eeEnabledProvider)
                        ? CryptoGate(
                          loading: const _SplashScreen(),
                          child: _signedInHome,
                        )
                        : _signedInHome)
                    : ref.watch(onboardingSeenProvider)
                    ? const LoginScreen()
                    : const OnboardingScreen(),
      ),
      onGenerateRoute: AppRouter.onGenerateRoute,
      onUnknownRoute: AppRouter.onUnknownRoute,
    );
  }

  // Outermost, so the start section is pushed before anything a
  // notification or widget tap opens.
  static final Widget _signedInHome = StartSectionLauncher(
    child: NotificationLaunchHandler(
      child: const HomeWidgetLaunchHandler(
        child: SharedTextLaunchHandler(child: HomeScreen()),
      ),
    ),
  );

  void _syncHomeWidget(WidgetRef ref) {
    WidgetService.instance.scheduleSync(
      ref.read(activeNotesProvider),
      ref.read(activeTasksProvider),
      ref.read(activeEventsProvider),
      ref.read(themeModeProvider),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(),
            const SizedBox(height: AppSpacing.xl),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
