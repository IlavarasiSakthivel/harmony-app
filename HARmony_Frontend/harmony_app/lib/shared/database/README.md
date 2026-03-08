# Local database (Floor)

The app uses a stub `app_database.g.dart` so it compiles without running Floor's code generator. `AppDatabase.open()` will throw if called until the real code is generated.

To generate the real Floor code (optional): add `floor_generator: ^1.4.2` back to `dev_dependencies` in pubspec.yaml when it is compatible with your Dart/Flutter version, then run:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

(floor_generator was removed from pubspec because it conflicted with flutter_riverpod + build_runner on Dart 3.11.)
