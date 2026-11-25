class Categoria {
  final String id;
  final String nombre;
  final String icono;
  final int color;

  Categoria({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.color,
  });

  Map<String, dynamic> toMap() =>
      {'id': id, 'nombre': nombre, 'icono': icono, 'color': color};

  factory Categoria.fromMap(Map m) => Categoria(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        icono: m['icono'] as String,
        color: m['color'] as int,
      );
}