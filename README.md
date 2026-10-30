# 🚗 RefuelLog (Refuel Log AI)

A modern, intelligent Flutter application designed to effortlessly track vehicle fuel consumption, expenses, and odometer readings. Powered by **Google Generative AI**, RefuelLog allows you to scan fuel pumps and odometers directly via camera or gallery to auto-fill your log entries.

---

## ✨ Key Features

- **🤖 AI-Powered Scanning:** Automatically extract liters, total cost, and odometer values using Google Generative AI.
- **🚙 Multi-Vehicle Management:** Track fuel logs and statistics separately for each vehicle in your garage.
- **💾 Local SQLite Storage:** Fast, reliable, and offline-first data persistence using `sqflite`.
- **🌐 Multi-Language Support:** Fully localized interface using `easy_localization` (it-IT, en-EN, en-US, de-DE).
- **📤 Export & Share:** Easily share your vehicle logs and stats with the `share_plus` plugin.
- **📱 Responsive UI:** Optimized modal layout and form screens designed to prevent overflows across various screen sizes.

---

### ⚙️ Configuration

To run this application, you need a Google Generative AI API Key from [Google AI Studio](https://aistudio.google.com). 

1. Create a file named `.env` in the root directory of the project.
2. Add your API key inside the file:
   ```env
   GEMINI_API_KEY=your_actual_api_key_here
   ```

## 🛠️ Tech Stack

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

- **Framework:** [Flutter](https://flutter.dev/) (v3.x) & Dart
- **Database:** `sqflite`
- **AI Integration:** `google_generative_ai`
- **Localization:** `easy_localization`
- **Media Handling:** `image_picker`
- **Sharing:** `share_plus`

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your system.

### Installation & Running

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/your-username/refuellog.git](https://github.com/your-username/refuellog.git)
   cd refuellog
   ```

2. **Install dependencies:**
    ```Bash
    flutter pub get
    ```

3. Run the app:
    ```Bash
    flutter run
    ```

### 📂 Project Structure

```Plaintext
lib/
│
├── models/         # Data models (Vehicle, FuelLog, etc.)
├── screens/        # Main app screens and views
├── database/       # SQLite database helper and local storage
└── main.dart       # App entry point and localization setup
```

### 📝 License

This project is open-source and available under the [MIT License](https://www.google.com/search?q=LICENSE).


