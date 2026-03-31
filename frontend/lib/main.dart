import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

// ── Providers ──
import 'package:arth/ai_chat_provider.dart';
import 'package:arth/dashboard_provider.dart';
import 'package:arth/transaction_provider.dart';
import 'package:arth/budget_provider.dart';
import 'package:arth/goal_provider.dart';
import 'package:arth/profile_provider.dart';
import 'package:arth/auth_provider.dart';
import 'package:arth/translation_provider.dart'; // ← NEW

// ── Screens ──
import 'package:arth/login_screen.dart';
import 'package:arth/email_auth_screen.dart';
import 'package:arth/profile_setup_screen.dart';
import 'package:arth/home_screen.dart';
import 'package:arth/ai_chat_screen.dart';
import 'package:arth/transactions_screen.dart';
import 'package:arth/budget_screen.dart';
import 'package:arth/goal_screen.dart';
import 'package:arth/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ── Init TranslationProvider BEFORE runApp ──────────────────────────────
  // This loads the saved language + cached translations from SharedPreferences
  // so the very first frame renders in the correct language (no flicker).
  final translationProvider = TranslationProvider();
  await translationProvider.init();
  // ────────────────────────────────────────────────────────────────────────

  runApp(ArthApp(translationProvider: translationProvider));
}

class ArthApp extends StatelessWidget {
  final TranslationProvider translationProvider;

  const ArthApp({super.key, required this.translationProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── TranslationProvider must be FIRST so all other widgets can use it
        ChangeNotifierProvider<TranslationProvider>.value(
          value: translationProvider,
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AiChatProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      // ── Consumer<TranslationProvider> here ensures the ENTIRE app rebuilds
      // when the language changes (including the bottom nav labels).
      child: Consumer<TranslationProvider>(
        builder: (context, tp, _) {
          return MaterialApp(
            title: 'Arth',
            debugShowCheckedModeBanner: false,

            // ── Show a full-screen loader while translations are being fetched
            builder: tp.isTranslating
                ? (_, __) => const _TranslatingOverlay()
                : null,

            theme: ThemeData(
              colorSchemeSeed: const Color(0xFF1D9E75),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1D9E75),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            routes: {
              '/login': (_) => const LoginScreen(),
              '/email-auth': (_) => const EmailAuthScreen(),
              '/profile-setup': (_) => const ProfileSetupScreen(),
              '/home': (_) => const _AppStartup(),
            },
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

// ── Full-screen overlay shown during translation fetch ────────────────────────
class _TranslatingOverlay extends StatelessWidget {
  const _TranslatingOverlay();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'அ',
              style: TextStyle(
                fontSize: 60,
                color: Color(0xFF1D9E75),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Color(0xFF1D9E75)),
            const SizedBox(height: 20),
            Text(
              'மொழிபெயர்க்கிறது...', // "Translating..." in Tamil (hardcoded since provider is loading)
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Auth Gate ─────────────────────────────────────────────────────────────────
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'அ',
                    style: TextStyle(
                      fontSize: 60,
                      color: Color(0xFF1D9E75),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: Color(0xFF1D9E75)),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }
        return const _AppStartup();
      },
    );
  }
}

// ── App Startup ───────────────────────────────────────────────────────────────
class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) => const MainShell();
}

// ── Main Shell ────────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final Set<int> _visitedTabs = {0};

  static const List<Widget> _screens = [
    HomeScreen(),
    AiChatScreen(),
    TransactionsScreen(),
    BudgetScreen(),
    GoalScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Watch TranslationProvider so bottom nav labels update on language change
    final tp = context.watch<TranslationProvider>();

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        body: Stack(
          children: List.generate(_screens.length, (index) {
            final visited = _visitedTabs.contains(index);
            return Offstage(
              offstage: _currentIndex != index,
              child: visited ? _screens[index] : const SizedBox.shrink(),
            );
          }),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) {
              setState(() {
                _visitedTabs.add(i);
                _currentIndex = i;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1D9E75),
            unselectedItemColor: Colors.grey.shade400,
            selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 10),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                label: tp.t('home'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.smart_toy_outlined),
                activeIcon: const Icon(Icons.smart_toy),
                label: tp.t('arthAi'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.receipt_long_outlined),
                activeIcon: const Icon(Icons.receipt_long),
                label: tp.t('history'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.pie_chart_outline),
                activeIcon: const Icon(Icons.pie_chart),
                label: tp.t('budget'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.flag_outlined),
                activeIcon: const Icon(Icons.flag),
                label: tp.t('goals'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: tp.t('profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}