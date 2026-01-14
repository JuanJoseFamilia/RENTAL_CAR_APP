/**
 * scripts/migrate_vehicles.js
 * Usage:
 *  - Dry run (no writes): node migrate_vehicles.js --dry-run --limit=10
 *  - Apply changes: node migrate_vehicles.js --limit=0  (0 or unspecified means all)
 *
 * Requirements:
 *  - Set GOOGLE_APPLICATION_CREDENTIALS to a service account JSON with Firestore access
 *  - npm install firebase-admin
 *
 * The script will:
 *  - Ensure `imagenes` is an array (copy from `imagenUrl` if missing)
 *  - Ensure `imagenPortada` exists (use first image)
 *  - Normalize numeric fields and `disponible` boolean
 *  - Convert `fechaCreacion` strings to Firestore Timestamps when possible
 */

const admin = require('firebase-admin');
const argv = require('yargs/yargs')(process.argv.slice(2)).argv;

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.warn('NOTICE: GOOGLE_APPLICATION_CREDENTIALS is not set. The script may still work if your environment is authenticated.');
}

admin.initializeApp();
const db = admin.firestore();

const DRY_RUN = !!argv['dry-run'] || !!argv['dryrun'] || !!argv.dry;
const LIMIT = argv.limit ? parseInt(argv.limit, 10) : 0; // 0 means all

function toNumber(v) {
  if (v === null || v === undefined) return null;
  const n = Number(v);
  return isNaN(n) ? null : n;
}

async function run() {
  console.log('Starting migration of vehicles...');

  let q = db.collection('vehicles').orderBy('fechaCreacion', 'desc');
  if (LIMIT > 0) q = q.limit(LIMIT);

  const snapshot = await q.get();
  console.log(`Documents to check: ${snapshot.size}`);

  const batchLimit = 400;
  let batch = db.batch();
  let ops = 0;
  let totalUpdated = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const updates = {};

    // imagenes
    if (!Array.isArray(data.imagenes) || data.imagenes.length === 0) {
      if (data.imagenUrl && typeof data.imagenUrl === 'string' && data.imagenUrl.trim() !== '') {
        updates.imagenes = [data.imagenUrl.trim()];
      } else {
        updates.imagenes = [];
      }
    }

    // imagenPortada
    if (!data.imagenPortada) {
      if (updates.imagenes && updates.imagenes.length > 0) {
        updates.imagenPortada = updates.imagenes[0];
      } else if (data.imagenUrl) {
        updates.imagenPortada = data.imagenUrl;
      }
    }

    // fechaCreacion -> Timestamp if string
    if (data.fechaCreacion && typeof data.fechaCreacion === 'string') {
      const d = new Date(data.fechaCreacion);
      if (!isNaN(d.getTime())) {
        updates.fechaCreacion = admin.firestore.Timestamp.fromDate(d);
      }
    }

    // normalize numeric fields
    const numberFields = ['precioPorDia', 'anio', 'capacidad', 'totalCalificaciones', 'calificacionPromedio'];
    for (const f of numberFields) {
      if (data[f] !== undefined) {
        const n = toNumber(data[f]);
        if (n !== null) updates[f] = n;
      }
    }

    // disponible boolean
    if (data.disponible !== undefined && typeof data.disponible !== 'boolean') {
      updates.disponible = (String(data.disponible).toLowerCase() === 'true');
    }

    if (Object.keys(updates).length > 0) {
      if (DRY_RUN) {
        console.log(`DRY RUN - Would update doc ${doc.id} with:`, updates);
      } else {
        batch.update(doc.ref, updates);
        ops++;
        totalUpdated++;
        if (ops >= batchLimit) {
          await batch.commit();
          batch = db.batch();
          ops = 0;
        }
      }
    }
  }

  if (!DRY_RUN && ops > 0) await batch.commit();

  console.log('Migration finished.');
  if (DRY_RUN) console.log('Dry run: no documents were modified.');
  else console.log(`Total documents updated: ${totalUpdated}`);
}

run().catch(err => {
  console.error('Migration error:', err);
  process.exit(1);
});
