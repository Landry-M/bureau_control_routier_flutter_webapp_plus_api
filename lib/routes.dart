import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'screens/login_screen.dart';
import 'screens/first_connection_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/logs/logs_screen.dart';
import 'screens/activity_report_screen.dart';
import 'screens/all_records_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/vehicules_screen.dart';
import 'screens/contraventions_screen.dart';
import 'screens/accidents_screen.dart';
import 'screens/avis_recherche_screen.dart';
import 'screens/permis_temporaire_screen.dart';
import 'screens/arrestations_screen.dart';
import 'screens/users_screen.dart';
import 'screens/create_dossier_screen.dart';
import 'screens/search_results_screen.dart';
import 'screens/vehicule_detail_screen.dart';
import 'providers/auth_provider.dart';

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final isFirstConnection = auth.isFirstConnection;
      final loggingIn = state.matchedLocation == '/login';
      final onFirstConnection = state.matchedLocation == '/first-connection';

      // If not logged in and not on login page, redirect to login
      if (!loggedIn && !loggingIn) return '/login';

      // If logged in but first connection, redirect to first connection page
      if (loggedIn && isFirstConnection && !onFirstConnection)
        return '/first-connection';

      // If logged in, not first connection, and on login page, redirect to dashboard
      if (loggedIn && !isFirstConnection && loggingIn) return '/dashboard';

      // If logged in, not first connection, and on first connection page, redirect to dashboard
      if (loggedIn && !isFirstConnection && onFirstConnection)
        return '/dashboard';

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: '/first-connection',
        name: 'first_connection',
        builder: (BuildContext context, GoRouterState state) =>
            const FirstConnectionScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (BuildContext context, GoRouterState state) =>
            const DashboardScreen(),
      ),
      GoRoute(
        path: '/alerts',
        name: 'alerts',
        builder: (BuildContext context, GoRouterState state) =>
            const AlertsScreen(),
      ),
      GoRoute(
        path: '/logs',
        name: 'logs',
        builder: (BuildContext context, GoRouterState state) =>
            const LogsScreen(),
      ),
      GoRoute(
        path: '/activity-report',
        name: 'activity_report',
        redirect: (context, state) {
          // Seuls les superadmins peuvent accéder aux rapports d'activité
          final role = auth.role;
          if (role != 'superadmin') {
            return '/dashboard'; // Rediriger vers le dashboard si pas superadmin
          }
          return null;
        },
        builder: (BuildContext context, GoRouterState state) =>
            const ActivityReportScreen(),
      ),
      GoRoute(
        path: '/all-records',
        name: 'all_records',
        builder: (BuildContext context, GoRouterState state) =>
            const AllRecordsScreen(),
      ),
      GoRoute(
        path: '/vehicules',
        name: 'vehicules',
        builder: (BuildContext context, GoRouterState state) =>
            const VehiculesScreen(),
      ),
      GoRoute(
        path: '/contraventions',
        name: 'contraventions',
        builder: (BuildContext context, GoRouterState state) =>
            const ContraventionsScreen(),
      ),
      GoRoute(
        path: '/accidents',
        name: 'accidents',
        builder: (BuildContext context, GoRouterState state) =>
            const AccidentsScreen(),
      ),
      GoRoute(
        path: '/avis-recherche',
        name: 'avis_recherche',
        builder: (BuildContext context, GoRouterState state) =>
            const AvisRechercheScreen(),
      ),
      GoRoute(
        path: '/permis-temporaire',
        name: 'permis_temporaire',
        builder: (BuildContext context, GoRouterState state) =>
            const PermisTemporaireScreen(),
      ),
      GoRoute(
        path: '/arrestations',
        name: 'arrestations',
        builder: (BuildContext context, GoRouterState state) =>
            const ArrestationsScreen(),
      ),
      GoRoute(
        path: '/users',
        name: 'users',
        builder: (BuildContext context, GoRouterState state) =>
            const UsersScreen(),
      ),
      GoRoute(
        path: '/create-dossier',
        name: 'create_dossier',
        builder: (BuildContext context, GoRouterState state) =>
            const CreateDossierScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (BuildContext context, GoRouterState state) {
          final q = state.uri.queryParameters['q'] ?? '';
          final type = state.uri.queryParameters['type'] ?? 'general';
          return SearchResultsScreen(query: q, type: type);
        },
      ),
      GoRoute(
        path: '/vehicule/:id',
        name: 'vehicule_detail',
        builder: (BuildContext context, GoRouterState state) {
          final id = state.pathParameters['id'] ?? '';
          return VehiculeDetailScreen(id: id);
        },
      ),
    ],
  );
}
