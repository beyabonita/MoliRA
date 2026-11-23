(function () {
  const user = window.ChmsuApi.requireSession();
  if (!user) return;

  document.getElementById('librarian-name').textContent = user.full_name || 'Ana Dela Cruz';
  const initials = (user.full_name || 'AD').split(' ').map(p => p[0]).join('').slice(0, 2).toUpperCase();
  document.getElementById('librarian-initials').textContent = initials;

  let currentTab = 'all';
  const searchEl = document.getElementById('search-input');

  const statusPill = {
    pending: '<span class="pill pill-amber">Pending</span>',
    approved: '<span class="pill pill-blue">Approved</span>',
    ready: '<span class="pill pill-green">Ready for pickup</span>',
    completed: '<span class="pill pill-green">Completed</span>',
    cancelled: '<span class="pill pill-gray">Cancelled</span>',
    borrowed: '<span class="pill pill-amber">Borrowed</span>',
    overdue: '<span class="pill pill-red">Overdue</span>',
    returned: '<span class="pill pill-green">Returned</span>',
  };

  function render() {
    const state = window.ChmsuApi.getDemoState();
    const q = searchEl.value.trim().toLowerCase();

    const activeCount = state.reservations.filter(r => ['pending', 'approved', 'ready'].includes(r.status)).length;
    document.getElementById('active-requests-pill').textContent = `${activeCount} active requests`;

    const counts = {
      all: state.reservations.length,
      pending: state.reservations.filter(r => r.status === 'pending').length,
      approved: state.reservations.filter(r => r.status === 'approved').length,
      ready: state.reservations.filter(r => r.status === 'ready').length,
      completed: state.reservations.filter(r => r.status === 'completed').length,
      cancelled: state.reservations.filter(r => r.status === 'cancelled').length,
      loans: state.borrowings.length,
    };

    const tabs = [
      { id: 'all', label: `All (${counts.all})` },
      { id: 'pending', label: `Pending (${counts.pending})` },
      { id: 'approved', label: `Approved (${counts.approved})` },
      { id: 'ready', label: `Ready (${counts.ready})` },
      { id: 'completed', label: `Completed (${counts.completed})` },
      { id: 'cancelled', label: `Cancelled (${counts.cancelled})` },
      { id: 'loans', label: `Active Loans & Returns (${counts.loans})` },
    ];

    document.getElementById('status-tabs').innerHTML = tabs
      .map(t => `<button class="tab-btn ${currentTab === t.id ? 'active' : ''}" data-tab="${t.id}">${t.label}</button>`)
      .join('');

    document.querySelectorAll('#status-tabs .tab-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        currentTab = btn.dataset.tab;
        render();
      });
    });

    if (currentTab === 'loans') {
      renderLoansTable(state.borrowings, q);
    } else {
      renderReservationsTable(state.reservations, q);
    }
  }

  function renderReservationsTable(reservations, q) {
    document.getElementById('table-head').innerHTML = `
      <tr>
        <th>Student / Reference</th>
        <th>Resource</th>
        <th>Status</th>
        <th>Pickup / Last Update</th>
        <th style="text-align:right;">Next Action</th>
      </tr>
    `;

    const filtered = reservations.filter(r => {
      const matchTab = currentTab === 'all' || r.status === currentTab;
      const matchQuery = !q || r.student_name.toLowerCase().includes(q) || r.resource_title.toLowerCase().includes(q) || r.reference_code.toLowerCase().includes(q) || r.student_id_num.toLowerCase().includes(q);
      return matchTab && matchQuery;
    });

    const tbody = document.getElementById('table-body');
    if (filtered.length === 0) {
      tbody.innerHTML = `<tr><td colspan="5" style="text-align:center;color:var(--text-muted);padding:28px;">No matching reservations found.</td></tr>`;
      return;
    }

    tbody.innerHTML = filtered.map(r => {
      let actions = '';
      if (r.status === 'pending') {
        actions = `
          <button class="btn btn-primary btn-sm" data-action="approve" data-id="${r.id}">Approve</button>
          <button class="btn-danger-link" data-action="cancel" data-id="${r.id}">Cancel</button>
        `;
      } else if (r.status === 'approved') {
        actions = `
          <button class="btn btn-primary btn-sm" data-action="ready" data-id="${r.id}">Mark ready</button>
          <button class="btn-danger-link" data-action="cancel" data-id="${r.id}">Cancel</button>
        `;
      } else if (r.status === 'ready') {
        actions = `
          <button class="btn btn-primary btn-sm" data-action="checkout" data-id="${r.id}">Complete checkout</button>
          <button class="btn-danger-link" data-action="cancel" data-id="${r.id}">Cancel</button>
        `;
      } else {
        actions = `<span style="font-size:12px;font-weight:600;color:var(--green-800);">Closed ✓</span>`;
      }

      return `
        <tr>
          <td>
            <div style="font-weight:600;">${r.student_name}</div>
            <div style="font-size:11px;color:var(--text-muted);">${r.student_id_num}</div>
            <div style="font-size:11px;font-weight:600;color:var(--green-700);">${r.reference_code}</div>
          </td>
          <td>
            <div style="font-weight:600;">${r.resource_title}</div>
            <div style="font-size:11px;color:var(--text-muted);">${r.resource_meta}</div>
          </td>
          <td>${statusPill[r.status] || r.status}</td>
          <td>
            <div style="font-weight:600;color:${r.status === 'ready' ? 'var(--green-800)' : 'var(--text-primary)'};">${r.pickup_label}</div>
            <div style="font-size:11px;color:var(--text-muted);">${r.updated_label}</div>
          </td>
          <td style="text-align:right;white-space:nowrap;">${actions}</td>
        </tr>
      `;
    }).join('');

    tbody.querySelectorAll('[data-action]').forEach(btn => {
      btn.addEventListener('click', () => handleAction(btn.dataset.action, btn.dataset.id));
    });
  }

  function renderLoansTable(borrowings, q) {
    document.getElementById('table-head').innerHTML = `
      <tr>
        <th>Student / Transaction</th>
        <th>Resource</th>
        <th>Status</th>
        <th>Borrowed / Due Date</th>
        <th style="text-align:right;">Action</th>
      </tr>
    `;

    const filtered = borrowings.filter(b =>
      !q || b.student_name.toLowerCase().includes(q) || b.resource_title.toLowerCase().includes(q) || b.transaction_code.toLowerCase().includes(q)
    );

    const tbody = document.getElementById('table-body');
    tbody.innerHTML = filtered.map(b => `
      <tr>
        <td>
          <div style="font-weight:600;">${b.student_name}</div>
          <div style="font-size:11px;color:var(--text-muted);">${b.student_id_num}</div>
          <div style="font-size:11px;font-weight:600;color:var(--green-700);">${b.transaction_code}</div>
        </td>
        <td><div style="font-weight:600;">${b.resource_title}</div></td>
        <td>${statusPill[b.status] || b.status}</td>
        <td>
          <div style="font-size:12px;">Borrowed: <strong>${b.borrowed_at}</strong></div>
          <div style="font-size:12px;color:${b.status === 'overdue' ? 'var(--red-600)' : 'var(--text-secondary)'};">Due: <strong>${b.due_at}</strong></div>
        </td>
        <td style="text-align:right;">
          ${b.status !== 'returned'
            ? `<button class="btn btn-primary btn-sm" data-return-id="${b.id}">Mark returned</button>`
            : `<span style="font-size:12px;color:var(--text-muted);">Returned ${b.returned_at || ''}</span>`}
        </td>
      </tr>
    `).join('');

    tbody.querySelectorAll('[data-return-id]').forEach(btn => {
      btn.addEventListener('click', () => handleReturn(btn.dataset.returnId));
    });
  }

  function handleAction(action, id) {
    const state = window.ChmsuApi.getDemoState();
    const rsv = state.reservations.find(r => r.id === id);
    if (!rsv) return;

    if (action === 'approve') {
      rsv.status = 'approved';
      rsv.pickup_label = 'Awaiting preparation';
      rsv.updated_label = 'Approved · Just now';
      window.ChmsuApi.showToast(`Approved ${rsv.reference_code}. Automated notification queued.`);
    } else if (action === 'ready') {
      rsv.status = 'ready';
      rsv.pickup_label = 'Next library day · 4:00 PM';
      rsv.updated_label = 'Ready · Just now';
      document.getElementById('ready-preview-text').textContent =
        `${rsv.student_name.split(' ')[0]}, ${rsv.resource_title} is ready at the Talisay circulation desk. Collect by ${rsv.pickup_label}. Reference: ${rsv.reference_code}.`;
      document.getElementById('preview-badge').textContent = 'Sent to student';
      window.ChmsuApi.showToast(`Marked ${rsv.reference_code} ready. Student notified!`);
    } else if (action === 'checkout') {
      rsv.status = 'completed';
      rsv.pickup_label = 'Collected today';
      rsv.updated_label = 'Checkout recorded · Just now';
      const txnCode = `TXN-261019-${Math.floor(200 + Math.random() * 700)}`;
      state.borrowings.unshift({
        id: `bor-${Date.now()}`,
        transaction_code: txnCode,
        student_name: rsv.student_name,
        student_id_num: rsv.student_id_num,
        resource_title: rsv.resource_title,
        status: 'borrowed',
        borrowed_at: '19 Oct 2026',
        due_at: '26 Oct 2026',
      });
      window.ChmsuApi.showToast(`Checkout completed (${txnCode}). Added to student borrowing activity.`);
    } else if (action === 'cancel') {
      rsv.status = 'cancelled';
      rsv.pickup_label = '—';
      rsv.updated_label = 'Cancelled by librarian · Just now';
      window.ChmsuApi.showToast(`Cancelled ${rsv.reference_code}.`);
    }

    window.ChmsuApi.saveDemoState(state);
    render();
  }

  function handleReturn(borrowingId) {
    const state = window.ChmsuApi.getDemoState();
    const bor = state.borrowings.find(b => b.id === borrowingId);
    if (!bor) return;
    bor.status = 'returned';
    bor.returned_at = '19 Oct 2026';
    window.ChmsuApi.saveDemoState(state);
    window.ChmsuApi.showToast(`Marked ${bor.transaction_code} as returned.`);
    render();
  }

  document.getElementById('send-due-alerts-btn').addEventListener('click', () => {
    const state = window.ChmsuApi.getDemoState();
    const overdueCount = state.borrowings.filter(b => b.status === 'overdue').length;
    window.ChmsuApi.showToast(`Due-date & overdue check complete: ${overdueCount} overdue alert(s) dispatched.`);
  });

  searchEl.addEventListener('input', render);
  render();
})();
