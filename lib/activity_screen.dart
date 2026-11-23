import 'package:flutter/material.dart';
import 'models/library_models.dart';
import 'services/library_service.dart';
import 'theme/app_theme.dart';
import 'transaction_detail_screen.dart';
import 'widgets/book_cover_widget.dart';
import 'widgets/chmsu_header.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final all = LibraryService.instance.borrowings;
    final current = all.where((b) => b.isActive).toList();
    final history = all.where((b) => !b.isActive).toList();

    return Column(
      children: [
        const ChmsuTopHeader(),
        const Divider(height: 1, color: AppColors.borderSubtle),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'YOUR READING RECORD',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 4),
              const Text('Borrowing activity', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              const Text('Track current loans and revisit past reads.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),

              // Segmented tabs: Current | History
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.softGreenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showHistory = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_showHistory ? AppColors.cardWhite : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text('Current (${current.length})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showHistory = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _showHistory ? AppColors.cardWhite : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: Text('History (${history.length})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (!_showHistory) ...[
                ...current.map((b) => _LoanCard(record: b)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warmBeigeCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.access_time, color: AppColors.amberAccent, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Return print books at the Talisay circulation desk. For an overdue item, contact the library for assistance.',
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recently returned', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    GestureDetector(
                      onTap: () => setState(() => _showHistory = true),
                      child: Text('View history (${history.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...history.map((b) => _HistoryCompactCard(record: b)),
              ] else ...[
                ...history.map((b) => _HistoryCompactCard(record: b)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LoanCard extends StatelessWidget {
  final BorrowingRecord record;

  const _LoanCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final isOverdue = record.status == 'overdue';
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetailScreen(record: record)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isOverdue ? AppColors.overdueRed.withValues(alpha: 0.4) : AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            BookCoverWidget(
              title: record.resourceTitle,
              tag: '',
              authors: record.campus,
              color: record.coverColor,
              width: 62,
              height: 86,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.resourceTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('${record.resourceEditionFormat} · ${record.campus}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOverdue ? AppColors.softRedBg : AppColors.softAmberBg,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '• ${record.statusPillLabel}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOverdue ? AppColors.overdueRed : const Color(0xFF8A6216),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isOverdue ? 'Was due ${record.dueAtLabel}' : 'Due ${record.dueAtLabel}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isOverdue ? AppColors.overdueRed : AppColors.textPrimary),
                  ),
                  Text('Borrowed ${record.borrowedAtLabel} · ${record.transactionCode}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _HistoryCompactCard extends StatelessWidget {
  final BorrowingRecord record;

  const _HistoryCompactCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final isLate = record.statusPillLabel.toLowerCase().contains('late');
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetailScreen(record: record)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.resourceTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Returned ${record.returnedAtLabel ?? ''} · ${record.transactionCode}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLate ? AppColors.softAmberBg : AppColors.softGreenBg,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '• ${record.statusPillLabel}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isLate ? const Color(0xFF8A6216) : AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
