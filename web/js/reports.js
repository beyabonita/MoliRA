(function () {
  const user = window.ChmsuApi.requireSession();
  if (!user) return;

  document.getElementById('librarian-name').textContent = user.full_name || 'Ana Dela Cruz';
  const initials = (user.full_name || 'AD').split(' ').map(p => p[0]).join('').slice(0, 2).toUpperCase();
  document.getElementById('librarian-initials').textContent = initials;

  let currentRows = [];
  let currentHeaders = [];

  document.querySelectorAll('.radio-card').forEach(card => {
    card.addEventListener('click', () => {
      document.querySelectorAll('.radio-card').forEach(c => c.classList.remove('selected'));
      card.classList.add('selected');
      card.querySelector('input').checked = true;
    });
  });

  function buildReport() {
    const state = window.ChmsuApi.getDemoState();
    const type = document.querySelector('input[name="report_type"]:checked').value;
    const period = document.getElementById('rpt-period').value;
    const campus = document.getElementById('rpt-campus').value;
    const format = document.getElementById('rpt-format').value;

    const formatLabel = format === 'all' ? 'All formats' : format === 'print' ? 'Print books' : 'E-resources';
    document.getElementById('preview-subtitle').textContent = `${campus} library · ${period} · ${formatLabel}`;

    const kpisEl = document.getElementById('preview-kpis');
    const theadEl = document.getElementById('preview-thead');
    const tbodyEl = document.getElementById('preview-tbody');

    if (type === 'resource_usage') {
      document.getElementById('preview-title').textContent = 'Resource usage report';
      const list = state.resources.filter(r => format === 'all' || r.format === format);
      const totalPrint = list.reduce((s, r) => s + r.print_uses, 0);
      const totalDigital = list.reduce((s, r) => s + r.digital_uses, 0);
      const total = totalPrint + totalDigital;

      kpisEl.innerHTML = `
        <div><div class="preview-kpi-val">${total}</div><div class="preview-kpi-label">Total resource uses</div></div>
        <div><div class="preview-kpi-val">${totalPrint}</div><div class="preview-kpi-label">Print borrowings</div></div>
        <div><div class="preview-kpi-val">${totalDigital}</div><div class="preview-kpi-label">Digital accesses</div></div>
      `;

      currentHeaders = ['Resource Title', 'Print', 'Digital', 'Total'];
      currentRows = list.map(r => [r.title, r.print_uses, r.digital_uses, r.print_uses + r.digital_uses]);

      theadEl.innerHTML = `<tr><th>Resource Title</th><th style="text-align:right;">Print</th><th style="text-align:right;">Digital</th><th style="text-align:right;">Total</th></tr>`;
      tbodyEl.innerHTML = currentRows.map(row => `
        <tr><td>${row[0]}</td><td style="text-align:right;">${row[1]}</td><td style="text-align:right;">${row[2]}</td><td style="text-align:right;font-weight:700;">${row[3]}</td></tr>
      `).join('') + `
        <tr style="background:var(--bg-green-soft);font-weight:700;">
          <td>Total</td><td style="text-align:right;">${totalPrint}</td><td style="text-align:right;">${totalDigital}</td><td style="text-align:right;">${total}</td>
        </tr>
      `;
    } else if (type === 'borrowing_summary') {
      document.getElementById('preview-title').textContent = 'Borrowing summary report';
      const list = state.borrowings;
      const borrowed = list.filter(b => b.status === 'borrowed').length;
      const overdue = list.filter(b => b.status === 'overdue').length;
      const returned = list.filter(b => b.status === 'returned').length;

      kpisEl.innerHTML = `
        <div><div class="preview-kpi-val">${borrowed}</div><div class="preview-kpi-label">Active loans</div></div>
        <div><div class="preview-kpi-val">${overdue}</div><div class="preview-kpi-label">Overdue</div></div>
        <div><div class="preview-kpi-val">${returned}</div><div class="preview-kpi-label">Returned</div></div>
      `;

      currentHeaders = ['Transaction', 'Student', 'Resource', 'Status', 'Due Date'];
      currentRows = list.map(b => [b.transaction_code, b.student_name, b.resource_title, b.status, b.due_at]);

      theadEl.innerHTML = `<tr><th>Transaction</th><th>Student</th><th>Resource</th><th>Status</th><th>Due Date</th></tr>`;
      tbodyEl.innerHTML = currentRows.map(row => `
        <tr><td>${row[0]}</td><td>${row[1]}</td><td>${row[2]}</td><td>${row[3]}</td><td>${row[4]}</td></tr>
      `).join('');
    } else {
      document.getElementById('preview-title').textContent = 'Reservation status report';
      const list = state.reservations;
      const pending = list.filter(r => r.status === 'pending').length;
      const ready = list.filter(r => r.status === 'ready').length;
      const completed = list.filter(r => r.status === 'completed').length;

      kpisEl.innerHTML = `
        <div><div class="preview-kpi-val">${pending}</div><div class="preview-kpi-label">Pending</div></div>
        <div><div class="preview-kpi-val">${ready}</div><div class="preview-kpi-label">Ready for pickup</div></div>
        <div><div class="preview-kpi-val">${completed}</div><div class="preview-kpi-label">Completed</div></div>
      `;

      currentHeaders = ['Reference', 'Student', 'Resource', 'Status', 'Pickup'];
      currentRows = list.map(r => [r.reference_code, r.student_name, r.resource_title, r.status, r.pickup_label]);

      theadEl.innerHTML = `<tr><th>Reference</th><th>Student</th><th>Resource</th><th>Status</th><th>Pickup</th></tr>`;
      tbodyEl.innerHTML = currentRows.map(row => `
        <tr><td>${row[0]}</td><td>${row[1]}</td><td>${row[2]}</td><td>${row[3]}</td><td>${row[4]}</td></tr>
      `).join('');
    }

    renderHistory(state.reports);
  }

  function renderHistory(reports) {
    document.getElementById('history-tbody').innerHTML = reports.map(r => `
      <tr>
        <td>
          <div style="font-weight:600;">${r.report_type}</div>
          <div style="font-size:11px;color:var(--text-muted);">${r.report_code} · ${r.generated_by}</div>
        </td>
        <td>${r.period_label}</td>
        <td>${r.created_label}</td>
        <td>${r.format}</td>
        <td style="text-align:right;">
          <button class="btn btn-outline btn-sm" onclick="window._downloadCurrentCsv()">Download ↓</button>
        </td>
      </tr>
    `).join('');
  }

  function downloadCsv() {
    const lines = [currentHeaders.join(','), ...currentRows.map(r => r.map(v => `"${String(v).replace(/"/g, '""')}"`).join(','))];
    const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `chmsu-library-report-${Date.now()}.csv`;
    a.click();
    URL.revokeObjectURL(url);

    const state = window.ChmsuApi.getDemoState();
    state.reports.unshift({
      report_code: `RPT-261019-${Math.floor(100 + Math.random() * 800)}`,
      report_type: document.getElementById('preview-title').textContent.replace(' report', ''),
      generated_by: user.full_name || 'Ana Dela Cruz',
      period_label: document.getElementById('rpt-period').value,
      created_label: 'Just now',
      format: 'CSV',
    });
    window.ChmsuApi.saveDemoState(state);
    renderHistory(state.reports);
    window.ChmsuApi.showToast('CSV report downloaded.');
  }

  window._downloadCurrentCsv = downloadCsv;

  document.getElementById('generate-preview-btn').addEventListener('click', () => {
    buildReport();
    window.ChmsuApi.showToast('Report preview updated.');
  });
  document.getElementById('export-csv-btn').addEventListener('click', downloadCsv);
  document.getElementById('export-pdf-btn').addEventListener('click', () => {
    window.print();
  });

  buildReport();
})();
