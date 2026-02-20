import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/controllers.dart';
import '../utils/helpers.dart';

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});
  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final c = Get.find<PatientController>();
  final nameC = TextEditingController();
  final bloodC = TextEditingController();
  DateTime? selectedDob;

  @override
  void initState() {
    super.initState();
    ever<String>(c.name, (_) => _hydrate());
    ever<String>(c.bloodGroup, (_) => _hydrate());
    ever<DateTime?>(c.birthDate, (_) => _hydrate());
    Future.microtask(_hydrate);
  }

  void _hydrate() {
    nameC.text = c.name.value;
    bloodC.text = c.bloodGroup.value;
    selectedDob = c.birthDate.value ?? selectedDob;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Patient ID: $uid', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 8),
            TextField(controller: bloodC, decoration: const InputDecoration(labelText: 'Blood Group (e.g., O+, A-)')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text(selectedDob == null ? 'Birth Date: not set' : 'Birth Date: ${fmtDate(selectedDob!)}')),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_month), label: const Text('Select'),
                  onPressed: () async {
                    final d = await pickDate(context, initial: selectedDob);
                    if (d != null) setState(() => selectedDob = d);
                  },
                )
              ],
            ),
            const SizedBox(height: 8),
            Text('Age: ${selectedDob == null ? '-' : calculateAge(selectedDob!).toString()}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.save_outlined), label: const Text('Save'),
              onPressed: () async {
                if (selectedDob == null) {
                  Get.snackbar('Missing', 'Select birth date', snackPosition: SnackPosition.BOTTOM);
                  return;
                }
                await c.saveProfile(name_: nameC.text, blood_: bloodC.text, birth_: selectedDob!, gender_: '', region_: '');
              },
            ),
          ],
        ),
      ),
    );
  }
}