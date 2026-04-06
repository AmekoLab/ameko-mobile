class AssembledProductEntity {
  final String id;
  final String name;
  final double price;
  final String shopId;
  final String shopName;
  final String? logoUrl;
  final String? view3DUrl;
  final String? image1;
  final String? image2;
  final String? image3;
  final String? description;
  final int quantity;
  final String? layout;
  final String? mounting;
  final String? pcb;
  final String? connection;
  final String? battery;
  final bool isDeleted;
  final DateTime createdAt;

  const AssembledProductEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.shopId,
    required this.shopName,
    this.logoUrl,
    this.view3DUrl,
    this.image1,
    this.image2,
    this.image3,
    this.description,
    required this.quantity,
    this.layout,
    this.mounting,
    this.pcb,
    this.connection,
    this.battery,
    required this.isDeleted,
    required this.createdAt,
  });
}

class AssembledProductDetailEntity extends AssembledProductEntity {
  final List<AssembledProductDetailItem> details;

  const AssembledProductDetailEntity({
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
    required this.details,
  });
}

class AssembledProductDetailItem {
  final String id;
  final String? baseKitId;
  final String? baseKitName;
  final String? componentId;
  final String? componentName;
  final int quantity;
  final String? soundUrl;

  const AssembledProductDetailItem({
    required this.id,
    this.baseKitId,
    this.baseKitName,
    this.componentId,
    this.componentName,
    required this.quantity,
    this.soundUrl,
  });
}
