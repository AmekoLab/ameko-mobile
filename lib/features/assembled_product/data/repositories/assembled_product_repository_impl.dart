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
  Future<AssembledProductListResponse> search({
    String? searchTerm,
    double? minPrice,
    double? maxPrice,
    String? layout,
    String? mounting,
    String? pcb,
    String? connection,
    String? battery,
    String? shopId,
    double? minRating,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    final Map<String, dynamic> queryParams = {
      'PageNumber': pageNumber,
      'PageSize': pageSize,
    };
    if (searchTerm != null) queryParams['SearchTerm'] = searchTerm;
    if (minPrice != null) queryParams['MinPrice'] = minPrice;
    if (maxPrice != null) queryParams['MaxPrice'] = maxPrice;
    if (layout != null) queryParams['Layout'] = layout;
    if (mounting != null) queryParams['Mounting'] = mounting;
    if (pcb != null) queryParams['PCB'] = pcb;
    if (connection != null) queryParams['Connection'] = connection;
    if (battery != null) queryParams['Battery'] = battery;
    if (shopId != null) queryParams['ShopId'] = shopId;
    if (minRating != null) queryParams['MinRating'] = minRating;

    final response = await _dio.get(
      '/api/v1/AssembledProduct/search',
      queryParameters: queryParams,
    );
    
    // The response might be slightly different for search according to some APIs, 
    // but the guide says it's PaginatedResult.
    final data = response.data['data'] ?? response.data;
    final items = (data['items'] as List<dynamic>)
        .map((e) => AssembledProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
        
    return AssembledProductListResponse(
      totalCount: data['totalCount'] as int? ?? 0,
      currentPage: data['currentPage'] as int? ?? pageNumber,
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
