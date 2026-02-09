import 'package:flutter/foundation.dart';
import 'package:translator/translator.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final GoogleTranslator _translator = GoogleTranslator();
  
  // Supported languages with their codes and names
  static const Map<String, Map<String, String>> supportedLanguages = {
    'en': {'name': 'English', 'voice': 'en-US'},
    'hi': {'name': 'हिंदी (Hindi)', 'voice': 'hi-IN'},
    'ml': {'name': 'മലയാളം (Malayalam)', 'voice': 'ml-IN'},
    'ta': {'name': 'தமிழ் (Tamil)', 'voice': 'ta-IN'},
    'te': {'name': 'తెలుగు (Telugu)', 'voice': 'te-IN'},
    'kn': {'name': 'ಕನ್ನಡ (Kannada)', 'voice': 'kn-IN'},
    'bn': {'name': 'বাংলা (Bengali)', 'voice': 'bn-IN'},
    'gu': {'name': 'ગુજરાતી (Gujarati)', 'voice': 'gu-IN'},
    'mr': {'name': 'मराठी (Marathi)', 'voice': 'mr-IN'},
    'pa': {'name': 'ਪੰਜਾਬੀ (Punjabi)', 'voice': 'pa-IN'},
    'ur': {'name': 'اردو (Urdu)', 'voice': 'ur-PK'},
    'es': {'name': 'Español (Spanish)', 'voice': 'es-ES'},
    'fr': {'name': 'Français (French)', 'voice': 'fr-FR'},
    'de': {'name': 'Deutsch (German)', 'voice': 'de-DE'},
    'ar': {'name': 'العربية (Arabic)', 'voice': 'ar-SA'},
  };

  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;
  String get currentLanguageName => supportedLanguages[_currentLanguage]?['name'] ?? 'English';
  String get currentVoiceCode => supportedLanguages[_currentLanguage]?['voice'] ?? 'en-US';

  /// Set current language
  void setLanguage(String languageCode) {
    if (supportedLanguages.containsKey(languageCode)) {
      _currentLanguage = languageCode;
      debugPrint('Language set to: $languageCode (${supportedLanguages[languageCode]?['name']})');
    }
  }

  /// Detect language of input text
  Future<String> detectLanguage(String text) async {
    try {
      if (text.trim().isEmpty) return 'en';
      
      final detection = await _translator.translate(text, to: 'en');
      final detectedLang = detection.sourceLanguage.code;
      
      // Return detected language if supported, otherwise default to English
      return supportedLanguages.containsKey(detectedLang) ? detectedLang : 'en';
    } catch (e) {
      debugPrint('Language detection error: $e');
      return 'en'; // Default to English on error
    }
  }

  /// Translate text to target language
  Future<String> translateText(String text, {String? targetLanguage}) async {
    try {
      if (text.trim().isEmpty) return text;
      
      final target = targetLanguage ?? _currentLanguage;
      
      // Skip translation if already in target language
      final detectedLang = await detectLanguage(text);
      if (detectedLang == target) return text;
      
      final translation = await _translator.translate(text, to: target);
      return translation.text;
    } catch (e) {
      debugPrint('Translation error: $e');
      return text; // Return original text on error
    }
  }

  /// Translate text from detected language to English (for AI processing)
  Future<String> translateToEnglish(String text) async {
    return await translateText(text, targetLanguage: 'en');
  }

  /// Translate AI response from English to user's language
  Future<String> translateFromEnglish(String text) async {
    if (_currentLanguage == 'en') return text;
    return await translateText(text, targetLanguage: _currentLanguage);
  }

  /// Get list of supported languages
  List<Map<String, String>> getSupportedLanguages() {
    return supportedLanguages.entries.map((entry) => {
      'code': entry.key,
      'name': entry.value['name']!,
      'voice': entry.value['voice']!,
    }).toList();
  }

  /// Auto-detect and set language from user input
  Future<void> autoDetectAndSetLanguage(String userInput) async {
    try {
      final detectedLang = await detectLanguage(userInput);
      if (detectedLang != _currentLanguage && supportedLanguages.containsKey(detectedLang)) {
        setLanguage(detectedLang);
        debugPrint('Auto-detected and switched to: $detectedLang');
      }
    } catch (e) {
      debugPrint('Auto-detection error: $e');
    }
  }

  /// Translate UI text based on current language
  String getLocalizedText(String key) {
    final translations = {
      'en': {
        'listening': 'Listening...',
        'speak_now': 'Speak now',
        'processing': 'Processing...',
        'voice_not_supported': 'Voice not supported',
        'mic_permission_denied': 'Microphone permission denied',
        'translation_error': 'Translation error occurred',
        'language_detected': 'Language detected',
        'switch_to_voice': 'Switch to voice',
        'switch_to_text': 'Switch to text',
        'select_language': 'Select Language',
        'voice_input': 'Voice Input',
        'text_input': 'Text Input',
      },
      'hi': {
        'listening': 'सुन रहा है...',
        'speak_now': 'अब बोलें',
        'processing': 'प्रसंस्करण...',
        'voice_not_supported': 'आवाज समर्थित नहीं',
        'mic_permission_denied': 'माइक्रोफोन अनुमति अस्वीकृत',
        'translation_error': 'अनुवाद त्रुटि हुई',
        'language_detected': 'भाषा का पता चला',
        'switch_to_voice': 'आवाज़ पर स्विच करें',
        'switch_to_text': 'टेक्स्ट पर स्विच करें',
        'select_language': 'भाषा चुनें',
        'voice_input': 'आवाज़ इनपुट',
        'text_input': 'टेक्स्ट इनपुट',
      },
      'ml': {
        'listening': 'കേൾക്കുന്നു...',
        'speak_now': 'ഇപ്പോൾ സംസാരിക്കുക',
        'processing': 'പ്രോസസ്സിംഗ്...',
        'voice_not_supported': 'ശബ്ദം പിന്തുണയ്ക്കുന്നില്ല',
        'mic_permission_denied': 'മൈക്രോഫോൺ അനുമതി നിഷേധിച്ചു',
        'translation_error': 'വിവർത്തന പിശക് സംഭവിച്ചു',
        'language_detected': 'ഭാഷ കണ്ടെത്തി',
        'switch_to_voice': 'ശബ്ദത്തിലേക്ക് മാറുക',
        'switch_to_text': 'ടെക്സ്റ്റിലേക്ക് മാറുക',
        'select_language': 'ഭാഷ തിരഞ്ഞെടുക്കുക',
        'voice_input': 'ശബ്ദ ഇൻപുട്ട്',
        'text_input': 'ടെക്സ്റ്റ് ഇൻപുട്ട്',
      },
    };

    return translations[_currentLanguage]?[key] ?? 
           translations['en']?[key] ?? 
           key;
  }

  /// Clean text for better TTS pronunciation
  String cleanTextForTts(String text) {
    // Remove markdown formatting
    String cleaned = text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1') // Bold
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')     // Italic
        .replaceAll(RegExp(r'`(.*?)`'), r'$1')       // Code
        .replaceAll(RegExp(r'#{1,6}\s*'), '')        // Headers
        .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1') // Links
        .replaceAll(RegExp(r'^\s*[-*+]\s*', multiLine: true), '') // List items
        .replaceAll(RegExp(r'^\s*\d+\.\s*', multiLine: true), '') // Numbered lists
        .replaceAll(RegExp(r'\n+'), ' ')             // Multiple newlines
        .trim();

    // Limit length for TTS (most TTS engines have limits)
    if (cleaned.length > 500) {
      cleaned = '${cleaned.substring(0, 497)}...';
    }

    return cleaned;
  }
}