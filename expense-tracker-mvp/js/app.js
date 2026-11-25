window.App = {
  currentPage: 'home',
  isRegisterMode: false,

  async init() {
    await DB.init();
    this.setupAuthHandlers();
    this.setupNavHandlers();
    this.setupGlobalHandlers();
    await SyncService.init();
    this.registerServiceWorker();
    this.setupInstallPrompt();

    // Si ya hay sesión (misma pestaña), saltar login
    if (sessionStorage.getItem('authed') === '1' && DB.encryptionKey) {
      await this.showMain();
    }
  },

  registerServiceWorker() {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('sw.js').catch(e => console.warn('SW:', e));
    }
  },

  setupInstallPrompt() {
    let deferredPrompt = null;
    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault();
      deferredPrompt = e;
      // Muestra botón de instalación si existe
      const btn = document.getElementById('btn-install');
      if (btn) {
        btn.classList.remove('hidden');
        btn.onclick = async () => {
          deferredPrompt.prompt();
          await deferredPrompt.userChoice;
          deferredPrompt = null;
          btn.classList.add('hidden');
        };
      }
    });
  },

  setupAuthHandlers() {
    const form = document.getElementById('auth-form');
    const toggleLink = document.getElementById('auth-toggle-link');
    const toggleText = document.getElementById('auth-toggle-text');
    const confirmField = document.getElementById('confirm-field');
    const submitBtn = document.getElementById('auth-submit');
    const bioContainer = document.getElementById('biometric-container');
    const bioBtn = document.getElementById('biometric-login');

    (async () => {
      const registered = await AuthService.isRegistered();
      if (registered) {
        // Mostrar modo login
        this.isRegisterMode = false;
        toggleText.textContent = '¿Problemas para entrar?';
        toggleLink.textContent = 'Reiniciar app';
        toggleLink.onclick = async (e) => {
          e.preventDefault();
          if (confirm('¿Borrar TODOS los datos locales y empezar de cero?')) {
            indexedDB.deleteDatabase('GastosMVP');
            localStorage.clear();
            sessionStorage.clear();
            location.reload();
          }
        };
        submitBtn.textContent = 'Entrar';
        if (AuthService.hasBiometric()) bioContainer.classList.remove('hidden');
      } else {
        this.isRegisterMode = true;
        confirmField.classList.remove('hidden');
        submitBtn.textContent = 'Crear cuenta';
        toggleText.textContent = '¿Ya tienes cuenta?';
        toggleLink.textContent = 'Inicia sesión';
      }
    })();

    toggleLink.onclick = (e) => {
      if (toggleLink.dataset.resetBound) return;
      e.preventDefault();
      this.isRegisterMode = !this.isRegisterMode;
      confirmField.classList.toggle('hidden', !this.isRegisterMode);
      submitBtn.textContent = this.isRegisterMode ? 'Crear cuenta' : 'Entrar';
      toggleText.textContent = this.isRegisterMode ? '¿Ya tienes cuenta?' : '¿No tienes cuenta?';
      toggleLink.textContent = this.isRegisterMode ? 'Inicia sesión' : 'Regístrate';
      document.getElementById('auth-error').textContent = '';
    };

    form.onsubmit = async (e) => {
      e.preventDefault();
      const email = document.getElementById('auth-email').value.trim();
      const password = document.getElementById('auth-password').value;
      const confirm = document.getElementById('auth-password-confirm').value;
      const errEl = document.getElementById('auth-error');
      errEl.textContent = '';

      if (password.length < 6) {
        errEl.textContent = 'La contraseña debe tener al menos 6 caracteres';
        return;
      }
      if (this.isRegisterMode && password !== confirm) {
        errEl.textContent = 'Las contraseñas no coinciden';
        return;
      }

      submitBtn.disabled = true;
      submitBtn.textContent = 'Procesando…';

      try {
        if (this.isRegisterMode) {
          await AuthService.register(email, password);
        } else {
          await AuthService.login(email, password);
        }
        await this.showMain();
      } catch (err) {
        errEl.textContent = err.message;
        submitBtn.disabled = false;
        submitBtn.textContent = this.isRegisterMode ? 'Crear cuenta' : 'Entrar';
      }
    };

    bioBtn.onclick = async () => {
      try {
        const ok = await AuthService.authenticateBiometric();
        if (!ok) throw new Error('Biometría fallida');
        // Biometría solo verifica; aún se requiere contraseña para descifrar
        App.toast('Biometría OK. Introduce tu contraseña para desbloquear.', 'success');
        document.getElementById('auth-password').focus();
      } catch (e) {
        App.toast('Biometría no disponible: ' + e.message, 'error');
      }
    };
  },

  async showMain() {
    document.getElementById('auth-screen').classList.add('hidden');
    document.getElementById('main-screen').classList.remove('hidden');
    document.getElementById('user-email').textContent = AuthService.currentUser?.email || '';
    await this.navigate('home');
    await NotifService.checkBudgetThreshold();
  },

  setupNavHandlers() {
    document.querySelectorAll('.nav-item').forEach(btn => {
      btn.onclick = () => this.navigate(btn.dataset.page);
    });

    document.getElementById('btn-logout').onclick = async () => {
      await AuthService.logout();
      location.reload();
    };

    document.getElementById('btn-sync').onclick = async () => {
      try { await SyncService.sync(); }
      catch (e) { App.toast(e.message, 'error'); }
    };

    document.getElementById('btn-notif').onclick = async () => {
      await NotifService.notify('🔔 Notificación de prueba', 'Todo funciona correctamente');
      App.toast('Notificación enviada', 'success');
    };

    document.getElementById('btn-nuevo-gasto').onclick = () => this.openGastoForm();
    document.getElementById('btn-nueva-categoria').onclick = () => this.openCategoriaForm();
    document.getElementById('btn-nuevo-presupuesto').onclick = () => this.openPresupuestoForm();
  },

  setupGlobalHandlers() {
    document.getElementById('modal').onclick = (e) => {
      if (e.target.id === 'modal') this.closeModal();
    };
  },

  async navigate(page) {
    this.currentPage = page;
    document.querySelectorAll('.nav-item').forEach(b =>
      b.classList.toggle('active', b.dataset.page === page));
    document.querySelectorAll('.page').forEach(p =>
      p.classList.toggle('active', p.id === `page-${page}`));

    if (page === 'home') await this.renderHome();
    if (page === 'gastos') await this.renderGastos();
    if (page === 'categorias') await this.renderCategorias();
    if (page === 'presupuestos') await this.renderPresupuestos();
    if (page === 'graficos') await ChartsService.render();
  },

  async renderHome() {
    const gastos = await GastosService.list();
    const total = gastos.reduce((s, g) => s + g.monto, 0);
    document.getElementById('total-amount').textContent = this.formatMoney(total);
    document.getElementById('total-count').textContent = `${gastos.length} gasto${gastos.length !== 1 ? 's' : ''}`;

    const recent = gastos.slice(0, 5);
    const container = document.getElementById('recent-gastos');
    if (recent.length === 0) {
      container.innerHTML = '<div class="empty"><div class="empty-icon">💸</div><p>Sin gastos aún</p></div>';
      return;
    }
    const categorias = await CategoriasService.list();
    container.innerHTML = '';
    for (const g of recent) {
      const cat = categorias.find(c => c.id === g.categoriaId);
      const div = document.createElement('div');
      div.className = 'list-item';
      div.innerHTML = `
        <div class="item-icon" style="background:${this.hexA(cat?.color || '#78909C', 0.2)}">${cat?.icono || '?'}</div>
        <div class="item-body">
          <div class="item-title">${cat?.nombre || 'Sin categoría'}</div>
          <div class="item-subtitle">${this.formatDate(g.fecha)}${g.descripcion ? ' · ' + g.descripcion : ''}</div>
        </div>
        <div class="item-amount">${this.formatMoney(g.monto)}</div>
      `;
      container.appendChild(div);
    }
  },

  async renderGastos() {
    const gastos = await GastosService.list();
    const categorias = await CategoriasService.list();
    const container = document.getElementById('gastos-list');

    if (gastos.length === 0) {
      container.innerHTML = '<div class="empty"><div class="empty-icon">📝</div><p>No hay gastos. ¡Añade el primero!</p></div>';
      return;
    }

    container.innerHTML = '';
    for (const g of gastos) {
      const cat = categorias.find(c => c.id === g.categoriaId);
      const div = document.createElement('div');
      div.className = 'list-item';
      div.innerHTML = `
        <div class="item-icon" style="background:${this.hexA(cat?.color || '#78909C', 0.2)}">${cat?.icono || '?'}</div>
        <div class="item-body">
          <div class="item-title">${cat?.nombre || 'Sin categoría'}</div>
          <div class="item-subtitle">${this.formatDate(g.fecha)}${g.descripcion ? ' · ' + g.descripcion : ''}</div>
        </div>
        <div class="item-amount">${this.formatMoney(g.monto)}</div>
        <div class="item-actions">
          <button title="Editar" data-edit="${g.id}">✏️</button>
          <button title="Eliminar" data-del="${g.id}">🗑️</button>
        </div>
      `;
      container.appendChild(div);
    }

    container.querySelectorAll('[data-edit]').forEach(btn => {
      btn.onclick = () => {
        const g = gastos.find(x => x.id === btn.dataset.edit);
        this.openGastoForm(g);
      };
    });
    container.querySelectorAll('[data-del]').forEach(btn => {
      btn.onclick = async () => {
        if (!confirm('¿Eliminar este gasto?')) return;
        await GastosService.delete(btn.dataset.del);
        App.toast('Gasto eliminado', 'success');
        this.renderGastos();
        this.renderHome();
      };
    });
  },

  async renderCategorias() {
    const cats = await CategoriasService.list();
    const container = document.getElementById('categorias-list');
    if (cats.length === 0) {
      container.innerHTML = '<div class="empty"><div class="empty-icon">🏷️</div><p>Sin categorías</p></div>';
      return;
    }
    container.innerHTML = '';
    cats.forEach(c => {
      const div = document.createElement('div');
      div.className = 'list-item';
      div.innerHTML = `
        <div class="item-icon" style="background:${this.hexA(c.color, 0.2)}">${c.icono}</div>
        <div class="item-body">
          <div class="item-title">${c.nombre}</div>
        </div>
        <div class="item-actions">
          <button data-del="${c.id}">🗑️</button>
        </div>
      `;
      container.appendChild(div);
    });
    container.querySelectorAll('[data-del]').forEach(btn => {
      btn.onclick = async () => {
        if (!confirm('¿Eliminar categoría?')) return;
        await CategoriasService.delete(btn.dataset.del);
        this.renderCategorias();
      };
    });
  },

  async renderPresupuestos() {
    const presupuestos = await PresupuestosService.list();
    const container = document.getElementById('presupuestos-list');
    if (presupuestos.length === 0) {
      container.innerHTML = '<div class="empty"><div class="empty-icon">💼</div><p>Crea tu primer presupuesto</p></div>';
      return;
    }
    container.innerHTML = '';
    for (const p of presupuestos) {
      const gastado = await PresupuestosService.totalGastadoEn(p);
      const pct = Math.min(gastado / p.limite, 1.5);
      const color = pct >= 1 ? '#B3261E' : pct >= 0.8 ? '#FF9800' : '#4CAF50';
      const div = document.createElement('div');
      div.className = 'list-item';
      div.style.flexDirection = 'column';
      div.style.alignItems = 'stretch';
      div.innerHTML = `
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px">
          <div class="item-title">${p.nombre}</div>
          <div class="item-actions"><button data-del="${p.id}">🗑️</button></div>
        </div>
        <div style="font-size:13px;color:#49454F;margin-bottom:6px">
          ${this.formatMoney(gastado)} / ${this.formatMoney(p.limite)}
        </div>
        <div class="progress">
          <div class="progress-bar" style="width:${Math.min(pct*100,100)}%;background:${color}"></div>
        </div>
        <div class="progress-text" style="color:${color}">${(pct*100).toFixed(1)}% usado</div>
      `;
      container.appendChild(div);
    }
    container.querySelectorAll('[data-del]').forEach(btn => {
      btn.onclick = async () => {
        if (!confirm('¿Eliminar presupuesto?')) return;
        await PresupuestosService.delete(btn.dataset.del);
        this.renderPresupuestos();
      };
    });
  },

  // ---------- MODALES ----------

  openModal(html) {
    document.getElementById('modal-content').innerHTML = html;
    document.getElementById('modal').classList.remove('hidden');
  },
  closeModal() {
    document.getElementById('modal').classList.add('hidden');
  },

  async openGastoForm(gasto = null) {
    const categorias = await CategoriasService.list();
    const catOptions = categorias
      .map(c => `<option value="${c.id}" ${gasto?.categoriaId === c.id ? 'selected' : ''}>${c.icono} ${c.nombre}</option>`)
      .join('');

    const hoy = new Date().toISOString().slice(0, 10);

    this.openModal(`
      <h3>${gasto ? 'Editar gasto' : 'Nuevo gasto'}</h3>
      <div class="form-group">
        <label>Monto</label>
        <input type="number" id="f-monto" step="0.01" min="0.01" placeholder="0.00" value="${gasto?.monto || ''}">
      </div>
      <div class="form-group">
        <label>Categoría</label>
        <select id="f-categoria">${catOptions}</select>
      </div>
      <div class="form-group">
        <label>Descripción (opcional)</label>
        <input type="text" id="f-desc" placeholder="Ej: almuerzo" value="${gasto?.descripcion || ''}">
      </div>
      <div class="form-group">
        <label>Fecha</label>
        <input type="date" id="f-fecha" value="${gasto ? new Date(gasto.fecha).toISOString().slice(0,10) : hoy}">
      </div>
      <div class="form-group">
        <label>Foto del ticket (opcional)</label>
        <button type="button" class="btn-secondary" id="f-camera" style="width:100%">📸 Capturar ticket</button>
        <div id="f-preview"></div>
      </div>
      <div class="modal-actions">
        <button class="btn-secondary" id="f-cancel">Cancelar</button>
        <button class="btn-primary" id="f-save">Guardar</button>
      </div>
    `);

    let foto = gasto?.fotoTicket || null;
    const preview = document.getElementById('f-preview');
    if (foto) preview.innerHTML = `<img src="${foto}" class="image-preview">`;

    document.getElementById('f-camera').onclick = async () => {
      const data = await GastosService.openCameraModal();
      if (data) {
        foto = data;
        preview.innerHTML = `<img src="${foto}" class="image-preview">`;
      }
    };

    document.getElementById('f-cancel').onclick = () => this.closeModal();

    document.getElementById('f-save').onclick = async () => {
      const monto = parseFloat(document.getElementById('f-monto').value);
      const categoriaId = document.getElementById('f-categoria').value;
      const descripcion = document.getElementById('f-desc').value.trim();
      const fecha = document.getElementById('f-fecha').value;

      if (!monto || monto <= 0) return this.toast('Monto inválido', 'error');
      if (!categoriaId) return this.toast('Selecciona una categoría', 'error');

      const record = {
        id: gasto?.id || crypto.randomUUID(),
        monto,
        categoriaId,
        descripcion: descripcion || null,
        fecha: new Date(fecha).toISOString(),
        fotoTicket: foto
      };

      if (gasto) await GastosService.update(record);
      else await GastosService.create(record);

      this.closeModal();
      this.toast(gasto ? 'Gasto actualizado' : 'Gasto añadido', 'success');
      await NotifService.checkBudgetThreshold();
      await this.navigate(this.currentPage);
    };
  },

  async openCategoriaForm() {
    this.openModal(`
      <h3>Nueva categoría</h3>
      <div class="form-group">
        <label>Nombre</label>
        <input type="text" id="c-nombre" placeholder="Ej: Comida">
      </div>
      <div class="form-group">
        <label>Emoji</label>
        <input type="text" id="c-icono" value="🏷️" maxlength="4">
      </div>
      <div class="form-group">
        <label>Color</label>
        <input type="color" id="c-color" value="#6750A4">
      </div>
      <div class="modal-actions">
        <button class="btn-secondary" id="c-cancel">Cancelar</button>
        <button class="btn-primary" id="c-save">Crear</button>
      </div>
    `);
    document.getElementById('c-cancel').onclick = () => this.closeModal();
    document.getElementById('c-save').onclick = async () => {
      const nombre = document.getElementById('c-nombre').value.trim();
      const icono = document.getElementById('c-icono').value || '🏷️';
      const color = document.getElementById('c-color').value;
      if (!nombre) return this.toast('Nombre requerido', 'error');
      await CategoriasService.create({ id: crypto.randomUUID(), nombre, icono, color });
      this.closeModal();
      this.toast('Categoría creada', 'success');
      await this.navigate(this.currentPage);
    };
  },

  async openPresupuestoForm() {
    const hoy = new Date();
    const fin = new Date(); fin.setDate(fin.getDate() + 7);
    this.openModal(`
      <h3>Nuevo presupuesto</h3>
      <div class="form-group">
        <label>Nombre</label>
        <input type="text" id="p-nombre" value="Semanal">
      </div>
      <div class="form-group">
        <label>Límite</label>
        <input type="number" id="p-limite" step="0.01" min="1" value="500">
      </div>
      <div class="form-group">
        <label>Inicio</label>
        <input type="date" id="p-inicio" value="${hoy.toISOString().slice(0,10)}">
      </div>
      <div class="form-group">
        <label>Fin</label>
        <input type="date" id="p-fin" value="${fin.toISOString().slice(0,10)}">
      </div>
      <div class="modal-actions">
        <button class="btn-secondary" id="p-cancel">Cancelar</button>
        <button class="btn-primary" id="p-save">Crear</button>
      </div>
    `);
    document.getElementById('p-cancel').onclick = () => this.closeModal();
    document.getElementById('p-save').onclick = async () => {
      const nombre = document.getElementById('p-nombre').value.trim();
      const limite = parseFloat(document.getElementById('p-limite').value);
      const fechaInicio = document.getElementById('p-inicio').value;
      const fechaFin = document.getElementById('p-fin').value;
      if (!nombre || !limite || !fechaInicio || !fechaFin) return this.toast('Completa todos los campos', 'error');
      await PresupuestosService.create({
        id: crypto.randomUUID(),
        nombre, limite,
        fechaInicio: new Date(fechaInicio).toISOString(),
        fechaFin: new Date(fechaFin).toISOString()
      });
      this.closeModal();
      this.toast('Presupuesto creado', 'success');
      await this.navigate(this.currentPage);
    };
  },

  // ---------- HELPERS ----------

  formatMoney(v) {
    return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(v || 0);
  },

  formatDate(d) {
    return new Date(d).toLocaleDateString('es-MX', { day: '2-digit', month: 'short', year: 'numeric' });
  },

  hexA(hex, alpha) {
    const c = hex.replace('#', '');
    const r = parseInt(c.substr(0, 2), 16);
    const g = parseInt(c.substr(2, 2), 16);
    const b = parseInt(c.substr(4, 2), 16);
    return `rgba(${r},${g},${b},${alpha})`;
  },

  toast(msg, type = 'info') {
    const el = document.getElementById('toast');
    el.textContent = msg;
    el.className = `toast ${type}`;
    clearTimeout(this._toastTimer);
    this._toastTimer = setTimeout(() => el.classList.add('hidden'), 3000);
  }
};

document.addEventListener('DOMContentLoaded', () => App.init());