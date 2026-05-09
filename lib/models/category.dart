import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج التصنيف، ويحتوي البيانات الأساسية لكل قسم من أقسام الخدمات.
class Category {
  /// معرف التصنيف داخل Firestore.
  final String id;
  /// اسم التصنيف المعروض للمستخدم.
  final String name;
  /// مسار الصورة أو الأصل المرئي المرتبط بالتصنيف.
  final String image;

  /// تهيئة كائن التصنيف بالقيم القادمة من التطبيق أو من Firestore.
  Category({required this.id, required this.name, required this.image});

  //  factory: يحوّل (document) من Firestore إلى  Category.
  /// إنشاء نموذج التصنيف من مستند Firestore.
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
