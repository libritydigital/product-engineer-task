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
  final int offsetSeconds;
  final String? note;
  final String chapterTitle;
  final DateTime createdAt;

  Insight({
    required this.id,
    required this.bookId,
    required this.timestampSeconds,
    required this.offsetSeconds,
    this.note,
    required this.chapterTitle,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Insight copyWith({
    int? offsetSeconds,
    String? note,
  }) =>
      Insight(
        id: id,
        bookId: bookId,
        timestampSeconds: timestampSeconds,
        offsetSeconds: offsetSeconds ?? this.offsetSeconds,
        note: note ?? this.note,
        chapterTitle: chapterTitle,
        createdAt: createdAt,
      );

  int get startOffset =>
      (timestampSeconds - offsetSeconds).clamp(0, timestampSeconds);
  int get endOffset => timestampSeconds + offsetSeconds;

  /// Metadata payload for the Elredo Voice sync engine.
  Map<String, dynamic> toSyncMetadata() => {
        'insight_id': id,
        'book_id': bookId,
        'exact_timestamp': timestampSeconds,
        'offset_seconds': offsetSeconds,
        'range_start': startOffset,
        'range_end': endOffset,
        'chapter': chapterTitle,
        'note': note,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Recommended default offset in seconds.
const int kRecommendedOffsetSeconds = 15;

/// Default capture area size in seconds.
const int kDefaultCaptureAreaSeconds = 30;

/// User-configurable defaults for quick-capture (volume button / headphone).
class CaptureSettings {
  int defaultOffsetSeconds;
  int captureAreaSeconds;
  bool showCaptureSheet;
  bool volumeCaptureEnabled;
  bool autoAiSummary;

  CaptureSettings({
    this.defaultOffsetSeconds = kRecommendedOffsetSeconds,
    this.captureAreaSeconds = kDefaultCaptureAreaSeconds,
    this.showCaptureSheet = true,
    this.volumeCaptureEnabled = true,
    this.autoAiSummary = false,
  });
}
