import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'models.dart';

class BookService {
  List<Book>? _cache;

  Future<List<Book>> loadBooks() async {
    if (_cache != null) return _cache!;
    final jsonString = await rootBundle.loadString('assets/books.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _cache = jsonList.map((j) => Book.fromJson(j)).toList();
    return _cache!;
  }
}

class InsightService {
  final Map<String, List<Insight>> _insights = {};

  List<Insight> getInsights(String bookId) =>
      List.unmodifiable(_insights[bookId] ?? []);

  Insight addInsight({
    required String bookId,
    required int timestampSeconds,
    required int offsetSeconds,
    required String chapterTitle,
    String? note,
  }) {
    final insight = Insight(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      bookId: bookId,
      timestampSeconds: timestampSeconds,
      offsetSeconds: offsetSeconds,
      chapterTitle: chapterTitle,
      note: note,
    );
    _insights.putIfAbsent(bookId, () => []);
    _insights[bookId]!.add(insight);
    return insight;
  }

  void updateInsight(String bookId, String insightId,
      {String? note, int? offsetSeconds}) {
    final list = _insights[bookId];
    if (list == null) return;
    final i = list.indexWhere((ins) => ins.id == insightId);
    if (i == -1) return;
    list[i] = list[i].copyWith(note: note, offsetSeconds: offsetSeconds);
  }

  void deleteInsight(String bookId, String insightId) {
    _insights[bookId]?.removeWhere((ins) => ins.id == insightId);
  }
}

class CaptureSettingsService {
  final CaptureSettings _settings = CaptureSettings();

  CaptureSettings get settings => _settings;

  void update({
    int? defaultOffsetSeconds,
    int? captureAreaSeconds,
    bool? showCaptureSheet,
    bool? volumeCaptureEnabled,
    bool? autoAiSummary,
  }) {
    if (defaultOffsetSeconds != null) {
      _settings.defaultOffsetSeconds = defaultOffsetSeconds;
    }
    if (captureAreaSeconds != null) {
      _settings.captureAreaSeconds = captureAreaSeconds;
    }
    if (showCaptureSheet != null) _settings.showCaptureSheet = showCaptureSheet;
    if (volumeCaptureEnabled != null) {
      _settings.volumeCaptureEnabled = volumeCaptureEnabled;
    }
    if (autoAiSummary != null) _settings.autoAiSummary = autoAiSummary;
  }
}

/// Mock AI service that simulates summarising an audio segment.
/// In production this would transcribe [startOffset..endOffset] and call an LLM.
class AiSummaryService {
  static final _rng = Random();

  static const _templates = [
    'The author explains how {topic} can fundamentally change the way we approach {area}, emphasizing the importance of {action}.',
    'Key point: {topic} is not about doing more — it\'s about focusing on {area} and consistently {action}.',
    'A practical framework for {topic} is introduced here: start with {area}, then build momentum through {action}.',
    'The core argument is that most people misunderstand {topic}. Real progress comes from {area} combined with deliberate {action}.',
    'An actionable insight on {topic}: prioritise {area} over perfection, and use {action} as your daily compass.',
  ];

  static const _topics = [
    'deep work',
    'energy management',
    'habit stacking',
    'intentional rest',
    'creative output',
    'compound growth',
    'mindful productivity',
    'flow state',
  ];

  static const _areas = [
    'small daily rituals',
    'your personal energy cycles',
    'eliminating decision fatigue',
    'meaningful progress',
    'sustainable routines',
    'deliberate practice',
    'clarity of purpose',
  ];

  static const _actions = [
    'regular reflection',
    'time-blocking your priorities',
    'protecting your peak hours',
    'saying no to low-value tasks',
    'building systems over goals',
    'embracing strategic laziness',
  ];

  /// Returns a plausible AI-generated summary after a simulated delay.
  Future<String> generateSummary({
    required String bookTitle,
    required String chapterTitle,
    required int timestampSeconds,
    required int rangeStartSeconds,
    required int rangeEndSeconds,
  }) async {
    // Simulate network + inference latency (1–2.5 s).
    await Future.delayed(
      Duration(milliseconds: 1000 + _rng.nextInt(1500)),
    );

    final template = _templates[_rng.nextInt(_templates.length)];
    final topic = _topics[_rng.nextInt(_topics.length)];
    final area = _areas[_rng.nextInt(_areas.length)];
    final action = _actions[_rng.nextInt(_actions.length)];

    return template
        .replaceAll('{topic}', topic)
        .replaceAll('{area}', area)
        .replaceAll('{action}', action);
  }
}
