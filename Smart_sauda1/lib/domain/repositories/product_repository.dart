import '../entities/product_entity.dart';

abstract class ProductRepository {
  Future<List<ProductEntity>> getProducts();
  Future<ProductEntity?> getProductByBarcode(String barcode);
  Future<ProductEntity?> getProductByNfcTag(String nfcTagId);
}
