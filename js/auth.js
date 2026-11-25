window.AuthService = {
  currentUser: null,

  async isRegistered() {
    const rec = await DB._getRaw('auth', 'current');
    return !!rec;
  },

  async register(email, password) {
    if (await this.isRegistered()) throw new Error('Ya existe una cuenta en este dispositivo');
    const salt = CryptoUtil.randomSalt();
    const hash = await CryptoUtil.hashPassword(password, salt);
    const { key } = await CryptoUtil.deriveKey(password, salt);

    const authData = { id: 'current', email, salt, hash };
    await DB._putRaw('auth', authData);
    DB.setKey(key);
    this.currentUser = { email };
    sessionStorage.setItem('authed', '1');
    await this.seedDefaults();
    return true;
  },

  async login(email, password) {
    const rec = await DB._getRaw('auth', 'current');
    if (!rec) throw new Error('No hay cuenta registrada');
    if (rec.email.toLowerCase() !== email.toLowerCase()) throw new Error('Email incorrecto');

    const hash = await CryptoUtil.hashPassword(password, rec.salt);
    if (hash !== rec.hash) throw new Error('Contraseña incorrecta');

    const { key } = await CryptoUtil.deriveKey(password, rec.salt);
    DB.setKey(key);
    this.currentUser = { email: rec.email };
    sessionStorage.setItem('authed', '1');
    await this.seedDefaults();
    return true;
  },

  async logout() {
    DB.setKey(null);
    this.currentUser = null;
    sessionStorage.removeItem('authed');
  },

  async seedDefaults() {
    const cats = await DB.getAll('categorias');
    if (cats.length > 0) return;
    const defaults = [
      { id: 'cat-comida', nombre: 'Comida', icono: '🍔', color: '#EF5350' },
      { id: 'cat-transporte', nombre: 'Transporte', icono: '🚗', color: '#42A5F5' },
      { id: 'cat-hogar', nombre: 'Hogar', icono: '🏠', color: '#66BB6A' },
      { id: 'cat-ocio', nombre: 'Ocio', icono: '🎬', color: '#AB47BC' },
      { id: 'cat-salud', nombre: 'Salud', icono: '💊', color: '#26A69A' },
      { id: 'cat-otros', nombre: 'Otros', icono: '📦', color: '#78909C' }
    ];
    for (const c of defaults) await DB.put('categorias', c.id, c);
  },

  async registerBiometric() {
    if (!window.PublicKeyCredential) throw new Error('Biometría no soportada en este navegador');
    const available = await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
    if (!available) throw new Error('No hay autenticador biométrico disponible');

    const challenge = crypto.getRandomValues(new Uint8Array(32));
    const userId = crypto.getRandomValues(new Uint8Array(16));

    const credential = await navigator.credentials.create({
      publicKey: {
        challenge,
        rp: { name: 'Gestor de Gastos' },
        user: {
          id: userId,
          name: this.currentUser.email,
          displayName: this.currentUser.email
        },
        pubKeyCredParams: [{ alg: -7, type: 'public-key' }, { alg: -257, type: 'public-key' }],
        authenticatorSelection: { authenticatorAttachment: 'platform', userVerification: 'required' },
        timeout: 60000,
        attestation: 'none'
      }
    });

    const credId = btoa(String.fromCharCode(...new Uint8Array(credential.rawId)));
    localStorage.setItem('biometric_cred_id', credId);
    return true;
  },

  hasBiometric() {
    return !!localStorage.getItem('biometric_cred_id');
  },

  async authenticateBiometric() {
    const credId = localStorage.getItem('biometric_cred_id');
    if (!credId) throw new Error('Biometría no registrada');
    const challenge = crypto.getRandomValues(new Uint8Array(32));
    const credIdBytes = Uint8Array.from(atob(credId), c => c.charCodeAt(0));

    const assertion = await navigator.credentials.get({
      publicKey: {
        challenge,
        allowCredentials: [{ id: credIdBytes, type: 'public-key' }],
        userVerification: 'required',
        timeout: 60000
      }
    });
    return !!assertion;
  }
};