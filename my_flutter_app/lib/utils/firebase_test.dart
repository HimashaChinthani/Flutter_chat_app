import 'package:flutter/material.dart';
import '../services/crud_services.dart';

Future<void> testFirebaseConnectionUI(BuildContext context) async {
  final crudServices = CrudServices();
  final id = await crudServices.insertUserAuto(
    name: 'Test User ${DateTime.now().millisecondsSinceEpoch}',
  );
  if (!context.mounted) return;
  if (id != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Firebase OK! User inserted: $id'),
        backgroundColor: Colors.green,
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Firebase connection failed!'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
