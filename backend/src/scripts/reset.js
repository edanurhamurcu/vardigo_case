// npm run reset → rebuilds data/db.json from seed/seed.json
const { createDb } = require('../db');

const db = createDb();
db.reset();
console.log('Veritabanı seed verisiyle sıfırlandı.');
