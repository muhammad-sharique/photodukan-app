# photodukan-app

Flutter client for PhotoDukan. The app uses Firebase Auth for email/password sign-in and then sends the Firebase ID token to the Node.js API so the backend can verify it and sync the user into PostgreSQL via Prisma.

## What is implemented

- Firebase runtime bootstrap through the generated `lib/firebase_options.dart` file.
- Email/password sign-in and registration with `firebase_auth`.
- Backend user sync call to `POST /auth/sync` after sign-in or registration.
- A fallback setup screen when Firebase cannot initialize for the current platform.

## Required setup

1. Create a Firebase project and enable Email/Password under Authentication.
2. Register the Android app with package name `com.photodukan.app` in Firebase project settings.
3. Add your Android signing fingerprints for that app before testing email/password auth.

	Debug keystore fingerprints on this machine:

	- SHA-1: `C5:8B:DF:B6:18:3E:AD:ED:E1:1E:C1:50:A5:39:0A:51:1A:12:F4:31`
	- SHA-256: `48:3B:4B:EC:FC:07:03:E4:25:96:54:1D:DE:F9:DD:AD:2C:2C:F0:EA:7F:85:84:39:77:C8:1D:FB:7B:42:0B:29`

4. Download a fresh `android/app/google-services.json` after adding fingerprints.
5. Generate `lib/firebase_options.dart` with FlutterFire CLI for your project and platforms.
6. Run the app with your backend URL:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

7. You can also load that value from a file with `--dart-define-from-file=.env`.
8. Use `http://localhost:3000` on web or desktop, and your machine's LAN IP on a physical Android device.
9. Point the app to the backend from the server repo before testing sign-in.

If Android sign-up or sign-in fails with `CONFIGURATION_NOT_FOUND` or reCAPTCHA-related internal errors, the package name and SHA fingerprints in Firebase do not match the app build you are running.
