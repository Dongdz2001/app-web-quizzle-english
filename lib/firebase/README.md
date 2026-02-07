# Firebase Configuration

This folder contains Firebase configuration and initialization files for the Quizzle English App.

## Files

- **firebase_config.dart**: Contains Firebase configuration constants (API keys, project ID, etc.)
- **firebase_init.dart**: Contains Firebase initialization logic and helper functions

## Usage

Firebase is automatically initialized in `main.dart` when the app starts. The initialization happens before the app runs, ensuring Firebase services are available throughout the app lifecycle.

## Configuration

All Firebase configuration values are stored in `firebase_config.dart`. To update configuration:

1. Open `firebase_config.dart`
2. Update the constants with your Firebase project values
3. Restart the app

## Services

Currently configured:
- **Firebase Analytics**: Automatically initialized and available via `getAnalytics()`

## Notes

- Firebase initialization errors are caught and logged, but won't crash the app
- For web platform, Firebase SDK is automatically loaded via Flutter Firebase packages
- Configuration values are read-only constants for security
