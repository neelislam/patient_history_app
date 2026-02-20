import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/controllers.dart';

import 'mdoel/disease_model.dart';
import 'screens/welcome_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/questionnaire_screen.dart';
import 'screens/settings_screen.dart';

// Import your existing pages here
import 'pages/emergency_page.dart';
import 'pages/disease_page.dart';
import 'pages/medicine_page.dart';
import 'pages/search_page.dart';

Future<void> _ensureAuth() async {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _ensureAuth();
  runApp(const PatientHistoryApp());
}

class PatientHistoryApp extends StatelessWidget {
  const PatientHistoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject Controllers globally
    Get.put(PatientController()..init());
    Get.put(EmergencyController());
    Get.put(DiseaseController());
    Get.put(MedicineController());

    final textTheme = GoogleFonts.interTextTheme();

    return GetMaterialApp(
      title: 'Patient History App BD',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF2BCDEE),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2BCDEE), primary: const Color(0xFF2BCDEE), surface: const Color(0xFFF6F8F8)),
        scaffoldBackgroundColor: const Color(0xFFF6F8F8),
        textTheme: textTheme,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF2BCDEE),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2BCDEE), primary: const Color(0xFF2BCDEE), surface: const Color(0xFF101F22), brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF101F22),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const WelcomeScreen()),
        GetPage(name: '/registration', page: () => const RegistrationScreen()),
        GetPage(name: '/dashboard', page: () => const DashboardScreen()),
        GetPage(name: '/questionnaire', page: () => const QuestionnaireScreen()),
        GetPage(name: '/settings', page: () => const SettingsScreen()),

        // Old functional CRUD Pages
        GetPage(name: '/emergency', page: () => const EmergencyPage()),
        GetPage(name: '/diseases', page: () => const DiseasePage()),
        GetPage(name: '/medicines', page: () => const MedicinePage()),
        GetPage(name: '/search', page: () => const SearchPage()),
      ],
    );
  }
}