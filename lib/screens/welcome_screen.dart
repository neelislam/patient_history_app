import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft, radius: 1.5,
            colors: isDark
                ? [const Color(0xFF2BCDEE).withOpacity(0.3), const Color(0xFF101F22)]
                : [const Color(0xFF2BCDEE), const Color(0xFFFFFFFF), const Color(0xFFE0F7FA)],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(24), margin: const EdgeInsets.only(bottom: 48),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                        boxShadow: const [BoxShadow(color: Color.fromRGBO(43, 205, 238, 0.3), blurRadius: 30, offset: Offset(0, 10), spreadRadius: -5)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(color: const Color(0xFF2BCDEE), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.monitor_heart, color: Colors.white, size: 36),
                          ),
                        ),
                      ),
                    ),
                    Text('WELCOME TO', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold, letterSpacing: 2.0, fontSize: 12)),
                    const SizedBox(height: 16),
                    Text('Patient History\nApp BD', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 36, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    Text('Your complete health history in one place.', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 18, fontWeight: FontWeight.w500, height: 1.5)),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => Get.toNamed('/registration'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2BCDEE), foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 64),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 10, shadowColor: const Color(0xFF2BCDEE).withOpacity(0.5),
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Get Started', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(width: 8), Icon(Icons.arrow_forward)]),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}