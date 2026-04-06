import 'package:ameko_app/features/assembled_product/domain/entities/assembled_product_entity.dart';

class AssembledProductModel extends AssembledProductEntity {
  const AssembledProductModel({
    required super.id,
    required super.name,
    required super.price,
    required super.shopId,
    required super.shopName,
    super.logoUrl,
    super.view3DUrl,
    super.image1,
    super.image2,
    super.image3,
    super.description,
    required super.quantity,
    super.layout,
    super.mounting,
    super.pcb,
    super.connection,
    super.battery,
    required super.isDeleted,
    required super.createdAt,
  });

  factory AssembledProductModel.fromJson(Map<String, dynamic> json) {
    return AssembledProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _parseDouble(json['price']),
      shopId: json['shopId']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString(),
      view3DUrl: json['view3DUrl']?.toString(),
      image1: json['image1']?.toString(),
      image2: json['image2']?.toString(),
      image3: json['image3']?.toString(),
      description: json['description']?.toString(),
      quantity: _parseInt(json['quantity']),
      layout: json['layout']?.toString(),
      mounting: json['mounting']?.toString(),
      pcb: json['pcb']?.toString(),
      connection: json['connection']?.toString(),
      battery: json['battery']?.toString(),
      isDeleted: json['isDeleted'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }

  static int parseIntPublic(dynamic val) => _parseInt(val);
}

class AssembledProductDetailModel extends AssembledProductDetailEntity {
  AssembledProductDetailModel({
    required super.id,
    required super.name,
    required super.price,
    required super.shopId,
    required super.shopName,
    super.logoUrl,
    super.view3DUrl,
    super.image1,
    super.image2,
    super.image3,
    super.description,
    required super.quantity,
    super.layout,
    super.mounting,
    super.pcb,
    super.connection,
    super.battery,
    required super.isDeleted,
    required super.createdAt,
    required super.details,
  });

  factory AssembledProductDetailModel.fromJson(Map<String, dynamic> json) {
    final base = AssembledProductModel.fromJson(json);
    final rawDetails = json['details'] as List<dynamic>? ?? [];
    return AssembledProductDetailModel(
      id: base.id,
      name: base.name,
      price: base.price,
      shopId: base.shopId,
      shopName: base.shopName,
      logoUrl: base.logoUrl,
      view3DUrl: base.view3DUrl,
      image1: base.image1,
      image2: base.image2,
      image3: base.image3,
      description: base.description,
      quantity: base.quantity,
      layout: base.layout,
      mounting: base.mounting,
      pcb: base.pcb,
      connection: base.connection,
      battery: base.battery,
      isDeleted: base.isDeleted,
      createdAt: base.createdAt,
      details: rawDetails
          .map((d) => AssembledProductDetailItem(
                id: d['id']?.toString() ?? '',
                baseKitId: d['baseKitId']?.toString(),
                baseKitName: d['baseKitName']?.toString(),
                componentId: d['componentId']?.toString(),
                componentName: d['componentName']?.toString(),
                quantity: AssembledProductModel.parseIntPublic(d['quantity']),
                soundUrl: d['soundUrl']?.toString(),
              ))
          .toList(),
    );
  }
}
