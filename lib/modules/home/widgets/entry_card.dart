import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jrnl/modules/home/models/entry_model.dart';
import 'package:jrnl/services/cover_image_service.dart';

class EntryCard extends StatefulWidget {
  final EntryModel entry;
  final VoidCallback onTap;

  const EntryCard({super.key, required this.entry, required this.onTap});

  @override
  State<EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<EntryCard> {
  File? _coverImage;

  @override
  void initState() {
    super.initState();
    _loadCoverImage();
  }

  @override
  void didUpdateWidget(EntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.hasImage != widget.entry.hasImage ||
        oldWidget.entry.id != widget.entry.id) {
      _loadCoverImage();
    }
  }

  Future<void> _loadCoverImage() async {
    if (!widget.entry.hasImage) {
      if (mounted && _coverImage != null) {
        setState(() => _coverImage = null);
      }
      return;
    }
    final file = await CoverImageService.getCoverImageFile(widget.entry.id);
    if (mounted) {
      setState(() => _coverImage = file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get first line of body, truncated
    final firstLine = widget.entry.body.isEmpty
        ? 'Empty entry'
        : widget.entry.body.split('\n').first;

    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final formattedDate = dateFormat.format(widget.entry.createdAt);

    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Cover image thumbnail
            if (_coverImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _coverImage!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
            ],
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firstLine,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
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
