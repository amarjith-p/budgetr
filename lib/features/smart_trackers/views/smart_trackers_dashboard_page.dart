import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/components/premium_empty_state.dart';
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/smart_tracker_provider.dart';
import 'smart_tracker_builder_page.dart';
import 'smart_tracker_detail_page.dart';

class _MatchPosition {
  final int cardIndex;
  final String field;
  final int occurrenceIndex;
  _MatchPosition(this.cardIndex, this.field, this.occurrenceIndex);
}

class SmartTrackersDashboardPage extends ConsumerStatefulWidget {
  const SmartTrackersDashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SmartTrackersDashboardPage> createState() =>
      _SmartTrackersDashboardPageState();
}

class _SmartTrackersDashboardPageState
    extends ConsumerState<SmartTrackersDashboardPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<int, GlobalKey> _rowKeys = {};
  Timer? _debounce;
  List<_MatchPosition> _matchPositions = [];
  int _currentMatchIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  int _countOccurrences(String text, String q) {
    if (q.isEmpty || text.isEmpty) return 0;
    int count = 0;
    int index = 0;
    while (true) {
      index = text.toLowerCase().indexOf(q, index);
      if (index == -1) break;
      count++;
      index += q.length;
    }
    return count;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) {
        setState(() {
          _matchPositions.clear();
          _currentMatchIndex = 0;
        });
        return;
      }

      final templates =
          ref.read(smartTrackerTemplatesProvider).asData?.value ?? [];
      final List<_MatchPosition> matches = [];

      for (int i = 0; i < templates.length; i++) {
        final t = templates[i];

        // Check Title
        int titleOccurrences = _countOccurrences(t.name, q);
        for (int k = 0; k < titleOccurrences; k++) {
          matches.add(_MatchPosition(i, 'title', k));
        }

        // Check Subtitle
        int subtitleOccurrences = _countOccurrences('Tap to view records', q);
        for (int k = 0; k < subtitleOccurrences; k++) {
          matches.add(_MatchPosition(i, 'subtitle', k));
        }
      }

      setState(() {
        _matchPositions = matches;
        _currentMatchIndex = 0;
      });

      if (_matchPositions.isNotEmpty) {
        _scrollToCurrentMatch();
      }
    });
  }

  void _nextMatch() {
    if (_matchPositions.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchPositions.length;
    });
    _scrollToCurrentMatch();
  }

  void _prevMatch() {
    if (_matchPositions.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matchPositions.length) %
          _matchPositions.length;
    });
    _scrollToCurrentMatch();
  }

  void _scrollToCurrentMatch() {
    if (_matchPositions.isEmpty || !_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final targetIndex = _matchPositions[_currentMatchIndex].cardIndex;
      final key = _rowKeys[targetIndex];

      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          alignment: 0.5,
        );
      } else {
        final estimatedRowHeight = 90.0;
        double targetOffset = targetIndex * estimatedRowHeight;

        final maxScroll = _scrollController.position.maxScrollExtent;
        if (targetOffset > maxScroll) targetOffset = maxScroll;

        _scrollController
            .animateTo(
              targetOffset,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            )
            .then((_) {
              final builtKey = _rowKeys[targetIndex];
              if (builtKey?.currentContext != null) {
                Scrollable.ensureVisible(
                  builtKey!.currentContext!,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOutCubic,
                  alignment: 0.5,
                );
              }
            });
      }
    });
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    ThemeData theme,
    bool isCurrentCard,
    bool isCurrentField,
    int activeOccurrenceIndex,
    TextStyle baseStyle,
  ) {
    final q = query.trim();
    if (q.isEmpty) return Text(text, style: baseStyle);

    final lowerText = text.toLowerCase();
    final lowerQuery = q.toLowerCase();

    List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch = lowerText.indexOf(lowerQuery, start);
    int currentOccurrence = 0;

    if (indexOfMatch == -1) return Text(text, style: baseStyle);

    while (indexOfMatch != -1) {
      if (indexOfMatch > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfMatch)));
      }

      bool isThisSpecificMatch =
          isCurrentCard &&
          isCurrentField &&
          currentOccurrence == activeOccurrenceIndex;

      spans.add(
        TextSpan(
          text: text.substring(indexOfMatch, indexOfMatch + lowerQuery.length),
          style: TextStyle(
            backgroundColor: isThisSpecificMatch
                ? Colors.orangeAccent.shade400
                : theme.colorScheme.primary.withOpacity(0.3),
            color: isThisSpecificMatch
                ? Colors.black
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
      start = indexOfMatch + lowerQuery.length;
      indexOfMatch = lowerText.indexOf(lowerQuery, start);
      currentOccurrence++;
    }

    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final templatesAsync = ref.watch(smartTrackerTemplatesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModernAppBar(
        title: 'Smart Trackers',
        subtitle: 'CUSTOM MODULES',
        leadingIcon: Icons.arrow_back_rounded,
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SmartTrackerBuilderPage()),
          );
        },
        icon: Icons.add_rounded,
        label: 'Build',
      ),
      body: Column(
        children: [
          // --- INTELLIGENT COMPACT SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spacingLg,
              DesignTokens.spacingMd,
              DesignTokens.spacingLg,
              0,
            ),
            child: Container(
              height: 48,
              padding: const EdgeInsets.only(left: 16, right: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search trackers...',
                        border: InputBorder.none,
                        isDense: true,
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.5,
                          ),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty) ...[
                    if (_matchPositions.isNotEmpty) ...[
                      Text(
                        '${_currentMatchIndex + 1}/${_matchPositions.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: _prevMatch,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2.0,
                            vertical: 6.0,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 22,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _nextMatch,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2.0,
                            vertical: 6.0,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 14,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: theme.dividerColor.withOpacity(0.5),
                      ),
                    ],
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _searchCtrl.clear();
                        _onSearchChanged('');
                        FocusScope.of(context).unfocus();
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 6.0,
                        ),
                        child: Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          Expanded(
            child: templatesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (templates) {
                if (templates.isEmpty) {
                  return const PremiumEmptyState(
                    title: 'No Trackers Yet',
                    subtitle:
                        'Build your first Smart Tracker to monitor anything you want, entirely on your terms.',
                    icon: Icons.extension_rounded,
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(DesignTokens.spacingLg),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    final rowKey = _rowKeys.putIfAbsent(
                      index,
                      () => GlobalKey(),
                    );

                    final isMatch = _matchPositions.any(
                      (m) => m.cardIndex == index,
                    );
                    final isCurrentMatch =
                        _matchPositions.isNotEmpty &&
                        _matchPositions[_currentMatchIndex].cardIndex == index;

                    return Padding(
                      key: rowKey,
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: BoxySlidableCard(
                        key: ValueKey(template.id),
                        onEdit: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SmartTrackerBuilderPage(
                                existingTemplate: template,
                              ),
                            ),
                          );
                        },
                        onDelete: () {
                          ConfirmationBottomSheet.show(
                            context,
                            title: 'Delete Smart Tracker?',
                            description:
                                'This will permanently delete the "${template.name}" tracker and ALL associated data records. This cannot be undone.',
                            confirmText: 'DELETE EVERYTHING',
                            isDestructive: true,
                            onConfirm: () {
                              ref
                                  .read(smartTrackerActionProvider.notifier)
                                  .deleteTrackerTemplate(template.id);
                            },
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SmartTrackerDetailPage(template: template),
                              ),
                            );
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isCurrentMatch
                                  ? theme.colorScheme.primary.withOpacity(0.1)
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: isMatch
                                  ? Border.all(
                                      color: isCurrentMatch
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.primary
                                                .withOpacity(0.4),
                                      width: isCurrentMatch ? 2.0 : 1.0,
                                    )
                                  : Border.all(color: Colors.transparent),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.dynamic_form_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildHighlightedText(
                                        template.name,
                                        _searchCtrl.text,
                                        theme,
                                        isCurrentMatch,
                                        isCurrentMatch &&
                                            _matchPositions[_currentMatchIndex]
                                                    .field ==
                                                'title',
                                        isCurrentMatch &&
                                                _matchPositions[_currentMatchIndex]
                                                        .field ==
                                                    'title'
                                            ? _matchPositions[_currentMatchIndex]
                                                  .occurrenceIndex
                                            : -1,
                                        TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _buildHighlightedText(
                                        'Tap to view records',
                                        _searchCtrl.text,
                                        theme,
                                        isCurrentMatch,
                                        isCurrentMatch &&
                                            _matchPositions[_currentMatchIndex]
                                                    .field ==
                                                'subtitle',
                                        isCurrentMatch &&
                                                _matchPositions[_currentMatchIndex]
                                                        .field ==
                                                    'subtitle'
                                            ? _matchPositions[_currentMatchIndex]
                                                  .occurrenceIndex
                                            : -1,
                                        TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
