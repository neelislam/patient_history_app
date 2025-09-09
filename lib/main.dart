import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// ---------- Helpers ----------
int calculateAge(DateTime birthDate) {
  final now = DateTime.now();
  int age = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }
  return age;
}

String fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

Future<DateTime?> pickDate(BuildContext context, {DateTime? initial}) async {
  final now = DateTime.now();
  return await showDatePicker(
    context: context,
    initialDate: initial ?? DateTime(now.year - 20),
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
  );
}

/// ---------- Controllers ----------
class PatientController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final RxString uid = ''.obs;

  final name = ''.obs;
  final bloodGroup = ''.obs;
  final Rxn<DateTime> birthDate = Rxn<DateTime>();
  int get age => birthDate.value == null ? 0 : calculateAge(birthDate.value!);

  /// initialize with current user
  Future<void> init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    uid.value = user.uid;
    await loadProfile();
  }

  Future<void> loadProfile() async {
    if (uid.isEmpty) return;
    final doc = await _db.collection('patients').doc(uid.value).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    name.value = (data['name'] ?? '') as String;
    bloodGroup.value = (data['bloodGroup'] ?? '') as String;
    final bd = data['birthDate'];
    if (bd is Timestamp) birthDate.value = bd.toDate();
  }

  Future<void> saveProfile({
    required String name_,
    required String blood_,
    required DateTime birth_,
  }) async {
    if (uid.isEmpty) throw Exception('No UID');
    await _db.collection('patients').doc(uid.value).set({
      'name': name_,
      'bloodGroup': blood_,
      'birthDate': birth_,
      'age': calculateAge(birth_),
      'patientId': uid.value, // convenience field
    }, SetOptions(merge: true));
    name.value = name_;
    bloodGroup.value = blood_;
    birthDate.value = birth_;
    Get.snackbar('Saved', 'Profile updated', snackPosition: SnackPosition.BOTTOM);
  }
}

class EmergencyController extends GetxController {
  final _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  CollectionReference<Map<String, dynamic>> get col =>
      _db.collection('patients').doc(uid).collection('emergencyHistory');

  Stream<QuerySnapshot<Map<String, dynamic>>> stream() =>
      col.orderBy('admissionDate', descending: true).snapshots();

  Future<void> addOrUpdate({
    String? id,
    required DateTime admissionDate,
    required String hospital,
    required String cause,
    required bool cured,
    required String doctor,
  }) async {
    final data = {
      'admissionDate': admissionDate,
      'hospital': hospital.trim(),
      'cause': cause.trim(),
      'cured': cured,
      'doctor': doctor.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (id == null) {
      await col.add(data);
    } else {
      await col.doc(id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> delete(String id) => col.doc(id).delete();
}

class DiseaseController extends GetxController {
  final _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  CollectionReference<Map<String, dynamic>> get col =>
      _db.collection('patients').doc(uid).collection('normalDiseases');

  Stream<QuerySnapshot<Map<String, dynamic>>> stream() =>
      col.orderBy('startDate', descending: true).snapshots();

  Future<void> addOrUpdate({
    String? id,
    required DateTime startDate,
    required String reportDetails,
    required String status, // 'Cured' | 'Running'
  }) async {
    final data = {
      'startDate': startDate,
      'reportDetails': reportDetails.trim(),
      'status': status, // constrained by UI
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (id == null) {
      await col.add(data);
    } else {
      await col.doc(id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> delete(String id) => col.doc(id).delete();
}

class MedicineController extends GetxController {
  final _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  CollectionReference<Map<String, dynamic>> get col =>
      _db.collection('patients').doc(uid).collection('medicines');

  Stream<QuerySnapshot<Map<String, dynamic>>> stream() =>
      col.orderBy('fromDate', descending: true).snapshots();

  Future<void> addOrUpdate({
    String? id,
    required DateTime fromDate,
    required String name,
    required String dose, // e.g., 500mg, 1-0-1
    required String reason,
    required String doctor,
    DateTime? endDate, // null => running
  }) async {
    final data = {
      'fromDate': fromDate,
      'name': name.trim(),
      'dose': dose.trim(),
      'reason': reason.trim(),
      'doctor': doctor.trim(),
      'endDate': endDate,
      'running': endDate == null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (id == null) {
      await col.add(data);
    } else {
      await col.doc(id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> endCourse(String id, DateTime endDate) =>
      col.doc(id).set({'endDate': endDate, 'running': false}, SetOptions(merge: true));

  Future<void> delete(String id) => col.doc(id).delete();
}

/// ---------- App ----------
Future<void> _ensureAuth() async {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _ensureAuth();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // Put controllers once at app start
    Get.put(PatientController()..init());
    Get.put(EmergencyController());
    Get.put(DiseaseController());
    Get.put(MedicineController());

    return GetMaterialApp(
      title: 'PatientCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const HomePage(),
      getPages: [
        GetPage(name: '/profile', page: () => const PatientProfilePage()),
        GetPage(name: '/emergency', page: () => const EmergencyPage()),
        GetPage(name: '/diseases', page: () => const DiseasePage()),
        GetPage(name: '/medicines', page: () => const MedicinePage()),
        GetPage(name: '/search', page: () => const SearchPage()),
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '—';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Get.toNamed('/search'),
          )
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Patient Profile'),
            subtitle: Text('Patient ID: $uid'),
            leading: const Icon(Icons.person_outline),
            onTap: () => Get.toNamed('/profile'),
          ),
          const Divider(height: 0),
          ListTile(
            title: const Text('Emergency Admissions'),
            leading: const Icon(Icons.local_hospital_outlined),
            onTap: () => Get.toNamed('/emergency'),
          ),
          const Divider(height: 0),
          ListTile(
            title: const Text('Normal Diseases'),
            leading: const Icon(Icons.sick_outlined),
            onTap: () => Get.toNamed('/diseases'),
          ),
          const Divider(height: 0),
          ListTile(
            title: const Text('Medicines (Running & History)'),
            leading: const Icon(Icons.medication_outlined),
            onTap: () => Get.toNamed('/medicines'),
          ),
          const Divider(height: 0),
          ListTile(
            title: const Text('Doctor Search (by Patient ID)'),
            leading: const Icon(Icons.search),
            onTap: () => Get.toNamed('/search'),
          ),
        ],
      ),
    );
  }
}

/// ---------- Pages ----------
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
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bloodC,
              decoration: const InputDecoration(labelText: 'Blood Group (e.g., O+, A-)'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDob == null
                        ? 'Birth Date: not set'
                        : 'Birth Date: ${fmtDate(selectedDob!)}',
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Select'),
                  onPressed: () async {
                    final d = await pickDate(context, initial: selectedDob);
                    if (d != null) setState(() => selectedDob = d);
                  },
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Age: ${selectedDob == null ? '-' : calculateAge(selectedDob!).toString()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
              onPressed: () async {
                if (selectedDob == null) {
                  Get.snackbar('Missing', 'Select birth date',
                      snackPosition: SnackPosition.BOTTOM);
                  return;
                }
                await c.saveProfile(
                  name_: nameC.text,
                  blood_: bloodC.text,
                  birth_: selectedDob!,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

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
                  DataCell(Icon(cured ? Icons.check_circle : Icons.cancel)),
                  DataCell(Text(doctor)),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openForm(context, c,
                            id: d.id,
                            admissionDate: date,
                            hospital: hosp,
                            cause: cause,
                            cured: cured,
                            doctor: doctor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
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

  Future<void> _openForm(BuildContext context, EmergencyController c,
      {String? id,
        DateTime? admissionDate,
        String hospital = '',
        String cause = '',
        bool cured = false,
        String doctor = ''}) async {
    final hospitalC = TextEditingController(text: hospital);
    final causeC = TextEditingController(text: cause);
    final doctorC = TextEditingController(text: doctor);
    DateTime? date = admissionDate;

    await Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Wrap(runSpacing: 12, children: [
            Text(id == null ? 'Add Admission' : 'Edit Admission',
                style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                Expanded(
                    child: Text(date == null
                        ? 'Date: not set'
                        : 'Date: ${fmtDate(date)}')),
                TextButton(
                    onPressed: () async {
                      final d = await pickDate(context, initial: date);
                      if (d != null) {
                        date = d;
                        (context as Element).markNeedsBuild();
                      }
                    },
                    child: const Text('Pick Date')),
              ],
            ),
            TextField(
              controller: hospitalC,
              decoration: const InputDecoration(labelText: 'Hospital Name'),
            ),
            TextField(
              controller: causeC,
              decoration: const InputDecoration(labelText: 'Cause'),
            ),
            SwitchListTile(
              value: cured,
              onChanged: (v) {
                cured = v;
                (context as Element).markNeedsBuild();
              },
              title: const Text('Cured fully?'),
            ),
            TextField(
              controller: doctorC,
              decoration: const InputDecoration(labelText: 'Doctor'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: () async {
                if (date == null) return;
                await c.addOrUpdate(
                  id: id,
                  admissionDate: date!,
                  hospital: hospitalC.text,
                  cause: causeC.text,
                  cured: cured,
                  doctor: doctorC.text,
                );
                Get.back();
              },
            ),
          ]),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

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
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No disease records yet.'));
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Start Date')),
                DataColumn(label: Text('Report Details')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: docs.map((d) {
                final data = d.data();
                final start = (data['startDate'] as Timestamp).toDate();
                final details = data['reportDetails'] ?? '';
                final status = data['status'] ?? '';
                return DataRow(cells: [
                  DataCell(Text(fmtDate(start))),
                  DataCell(SizedBox(width: 280, child: Text(details))),
                  DataCell(Text(status)),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openForm(context, c,
                            id: d.id,
                            startDate: start,
                            reportDetails: details,
                            status: status),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
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

  Future<void> _openForm(BuildContext context, DiseaseController c,
      {String? id,
        DateTime? startDate,
        String reportDetails = '',
        String status = 'Running'}) async {
    final detailsC = TextEditingController(text: reportDetails);
    DateTime? date = startDate;
    String currentStatus = status;

    await Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Wrap(runSpacing: 12, children: [
            Text(id == null ? 'Add Disease' : 'Edit Disease',
                style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                Expanded(
                    child: Text(date == null
                        ? 'Symptom Start: not set'
                        : 'Symptom Start: ${fmtDate(date)}')),
                TextButton(
                    onPressed: () async {
                      final d = await pickDate(context, initial: date);
                      if (d != null) {
                        date = d;
                        (context as Element).markNeedsBuild();
                      }
                    },
                    child: const Text('Pick Date')),
              ],
            ),
            TextField(
              controller: detailsC,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Report Details'),
            ),
            DropdownButtonFormField<String>(
              value: (currentStatus == 'Cured' || currentStatus == 'Running')
                  ? currentStatus
                  : 'Running',
              items: const [
                DropdownMenuItem(value: 'Running', child: Text('Running')),
                DropdownMenuItem(value: 'Cured', child: Text('Cured')),
              ],
              onChanged: (v) {
                if (v != null) {
                  currentStatus = v;
                }
              },
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: () async {
                if (date == null) return;
                await c.addOrUpdate(
                  id: id,
                  startDate: date!,
                  reportDetails: detailsC.text,
                  status: currentStatus,
                );
                Get.back();
              },
            ),
          ]),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

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
                final endStr =
                running ? 'Running' : fmtDate(endTs!.toDate());
                return DataRow(cells: [
                  DataCell(Text(fmtDate(from))),
                  DataCell(Text(name)),
                  DataCell(Text(dose)),
                  DataCell(SizedBox(width: 220, child: Text(reason))),
                  DataCell(Text(doctor)),
                  DataCell(Text(endStr)),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openForm(
                          context,
                          c,
                          id: d.id,
                          fromDate: from,
                          name: name,
                          dose: dose,
                          reason: reason,
                          doctor: doctor,
                          endDate: endTs?.toDate(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flag_outlined),
                        tooltip: 'End Course Today',
                        onPressed: () => c.endCourse(d.id, DateTime.now()),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
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

  Future<void> _openForm(BuildContext context, MedicineController c,
      {String? id,
        DateTime? fromDate,
        String name = '',
        String dose = '',
        String reason = '',
        String doctor = '',
        DateTime? endDate}) async {
    final nameC = TextEditingController(text: name);
    final doseC = TextEditingController(text: dose);
    final reasonC = TextEditingController(text: reason);
    final doctorC = TextEditingController(text: doctor);
    DateTime? from = fromDate;
    DateTime? end = endDate;

    await Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Wrap(runSpacing: 12, children: [
            Text(id == null ? 'Add Medicine' : 'Edit Medicine',
                style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                Expanded(
                    child: Text(from == null
                        ? 'From: not set'
                        : 'From: ${fmtDate(from)}')),
                TextButton(
                    onPressed: () async {
                      final d = await pickDate(context, initial: from);
                      if (d != null) {
                        from = d;
                        (context as Element).markNeedsBuild();
                      }
                    },
                    child: const Text('Pick Date')),
              ],
            ),
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: 'Medicine Name'),
            ),
            TextField(
              controller: doseC,
              decoration:
              const InputDecoration(labelText: 'Dose/Power (e.g., 500mg, 1-0-1)'),
            ),
            TextField(
              controller: reasonC,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            TextField(
              controller: doctorC,
              decoration: const InputDecoration(labelText: 'Doctor'),
            ),
            Row(
              children: [
                Expanded(
                    child: Text(end == null
                        ? 'End: Running'
                        : 'End: ${fmtDate(end)}')),
                TextButton(
                    onPressed: () async {
                      final d = await pickDate(context, initial: end);
                      end = d;
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Pick End (optional)')),
                IconButton(
                  onPressed: () {
                    end = null; // mark running
                    (context as Element).markNeedsBuild();
                  },
                  tooltip: 'Set Running',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: () async {
                if (from == null) return;
                await c.addOrUpdate(
                  id: id,
                  fromDate: from!,
                  name: nameC.text,
                  dose: doseC.text,
                  reason: reasonC.text,
                  doctor: doctorC.text,
                  endDate: end,
                );
                Get.back();
              },
            ),
          ]),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

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
      final emer =
      await db.collection('patients').doc(uid).collection('emergencyHistory').get();
      final dis =
      await db.collection('patients').doc(uid).collection('normalDiseases').get();
      final meds =
      await db.collection('patients').doc(uid).collection('medicines').get();

      setState(() {
        profile = profileDoc.data();
        emergency = emer.docs;
        diseases = dis.docs;
        medicines = meds.docs;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Search (by Patient ID)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: idC,
                    decoration: const InputDecoration(
                      labelText: 'Enter Patient ID (UID)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _search,
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Text(error!, style: TextStyle(color: cs.error)),
            if (profile != null) ...[
              Card(
                child: ListTile(
                  title: Text('${profile!['name'] ?? ''}  (${profile!['bloodGroup'] ?? ''})'),
                  subtitle: Text(
                      'Patient ID: ${profile!['patientId'] ?? ''} • Age: ${profile!['age'] ?? '-'}'),
                ),
              ),
              const SizedBox(height: 8),
              Text('Emergency Admissions (${emergency.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ...emergency.map((d) {
                final x = d.data();
                final date = (x['admissionDate'] as Timestamp).toDate();
                return ListTile(
                  dense: true,
                  title: Text('${fmtDate(date)} • ${x['hospital'] ?? ''}'),
                  subtitle: Text(
                      'Cause: ${x['cause'] ?? ''} • Cured: ${(x['cured'] ?? false) ? "Yes" : "No"} • Doctor: ${x['doctor'] ?? ''}'),
                );
              }),
              const Divider(),
              Text('Diseases (${diseases.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ...diseases.map((d) {
                final x = d.data();
                final date = (x['startDate'] as Timestamp).toDate();
                return ListTile(
                  dense: true,
                  title: Text('${fmtDate(date)} • ${x['status'] ?? ''}'),
                  subtitle: Text(x['reportDetails'] ?? ''),
                );
              }),
              const Divider(),
              Text('Medicines (${medicines.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ...medicines.map((d) {
                final x = d.data();
                final from = (x['fromDate'] as Timestamp).toDate();
                final endTs = x['endDate'] as Timestamp?;
                final running = (x['running'] ?? (endTs == null)) as bool;
                final end = running ? 'Running' : fmtDate(endTs!.toDate());
                return ListTile(
                  dense: true,
                  title: Text('${x['name'] ?? ''} • ${x['dose'] ?? ''}'),
                  subtitle: Text(
                      'From: ${fmtDate(from)} → $end • Reason: ${x['reason'] ?? ''} • Doctor: ${x['doctor'] ?? ''}'),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
