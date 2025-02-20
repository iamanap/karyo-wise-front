import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:karyo_wise/pages/annotation_page.dart';
import 'package:karyo_wise/pages/home_page.dart';
import 'package:karyo_wise/theme.dart';
import 'package:system_theme/system_theme.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:go_router/go_router.dart';
import 'package:karyo_wise/constants.dart';

const String appTitle = 'Karyo Wise';

/// Checks if the current environment is a desktop environment.
bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // if it's not on the web, windows or android, load the accent color
  if (!kIsWeb &&
      [
        TargetPlatform.windows,
        TargetPlatform.android,
      ].contains(defaultTargetPlatform)) {
    SystemTheme.accentColor.load();
  }

  if (isDesktop) {
    await flutter_acrylic.Window.initialize();
    if (defaultTargetPlatform == TargetPlatform.windows) {
      await flutter_acrylic.Window.hideWindowControls();
    }
    await WindowManager.instance.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
      await windowManager.setMinimumSize(const Size(800, 600));
      await windowManager.show();
      await windowManager.setTitle(appTitle);
      await windowManager.setPreventClose(true);
      await windowManager.setSkipTaskbar(false);
      await windowManager.setMaximizable(true);
      await windowManager.maximize();
    });
  }

  runApp(const MyApp());
}

@override
void onWindowClose() async {}

final appTheme = AppTheme();
HomePage homePage = const HomePage();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final rootNavigatorKey = GlobalKey<NavigatorState>();
    final shellNavigatorKey = GlobalKey<NavigatorState>();
    final router = GoRouter(navigatorKey: rootNavigatorKey, routes: [
      ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) {
            return homePage;
          },
          routes: [
            GoRoute(
                name: 'Home', path: '/', builder: (context, state) => homePage),
            GoRoute(
                name: 'Annotations',
                path: '/annotations',
                builder: (context, state) =>
                    const AnnotationPage(metaphase: null))
          ])
    ]);

    return FluentApp.router(
      routerConfig: router,
      title: 'Karyo Wise',
      debugShowCheckedModeBanner: false,
    );
  }
}
