(function () {
  const user = window.ChmsuApi.requireSession();
  if (!user) return;

  document.getElementById('librarian-name').textContent = user.full_name || 'Ana Dela Cruz';
  const initials = (user.full_name || 'AD').split(' ').map(p => p[0]).join('').slice(0, 2).toUpperCase();
  document.getElementById('librarian-initials').textContent = initials;

  const periodEl = document.getElementById('filter-period');
  const formatEl = document.getElementById('filter-format');

  async function fetchLiveAnalyticsData() {
    const client = window.ChmsuApi.getSupabaseClient();
    const [resQ, rsvQ, borQ, digQ] = await Promise.all([
      client.from('resources').select('*'),
      client.from('reservations').select('id, status, created_at, resource_id'),
      client.from('borrowings').select('id, status, borrowed_at, resource_id'),
      client.from('digital_access_logs').select('id, accessed_at, resource_id'),
    ]);

    if (resQ.error) throw resQ.error;

    const resources = (resQ.data || []).map(r => {
      const printUses = (borQ.data || []).filter(b => b.resource_id === r.id).length;
      const digitalUses = (digQ.data || []).filter(d => d.resource_id === r.id).length;
      return { ...r, print_uses: printUses, digital_uses: digitalUses };
    });

    const buckets = {};
    const addToBucket = (iso, kind) => {
      const d = new Date(iso);
      const label = d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
      if (!buckets[label]) buckets[label] = { label, print: 0, digital: 0 };
      buckets[label][kind] += 1;
    };
    (borQ.data || []).forEach(b => addToBucket(b.borrowed_at, 'print'));
    (digQ.data || []).forEach(d => addToBucket(d.accessed_at, 'digital'));
    const timeseries = Object.values(buckets).slice(-4);
    if (timeseries.length === 0) {
      timeseries.push({ label: 'Today', print: 0, digital: 0 });
    }

    return {
      resources,
      reservations: rsvQ.data || [],
      borrowings: borQ.data || [],
      timeseries,
    };
  }

  async function loadAnalytics() {
    let state;
    if (window.ChmsuApi.isLiveSession()) {
      try {
        state = await fetchLiveAnalyticsData();
      } catch (err) {
        window.ChmsuApi.showToast('Supabase fetch error: ' + err.message);
        state = window.ChmsuApi.getDemoState();
      }
    } else {
      state = window.ChmsuApi.getDemoState();
    }

    const formatFilter = formatEl.value;
    const periodScale = window.ChmsuApi.isLiveSession()
      ? 1
      : (periodEl.value === '7d' ? 0.45 : periodEl.value === '30d' ? 1.25 : 1);

    const resources = state.resources.filter(r => formatFilter === 'all' || r.format === formatFilter);
    const totalPrint = Math.round(resources.reduce((s, r) => s + r.print_uses, 0) * periodScale);
    const totalDigital = Math.round(resources.reduce((s, r) => s + r.digital_uses, 0) * periodScale);
    const totalUses = totalPrint + totalDigital;

    const rsvCounts = {
      pending: state.reservations.filter(r => r.status === 'pending').length,
      approved: state.reservations.filter(r => r.status === 'approved').length,
      ready: state.reservations.filter(r => r.status === 'ready').length,
      completed: state.reservations.filter(r => r.status === 'completed').length,
      cancelled: state.reservations.filter(r => r.status === 'cancelled').length,
    };
    const rsvTotal = Object.values(rsvCounts).reduce((a, b) => a + b, 0);

    document.getElementById('kpi-total-uses').textContent = totalUses;
    document.getElementById('kpi-print-loans').textContent = totalPrint;
    document.getElementById('kpi-reservations').textContent = rsvTotal;
    document.getElementById('kpi-digital').textContent = totalDigital;

    renderChart(state.timeseries, periodScale, formatFilter);
    renderSnapshot(rsvCounts, rsvTotal, state.borrowings);
    renderTopResources(resources, periodScale);
    renderInsights(totalPrint, totalUses, resources, state.borrowings, periodScale);
  }

  function renderChart(series, scale, formatFilter) {
    const container = document.getElementById('usage-chart');
    const points = series.map(pt => ({
      label: pt.label,
      print: formatFilter === 'ebook' ? 0 : Math.round(pt.print * scale),
      digital: formatFilter === 'print' ? 0 : Math.round(pt.digital * scale),
    }));

    const maxRaw = Math.max(10, ...points.map(pt => Math.max(pt.print, pt.digital)));
    const maxVal = Math.ceil(maxRaw / 10) * 10;
    const width = 620;
    const height = 225;
    const chartLeft = 46;
    const chartRight = width - 26;
    const chartTop = 24;
    const chartBottom = 175;
    const chartH = chartBottom - chartTop;
    const chartW = chartRight - chartLeft;

    const getX = (idx) => {
      if (points.length === 1) return chartLeft + chartW / 2;
      return chartLeft + (idx / (points.length - 1)) * chartW;
    };
    const getY = (val) => chartBottom - Math.min(chartH, (val / maxVal) * chartH);

    let svg = `<svg viewBox="0 0 ${width} ${height}" style="width:100%;height:100%;overflow:visible;">`;
    svg += `
      <defs>
        <linearGradient id="gradPrint" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="#1B4332" stop-opacity="0.22"/>
          <stop offset="100%" stop-color="#1B4332" stop-opacity="0.01"/>
        </linearGradient>
        <linearGradient id="gradDigital" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="#B08434" stop-opacity="0.24"/>
          <stop offset="100%" stop-color="#B08434" stop-opacity="0.01"/>
        </linearGradient>
      </defs>
    `;

    [0, 0.25, 0.5, 0.75, 1].forEach(ratio => {
      const tick = Math.round(maxVal * ratio);
      const y = chartBottom - ratio * chartH;
      svg += `<line x1="${chartLeft}" y1="${y}" x2="${chartRight}" y2="${y}" stroke="#ECE9DF" stroke-dasharray="3,3" />`;
      svg += `<text x="${chartLeft - 10}" y="${y + 4}" text-anchor="end" font-size="11" fill="#7C847E">${tick}</text>`;
    });

    const drawSeries = (key, color, gradId, labelOffset) => {
      const coords = points.map((pt, idx) => ({
        x: getX(idx),
        y: getY(pt[key]),
        val: pt[key],
      }));

      if (coords.length > 1) {
        const linePath = coords.map((c, i) => `${i === 0 ? 'M' : 'L'} ${c.x} ${c.y}`).join(' ');
        const areaPath = `${linePath} L ${coords[coords.length - 1].x} ${chartBottom} L ${coords[0].x} ${chartBottom} Z`;
        svg += `<path d="${areaPath}" fill="url(#${gradId})" />`;
        svg += `<path d="${linePath}" fill="none" stroke="${color}" stroke-width="2.75" stroke-linecap="round" stroke-linejoin="round" />`;
      } else if (coords.length === 1) {
        const c = coords[0];
        svg += `<line x1="${chartLeft}" y1="${c.y}" x2="${chartRight}" y2="${c.y}" stroke="${color}" stroke-width="2" stroke-dasharray="5,4" stroke-opacity="0.45" />`;
      }

      coords.forEach(c => {
        svg += `<circle cx="${c.x}" cy="${c.y}" r="5.5" fill="#FFFFFF" stroke="${color}" stroke-width="2.75"><title>${key === 'print' ? 'Print' : 'Digital'}: ${c.val}</title></circle>`;
        svg += `<text x="${c.x}" y="${c.y + labelOffset}" text-anchor="middle" font-size="11" font-weight="700" fill="${color}">${c.val}</text>`;
      });
    };

    if (formatFilter !== 'ebook') drawSeries('print', '#1B4332', 'gradPrint', -10);
    if (formatFilter !== 'print') drawSeries('digital', '#B08434', 'gradDigital', -10);

    points.forEach((pt, idx) => {
      const x = getX(idx);
      svg += `<text x="${x}" y="${chartBottom + 18}" text-anchor="middle" font-size="11" fill="#5D6660">${pt.label}</text>`;
      svg += `<text x="${x}" y="${chartBottom + 34}" text-anchor="middle" font-size="11" font-weight="600" fill="#1D2420">${pt.print + pt.digital} uses</text>`;
    });

    svg += `</svg>`;
    container.innerHTML = svg;
  }

  function renderSnapshot(counts, total, borrowings) {
    document.getElementById('snap-rsv-total').textContent = total;
    const colors = {
      pending: '#B08434',
      approved: '#345F7D',
      ready: '#1B4332',
      completed: '#7BA18C',
      cancelled: '#D3CFC2',
    };
    const bar = document.getElementById('rsv-bar');
    bar.innerHTML = Object.entries(counts)
      .filter(([, v]) => v > 0)
      .map(([k, v]) => `<div style="width:${(v / Math.max(1, total)) * 100}%;background:${colors[k]};"></div>`)
      .join('');

    document.getElementById('rsv-breakdown').innerHTML = `
      <div>Pending: <strong>${counts.pending}</strong></div>
      <div>Completed: <strong>${counts.completed}</strong></div>
      <div>Approved: <strong>${counts.approved}</strong></div>
      <div>Cancelled: <strong>${counts.cancelled}</strong></div>
      <div>Ready: <strong>${counts.ready}</strong></div>
    `;

    const returned = borrowings.filter(b => b.status === 'returned').length;
    const current = borrowings.filter(b => b.status === 'borrowed').length;
    const overdue = borrowings.filter(b => b.status === 'overdue').length;
    document.getElementById('snap-loan-total').textContent = borrowings.length;
    document.getElementById('snap-returned').textContent = returned;
    document.getElementById('snap-current').textContent = current;
    document.getElementById('snap-overdue').textContent = overdue;
  }

  function renderTopResources(resources, scale) {
    const sorted = [...resources].sort((a, b) => (b.print_uses + b.digital_uses) - (a.print_uses + a.digital_uses));
    document.getElementById('top-resources-body').innerHTML = sorted.map(r => {
      const p = Math.round(r.print_uses * scale);
      const d = Math.round(r.digital_uses * scale);
      return `
        <tr>
          <td>
            <div style="font-weight:600;">${r.title}</div>
            <div style="font-size:11px;color:var(--text-muted);">${r.subject}</div>
          </td>
          <td style="text-align:right;">${p}</td>
          <td style="text-align:right;">${d}</td>
          <td style="text-align:right;font-weight:700;color:var(--green-800);">${p + d}</td>
        </tr>
      `;
    }).join('');
  }

  function renderInsights(totalPrint, totalUses, resources, borrowings, scale) {
    const pct = totalUses > 0 ? ((totalPrint / totalUses) * 100).toFixed(1) : '0.0';
    document.getElementById('insight-pct').textContent = `${pct}%`;

    const top = [...resources].sort((a, b) => (b.print_uses + b.digital_uses) - (a.print_uses + a.digital_uses))[0];
    if (top) {
      const topUses = Math.round((top.print_uses + top.digital_uses) * scale);
      document.getElementById('insight-top-uses').textContent = `${topUses} uses`;
      document.getElementById('insight-top-desc').textContent = `make ${top.title} the most-used title.`;
    }

    const overdueCount = borrowings.filter(b => b.status === 'overdue').length;
    document.getElementById('insight-overdue').textContent = `${overdueCount} overdue`;
  }

  periodEl.addEventListener('change', loadAnalytics);
  formatEl.addEventListener('change', loadAnalytics);
  loadAnalytics();
})();
