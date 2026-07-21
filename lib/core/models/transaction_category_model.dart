/// Represents a category for grouping transactions (e.g., Food, Housing, Salary).
class TransactionCategoryModel {
  final String id;
  final String name;
  final String type; // "Expense" or "Income"
  final List<String> subCategories;
  final int iconCode;

  const TransactionCategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.subCategories,
    required this.iconCode,
  });

  // Optional: Add a copyWith method for easier state immutability if needed later
  TransactionCategoryModel copyWith({
    String? id,
    String? name,
    String? type,
    List<String>? subCategories,
    int? iconCode,
  }) {
    return TransactionCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      subCategories: subCategories ?? this.subCategories,
      iconCode: iconCode ?? this.iconCode,
    );
  }
}