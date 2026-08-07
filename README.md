# Habitly

Build streaks you actually want to keep — Habitly is a habit tracker that celebrates consistency without ever shaming a missed day.

**Live web preview:** https://shaisolaris.github.io/flutter-habitly/

## Why Habitly

Most habit trackers turn a missed day into a guilt trip: your streak resets to zero and the app quietly makes you feel bad about it. Habitly is built around a simpler idea — progress isn't a single unbroken line, it's a pattern you can see and rebuild. A missed day is just a day with nothing checked in; the app never scolds you for it, and a grace period means your current streak doesn't evaporate the instant a new day starts before you've had a chance to check in.

## Screens

**Today** — the home screen. Only habits scheduled for today are shown, each with a big, satisfying check-in circle and its current streak. An animated progress ring at the top fills in as you check things off, so "how am I doing today" is answerable at a glance.

**Stats** — the payoff screen. Every habit gets its current streak, best-ever streak, and a completion-rate bar for the last four weeks, plus a GitHub-contributions-style heatmap showing consistency across all habits over the same period.

**New/Edit Habit** — a short form: a name, an icon picked from a curated grid of ~24 emoji, and a frequency — either every day or a specific set of weekdays. The same screen handles both creating a habit and editing (or deleting) an existing one.

**Settings** — a daily reminder time (native time picker), which day the week starts on (affects how the Stats heatmap is laid out), and a guarded "reset all data" action that requires confirmation before it wipes your habits and check-ins.

Navigation is a bottom bar across Today / Stats / Settings, with a floating action button on Today for adding a new habit.

## Architecture

```
lib/
  core/
    models/     Habit, CheckIn, AppSettings — plain, JSON-serializable data classes
    logic/      streaks.dart, heatmap.dart, date_math.dart — pure functions, no Flutter imports
    constants/  emoji options, weekday/month labels
    seed/       deterministic demo data for first launch
  data/
    habit_repository.dart   storage abstraction (interface + shared_preferences implementation)
    app_providers.dart      Riverpod providers and controllers that sit on top of the repository
  features/
    today/ stats/ edit_habit/ settings/   one screen + one widgets file per feature
    root/                                  bottom-navigation shell
```

**The repository pattern.** `HabitRepository` is an abstract class with one concrete implementation, `SharedPreferencesHabitRepository`. Every screen and controller talks to the *abstraction*, never to `shared_preferences` directly. That keeps persistence as an implementation detail: swapping local storage for something else later — or standing up a fake for a test — means writing a new class, not touching a single widget.

**A pure logic layer.** Streak calculation, completion rates, and the heatmap's week-bucketing all live in `core/logic/` as plain functions that take data in and return data out — no `BuildContext`, no providers, no Flutter SDK at all. That's deliberate: the trickiest part of a habit tracker isn't the UI, it's getting the *math* right (what happens to a streak on a day the habit isn't even scheduled? what about the day that hasn't finished yet?). Keeping that logic UI-independent is what makes it possible to unit test it exhaustively and trust the result, and it means the widgets are always thin — read state, call a pure function, render the result.

**Why Riverpod.** Habitly's state (habits, check-ins, settings) needs to be readable from four different screens and mutated from several more, survive screen navigation, and load asynchronously from disk on startup. Riverpod's `StateNotifierProvider` + `AsyncValue` combination models that directly: `AsyncValue.loading()/.data()/.error()` maps cleanly onto "reading from shared_preferences," controllers expose intention-revealing methods (`toggleCheckIn`, `addHabit`, `resetAllData`) instead of a generic setter, and providers are testable and overridable in isolation without a `BuildContext` in sight.

## Testing

```
test/
  streaks_test.dart      current/best streak math, including frequency-aware
                          habits (e.g. Mon/Wed/Fri) where the streak has to
                          skip over non-scheduled days without breaking, the
                          "today hasn't happened yet" grace period, and
                          completion-rate windows that fall partly or
                          entirely before a habit existed
  heatmap_test.dart       week-bucketing shape and boundaries: 4 full weeks,
                          Monday-start vs. Sunday-start alignment, days
                          before a habit's creation date, and days in the
                          future being marked distinctly from a missed day
  repository_test.dart    save/load round-trips for habits, check-ins, and
                          settings against shared_preferences, plus
                          first-run vs. already-seeded vs. reset behavior
```

Every expected value in `streaks_test.dart` and `heatmap_test.dart` was hand-traced against the algorithm (and cross-checked with an independent re-implementation) before being written down — the point of the pure logic layer is that its test suite can be this exhaustive without ever touching a widget.

Run the suite with:

```
flutter test
```

## Run it

```
flutter pub get
flutter run
```

To build the web version the same way CI does:

```
flutter build web --base-href /flutter-habitly/
```

## Tech

- Flutter 3.x, null-safe Dart, Material 3 (light + dark, seeded from `#10B981`)
- State management: `flutter_riverpod`
- Persistence: `shared_preferences`, storing habits/check-ins/settings as JSON
- CI: GitHub Actions runs `flutter analyze` and `flutter test` on every push, then builds and deploys the web app to GitHub Pages

## License

MIT © 2026 Shai A — see [LICENSE](LICENSE).

Built by [Shai](https://github.com/shaisolaris).
