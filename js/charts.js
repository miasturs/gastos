window.ChartsService = {
  chart: null,

  async render() {
    const gastos = await GastosService.list();
    const categorias = await CategoriasService.list();
    const totals = {};
    gastos.forEach(g => {
      totals[g.categoriaId] = (totals[g.categoriaId] || 0) + g.monto;
    });

    const entries = Object.entries(totals);
    const canvas = document.getElementById('chart-categorias');
    const legend = document.getElementById('chart-legend');

    if (this.chart) { this.chart.destroy(); this.chart = null; }

    if (entries.length === 0) {
      legend.innerHTML = '<div class="empty"><div class="empty-icon">📊</div><p>Registra gastos para ver gráficos</p></div>';
      const ctx = canvas.getContext('2d');
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      return;
    }

    const labels = [];
    const data = [];
    const colors = [];

    entries.forEach(([catId, total]) => {
      const cat = categorias.find(c => c.id === catId);
      labels.push(`${cat?.icono || ''} ${cat?.nombre || 'Sin categoría'}`);
      data.push(total);
      colors.push(cat?.color || '#78909C');
    });

    this.chart = new Chart(canvas, {
      type: 'doughnut',
      data: {
        labels,
        datasets: [{ data, backgroundColor: colors, borderWidth: 2, borderColor: '#fff' }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: { legend: { display: false } }
      }
    });

    legend.innerHTML = '';
    entries.forEach(([catId, total]) => {
      const cat = categorias.find(c => c.id === catId);
      const div = document.createElement('div');
      div.className = 'legend-item';
      div.innerHTML = `
        <div class="legend-color" style="background:${cat?.color || '#78909C'}"></div>
        <div class="legend-name">${cat?.icono || ''} ${cat?.nombre || 'Sin categoría'}</div>
        <div class="legend-value">${App.formatMoney(total)}</div>
      `;
      legend.appendChild(div);
    });
  }
};