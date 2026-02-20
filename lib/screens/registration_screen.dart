import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/controllers.dart';
import '../core/helpers.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final c = Get.find<PatientController>();
  final nameController = TextEditingController();
  int _selectedGenderIndex = 0;
  String? _selectedRegion;
  DateTime? _selectedDob;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _regions = ['Dhaka', 'Chattogram', 'Rajshahi', 'Khulna', 'Barishal', 'Sylhet', 'Rangpur', 'Mymensingh'];

  @override
  void initState() {
    super.initState();
    nameController.text = c.name.value;
    _selectedDob = c.birthDate.value;
    if (c.region.value.isNotEmpty) _selectedRegion = c.region.value;
    if (c.gender.value.isNotEmpty) _selectedGenderIndex = _genders.indexOf(c.gender.value) == -1 ? 0 : _genders.indexOf(c.gender.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final inputBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 430),
          color: bgColor,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 48, left: 24, right: 24, bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.chevron_left), style: IconButton.styleFrom(backgroundColor: inputBgColor, padding: const EdgeInsets.all(12))),
                    Text('Create Profile', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                    const SizedBox(height: 6),
                    TextField(controller: nameController, decoration: _inputDecoration('John Doe', inputBgColor, isDark)),
                    const SizedBox(height: 24),

                    Text('Birthdate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        final d = await pickDate(context, initial: _selectedDob);
                        if (d != null) setState(() => _selectedDob = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: inputBgColor, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_selectedDob == null ? 'Select Date' : fmtDate(_selectedDob!), style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                            Icon(Icons.calendar_month, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text('Gender', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: inputBgColor, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: List.generate(_genders.length, (index) {
                          final isSelected = _selectedGenderIndex == index;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedGenderIndex = index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(color: isSelected ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                                alignment: Alignment.center,
                                child: Text(_genders[index], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isSelected ? theme.primaryColor : theme.colorScheme.onSurface.withOpacity(0.5))),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text('Region in Bangladesh', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Select your region', inputBgColor, isDark),
                      value: _selectedRegion,
                      items: _regions.map((region) => DropdownMenuItem(value: region, child: Text(region))).toList(),
                      onChanged: (value) => setState(() => _selectedRegion = value),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        color: Colors.transparent,
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: bgColor.withOpacity(0.8), border: Border(top: BorderSide(color: inputBgColor))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty || _selectedDob == null || _selectedRegion == null) {
                        Get.snackbar('Error', 'Please fill all fields');
                        return;
                      }
                      await c.saveProfile(name_: nameController.text, birth_: _selectedDob!, gender_: _genders[_selectedGenderIndex], region_: _selectedRegion!, blood_: '');
                      Get.toNamed('/questionnaire');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 18)]),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, Color bg, bool isDark) {
    return InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
      filled: true, fillColor: bg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}