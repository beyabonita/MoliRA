/**
 * CHMSU Library - Supabase Client & Demo Data Layer
 * Mirrors the Security Agency Management System pattern:
 * - Uses Supabase REST/JS when configured in window.CHMSU_CONFIG
 * - Provides a persistent localStorage Demo Mode when Supabase keys are not yet set
 */
(function () {
  const DEFAULT_CONFIG = {
    supabaseUrl: localStorage.getItem('chmsu_supabase_url') || 'https://ayjvgmbwhanikoqfkrym.supabase.co',
    supabaseAnonKey: localStorage.getItem('chmsu_supabase_key') || 'sb_publishable_t0m2Uv5Zq7M6R7SGJve47w_8MmLt0p6',
  };

  window.CHMSU_CONFIG = window.CHMSU_CONFIG || DEFAULT_CONFIG;

  const DEMO_KEY = 'chmsu_library_demo_v1';

  const SEED_DEMO = {
    librarian: {
      id: 'lib-001',
      full_name: 'Ana Dela Cruz',
      email: 'ana.delacruz@chmsu.edu.ph',
      role: 'librarian',
      campus: 'Talisay',
    },
    resources: [
      {
        id: 'res-1',
        title: 'Research Methods in Education',
        authors: 'Louis Cohen, Lawrence Manion & Keith Morrison',
        edition_year: '8th ed. · Print book',
        format: 'print',
        subject: 'Education',
        campus: 'Talisay',
        shelf_location: 'Talisay · Education section',
        call_number: 'LB1028 C64 2018',
        total_copies: 5,
        available_copies: 2,
        print_uses: 54,
        digital_uses: 12,
      },
      {
        id: 'res-2',
        title: 'Fundamentals of Nursing',
        authors: 'Barbara Kozier, Glenora Erb & Audrey Berman',
        edition_year: '10th ed. · Print book',
        format: 'print',
        subject: 'Nursing',
        campus: 'Talisay',
        shelf_location: 'Talisay · Health Sciences section',
        call_number: 'RT41 K69 2020',
        total_copies: 3,
        available_copies: 0,
        print_uses: 54,
        digital_uses: 0,
      },
      {
        id: 'res-3',
        title: 'Statistics for Research',
        authors: 'R. Sharma',
        edition_year: 'Study guide · E-book',
        format: 'ebook',
        subject: 'Research',
        campus: 'Talisay',
        shelf_location: 'Digital Repository',
        call_number: 'QA276 S48 2022',
        total_copies: 10,
        available_copies: 10,
        print_uses: 24,
        digital_uses: 24,
      },
      {
        id: 'res-4',
        title: 'Ethics & the Human Condition',
        authors: 'Learning Collection Editorial Board',
        edition_year: '2nd ed. · Print book',
        format: 'print',
        subject: 'General education',
        campus: 'Talisay',
        shelf_location: 'Talisay · Humanities section',
        call_number: 'BJ1012 E84 2021',
        total_copies: 2,
        available_copies: 1,
        print_uses: 30,
        digital_uses: 6,
      },
    ],
    reservations: [
      {
        id: 'rsv-1',
        reference_code: 'RSV-261019-042',
        student_name: 'Maria Santos',
        student_id_num: '2024-01842',
        resource_id: 'res-1',
        resource_title: 'Research Methods in Education',
        resource_meta: '8th ed. · Print book',
        status: 'ready',
        pickup_label: '20 Oct · 4:00 PM',
        updated_label: 'Ready 19 Oct · 9:30 AM',
        created_at: '2026-10-19T09:30:00Z',
      },
      {
        id: 'rsv-2',
        reference_code: 'RSV-261019-039',
        student_name: 'Maria Santos',
        student_id_num: '2024-01842',
        resource_id: 'res-4',
        resource_title: 'Ethics & the Human Condition',
        resource_meta: '2nd ed. · Print book',
        status: 'pending',
        pickup_label: 'Not assigned',
        updated_label: 'Requested 19 Oct · 8:50 AM',
        created_at: '2026-10-19T08:50:00Z',
      },
      {
        id: 'rsv-3',
        reference_code: 'RSV-261019-043',
        student_name: 'Juan Villanueva',
        student_id_num: '2023-00851',
        resource_id: 'res-1',
        resource_title: 'Research Methods in Education',
        resource_meta: '8th ed. · Print book',
        status: 'pending',
        pickup_label: 'Not assigned',
        updated_label: 'Requested 19 Oct · 9:45 AM',
        created_at: '2026-10-19T09:45:00Z',
      },
      {
        id: 'rsv-4',
        reference_code: 'RSV-261019-041',
        student_name: 'Ana Reyes',
        student_id_num: '2024-01126',
        resource_id: 'res-3',
        resource_title: 'Statistics for Research',
        resource_meta: 'Study guide · Print book',
        status: 'approved',
        pickup_label: 'Awaiting preparation',
        updated_label: 'Approved 19 Oct · 9:10 AM',
        created_at: '2026-10-19T09:10:00Z',
      },
      {
        id: 'rsv-5',
        reference_code: 'RSV-261018-038',
        student_name: 'Miguel Bautista',
        student_id_num: '2022-00904',
        resource_id: 'res-1',
        resource_title: 'Research Methods in Education',
        resource_meta: '8th ed. · Print book',
        status: 'completed',
        pickup_label: 'Collected 19 Oct',
        updated_label: 'Checkout recorded · 8:40 AM',
        created_at: '2026-10-18T08:40:00Z',
      },
      {
        id: 'rsv-6',
        reference_code: 'RSV-261018-037',
        student_name: 'Carlo Ramos',
        student_id_num: '2023-01447',
        resource_id: 'res-2',
        resource_title: 'Fundamentals of Nursing',
        resource_meta: '10th ed. · Print book',
        status: 'cancelled',
        pickup_label: '—',
        updated_label: 'Cancelled by student · 18 Oct',
        created_at: '2026-10-18T08:00:00Z',
      },
    ],
    borrowings: [
      {
        id: 'bor-1',
        transaction_code: 'TXN-261014-122',
        student_name: 'Maria Santos',
        student_id_num: '2024-01842',
        resource_title: 'Statistics for Research',
        status: 'borrowed',
        borrowed_at: '14 Oct 2026',
        due_at: '21 Oct 2026',
      },
      {
        id: 'bor-2',
        transaction_code: 'TXN-261010-107',
        student_name: 'Maria Santos',
        student_id_num: '2024-01842',
        resource_title: 'Fundamentals of Nursing',
        status: 'overdue',
        borrowed_at: '10 Oct 2026',
        due_at: '17 Oct 2026',
      },
      {
        id: 'bor-3',
        transaction_code: 'TXN-261001-084',
        student_name: 'Maria Santos',
        student_id_num: '2024-01842',
        resource_title: 'Research Methods in Education',
        status: 'returned',
        borrowed_at: '1 Oct 2026',
        due_at: '8 Oct 2026',
        returned_at: '9 Oct 2026',
      },
    ],
    reports: [
      {
        report_code: 'RPT-261019-007',
        report_type: 'Resource usage',
        generated_by: 'Ana Dela Cruz',
        period_label: '1–19 Oct 2026',
        created_label: '19 Oct · 10:00 AM',
        format: 'CSV / PDF',
      },
      {
        report_code: 'RPT-261019-006',
        report_type: 'Reservation status',
        generated_by: 'Ana Dela Cruz',
        period_label: '1–19 Oct 2026',
        created_label: '19 Oct · 9:45 AM',
        format: 'PDF',
      },
      {
        report_code: 'RPT-261018-005',
        report_type: 'Borrowing summary',
        generated_by: 'Ana Dela Cruz',
        period_label: '1–18 Oct 2026',
        created_label: '18 Oct · 4:30 PM',
        format: 'CSV',
      },
    ],
    timeseries: [
      { label: '1–5 Oct', print: 54, digital: 18 },
      { label: '6–10 Oct', print: 66, digital: 22 },
      { label: '11–15 Oct', print: 74, digital: 28 },
      { label: '16–19 Oct', print: 54, digital: 28 },
    ],
  };

  function getDemoState() {
    const raw = localStorage.getItem(DEMO_KEY);
    if (!raw) {
      localStorage.setItem(DEMO_KEY, JSON.stringify(SEED_DEMO));
      return structuredClone(SEED_DEMO);
    }
    return JSON.parse(raw);
  }

  function saveDemoState(state) {
    localStorage.setItem(DEMO_KEY, JSON.stringify(state));
  }

  function hasSupabase() {
    return Boolean(window.CHMSU_CONFIG.supabaseUrl && window.CHMSU_CONFIG.supabaseAnonKey && window.supabase);
  }

  function getSupabaseClient() {
    if (!hasSupabase()) return null;
    if (!window._sbClient) {
      window._sbClient = window.supabase.createClient(
        window.CHMSU_CONFIG.supabaseUrl,
        window.CHMSU_CONFIG.supabaseAnonKey
      );
    }
    return window._sbClient;
  }

  function showToast(msg) {
    let el = document.getElementById('chmsu-toast');
    if (!el) {
      el = document.createElement('div');
      el.id = 'chmsu-toast';
      el.className = 'toast';
      document.body.appendChild(el);
    }
    el.textContent = msg;
    el.style.display = 'block';
    clearTimeout(window._toastTimer);
    window._toastTimer = setTimeout(() => {
      el.style.display = 'none';
    }, 3200);
  }

  function isLiveSession() {
    const raw = localStorage.getItem('chmsu_librarian_session');
    if (!raw || !hasSupabase()) return false;
    try {
      const s = JSON.parse(raw);
      return Boolean(s && s.is_supabase);
    } catch {
      return false;
    }
  }

  window.ChmsuApi = {
    hasSupabase,
    getSupabaseClient,
    isLiveSession,
    getDemoState,
    saveDemoState,
    showToast,
    requireSession() {
      const session = localStorage.getItem('chmsu_librarian_session');
      if (!session) {
        window.location.href = 'librarian.html';
        return null;
      }
      return JSON.parse(session);
    },
    logout() {
      localStorage.removeItem('chmsu_librarian_session');
      const client = getSupabaseClient();
      if (client) client.auth.signOut();
      window.location.href = 'librarian.html';
    },
  };
})();
