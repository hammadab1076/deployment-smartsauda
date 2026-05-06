import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/api_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ApiDataSource _dataSource;

  ProductRepositoryImpl(this._dataSource);

  @override
  Future<List<ProductEntity>> getProducts() async {
    return await _dataSource.getProducts();
  }

  @override
  Future<ProductEntity?> getProductByBarcode(String barcode) async {
    return await _dataSource.getProductByBarcode(barcode);
  }

  @override
  Future<ProductEntity?> getProductByNfcTag(String nfcTagId) async {
    return await _dataSource.getProductByNfcTag(nfcTagId);
  }
}
