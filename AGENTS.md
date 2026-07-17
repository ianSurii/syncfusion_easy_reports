# AGENTS.md

Purpose
- Minimal repo-level agent guide for contributors and automation agents working on this Flutter/Dart package.

Quick start (developer / agent)
- Get dependencies: `flutter pub get` (run from repo root and in `example/`).
- Static checks: `flutter analyze` and `dart format --set-exit-if-changed .`.
- Run tests: `flutter test`.
- Run example app: `cd example && flutter run -d <device>` (for macOS use `-d macos`).
- Package checks: `dart pub publish --dry-run` (for maintainers).

Key files & entry points
- Package manifest: [pubspec.yaml](pubspec.yaml) — package name, versions, dependencies.
- Library surface: [lib/syncfusion_easy_reports.dart](lib/syncfusion_easy_reports.dart).
- Example: [example/README.md](example/README.md) and the `example/` folder — run commands from there.
- Tests: [test/syncfusion_easy_reports_test.dart](test/syncfusion_easy_reports_test.dart).
- Legacy reference (do NOT use in new code): [old/](old/)

Notes, pitfalls & platform specifics
- This repository is a package (library), not an app. Focus CI and development on package workflows (analyze, test, example run, pub publish checks).
- macOS/desktop specifics: ensure Xcode and CocoaPods are installed. Run `flutter doctor` and resolve issues before running `example` on macOS.
- Native assets & plugin wiring: keep native assets under `assets/` and `example/macos/` intact; macOS builds may need additional Xcode settings.
- Avoid committing legacy snapshots: `old/` (or any `.old` folders) contains historical references only — do NOT import from or reintroduce `old/` into active code; move useful snippets to `docs/` or an `archive/` branch instead.
- Ignore generated build artifacts: ensure `build/`, `ios/Pods/`, and other generated folders are excluded in `.gitignore`.

How an AI agent should work here
- Run the quick checks below first (dependency install, analyze, test).
- Work in feature branches; do not apply or recommit contents from `old/`.
- If preserving material from `old/` is necessary, extract it to `docs/` with attribution before removal.
- For platform-affecting changes, include local verification: `cd example && flutter run -d <target>` and run unit tests.

Suggested CI checks
- `flutter pub get`
- `flutter analyze`
- `dart format --set-exit-if-changed .`
- `flutter test`
- (Optional) `dart pub publish --dry-run`

Contact / Maintainer notes
- If something in `old/` seems required, open an issue rather than reusing it directly.
