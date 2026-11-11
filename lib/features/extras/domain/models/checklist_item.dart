class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.roomCategory,
    required this.title,
    this.isMarked = false,
    this.position = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String roomCategory;
  final String title;
  final bool isMarked;
  final int position;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChecklistItem copyWith({
    String? id,
    String? roomCategory,
    String? title,
    bool? isMarked,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      roomCategory: roomCategory ?? this.roomCategory,
      title: title ?? this.title,
      isMarked: isMarked ?? this.isMarked,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChecklistItem &&
        other.id == id &&
        other.roomCategory == roomCategory &&
        other.title == title &&
        other.isMarked == isMarked &&
        other.position == position &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      roomCategory,
      title,
      isMarked,
      position,
      createdAt,
      updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomCategory': roomCategory,
      'title': title,
      'isMarked': isMarked,
      'position': position,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      roomCategory: json['roomCategory'] as String,
      title: json['title'] as String,
      isMarked: json['isMarked'] as bool? ?? false,
      position: json['position'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}
