const { createApp } = require('./app');
const { createDb } = require('./db');

const PORT = Number(process.env.PORT) || 3000;
const HOST = process.env.HOST || '0.0.0.0'; // 0.0.0.0 so emulators/devices on LAN can reach it

// Last-resort logging for bugs that escape the request pipeline.
process.on('unhandledRejection', (reason) => console.error('Unhandled rejection:', reason));

const db = createDb();
const app = createApp(db);

app.listen(PORT, HOST, () => {
  console.log(`VardiGO API → http://localhost:${PORT}/api`);
  console.log('Android emulator için: http://10.0.2.2:' + PORT + '/api');
});
