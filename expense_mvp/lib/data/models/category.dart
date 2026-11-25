class Category {
  final String id;
  final String name;
  final String icon;
  final int color;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
      };

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as String,
        name: m['name'] as String,
        icon: m['icon'] as String,
        color: m['color'] as int,
      );
}