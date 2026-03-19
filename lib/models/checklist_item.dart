class ChecklistItem {
  final String id;
  final String title;
  bool isChecked;
  final ChecklistCategory category;

  ChecklistItem({
    required this.id,
    required this.title,
    this.isChecked = false,
    this.category = ChecklistCategory.always,
  });

  ChecklistItem copyWith({
    String? id,
    String? title,
    bool? isChecked,
    ChecklistCategory? category,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isChecked: isChecked ?? this.isChecked,
      category: category ?? this.category,
    );
  }
}

enum ChecklistCategory {
  always,
  rain,
  hot,
  cold,
  windy,
}
