import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/controllers.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final patientC = Get.find<PatientController>();
    final medicineC = Get.find<MedicineController>();
    final diseaseC = Get.find<DiseaseController>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: theme.primaryColor.withOpacity(0.3), width: 2), color: theme.primaryColor.withOpacity(0.1)), child: const Icon(Icons.person)),
                            const SizedBox(width: 16),
                            Obx(() => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hello, ${patientC.name.value.isEmpty ? 'Patient' : patientC.name.value.split(' ')[0]}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                                Text('ID: ${patientC.uid.value.substring(0, 6).toUpperCase()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                              ],
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Dynamic Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: StreamBuilder(
                            stream: medicineC.stream(),
                            builder: (context, snap) => _buildSummaryCard(isDark, title: 'Running Meds', value: '${snap.data?.docs.where((d) => d['running'] == true).length ?? 0}', icon: Icons.medication, color: theme.primaryColor, theme: theme),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StreamBuilder(
                            stream: diseaseC.stream(),
                            builder: (context, snap) => _buildSummaryCard(isDark, title: 'Active Diseases', value: '${snap.data?.docs.where((d) => d['status'] == 'Running').length ?? 0}', icon: Icons.medical_services, color: Colors.orange[400]!, theme: theme),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Health Tips (Static)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Health Tips', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildTipCard('Do', 'Stay hydrated throughout the day (min 2L).', Icons.check_circle, Colors.green, isDark)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTipCard('Don\'t', 'Avoid caffeine at least 4 hours before bed.', Icons.cancel, Colors.red, isDark)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Custom Bottom Navigation
          Positioned(
            bottom: 24, left: 24, right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF101F22).withOpacity(0.9) : Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(32), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, 'Home', true, theme),
                  _buildNavItem(Icons.search, 'Doctor Search', false, theme, onTap: () => Get.toNamed('/search')),
                  _buildNavItem(Icons.folder_open, 'Settings', false, theme, onTap: () => Get.toNamed('/settings')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark, {required String title, required String value, required IconData icon, required Color color, required ThemeData theme}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF101F22).withOpacity(0.7) : Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildTipCard(String title, String text, IconData icon, MaterialColor color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color[50]?.withOpacity(isDark ? 0.1 : 0.5), border: Border.all(color: color[100]!.withOpacity(isDark ? 0.3 : 1.0)), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: isDark ? color[400] : color[600], size: 18), const SizedBox(width: 8), Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? color[400] : color[600]))]),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(fontSize: 12, height: 1.5, color: isDark ? Colors.white70 : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, ThemeData theme, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? theme.primaryColor : theme.colorScheme.onSurface.withOpacity(0.4)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? theme.primaryColor : theme.colorScheme.onSurface.withOpacity(0.4))),
        ],
      ),
    );
  }
}