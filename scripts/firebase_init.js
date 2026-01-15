/**
 * Firebase Firestore Initialization Script
 * 
 * This script creates all required collections with dummy data.
 * 
 * Setup:
 * 1. npm install firebase-admin
 * 2. Download your Firebase service account key from Firebase Console
 * 3. Replace 'path/to/serviceAccountKey.json' with actual path
 * 4. Run: node firebase_init.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// Download your service account key from Firebase Console:
// Project Settings → Service Accounts → Generate New Private Key
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function initializeFirebase() {
  try {
    console.log('🚀 Starting Firebase Firestore initialization...\n');

    // 1. Users Collection
    console.log('📝 Creating users collection...');
    await createUsersCollection();

    // 2. Colleges Collection
    console.log('📝 Creating colleges collection...');
    await createCollegesCollection();

    // 3. Departments Collection
    console.log('📝 Creating departments collection...');
    await createDepartmentsCollection();

    // 4. Students Collection
    console.log('📝 Creating students collection...');
    await createStudentsCollection();

    // 5. Staff Collection
    console.log('📝 Creating staff collection...');
    await createStaffCollection();

    // 6. Courses Collection
    console.log('📝 Creating courses collection...');
    await createCoursesCollection();

    // 7. Classes Collection
    console.log('📝 Creating classes collection...');
    await createClassesCollection();

    // 8. Announcements Collection
    console.log('📝 Creating announcements collection...');
    await createAnnouncementsCollection();

    // 9. Attendance Collection
    console.log('📝 Creating attendance collection...');
    await createAttendanceCollection();

    // 10. Reports Collection
    console.log('📝 Creating reports collection...');
    await createReportsCollection();

    console.log('\n✅ Firebase initialization completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error initializing Firebase:', error);
    process.exit(1);
  }
}

// ============================================
// Collection Creation Functions
// ============================================

async function createUsersCollection() {
  const users = [
    {
      username: 'admin123',
      password: 'admin@123',
      email: 'admin@edlab.com',
      role: 'admin',
      firstName: 'Admin',
      lastName: 'User',
      collegeCode: 'TVE',
      collegeName: 'College of Engineering Trivandrum',
      phone: '9876543210',
      department: 'Administration',
      isActive: true,
      createdAt: new Date('2024-01-13'),
      lastLogin: new Date('2024-01-13'),
    },
    {
      username: 'hod456',
      password: 'hod@456',
      email: 'hod@edlab.com',
      role: 'hod',
      firstName: 'Dr.',
      lastName: 'Sharma',
      collegeCode: 'KMCT',
      collegeName: 'KMCT College of Engineering, Kozhikode',
      phone: '9876543211',
      department: 'Computer Science & Engineering',
      isActive: true,
      createdAt: new Date('2024-01-13'),
      lastLogin: new Date('2024-01-13'),
    },
    {
      username: 'staff789',
      password: 'staff@789',
      email: 'staff@edlab.com',
      role: 'staff',
      firstName: 'John',
      lastName: 'Doe',
      collegeCode: 'TCR',
      collegeName: 'Govt. Engineering College, Thrissur',
      phone: '9876543212',
      department: 'Mechanical Engineering',
      isActive: true,
      createdAt: new Date('2024-01-13'),
      lastLogin: new Date('2024-01-13'),
    },
    {
      username: 'advisor101',
      password: 'advisor@101',
      email: 'advisor@edlab.com',
      role: 'staff_advisor',
      firstName: 'Prof.',
      lastName: 'Kumar',
      collegeCode: 'RIT',
      collegeName: 'Rajiv Gandhi Institute of Technology, Kottayam',
      phone: '9876543213',
      department: 'Civil Engineering',
      isActive: true,
      createdAt: new Date('2024-01-13'),
      lastLogin: new Date('2024-01-13'),
    },
  ];

  for (const user of users) {
    await db.collection('users').doc(user.username).set(user);
  }
  console.log(`  ✓ Created ${users.length} test users`);
}

async function createCollegesCollection() {
  const colleges = [
    {
      code: 'TVE',
      name: 'College of Engineering Trivandrum',
      location: 'Thiruvananthapuram',
      affiliatedUniversity: 'KTU',
      establishedYear: 1998,
      studentsCount: 3500,
      staffCount: 250,
    },
    {
      code: 'KMCT',
      name: 'KMCT College of Engineering, Kozhikode',
      location: 'Kozhikode',
      affiliatedUniversity: 'KTU',
      establishedYear: 2000,
      studentsCount: 2800,
      staffCount: 200,
    },
    {
      code: 'TCR',
      name: 'Govt. Engineering College, Thrissur',
      location: 'Thrissur',
      affiliatedUniversity: 'KTU',
      establishedYear: 1987,
      studentsCount: 3200,
      staffCount: 280,
    },
    {
      code: 'RIT',
      name: 'Rajiv Gandhi Institute of Technology, Kottayam',
      location: 'Kottayam',
      affiliatedUniversity: 'KTU',
      establishedYear: 2001,
      studentsCount: 2900,
      staffCount: 210,
    },
  ];

  for (const college of colleges) {
    await db.collection('colleges').doc(college.code).set(college);
  }
  console.log(`  ✓ Created ${colleges.length} colleges`);
}

async function createDepartmentsCollection() {
  const departments = [
    {
      code: 'CSE',
      name: 'Computer Science & Engineering',
      collegeCode: 'TVE',
      hodName: 'Dr. Sharma',
      totalStudents: 420,
      totalStaff: 35,
    },
    {
      code: 'ECE',
      name: 'Electronics & Communication Engineering',
      collegeCode: 'TVE',
      hodName: 'Dr. Patel',
      totalStudents: 380,
      totalStaff: 32,
    },
    {
      code: 'ME',
      name: 'Mechanical Engineering',
      collegeCode: 'TCR',
      hodName: 'Prof. Kumar',
      totalStudents: 400,
      totalStaff: 38,
    },
    {
      code: 'CE',
      name: 'Civil Engineering',
      collegeCode: 'RIT',
      hodName: 'Dr. Singh',
      totalStudents: 380,
      totalStaff: 36,
    },
  ];

  for (const dept of departments) {
    await db.collection('departments').doc(`${dept.collegeCode}_${dept.code}`).set(dept);
  }
  console.log(`  ✓ Created ${departments.length} departments`);
}

async function createStudentsCollection() {
  const students = [
    {
      registrationNumber: 'TVE20CS001',
      firstName: 'Arjun',
      lastName: 'Nair',
      email: 'arjun.nair@student.edu',
      phone: '9876543220',
      collegeCode: 'TVE',
      collegeName: 'College of Engineering Trivandrum',
      department: 'Computer Science & Engineering',
      semester: 4,
      batch: 2022,
      gpa: 3.8,
      enrollmentDate: new Date('2022-07-15'),
      status: 'active',
    },
    {
      registrationNumber: 'TVE20CS002',
      firstName: 'Priya',
      lastName: 'Menon',
      email: 'priya.menon@student.edu',
      phone: '9876543221',
      collegeCode: 'TVE',
      collegeName: 'College of Engineering Trivandrum',
      department: 'Computer Science & Engineering',
      semester: 4,
      batch: 2022,
      gpa: 3.9,
      enrollmentDate: new Date('2022-07-15'),
      status: 'active',
    },
    {
      registrationNumber: 'KMCT20ECE001',
      firstName: 'Vikram',
      lastName: 'Kumar',
      email: 'vikram.kumar@student.edu',
      phone: '9876543222',
      collegeCode: 'KMCT',
      collegeName: 'KMCT College of Engineering, Kozhikode',
      department: 'Electronics & Communication Engineering',
      semester: 2,
      batch: 2023,
      gpa: 3.7,
      enrollmentDate: new Date('2023-07-18'),
      status: 'active',
    },
  ];

  for (const student of students) {
    await db.collection('students').doc(student.registrationNumber).set(student);
  }
  console.log(`  ✓ Created ${students.length} students`);
}

async function createStaffCollection() {
  const staff = [
    {
      staffId: 'TVE_001',
      firstName: 'Dr.',
      lastName: 'Sharma',
      email: 'sharma@edlab.com',
      phone: '9876543230',
      collegeCode: 'TVE',
      department: 'Computer Science & Engineering',
      designation: 'Associate Professor',
      qualifications: ['B.Tech', 'M.Tech', 'PhD'],
      joinDate: new Date('2010-06-01'),
      isActive: true,
    },
    {
      staffId: 'TCR_001',
      firstName: 'Prof.',
      lastName: 'Kumar',
      email: 'kumar@edlab.com',
      phone: '9876543231',
      collegeCode: 'TCR',
      department: 'Mechanical Engineering',
      designation: 'Assistant Professor',
      qualifications: ['B.Tech', 'M.Tech'],
      joinDate: new Date('2015-08-15'),
      isActive: true,
    },
    {
      staffId: 'KMCT_001',
      firstName: 'Dr.',
      lastName: 'Patel',
      email: 'patel@edlab.com',
      phone: '9876543232',
      collegeCode: 'KMCT',
      department: 'Electronics & Communication Engineering',
      designation: 'Professor',
      qualifications: ['B.Tech', 'M.Tech', 'PhD'],
      joinDate: new Date('2008-01-20'),
      isActive: true,
    },
  ];

  for (const s of staff) {
    await db.collection('staff').doc(s.staffId).set(s);
  }
  console.log(`  ✓ Created ${staff.length} staff members`);
}

async function createCoursesCollection() {
  const courses = [
    {
      courseCode: 'CS301',
      courseName: 'Data Structures',
      semester: 3,
      credits: 4,
      department: 'Computer Science & Engineering',
      instructor: 'Dr. Sharma',
      totalStudents: 120,
    },
    {
      courseCode: 'CS302',
      courseName: 'Database Management Systems',
      semester: 3,
      credits: 4,
      department: 'Computer Science & Engineering',
      instructor: 'Dr. Sharma',
      totalStudents: 125,
    },
    {
      courseCode: 'ME201',
      courseName: 'Thermodynamics',
      semester: 2,
      credits: 3,
      department: 'Mechanical Engineering',
      instructor: 'Prof. Kumar',
      totalStudents: 98,
    },
    {
      courseCode: 'ECE401',
      courseName: 'Digital Signal Processing',
      semester: 4,
      credits: 4,
      department: 'Electronics & Communication Engineering',
      instructor: 'Dr. Patel',
      totalStudents: 110,
    },
  ];

  for (const course of courses) {
    await db.collection('courses').doc(course.courseCode).set(course);
  }
  console.log(`  ✓ Created ${courses.length} courses`);
}

async function createClassesCollection() {
  const classes = [
    {
      classId: 'TVE_CSE_3A',
      collegeCode: 'TVE',
      department: 'Computer Science & Engineering',
      semester: 3,
      section: 'A',
      totalStrength: 60,
      classAdvisor: 'Dr. Sharma',
      createdDate: new Date('2024-01-01'),
    },
    {
      classId: 'TVE_CSE_3B',
      collegeCode: 'TVE',
      department: 'Computer Science & Engineering',
      semester: 3,
      section: 'B',
      totalStrength: 58,
      classAdvisor: 'Prof. Nair',
      createdDate: new Date('2024-01-01'),
    },
    {
      classId: 'TCR_ME_2A',
      collegeCode: 'TCR',
      department: 'Mechanical Engineering',
      semester: 2,
      section: 'A',
      totalStrength: 52,
      classAdvisor: 'Prof. Kumar',
      createdDate: new Date('2024-01-01'),
    },
  ];

  for (const cls of classes) {
    await db.collection('classes').doc(cls.classId).set(cls);
  }
  console.log(`  ✓ Created ${classes.length} classes`);
}

async function createAnnouncementsCollection() {
  const announcements = [
    {
      id: '1',
      title: 'Welcome to EdLab 2024',
      content: 'Welcome to the new academic year. Please update your profiles.',
      collegeCode: 'TVE',
      postedBy: 'admin123',
      postedDate: new Date('2024-01-13'),
      expiryDate: new Date('2024-12-31'),
      priority: 'high',
      isActive: true,
    },
    {
      id: '2',
      title: 'Semester Examination Schedule',
      content: 'Midterm examinations scheduled for March 2024',
      collegeCode: 'TVE',
      postedBy: 'hod456',
      postedDate: new Date('2024-01-10'),
      expiryDate: new Date('2024-04-30'),
      priority: 'high',
      isActive: true,
    },
    {
      id: '3',
      title: 'Library Extensions Now Available',
      content: 'Digital library access extended to all students',
      collegeCode: 'KMCT',
      postedBy: 'admin123',
      postedDate: new Date('2024-01-08'),
      expiryDate: new Date('2024-06-30'),
      priority: 'medium',
      isActive: true,
    },
  ];

  for (const announcement of announcements) {
    await db.collection('announcements').doc(announcement.id).set(announcement);
  }
  console.log(`  ✓ Created ${announcements.length} announcements`);
}

async function createAttendanceCollection() {
  const attendance = [
    {
      id: 'TVE_CSE_3A_20240113_001',
      classId: 'TVE_CSE_3A',
      courseCode: 'CS301',
      date: new Date('2024-01-13'),
      studentId: 'TVE20CS001',
      studentName: 'Arjun Nair',
      status: 'present',
      markedBy: 'Dr. Sharma',
      markedTime: new Date('2024-01-13T10:30:00'),
    },
    {
      id: 'TVE_CSE_3A_20240113_002',
      classId: 'TVE_CSE_3A',
      courseCode: 'CS301',
      date: new Date('2024-01-13'),
      studentId: 'TVE20CS002',
      studentName: 'Priya Menon',
      status: 'present',
      markedBy: 'Dr. Sharma',
      markedTime: new Date('2024-01-13T10:30:00'),
    },
  ];

  for (const att of attendance) {
    await db.collection('attendance').doc(att.id).set(att);
  }
  console.log(`  ✓ Created ${attendance.length} attendance records`);
}

async function createReportsCollection() {
  const reports = [
    {
      id: 'TVE20CS001_CS301_2024',
      studentId: 'TVE20CS001',
      studentName: 'Arjun Nair',
      courseCode: 'CS301',
      courseName: 'Data Structures',
      semester: 3,
      internalMarks: 35,
      assignmentMarks: 10,
      practicalMarks: 20,
      externalMarks: 68,
      totalMarks: 133,
      grade: 'A',
      gpa: 4.0,
      remarks: 'Excellent performance',
      evaluatedBy: 'Dr. Sharma',
      evaluatedDate: new Date('2024-01-13'),
    },
    {
      id: 'TVE20CS002_CS301_2024',
      studentId: 'TVE20CS002',
      studentName: 'Priya Menon',
      courseCode: 'CS301',
      courseName: 'Data Structures',
      semester: 3,
      internalMarks: 36,
      assignmentMarks: 10,
      practicalMarks: 21,
      externalMarks: 70,
      totalMarks: 137,
      grade: 'A+',
      gpa: 4.0,
      remarks: 'Outstanding performance',
      evaluatedBy: 'Dr. Sharma',
      evaluatedDate: new Date('2024-01-13'),
    },
  ];

  for (const report of reports) {
    await db.collection('reports').doc(report.id).set(report);
  }
  console.log(`  ✓ Created ${reports.length} reports`);
}

// Run initialization
initializeFirebase();
