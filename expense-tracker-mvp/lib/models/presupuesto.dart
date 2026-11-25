class Presupuesto {
  final String id;
  final String nombre;
  final double limite;
  final DateTime fechaInicio;
  final DateTime fechaFin;

  Presupuesto({
    required this.id,
    required this.nombre,
    required this.limite,
    required this.fechaInicio,
    required this.fechaFin,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'limite': limite,
        'fechaInicio': fechaInicio.toIso8601String(),
        'fechaFin': fechaFin.toIso8601String(),
      };

  factory Presupuesto.fromMap(Map m) => Presupuesto(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        limite: (m['limite'] as num).toDouble(),
        fechaInicio: DateTime.parse(m['fechaInicio'] as String),
        fechaFin: DateTime.parse(m['fechaFin'] as String),
      );

  bool get estaActivo {
    final hoy = DateTime.now();
    return hoy.isAfter(fechaInicio.subtract(const Duration(days: 1))) &&
        hoy.isBefore(fechaFin.add(const Duration(days: 1)));
  }
}