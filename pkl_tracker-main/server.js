const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const multer = require('multer');
const { Pool } = require('pg');
const { v2: cloudinary } = require('cloudinary');

const app = express();
const port = Number(process.env.PORT || 3000);
if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL wajib diatur pada environment backend.');
}
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_SSL === 'false' ? false : { rejectUnauthorized: false },
});
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { files: 5, fileSize: 10 * 1024 * 1024 },
});

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});
const cloudinaryConfigured = Boolean(
  process.env.CLOUDINARY_CLOUD_NAME &&
  process.env.CLOUDINARY_API_KEY &&
  process.env.CLOUDINARY_API_SECRET,
);

app.use(cors());
app.use(express.json({ limit: '1mb' }));

async function initializeDatabase() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id BIGSERIAL PRIMARY KEY, uid TEXT NOT NULL UNIQUE, name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE, password TEXT NOT NULL, role TEXT NOT NULL,
      no_induk TEXT, sekolah TEXT, jurusan TEXT, alamat TEXT, photo_url TEXT,
      phone TEXT, guru_uid TEXT, pkl_place_name TEXT, pkl_place_address TEXT,
      pkl_lat DOUBLE PRECISION, pkl_lng DOUBLE PRECISION,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
    CREATE TABLE IF NOT EXISTS logbooks (
      uid TEXT PRIMARY KEY, user_id TEXT NOT NULL, tanggal TEXT NOT NULL,
      kegiatan TEXT NOT NULL, foto_bukti TEXT, status TEXT NOT NULL DEFAULT 'menunggu',
      catatan_guru TEXT, guru_id TEXT, location_lat DOUBLE PRECISION,
      location_lng DOUBLE PRECISION, location_address TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
    CREATE TABLE IF NOT EXISTS presensi (
      id BIGSERIAL PRIMARY KEY, payload JSONB NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);
}

function publicUser(row) {
  return {
    id: row.id, uid: row.uid, name: row.name, email: row.email, role: row.role,
    no_induk: row.no_induk, sekolah: row.sekolah, jurusan: row.jurusan,
    alamat: row.alamat, photo_url: row.photo_url, phone: row.phone,
    guru_uid: row.guru_uid, pkl_place_name: row.pkl_place_name,
    pkl_place_address: row.pkl_place_address, pkl_lat: row.pkl_lat,
    pkl_lng: row.pkl_lng, created_at: row.created_at,
  };
}

app.get('/api/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ ok: true, cloudinary: cloudinaryConfigured });
  } catch (error) {
    console.error('Health check failed:', error);
    res.status(503).json({ ok: false, error: 'Database tidak tersedia' });
  }
});

app.post('/api/users', async (req, res) => {
  const p = req.body;
  if (!p.uid || !p.email || !p.name || !p.role || !p.password) {
    res.status(400).json({ ok: false, error: 'Data user tidak lengkap' });
    return;
  }
  try {
    const result = await pool.query(
      `INSERT INTO users
       (uid,name,email,password,role,no_induk,sekolah,jurusan,alamat,photo_url,phone,
        guru_uid,pkl_place_name,pkl_place_address,pkl_lat,pkl_lng,created_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)
       ON CONFLICT (uid) DO UPDATE SET
        name=EXCLUDED.name,email=EXCLUDED.email,role=EXCLUDED.role,
        no_induk=EXCLUDED.no_induk,sekolah=EXCLUDED.sekolah,jurusan=EXCLUDED.jurusan,
        alamat=EXCLUDED.alamat,photo_url=EXCLUDED.photo_url,phone=EXCLUDED.phone,
        guru_uid=EXCLUDED.guru_uid,pkl_place_name=EXCLUDED.pkl_place_name,
        pkl_place_address=EXCLUDED.pkl_place_address,pkl_lat=EXCLUDED.pkl_lat,pkl_lng=EXCLUDED.pkl_lng
       RETURNING *`,
      [p.uid, p.name, p.email, await bcrypt.hash(p.password, 12), p.role,
       p.no_induk ?? null, p.sekolah ?? null, p.jurusan ?? null, p.alamat ?? null,
       p.photo_url ?? null, p.phone ?? null, p.guru_uid ?? null, p.pkl_place_name ?? null,
       p.pkl_place_address ?? null, p.pkl_lat ?? null, p.pkl_lng ?? null,
       p.created_at ?? new Date().toISOString()],
    );
    res.json({ ok: true, user: publicUser(result.rows[0]) });
  } catch (error) {
    console.error('User save failed:', error);
    res.status(error.code === '23505' ? 409 : 500).json({
      ok: false, error: error.code === '23505' ? 'Email sudah digunakan' : 'Gagal menyimpan user',
    });
  }
});

app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    res.status(400).json({ ok: false, error: 'Email dan password wajib diisi' });
    return;
  }
  try {
    const result = await pool.query(
      'SELECT * FROM users WHERE LOWER(email)=LOWER($1) LIMIT 1', [email],
    );
    const user = result.rows[0];
    if (!user || !(await bcrypt.compare(password, user.password))) {
      res.status(401).json({ ok: false, error: 'Email atau password salah' });
      return;
    }
    res.json({ ok: true, user: publicUser(user) });
  } catch (error) {
    console.error('Login failed:', error);
    res.status(500).json({ ok: false, error: 'Login gagal' });
  }
});

app.get('/api/users', async (req, res) => {
  const result = await pool.query('SELECT * FROM users ORDER BY id DESC');
  res.json(result.rows.map(publicUser));
});

app.get('/api/users/:uid', async (req, res) => {
  const result = await pool.query('SELECT * FROM users WHERE uid=$1 LIMIT 1', [req.params.uid]);
  res.json(result.rows[0] ? publicUser(result.rows[0]) : null);
});

app.post('/api/logbook', async (req, res) => {
  const p = req.body;
  if (!p.uid || !p.user_id || !p.tanggal || !p.kegiatan) {
    res.status(400).json({ ok: false, error: 'Data logbook tidak lengkap' });
    return;
  }
  const result = await pool.query(
    `INSERT INTO logbooks
     (uid,user_id,tanggal,kegiatan,foto_bukti,status,catatan_guru,guru_id,
      location_lat,location_lng,location_address)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
     ON CONFLICT (uid) DO UPDATE SET
      user_id=EXCLUDED.user_id,tanggal=EXCLUDED.tanggal,kegiatan=EXCLUDED.kegiatan,
      foto_bukti=EXCLUDED.foto_bukti,status=EXCLUDED.status,
      catatan_guru=EXCLUDED.catatan_guru,guru_id=EXCLUDED.guru_id,
      location_lat=EXCLUDED.location_lat,location_lng=EXCLUDED.location_lng,
      location_address=EXCLUDED.location_address
     RETURNING *`,
    [p.uid, p.user_id, p.tanggal, p.kegiatan, p.foto_bukti ?? null,
     p.status ?? 'menunggu', p.catatan_guru ?? null, p.guru_id ?? null,
     p.location_lat ?? null, p.location_lng ?? null, p.location_address ?? null],
  );
  res.status(201).json({ ok: true, logbook: result.rows[0] });
});

function uploadToCloudinary(file) {
  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      { folder: 'pkl-tracker/logbooks', resource_type: 'image' },
      (error, result) => (error ? reject(error) : resolve(result.secure_url)),
    );
    stream.end(file.buffer);
  });
}

app.post('/api/logbook/upload', upload.array('photos', 5), async (req, res) => {
  try {
    if (!cloudinaryConfigured) {
      res.status(503).json({
        ok: false,
        error: 'Cloudinary belum dikonfigurasi pada environment backend',
      });
      return;
    }
    if (!req.files || req.files.length === 0) {
      res.status(400).json({ ok: false, error: 'Minimal satu foto wajib dipilih' });
      return;
    }
    const photoUrls = await Promise.all((req.files || []).map(uploadToCloudinary));
    const payload = {
      uid: req.body.uid,
      user_id: req.body.user_id || req.body.userId,
      tanggal: req.body.tanggal,
      kegiatan: req.body.kegiatan || req.body.activity,
      foto_bukti: photoUrls.join(','),
      status: req.body.status || 'menunggu',
      location_lat: req.body.location_lat ? Number(req.body.location_lat) : null,
      location_lng: req.body.location_lng ? Number(req.body.location_lng) : null,
      location_address: req.body.location_address || null,
    };
    if (!payload.uid || !payload.user_id || !payload.tanggal || !payload.kegiatan) {
      res.status(400).json({ ok: false, error: 'Data logbook tidak lengkap' });
      return;
    }
    const result = await pool.query(
      `INSERT INTO logbooks
       (uid,user_id,tanggal,kegiatan,foto_bukti,status,location_lat,location_lng,location_address)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       ON CONFLICT (uid) DO UPDATE SET foto_bukti=EXCLUDED.foto_bukti,
        kegiatan=EXCLUDED.kegiatan,status=EXCLUDED.status,
        location_lat=EXCLUDED.location_lat,location_lng=EXCLUDED.location_lng,
        location_address=EXCLUDED.location_address
       RETURNING *`,
      [payload.uid, payload.user_id, payload.tanggal, payload.kegiatan, payload.foto_bukti,
       payload.status, payload.location_lat, payload.location_lng, payload.location_address],
    );
    res.status(201).json({ ok: true, logbook: result.rows[0] });
  } catch (error) {
    console.error('Cloudinary/database upload failed:', error);
    res.status(502).json({ ok: false, error: 'Upload foto gagal' });
  }
});

app.use((error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    res.status(400).json({ ok: false, error: `Upload foto ditolak: ${error.message}` });
    return;
  }
  console.error('Unhandled API error:', error);
  res.status(500).json({ ok: false, error: 'Terjadi kesalahan pada server' });
});

app.post('/api/presensi', async (req, res) => {
  await pool.query('INSERT INTO presensi (payload) VALUES ($1)', [req.body]);
  res.json({ ok: true });
});

app.get('/api/presensi', async (req, res) => {
  const result = await pool.query('SELECT payload FROM presensi ORDER BY id DESC');
  res.json(result.rows.map((row) => row.payload));
});

app.get('/api/logbook', async (req, res) => {
  const result = req.query.user_id
    ? await pool.query('SELECT * FROM logbooks WHERE user_id=$1 ORDER BY created_at DESC', [req.query.user_id])
    : await pool.query('SELECT * FROM logbooks ORDER BY created_at DESC');
  res.json(result.rows);
});

app.get('/api/snapshot', async (req, res) => {
  const result = await pool.query(`
    SELECT (SELECT COUNT(*) FROM users)::int AS users,
           (SELECT COUNT(*) FROM logbooks)::int AS logbooks,
           (SELECT COUNT(*) FROM presensi)::int AS presensi`);
  res.json(result.rows[0]);
});

initializeDatabase()
  .then(() => app.listen(port, () => console.log(`API listening on port ${port}`)))
  .catch((error) => {
    console.error('Database initialization failed:', error);
    process.exit(1);
  });
