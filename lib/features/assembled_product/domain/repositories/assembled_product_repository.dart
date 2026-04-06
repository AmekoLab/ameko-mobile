import 'package:ameko_app/features/assembled_product/domain/entities/assembled_product_entity.dart';

abstract class AssembledProductRepository {
  Future<AssembledProductListResponse> getAll({int currentPage = 1, int pageSize = 10});
  Future<AssembledProductDetailEntity> getById(String id);
  Future<List<AssembledProductEntity>> getByShop(String shopId);
}

class AssembledProductListResponse {
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final List<AssembledProductEntity> items;

  const AssembledProductListResponse({
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.items,
  });

  bool get hasMore => currentPage * pageSize < totalCount;
}
