import 'package:flutter/material.dart';
import 'resource_detail_screen.dart';
import 'services/library_service.dart';
import 'theme/app_theme.dart';
import 'widgets/book_cover_widget.dart';
import 'widgets/chmsu_header.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int tabIndex, {String catalogFilter}) onNavigateTab;

  const HomeScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final svc = LibraryService.instance;
    final user = svc.currentUser;
    final activeLoans = svc.activeLoanCount;
    final overdueLoans = svc.overdueLoanCount;
    final featured = svc.resources.take(2).toList();

    return RefreshIndicator(
      onRefresh: LibraryService.instance.refreshFromSupabase,
      color: AppColors.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ChmsuTopHeader(),
          const Divider(height: 1, color: AppColors.borderSubtle),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MONDAY, 19 OCTOBER 2026',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.primaryGreen),
                ),
                const SizedBox(height: 4),
                Text(
                  'Good morning, ${user?.firstName ?? 'Maria'}.',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const Text(
                  'A little discovery goes a long way.',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Search bar -> jumps to Catalog
                GestureDetector(
                  onTap: () => onNavigateTab(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: AppColors.textMuted, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Search title, author, or subject',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                          ),
                        ),
                        Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Dark green shelf status card
                InkWell(
                  onTap: () => onNavigateTab(3),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$activeLoans books on your shelf',
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                overdueLoans > 0
                                    ? 'Next due 21 Oct · $overdueLoans item overdue'
                                    : 'All current loans are on schedule',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.north_east, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Find what you need', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    GestureDetector(
                      onTap: () => onNavigateTab(1),
                      child: const Text('Browse all', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _QuickCategoryCard(
                        icon: Icons.book_outlined,
                        title: 'Print books',
                        subtitle: 'Reserve a copy',
                        onTap: () => onNavigateTab(1, catalogFilter: 'print'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickCategoryCard(
                        icon: Icons.description_outlined,
                        title: 'E-resources',
                        subtitle: 'Digital access',
                        onTap: () => onNavigateTab(1, catalogFilter: 'ebook'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('For curious minds', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    GestureDetector(
                      onTap: () => onNavigateTab(1),
                      child: const Text('View catalog', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: featured.map((res) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: res == featured.first ? 10 : 0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ResourceDetailScreen(resource: res)),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 165,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: res.coverColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: BookCoverWidget(
                                    title: res.title,
                                    tag: res.coverTag,
                                    authors: res.authors,
                                    color: res.coverColor,
                                    width: 96,
                                    height: 134,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(res.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(res.authors, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text(
                                res.isEbook ? 'E-book available' : '${res.availableCopies} copies available',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Campus hours card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warmBeigeCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, color: AppColors.amberAccent, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Talisay campus library', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            SizedBox(height: 2),
                            Text('Library hours · Mon–Fri, 8 AM–5 PM\nPickup at the circulation desk.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _QuickCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickCategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 20),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
