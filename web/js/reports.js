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

  async function fetchLiveReportState() {
    const client = window.ChmsuApi.getSupabaseClient();
    const [resQ, borQ, rsvQ, digQ, rptQ] = await Promise.all([
      client.from('resources').select('*'),
      client.from('borrowings').select('id, transaction_code, status, due_at, resource_id, profiles(full_name), resources(title)'),
      client.from('reservations').select('id, reference_code, status, pickup_deadline, profiles(full_name), resources(title)'),
      client.from('digital_access_logs').select('id, resource_id'),
      client.from('generated_reports').select('*, profiles(full_name)').order('created_at', { ascending: false }).limit(15),
    ]);
    if (resQ.error) throw resQ.error;

    return {
      resources: (resQ.data || []).map(r => ({
        ...r,
        print_uses: (borQ.data || []).filter(b => b.resource_id === r.id).length,
        digital_uses: (digQ.data || []).filter(d => d.resource_id === r.id).length,
      })),
      borrowings: (borQ.data || []).map(b => ({
        transaction_code: b.transaction_code,
        student_name: b.profiles?.full_name || 'Student',
        resource_title: b.resources?.title || 'Resource',
        status: b.status,
        due_at: b.due_at ? new Date(b.due_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }) : '—',
      })),
      reservations: (rsvQ.data || []).map(r => ({
        reference_code: r.reference_code,
        student_name: r.profiles?.full_name || 'Student',
        resource_title: r.resources?.title || 'Resource',
        status: r.status,
        pickup_label: r.pickup_deadline ? new Date(r.pickup_deadline).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' }) : '—',
      })),
      reports: (rptQ.data || []).map(rp => ({
        report_code: rp.report_code,
        report_type: rp.report_type.replace('_', ' '),
        generated_by: rp.profiles?.full_name || 'Librarian',
        period_label: rp.period_label,
        created_label: new Date(rp.created_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' }),
        format: rp.format,
      })),
    };
  }

  async function buildReport() {
    let state;
    if (window.ChmsuApi.isLiveSession()) {
      try {
        state = await fetchLiveReportState();
      } catch (err) {
        window.ChmsuApi.showToast('Supabase error: ' + err.message);
        state = window.ChmsuApi.getDemoState();
      }
    } else {
      state = window.ChmsuApi.getDemoState();
    }

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

  async function logReportExport(exportFormat) {
    const type = document.querySelector('input[name="report_type"]:checked').value;
    const period = document.getElementById('rpt-period').value;
    const formatFilter = document.getElementById('rpt-format').value;
    const code = `RPT-261019-${Math.floor(100 + Math.random() * 800)}`;

    if (window.ChmsuApi.isLiveSession()) {
      const client = window.ChmsuApi.getSupabaseClient();
      await client.from('generated_reports').insert({
        report_code: code,
        report_type: type,
        period_label: period,
        campus: 'Talisay',
        resource_format: formatFilter,
        generated_by: user.id,
        format: exportFormat,
      });
      await buildReport();
      return;
    }

    const state = window.ChmsuApi.getDemoState();
    state.reports.unshift({
      report_code: code,
      report_type: document.getElementById('preview-title').textContent.replace(' report', ''),
      generated_by: user.full_name || 'Ana Dela Cruz',
      period_label: period,
      created_label: 'Just now',
      format: exportFormat,
    });
    window.ChmsuApi.saveDemoState(state);
    renderHistory(state.reports);
  }

  async function downloadCsv() {
    const lines = [currentHeaders.join(','), ...currentRows.map(r => r.map(v => `"${String(v).replace(/"/g, '""')}"`).join(','))];
    const blob = new Blob([lines.join('\n')], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `chmsu-library-report-${Date.now()}.csv`;
    a.click();
    URL.revokeObjectURL(url);

    await logReportExport('CSV');
    window.ChmsuApi.showToast('CSV report downloaded.');
  }

  window._downloadCurrentCsv = downloadCsv;

  document.getElementById('generate-preview-btn').addEventListener('click', async () => {
    await buildReport();
    window.ChmsuApi.showToast('Report preview updated.');
  });
  document.getElementById('export-csv-btn').addEventListener('click', downloadCsv);
  document.getElementById('export-pdf-btn').addEventListener('click', async () => {
    await logReportExport('PDF');
    window.print();
  });

  buildReport();
})();
