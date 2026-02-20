import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'helpers.dart';

class PatientController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final RxString uid = ''.obs;

  final name = ''.obs;
  final bloodGroup = 'O+'.obs; // Default
  final gender = ''.obs;
  final region = ''.obs;
  final problems = <String>[].obs;
  final Rxn<DateTime> birthDate = Rxn<DateTime>();
  int get age => birthDate.value == null ? 0 : calculateAge(birthDate.value!);

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
    bloodGroup.value = (data['bloodGroup'] ?? 'O+') as String;
    gender.value = (data['gender'] ?? '') as String;
    region.value = (data['region'] ?? '') as String;
    problems.value = List<String>.from(data['problems'] ?? []);
    final bd = data['birthDate'];
    if (bd is Timestamp) birthDate.value = bd.toDate();
  }

  Future<void> saveProfile({required String name_, required DateTime birth_, required String gender_, required String region_, required String blood_}) async {
    if (uid.isEmpty) throw Exception('No UID');
    await _db.collection('patients').doc(uid.value).set({
      'name': name_, 'birthDate': birth_, 'age': calculateAge(birth_),
      'gender': gender_, 'region': region_, 'patientId': uid.value,
    }, SetOptions(merge: true));
    name.value = name_; birthDate.value = birth_; gender.value = gender_; region.value = region_;
  }

  Future<void> saveProblems(List<String> selectedProblems) async {
    if (uid.isEmpty) return;
    await _db.collection('patients').doc(uid.value).set({'problems': selectedProblems}, SetOptions(merge: true));
    problems.value = selectedProblems;
  }
}

class EmergencyController extends GetxController {
  final _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  CollectionReference<Map<String, dynamic>> get col => _db.collection('patients').doc(uid).collection('emergencyHistory');
  Stream<QuerySnapshot<Map<String, dynamic>>> stream() => col.orderBy('admissionDate', descending: true).snapshots();
  Future<void> addOrUpdate({String? id, required DateTime admissionDate, required String hospital, required String cause, required bool cured, required String doctor}) async {
    final data = {'admissionDate': admissionDate, 'hospital': hospital.trim(), 'cause': cause.trim(), 'cured': cured, 'doctor': doctor.trim(), 'updatedAt': FieldValue.serverTimestamp()};
    id == null ? await col.add(data) : await col.doc(id).set(data, SetOptions(merge: true));
  }
  Future<void> delete(String id) => col.doc(id).delete();
}

class DiseaseController extends GetxController {
  final _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  CollectionReference<Map<String, dynamic>> get col => _db.collection('patients').doc(uid).collection('normalDiseases');
  Stream<QuerySnapshot<Map<String, dynamic>>> stream() => col.orderBy('startDate', descending: true).snapshots();
  Future<void> addOrUpdate({String? id, required DateTime startDate, required String reportDetails, required String status}) async {
    final data = {'startDate': startDate, 'reportDetails': reportDetails.trim(), 'status': status, 'updatedAt': FieldValue.serverTimestamp()};
    id == null ? await col.add(data) : await col.doc(id).set(data, SetOptions(merge: true));
  }
  Future<void> delete(String id) => col.doc(id).delete();
}

class MedicineController extends GetxController {
  final _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  CollectionReference<Map<String, dynamic>> get col => _db.collection('patients').doc(uid).collection('medicines');
  Stream<QuerySnapshot<Map<String, dynamic>>> stream() => col.orderBy('fromDate', descending: true).snapshots();
  Future<void> addOrUpdate({String? id, required DateTime fromDate, required String name, required String dose, required String reason, required String doctor, DateTime? endDate}) async {
    final data = {'fromDate': fromDate, 'name': name.trim(), 'dose': dose.trim(), 'reason': reason.trim(), 'doctor': doctor.trim(), 'endDate': endDate, 'running': endDate == null, 'updatedAt': FieldValue.serverTimestamp()};
    id == null ? await col.add(data) : await col.doc(id).set(data, SetOptions(merge: true));
  }
  Future<void> endCourse(String id, DateTime endDate) => col.doc(id).set({'endDate': endDate, 'running': false}, SetOptions(merge: true));
  Future<void> delete(String id) => col.doc(id).delete();
}