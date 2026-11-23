import 'package:flutter/material.dart';
import '../services/library_service.dart';
import '../theme/app_theme.dart';

class ChmsuTopHeader extends StatelessWidget {
  const ChmsuTopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = LibraryService.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.softGreenBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHMSU Library',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
              Text(
                'LEARN. DISCOVER. GROW.',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'signout') {
                await LibraryService.instance.signOut();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text('${user?.fullName ?? 'Student'} (${user?.studentId ?? ''})'),
              ),
              const PopupMenuItem(value: 'signout', child: Text('Sign out')),
            ],
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.warmBeigeCard,
              child: Text(
                user?.initials ?? 'MS',
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
