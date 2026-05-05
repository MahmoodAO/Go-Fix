import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String image;

  Category({required this.id, required this.name, required this.image});

  //  factory: يحوّل (document) من Firestore إلى  Category.
  factory Category.fromFirestore(DocumentSnapshot doc) {
    //DocumentSnapshot: المستند يلي جاي من قاعدة البيانات.
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
    );
  }
}
