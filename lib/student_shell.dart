import 'package:flutter/material.dart';
import 'activity_screen.dart';
import 'catalog_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'reservations_screen.dart';
import 'services/library_service.dart';
import 'theme/app_theme.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;
  String _catalogInitialFilter = 'all';

  @override
  void initState() {
    super.initState();
    LibraryService.instance.refreshFromSupabase();
  }

  void _goToTab(int idx, {String catalogFilter = 'all'}) {
    setState(() {
      _index = idx;
      _catalogInitialFilter = catalogFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LibraryService.instance,
      builder: (context, _) {
        final unread = LibraryService.instance.unreadNotificationCount;
        final pages = [
          HomeScreen(onNavigateTab: _goToTab),
          CatalogScreen(initialFormat: _catalogInitialFilter),
          const ReservationsScreen(),
          const ActivityScreen(),
          NotificationsScreen(onNavigateTab: _goToTab),
        ];

        return Scaffold(
          body: SafeArea(child: pages[_index]),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            backgroundColor: AppColors.cardWhite,
            indicatorColor: AppColors.softGreenBg,
            onDestinationSelected: (i) => _goToTab(i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: AppColors.primaryGreen),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search_rounded, color: AppColors.primaryGreen),
                label: 'Catalog',
              ),
              const NavigationDestination(
                icon: Icon(Icons.bookmark_border_rounded),
                selectedIcon: Icon(Icons.bookmark_rounded, color: AppColors.primaryGreen),
                label: 'Reservations',
              ),
              const NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded, color: AppColors.primaryGreen),
                label: 'Activity',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
                selectedIcon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_rounded, color: AppColors.primaryGreen),
                ),
                label: 'Alerts',
              ),
            ],
          ),
        );
      },
    );
  }
}
