import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models.dart';
import '../widgets/insight_capture_sheet.dart';
import 'insights_screen.dart';

class PlayerScreen extends StatefulWidget {
  final Book book;
  const PlayerScreen({super.key, required this.book});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  int _positionSeconds = 0;
  bool _isPlaying = false;
  Timer? _timer;
  double _playbackSpeed = 1.0;
  final OffsetPrecision _precision = OffsetPrecision.medium;
  bool _isDragging = false;
  double _dragValue = 0;

  late AnimationController _captureAnimController;
  late Animation<double> _captureAnim;

  @override
  void initState() {
    super.initState();
    _captureAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _captureAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
          parent: _captureAnimController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _captureAnimController.dispose();
    super.dispose();
  }

  // ── Playback ──

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
      _isPlaying ? _startTimer() : _timer?.cancel();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    final intervalMs = (1000 / _playbackSpeed).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (_positionSeconds < widget.book.totalDurationSeconds) {
        setState(() => _positionSeconds++);
      } else {
        _timer?.cancel();
        setState(() => _isPlaying = false);
      }
    });
  }

  void _seek(double value) =>
      setState(() => _positionSeconds = value.toInt());

  void _skip(int seconds) {
    setState(() {
      _positionSeconds = (_positionSeconds + seconds)
          .clamp(0, widget.book.totalDurationSeconds);
    });
  }

  void _previousChapter() {
    Chapter? prev;
    for (final ch in widget.book.chapters) {
      if (ch.startTime < _positionSeconds - 2) prev = ch;
    }
    setState(() => _positionSeconds = prev?.startTime ?? 0);
  }

  void _nextChapter() {
    for (final ch in widget.book.chapters) {
      if (ch.startTime > _positionSeconds) {
        setState(() => _positionSeconds = ch.startTime);
        return;
      }
    }
  }

  void _cycleSpeed() {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final idx = speeds.indexOf(_playbackSpeed);
    setState(() {
      _playbackSpeed = speeds[(idx + 1) % speeds.length];
      if (_isPlaying) _startTimer();
    });
  }

  // ── Insight Catcher ──

  void _captureInsight() {
    HapticFeedback.mediumImpact();
    _captureAnimController.forward().then((_) {
      _captureAnimController.reverse();
    });

    final chapter = widget.book.currentChapter(_positionSeconds);
    final insight = insightService.addInsight(
      bookId: widget.book.bookId,
      timestampSeconds: _positionSeconds,
      precision: _precision,
      chapterTitle: chapter.title,
    );

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

  void _openInsightsScreen() async {
    final seekTo = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => InsightsScreen(book: widget.book),
      ),
    );
    if (seekTo != null) {
      setState(() => _positionSeconds = seekTo);
    } else {
      // Refresh in case insights were edited/deleted
      setState(() {});
    }
  }

  // ── Helpers ──

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

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final chapter = widget.book.currentChapter(_positionSeconds);
    final insights = insightService.getInsights(widget.book.bookId);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A4638),
              Color(0xFF2A2820),
              Color(0xFF111111),
              Colors.black,
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(insights),
              const Spacer(flex: 1),
              _buildCoverArt(),
              const SizedBox(height: 28),
              _buildTitleSection(chapter),
              const Spacer(flex: 1),
              _buildSlider(insights),
              const SizedBox(height: 20),
              _buildTransportControls(),
              const SizedBox(height: 14),
              _buildCaptureButton(),
              const SizedBox(height: 14),
              _buildBottomBar(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(List<Insight> insights) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 32),
            color: Colors.white,
            onPressed: () => Navigator.pop(context),
          ),
          Row(
            children: [
              // Insights badge
              if (insights.isNotEmpty)
                GestureDetector(
                  onTap: _openInsightsScreen,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lightbulb,
                            size: 15, color: Colors.amber),
                        const SizedBox(width: 5),
                        Text(
                          '${insights.length}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.more_horiz, size: 28),
                color: Colors.white,
                onPressed: _openInsightsScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoverArt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(130),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.book.coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: const Color(0xFFF5F0E8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.headphones, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        widget.book.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(Chapter chapter) {
    return Column(
      children: [
        Text(
          chapter.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.book.author,
          style: TextStyle(fontSize: 16, color: Colors.white.withAlpha(180)),
        ),
      ],
    );
  }

  Widget _buildSlider(List<Insight> insights) {
    final position =
        _isDragging ? _dragValue : _positionSeconds.toDouble();
    final total = widget.book.totalDurationSeconds.toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              return SizedBox(
                height: 30,
                child: Stack(
                  children: [
                    // Insight markers on the track
                    for (final insight in insights)
                      Positioned(
                        left: (insight.timestampSeconds / total) * trackWidth -
                            4,
                        top: 11,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.amber.withAlpha(200),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withAlpha(60),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Slider
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 16),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withAlpha(60),
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withAlpha(30),
                      ),
                      child: Slider(
                        min: 0,
                        max: total,
                        value: position.clamp(0, total),
                        onChangeStart: (v) {
                          setState(() {
                            _isDragging = true;
                            _dragValue = v;
                          });
                        },
                        onChanged: (v) => setState(() => _dragValue = v),
                        onChangeEnd: (v) {
                          _seek(v);
                          setState(() => _isDragging = false);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(
                      _isDragging ? _dragValue.toInt() : _positionSeconds),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withAlpha(180),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  _formatTime(widget.book.totalDurationSeconds),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withAlpha(180),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          iconSize: 32,
          color: Colors.white,
          onPressed: _previousChapter,
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.replay_30),
          iconSize: 36,
          color: Colors.white,
          onPressed: () {
            HapticFeedback.lightImpact();
            _skip(-30);
          },
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _togglePlayback();
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(20),
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 42,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.forward_30),
          iconSize: 36,
          color: Colors.white,
          onPressed: () {
            HapticFeedback.lightImpact();
            _skip(30);
          },
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded),
          iconSize: 32,
          color: Colors.white,
          onPressed: _nextChapter,
        ),
      ],
    );
  }

  Widget _buildCaptureButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: ScaleTransition(
        scale: _captureAnim,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _captureInsight,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withAlpha(60),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb_rounded,
                      color: Colors.black87, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Catch Insight',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _cycleSpeed();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_playbackSpeed}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.nightlight_round_outlined),
            color: Colors.white.withAlpha(180),
            iconSize: 24,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

