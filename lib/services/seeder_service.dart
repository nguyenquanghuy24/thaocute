import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart';

class SeederService {
  SeederService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : firestore = firestore ?? FirebaseFirestore.instance,
      auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  Future<void> seed() async {
    final user = await _ensureDemoAuthUser();
    final batch = firestore.batch();
    for (final table in demoTables) {
      batch.set(firestore.collection('tables').doc(table.id), table.toMap());
    }
    for (final food in sampleFoods) {
      batch.set(firestore.collection('foods').doc(food.id), food.toMap());
    }
    final employee = demoEmployees.first;
    batch.set(firestore.collection('employees').doc(user.uid), {
      ...employee.toMap(),
      'authUid': user.uid,
      'employeeCode': employee.employeeCode,
    });
    await batch.commit();
    await auth.signOut();
  }

  Future<User> _ensureDemoAuthUser() async {
    const email = 'nv001@bepnha.demo';
    const password = '123456';
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!;
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') rethrow;
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!;
    }
  }
}
