class Document {
  final String id;
  final String supplier;
  final String type; // Factura, Comprobante, Recibo
  final String date;
  final String category;
  final double amount;
  final String notes;
  final String format;
  final String? imageUrl;

  Document({
    required this.id,
    required this.supplier,
    required this.type,
    required this.date,
    required this.category,
    required this.amount,
    required this.notes,
    required this.format,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'supplier': supplier,
        'type': type,
        'date': date,
        'category': category,
        'amount': amount,
        'notes': notes,
        'format': format,
        'image_url': imageUrl,
      };

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        id: json['id'] as String,
        supplier: json['supplier'] as String,
        type: json['type'] as String,
        date: json['date'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        notes: json['notes'] as String,
        format: json['format'] as String,
        imageUrl: json['image_url'] as String?,
      );
}
