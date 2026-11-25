window.SyncService = {
  client: null,

  async init() {
    const cfg = window.APP_CONFIG;
    if (!cfg.supabaseUrl || !cfg.supabaseAnonKey) return false;
    try {
      // Carga dinámica del SDK de Supabase
      await new Promise((resolve, reject) => {
        const s = document.createElement('script');
        s.src = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2';
        s.onload = resolve;
        s.onerror = reject;
        document.head.appendChild(s);
      });
      this.client = window.supabase.createClient(cfg.supabaseUrl, cfg.supabaseAnonKey);
      return true;
    } catch (e) {
      console.warn('Supabase no disponible:', e);
      return false;
    }
  },

  enabled() { return !!this.client; },

  async sync() {
    if (!this.enabled()) throw new Error('Sincronización no configurada');

    const { data: { user } } = await this.client.auth.getUser();
    if (!user) {
      App.toast('Inicia sesión con Supabase en js/config.js primero', 'error');
      return;
    }

    const gastos = await GastosService.list();
    const payload = gastos.map(g => ({
      id: g.id,
      user_id: user.id,
      monto: g.monto,
      fecha: g.fecha,
      categoria_id: g.categoriaId,
      descripcion: g.descripcion || null
    }));

    const { error } = await this.client.from('gastos').upsert(payload);
    if (error) throw error;
    App.toast('Sincronización exitosa', 'success');
  }
};