import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/helpers.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final idC = TextEditingController();
  Map<String, dynamic>? profile;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> emergency = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> diseases = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> medicines = [];
  bool loading = false;
  String? error;

  Future<void> _search() async {
    setState(() {
      loading = true;
      error = null;
      profile = null;
      emergency = [];
      diseases = [];
      medicines = [];
    });
    final uid = idC.text.trim();
    if (uid.isEmpty) {
      setState(() {
        error = 'Please enter a Patient ID';
        loading = false;
      });
      return;
    }

    try {
      final db = FirebaseFirestore.instance;
      final profileDoc = await db.collection('patients').doc(uid).get();

      if (!profileDoc.exists) {
        setState(() {
          error = 'No patient found for ID: $uid';
          loading = false;
        });
        return;
      }

      final emer = await db.collection('patients').doc(uid).collection('emergencyHistory').get();
      final dis = await db.collection('patients').doc(uid).collection('normalDiseases').get();
      final meds = await db.collection('patients').doc(uid).collection('medicines').get();

      setState(() {
        profile = profileDoc.data();
        emergency = emer.docs;
        diseases = dis.docs;
        medicines = meds.docs;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'An error occurred while searching: $e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Search Tool')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: idC,
                    decoration: const InputDecoration(
                      labelText: 'Enter Patient ID (UID)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56, // Match standard TextField height
                  child: FilledButton.icon(
                    onPressed: _search,
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cs.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(error!, style: TextStyle(color: cs.error)),
              ),

            Expanded(
              child: profile == null ? const SizedBox() : ListView(
                children: [
                  Card(
                    elevation: 0,
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColor, child: const Icon(Icons.person, color: Colors.white)),
                      title: Text('${profile!['name'] ?? 'Unknown'}  (${profile!['bloodGroup'] ?? 'N/A'})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Patient ID: ${profile!['patientId'] ?? ''}\nAge: ${profile!['age'] ?? '-'} • Gender: ${profile!['gender'] ?? '-'}'),
                      isThreeLine: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSectionHeader(context, 'Emergency Admissions', emergency.length),
                  ...emergency.map((d) {
                    final x = d.data();
                    final date = (x['admissionDate'] as Timestamp).toDate();
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.local_hospital, color: Colors.red),
                      title: Text('${fmtDate(date)} • ${x['hospital'] ?? ''}'),
                      subtitle: Text('Cause: ${x['cause'] ?? ''} • Cured: ${(x['cured'] ?? false) ? "Yes" : "No"} • Doctor: ${x['doctor'] ?? ''}'),
                    );
                  }),
                  if (emergency.isNotEmpty) const Divider(),

                  _buildSectionHeader(context, 'Diseases History', diseases.length),
                  ...diseases.map((d) {
                    final x = d.data();
                    final date = (x['startDate'] as Timestamp).toDate();
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.sick, color: Colors.orange),
                      title: Text('${fmtDate(date)} • ${x['status'] ?? ''}'),
                      subtitle: Text(x['reportDetails'] ?? ''),
                    );
                  }),
                  if (diseases.isNotEmpty) const Divider(),

                  _buildSectionHeader(context, 'Medicines', medicines.length),
                  ...medicines.map((d) {
                    final x = d.data();
                    final from = (x['fromDate'] as Timestamp).toDate();
                    final endTs = x['endDate'] as Timestamp?;
                    final running = (x['running'] ?? (endTs == null)) as bool;
                    final end = running ? 'Running' : fmtDate(endTs!.toDate());
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.medication, color: Theme.of(context).primaryColor),
                      title: Text('${x['name'] ?? ''} • ${x['dose'] ?? ''}'),
                      subtitle: Text('From: ${fmtDate(from)} → $end\nReason: ${x['reason'] ?? ''} • Doctor: ${x['doctor'] ?? ''}'),
                      isThreeLine: true,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '$title ($count)',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
      ),
    );
  }
}