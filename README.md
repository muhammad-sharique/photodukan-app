# photodukan-app

Flutter client for PhotoDukan. The app uses Firebase Auth for email/password sign-in and then sends the Firebase ID token to the Node.js API so the backend can verify it and sync the user into PostgreSQL via Prisma.

## What is implemented

- Firebase runtime bootstrap through `--dart-define` values instead of committing platform secrets.
- Email/password sign-in and registration with `firebase_auth`.
- Backend user sync call to `POST /auth/sync` after sign-in or registration.
- A fallback setup screen when Firebase config values are missing.

## Required setup

1. Create a Firebase project and enable Email/Password under Authentication.
2. Add Android, iOS, and web apps in Firebase as needed.
3. Run the app with your Firebase settings:

```bash
flutter run \
	--dart-define=FIREBASE_API_KEY=your-api-key \
	--dart-define=FIREBASE_APP_ID=your-app-id \
	--dart-define=FIREBASE_MESSAGING_SENDER_ID=your-sender-id \
	--dart-define=FIREBASE_PROJECT_ID=your-project-id \
	--dart-define=FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com \
	--dart-define=API_BASE_URL=http://10.0.2.2:3000
```

4. Use `http://localhost:3000` instead of `10.0.2.2` when running on web or desktop.
5. Point the app to the backend from the server repo before testing sign-in.
