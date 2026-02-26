const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}
const db = admin.firestore();

async function checkData() {
    console.log('--- COURSES ---');
    const courses = await db.collection('courses').limit(5).get();
    courses.docs.forEach(d => console.log(d.id, JSON.stringify(d.data())));

    console.log('\n--- USERS ---');
    const users = await db.collection('users').limit(5).get();
    users.docs.forEach(d => console.log(d.id, JSON.stringify(d.data())));
}

checkData();
