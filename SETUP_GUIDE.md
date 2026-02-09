# EdLab Enhanced Chatbot Setup Guide
## Voice Interface & Multilingual Support

### 🚀 **Quick Start**

This guide will help you set up and run the enhanced EdLab chatbot with voice interface and multilingual capabilities.

---

## 📋 **Prerequisites**

### System Requirements
- **Flutter SDK**: 3.10.7 or higher
- **Dart SDK**: 3.0.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase Project** with Firestore and Firebase AI enabled

### Platform Requirements
- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 10.0+
- **Web**: Modern browsers with microphone support
- **Windows/macOS/Linux**: Desktop support available

---

## 🛠 **Installation Steps**

### 1. Clone and Setup Project

```bash
# Navigate to your project directory
cd edlab

# Install dependencies
flutter pub get

# Verify installation
flutter doctor
```

### 2. Configure Firebase

Ensure your Firebase project has:
- **Firestore Database** enabled
- **Firebase AI** (Gemini) enabled
- **Authentication** configured
- **Web API Key** configured in `lib/config/api_config.dart`

### 3. Platform-Specific Setup

#### Android Setup
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.MICROPHONE" />
```

#### iOS Setup
Add to `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for voice input</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app needs speech recognition for voice commands</string>
```

#### Web Setup
Ensure your web server supports HTTPS for microphone access.

---

## 🎯 **Running the Enhanced Chatbot**

### 1. Standard Chat Screen (Original)
```bash
# Run the app and navigate to AI Chat
flutter run
# Navigate to: Admin Dashboard > AI Chat
```

### 2. Enhanced Chat Screen (New)
```bash
# Run the app and navigate to Enhanced AI Chat
flutter run
# Navigate to: Admin Dashboard > Enhanced AI Chat
```

### 3. Testing Suite
```bash
# Run the app and navigate to Testing Suite
flutter run
# Navigate to: Admin Dashboard > Chatbot Testing
```

---

## 🗣️ **Using Voice Features**

### Voice Input
1. **Enable Voice Mode**: Click the microphone icon in the chat interface
2. **Start Speaking**: Click "Speak Now" button
3. **Stop Listening**: Click the stop button or wait for auto-timeout
4. **Submit**: Voice input automatically populates text field

### Text-to-Speech
1. **Auto-Play**: Responses automatically spoken in voice mode
2. **Manual Play**: Click the speaker icon to hear any response
3. **Stop Speaking**: Click the volume-off icon to interrupt

### Language Controls
1. **Auto-Detection**: System automatically detects your language
2. **Manual Selection**: Click language button to choose preferred language
3. **Voice Language**: TTS automatically matches your selected language

---

## 🌍 **Supported Languages**

### Tier 1 (Fully Tested)
- **English** (en-US)
- **Hindi** (hi-IN) 
- **Malayalam** (ml-IN)
- **Tamil** (ta-IN)
- **Telugu** (te-IN)

### Tier 2 (Basic Support)
- **Kannada** (kn-IN)
- **Bengali** (bn-IN)
- **Gujarati** (gu-IN)
- **Marathi** (mr-IN)
- **Punjabi** (pa-IN)

### Tier 3 (International)
- **Spanish** (es-ES)
- **French** (fr-FR)
- **German** (de-DE)
- **Arabic** (ar-SA)
- **Urdu** (ur-PK)

---

## 🧪 **Testing the Implementation**

### 1. Run Automated Tests
```bash
# Navigate to Testing Suite in the app
# Click "Run Comprehensive Tests"
# Wait for results (may take 2-3 minutes)
```

### 2. Manual Testing Checklist

#### Voice Features
- [ ] Microphone permission granted
- [ ] Voice input works in English
- [ ] Voice input works in Hindi/local language
- [ ] Text-to-speech plays responses
- [ ] Voice mode toggle works
- [ ] Stop controls function properly

#### Multilingual Features
- [ ] Language auto-detection works
- [ ] Manual language selection works
- [ ] Responses translated correctly
- [ ] UI elements localized
- [ ] Chat history shows language metadata

#### Integration Features
- [ ] Voice + AI integration works
- [ ] Translation + AI integration works
- [ ] Error handling graceful
- [ ] Performance acceptable (<3s response)

### 3. Test Specific Scenarios

#### English Voice Test
1. Enable voice mode
2. Say: "Show me student attendance summary"
3. Verify: Response contains attendance data

#### Hindi Voice Test
1. Switch language to Hindi
2. Say: "छात्रों की उपस्थिति दिखाएं"
3. Verify: Response in Hindi with data

#### Mixed Language Test
1. Type in English: "What is fee collection?"
2. Switch to Hindi and ask: "फीस संग्रह क्या है?"
3. Verify: Both get appropriate responses

---

## 🔧 **Troubleshooting**

### Common Issues

#### Voice Not Working
**Problem**: Microphone not responding
**Solutions**:
- Check microphone permissions
- Ensure HTTPS on web
- Restart app and grant permissions
- Test on different device

#### Translation Errors
**Problem**: Responses not translating
**Solutions**:
- Check internet connection
- Verify Google Translate API access
- Try different languages
- Check API quotas

#### Performance Issues
**Problem**: Slow responses
**Solutions**:
- Check network connection
- Monitor Firebase usage
- Reduce concurrent requests
- Clear app cache

#### Language Detection Issues
**Problem**: Wrong language detected
**Solutions**:
- Use manual language selection
- Speak more clearly
- Try typing instead of voice
- Check supported languages list

### Debug Mode

Enable debug logging by setting:
```dart
// In main.dart
void main() {
  debugPrint('Enhanced Chatbot Debug Mode Enabled');
  runApp(MyApp());
}
```

### Performance Monitoring

Monitor performance in Firebase Console:
- **Performance Tab**: Response times
- **Analytics Tab**: Usage patterns
- **Crashlytics Tab**: Error reports

---

## 📱 **Platform-Specific Notes**

### Android
- **Minimum API**: Level 21 (Android 5.0)
- **Permissions**: Auto-requested on first use
- **Performance**: Optimized for Android devices
- **Testing**: Use physical device for voice testing

### iOS
- **Minimum Version**: iOS 10.0
- **Permissions**: Requested via Info.plist descriptions
- **Performance**: Native iOS speech recognition
- **Testing**: Simulator has limited voice support

### Web
- **HTTPS Required**: For microphone access
- **Browser Support**: Chrome, Firefox, Safari, Edge
- **Limitations**: Some voice features may be limited
- **Testing**: Use localhost with HTTPS or deployed site

### Desktop
- **Windows**: Full support with Windows Speech Platform
- **macOS**: Native speech recognition support
- **Linux**: Limited voice support, varies by distribution

---

## 🚀 **Deployment Checklist**

### Pre-Deployment
- [ ] All tests passing
- [ ] Performance benchmarks met
- [ ] Security review completed
- [ ] Documentation updated
- [ ] User training materials ready

### Production Setup
- [ ] Firebase production environment configured
- [ ] API keys secured
- [ ] Monitoring enabled
- [ ] Error tracking configured
- [ ] Backup procedures in place

### Post-Deployment
- [ ] Monitor performance metrics
- [ ] Collect user feedback
- [ ] Track usage analytics
- [ ] Plan iterative improvements

---

## 📞 **Support & Resources**

### Documentation
- **Flutter Voice**: [speech_to_text documentation](https://pub.dev/packages/speech_to_text)
- **Flutter TTS**: [flutter_tts documentation](https://pub.dev/packages/flutter_tts)
- **Google Translate**: [translator package docs](https://pub.dev/packages/translator)
- **Firebase AI**: [Firebase AI documentation](https://firebase.google.com/docs/ai)

### Community Support
- **Flutter Community**: [flutter.dev/community](https://flutter.dev/community)
- **Firebase Support**: [firebase.google.com/support](https://firebase.google.com/support)
- **GitHub Issues**: Create issues for bugs or feature requests

### Professional Support
- **Firebase Support Plans**: Available for production deployments
- **Flutter Consulting**: Available through Flutter partners
- **Custom Development**: Contact development team for enhancements

---

## 🎉 **Success Indicators**

### Technical Success
- ✅ Voice recognition accuracy >85%
- ✅ Translation accuracy >90%
- ✅ Response time <3 seconds
- ✅ Error rate <1%
- ✅ All tests passing

### User Success
- ✅ Positive user feedback
- ✅ Increased engagement
- ✅ Reduced support tickets
- ✅ Higher accessibility scores
- ✅ Multi-language adoption

### Business Success
- ✅ Improved user satisfaction
- ✅ Expanded user base
- ✅ Competitive advantage
- ✅ ROI achievement
- ✅ Scalability demonstrated

---

*Setup Guide Version: 1.0*  
*Last Updated: February 4, 2026*  
*For Technical Support: Contact EdLab Development Team*