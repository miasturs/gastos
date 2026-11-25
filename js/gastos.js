window.GastosService = {
  async list() {
    const gs = await DB.getAll('gastos');
    return gs.sort((a, b) => new Date(b.fecha) - new Date(a.fecha));
  },
  async create(g) { await DB.put('gastos', g.id, g); },
  async update(g) { await DB.put('gastos', g.id, g); },
  async delete(id) { await DB.del('gastos', id); },

  async openCameraModal() {
    return new Promise(async (resolve) => {
      const modal = document.getElementById('camera-modal');
      const video = document.getElementById('camera-video');
      const btnCapture = document.getElementById('camera-capture');
      const btnCancel = document.getElementById('camera-cancel');
      let stream = null;

      try {
        stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: 'environment' }
        });
        video.srcObject = stream;
        modal.classList.remove('hidden');
      } catch (e) {
        App.toast('No se pudo acceder a la cámara: ' + e.message, 'error');
        resolve(null);
        return;
      }

      const cleanup = () => {
        if (stream) stream.getTracks().forEach(t => t.stop());
        modal.classList.add('hidden');
      };

      btnCancel.onclick = () => { cleanup(); resolve(null); };

      btnCapture.onclick = () => {
        const canvas = document.createElement('canvas');
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        canvas.getContext('2d').drawImage(video, 0, 0);
        const dataUrl = canvas.toDataURL('image/jpeg', 0.7);
        cleanup();
        resolve(dataUrl);
      };
    });
  }
};