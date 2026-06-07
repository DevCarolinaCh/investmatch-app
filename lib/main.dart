import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'shared/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forzar orientación vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurar timeago en español
  timeago.setLocaleMessages('es', timeago.EsMessages());

  // Inicializar Firebase
  await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      child: InvestMatchApp(),
    ),
  );
}

class InvestMatchApp extends ConsumerStatefulWidget {
  const InvestMatchApp({super.key});

  @override
  ConsumerState<InvestMatchApp> createState() => _InvestMatchAppState();
}

class _InvestMatchAppState extends ConsumerState<InvestMatchApp> {
  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final api = ref.read(apiServiceProvider);
    await NotificationService.instance.initialize(api);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'InvestMatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        // Escalar texto consistente independientemente del tamaño de fuente del sistema
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }
}
