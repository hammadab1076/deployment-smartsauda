import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  ProductModel({
    required super.id,
    required super.name,
    required super.price,
    required super.imageUrl,
    required super.barcode,
    super.nfcTagId = '',
    required super.description,
    required super.category,
  });

  // From Firestore (camelCase)
  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id:          id,
      name:        map['name'] ?? '',
      price:       (map['price'] ?? 0).toDouble(),
      imageUrl:    map['imageUrl'] ?? '',
      barcode:     map['barcode'] ?? '',
      nfcTagId:    map['nfcTagId'] ?? '',
      description: map['description'] ?? '',
      category:    map['category'] ?? 'Miscellaneous',
    );
  }

  // From MySQL API response (snake_case columns)
  factory ProductModel.fromApiMap(Map<String, dynamic> map) {
    return ProductModel(
      id:          map['id'] ?? '',
      name:        map['name'] ?? '',
      price:       double.tryParse(map['price'].toString()) ?? 0.0,
      imageUrl:    map['image_url'] ?? '',
      barcode:     map['barcode'] ?? '',
      nfcTagId:    map['nfc_tag_id'] ?? '',
      description: map['description'] ?? '',
      category:    map['category'] ?? 'Miscellaneous',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name':        name,
      'price':       price,
      'imageUrl':    imageUrl,
      'barcode':     barcode,
      'nfcTagId':    nfcTagId,
      'description': description,
      'category':    category,
    };
  }
}
