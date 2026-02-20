import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/controllers.dart';
import '../utils/helpers.dart';

class DiseasePage extends StatelessWidget {
  const DiseasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DiseaseController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Normal Diseases')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, c),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: c.stream(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No disease records yet.'));

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Start Date')), DataColumn(label: Text('Report Details')),
                DataColumn(label: Text('Status')), DataColumn(label: Text('Actions')),
              ],
              rows: docs.map((d) {
                final data = d.data();
                final start = (data['startDate'] as Timestamp).toDate();
                return DataRow(cells: [
                  DataCell(Text(fmtDate(start))), DataCell(SizedBox(width: 280, child: Text(data['reportDetails'] ?? ''))),
                  DataCell(Text(data['status'] ?? '')),
                  DataCell(Row(
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _openForm(context, c, id: d.id, startDate: start, reportDetails: data['reportDetails'] ?? '', status: data['status'] ?? '')),
                      IconButton(icon: const Icon(Icons.delete), onPressed: () => c.delete(d.id)),
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

  Future<void> _openForm(BuildContext context, DiseaseController c, {String? id, DateTime? startDate, String reportDetails = '', String status = 'Running'}) async {
    final detailsC = TextEditingController(text: reportDetails);
    DateTime? date = startDate;
    String currentStatus = status;

    await Get.bottomSheet(
      StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                child: Wrap(runSpacing: 12, children: [
                  Text(id == null ? 'Add Disease' : 'Edit Disease', style: Theme.of(context).textTheme.titleMedium),
                  Row(
                    children: [
                      Expanded(child: Text(date == null ? 'Symptom Start: not set' : 'Symptom Start: ${fmtDate(date!)}')),
                      TextButton(
                          onPressed: () async {
                            final d = await pickDate(context, initial: date);
                            if (d != null) setState(() => date = d);
                          },
                          child: const Text('Pick Date')),
                    ],
                  ),
                  TextField(controller: detailsC, minLines: 2, maxLines: 6, decoration: const InputDecoration(labelText: 'Report Details')),
                  DropdownButtonFormField<String>(
                    value: (currentStatus == 'Cured' || currentStatus == 'Running') ? currentStatus : 'Running',
                    items: const [DropdownMenuItem(value: 'Running', child: Text('Running')), DropdownMenuItem(value: 'Cured', child: Text('Cured'))],
                    onChanged: (v) { if (v != null) setState(() => currentStatus = v); },
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.save), label: const Text('Save'),
                    onPressed: () async {
                      if (date == null) return;
                      await c.addOrUpdate(id: id, startDate: date!, reportDetails: detailsC.text, status: currentStatus);
                      Get.back();
                    },
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