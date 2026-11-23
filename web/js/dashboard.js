(function () {
  const user = window.ChmsuApi.requireSession();
  if (!user) return;

  const fullName = user.full_name || 'Ana Dela Cruz';
  document.getElementById('librarian-name').textContent = fullName;
  document.getElementById('greeting-name').textContent = fullName.split(' ')[0];
  const initials = fullName.split(' ').map(p => p[0]).join('').slice(0, 2).toUpperCase();
  document.getElementById('librarian-initials').textContent = initials;

  function fmtDate(iso) {
    if (!iso) return '—';
    return new Date(iso).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
  }

  async function loadDashboard() {
    try {
      let reservations = [];
      let borrowings = [];
      let students = [];

      if (window.ChmsuApi.isLiveSession()) {
        const client = window.ChmsuApi.getSupabaseClient();
        const { data: sessionData } = await client.auth.getSession();
        if (!sessionData?.session) {
          window.ChmsuApi.showToast('Session expired. Please sign in again.');
          setTimeout(() => window.ChmsuApi.logout(), 1200);
          return;
        }

        const [rsvQ, borQ, stuQ] = await Promise.all([
          client
            .from('reservations')
            .select('id, reference_code, status, created_at, profiles(full_name, student_id), resources(title)')
            .order('created_at', { ascending: false }),
          client
            .from('borrowings')
            .select('id, transaction_code, status, due_at, profiles(full_name, student_id), resources(title)')
            .in('status', ['borrowed', 'overdue'])
            .order('due_at', { ascending: true }),
          client
            .from('profiles')
            .select('id, student_id, full_name, email, campus')
            .eq('role', 'student')
            .order('created_at', { ascending: false }),
        ]);
        if (rsvQ.error) throw rsvQ.error;
        if (borQ.error) throw borQ.error;
        if (stuQ.error) throw stuQ.error;
        students = stuQ.data || [];

        reservations = (rsvQ.data || []).map(r => ({
          id: r.id,
          reference_code: r.reference_code,
          student_name: r.profiles?.full_name || 'Student',
          resource_title: r.resources?.title || 'Resource',
          status: r.status,
        }));
        borrowings = (borQ.data || []).map(b => ({
          id: b.id,
          transaction_code: b.transaction_code,
          student_name: b.profiles?.full_name || 'Student',
          resource_title: b.resources?.title || 'Resource',
          status: b.status,
          due_at: fmtDate(b.due_at),
        }));
      } else {
        const state = window.ChmsuApi.getDemoState();
        reservations = state.reservations;
        borrowings = state.borrowings.filter(b => b.status !== 'returned');
        students = [{ student_id: '2024-01842', full_name: 'Maria Santos', email: 'maria.santos@chmsu.edu.ph', campus: 'Talisay' }];
      }

      document.getElementById('dash-users').textContent = students.length;
      document.getElementById('dash-pending').textContent = reservations.filter(r => r.status === 'pending').length;
      document.getElementById('dash-ready').textContent = reservations.filter(r => r.status === 'ready').length;
      document.getElementById('dash-active').textContent = borrowings.length;
      document.getElementById('dash-overdue').textContent = borrowings.filter(b => b.status === 'overdue').length;

      const studentsBody = document.getElementById('dash-students-body');
      if (studentsBody) {
        if (students.length === 0) {
          studentsBody.innerHTML = '<tr><td colspan="4" style="text-align:center;color:var(--text-muted);padding:24px;">No registered student accounts yet.</td></tr>';
        } else {
          studentsBody.innerHTML = students.map(s => `
            <tr>
              <td style="font-weight:600;color:var(--green-800);">${s.student_id || '—'}</td>
              <td style="font-weight:600;">${s.full_name || '—'}</td>
              <td>${s.email || '—'}</td>
              <td>${s.campus || 'Talisay'}</td>
            </tr>
          `).join('');
        }
      }

    const queue = reservations.filter(r => ['pending', 'approved', 'ready'].includes(r.status)).slice(0, 6);
    const queueBody = document.getElementById('dash-queue-body');
    if (queue.length === 0) {
      queueBody.innerHTML = '<tr><td colspan="4" style="text-align:center;color:var(--text-muted);padding:24px;">No active reservation requests right now.</td></tr>';
    } else {
      queueBody.innerHTML = queue.map(r => {
        const pill = r.status === 'pending'
          ? '<span class="pill pill-amber">Pending</span>'
          : r.status === 'approved'
            ? '<span class="pill pill-blue">Approved</span>'
            : '<span class="pill pill-green">Ready</span>';
        const btnLabel = r.status === 'pending' ? 'Approve' : r.status === 'approved' ? 'Mark ready' : 'Complete checkout';
        const action = r.status === 'pending' ? 'approve' : r.status === 'approved' ? 'ready' : 'checkout';
        return `
          <tr>
            <td>
              <div style="font-weight:600;">${r.student_name}</div>
              <div style="font-size:11px;color:var(--green-700);font-weight:600;">${r.reference_code}</div>
            </td>
            <td style="font-weight:500;">${r.resource_title}</td>
            <td>${pill}</td>
            <td style="text-align:right;">
              <button class="btn btn-primary btn-sm" data-dash-action="${action}" data-id="${r.id}">${btnLabel}</button>
            </td>
          </tr>
        `;
      }).join('');

      queueBody.querySelectorAll('[data-dash-action]').forEach(btn => {
        btn.addEventListener('click', () => handleQueueAction(btn.dataset.dashAction, btn.dataset.id));
      });
    }

    const loansBody = document.getElementById('dash-loans-body');
    if (borrowings.length === 0) {
      loansBody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:var(--text-muted);padding:24px;">No active or overdue loans.</td></tr>';
    } else {
      loansBody.innerHTML = borrowings.slice(0, 6).map(b => `
        <tr>
          <td>
            <div style="font-weight:600;">${b.student_name}</div>
            <div style="font-size:11px;color:var(--green-700);font-weight:600;">${b.transaction_code}</div>
          </td>
          <td style="font-weight:500;">${b.resource_title}</td>
          <td>${b.status === 'overdue' ? '<span class="pill pill-red">Overdue</span>' : '<span class="pill pill-amber">Borrowed</span>'}</td>
          <td>${b.due_at}</td>
          <td style="text-align:right;">
            <button class="btn btn-outline btn-sm" data-return-id="${b.id}">Mark returned</button>
          </td>
        </tr>
      `).join('');

      loansBody.querySelectorAll('[data-return-id]').forEach(btn => {
        btn.addEventListener('click', () => handleReturn(btn.dataset.returnId));
      });
    }
    } catch (err) {
      window.ChmsuApi.showToast(err?.message || 'Failed to load dashboard data.');
    }
  }

  async function handleQueueAction(action, id) {
    if (window.ChmsuApi.isLiveSession()) {
      const client = window.ChmsuApi.getSupabaseClient();
      const { error } = action === 'checkout'
        ? await client.rpc('complete_reservation_checkout', { p_reservation_id: id })
        : await client.rpc('update_reservation_status', {
            p_reservation_id: id,
            p_new_status: action === 'approve' ? 'approved' : 'ready',
          });
      if (error) {
        window.ChmsuApi.showToast(error.message);
        return;
      }
      window.ChmsuApi.showToast('Reservation updated & student notified.');
      loadDashboard();
      return;
    }

    const state = window.ChmsuApi.getDemoState();
    const rsv = state.reservations.find(r => r.id === id);
    if (rsv) {
      rsv.status = action === 'approve' ? 'approved' : action === 'ready' ? 'ready' : 'completed';
      window.ChmsuApi.saveDemoState(state);
      window.ChmsuApi.showToast('Reservation updated.');
      loadDashboard();
    }
  }

  async function handleReturn(borrowingId) {
    if (window.ChmsuApi.isLiveSession()) {
      const client = window.ChmsuApi.getSupabaseClient();
      const { error } = await client.rpc('return_borrowed_book', { p_borrowing_id: borrowingId });
      if (error) {
        window.ChmsuApi.showToast(error.message);
        return;
      }
      window.ChmsuApi.showToast('Book marked as returned.');
      loadDashboard();
      return;
    }
    const state = window.ChmsuApi.getDemoState();
    const b = state.borrowings.find(x => x.id === borrowingId);
    if (b) {
      b.status = 'returned';
      window.ChmsuApi.saveDemoState(state);
      window.ChmsuApi.showToast('Book marked as returned.');
      loadDashboard();
    }
  }

  document.getElementById('run-alerts-btn').addEventListener('click', async () => {
    if (window.ChmsuApi.isLiveSession()) {
      const client = window.ChmsuApi.getSupabaseClient();
      const { data, error } = await client.rpc('generate_due_and_overdue_notifications');
      if (error) {
        window.ChmsuApi.showToast(error.message);
        return;
      }
      window.ChmsuApi.showToast(`Dispatched ${data || 0} due-soon/overdue notification(s).`);
      loadDashboard();
      return;
    }
    window.ChmsuApi.showToast('Due-date & overdue check completed.');
  });

  document.getElementById('announcement-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const title = document.getElementById('ann-title').value.trim();
    const body = document.getElementById('ann-body').value.trim();
    if (!title || !body) return;

    if (window.ChmsuApi.isLiveSession()) {
      const client = window.ChmsuApi.getSupabaseClient();
      const { data: students, error: stuErr } = await client
        .from('profiles')
        .select('id')
        .eq('role', 'student');
      if (stuErr) {
        window.ChmsuApi.showToast(stuErr.message);
        return;
      }
      if (!students || students.length === 0) {
        window.ChmsuApi.showToast('No student accounts registered yet.');
        return;
      }
      const rows = students.map(s => ({
        user_id: s.id,
        category: 'library',
        type: 'library_update',
        title,
        body,
        status_label: 'Library update',
      }));
      const { error } = await client.from('notifications').insert(rows);
      if (error) {
        window.ChmsuApi.showToast(error.message);
        return;
      }
      document.getElementById('announcement-form').reset();
      window.ChmsuApi.showToast(`Announcement sent to ${students.length} student(s).`);
      return;
    }

    document.getElementById('announcement-form').reset();
    window.ChmsuApi.showToast('Announcement sent (Demo Mode).');
  });

  loadDashboard();
})();
