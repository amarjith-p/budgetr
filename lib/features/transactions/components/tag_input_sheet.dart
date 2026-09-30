// lib/features/transactions/components/tag_input_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Extracts all unique tags from a list of raw comma-separated tag strings.
List<String> extractUniqueTags(Iterable<String?> rawTagStrings) {
  final seen = <String>{};
  final result = <String>[];
  for (final raw in rawTagStrings) {
    if (raw == null || raw.trim().isEmpty) continue;
    for (final tag in raw.split(',')) {
      final t = tag.trim().toLowerCase();
      if (t.isNotEmpty && seen.add(t)) result.add(t);
    }
  }
  return result;
}

/// Converts a List<String> of tags to the DB storage format (comma-separated).
String tagsToString(List<String> tags) => tags.join(',');

/// Parses DB storage string back to a list of tags.
List<String> parseTagString(String? raw) {
  if (raw == null || raw.trim().isEmpty) return [];
  return raw
      .split(',')
      .map((t) => t.trim().toLowerCase())
      .where((t) => t.isNotEmpty)
      .toList();
}

class TagColorHelper {
  static Color getColor(String tag, Brightness brightness) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.deepOrange,
      Colors.lightBlue,
      Colors.deepPurple,
    ];
    final hash = tag.hashCode.abs();
    final color = colors[hash % colors.length];
    return brightness == Brightness.dark ? color.shade300 : color.shade700;
  }
}

class TagInputSheet extends StatefulWidget {
  /// Currently selected tags (before opening the sheet).
  final List<String> selectedTags;

  /// All recently used tags across all transactions (for suggestions).
  final List<String> recentTags;

  const TagInputSheet({
    Key? key,
    required this.selectedTags,
    required this.recentTags,
  }) : super(key: key);

  /// Convenience static method to open the sheet and get the result.
  static Future<List<String>?> show(
    BuildContext context, {
    required List<String> selectedTags,
    required List<String> recentTags,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TagInputSheet(
        selectedTags: selectedTags,
        recentTags: recentTags,
      ),
    );
  }

  @override
  State<TagInputSheet> createState() => _TagInputSheetState();
}

class _TagInputSheetState extends State<TagInputSheet>
    with SingleTickerProviderStateMixin {
  late List<String> _selectedTags;
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _selectedTags = List<String>.from(widget.selectedTags);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final tag = raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_\-]'), '');
    if (tag.isEmpty) return;
    if (!_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _ctrl.clear();
        _query = '';
      });
      HapticFeedback.selectionClick();
    } else {
      // Already in list — just clear the input
      _ctrl.clear();
      setState(() => _query = '');
    }
  }

  void _removeTag(String tag) {
    HapticFeedback.selectionClick();
    setState(() => _selectedTags.remove(tag));
  }

  List<String> get _filteredSuggestions {
    final q = _query.trim().toLowerCase();
    final suggestions = widget.recentTags
        .where((t) => !_selectedTags.contains(t))
        .where((t) => q.isEmpty || t.contains(q))
        .take(q.isEmpty ? 5 : 16)
        .toList();
    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: mq.viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.tag_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ADD TAGS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Organize & filter your transactions',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  iconSize: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Selected tags ────────────────────────────────────────────────
            if (_selectedTags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedTags
                    .map((tag) => _SelectedTagChip(
                          tag: tag,
                          onRemove: () => _removeTag(tag),
                          theme: theme,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // ── Text input ───────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withOpacity(isDark ? 0.4 : 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? theme.colorScheme.primary.withOpacity(0.5)
                      : theme.dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Text(
                      '#',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focusNode,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Type a tag and press Enter…',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 14,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onChanged: (v) => setState(() => _query = v),
                      onSubmitted: _addTag,
                      // Only allow word chars, dashes, underscores
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9_\-]')),
                      ],
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () => _addTag(_ctrl.text),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ADD',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Suggestions ──────────────────────────────────────────────────
            if (_filteredSuggestions.isNotEmpty) ...[
              Text(
                _query.isEmpty ? 'RECENT TAGS' : 'SUGGESTIONS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filteredSuggestions
                    .map((tag) => _SuggestionChip(
                          tag: tag,
                          onTap: () => _addTag(tag),
                          theme: theme,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // ── Done button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context, _selectedTags),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _selectedTags.isEmpty
                          ? 'NO TAGS'
                          : 'SAVE ${_selectedTags.length} TAG${_selectedTags.length == 1 ? '' : 'S'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedTagChip extends StatelessWidget {
  final String tag;
  final VoidCallback onRemove;
  final ThemeData theme;

  const _SelectedTagChip({
    required this.tag,
    required this.onRemove,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final tagColor = TagColorHelper.getColor(tag, theme.brightness);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: tagColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6),
              child: Text(
                '#$tag',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 4, right: 8, top: 4, bottom: 4),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String tag;
  final VoidCallback onTap;
  final ThemeData theme;

  const _SuggestionChip({
    required this.tag,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final tagColor = TagColorHelper.getColor(tag, theme.brightness);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: tagColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: tagColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: 12,
              color: tagColor,
            ),
            const SizedBox(width: 4),
            Text(
              '#$tag',
              style: TextStyle(
                color: tagColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
