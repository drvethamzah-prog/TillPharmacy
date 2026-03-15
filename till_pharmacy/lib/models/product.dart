class Product {
  final String barcode;
  final String name;
  final String unit;
  final double minPrice;
  double price;
  int qty;

  Product({
    required this.barcode,
    required this.name,
    required this.unit,
    required this.price,
    required this.minPrice,
    this.qty = 1,
  });
}