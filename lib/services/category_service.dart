import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homemate/models/category.dart';

// هذا بمثل استرجاع البيانات من الفاير بيز
// بتعامل مع ال category
/// خدمة التصنيفات، ومسؤولة عن جلب التصنيفات من Firestore.
class CategoryService {
  /// مرجع قاعدة البيانات المستخدم للوصول إلى البيانات.
  final _db = FirebaseFirestore.instance;

  /// جلب جميع التصنيفات وتحويلها إلى نماذج قابلة للاستخدام داخل التطبيق.
  Future<List<Category>> getCategories() async {
    final snapshot = await _db.collection('categories').get();

    return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
  }
}
