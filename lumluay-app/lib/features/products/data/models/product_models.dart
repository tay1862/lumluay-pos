class Category {
  final String id;
  final String name;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  factory Category.fromJson(Map<String, dynamic> j) {
    return Category(
      id: '${j['id']}',
      name: '${j['name']}',
      sortOrder: int.tryParse('${j['sortOrder']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sortOrder': sortOrder,
      };
}

class ModifierOption {
  final String id;
  final String name;
  final double priceAdjustment;

  const ModifierOption({
    required this.id,
    required this.name,
    required this.priceAdjustment,
  });

  factory ModifierOption.fromJson(Map<String, dynamic> j) {
    return ModifierOption(
      id: '${j['id']}',
      name: '${j['name']}',
      priceAdjustment:
          double.tryParse('${j['priceAdjustment'] ?? j['extraPrice'] ?? 0}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'priceAdjustment': priceAdjustment,
      };
}

class ModifierGroup {
  final String id;
  final String name;
  final bool isRequired;
  final bool isMultiple;
  final List<ModifierOption> options;

  const ModifierGroup({
    required this.id,
    required this.name,
    required this.isRequired,
    required this.isMultiple,
    required this.options,
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> j) {
    return ModifierGroup(
      id: '${j['id']}',
      name: '${j['name']}',
      isRequired: j['isRequired'] == true,
      isMultiple: j['isMultiple'] == true || j['multiSelect'] == true,
      options: (j['options'] as List<dynamic>? ?? [])
          .map((e) => ModifierOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isRequired': isRequired,
        'isMultiple': isMultiple,
        'options': options.map((e) => e.toJson()).toList(),
      };
}

class ProductVariant {
  final String id;
  final String name;
  final double price;
  final String? sku;

  const ProductVariant({
    required this.id,
    required this.name,
    required this.price,
    this.sku,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> j) {
    return ProductVariant(
      id: '${j['id']}',
      name: '${j['name']}',
      price: double.tryParse('${j['price']}') ?? 0,
      sku: j['sku']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'sku': sku,
      };
}

class Product {
  final String id;
  final String name;
  final double basePrice;
  final String? sku;
  final String? barcode;
  final String? imageUrl;
  final String productType;
  final bool isActive;
  final Category? category;
  final int? stock;
  final List<ProductVariant> variants;
  final List<ModifierGroup> modifierGroups;

  const Product({
    required this.id,
    required this.name,
    required this.basePrice,
    this.sku,
    this.barcode,
    this.imageUrl,
    required this.productType,
    required this.isActive,
    this.category,
    this.stock,
    this.variants = const [],
    this.modifierGroups = const [],
  });

  factory Product.fromJson(Map<String, dynamic> j) {
    return Product(
      id: '${j['id']}',
      name: '${j['name']}',
      basePrice: double.tryParse('${j['basePrice']}') ?? 0,
      sku: j['sku']?.toString(),
      barcode: j['barcode']?.toString(),
      imageUrl: j['imageUrl']?.toString(),
      productType: '${j['productType'] ?? 'simple'}',
      isActive: j['isActive'] == true || j['isActive'] == 1,
      category: j['category'] != null
          ? Category.fromJson(j['category'] as Map<String, dynamic>)
          : null,
      stock: j['stock'] != null ? int.tryParse('${j['stock']}') : null,
      variants: (j['variants'] as List<dynamic>? ?? [])
          .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
      modifierGroups: (j['modifierGroups'] as List<dynamic>? ?? [])
          .map((e) => ModifierGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'basePrice': basePrice,
        'sku': sku,
        'barcode': barcode,
        'imageUrl': imageUrl,
        'productType': productType,
        'isActive': isActive,
        'category': category?.toJson(),
        'stock': stock,
        'variants': variants.map((e) => e.toJson()).toList(),
        'modifierGroups': modifierGroups.map((e) => e.toJson()).toList(),
      };
}
