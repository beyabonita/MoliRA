import 'package:flutter/material.dart';
import 'services/library_service.dart';
import 'theme/app_theme.dart';
import 'widgets/chmsu_header.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = LibraryService.instance.reservations;

    return Column(
      children: [
        const ChmsuTopHeader(),
        const Divider(height: 1, color: AppColors.borderSubtle),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'HOLD REQUESTS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 4),
              const Text('My reservations', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              const Text('Track approval status and pickup deadlines.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),

              if (list.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No reservations yet. Browse the catalog to reserve a print book.', textAlign: TextAlign.center),
                  ),
                )
              else
                ...list.map((r) {
                  final canCancel = r.status == 'pending' || r.status == 'approved' || r.status == 'ready';
                  final (pillBg, pillFg, label) = switch (r.status) {
                    'ready' => (AppColors.softGreenBg, AppColors.primaryGreen, 'Ready for pickup'),
                    'approved' => (AppColors.softBlueBg, AppColors.blueAccent, 'Approved'),
                    'completed' => (AppColors.softGreenBg, AppColors.primaryGreen, 'Completed'),
                    'cancelled' => (const Color(0xFFEFECE4), AppColors.textSecondary, 'Cancelled'),
                    _ => (AppColors.softAmberBg, const Color(0xFF8A6216), 'Pending'),
                  };

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(r.referenceCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(99)),
                              child: Text('• $label', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pillFg)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(r.resourceTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text(r.resourceMeta, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 15, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(r.pickupLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            if (canCancel)
                              TextButton(
                                onPressed: () => LibraryService.instance.cancelReservation(r.id),
                                child: const Text('Cancel', style: TextStyle(color: AppColors.overdueRed, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}
