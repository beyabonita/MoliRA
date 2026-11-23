(function () {
  const user = window.ChmsuApi.requireSession();
  if (!user) return;

  const fullName = user.full_name || 'Ana Dela Cruz';
  document.getElementById('librarian-name').textContent = fullName;
  document.getElementById('librarian-initials').textContent = fullName.split(' ').map(p => p[0]).join('').slice(0, 2).toUpperCase();

  const addCard = document.getElementById('add-resource-card');
  document.getElementById('toggle-add-btn').addEventListener('click', () => {
    addCard.style.display = addCard.style.display === 'none' ? 'block' : 'none';
  });
  document.getElementById('close-add-btn').addEventListener('click', () => {
    addCard.style.display = 'none';
  });

  const searchEl = document.getElementById('catalog-search');
  const formatEl = document.getElementById('catalog-format');

  async function loadCatalog() {
    let resources = [];
    if (window.ChmsuApi.isLiveSession()) {
      const client = window.ChmsuApi.getSupabaseClient();
      const { data, error } = await client.from('resources').select('*').order('title');
      if (error) {
        window.ChmsuApi.showToast(error.message);
        return;
      }
      resources = data || [];
    } else {
      resources = window.ChmsuApi.getDemoState().resources;
    }

    const q = searchEl.value.trim().toLowerCase();
    const fmt = formatEl.value;
    const filtered = resources.filter(r => {
      const matchFmt = fmt === 'all' || r.format === fmt;
      const matchQ = !q || r.title.toLowerCase().includes(q) || r.authors.toLowerCase().includes(q) || r.subject.toLowerCase().includes(q);
      return matchFmt && matchQ;
    });

    document.getElementById('catalog-count-pill').textContent = `${resources.length} resources`;
    const tbody = document.getElementById('catalog-tbody');
    if (filtered.length === 0) {
      tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:var(--text-muted);padding:28px;">No resources found.</td></tr>';
      return;
    }

    tbody.innerHTML = filtered.map(r => `
      <tr>
        <td>
          <div style="font-weight:600;">${r.title}</div>
          <div style="font-size:11px;color:var(--text-muted);">${r.authors}</div>
        </td>
        <td>${r.format === 'ebook' ? '<span class="pill pill-blue">E-book</span>' : '<span class="pill pill-green">Print</span>'}</td>
        <td>
          <div style="font-weight:500;">${r.subject}</div>
          <div style="font-size:11px;color:var(--text-muted);">${r.shelf_location || 'Talisay'}</div>
        </td>
        <td>${r.call_number || '—'}</td>
        <td><strong>${r.available_copies}</strong> / ${r.total_copies}</td>
        <td style="text-align:right;white-space:nowrap;">
          <button class="btn btn-outline btn-sm" data-inc="${r.id}" data-avail="${r.available_copies}" data-total="${r.total_copies}">+1 copy</button>
          <button class="btn-danger-link" data-del="${r.id}">Delete</button>
        </td>
      </tr>
    `).join('');

    tbody.querySelectorAll('[data-inc]').forEach(btn => {
      btn.addEventListener('click', () => addCopy(btn.dataset.inc, Number(btn.dataset.avail), Number(btn.dataset.total)));
    });
    tbody.querySelectorAll('[data-del]').forEach(btn => {
      btn.addEventListener('click', () => deleteResource(btn.dataset.del));
    });
  }

  async function addCopy(id, avail, total) {
    if (window.ChmsuApi.isLiveSession()) {
      const client = window.ChmsuApi.getSupabaseClient();
      const { error } = await client
        .from('resources')
        .update({ available_copies: avail + 1, total_copies: total + 1 })
        .eq('id', id);
      if (error) {
        window.ChmsuApi.showToast(error.message);
        return;
      }
      window.ChmsuApi.showToast('Added 1 copy to catalog.');
      loadCatalog();
      return;
    }
    const state = window.ChmsuApi.getDemoState();
    const res = state.resources.find(r => r.id === id);
    if (res) {
      res.available_copies += 1;
      res.total_copies += 1;
      window.ChmsuApi.saveDemoState(state);
      loadCatalog();
    }
  }

  async function deleteResource(id) {
    if (!confirm('Remove this resource from the catalog?')) return;
    if (window.ChmsuApi.isLiveSession()) {
      const client = window.ChmsuApi.getSupabaseClient();
      const { error } = await client.from('resources').delete().eq('id', id);
      if (error) {
        window.ChmsuApi.showToast(error.message);
        return;
      }
      window.ChmsuApi.showToast('Resource removed.');
      loadCatalog();
      return;
    }
    const state = window.ChmsuApi.getDemoState();
    state.resources = state.resources.filter(r => r.id !== id);
    window.ChmsuApi.saveDemoState(state);
    loadCatalog();
  }

  document.getElementById('add-resource-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const copies = Math.max(1, Number(document.getElementById('res-copies').value || 1));
    const payload = {
      title: document.getElementById('res-title').value.trim(),
      authors: document.getElementById('res-authors').value.trim(),
      edition_year: document.getElementById('res-edition').value.trim(),
      format: document.getElementById('res-format').value,
      subject: document.getElementById('res-subject').value.trim(),
      campus: 'Talisay',
      shelf_location: document.getElementById('res-shelf').value.trim(),
      call_number: document.getElementById('res-call').value.trim(),
      description: document.getElementById('res-desc').value.trim(),
      total_copies: copies,
      available_copies: copies,
      cover_color: document.getElementById('res-color').value,
      cover_tag: 'CHMSU',
    };

    if (window.ChmsuApi.isLiveSession()) {
      const client = window.ChmsuApi.getSupabaseClient();
      const { error } = await client.from('resources').insert(payload);
      if (error) {
        window.ChmsuApi.showToast(error.message);
        return;
      }
      document.getElementById('add-resource-form').reset();
      addCard.style.display = 'none';
      window.ChmsuApi.showToast('Resource added to Supabase catalog.');
      loadCatalog();
      return;
    }

    const state = window.ChmsuApi.getDemoState();
    state.resources.unshift({ id: `res-${Date.now()}`, ...payload, print_uses: 0, digital_uses: 0 });
    window.ChmsuApi.saveDemoState(state);
    document.getElementById('add-resource-form').reset();
    addCard.style.display = 'none';
    loadCatalog();
  });

  searchEl.addEventListener('input', loadCatalog);
  formatEl.addEventListener('change', loadCatalog);
  loadCatalog();
})();
