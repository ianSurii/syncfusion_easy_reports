Prefer idiomatic Dart and Flutter patterns in code and tests. When suggesting changes:

- Avoid importing or reusing code from the `old/` directory; it's for historical reference only.
- Keep the public API stable; prefer adding new methods over breaking changes.
- Add or update tests for behavioral changes; run `flutter test` locally.
- Run `dart format --set-exit-if-changed .` before proposing patches.
