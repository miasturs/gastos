class Gasto {
  final String id;
  final double monto;
  final DateTime fecha;
  final String categoriaId;
  final String? presupuestoId;
  final String? fotoTicket;
  final String? descripcion;
  final bool sincronizado;

  Gasto({
    required this.id,
    required this.monto,
    required this.fecha,
    required this.categoriaId,
    this.presupuestoId,
    this.fotoTicket,
    this.descripcion,
    this.sincronizado = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'monto': monto,
        'fecha': fecha.toIso8601String(),
        'categoriaId': categoriaId,
        'presupuestoId': presupuestoId,
        'fotoTicket': fotoTicket,
        'descripcion': descripcion,
        'sincronizado': sincronizado,
      };

  factory Gasto.fromMap(Map m) => Gasto(
        id: m['id'] as String,
        monto: (m['monto'] as num).toDouble(),
        fecha: DateTime.parse(m['fecha'] as String),
        categoriaId: m['categoriaId'] as String,
        presupuestoId: m['presupuestoId'] as String?,
        fotoTicket: m['fotoTicket'] as String?,
        descripcion: m['descripcion'] as String?,
        sincronizado: m['sincronizado'] as bool? ?? false,
      );

  Gasto copyWith({bool? sincronizado}) => Gasto(
        id: id,
        monto: monto,
        fecha: fecha,
        categoriaId: categoriaId,
        presupuestoId: presupuestoId,
        fotoTicket: fotoTicket,
        descripcion: descripcion,
        sincronizado: sincronizado ?? this.sincronizado,
      );
}