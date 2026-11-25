window.PresupuestosService = {
  async list() { return await DB.getAll('presupuestos'); },
  async create(p) { await DB.put('presupuestos', p.id, p); },
  async update(p) { await DB.put('presupuestos', p.id, p); },
  async delete(id) { await DB.del('presupuestos', id); },

  async totalGastadoEn(p) {
    const gastos = await GastosService.list();
    const inicio = new Date(p.fechaInicio);
    const fin = new Date(p.fechaFin);
    return gastos
      .filter(g => {
        const f = new Date(g.fecha);
        return f >= inicio && f <= fin;
      })
      .reduce((s, g) => s + g.monto, 0);
  }
};