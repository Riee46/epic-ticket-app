class TicketModel {
  final int id;
  final String category;
  final int price;
  final int quota;

  TicketModel({
    required this.id,
    required this.category,
    required this.price,
    required this.quota,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'],
      category: json['category'],
      price: json['price'],
      quota: json['quota'],
    );
  }
}
