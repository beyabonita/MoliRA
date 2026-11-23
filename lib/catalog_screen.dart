import 'package:flutter/material.dart';
import 'models/library_models.dart';
import 'resource_detail_screen.dart';
import 'services/library_service.dart';
import 'theme/app_theme.dart';
import 'widgets/book_cover_widget.dart';
import 'widgets/chmsu_header.dart';

class CatalogScreen extends StatefulWidget {
  final String initialFormat;

  const CatalogScreen({super.key, this.initialFormat = 'all'});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchCtrl = TextEditingController();
  late String _formatFilter;
  bool _onlyAvailable = false;

  @override
  void initState() {
    super.initState();
    _formatFilter = widget.initialFormat;
  }

  @override
  void didUpdateWidget(covariant CatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFormat != widget.initialFormat) {
      _formatFilter = widget.initialFormat;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = LibraryService.instance.resources.where((r) {
      final matchFormat = _formatFilter == 'all' || r.format == _formatFilter;
      final matchAvail = !_onlyAvailable || r.isAvailable;
      final matchQuery = q.isEmpty ||
          r.title.toLowerCase().includes(q) ||
          r.authors.toLowerCase().includes(q) ||
          r.subject.toLowerCase().includes(q);
      return matchFormat && matchAvail && matchQuery;
    }).toList();

    return Column(
      children: [
        const ChmsuTopHeader(),
        const Divider(height: 1, color: AppColors.borderSubtle),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'DISCOVER & RESERVE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.primaryGreen),
              ),
              const SizedBox(height: 4),
              const Text('Library catalog', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              const Text('Explore resources at Talisay campus.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 14),

              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'All resources',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChipBtn(
                      label: 'All formats',
                      selected: _formatFilter == 'all',
                      onTap: () => setState(() => _formatFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipBtn(
                      label: 'Print books',
                      selected: _formatFilter == 'print',
                      onTap: () => setState(() => _formatFilter = 'print'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipBtn(
                      label: 'E-books',
                      selected: _formatFilter == 'ebook',
                      onTap: () => setState(() => _formatFilter = 'ebook'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipBtn(
                      label: 'Available',
                      selected: _onlyAvailable,
                      onTap: () => setState(() => _onlyAvailable = !_onlyAvailable),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Text('${filtered.length} resources', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),

              ...filtered.map((res) => _ResourceListCard(resource: res)),
            ],
          ),
        ),
      ],
    );
  }
}

extension on String {
  bool includes(String needle) => contains(needle);
}

class _FilterChipBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? AppColors.primaryGreen : AppColors.borderSubtle),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ResourceListCard extends StatelessWidget {
  final LibraryResource resource;

  const _ResourceListCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    final availText = resource.isEbook
        ? 'Digital access available'
        : resource.availableCopies > 0
            ? '${resource.availableCopies} of ${resource.totalCopies} copies available'
            : 'All ${resource.totalCopies} copies on loan';
    final availBg = resource.isAvailable ? AppColors.softGreenBg : AppColors.softAmberBg;
    final availColor = resource.isAvailable ? AppColors.primaryGreen : const Color(0xFF8A6216);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResourceDetailScreen(resource: resource)),
        );
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
          children: [
            BookCoverWidget(
              title: resource.title,
              tag: resource.coverTag,
              authors: resource.authors,
              color: resource.coverColor,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${resource.isEbook ? 'E-BOOK' : 'PRINT BOOK'} · ${resource.subject}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(resource.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${resource.authors} · ${resource.editionYear}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: availBg, borderRadius: BorderRadius.circular(99)),
                    child: Text('• $availText', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: availColor)),
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
