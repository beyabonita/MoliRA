import 'package:flutter/material.dart';
import 'models/library_models.dart';
import 'services/library_service.dart';
import 'theme/app_theme.dart';
import 'widgets/book_cover_widget.dart';

class ResourceDetailScreen extends StatefulWidget {
  final LibraryResource resource;

  const ResourceDetailScreen({super.key, required this.resource});

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  bool _submitting = false;

  Future<void> _reserve() async {
    setState(() => _submitting = true);
    try {
      final item = await LibraryService.instance.reserveResource(widget.resource);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Reservation submitted'),
          content: Text(
            'Reference: ${item.referenceCode}\n\nYour request for "${widget.resource.title}" is pending librarian confirmation. You will receive a notification once it is ready for pickup.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openEbook() async {
    await LibraryService.instance.logDigitalAccess(widget.resource);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening digital access for "${widget.resource.title}" (logged for analytics).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resource;
    final availText = r.isEbook
        ? 'Digital access available'
        : r.availableCopies > 0
            ? '${r.availableCopies} of ${r.totalCopies} copies available'
            : 'All ${r.totalCopies} copies on loan';

    return Scaffold(
      appBar: AppBar(title: const Text('Resource details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: r.coverColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: BookCoverWidget(
                  title: r.title,
                  tag: r.coverTag,
                  authors: r.authors,
                  color: r.coverColor,
                  width: 120,
                  height: 170,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              '${r.subject.toUpperCase()} · ${r.isEbook ? 'E-BOOK' : 'PRINT BOOK'}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 6),
            Text(r.title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(r.authors, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: r.isAvailable ? AppColors.softGreenBg : AppColors.softAmberBg,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '• $availText',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: r.isAvailable ? AppColors.primaryGreen : const Color(0xFF8A6216),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  _MetaRow('Edition / year', r.editionYear),
                  _MetaRow('Format', r.isEbook ? 'E-book (Digital)' : 'Print book'),
                  _MetaRow('Campus / shelf', r.shelfLocation),
                  _MetaRow('Call number', r.callNumber, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const Text('About this resource', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(r.description, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 16),

            if (!r.isEbook)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.softGreenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.event_note_outlined, color: AppColors.primaryGreen, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Loan policy: borrow for 7 calendar days. Collect a confirmed reservation by 4 PM on the next library day. Bring your student ID.',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),

            if (r.isEbook)
              ElevatedButton.icon(
                onPressed: _openEbook,
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Access E-resource'),
              )
            else if (r.availableCopies > 0) ...[
              ElevatedButton.icon(
                onPressed: _submitting ? null : _reserve,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(_submitting ? 'Submitting...' : 'Reserve a copy'),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Your request is subject to librarian confirmation.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warmBeigeCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ⓘ All copies are currently on loan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    SizedBox(height: 4),
                    Text(
                      'Reservations close when no copies remain. Check back soon or browse related resources.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _MetaRow(this.label, this.value, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          SizedBox(width: 115, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
