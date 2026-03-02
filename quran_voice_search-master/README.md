# 🎙️ Quran Voice Search Detector

This project is a **Flutter-based Quran voice search detector** that allows users to **speak a Surah name** (e.g., “Surah Yasin”) and automatically identifies the corresponding Surah from a local dataset.

It integrates **speech recognition**, **smart text matching**, and **Quran data lookup**, providing an intuitive way to interact with Quranic content using voice input.

---

## 🧠 Features

🎧 **Voice Recognition** — Detects user speech and converts it to text using the device’s microphone.  
📖 **Surah Detection** — Identifies the Surah mentioned in the spoken text using fuzzy matching (e.g., “Yasin” → “Ya-Sin”).  
⚙️ **Quran Context Check** — Detects if the input is Quran-related before performing a lookup.  
🕋 **Local Surah Data** — Uses preloaded Surah names from local JSON for offline operation.  
💬 **Dynamic Feedback** — Displays results such as “Result for Surah: Ya-Sin” or “Cannot find Surah for …”.  
⏱️ **Auto-stop Listening** — Automatically stops listening after a set duration.  

---

## 🧩 Example Workflow

1. Tap the microphone button 🎙️  
2. Say something like:  
   > "Search Surah Yasin"  
3. The system detects “Yasin” → matches it to “Ya-Sin”  
4. The result shows:  
   ```
   Result for Surah: Ya-Sin
   ```  
5. If the speech is unrelated (e.g., “What time is it?”), the app will respond with:  
   > “Unrelated speech detected. Please mention a Surah or Ayat.”

---

## 🧑‍💻 Development Notes

This project was **developed by [Haikal]** under the **supervision of [Kimi Md Noor]**.  
It was created as part of an **internship learning project** to explore **real-time speech recognition** and **Quranic data handling** using Flutter.  

The goal of this project is to apply **AI-driven voice interaction** in **Islamic educational tools** and enhance accessibility for Quranic study.

---

## ⚙️ Tech Stack

- **Flutter** — Speech interface and UI  
- **speech_to_text** — Voice recognition  
- **Dart** — Logic and data processing  
- **Local JSON** — Surah data storage  

---

## 📂 File Overview

| File | Description |
|------|--------------|
| `main.dart` | Entry point and UI for microphone listening |
| `_listen()` | Handles voice input and speech result logic |
| `_extractSurahName()` | Extracts surah names from the detected text |
| `_isQuranRelated()` | Determines if the detected speech is Quran-related |
| `surahLocal` | Local dataset containing Surah names |

---

## 🚀 Future Enhancements

- Add **Ayat number detection and lookup**  
- Support **multi-language recognition** (Malay, Arabic, English)  
- Integrate with **Firebase** or **Quran APIs** for extended features  
- Enable **text-to-speech recitation** for the detected Surah  

---

## 🕌 Acknowledgment

**Developed by [Haikal]**  
**Supervised by [Hakimi Md Noor]**  

Special thanks to the intern for their dedication and effort in developing this experimental Quranic voice recognition system.  
Together, this project aims to encourage **AI and Flutter integration** in **Islamic tech innovation**.
