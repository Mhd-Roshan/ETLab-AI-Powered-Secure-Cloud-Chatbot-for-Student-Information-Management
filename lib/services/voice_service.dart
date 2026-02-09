import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _currentLanguage = 'en-US';
  
  // Getters
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get speechEnabled => _speechEnabled;
  String get currentLanguage => _currentLanguage;

  // Voice recognition callback
  Function(String)? onSpeechResult;
  Function(String)? onSpeechError;
  Function(bool)? onListeningStateChanged;

  /// Initialize voice services
  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (micPermission != PermissionStatus.granted) {
        debugPrint('Microphone permission denied');
        return false;
      }

      // Initialize speech recognition
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: ${error.errorMsg}');
          onSpeechError?.call(error.errorMsg);
          _isListening = false;
          onListeningStateChanged?.call(false);
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          _isListening = status == 'listening';
          onListeningStateChanged?.call(_isListening);
        },
      );

      // Initialize TTS
      await _initializeTts();

      debugPrint('Voice service initialized: $_speechEnabled');
      return _speechEnabled;
    } catch (e) {
      debugPrint('Voice service initialization error: $e');
      return false;
    }
  }

  /// Initialize Text-to-Speech
  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setLanguage(_currentLanguage);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _isSpeaking = false;
      });
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  /// Start listening for speech
  Future<void> startListening() async {
    if (!_speechEnabled || _isListening) return;

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onSpeechResult?.call(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: _currentLanguage,
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('Start listening error: $e');
      onSpeechError?.call(e.toString());
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
    }
  }

  /// Speak text
  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  /// Set language for both speech recognition and TTS
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    
    try {
      await _flutterTts.setLanguage(languageCode);
      debugPrint('Language set to: $languageCode');
    } catch (e) {
      debugPrint('Set language error: $e');
    }
  }

  /// Get available languages for speech recognition
  Future<List<LocaleName>> getAvailableLanguages() async {
    if (!_speechEnabled) return [];
    return await _speechToText.locales();
  }

  /// Get available TTS languages
  Future<List<String>> getAvailableTtsLanguages() async {
    // Return a predefined list of commonly supported languages
    // This avoids API compatibility issues across different flutter_tts versions
    return <String>[
      'en-US', 'en-GB', 'en-AU', 'en-IN',
      'hi-IN', 'ml-IN', 'ta-IN', 'te-IN', 
      'kn-IN', 'bn-IN', 'gu-IN', 'mr-IN', 
      'pa-IN', 'ur-PK', 'es-ES', 'fr-FR', 
      'de-DE', 'ar-SA', 'zh-CN', 'ja-JP'
    ];
  }

  /// Dispose resources
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
  }
}