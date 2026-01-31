# Setting Up Gemini AI for EdLab

## Getting Your Gemini API Key

1. **Visit Google AI Studio**
   - Go to: https://aistudio.google.com/
   - Sign in with your Google account

2. **Create an API Key**
   - Click on "Get API Key" in the left sidebar
   - Click "Create API Key"
   - Choose "Create API key in new project" or select an existing project
   - Copy the generated API key

3. **Add the API Key to Your Project**
   - Open the file: `lib/config/api_config.dart`
   - Replace `YOUR_GEMINI_API_KEY_HERE` with your actual API key
   - Example:
     ```dart
     static const String geminiApiKey = "AIzaSyABC123...your-actual-key";
     ```

## Important Security Notes

⚠️ **DO NOT commit your API key to version control!**

### For Development:

- The current setup stores the key in `lib/config/api_config.dart`
- Add this file to `.gitignore` to prevent accidental commits

### For Production:

Consider using one of these secure methods:

1. **Environment Variables** with `flutter_dotenv` package
2. **Firebase Remote Config** for dynamic updates
3. **Secure Storage** packages like `flutter_secure_storage`
4. **Backend API** that proxies requests to Gemini

## Testing the AI Dashboard

1. Make sure you've added your API key to `lib/config/api_config.dart`
2. Run the app
3. Navigate to Admin Dashboard
4. Click on "AI Dashboard" in the grid
5. Enter a student ID (e.g., TVE20CS001)
6. Enter a prompt like: "Summarize this student's performance"
7. Click "Generate Insights"

## Features

The AI Dashboard can:

- Analyze student academic performance
- Review attendance patterns
- Generate personalized reports
- Provide insights and recommendations
- Export reports as PDF

## Troubleshooting

**Error: "API key not valid"**

- Double-check that you copied the entire API key
- Ensure there are no extra spaces or quotes
- Verify the key is active in Google AI Studio

**Error: "Student not found"**

- Make sure the student ID exists in your Firestore database
- Check the 'students' collection in Firebase Console

**No response from AI**

- Check your internet connection
- Verify Firebase is properly configured
- Check the Flutter console for detailed error messages
