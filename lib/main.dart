import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/buildings_screen.dart';
import 'screens/tenants.dart';
import 'screens/payments_screen.dart';
import 'screens/dashboard.dart';
import 'screens/tenant_payments_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion Locative',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        useMaterial3: true,
        textTheme: GoogleFonts.urbanistTextTheme(),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const BuildingsScreen(),
    const TenantsScreen(),
    const PaymentsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.business),
            label: 'Immeubles',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Locataires',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment),
            label: 'Paiements',
          ),
        ],
      ),
    );
  }
}