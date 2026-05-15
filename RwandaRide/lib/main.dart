import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/trip_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/rider/rider_home_screen.dart';
import 'screens/rider/trip_detail_screen.dart';
import 'screens/driver/driver_home_screen.dart';

void main() {
  runApp(const RwandaRideApp());
}

class RwandaRideApp extends StatelessWidget {
  const RwandaRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'RwandaRide',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            home: _resolveHome(auth),
            routes: {
              '/login': (_) => const LoginScreen(),
              '/register': (_) => const RegisterScreen(),
              '/rider/home': (_) => const RiderHomeScreen(),
              '/rider/trip-detail': (_) => const TripDetailScreen(),
              '/driver/home': (_) => const DriverHomeScreen(),
              '/logout': (ctx) {
                // Trigger logout and return login screen
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ctx.read<AuthProvider>().logout();
                });
                return const LoginScreen();
              },
            },
          );
        },
      ),
    );
  }

  Widget _resolveHome(AuthProvider auth) {
    switch (auth.status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        final role = auth.user?.role;
        if (role == 'driver') return const DriverHomeScreen();
        return const RiderHomeScreen();
    }
  }
}
