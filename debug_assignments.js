const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}
const db = admin.firestore();

async function checkData() {
    console.log('--- ASSIGNMENTS_MASTER ---');
    const assignments = await db.collection('assignments_master').limit(5).get();
    assignments.docs.forEach(d => console.log(d.id, JSON.stringify(d.data())));
}

checkData();
