import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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