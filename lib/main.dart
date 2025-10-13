import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routes.dart';
import 'theme.dart';
import 'providers/auth_provider.dart';
import 'providers/log_provider.dart';
import 'providers/vehicule_provider.dart';
import 'providers/particulier_provider.dart';
import 'providers/entreprise_provider.dart';
import 'providers/contravention_provider.dart';
import 'providers/permis_provider.dart';
import 'providers/avis_provider.dart';
import 'providers/accident_provider.dart';
import 'providers/arrestation_provider.dart';
import 'providers/search_provider.dart';
import 'providers/conducteur_provider.dart';
import 'providers/global_search_provider.dart';
import 'providers/alert_provider.dart';
import 'widgets/schedule_guard.dart';
import 'widgets/activity_detector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider();
  await auth.loadFromStorage();
  runApp(MyApp(auth: auth));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.auth});
  final AuthProvider? auth;

  @override
  Widget build(BuildContext context) {
    final providedAuth = auth ?? AuthProvider();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: providedAuth),
        ChangeNotifierProvider(create: (_) => LogProvider()),
        ChangeNotifierProvider(create: (_) => VehiculeProvider()),
        ChangeNotifierProvider(create: (_) => ParticulierProvider()),
        ChangeNotifierProvider(create: (_) => EntrepriseProvider()),
        ChangeNotifierProvider(create: (_) => ContraventionProvider()),
        ChangeNotifierProvider(create: (_) => PermisProvider()),
        ChangeNotifierProvider(create: (_) => AvisProvider()),
        ChangeNotifierProvider(create: (_) => AccidentProvider()),
        ChangeNotifierProvider(create: (_) => ArrestationProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => ConducteurProvider()),
        ChangeNotifierProvider(create: (_) => GlobalSearchProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
      ],
      child: ScheduleGuard(
        child: ActivityDetector(
          child: MaterialApp.router(
            title: 'Bureau de Contrôle Routier',
            theme: buildAppTheme(),
            routerConfig: createRouter(providedAuth),
          ),
        ),
      ),
    );
  }
}
