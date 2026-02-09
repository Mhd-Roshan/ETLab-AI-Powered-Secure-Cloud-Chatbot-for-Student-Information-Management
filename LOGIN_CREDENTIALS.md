# Login Credentials for EdLab

## ✅ Fixed! Login now works with Firebase

The login system now properly authenticates against your Firebase `users` collection.

---

## Student Login (Roshan)

Based on your Firebase data:

**Username:** `rosh@gmail.com` (lowercase)  
**Password:** `Rosh@101`  
**College:** Select any college from dropdown (e.g., KMCT College of Engineering Kozhikode)

### Alternative Login Options:
- Username: `roshan@gmail.com` (if that's in your Firebase)
- Username: The exact value in your `username` field in Firebase

---

## How Login Works Now

1. **Enter credentials** in the login form
2. **System queries Firebase** `users` collection
3. **Searches by username** first, then by email if not found
4. **Verifies password** matches the stored password
5. **Checks if account is active** (`isActive: true`)
6. **Redirects to dashboard** based on `role` field

---

## Your Firebase User Document

```
users/student/
  ├── username: "Rosh@gmail.com"
  ├── email: "roshan@gmail.com"
  ├── password: "Rosh@101"
  ├── role: "student"
  ├── firstname: "Roshan"
  ├── department: "Master Of Computer Application"
  ├── collegeCode: "KMCT"
  ├── collegeName: "KMCT College of Engineering Kozhikode"
  └── isActive: true
```

---

## Important Notes

### Case Sensitivity
- The system converts username to **lowercase** before searching
- So `Rosh@gmail.com`, `rosh@gmail.com`, `ROSH@GMAIL.COM` all work

### Password
- Must match **exactly** (case-sensitive)
- Your password: `Rosh@101`

### Document ID
- Your document ID is `student` (not the username)
- The system searches by the `username` field, not document ID

---

## Test Other Users

If you have other users in Firebase, login format:

### Admin
- Username: `admin123`
- Password: (whatever is in Firebase)
- Role: `admin`

### HOD
- Username: `hod456`
- Password: (whatever is in Firebase)
- Role: `hod`

### Staff
- Username: `staff789`
- Password: (whatever is in Firebase)
- Role: `staff`

---

## Troubleshooting

### "USER NOT FOUND"
- Check the exact username in Firebase
- Try using the email instead
- Make sure the document exists in `users` collection

### "INCORRECT PASSWORD"
- Password is case-sensitive
- Check for extra spaces
- Verify password in Firebase console

### "ACCOUNT SUSPENDED"
- Check `isActive` field in Firebase
- Should be `true` (boolean, not string)

---

## Quick Test Steps

1. **Run the app:**
   ```bash
   flutter run -d chrome
   ```

2. **Fill in login form:**
   - College: KMCT College of Engineering Kozhikode
   - Username: `rosh@gmail.com`
   - Password: `Rosh@101`

3. **Click LOGIN**

4. **You should see:**
   - Loading indicator
   - Redirect to Student Dashboard
   - Your name "Roshan" displayed
   - Department: "Master Of Computer Application"

---

## Success! 🎉

Once logged in, you'll see:
- ✅ Beautiful student dashboard
- ✅ Your profile information
- ✅ Department and college details
- ✅ Navigation to profile page
- ✅ All your data from Firebase

Try it now! 🚀
