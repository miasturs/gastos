window.CryptoUtil = {
  async deriveKey(password, saltBase64) {
    const enc = new TextEncoder();
    const salt = saltBase64
      ? Uint8Array.from(atob(saltBase64), c => c.charCodeAt(0))
      : crypto.getRandomValues(new Uint8Array(16));

    const baseKey = await crypto.subtle.importKey(
      'raw', enc.encode(password), 'PBKDF2', false, ['deriveKey']
    );
    const key = await crypto.subtle.deriveKey(
      { name: 'PBKDF2', salt, iterations: 150000, hash: 'SHA-256' },
      baseKey,
      { name: 'AES-GCM', length: 256 },
      false,
      ['encrypt', 'decrypt']
    );
    return {
      key,
      saltBase64: btoa(String.fromCharCode(...salt))
    };
  },

  async encrypt(key, data) {
    const iv = crypto.getRandomValues(new Uint8Array(12));
    const enc = new TextEncoder();
    const ct = await crypto.subtle.encrypt(
      { name: 'AES-GCM', iv }, key, enc.encode(JSON.stringify(data))
    );
    return { iv: Array.from(iv), ct: Array.from(new Uint8Array(ct)) };
  },

  async decrypt(key, ivArr, ctArr) {
    const iv = new Uint8Array(ivArr);
    const ct = new Uint8Array(ctArr);
    const plain = await crypto.subtle.decrypt({ name: 'AES-GCM', iv }, key, ct);
    return JSON.parse(new TextDecoder().decode(plain));
  },

  async hashPassword(password, saltBase64) {
    const enc = new TextEncoder();
    const salt = Uint8Array.from(atob(saltBase64), c => c.charCodeAt(0));
    const baseKey = await crypto.subtle.importKey(
      'raw', enc.encode(password), 'PBKDF2', false, ['deriveBits']
    );
    const bits = await crypto.subtle.deriveBits(
      { name: 'PBKDF2', salt, iterations: 150000, hash: 'SHA-256' },
      baseKey, 256
    );
    return btoa(String.fromCharCode(...new Uint8Array(bits)));
  },

  randomSalt() {
    const s = crypto.getRandomValues(new Uint8Array(16));
    return btoa(String.fromCharCode(...s));
  }
};