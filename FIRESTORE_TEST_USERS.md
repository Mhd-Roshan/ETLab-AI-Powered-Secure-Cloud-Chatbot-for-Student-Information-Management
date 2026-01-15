# Firestore Test Users for EdLab

This document contains sample test users for all roles. Add these to your Firestore database under the `users` collection.

## How to Add Users to Firestore

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Firestore Database**
4. Go to the `users` collection
5. Click **Add Document** for each user below
6. Use the username as the document ID
7. Copy-paste the fields below

---

## Test Users by Role

### 1. ADMIN User
**Document ID:** `admin123`

```json
{
  "username": "admin123",
  "password": "admin@123",
  "email": "admin@edlab.com",
  "role": "admin",
  "firstName": "Admin",
  "lastName": "User",
  "collegeCode": "TVE",
  "collegeName": "College of Engineering Trivandrum",
  "phone": "9876543210",
  "department": "Administration",
  "isActive": true,
  "createdAt": "2024-01-13",
  "lastLogin": "2024-01-13"
}
```

**Login Credentials:**
- Username: `admin123`
- Password: `admin@123`
- College: College of Engineering Trivandrum (TVE)

---

### 2. HOD (Head of Department) User
**Document ID:** `hod456`

```json
{
  "username": "hod456",
  "password": "hod@456",
  "email": "hod@edlab.com",
  "role": "hod",
  "firstName": "Dr.",
  "lastName": "Sharma",
  "collegeCode": "KMCT",
  "collegeName": "KMCT College of Engineering, Kozhikode",
  "phone": "9876543211",
  "department": "Computer Science & Engineering",
  "isActive": true,
  "createdAt": "2024-01-13",
  "lastLogin": "2024-01-13"
}
```

**Login Credentials:**
- Username: `hod456`
- Password: `hod@456`
- College: KMCT College of Engineering, Kozhikode (KMCT)

---

### 3. STAFF User
**Document ID:** `staff789`

```json
{
  "username": "staff789",
  "password": "staff@789",
  "email": "staff@edlab.com",
  "role": "staff",
  "firstName": "John",
  "lastName": "Doe",
  "collegeCode": "TCR",
  "collegeName": "Govt. Engineering College, Thrissur",
  "phone": "9876543212",
  "department": "Mechanical Engineering",
  "isActive": true,
  "createdAt": "2024-01-13",
  "lastLogin": "2024-01-13"
}
```

**Login Credentials:**
- Username: `staff789`
- Password: `staff@789`
- College: Govt. Engineering College, Thrissur (TCR)

---

### 4. STAFF ADVISOR User
**Document ID:** `advisor101`

```json
{
  "username": "advisor101",
  "password": "advisor@101",
  "email": "advisor@edlab.com",
  "role": "staff_advisor",
  "firstName": "Prof.",
  "lastName": "Kumar",
  "collegeCode": "RIT",
  "collegeName": "Rajiv Gandhi Institute of Technology, Kottayam",
  "phone": "9876543213",
  "department": "Civil Engineering",
  "isActive": true,
  "createdAt": "2024-01-13",
  "lastLogin": "2024-01-13"
}
```

**Login Credentials:**
- Username: `advisor101`
- Password: `advisor@101`
- College: Rajiv Gandhi Institute of Technology, Kottayam (RIT)

---

## Additional Test Users (Optional)

### Extra Admin User
**Document ID:** `admin_test`

```json
{
  "username": "admin_test",
  "password": "test123",
  "email": "admin.test@edlab.com",
  "role": "admin",
  "firstName": "Test",
  "lastName": "Admin",
  "collegeCode": "TRV",
  "collegeName": "Govt. Engineering College, Barton Hill",
  "phone": "9876543220",
  "department": "Administration",
  "isActive": true,
  "createdAt": "2024-01-13",
  "lastLogin": "2024-01-13"
}
```

### Inactive User (for testing)
**Document ID:** `inactive_user`

```json
{
  "username": "inactive_user",
  "password": "inactive@123",
  "email": "inactive@edlab.com",
  "role": "staff",
  "firstName": "Inactive",
  "lastName": "User",
  "collegeCode": "KKE",
  "collegeName": "Govt. Engineering College, Kozhikode",
  "phone": "9876543221",
  "department": "Information Technology",
  "isActive": false,
  "createdAt": "2024-01-10",
  "lastLogin": "2024-01-10"
}
```

---

## Steps to Add Users via Firebase Console

1. **Open Firestore Console**
   - Project Settings → Database

2. **Create `users` Collection** (if not exists)
   - Click "Create Collection"
   - Name: `users`

3. **Add Each Document**
   - Click "Add Document"
   - Set Document ID to the username
   - Add each field as a string, boolean, or timestamp

4. **Test Login**
   - Open your app
   - Enter the college name, username, and password from above
   - Click LOGIN
   - You should be redirected to the appropriate dashboard

---

## Important Notes

- All passwords are stored in plaintext (for testing only). In production, use hashed passwords.
- Document IDs should match the `username` field for easy lookup
- The `role` field determines which dashboard is shown:
  - `admin` → Admin Dashboard
  - `hod` → HOD Dashboard
  - `staff` → Staff Dashboard
  - `staff_advisor` → Staff Advisor Dashboard
- Set `isActive: false` to test inactive user error handling
- Timestamps can be set to the current date or a Firestore timestamp

---

## Testing Workflow

1. ✅ Add all 4 main test users to Firestore
2. ✅ Run your app and try each login
3. ✅ Verify correct dashboard loads for each role
4. ✅ Test with inactive user (should show error)
5. ✅ Test with non-existent username (should show error)

---

## Need to Reset Users?

To delete all test users:
1. Go to Firestore Console
2. Select the `users` collection
3. Select each document and click Delete
4. Re-add fresh users as needed
