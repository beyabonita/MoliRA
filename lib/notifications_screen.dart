import 'package:flutter/material.dart';
import 'services/library_service.dart';
import 'theme/app_theme.dart';
import 'widgets/chmsu_header.dart';

class NotificationsScreen extends StatefulWidget {
  final void Function(int tabIndex, {String catalogFilter}) onNavigateTab;

  const NotificationsScreen({super.key, required this.onNavigateTab});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _tab = 'all'; // all, borrowing, library

  @override
  Widget build(BuildContext context) {
    final svc = LibraryService.instance;
    final unread = svc.unreadNotificationCount;
    final filtered = svc.notifications.where((n) => _tab == 'all' || n.category == _tab).toList();

    return Column(
      children: [
        const ChmsuTopHeader(),
        const Divider(height: 1, color: AppColors.borderSubtle),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'STAY IN THE KNOW',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 4),
              const Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              const Text('Reservation updates, returns, and library news.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$unread unread', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: svc.markAllNotificationsRead,
                    child: const Text('Mark all as read', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.softGreenBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    _segTab('All', 'all'),
                    _segTab('Borrowing', 'borrowing'),
                    _segTab('Library', 'library'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              ...filtered.map((n) {
                final (bg, fg, icon) = switch (n.type) {
                  'reservation_ready' => (AppColors.softGreenBg, AppColors.primaryGreen, Icons.bookmark_added_outlined),
                  'due_soon' => (AppColors.softAmberBg, const Color(0xFF8A6216), Icons.event_available_outlined),
                  'overdue' => (AppColors.softRedBg, AppColors.overdueRed, Icons.error_outline),
                  _ => (AppColors.softBlueBg, AppColors.blueAccent, Icons.campaign_outlined),
                };

                return GestureDetector(
                  onTap: () {
                    svc.markNotificationRead(n.id);
                    if (n.type == 'reservation_ready' || n.type == 'reservation_update') {
                      widget.onNavigateTab(2);
                    } else if (n.type == 'due_soon' || n.type == 'overdue') {
                      widget.onNavigateTab(3);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                          child: Icon(icon, color: fg, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(n.timestampLabel, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  if (!n.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                                    )
                                  else
                                    const Text('Read', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(n.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text(n.body, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
                                child: Text('• ${n.statusLabel}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
                              ),
                              const SizedBox(height: 6),
                              Text(n.actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryGreen)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _segTab(String label, String key) {
    final active = _tab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.cardWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ),
      ),
    );
  }
}
