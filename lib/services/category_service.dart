import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homemate/models/category.dart';

// هذا بمثل استرجاع البيانات من الفاير بيز
// بتعامل مع ال category
class CategoryService {
  final _db = FirebaseFirestore.instance;

  Future<List<Category>> getCategories() async {
    final snapshot = await _db.collection('categories').get();

    return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
  }
}
