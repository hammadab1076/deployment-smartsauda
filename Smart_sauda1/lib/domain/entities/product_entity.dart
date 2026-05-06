class ProductEntity {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String barcode;
  final String nfcTagId;
  final String description;
  final String category;

  ProductEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.barcode,
    this.nfcTagId = '',
    required this.description,
    required this.category,
  });
}
