import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final CollectionReference User =
      FirebaseFirestore.instance.collection('user');
}
