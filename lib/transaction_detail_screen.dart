import 'package:flutter/material.dart';
import 'models/library_models.dart';
import 'services/library_service.dart';
import 'theme/app_theme.dart';
import 'widgets/book_cover_widget.dart';

class TransactionDetailScreen extends StatelessWidget {
  final BorrowingRecord record;

  const TransactionDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final user = LibraryService.instance.currentUser;
    final isReturned = record.status == 'returned';

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction detail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BORROWING HISTORY',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 4),
            Text(
              isReturned ? 'A chapter completed' : 'Active borrowing record',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            Text(
              isReturned ? 'Your returned-item transaction record.' : 'Current circulation desk loan details.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      BookCoverWidget(
                        title: record.resourceTitle,
                        tag: '',
                        authors: record.campus,
                        color: record.coverColor,
                        width: 68,
                        height: 94,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(record.resourceTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(record.resourceEditionFormat, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isReturned ? AppColors.softGreenBg : AppColors.softAmberBg,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                '• ${isReturned ? 'Returned' : record.statusPillLabel}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isReturned ? AppColors.primaryGreen : const Color(0xFF8A6216),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.borderSubtle),
                  _InfoRow('Transaction', record.transactionCode),
                  _InfoRow('Borrower', '${user?.fullName ?? 'Maria Santos'} · ${user?.studentId ?? '2024-01842'}'),
                  _InfoRow('Library', record.campus, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Transaction timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  _TimelineStep(
                    icon: Icons.menu_book_outlined,
                    iconBg: AppColors.softGreenBg,
                    iconColor: AppColors.primaryGreen,
                    title: 'Borrowed',
                    date: record.borrowedAtLabel,
                    subtitle: 'Checked out at the circulation desk',
                  ),
                  _TimelineStep(
                    icon: Icons.event_outlined,
                    iconBg: AppColors.softGreenBg,
                    iconColor: AppColors.primaryGreen,
                    title: 'Due date',
                    date: record.dueAtLabel,
                    subtitle: '7-day borrowing period',
                    isLast: !isReturned,
                  ),
                  if (isReturned)
                    _TimelineStep(
                      icon: Icons.check_circle_outline,
                      iconBg: AppColors.softAmberBg,
                      iconColor: AppColors.amberAccent,
                      title: 'Returned',
                      date: record.returnedAtLabel ?? '',
                      subtitle: record.statusPillLabel,
                      isLast: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.borderSubtle),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to borrowing activity', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow(this.label, this.value, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String date;
  final String subtitle;
  final bool isLast;

  const _TimelineStep({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.date,
    required this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(date, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
