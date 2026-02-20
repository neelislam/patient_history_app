import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/controllers.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF101F22) : const Color(0xFFF6F8F8);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final patientC = Get.find<PatientController>();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Settings & Records')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(width: 56, height: 56, decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.person)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patientC.name.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Blood Type: ${patientC.bloodGroup.value}', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                      ],
                    )),
                  ),
                  IconButton(icon: Icon(Icons.edit, color: theme.primaryColor), onPressed: () => Get.toNamed('/registration')),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Links to Original CRUD Pages
            Text('DATA ENTRY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildListItem('Emergency Admissions', Icons.local_hospital, theme, true, onTap: () => Get.toNamed('/emergency')),
                  _buildListItem('Normal Diseases History', Icons.sick, theme, true, onTap: () => Get.toNamed('/diseases')),
                  _buildListItem('Running & Past Medicines', Icons.medication, theme, false, onTap: () => Get.toNamed('/medicines')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('TOOLS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildListItem('Medical Questionnaire', Icons.question_answer, theme, true, onTap: () => Get.toNamed('/questionnaire')),
                  _buildListItem('Search Doctor by Patient ID', Icons.search, theme, false, onTap: () => Get.toNamed('/search')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String title, IconData icon, ThemeData theme, bool showDivider, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: showDivider ? Border(bottom: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.05))) : null),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: theme.primaryColor)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}