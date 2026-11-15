import 'package:flutter/widgets.dart';

/// Home-page chapter progress for the ChapterIndicator (P15).
/// Chapters 0..2 (About, Achievements, Projects).
///
/// Each pinned chapter calls [report] with its own scrubbed progress. The
/// active chapter is the highest chapter that has started (p > 0), falling
/// back to chapter 0, so scrolling back up hands the bar back naturally.
class StoryProgress extends ChangeNotifier {
  /// Number of chapters tracked.
  static const chapterCount = 3;

  /// Minimum change in [activeProgress] that triggers a notification.
  static const _epsilon = 0.002;

  final List<double> _chapters = List<double>.filled(chapterCount, 0.0);
  int _active = 0;
  double _activeProgress = 0.0;
  bool _visible = true;

  /// Index of the chapter currently being scrubbed (0..2).
  int get active => _active;

  /// Progress (0..1) within [active].
  double get activeProgress => _activeProgress;

  /// Progress (0..1) of an arbitrary chapter.
  double progressOf(int chapter) => _chapters[chapter];

  /// Whether the indicator is shown (slides out when false).
  bool get visible => _visible;
  set visible(bool v) {
    if (v == _visible) return;
    _visible = v;
    notifyListeners();
  }

  /// Reports [p] (0..1) within [chapter]. Notifies only when the active chapter
  /// changes, the progress moves by more than 0.002, or it reaches 0 / 1.
  void report(int chapter, double p) {
    if (chapter < 0 || chapter >= chapterCount) return;
    final clamped = p.isNaN ? 0.0 : p.clamp(0.0, 1.0);
    _chapters[chapter] = clamped;

    var active = 0;
    for (var i = chapterCount - 1; i >= 0; i--) {
      if (_chapters[i] > 0) {
        active = i;
        break;
      }
    }
    final value = _chapters[active];
    final reachedEnd =
        (value == 0.0 || value == 1.0) && value != _activeProgress;
    if (active != _active ||
        (value - _activeProgress).abs() > _epsilon ||
        reachedEnd) {
      _active = active;
      _activeProgress = value;
      notifyListeners();
    }
  }
}

/// Provides a [StoryProgress] to the home page subtree.
class StoryProgressScope extends InheritedNotifier<StoryProgress> {
  const StoryProgressScope({
    super.key,
    required StoryProgress progress,
    required super.child,
  }) : super(notifier: progress);

  /// Read-only lookup — does NOT register a dependency (chapters report into
  /// it; they must not rebuild when it changes).
  static StoryProgress? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoryProgressScope>()?.notifier;

  /// Lookup that rebuilds [context] whenever the progress notifies.
  static StoryProgress? watch(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<StoryProgressScope>()
      ?.notifier;
}
