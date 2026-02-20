import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/controllers.dart';
import '../core/helpers.dart';

class MedicinePage extends StatelessWidget {
  const MedicinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MedicineController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Medicines')),
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
            return const Center(child: Text('No medicines yet.'));
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('From')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Dose/Power')),
                DataColumn(label: Text('Reason')),
                DataColumn(label: Text('Doctor')),
                DataColumn(label: Text('End/Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: docs.map((d) {
                final data = d.data();
                final from = (data['fromDate'] as Timestamp).toDate();
                final name = data['name'] ?? '';
                final dose = data['dose'] ?? '';
                final reason = data['reason'] ?? '';
                final doctor = data['doctor'] ?? '';
                final Timestamp? endTs = data['endDate'];
                final running = (data['running'] ?? (endTs == null)) as bool;
                final endStr = running ? 'Running' : fmtDate(endTs!.toDate());

                return DataRow(cells: [
                  DataCell(Text(fmtDate(from))),
                  DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(dose)),
                  DataCell(SizedBox(width: 220, child: Text(reason))),
                  DataCell(Text(doctor)),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: running ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(endStr, style: TextStyle(color: running ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
                  )),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _openForm(context, c, id: d.id, fromDate: from, name: name, dose: dose, reason: reason, doctor: doctor, endDate: endTs?.toDate()),
                      ),
                      if (running)
                        IconButton(
                          icon: const Icon(Icons.flag_outlined, color: Colors.orange),
                          tooltip: 'End Course Today',
                          onPressed: () => c.endCourse(d.id, DateTime.now()),
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

  Future<void> _openForm(BuildContext context, MedicineController c, {String? id, DateTime? fromDate, String name = '', String dose = '', String reason = '', String doctor = '', DateTime? endDate}) async {
    final nameC = TextEditingController(text: name);
    final doseC = TextEditingController(text: dose);
    final reasonC = TextEditingController(text: reason);
    final doctorC = TextEditingController(text: doctor);
    DateTime? from = fromDate;
    DateTime? end = endDate;

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
                  Text(id == null ? 'Add Medicine' : 'Edit Medicine', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(child: Text(from == null ? 'From: not set' : 'From: ${fmtDate(from!)}')),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today), label: const Text('Pick Start Date'),
                        onPressed: () async {
                          final d = await pickDate(context, initial: from);
                          if (d != null) setState(() => from = d);
                        },
                      ),
                    ],
                  ),
                  TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Medicine Name', border: OutlineInputBorder())),
                  TextField(controller: doseC, decoration: const InputDecoration(labelText: 'Dose/Power (e.g., 500mg, 1-0-1)', border: OutlineInputBorder())),
                  TextField(controller: reasonC, decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder())),
                  TextField(controller: doctorC, decoration: const InputDecoration(labelText: 'Doctor', border: OutlineInputBorder())),
                  Row(
                    children: [
                      Expanded(child: Text(end == null ? 'Status: Running' : 'Ended: ${fmtDate(end!)}')),
                      TextButton(
                        onPressed: () async {
                          final d = await pickDate(context, initial: end);
                          if (d != null) setState(() => end = d);
                        },
                        child: const Text('Pick End Date'),
                      ),
                      if (end != null)
                        IconButton(
                          onPressed: () => setState(() => end = null),
                          tooltip: 'Set as Running',
                          icon: const Icon(Icons.refresh),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Record'),
                      onPressed: () async {
                        if (from == null) {
                          Get.snackbar('Error', 'Please select a start date');
                          return;
                        }
                        await c.addOrUpdate(id: id, fromDate: from!, name: nameC.text, dose: doseC.text, reason: reasonC.text, doctor: doctorC.text, endDate: end);
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