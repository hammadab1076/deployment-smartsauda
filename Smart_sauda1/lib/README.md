Pre-submission checklist:
1. Run these commands:
   flutter pub get
   flutter pub clean
   dart format .
   dart fix --apply
   dart analyze

2. Ensure zero analyzer warnings and issues.

3. Remove build/ and .dart_tool/ from the ZIP.
4. Include only lib/, pubspec.yaml, assets/, and other necessary files.
