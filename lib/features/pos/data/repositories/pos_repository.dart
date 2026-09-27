import '../../../products/data/models/product_model.dart';
import '../datasources/pos_remote_data_source.dart';
import '../models/pos_sale_model.dart';

abstract class PosRepository {
  Stream<List<ProductModel>> getProductsStream();
  Future<List<ProductModel>> getProducts();
  Future<PosSaleModel> submitPosSale(PosSaleModel sale);
}

class PosRepositoryImpl implements PosRepository {
  final PosRemoteDataSource _remoteDataSource;

  PosRepositoryImpl({PosRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? PosRemoteDataSourceImpl();

  @override
  Stream<List<ProductModel>> getProductsStream() {
    return _remoteDataSource.getProductsStream();
  }

  @override
  Future<List<ProductModel>> getProducts() {
    return _remoteDataSource.getProducts();
  }

  @override
  Future<PosSaleModel> submitPosSale(PosSaleModel sale) {
    return _remoteDataSource.submitPosSale(sale);
  }
}
