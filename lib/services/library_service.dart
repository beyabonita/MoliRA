import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/library_models.dart';
import '../supabase_config.dart';

class LibraryService extends ChangeNotifier {
  static final LibraryService instance = LibraryService._();
  LibraryService._();

  StudentProfile? currentUser;
  List<LibraryResource> resources = _seedResources();
  List<ReservationItem> reservations = _seedReservations();
  List<BorrowingRecord> borrowings = _seedBorrowings();
  List<AppNotificationItem> notifications = _seedNotifications();

  int get unreadNotificationCount => notifications.where((n) => !n.isRead).length;
  int get activeLoanCount => borrowings.where((b) => b.isActive).length;
  int get overdueLoanCount => borrowings.where((b) => b.status == 'overdue').length;

  Future<bool> signIn({required String studentId, required String password}) async {
    if (SupabaseConfig.isConfigured) {
      final client = Supabase.instance.client;
      // Lookup email by student_id or sign in with university email
      final email = studentId.contains('@') ? studentId : '$studentId@chmsu.edu.ph';
      final res = await client.auth.signInWithPassword(email: email, password: password);
      if (res.user != null) {
        currentUser = StudentProfile(
          id: res.user!.id,
          studentId: studentId,
          fullName: res.user!.userMetadata?['full_name'] ?? 'Maria Santos',
          email: res.user!.email ?? email,
          campus: 'Talisay',
        );
        await refreshFromSupabase();
        notifyListeners();
        return true;
      }
      return false;
    }

    // Demo / Local fallback
    currentUser = StudentProfile(
      id: 'stu-demo-1',
      studentId: studentId.isEmpty ? '2024-01842' : studentId,
      fullName: 'Maria Santos',
      email: 'maria.santos@chmsu.edu.ph',
      campus: 'Talisay',
    );
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String studentId,
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (SupabaseConfig.isConfigured) {
      final client = Supabase.instance.client;
      final res = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'student_id': studentId,
          'full_name': fullName,
          'role': 'student',
          'campus': 'Talisay',
        },
      );
      if (res.user != null) {
        currentUser = StudentProfile(
          id: res.user!.id,
          studentId: studentId,
          fullName: fullName,
          email: email,
          campus: 'Talisay',
        );
        notifyListeners();
        return true;
      }
      return false;
    }

    currentUser = StudentProfile(
      id: 'stu-demo-new',
      studentId: studentId,
      fullName: fullName,
      email: email,
      campus: 'Talisay',
    );
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    if (SupabaseConfig.isConfigured) {
      await Supabase.instance.client.auth.signOut();
    }
    currentUser = null;
    notifyListeners();
  }

  Future<void> refreshFromSupabase() async {
    if (!SupabaseConfig.isConfigured) return;
    final client = Supabase.instance.client;
    final resRows = await client.from('resources').select().order('title');
    resources = (resRows as List).map((r) => LibraryResource(
      id: r['id'],
      title: r['title'],
      authors: r['authors'],
      editionYear: r['edition_year'] ?? '',
      format: r['format'],
      subject: r['subject'],
      campus: r['campus'] ?? 'Talisay',
      shelfLocation: r['shelf_location'] ?? '',
      callNumber: r['call_number'] ?? '',
      description: r['description'] ?? '',
      totalCopies: r['total_copies'] ?? 1,
      availableCopies: r['available_copies'] ?? 0,
      coverColor: Color(int.parse((r['cover_color'] ?? '#1B4332').replaceFirst('#', '0xFF'))),
      coverTag: r['cover_tag'] ?? '',
    )).toList();
    notifyListeners();
  }

  Future<ReservationItem> reserveResource(LibraryResource resource) async {
    if (SupabaseConfig.isConfigured) {
      final data = await Supabase.instance.client.rpc(
        'reserve_resource',
        params: {'p_resource_id': resource.id},
      );
      final item = ReservationItem(
        id: data['id'],
        referenceCode: data['reference_code'],
        resourceId: resource.id,
        resourceTitle: resource.title,
        resourceMeta: '${resource.editionYear} · Print book',
        status: data['status'],
        pickupLabel: 'Pending librarian review',
        updatedLabel: 'Submitted just now',
      );
      reservations.insert(0, item);
      notifyListeners();
      return item;
    }

    final ref = 'RSV-261019-${100 + reservations.length + 1}';
    final item = ReservationItem(
      id: 'rsv-${DateTime.now().millisecondsSinceEpoch}',
      referenceCode: ref,
      resourceId: resource.id,
      resourceTitle: resource.title,
      resourceMeta: '${resource.editionYear} · Print book',
      status: 'pending',
      pickupLabel: 'Awaiting librarian review',
      updatedLabel: 'Requested just now',
    );
    reservations.insert(0, item);

    notifications.insert(
      0,
      AppNotificationItem(
        id: 'not-${DateTime.now().millisecondsSinceEpoch}',
        category: 'borrowing',
        type: 'reservation_update',
        title: 'Reservation submitted',
        body: '${resource.title} ($ref) has been submitted for librarian confirmation.',
        statusLabel: 'Pending review',
        timestampLabel: 'Today · Just now',
        actionLabel: 'View reservation →',
        isRead: false,
      ),
    );
    notifyListeners();
    return item;
  }

  Future<void> cancelReservation(String reservationId) async {
    if (SupabaseConfig.isConfigured) {
      await Supabase.instance.client.rpc('update_reservation_status', params: {
        'p_reservation_id': reservationId,
        'p_new_status': 'cancelled',
      });
    }
    reservations = reservations.map((r) {
      if (r.id == reservationId) {
        return r.copyWith(
          status: 'cancelled',
          pickupLabel: '—',
          updatedLabel: 'Cancelled by student · Just now',
        );
      }
      return r;
    }).toList();
    notifyListeners();
  }

  Future<void> logDigitalAccess(LibraryResource resource) async {
    if (SupabaseConfig.isConfigured) {
      await Supabase.instance.client.rpc('log_digital_access', params: {
        'p_resource_id': resource.id,
      });
    }
  }

  void markNotificationRead(String id) {
    notifications = notifications.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    notifyListeners();
  }

  void markAllNotificationsRead() {
    notifications = notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  static List<LibraryResource> _seedResources() => [
    const LibraryResource(
      id: 'res-1',
      title: 'Research Methods in Education',
      authors: 'Louis Cohen, Lawrence Manion & Keith Morrison',
      editionYear: '8th edition · 2018',
      format: 'print',
      subject: 'Education',
      campus: 'Talisay',
      shelfLocation: 'Talisay · Education section',
      callNumber: 'LB1028 C64 2018',
      description:
          'A practical guide to planning educational research, selecting methods, and interpreting findings. Useful for research proposals and thesis preparation.',
      totalCopies: 5,
      availableCopies: 2,
      coverColor: Color(0xFF1B4332),
      coverTag: 'EIGHTH EDITION',
    ),
    const LibraryResource(
      id: 'res-2',
      title: 'Fundamentals of Nursing',
      authors: 'Barbara Kozier, Glenora Erb & Audrey Berman',
      editionYear: '10th edition · 2020',
      format: 'print',
      subject: 'Nursing',
      campus: 'Talisay',
      shelfLocation: 'Talisay · Health Sciences section',
      callNumber: 'RT41 K69 2020',
      description:
          'Comprehensive foundational text covering clinical nursing concepts, patient care procedures, and evidence-based practice.',
      totalCopies: 3,
      availableCopies: 0,
      coverColor: Color(0xFF9A5B3C),
      coverTag: 'TENTH EDITION',
    ),
    const LibraryResource(
      id: 'res-3',
      title: 'Statistics for Research',
      authors: 'R. Sharma',
      editionYear: 'Study guide · 2022',
      format: 'ebook',
      subject: 'Research',
      campus: 'Talisay',
      shelfLocation: 'Digital Repository',
      callNumber: 'QA276 S48 2022',
      description:
          'Applied statistical techniques for undergraduate and graduate research, including hypothesis testing, ANOVA, and regression.',
      totalCopies: 10,
      availableCopies: 10,
      coverColor: Color(0xFF345063),
      coverTag: 'STUDY GUIDE',
    ),
    const LibraryResource(
      id: 'res-4',
      title: 'Ethics & the Human Condition',
      authors: 'Learning Collection Editorial Board',
      editionYear: '2nd edition · 2021',
      format: 'print',
      subject: 'General education',
      campus: 'Talisay',
      shelfLocation: 'Talisay · Humanities section',
      callNumber: 'BJ1012 E84 2021',
      description:
          'Introductory reader on moral philosophy, civic responsibility, and ethical reasoning in contemporary society.',
      totalCopies: 2,
      availableCopies: 1,
      coverColor: Color(0xFF7D6B44),
      coverTag: 'SECOND EDITION',
    ),
  ];

  static List<ReservationItem> _seedReservations() => [
    const ReservationItem(
      id: 'rsv-1',
      referenceCode: 'RSV-261019-042',
      resourceId: 'res-1',
      resourceTitle: 'Research Methods in Education',
      resourceMeta: '8th ed. · Print book',
      status: 'ready',
      pickupLabel: 'Collect by 20 Oct, 4:00 PM',
      updatedLabel: 'Ready 19 Oct · 9:30 AM',
    ),
    const ReservationItem(
      id: 'rsv-2',
      referenceCode: 'RSV-261019-039',
      resourceId: 'res-4',
      resourceTitle: 'Ethics & the Human Condition',
      resourceMeta: '2nd ed. · Print book',
      status: 'pending',
      pickupLabel: 'Awaiting librarian review',
      updatedLabel: 'Requested 19 Oct · 8:50 AM',
    ),
  ];

  static List<BorrowingRecord> _seedBorrowings() => [
    const BorrowingRecord(
      id: 'bor-1',
      transactionCode: 'TXN-261014-122',
      resourceTitle: 'Statistics for Research',
      resourceEditionFormat: 'Study guide · Print book',
      campus: 'Talisay campus',
      coverColor: Color(0xFF345063),
      status: 'borrowed',
      borrowedAtLabel: '14 Oct 2026 · 9:20 AM',
      dueAtLabel: '21 Oct 2026 · 5:00 PM',
      statusPillLabel: 'Due in 2 days',
    ),
    const BorrowingRecord(
      id: 'bor-2',
      transactionCode: 'TXN-261010-107',
      resourceTitle: 'Fundamentals of Nursing',
      resourceEditionFormat: '10th edition · Print book',
      campus: 'Talisay campus',
      coverColor: Color(0xFF9A5B3C),
      status: 'overdue',
      borrowedAtLabel: '10 Oct 2026 · 2:10 PM',
      dueAtLabel: '17 Oct 2026 · 5:00 PM',
      statusPillLabel: '2 days overdue',
    ),
    const BorrowingRecord(
      id: 'bor-3',
      transactionCode: 'TXN-261001-084',
      resourceTitle: 'Research Methods in Education',
      resourceEditionFormat: '8th edition · Print book',
      campus: 'Talisay circulation desk',
      coverColor: Color(0xFF1B4332),
      status: 'returned',
      borrowedAtLabel: '1 Oct 2026 · 10:15 AM',
      dueAtLabel: '8 Oct 2026 · 5:00 PM',
      returnedAtLabel: '9 Oct 2026 · 9:10 AM',
      statusPillLabel: 'Returned late',
    ),
    const BorrowingRecord(
      id: 'bor-4',
      transactionCode: 'TXN-260925-061',
      resourceTitle: 'Ethics & the Human Condition',
      resourceEditionFormat: '2nd edition · Print book',
      campus: 'Talisay circulation desk',
      coverColor: Color(0xFF7D6B44),
      status: 'returned',
      borrowedAtLabel: '25 Sep 2026 · 11:00 AM',
      dueAtLabel: '2 Oct 2026 · 5:00 PM',
      returnedAtLabel: '1 Oct 2026 · 3:45 PM',
      statusPillLabel: 'Returned on time',
    ),
  ];

  static List<AppNotificationItem> _seedNotifications() => [
    const AppNotificationItem(
      id: 'not-1',
      category: 'borrowing',
      type: 'reservation_ready',
      title: 'Your book is ready',
      body: 'Research Methods in Education is ready at the Talisay circulation desk. Collect by 20 Oct, 4 PM.',
      statusLabel: 'Reservation ready',
      timestampLabel: 'Today · 9:30 AM',
      actionLabel: 'View reservation →',
      isRead: false,
    ),
    const AppNotificationItem(
      id: 'not-2',
      category: 'borrowing',
      type: 'due_soon',
      title: 'Due in 2 days',
      body: 'Statistics for Research is due on 21 Oct 2026. Please return your print copy to the circulation desk.',
      statusLabel: 'Due soon',
      timestampLabel: 'Today · 8:00 AM',
      actionLabel: 'View current loans →',
      isRead: false,
    ),
    const AppNotificationItem(
      id: 'not-3',
      category: 'borrowing',
      type: 'overdue',
      title: 'A return is overdue',
      body: 'Fundamentals of Nursing was due on 17 Oct 2026. Return the copy or contact the library for help.',
      statusLabel: '2 days overdue',
      timestampLabel: 'Today · 8:00 AM',
      actionLabel: 'View loan details →',
      isRead: false,
    ),
    const AppNotificationItem(
      id: 'not-4',
      category: 'library',
      type: 'library_update',
      title: 'Research help this week',
      body: 'Visit the Talisay reference desk for help finding sources and using the catalog.',
      statusLabel: 'Library update',
      timestampLabel: '18 Oct · 3:00 PM',
      actionLabel: 'Read update →',
      isRead: true,
    ),
  ];
}
