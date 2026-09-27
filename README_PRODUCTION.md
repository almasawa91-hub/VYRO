# VYRO Production Build

## Authentication
The app uses Firebase Authentication with:
- Email/password
- Google Sign-In

Phone/OTP authentication is not used.

## Firebase configuration
`android/app/google-services.json` must belong to the Firebase Android app whose package is `com.vyro.vyro`.
For Google Sign-In, the SHA-1/SHA-256 fingerprints of every signing key used to build the app must be registered in Firebase:
- CI debug key for debug/diagnostic builds
- release key for production builds

Do not commit release keystores or `android/key.properties`.

## Cloud release
GitHub Actions expects these repository secrets:
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`

The workflow produces both:
- signed APK
- signed AAB

## Important Firebase notes
Deploy `firestore.rules` and `storage.rules` from the Firebase project. Composite indexes may be required for some Firestore queries; Firebase will provide the index creation link when a query needs one.

## Calls
The current project contains call signaling/data structures and a call screen, but it does not contain a WebRTC/RTC media SDK. Therefore the build does not pretend that a phone/video call is operational when it is not. A real call provider (WebRTC, LiveKit, Agora, etc.) must be selected before claiming audio/video transport is complete.

## Current implemented modules
- Email/Google authentication
- Profile creation and profiles
- Public feed and post creation with image upload
- Post reactions/comments backend
- Marketplace listing and product creation with image upload
- User search
- Notifications reader
- Follow/friend backend
- Chat list, text messaging and read state
- Video upload backend and upload UI
- Stories reader
- Settings/sign-out/account deletion flow
- Firebase Firestore/Storage security rules
- Cloud APK/AAB workflow with release signing
