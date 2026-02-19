import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../main.dart';

class InsightCaptureSheet extends StatefulWidget {
  final Insight insight;
  final bool autoAiSummary;
  final VoidCallback onSaved;
  final VoidCallback onDeleted;

  const InsightCaptureSheet({
    super.key,
    required this.insight,
    this.autoAiSummary = false,
    required this.onSaved,
    required this.onDeleted,
  });

  @override
  State<InsightCaptureSheet> createState() => _InsightCaptureSheetState();
}

class _InsightCaptureSheetState extends State<InsightCaptureSheet> {
  late OffsetPrecision _precision;
  final _noteController = TextEditingController();
  final _noteFocus = FocusNode();
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    _precision = widget.insight.precision;
    _noteController.text = widget.insight.note ?? '';
    if (widget.autoAiSummary) {
      // Trigger after the first frame so the sheet is visible.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateAiSummary();
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocus.dispose();
    super.dispose();
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

  void _save() {
    final note = _noteController.text.trim();
    insightService.updateInsight(
      widget.insight.bookId,
      widget.insight.id,
      note: note.isNotEmpty ? note : null,
      precision: _precision,
    );
    widget.onSaved();
    Navigator.pop(context);
  }

  void _delete() {
    insightService.deleteInsight(widget.insight.bookId, widget.insight.id);
    widget.onDeleted();
    Navigator.pop(context);
  }

  Future<void> _generateAiSummary() async {
    if (_aiLoading) return;
    setState(() => _aiLoading = true);
    final ts = widget.insight.timestampSeconds;
    final offset = _precision.offsetSeconds;
    try {
      final summary = await aiSummaryService.generateSummary(
        bookTitle: widget.insight.bookId,
        chapterTitle: widget.insight.chapterTitle,
        timestampSeconds: ts,
        rangeStartSeconds: (ts - offset).clamp(0, ts),
        rangeEndSeconds: ts + offset,
      );
      if (!mounted) return;
      _noteController.text = summary;
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = widget.insight.timestampSeconds;
    final offset = _precision.offsetSeconds;
    final rangeStart = (ts - offset).clamp(0, ts);
    final rangeEnd = ts + offset;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lightbulb_rounded,
                        color: Colors.amber, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Insight Captured',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatTime(ts)} · ${widget.insight.chapterTitle}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Variable Offset Precision
              Text(
                'Offset Precision',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Expand the capture range to account for reaction time',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),

              // Precision chips
              Row(
                children: OffsetPrecision.values.map((p) {
                  final selected = p == _precision;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _precision = p);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.amber.withAlpha(30)
                                : Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? Colors.amber
                                  : Colors.white.withAlpha(20),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                p.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      selected ? Colors.amber : Colors.white70,
                                ),
                              ),
                              if (p.offsetSeconds > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${p.offsetSeconds}s range',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: selected
                                        ? Colors.amber.withAlpha(180)
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Timeline visualization
              if (offset > 0) _buildTimelineVisualization(ts, rangeStart, rangeEnd),

              const SizedBox(height: 20),

              // Note field
              TextField(
                controller: _noteController,
                focusNode: _noteFocus,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: "What's the key takeaway?",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white.withAlpha(10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.amber, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 10),

              // AI Summary button
              GestureDetector(
                onTap: _aiLoading ? null : _generateAiSummary,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C3AED).withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF6C3AED).withAlpha(60),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_aiLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF6C3AED),
                          ),
                        )
                      else
                        const Icon(Icons.auto_awesome,
                            size: 16, color: Color(0xFF6C3AED)),
                      const SizedBox(width: 8),
                      Text(
                        _aiLoading
                            ? 'Generating summary…'
                            : 'AI Summary',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6C3AED),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.redAccent),
                      label: const Text('Discard',
                          style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: const Text('Save Insight',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineVisualization(int ts, int rangeStart, int rangeEnd) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Range labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(rangeStart),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              Text(
                _formatTime(ts),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatTime(rangeEnd),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Visual bar
          SizedBox(
            height: 8,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Full range bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Center marker
                    Positioned(
                      left: constraints.maxWidth / 2 - 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sync engine will search within this ${_precision.offsetSeconds * 2}s window',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
