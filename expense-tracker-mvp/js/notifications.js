window.NotifService = {
  async requestPermission() {
    if (!('Notification' in window)) return false;
    if (Notification.permission === 'granted') return true;
    if (Notification.permission === 'denied') return false;
    const perm = await Notification.requestPermission();
    return perm === 'granted';
  },

  async notify(title, body) {
    const ok = await this.requestPermission();
    if (!ok) {
      App.toast('Permiso de notificaciones no concedido', 'error');
      return;
    }
    new Notification(title, {
      body,
      icon: "data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>💰</text></svg>",
      badge: "data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>💰</text></svg>"
    });
  },

  async checkBudgetThreshold() {
    const presupuestos = await PresupuestosService.list();
    const gastos = await GastosService.list();
    const hoy = new Date();

    for (const p of presupuestos) {
      const inicio = new Date(p.fechaInicio);
      const fin = new Date(p.fechaFin);
      if (hoy < inicio || hoy > fin) continue;

      const total = gastos
        .filter(g => new Date(g.fecha) >= inicio && new Date(g.fecha) <= fin)
        .reduce((s, g) => s + g.monto, 0);

      const pct = total / p.limite;
      if (pct >= 0.8) {
        const key = `notif_${p.id}_${hoy.toISOString().slice(0,10)}`;
        if (!localStorage.getItem(key)) {
          await this.notify(
            '⚠️ Alerta de presupuesto',
            `Has superado el ${(pct*100).toFixed(0)}% de tu presupuesto "${p.nombre}"`
          );
          localStorage.setItem(key, '1');
        }
      }
    }
  }
};