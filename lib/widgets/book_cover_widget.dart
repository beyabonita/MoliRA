import 'package:flutter/material.dart';

class BookCoverWidget extends StatelessWidget {
  final String title;
  final String tag;
  final String authors;
  final Color color;
  final double width;
  final double height;

  const BookCoverWidget({
    super.key,
    required this.title,
    required this.tag,
    required this.authors,
    required this.color,
    this.width = 74,
    this.height = 104,
  });

  @override
  Widget build(BuildContext context) {
    final compact = width < 90;
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(compact ? 8 : 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(compact ? 6 : 10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tag.isNotEmpty)
            Text(
              tag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: compact ? 6.5 : 8.5,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          SizedBox(height: compact ? 4 : 8),
          Container(
            width: compact ? 18 : 28,
            height: 2,
            color: const Color(0xFFD4A853),
          ),
          SizedBox(height: compact ? 5 : 10),
          Expanded(
            child: Text(
              title,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Georgia',
                fontSize: compact ? 9.5 : 15,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            authors,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: compact ? 6 : 8,
            ),
          ),
        ],
      ),
    );
  }
}
