window.DB = {
  db: null,
  encryptionKey: null,

  async init() {
    return new Promise((resolve, reject) => {
      const req = indexedDB.open('GastosMVP', 1);
      req.onupgradeneeded = (e) => {
        const db = e.target.result;
        ['auth', 'gastos', 'categorias', 'presupuestos'].forEach(name => {
          if (!db.objectStoreNames.contains(name)) {
            db.createObjectStore(name, { keyPath: 'id' });
          }
        });
      };
      req.onsuccess = (e) => { this.db = e.target.result; resolve(); };
      req.onerror = () => reject(req.error);
    });
  },

  setKey(key) { this.encryptionKey = key; },

  async _putRaw(store, record) {
    return new Promise((resolve, reject) => {
      const tx = this.db.transaction(store, 'readwrite');
      tx.objectStore(store).put(record);
      tx.oncomplete = resolve;
      tx.onerror = () => reject(tx.error);
    });
  },

  async _getRaw(store, id) {
    return new Promise((resolve, reject) => {
      const tx = this.db.transaction(store, 'readonly');
      const req = tx.objectStore(store).get(id);
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  },

  async _getAllRaw(store) {
    return new Promise((resolve, reject) => {
      const tx = this.db.transaction(store, 'readonly');
      const req = tx.objectStore(store).getAll();
      req.onsuccess = () => resolve(req.result || []);
      req.onerror = () => reject(req.error);
    });
  },

  async _deleteRaw(store, id) {
    return new Promise((resolve, reject) => {
      const tx = this.db.transaction(store, 'readwrite');
      tx.objectStore(store).delete(id);
      tx.oncomplete = resolve;
      tx.onerror = () => reject(tx.error);
    });
  },

  // Encrypted API
  async put(store, id, data) {
    const { iv, ct } = await CryptoUtil.encrypt(this.encryptionKey, data);
    await this._putRaw(store, { id, iv, ct });
  },

  async get(store, id) {
    const rec = await this._getRaw(store, id);
    if (!rec) return null;
    return CryptoUtil.decrypt(this.encryptionKey, rec.iv, rec.ct);
  },

  async getAll(store) {
    const recs = await this._getAllRaw(store);
    const out = [];
    for (const r of recs) {
      try { out.push(await CryptoUtil.decrypt(this.encryptionKey, r.iv, r.ct)); }
      catch (e) { console.warn('No se pudo descifrar registro', e); }
    }
    return out;
  },

  async del(store, id) { await this._deleteRaw(store, id); }
};