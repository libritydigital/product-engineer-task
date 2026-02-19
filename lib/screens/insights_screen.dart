import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/insight_capture_sheet.dart';

class InsightsScreen extends StatefulWidget {
  final Book book;

  const InsightsScreen({super.key, required this.book});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int? _seekResult;

  List<Insight> get _insights =>
      insightService.getInsights(widget.book.bookId);

  /// Group insights by chapter title, keeping chapter order from the book.
  Map<String, List<Insight>> get _groupedByChapter {
    final map = <String, List<Insight>>{};
    for (final ch in widget.book.chapters) {
      final matching =
          _insights.where((i) => i.chapterTitle == ch.title).toList();
      if (matching.isNotEmpty) {
        map[ch.title] = matching;
      }
    }
    return map;
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _onTapInsight(Insight insight) {
    _seekResult = insight.timestampSeconds;
    Navigator.pop(context, _seekResult);
  }

  void _deleteInsight(Insight insight) {
    insightService.deleteInsight(widget.book.bookId, insight.id);
    HapticFeedback.lightImpact();
    setState(() {});
  }

  void _editInsight(Insight insight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InsightCaptureSheet(
        insight: insight,
        onSaved: () => setState(() {}),
        onDeleted: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insights = _insights;
    final grouped = _groupedByChapter;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // ── App bar ──
          SliverAppBar(
            backgroundColor: const Color(0xFF1A1A1A),
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context, _seekResult),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  widget.book.title,
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              ],
            ),
            actions: [
              if (insights.isNotEmpty)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${insights.length}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Empty state ──
          if (insights.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lightbulb_outline,
                          size: 48, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No insights yet',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Catch Insight" while listening\nto save your aha moments',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          // ── Grouped insights ──
          if (insights.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            for (final entry in grouped.entries) ...[
              // Chapter header
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_outline,
                          size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Divider(
                          color: Colors.grey[800],
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Insight tiles for this chapter
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final insight = entry.value[index];
                      return _InsightCard(
                        insight: insight,
                        formatTime: _formatTime,
                        onTap: () => _onTapInsight(insight),
                        onEdit: () => _editInsight(insight),
                        onDismissed: () => _deleteInsight(insight),
                      );
                    },
                    childCount: entry.value.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final Insight insight;
  final String Function(int) formatTime;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDismissed;

  const _InsightCard({
    required this.insight,
    required this.formatTime,
    required this.onTap,
    required this.onEdit,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(insight.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withAlpha(40),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) => onDismissed(),
      child: Card(
        color: const Color(0xFF1E1E1E),
        margin: const EdgeInsets.only(bottom: 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timestamp badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formatTime(insight.timestampSeconds),
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (insight.note != null && insight.note!.isNotEmpty)
                        Text(
                          insight.note!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.3,
                          ),
                        )
                      else
                        Text(
                          'No note added',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _PrecisionChip(label: insight.precision.label),
                          const SizedBox(width: 8),
                          Text(
                            _timeAgo(insight.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Edit button
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: 18, color: Colors.grey[600]),
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _PrecisionChip extends StatelessWidget {
  final String label;
  const _PrecisionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
