import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  timeago.setLocaleMessages('es', timeago.EsMessages());

  // Firebase se inicializa cuando se configuren las credenciales reales
  // await Firebase.initializeApp();

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
