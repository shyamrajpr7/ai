class ConversationBranch {
  final String id;
  String name;

  ConversationBranch({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };

  factory ConversationBranch.fromJson(Map<String, dynamic> json) =>
      ConversationBranch(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Branch',
      );
}
