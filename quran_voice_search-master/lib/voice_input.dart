// ignore_for_file: avoid_print

import 'dart:async' show Timer;
import 'package:flutter/material.dart';
import 'package:quran_voice_search/quran_api.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceInputPage extends StatefulWidget {
  const VoiceInputPage({super.key});

  @override
  VoiceInputPageState createState() => VoiceInputPageState();
}

class VoiceInputPageState extends State<VoiceInputPage>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Tap the mic and start speaking...';

  List<stt.LocaleName> _locales = [];
  int _selectedLocaleIndex = 0;
  bool _loadingLocales = false;
  late AnimationController _micController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initLocales();
    _micController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      lowerBound: 1.0,
      upperBound: 1.2,
    );
  }

  @override
  void dispose() {
    _micController.dispose();
    super.dispose();
  }

  Future<void> _initLocales() async {
    await _speech.initialize();
    var locales = await _speech.locales();
    setState(() {
      _locales = locales;
      _selectedLocaleIndex = 0;
      _loadingLocales = false;
    });
  }

  void _listen() async {
    if (_isListening) {
      // Stop listening if already active
      setState(() => _isListening = true);
      _micController.stop();
      _speech.stop();
      return;
    }

    // Try to initialize the speech recognizer
    bool available = await _speech.initialize(
      onError: (error) {
        setState(() => _text = "Speech error: ${error.errorMsg}");
        _micController.stop();
        _isListening = false;
      },
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() => _isListening = false);
          _micController.stop();
        }
      },
    );

    if (!available) {
      setState(() => _text = "Speech recognition not available.");
      return;
    }

    // If available, start listening
    setState(() {
      _isListening = true;
      _text = "🎙️ Listening... please mention a Surah or Ayah";
    });
    _micController.repeat(reverse: true);

    String? localeId = _locales.isNotEmpty
        ? _locales[_selectedLocaleIndex].localeId
        : null;

    _speech.listen(
      localeId: localeId,
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: false,
        listenMode: stt.ListenMode.search,
      ),
      onResult: (result) async {
        String spokenText = result.recognizedWords.trim();
        if (spokenText.isEmpty) {
          setState(() => _text = "No speech detected. Try again.");
          return;
        }

        setState(() => _text = "You said: \"$spokenText\"");

        // Detect if Quran-related
        if (_isQuranRelated(spokenText)) {
          String surahName = _extractSurahName(spokenText);

          if (surahName == 'Unknown Surah') {
            // Try again with cleaned input (remove “surah” etc.)
            String retryText = spokenText
                .replaceAll(RegExp(r'\bsurah\b', caseSensitive: false), '')
                .trim();
            surahName = _extractSurahName(retryText);
          }

          if (surahName == 'Unknown Surah') {
            setState(() => _text = "❌ Cannot find surah for \"$spokenText\"");
            print("Cannot find surah for $spokenText");
          } else {
            setState(() => _text = "✅ Result for Surah: $surahName");
            print("Found Surah: $surahName");
          }
        } else {
          setState(
            () => _text =
                "⚠️ Unrelated speech detected. Please mention a Surah or Ayah.",
          );
        }
      },
    );

    // Auto-stop after 10 seconds of listening
    Timer(const Duration(seconds: 10), () {
      if (_isListening) {
        setState(() => _isListening = false);
        _micController.stop();
        _speech.stop();
        if (_text == "🎙️ Listening... please mention a Surah or Ayah") {
          setState(() => _text = "⏹️ No input detected. Try again.");
        }
      }
    });
  }

  bool _isQuranRelated(String input) {
    final text = input.trim().toLowerCase();

    // Common Quran-related words in English & Malay
    final keywords = [
      'quran',
      'koran',
      'surah',
      'ayat',
      'verse',
      'chapter',
      'tafseer',
      'tafsir',
      'makkah',
      'madinah',
      'allah',
      'rasul',
      'prophet',
      'hadith',
      'islam',
      'recitation',
      'translation',
      'al-',
      'surat',
      'ayat',
      'mushaf',
      'tajwid',
      'makkiyah',
      'madaniyah',
    ];

    // Common surah names (shortened)
    final surahNames = [
      'alfatihah',
      'albaqarah',
      'ali imran',
      'annisa',
      'almaida',
      'alyunus',
      'yasin',
      'alkahf',
      'almulk',
      'alrahman',
      'alikhhlas',
      'annas',
      'alfalaq',
    ];

    // Check if Arabic script is present (U+0600–U+06FF)
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(input);

    // Check if ayah/surah number pattern is present
    final hasSurahPattern = RegExp(r'(surah|ayat|ayah)\s*\d+').hasMatch(text);

    // Check for known keywords or surah names
    final hasKeyword = keywords.any((k) => text.contains(k));
    final hasSurahName = surahNames.any((n) => text.contains(n));

    return hasArabic || hasKeyword || hasSurahPattern || hasSurahName;
  }

  String _extractSurahName(String input) {
    final raw = input.trim().toLowerCase();

    // Remove common Quran prefixes like "surah", "surat", "chapter", etc.
    final text = raw
        .replaceAll(RegExp(r'\b(surah|surat|chapter|surah al|surat al)\b'), '')
        .trim();

    String bestMatch = 'Unknown Surah';
    double bestScore = 0.0;

    // Helper: Levenshtein similarity
    double similarity(String a, String b) {
      final lenA = a.length;
      final lenB = b.length;
      if (lenA == 0 || lenB == 0) return 0;

      final dp = List.generate(lenA + 1, (_) => List<int>.filled(lenB + 1, 0));
      for (int i = 0; i <= lenA; i++) {
        dp[i][0] = i;
        for (int j = 0; j <= lenB; j++) {
          dp[0][j] = j;
        }
      }

      for (int i = 1; i <= lenA; i++) {
        for (int j = 1; j <= lenB; j++) {
          final cost = a[i - 1] == b[j - 1] ? 0 : 1;
          dp[i][j] = [
            dp[i - 1][j] + 1, // deletion
            dp[i][j - 1] + 1, // insertion
            dp[i - 1][j - 1] + cost, // substitution
          ].reduce((a, b) => a < b ? a : b);
        }
      }

      final distance = dp[lenA][lenB];
      final maxLen = lenA > lenB ? lenA : lenB;
      return 1 - (distance / maxLen);
    }

    for (final surah in QuranApi.surahLocal) {
      final english = (surah['english'] as String).toLowerCase();
      final malay = (surah['malay'] as String).toLowerCase();
      final name = (surah['name'] as String).toLowerCase();
      final arabic = (surah['arabic'] as String);

      // Direct containment check
      if (text.contains(english) ||
          text.contains(malay) ||
          text.contains(name) ||
          text.contains(arabic)) {
        return surah['name'];
      }

      // Fuzzy matching
      final scores = [
        similarity(text, english),
        similarity(text, malay),
        similarity(text, name),
      ];
      final score = scores.reduce((a, b) => a > b ? a : b);

      if (score > bestScore) {
        bestScore = score;
        bestMatch = surah['name'];
      }
    }

    // Pattern: "surah 36"
    final match = RegExp(r'surah\s*(\d+)').firstMatch(raw);
    if (match != null) {
      final index = int.tryParse(match.group(1) ?? '');
      if (index != null && index > 0 && index <= QuranApi.surahLocal.length) {
        return QuranApi.surahLocal[index - 1]['name'];
      }
    }

    // Only accept fuzzy match if confidence is decent
    if (bestScore >= 0.65) {
      return bestMatch;
    }

    return 'Unknown Surah';
  }

  void _clearText() {
    setState(() {
      _text = 'Tap the mic and start speaking...';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Quran Voice Search',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_loadingLocales)
              const Center(child: CircularProgressIndicator())
            else if (_locales.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedLocaleIndex,
                    icon: const Icon(Icons.language),
                    borderRadius: BorderRadius.circular(12),
                    items: List.generate(_locales.length, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text(_locales[index].name),
                      );
                    }),
                    onChanged: (int? newIndex) {
                      setState(() {
                        _selectedLocaleIndex = newIndex!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 24,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.format_quote,
                      color: Colors.teal,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_text != 'Tap the mic and start speaking...')
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.redAccent),
                        onPressed: _clearText,
                        tooltip: 'Clear',
                      ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _listen,
              child: ScaleTransition(
                scale: _isListening
                    ? _micController
                    : AlwaysStoppedAnimation(1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _isListening
                        ? Colors.teal
                        : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (_isListening)
                        BoxShadow(
                          color: const Color.fromARGB(
                            255,
                            68,
                            3,
                            221,
                          ).withGreen(77),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isListening ? "Listening..." : "Tap the mic to start",
              style: TextStyle(
                color: _isListening ? Colors.teal : theme.hintColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
