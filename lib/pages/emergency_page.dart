import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/controllers.dart';
import '../core/helpers.dart';

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<EmergencyController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Admissions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, c),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: c.stream(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No emergency admissions yet.'));
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Hospital')),
                DataColumn(label: Text('Cause')),
                DataColumn(label: Text('Cured')),
                DataColumn(label: Text('Doctor')),
                DataColumn(label: Text('Actions')),
              ],
              rows: docs.map((d) {
                final data = d.data();
                final date = (data['admissionDate'] as Timestamp).toDate();
                final hosp = data['hospital'] ?? '';
                final cause = data['cause'] ?? '';
                final cured = (data['cured'] ?? false) as bool;
                final doctor = data['doctor'] ?? '';
                return DataRow(cells: [
                  DataCell(Text(fmtDate(date))),
                  DataCell(Text(hosp)),
                  DataCell(Text(cause)),
                  DataCell(Icon(cured ? Icons.check_circle : Icons.cancel, color: cured ? Colors.green : Colors.red)),
                  DataCell(Text(doctor)),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _openForm(context, c, id: d.id, admissionDate: date, hospital: hosp, cause: cause, cured: cured, doctor: doctor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => c.delete(d.id),
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, EmergencyController c, {String? id, DateTime? admissionDate, String hospital = '', String cause = '', bool cured = false, String doctor = ''}) async {
    final hospitalC = TextEditingController(text: hospital);
    final causeC = TextEditingController(text: cause);
    final doctorC = TextEditingController(text: doctor);
    DateTime? date = admissionDate;
    bool isCured = cured;

    await Get.bottomSheet(
      StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Wrap(runSpacing: 12, children: [
                  Text(id == null ? 'Add Admission' : 'Edit Admission', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(child: Text(date == null ? 'Date: not set' : 'Date: ${fmtDate(date!)}')),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Pick Date'),
                        onPressed: () async {
                          final d = await pickDate(context, initial: date);
                          if (d != null) setState(() => date = d);
                        },
                      ),
                    ],
                  ),
                  TextField(controller: hospitalC, decoration: const InputDecoration(labelText: 'Hospital Name', border: OutlineInputBorder())),
                  TextField(controller: causeC, decoration: const InputDecoration(labelText: 'Cause', border: OutlineInputBorder())),
                  SwitchListTile(
                    value: isCured,
                    onChanged: (v) => setState(() => isCured = v),
                    title: const Text('Cured fully?'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  TextField(controller: doctorC, decoration: const InputDecoration(labelText: 'Doctor', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Record'),
                      onPressed: () async {
                        if (date == null) {
                          Get.snackbar('Error', 'Please select a date');
                          return;
                        }
                        await c.addOrUpdate(id: id, admissionDate: date!, hospital: hospitalC.text, cause: causeC.text, cured: isCured, doctor: doctorC.text);
                        Get.back();
                      },
                    ),
                  ),
                ]),
              ),
            );
          }
      ),
      isScrollControlled: true,
    );
  }
}