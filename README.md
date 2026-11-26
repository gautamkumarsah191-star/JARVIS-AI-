# JARVIS — Improved Android Starter

A bilingual (Hindi + English) Flutter assistant UI with an xAI-compatible Node.js backend.

## Important
- This is a source project, not a prebuilt APK.
- Flutter/Android SDK builds must be run on a computer with the Flutter SDK and Android toolchain installed.
- The backend API key belongs only in `backend/.env`. Never put it in Flutter code or share it in chat.
- The backend model is deliberately configured through `XAI_MODEL`; choose a model currently enabled in your xAI account.
- Voice recognition and voice quality depend on the Android device, its speech services, and installed TTS voices.
- Microphone activation is manual. There is no always-on listening or hidden recording.

## Project layout
- `app/` Flutter Android app
- `backend/` Node.js API proxy

## 1. Configure backend
```bash
cd backend
cp .env.example .env
```
Edit `.env` privately:
```env
PORT=8787
XAI_API_KEY=your_private_xai_key
XAI_MODEL=your_enabled_xai_model
ALLOWED_ORIGINS=
```
Install and run:
```bash
npm install
npm start
```
Check `http://localhost:8787/health`.

Deploy the backend to a host with HTTPS for real phone use. Do not expose a development server to the public internet without HTTPS and appropriate access controls.

## 2. Configure Flutter app
Edit `app/lib/config/app_config.dart`:
- Android emulator: `http://10.0.2.2:8787`
- Physical phone on same Wi-Fi: `http://YOUR_COMPUTER_LAN_IP:8787` (development only)
- Production: your backend HTTPS URL

Then:
```bash
cd app
# Generate any missing platform wrapper files with your installed Flutter SDK.
flutter create --platforms=android .
flutter pub get
flutter analyze
flutter run
```
Build APK:
```bash
flutter build apk --release
```
APK output:
`app/build/app/outputs/flutter-apk/app-release.apk`

## 3. Android permissions
The app requests microphone access only when you tap the microphone button. Android may also require speech recognition services to be installed/enabled.

## 4. Troubleshooting
- `Backend API key is not configured`: add `XAI_API_KEY` to backend `.env` and restart.
- `XAI_MODEL is not configured`: set a model name currently available in your xAI account.
- `Could not reach backend`: check backend URL, network, firewall, and HTTPS.
- Speech unavailable: enable/install Android speech services and grant microphone permission.
- No Hindi voice: install a Hindi TTS voice in Android text-to-speech settings.

## 5. Security notes
- `.env` files are ignored by git.
- The backend validates message payloads, applies a per-IP rate limit, limits request size, and does not send provider credentials to the app.
- Rate limiting is basic protection, not a complete public-production authentication system. Add proper user authentication before launching publicly.


## 6. Optional cloud APK build with GitHub Actions
This repository includes `.github/workflows/build-apk.yml`.
1. Create a GitHub repository and upload the contents of this project.
2. Open the repository's **Actions** tab.
3. Select **Build JARVIS Android APK** and choose **Run workflow** (or push to `main`).
4. When the workflow completes successfully, open its run and download the `jarvis-release-apk` artifact.
5. Extract the artifact ZIP to get `app-release.apk`.

Note: this workflow builds the Flutter APK; it does not deploy the Node.js backend.
Configure `app/lib/config/app_config.dart` with your deployed HTTPS backend URL before installing for normal AI chat use.
