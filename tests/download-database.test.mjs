import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { DatabaseSync } from 'node:sqlite';
import test from 'node:test';
import vm from 'node:vm';

// Execute the production DAO's schema, load query, row mapping, and seed mapping
// against Node's in-memory SQLite. A ResultSet adapter models the HarmonyOS RDB
// interface; this is not a device test of relationalStore or ArkTS compilation.
// Run with Node.js 22.13+: node --test tests/download-database.test.mjs
const source = readFileSync(new URL('../entry/src/main/ets/data/EhLocalDataDao.ets', import.meta.url), 'utf8');
const models = readFileSync(new URL('../entry/src/main/ets/download/DownloadModels.ets', import.meta.url), 'utf8');
const appConstants = readFileSync(new URL('../entry/src/main/ets/constants/AppConstants.ets', import.meta.url), 'utf8');

function productionMethod(name) {
  const start = source.search(new RegExp(`\\n  (?:private )?(?:async )?${name}\\(`));
  assert.notEqual(start, -1, `Missing production DAO method: ${name}`);
  const tail = source.slice(start + 1);
  const next = tail.slice(1).search(/\n  (?:private |async |static )/);
  return next < 0 ? tail.slice(0, tail.lastIndexOf('\n}')) : tail.slice(0, next + 1);
}

const constants = [...models.split('\n'), ...appConstants.split('\n')]
  .filter((line) => /^export const (?:DOWNLOAD_STATUS_\w+|DOWNLOAD_DEFAULT_LABEL|\w+_TABLE)\b/.test(line))
  .join('\n').replace(/^export /gm, '');
const schemaExpression = source.match(
  /await this\.store\.executeSql\(\s*(`CREATE TABLE IF NOT EXISTS \$\{DOWNLOAD_TABLE\}[\s\S]+?)\n    \);/
)?.[1];
assert.ok(schemaExpression, 'Missing production download-table schema');
const methods = [
  'loadDownloadItems', 'galleryRecordFromResult', 'resultString', 'resultNumber',
  'normalizeDownloadStatus', 'parseDownloadPageErrors', 'readObjectString', 'readObjectNumber',
  'downloadItemToBucket', 'downloadKey', 'ensureSchema', 'ensureDownloadImageQualityColumn',
  'nowLabel', 'downloadLabelToBucket', 'upsertDownloadItem'
];
const harnessSource = stripTypeScriptTypes(`(() => {
  ${constants}
  return {
    schema: ${schemaExpression},
    Harness: class DownloadDatabaseHarness {
      constructor(store: Object) { this.store = store; }
      ${methods.map(productionMethod).join('\n')}
    }
  };
})()`);

// Historical schema fixture: it deliberately has no image_quality column.
const legacySchema = `CREATE TABLE downloads (
  download_key TEXT PRIMARY KEY, gid INTEGER NOT NULL,
  token TEXT, title TEXT, title_jpn TEXT, cover TEXT, detail_url TEXT, site TEXT NOT NULL,
  uploader TEXT, category_label TEXT, posted TEXT, pages INTEGER, language TEXT, rating REAL,
  status TEXT NOT NULL, label TEXT NOT NULL, queued_at TEXT, last_action TEXT,
  downloaded INTEGER, total INTEGER, failed_count INTEGER, archive_uri TEXT, created_at TEXT, updated_at TEXT,
  current_page INTEGER, current_page_label TEXT, speed_bps REAL, remaining_seconds INTEGER,
  download_dir TEXT, error TEXT, page_errors TEXT
)`;

function item(gid, overrides = {}) {
  return {
    gid, token: 'token', title: `Gallery ${gid}`, titleJpn: 'title-jpn', cover: 'cover',
    detailUrl: `https://gallery.example/g/${gid}/token/`, site: 'e', uploader: 'uploader',
    categoryLabel: 'Manga', posted: 'posted', pages: 100, language: 'Japanese', rating: 4,
    status: 'paused', label: '默认', queuedAt: 'queued', lastAction: 'paused before restart',
    downloaded: 20, total: 100, failedCount: 1, archiveUri: '', createdAt: 'created',
    updatedAt: String(gid).padStart(8, '0'), currentPage: 20, currentPageLabel: '20/100',
    speedBytesPerSecond: 0, remainingSeconds: -1, downloadDir: `/public/e-${gid}`, error: 'retry page',
    pageErrors: [{ page: 21, message: 'retry page', updatedAt: 'before restart' }], ...overrides
  };
}

function createDatabase(t, items, { failIteration = false, legacy = false } = {}) {
  const database = new DatabaseSync(':memory:');
  t.after(() => database.close());
  const queries = [];
  const results = [];
  const executions = [];
  const production = vm.runInNewContext(harnessSource, {
    GallerySite: { E: 'e', EX: 'ex' },
    relationalStore: { ConflictResolution: { ON_CONFLICT_REPLACE: 'replace', ON_CONFLICT_IGNORE: 'ignore' } }
  });
  database.exec(legacy ? legacySchema : production.schema);
  const store = {
    async executeSql(sql) {
      executions.push(sql);
      database.exec(sql);
    },
    async insert(table, bucket, conflict) {
      const keys = Object.keys(bucket);
      const clause = conflict === 'ignore' ? 'OR IGNORE' : 'OR REPLACE';
      return database.prepare(`INSERT ${clause} INTO ${table} (${keys.join(',')}) VALUES (${keys.map(() => '?').join(',')})`)
        .run(...keys.map((key) => bucket[key])).lastInsertRowid;
    },
    async querySql(sql) {
      queries.push(sql);
      const statement = database.prepare(sql);
      const rows = statement.all();
      const columns = statement.columns().map((column) => column.name);
      let position = -1;
      const result = {
        sql,
        closeCount: 0,
        goToFirstRow() { position = 0; return rows.length > 0; },
        goToNextRow() {
          if (failIteration) throw new Error('Controlled ResultSet iteration failure');
          position++;
          return position < rows.length;
        },
        getColumnIndex(column) { return columns.indexOf(column); },
        getString(index) { return String(rows[position][columns[index]] ?? ''); },
        getDouble(index) { return Number(rows[position][columns[index]]); },
        close() { this.closeCount++; }
      };
      results.push(result);
      return result;
    }
  };
  const dao = new production.Harness(store);
  for (const current of items) {
    const bucket = dao.downloadItemToBucket(current);
    if (legacy) delete bucket.image_quality;
    const keys = Object.keys(bucket);
    database.prepare(`INSERT INTO downloads (${keys.join(',')}) VALUES (${keys.map(() => '?').join(',')})`)
      .run(...keys.map((key) => bucket[key]));
  }
  return { dao, queries, results, executions, database };
}

test('default load executes an unrestricted production query and restores more than 240 tasks', async (t) => {
  const originals = Array.from({ length: 271 }, (_, index) => item(index + 1));
  const { dao, queries, results } = createDatabase(t, originals);
  const loaded = await dao.loadDownloadItems();
  assert.equal(loaded.length, originals.length);
  assert.equal(queries[0], 'SELECT * FROM downloads ORDER BY updated_at DESC');
  assert.deepEqual(Array.from(loaded, (current) => current.gid), originals.map((current) => current.gid).reverse());
  for (const current of [loaded[0], loaded.at(-1)]) {
    const original = originals[current.gid - 1];
    assert.equal(current.downloaded, original.downloaded);
    assert.equal(current.status, original.status);
    assert.equal(current.downloadDir, original.downloadDir);
    assert.equal(current.failedCount, original.failedCount);
    assert.equal(current.pageErrors[0].page, 21);
    assert.equal(current.pageErrors[0].message, 'retry page');
  }
  assert.equal(results[0].closeCount, 1);
});

test('an explicit positive limit still constrains actual SQLite rows in update order', async (t) => {
  const { dao, queries, results } = createDatabase(t, Array.from({ length: 271 }, (_, index) => item(index + 1)));
  const loaded = await dao.loadDownloadItems(17.9);
  assert.equal(queries[0], 'SELECT * FROM downloads ORDER BY updated_at DESC LIMIT 17');
  assert.deepEqual(Array.from(loaded, (current) => current.gid), Array.from({ length: 17 }, (_, index) => 271 - index));
  assert.equal(results[0].closeCount, 1);
});

test('zero, negative, and nonfinite limits keep the complete queue available', async (t) => {
  const { dao, queries, results } = createDatabase(t, Array.from({ length: 261 }, (_, index) => item(index + 1)));
  for (const limit of [0, -1, Number.NaN, Number.POSITIVE_INFINITY]) {
    const loaded = await dao.loadDownloadItems(limit);
    assert.equal(loaded.length, 261);
    assert.equal(queries.at(-1), 'SELECT * FROM downloads ORDER BY updated_at DESC');
    assert.equal(results.at(-1).closeCount, 1);
  }
});

test('invalid records are skipped without losing valid rows and every result set closes', async (t) => {
  const { dao, queries, results } = createDatabase(t, [
    item(1), item(0), item(2, { detailUrl: '' }), item(3, { status: 'queued', pageErrors: [] })
  ]);
  const loaded = await dao.loadDownloadItems();
  assert.deepEqual(Array.from(loaded, (current) => current.gid), [3, 1]);
  assert.equal(loaded[0].status, 'waiting');
  assert.equal(loaded[0].pageErrors.length, 0);
  assert.equal(queries.length, 1);
  assert.equal(results[0].closeCount, 1);
});

test('the production finally block closes the result set even when iteration fails', async (t) => {
  const { dao, results } = createDatabase(t, [item(1), item(2)], { failIteration: true });
  const loaded = await dao.loadDownloadItems();
  assert.equal(loaded.length, 0);
  assert.equal(results[0].closeCount, 1);
});

test('the real schema migration upgrades legacy downloads once while preserving their files and progress', async (t) => {
  const originals = [item(1), item(2, { status: 'failed', downloaded: 87 })];
  const { dao, executions, results, database } = createDatabase(t, originals, { legacy: true });
  assert.equal(database.prepare('PRAGMA table_info(downloads)').all().some((column) => column.name === 'image_quality'), false);
  await dao.ensureSchema();
  await dao.ensureSchema();
  const alters = executions.filter((sql) => /^ALTER TABLE downloads /i.test(sql));
  assert.deepEqual(alters, ["ALTER TABLE downloads ADD COLUMN image_quality TEXT DEFAULT ''"]);
  const column = database.prepare('PRAGMA table_info(downloads)').all().find((current) => current.name === 'image_quality');
  assert.equal(column.type, 'TEXT');
  assert.equal(column.dflt_value, "''");

  const loaded = await dao.loadDownloadItems();
  assert.equal(loaded.length, originals.length);
  for (const current of loaded) {
    const original = originals.find((previous) => previous.gid === current.gid);
    assert.equal(current.imageQuality, '', 'An existing task must not silently change to a new quality');
    assert.equal(current.downloadDir, original.downloadDir);
    assert.equal(current.downloaded, original.downloaded);
    assert.equal(current.status, original.status);
    assert.equal(current.pageErrors[0].message, original.pageErrors[0].message);
  }
  for (const result of results) assert.equal(result.closeCount, 1);
});

test('a new schema already contains the quality column and repeated initialization never alters it', async (t) => {
  const { dao, executions, results, database } = createDatabase(t, []);
  await dao.ensureSchema();
  await dao.ensureSchema();
  assert.equal(executions.some((sql) => /^ALTER TABLE downloads /i.test(sql)), false);
  assert.equal(database.prepare('PRAGMA table_info(downloads)').all().filter((column) => column.name === 'image_quality').length, 1);
  assert.equal(results.filter((result) => result.sql === 'PRAGMA table_info(downloads)').length, 2);
  for (const result of results) assert.equal(result.closeCount, 1);
});

test('production upsert and load restore original and compressed choices independently across tasks and sites', async (t) => {
  const { dao } = createDatabase(t, []);
  const original = item(1, { imageQuality: 'original' });
  const compressed = item(2, { imageQuality: 'compressed' });
  const sameGidOtherSite = item(1, { site: 'ex', imageQuality: 'compressed' });
  for (const current of [original, compressed, sameGidOtherSite, item(3)]) await dao.upsertDownloadItem(current);
  let loaded = await dao.loadDownloadItems();
  const quality = (items, key) => items.find((current) => `${current.site}-${current.gid}` === key)?.imageQuality;
  assert.equal(quality(loaded, 'e-1'), 'original');
  assert.equal(quality(loaded, 'e-2'), 'compressed');
  assert.equal(quality(loaded, 'ex-1'), 'compressed');
  assert.equal(quality(loaded, 'e-3'), '');

  await dao.upsertDownloadItem({ ...original, downloaded: 43, status: 'paused' });
  loaded = await dao.loadDownloadItems();
  assert.equal(loaded.length, 4);
  assert.equal(quality(loaded, 'e-1'), 'original');
  assert.equal(quality(loaded, 'e-2'), 'compressed');
  assert.equal(quality(loaded, 'ex-1'), 'compressed');
  assert.equal(loaded.find((current) => current.gid === 1 && current.site === 'e').downloaded, 43);
});

test('migration closes its PRAGMA result when inspection fails and does not attempt an unverified ALTER', async (t) => {
  const { dao, executions, results } = createDatabase(t, [item(1)], { legacy: true, failIteration: true });
  await assert.rejects(() => dao.ensureSchema(), /Controlled ResultSet iteration failure/);
  assert.equal(results.length, 1);
  assert.equal(results[0].sql, 'PRAGMA table_info(downloads)');
  assert.equal(results[0].closeCount, 1);
  assert.equal(executions.some((sql) => /^ALTER TABLE downloads /i.test(sql)), false);
});
