import 'package:dio/dio.dart';
import 'package:ameko_app/features/assembled_product/domain/entities/assembled_product_entity.dart';
import 'package:ameko_app/features/assembled_product/domain/repositories/assembled_product_repository.dart';
import 'package:ameko_app/features/assembled_product/data/models/assembled_product_model.dart';

class AssembledProductRepositoryImpl implements AssembledProductRepository {
  final Dio _dio;

  AssembledProductRepositoryImpl(this._dio);

  @override
  Future<AssembledProductListResponse> getAll({int currentPage = 1, int pageSize = 10, String? keyword}) async {
    final Map<String, dynamic> queryParams = {
      'currentPage': currentPage,
      'pageSize': pageSize,
    };
    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }

    final response = await _dio.get(
      '/api/v1/AssembledProduct',
      queryParameters: queryParams,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .map((e) => AssembledProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return AssembledProductListResponse(
      totalCount: data['totalCount'] as int? ?? 0,
      currentPage: data['currentPage'] as int? ?? currentPage,
      pageSize: data['pageSize'] as int? ?? pageSize,
      items: items,
    );
  }

  @override
  Future<AssembledProductDetailEntity> getById(String id) async {
    final response = await _dio.get('/api/v1/AssembledProduct/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return AssembledProductDetailModel.fromJson(data);
  }

  @override
  Future<List<AssembledProductEntity>> getByShop(String shopId) async {
    final response = await _dio.get('/api/v1/AssembledProduct/shop/$shopId');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => AssembledProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
