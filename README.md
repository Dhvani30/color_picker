<p align="center">
  <img src="assets/logo.png" alt="ColorPicker Logo" width="90" style="margin-bottom: 10px;" />
  <h1 align="center" style="font-weight: 800; letter-spacing: -1px;">ColorPicker</h1>
  <p align="center" style="font-size: 1.2rem; color: #6a737d;">Advanced Camera Color Picker & AI Design Assistant</p>
</p>

<p align="center">
  <a href="https://flutter.dev/">
    <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white&style=for-the-badge" alt="Flutter" />
  </a>
  <a href="https://dart.dev/">
    <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white&style=for-the-badge" alt="Dart" />
  </a>
  <a href="https://github.com/Dhvani30/color_picker/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
  </a>
  <a href="https://github.com/Dhvani30/color_picker/stargazers">
    <img src="https://img.shields.io/github/stars/Dhvani30/color_picker?style=for-the-badge&logo=github" alt="Stars" />
  </a>
</p>

<p align="center">
  <img src="https://readme-typing-svg.herokuapp.com?font=Fira+Code&weight=600&pause=1500&color=02569B&center=true&vCenter=true&width=500&lines=Capture+Real-World+Colors+Instantly;Match+with+Asian+Paints+Database;AI-Powered+Design+Suggestions" alt="Typing SVG" />
</p>

<p align="center">
  <img src="assets/demo.gif" alt="App Demo" width="300" style="border-radius: 20px; box-shadow: 0 20px 40px rgba(0,0,0,0.25); border: 4px solid #ffffff;" />
  <br>
  <sub><i>Drag, match, save, and get AI design tips in real-time</i></sub>
</p>

> A beautiful, glassmorphic Flutter application that lets you capture real-world colors using your live camera or photo gallery, instantly matches them to a comprehensive **Asian Paints** database, and provides **AI-powered interior design suggestions**.

---

## ✨ Key Features

-  **Live Camera Picking**: Drag a precision crosshair over the live camera feed to sample colors in real-time.
-  **Gallery Support**: Import images from your device to extract colors from existing photos.
-  **Asian Paints Database**: Instantly matches sampled RGB values to the closest official Asian Paints color name (Melange, Brights, and Whites).
-  **AI Design Assistant**: Get instant, professional, emoji-free interior design tips, complementary color suggestions, and lighting advice tailored to your selected color.
-  **Glassmorphism UI**: Modern, frosted-glass interface with smooth animations and transparent overlays.
-  **Rich Haptic Feedback**: Tactile vibrations on every interaction (button taps, crosshair dragging, saving, and deleting).
-  **Persistent History**: Automatically saves your captured colors, HEX, RGB, and timestamps locally.
-  **Freeze Frame**: Pause the live camera feed to accurately pick colors from a still frame.

---

## 🛠️ Tech Stack

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Camera_API-green?logo=android" alt="Camera" />
  <img src="https://img.shields.io/badge/Image_Picker-orange?logo=files" alt="Image Picker" />
  <img src="https://img.shields.io/badge/Shared_Preferences-yellow?logo=database" alt="Shared Preferences" />
  <img src="https://img.shields.io/badge/OpenRouter_AI-7c3aed?logo=openai&logoColor=white" alt="AI Assistant" />
</p>

---

## 🚀 Getting Started

Follow these simple steps to run the project locally:

### 1. Prerequisites
- Install [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Install [Git](https://git-scm.com/)

### 2. Clone the Repository
```bash
git clone https://github.com/Dhvani30/color_picker.git
cd color_picker
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Configure Environment (For AI Features)
1. Create a file named `.env` in the root directory (same level as `pubspec.yaml`).
2. Add your free OpenRouter API key:
   ```env
   OPENROUTER_API_KEY=your_api_key_here
   ```
3. Ensure `.env` is listed in your `.gitignore` to keep your key secure.

### 5. Run the App
```bash
flutter run
```
*(Optional) To regenerate the app icons after adding your own `assets/logo.png`:*
```bash
dart run flutter_launcher_icons
```
---

## 📥 Download APK

Want to try the app without building it from source? You can download and install the APK directly on your Android device!

- **Latest Release**: [Download ColorPicker APK](https://github.com/Dhvani30/color_picker/releases/latest) *(Recommended)*
- **Local Build Path**: If you cloned the repo and built it yourself, the APK is located at:  
  `build/app/outputs/flutter-apk/app-release.apk`

> *Note: When installing the APK on your Android device, you may need to enable "Install from Unknown Sources" in your device settings.*
---

## 📖 How to Use

1. **Grant Permissions**: Allow camera access when prompted on first launch.
2. **Pick a Color**: Drag the `+` crosshair over any object in the live camera view or imported gallery image.
3. **View Details**: The top-right glass panel will instantly display the closest **Asian Paints** color name, HEX code, and RGB values.
4. **Get AI Tips**: Tap the ✨ button to receive professional, emoji-free interior design suggestions tailored to your selected color.
5. **Save**: Tap the `Save` icon to store the color in your persistent history sheet (complete with date and time).
6. **Manage History**: Tap any saved color in the bottom sheet to reload it, or **long-press** to delete it.

---

## 🤝 Contributing

Contributions, issues, and feature requests are highly welcome! 
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  <b>🌟 Show Your Support</b><br>
  If you found this project helpful or interesting, please consider giving it a <b>Star</b> on GitHub!<br>
  It helps the project grow, improves its search visibility, and motivates further development.
</p>

<p align="center">
  <a href="https://github.com/Dhvani30/color_picker/stargazers">
    <img src="https://img.shields.io/github/stars/Dhvani30/color_picker?style=social" alt="Star this repo" />
  </a>
</p>

---
<p align="center">
  <sub>Built with ❤️ by <a href="https://github.com/Dhvani30">Dhvani</a></sub>
</p>
