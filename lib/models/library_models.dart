import 'package:flutter/material.dart';

class StudentProfile {
  final String id;
  final String studentId;
  final String fullName;
  final String email;
  final String campus;

  const StudentProfile({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.campus,
  });

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'ST';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;
}

class LibraryResource {
  final String id;
  final String title;
  final String authors;
  final String editionYear;
  final String format; // 'print' | 'ebook'
  final String subject;
  final String campus;
  final String shelfLocation;
  final String callNumber;
  final String description;
  final int totalCopies;
  final int availableCopies;
  final Color coverColor;
  final String coverTag;

  const LibraryResource({
    required this.id,
    required this.title,
    required this.authors,
    required this.editionYear,
    required this.format,
    required this.subject,
    required this.campus,
    required this.shelfLocation,
    required this.callNumber,
    required this.description,
    required this.totalCopies,
    required this.availableCopies,
    required this.coverColor,
    required this.coverTag,
  });

  bool get isEbook => format == 'ebook';
  bool get isAvailable => isEbook || availableCopies > 0;

  LibraryResource copyWith({int? availableCopies}) {
    return LibraryResource(
      id: id,
      title: title,
      authors: authors,
      editionYear: editionYear,
      format: format,
      subject: subject,
      campus: campus,
      shelfLocation: shelfLocation,
      callNumber: callNumber,
      description: description,
      totalCopies: totalCopies,
      availableCopies: availableCopies ?? this.availableCopies,
      coverColor: coverColor,
      coverTag: coverTag,
    );
  }
}

class ReservationItem {
  final String id;
  final String referenceCode;
  final String resourceId;
  final String resourceTitle;
  final String resourceMeta;
  final String status; // pending, approved, ready, completed, cancelled
  final String pickupLabel;
  final String updatedLabel;

  const ReservationItem({
    required this.id,
    required this.referenceCode,
    required this.resourceId,
    required this.resourceTitle,
    required this.resourceMeta,
    required this.status,
    required this.pickupLabel,
    required this.updatedLabel,
  });

  ReservationItem copyWith({String? status, String? pickupLabel, String? updatedLabel}) {
    return ReservationItem(
      id: id,
      referenceCode: referenceCode,
      resourceId: resourceId,
      resourceTitle: resourceTitle,
      resourceMeta: resourceMeta,
      status: status ?? this.status,
      pickupLabel: pickupLabel ?? this.pickupLabel,
      updatedLabel: updatedLabel ?? this.updatedLabel,
    );
  }
}

class BorrowingRecord {
  final String id;
  final String transactionCode;
  final String resourceTitle;
  final String resourceEditionFormat;
  final String campus;
  final Color coverColor;
  final String status; // borrowed, overdue, returned
  final String borrowedAtLabel;
  final String dueAtLabel;
  final String? returnedAtLabel;
  final String statusPillLabel;

  const BorrowingRecord({
    required this.id,
    required this.transactionCode,
    required this.resourceTitle,
    required this.resourceEditionFormat,
    required this.campus,
    required this.coverColor,
    required this.status,
    required this.borrowedAtLabel,
    required this.dueAtLabel,
    this.returnedAtLabel,
    required this.statusPillLabel,
  });

  bool get isActive => status == 'borrowed' || status == 'overdue';
}

class AppNotificationItem {
  final String id;
  final String category; // borrowing, library
  final String type; // reservation_ready, due_soon, overdue, library_update
  final String title;
  final String body;
  final String statusLabel;
  final String timestampLabel;
  final String actionLabel;
  final bool isRead;

  const AppNotificationItem({
    required this.id,
    required this.category,
    required this.type,
    required this.title,
    required this.body,
    required this.statusLabel,
    required this.timestampLabel,
    required this.actionLabel,
    required this.isRead,
  });

  AppNotificationItem copyWith({bool? isRead}) {
    return AppNotificationItem(
      id: id,
      category: category,
      type: type,
      title: title,
      body: body,
      statusLabel: statusLabel,
      timestampLabel: timestampLabel,
      actionLabel: actionLabel,
      isRead: isRead ?? this.isRead,
    );
  }
}
