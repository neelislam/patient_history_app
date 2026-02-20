import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/controllers.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final c = Get.find<PatientController>();
  final List<String> _problems = ['High Blood Pressure', 'Low Blood Pressure', 'Blood Sugar', 'Diabetes', 'Pregnancy', 'Asthma', 'Heart Condition', 'Allergies', 'Kidney Issues'];
  late Set<String> _selectedProblems;

  @override
  void initState() {
    super.initState();
    _selectedProblems = Set.from(c.problems);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF101F22) : const Color(0xFFF6F8F8);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: Icon(Icons.arrow_back_ios_new, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.7)), onPressed: () => Get.back()),
                      Text('MEDICAL PROFILE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 2.0)),
                      TextButton(onPressed: () => Get.offAllNamed('/dashboard'), child: const Text('Skip')),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    children: [
                      Text('What current or previous problems do you have/had?', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, height: 1.2)),
                      const SizedBox(height: 24),
                      ..._problems.map((problem) => _buildCheckboxCard(problem, cardColor, theme)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: BoxDecoration(color: bgColor.withOpacity(0.9), border: Border(top: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.1)))),
                  child: ElevatedButton(
                    onPressed: () async {
                      await c.saveProblems(_selectedProblems.toList());
                      Get.offAllNamed('/dashboard');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Finish Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), SizedBox(width: 8), Icon(Icons.check, size: 20)]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxCard(String title, Color cardColor, ThemeData theme) {
    final isSelected = _selectedProblems.contains(title);
    return GestureDetector(
      onTap: () => setState(() => isSelected ? _selectedProblems.remove(title) : _selectedProblems.add(title)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: isSelected ? theme.primaryColor.withOpacity(0.05) : cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? theme.primaryColor : Colors.transparent, width: 2)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
            Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? theme.primaryColor : Colors.transparent, border: Border.all(color: isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withOpacity(0.2), width: 2)), child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null),
          ],
        ),
      ),
    );
  }
}