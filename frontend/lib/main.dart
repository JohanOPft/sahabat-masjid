import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/auth_state.dart';
import 'screens/public/public_home_screen.dart';
import 'screens/public/public_activities_screen.dart';
import 'screens/public/public_how_to_donate_screen.dart';
import 'screens/public/public_confirm_donation_screen.dart';
import 'screens/public/public_reports_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/activities_manage_screen.dart';
import 'screens/admin/donations_manage_screen.dart';
import 'screens/admin/expenses_manage_screen.dart';
import 'screens/admin/cash_manage_screen.dart';
import 'screens/admin/confirmations_manage_screen.dart';
import 'screens/admin/reports_manage_screen.dart';
import 'screens/admin/users_manage_screen.dart';
import 'screens/admin/mosque_info_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
      ],
      child: const SahabatMasjidApp(),
    ),
  );
}

class SahabatMasjidApp extends StatelessWidget {
  const SahabatMasjidApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahabat Masjid - Masjid Al-Ikhlas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          primary: const Color(0xFF0F766E),
          secondary: const Color(0xFF059669),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F766E),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: false,
        ),
        // NFR-01: Ukuran huruf memadai untuk kemudahan baca lansia
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 15),
          titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      initialRoute: '/',
      routes: {
        // Halaman Publik (Jamaah & Donatur)
        '/': (ctx) => const PublicHomeScreen(),
        '/public-activities': (ctx) => const PublicActivitiesScreen(),
        '/how-to-donate': (ctx) => const PublicHowToDonateScreen(),
        '/confirm-donation': (ctx) => const PublicConfirmDonationScreen(),
        '/public-reports': (ctx) => const PublicReportsScreen(),

        // Auth
        '/login': (ctx) => const LoginScreen(),
        '/register': (ctx) => const RegisterScreen(),

        // Halaman Pengurus (Admin/Marbot & Takmir)
        '/admin/dashboard': (ctx) => const DashboardScreen(),
        '/admin/activities': (ctx) => const ActivitiesManageScreen(),
        '/admin/donations': (ctx) => const DonationsManageScreen(),
        '/admin/expenses': (ctx) => const ExpensesManageScreen(),
        '/admin/cash': (ctx) => const CashManageScreen(),
        '/admin/confirmations': (ctx) => const ConfirmationsManageScreen(),
        '/admin/reports': (ctx) => const ReportsManageScreen(),
        '/admin/users': (ctx) => const UsersManageScreen(),
        '/admin/mosque-info': (ctx) => const MosqueInfoScreen(),
      },
    );
  }
}
