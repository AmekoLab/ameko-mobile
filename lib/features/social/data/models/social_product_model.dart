class SocialProductModel {
  final String id;
  final String name;
  final String? imageUrl;
  final double price;

  SocialProductModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
  });

  factory SocialProductModel.fromJson(Map<String, dynamic> json) {
    return SocialProductModel(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      price: json['price']?.toDouble() ?? 0.0,
    );
  }
}
