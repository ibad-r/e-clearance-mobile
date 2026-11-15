import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_state.dart';
import 'core/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppState _state = AppState();
  final ThemeController _theme = ThemeController();
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _theme.load();
    _state.addListener(_onStateChanged);
    _restoreSession();
  }

  /// Checks a saved login token with the server when the app starts.
  Future<void> _restoreSession() async {
    try {
      await _state.restoreSession().timeout(const Duration(seconds: 20));
    } catch (_) {
      // The saved session could not be confirmed (no network, server down).
      // Start from the role selection screen instead of guessing.
      try {
        await _state.logout();
      } catch (_) {}
    }
    if (!mounted) return;
    _state.sessionExpired = false;
    setState(() => _ready = true);
  }

  /// When the server says the token has expired, return to role selection.
  void _onStateChanged() {
    if (!_state.sessionExpired) return;
    _state.sessionExpired = false;
    if (!_ready) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.roleSelection, (route) => false);
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please log in again.'),
        ),
      );
    });
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _state.dispose();
    _theme.dispose();
    super.dispose();
  }

  String get _initialRoute {
    if (_state.employee != null) return AppRoutes.dashboard;
    if (_state.isStudentSignedIn) return AppRoutes.studentHome;
    return AppRoutes.roleSelection;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: _state),
        ChangeNotifierProvider<ThemeController>.value(value: _theme),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeCtrl, _) => MaterialApp(
          title: 'E-Clearance',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeCtrl.mode,
          navigatorKey: _navigatorKey,
          scaffoldMessengerKey: _messengerKey,
          initialRoute: _initialRoute,
          routes: AppRoutes.table,
          // Shows a spinner until the saved session has been checked.
          builder: (context, child) => _ready
              ? child!
              : const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}