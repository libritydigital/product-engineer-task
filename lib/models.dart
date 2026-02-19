/// Configurable precision for insight timestamps.
/// Accounts for human reaction time — the user taps *after* hearing the insight.
/// The sync engine uses [startOffset, endOffset] to locate the relevant segment.
enum OffsetPrecision {
  exact(0, 'Exact'),
  low(5, '±5s'),
  medium(15, '±15s'),
  high(30, '±30s');

  final int offsetSeconds;
  final String label;
  const OffsetPrecision(this.offsetSeconds, this.label);
}

class Chapter {
  final int id;
  final String title;
  final int startTime;

  Chapter({required this.id, required this.title, required this.startTime});

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: json['id'],
        title: json['title'],
        startTime: json['start_time'],
      );
}

class Book {
  final String bookId;
  final String title;
  final String author;
  final int totalDurationSeconds;
  final String coverUrl;
  final String audioPreviewUrl;
  final List<Chapter> chapters;

  Book({
    required this.bookId,
    required this.title,
    required this.author,
    required this.totalDurationSeconds,
    required this.coverUrl,
    required this.audioPreviewUrl,
    required this.chapters,
  });

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        bookId: json['book_id'],
        title: json['title'],
        author: json['author'],
        totalDurationSeconds: json['total_duration_seconds'],
        coverUrl: json['cover_url'],
        audioPreviewUrl: json['audio_preview_url'],
        chapters: (json['chapters'] as List)
            .map((c) => Chapter.fromJson(c))
            .toList(),
      );

  Chapter currentChapter(int positionSeconds) {
    Chapter current = chapters.first;
    for (final chapter in chapters) {
      if (positionSeconds >= chapter.startTime) {
        current = chapter;
      } else {
        break;
      }
    }
    return current;
  }
}

class Insight {
  final String id;
  final String bookId;
  final int timestampSeconds;
  final OffsetPrecision precision;
  final String? note;
  final String chapterTitle;
  final DateTime createdAt;

  Insight({
    required this.id,
    required this.bookId,
    required this.timestampSeconds,
    required this.precision,
    this.note,
    required this.chapterTitle,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Insight copyWith({
    OffsetPrecision? precision,
    String? note,
  }) =>
      Insight(
        id: id,
        bookId: bookId,
        timestampSeconds: timestampSeconds,
        precision: precision ?? this.precision,
        note: note ?? this.note,
        chapterTitle: chapterTitle,
        createdAt: createdAt,
      );

  int get startOffset =>
      (timestampSeconds - precision.offsetSeconds).clamp(0, timestampSeconds);
  int get endOffset => timestampSeconds + precision.offsetSeconds;

  /// Metadata payload for the Elredo Voice sync engine.
  Map<String, dynamic> toSyncMetadata() => {
        'insight_id': id,
        'book_id': bookId,
        'exact_timestamp': timestampSeconds,
        'offset_precision': precision.name,
        'range_start': startOffset,
        'range_end': endOffset,
        'chapter': chapterTitle,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };
}

/// User-configurable defaults for quick-capture (volume button / headphone).
class CaptureSettings {
  OffsetPrecision defaultPrecision;
  bool showCaptureSheet;
  bool volumeCaptureEnabled;
  bool autoAiSummary;

  CaptureSettings({
    this.defaultPrecision = OffsetPrecision.medium,
    this.showCaptureSheet = true,
    this.volumeCaptureEnabled = true,
    this.autoAiSummary = false,
  });
}
