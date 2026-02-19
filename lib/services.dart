import 'dart:convert';
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
    required OffsetPrecision precision,
    required String chapterTitle,
    String? note,
  }) {
    final insight = Insight(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      bookId: bookId,
      timestampSeconds: timestampSeconds,
      precision: precision,
      chapterTitle: chapterTitle,
      note: note,
    );
    _insights.putIfAbsent(bookId, () => []);
    _insights[bookId]!.add(insight);
    return insight;
  }

  void updateInsight(String bookId, String insightId,
      {String? note, OffsetPrecision? precision}) {
    final list = _insights[bookId];
    if (list == null) return;
    final i = list.indexWhere((ins) => ins.id == insightId);
    if (i == -1) return;
    list[i] = list[i].copyWith(note: note, precision: precision);
  }

  void deleteInsight(String bookId, String insightId) {
    _insights[bookId]?.removeWhere((ins) => ins.id == insightId);
  }
}
