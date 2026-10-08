import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';

// Execute the production refresh/bootstrap, canonical snapshot, controls, and
// persistence methods. Deferred DAO reads model routed pages interleaving with
// startup; filesystem, preferences, and ArkUI services remain test doubles.
// Run with Node.js 22.13+: node --test tests/download-state-refresh.test.mjs
const source = readFileSync(new URL('../entry/src/main/ets/pages/Index.ets', import.meta.url), 'utf8');
const modelSource = readFileSync(new URL('../entry/src/main/ets/download/DownloadModels.ets', import.meta.url), 'utf8');
const parserSource = readFileSync(new URL('../entry/src/main/ets/storage/PreferenceParsers.ets', import.meta.url), 'utf8');
const recordSource = readFileSync(new URL('../entry/src/main/ets/utils/RecordUtils.ets', import.meta.url), 'utf8');

function productionMethod(name) {
  const start = source.search(new RegExp(`\\n  private (?:async )?${name}\\(`));
  assert.notEqual(start, -1, `Missing production method: ${name}`);
  const tail = source.slice(start + 1);
  const end = tail.slice(1).search(/\n  (?:private |aboutTo|@Builder)/);
  assert.notEqual(end, -1, `Missing end of production method: ${name}`);
  return tail.slice(0, end + 1);
}

function productionFunction(text, name) {
  const start = text.search(new RegExp(`(?:^|\\n)export function ${name}\\(`));
  assert.notEqual(start, -1, `Missing production function: ${name}`);
  const tail = text.slice(start).trimStart();
  const end = tail.slice(1).search(/\n(?:export )?function /);
  return (end < 0 ? tail : tail.slice(0, end + 1)).replace(/^export /, '');
}

const globals = source.split('\n')
  .filter((line) => /^(?:let|const) (?:sharedDownload\w+|DOWNLOAD_RUNTIME_\w+)\b/.test(line)).join('\n');
const constants = modelSource.split('\n')
  .filter((line) => /^export const (?:DOWNLOAD_STATUS_\w+|DOWNLOAD_DEFAULT_LABEL)\b/.test(line))
  .join('\n').replace(/^export /gm, '');
const fieldNames = [
  'localDao', 'downloadItems', 'downloadLabels', 'downloadWorkerRunning', 'downloadActiveKey',
  'downloadWaitKeys', 'downloadCancelKeys', 'downloadRemovedKeys', 'downloadStartRequestedKeys',
  'downloadRunGenerations', 'downloadPageTransferFractions', 'downloadActiveRequests', 'downloadPersistVersions',
  'downloadRuntimeHeartbeatLastWriteAt', 'downloadQueueRevision', 'downloadManagerStatus',
  'downloadStateLoadSerial', 'downloadStateLoading',
  'downloadRuntimeItemsJson', 'downloadRuntimeActiveKey', 'downloadRuntimeWorkerRunning', 'downloadRuntimeRevision'
];
const fields = fieldNames.map((name) => {
  const field = source.split('\n').find((line) =>
    new RegExp(`\\b${name}\\??\\s*:`).test(line) && line.trimEnd().endsWith(';'));
  assert.ok(field, `Missing production field: ${name}`);
  return field;
}).join('\n').replace(/@\w+(?:\([^)]*\))?\s*/g, '');
const methods = [
  'loadDownloadState', 'syncDownloadStateFromDatabase', 'loadDownloadItemsFromDatabase', 'loadDownloadLabelsFromDatabase',
  'upsertDownloadItemToDatabase', 'upsertDownloadLabelToDatabase', 'scheduleDownloadItemPersist',
  'saveDownloadItems', 'saveDownloadLabels', 'parseDownloadItems', 'reconcileDownloadItemsWithLocalFiles',
  'recoverInterruptedDownloads', 'refreshDownloadManagerStatusFromState',
  'downloadKey', 'toDownloadItem', 'cloneDownloadItem', 'normalizeDownloadStatus', 'downloadUsesOriginalImage',
  'ensureDownloadRuntimeStorageDefaults', 'runtimeStringArray', 'updateRuntimeStringArray', 'isRuntimeStringArrayMarked',
  'publishDownloadRuntimeStorage', 'writeDownloadRuntimeHeartbeat', 'runtimeDownloadItemsSnapshot',
  'findDownloadItem', 'findDownloadItemByKey', 'sharedDownloadItemByKey', 'downloadItemsSource', 'downloadDisplayItem',
  'isDownloadKeyCancelled', 'isDownloadKeyRemoved', 'markDownloadKeyRemoved', 'filterRemovedDownloadItems',
  'isDownloadKeyRunningInCurrentProcess', 'activeDownloadRuntimeKey', 'isDownloadItemRunning', 'isDownloadItemQueued',
  'publishSharedDownloadItems', 'bumpDownloadQueueRevision', 'replaceDownloadItem', 'replaceDownloadItemInternal',
  'currentDownloadRunGeneration', 'bumpDownloadRunGeneration', 'pauseDownloadItem',
  'removeSharedDownloadWaitKey', 'clearDownloadTransferProgress', 'cancelDownloadActiveRequests',
  'registerDownloadActiveRequest'
];
const functions = [
  ...['readObjectString', 'readObjectNumber'].map((name) => productionFunction(recordSource, name)),
  ...['parseLocalGalleryRecord', 'normalizeDownloadPageErrors', 'parseDownloadPageErrors',
    'parseDownloadPageErrorsFromObject', 'parseDownloadLabels', 'ensureDownloadDefaultLabel']
    .map((name) => productionFunction(parserSource, name))
];
const harnessSource = stripTypeScriptTypes(`(() => {
  ${globals}
  ${constants}
  ${functions.join('\n')}
  return {
    Harness: class DownloadRefreshHarness {
      ${fields}
      ${methods.map(productionMethod).join('\n')}
    },
    seed(items: DownloadQueueItem[], running: boolean = false, activeKey: string = ''): void {
      sharedDownloadItemsSnapshot = items;
      sharedDownloadItemsInitialized = true;
      sharedDownloadWorkerRunning = running;
      sharedDownloadActiveKey = activeKey;
    },
    initialized(): boolean { return sharedDownloadItemsInitialized; },
    flushPersistence(): Promise<void> { return sharedDownloadPersistQueue; }
  };
})()`);

function item(overrides = {}) {
  return {
    gid: 123, site: 'e', token: 'token', title: 'Gallery', titleJpn: '', cover: '',
    detailUrl: 'https://gallery.example/g/123/token/', uploader: 'uploader',
    categoryLabel: 'Manga', posted: 'posted', pages: 100, language: 'Japanese', rating: 4,
    status: 'downloading', label: 'default', queuedAt: 'queued', lastAction: 'downloading',
    downloaded: 12, total: 100, failedCount: 0, archiveUri: '', createdAt: 'created',
    updatedAt: 'updated', currentPage: 12, currentPageLabel: '12/100',
    speedBytesPerSecond: 4096, remainingSeconds: 30, downloadDir: '/public/e-123',
    error: '', pageErrors: [], ...overrides
  };
}

function deferred() {
  let resolve;
  const promise = new Promise((accept) => { resolve = accept; });
  return { promise, resolve };
}

function createRuntime() {
  const storage = new Map();
  const preferences = new Map();
  const persistence = [];
  const reads = [];
  const viewUpdates = [];
  let revision = 0;
  const runtime = vm.runInNewContext(harnessSource, {
    AppStorage: {
      has: (key) => storage.has(key), get: (key) => storage.get(key),
      setOrCreate: (key, value) => storage.set(key, value)
    },
    GallerySite: { E: 'e', EX: 'ex' },
    clampNumber: (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum)
  });
  const links = {
    downloadRuntimeItemsJson: 'download_runtime_items_snapshot',
    downloadRuntimeActiveKey: 'download_runtime_active_key',
    downloadRuntimeWorkerRunning: 'download_runtime_worker_running',
    downloadRuntimeRevision: 'download_runtime_revision'
  };

  function dao({ loadItems = async () => [], loadLabels = async () => [] } = {}) {
    return {
      loadDownloadItems() { reads.push('items'); return loadItems(); },
      loadDownloadLabels() { reads.push('labels'); return loadLabels(); },
      async upsertDownloadItem(current) { persistence.push(JSON.parse(JSON.stringify(current))); },
      async upsertDownloadLabel() {}
    };
  }

  function page(items = [], database = dao()) {
    const page = new Proxy(new runtime.Harness(), {
      get(target, property, receiver) {
        if (links[property] && storage.has(links[property])) return storage.get(links[property]);
        return Reflect.get(target, property, receiver);
      },
      set(target, property, value) {
        if (links[property]) storage.set(links[property], value);
        target[property] = value;
        return true;
      }
    });
    page.downloadItems = items;
    page.localDao = database ?? undefined;
    page.readString = (key, fallback) => preferences.get(key) ?? fallback;
    page.writeValue = (key, value) => preferences.set(key, value);
    page.nowLabel = () => `updated-${++revision}`;
    // Local file discovery is an I/O boundary; execute the real reconciliation
    // loop while reporting no directory migration or discovered page changes.
    page.restoreExistingDownloadDirectory = (current) => current;
    page.downloadedFileCountForItem = () => -1;
    page.readBoolean = () => false;
    page.reconcileDownloadViewMode = (preferred) => viewUpdates.push({ page, preferred });
    page.refreshDownloadRuntimeState = () => {};
    return page;
  }
  return { ...runtime, page, dao, storage, preferences, persistence, reads, viewUpdates };
}

function ids(page) {
  return Array.from(page.downloadItemsSource(), (current) => current.gid).sort((a, b) => a - b);
}

test('adding a sibling while an observer awaits labels preserves the latest canonical queue', async () => {
  const runtime = createRuntime();
  const labels = deferred();
  runtime.seed([item()], true, 'e-123');
  const owner = runtime.page();
  const observer = runtime.page([], runtime.dao({ loadLabels: () => labels.promise }));
  const refresh = observer.syncDownloadStateFromDatabase(false);
  assert.equal(observer.downloadStateLoading, true);
  owner.replaceDownloadItem(item({ gid: 456, status: 'waiting', title: 'New sibling' }));
  assert.deepEqual(ids(owner), [123, 456]);
  const revisionBeforeRefresh = runtime.storage.get('download_runtime_revision');
  labels.resolve([]);
  await refresh;
  assert.deepEqual(ids(owner), [123, 456]);
  assert.deepEqual(ids(observer), [123, 456]);
  assert.deepEqual(Array.from(observer.downloadItems, (current) => current.gid).sort((a, b) => a - b), [123, 456]);
  assert.ok(runtime.storage.get('download_runtime_revision') > revisionBeforeRefresh);
  assert.equal(owner.findDownloadItemByKey('e-456').title, 'New sibling');
  assert.deepEqual(runtime.reads, ['labels'], 'An initialized canonical snapshot needs no item DB read');
  assert.deepEqual(JSON.parse(runtime.storage.get('download_runtime_items_snapshot'))
    .map((current) => current.gid).sort((a, b) => a - b), [123, 456]);
  assert.equal(observer.downloadStateLoading, false);
});

test('pausing during a label read retains the latest pause command, progress, and sibling', async () => {
  const runtime = createRuntime();
  const labels = deferred();
  runtime.seed([item(), item({ gid: 456, status: 'failed', downloaded: 30 })], true, 'e-123');
  const owner = runtime.page();
  const observer = runtime.page([], runtime.dao({ loadLabels: () => labels.promise }));
  let destroyed = 0;
  owner.registerDownloadActiveRequest('e-123', { destroy() { destroyed++; } });
  const refresh = observer.syncDownloadStateFromDatabase(false);
  owner.replaceDownloadItem(item({ downloaded: 42, currentPage: 43, currentPageLabel: '43/100' }));
  owner.pauseDownloadItem(item());
  const pausedGeneration = owner.currentDownloadRunGeneration('e-123');
  const revisionBeforeRefresh = runtime.storage.get('download_runtime_revision');
  labels.resolve([]);
  await refresh;
  const current = observer.findDownloadItemByKey('e-123');
  assert.equal(current.status, 'paused');
  assert.equal(current.downloaded, 42);
  assert.equal(current.currentPage, 43);
  assert.equal(current.speedBytesPerSecond, 0);
  assert.equal(observer.currentDownloadRunGeneration('e-123'), pausedGeneration);
  assert.equal(observer.isDownloadKeyCancelled('e-123'), true);
  assert.equal(destroyed, 1);
  assert.equal(observer.findDownloadItemByKey('e-456').downloaded, 30);
  assert.equal(observer.downloadItems.find((current) => current.gid === 123).status, 'paused');
  assert.equal(observer.downloadItems.find((current) => current.gid === 123).downloaded, 42);
  assert.ok(runtime.storage.get('download_runtime_revision') > revisionBeforeRefresh);
  const published = JSON.parse(runtime.storage.get('download_runtime_items_snapshot'));
  assert.equal(published.find((current) => current.gid === 123).status, 'paused');
  assert.equal(published.find((current) => current.gid === 123).downloaded, 42);
  assert.equal(published.find((current) => current.gid === 456).downloaded, 30);
});

test('a canonical initialized by another page during an item DB read wins over the old DB array', async () => {
  const runtime = createRuntime();
  const items = deferred();
  const observer = runtime.page([], runtime.dao({ loadItems: () => items.promise }));
  const refresh = observer.syncDownloadStateFromDatabase(true);
  assert.equal(runtime.initialized(), false);
  const owner = runtime.page([], null);
  owner.replaceDownloadItem(item({ gid: 456, status: 'paused', downloaded: 27 }));
  const revisionBeforeRefresh = runtime.storage.get('download_runtime_revision');
  items.resolve([item({ gid: 123, downloaded: 1 })]);
  await refresh;
  assert.deepEqual(ids(observer), [456]);
  assert.deepEqual(Array.from(observer.downloadItems, (current) => current.gid), [456]);
  assert.ok(runtime.storage.get('download_runtime_revision') > revisionBeforeRefresh);
  assert.equal(observer.findDownloadItemByKey('e-456').downloaded, 27);
  assert.equal(observer.findDownloadItemByKey('e-456').status, 'paused');
  assert.deepEqual(runtime.reads, ['items', 'labels']);
});

test('an older refresh resolving last cannot replace newer labels or publish another stale revision', async () => {
  const runtime = createRuntime();
  const older = deferred();
  const newer = deferred();
  let calls = 0;
  runtime.seed([item({ status: 'paused' })]);
  const observer = runtime.page([], runtime.dao({ loadLabels: () => ++calls === 1 ? older.promise : newer.promise }));
  const oldRefresh = observer.syncDownloadStateFromDatabase(false, false);
  const newRefresh = observer.syncDownloadStateFromDatabase(false, true);
  assert.equal(observer.downloadStateLoadSerial, 2);
  newer.resolve([{ label: 'New labels', createdAt: 'new' }]);
  await newRefresh;
  const publishedRevision = runtime.storage.get('download_runtime_revision');
  older.resolve([{ label: 'Old labels', createdAt: 'old' }]);
  await oldRefresh;
  assert.deepEqual(Array.from(observer.downloadLabels, (label) => label.label), ['默认', 'New labels']);
  assert.equal(runtime.storage.get('download_runtime_revision'), publishedRevision);
  assert.equal(runtime.viewUpdates.length, 1);
  assert.equal(runtime.viewUpdates[0].preferred, true);
  assert.equal(observer.downloadStateLoading, false);
});

test('an obsolete refresh finishing first cannot clear the newest refresh loading state', async () => {
  const runtime = createRuntime();
  const older = deferred();
  const newer = deferred();
  let calls = 0;
  runtime.seed([item({ status: 'paused' })]);
  const observer = runtime.page([], runtime.dao({ loadLabels: () => ++calls === 1 ? older.promise : newer.promise }));
  const oldRefresh = observer.syncDownloadStateFromDatabase(false);
  const newRefresh = observer.syncDownloadStateFromDatabase(false);
  older.resolve([{ label: 'Obsolete', createdAt: 'old' }]);
  await oldRefresh;
  assert.equal(observer.downloadStateLoading, true);
  assert.equal(runtime.storage.has('download_runtime_revision'), false);
  assert.equal(observer.downloadLabels.length, 0);
  newer.resolve([{ label: 'Current', createdAt: 'new' }]);
  await newRefresh;
  assert.equal(observer.downloadStateLoading, false);
  assert.equal(observer.downloadLabels.some((label) => label.label === 'Current'), true);
});

test('a cold page without a DAO cannot publish an empty canonical or bypass a later item DB read', async () => {
  const runtime = createRuntime();
  const observer = runtime.page([], null);
  await observer.syncDownloadStateFromDatabase(false);
  assert.equal(runtime.initialized(), false);
  assert.equal(runtime.storage.has('download_runtime_items_snapshot'), false);
  assert.equal(runtime.storage.has('download_runtime_revision'), false);
  assert.equal(observer.downloadStateLoadSerial, 0);
  assert.equal(observer.downloadStateLoading, false);
  assert.deepEqual(runtime.reads, []);
  observer.localDao = runtime.dao({ loadItems: async () => [item({ status: 'paused', downloaded: 19 })] });
  await observer.syncDownloadStateFromDatabase(false);
  assert.deepEqual(runtime.reads, ['items', 'labels']);
  assert.deepEqual(ids(observer), [123]);
  assert.equal(observer.findDownloadItemByKey('e-123').downloaded, 19);
});

for (const readStage of ['items', 'labels']) {
  test(`bootstrap merges persisted missing tasks after the ${readStage} read, preserves live edits, and excludes removals`, async () => {
    const runtime = createRuntime();
    const gate = deferred();
    const entered = deferred();
    const storedItems = [
      item({ downloaded: 1 }),
      item({ gid: 456, status: 'waiting', downloaded: 31 }),
      item({ gid: 789, status: 'done', downloaded: 100 })
    ];
    const bootstrap = runtime.page([], runtime.dao({
      loadItems: () => {
        if (readStage === 'items') { entered.resolve(); return gate.promise; }
        return Promise.resolve(storedItems);
      },
      loadLabels: () => {
        if (readStage === 'labels') { entered.resolve(); return gate.promise; }
        return Promise.resolve([]);
      }
    }));
    const load = bootstrap.loadDownloadState();
    await entered.promise;
    const earlyPage = runtime.page([], null);
    earlyPage.replaceDownloadItem(item({ status: 'paused', downloaded: 42, lastAction: 'Early pause' }));
    earlyPage.replaceDownloadItem(item({ gid: 999, status: 'waiting', downloaded: 0, title: 'Early new task' }));
    earlyPage.markDownloadKeyRemoved('e-789');
    assert.equal(runtime.persistence.length, 0, 'Actions before DAO preparation are not written prematurely');
    gate.resolve(readStage === 'items' ? storedItems : []);
    await load;
    await runtime.flushPersistence();
    assert.deepEqual(ids(bootstrap), [123, 456, 999]);
    assert.deepEqual(ids(earlyPage), [123, 456, 999]);
    const current = bootstrap.findDownloadItemByKey('e-123');
    assert.equal(current.status, 'paused');
    assert.equal(current.downloaded, 42);
    assert.equal(current.lastAction, 'Early pause');
    const recovered = bootstrap.findDownloadItemByKey('e-456');
    assert.equal(recovered.status, 'paused');
    assert.equal(recovered.downloaded, 31);
    assert.equal(recovered.speedBytesPerSecond, 0);
    assert.equal(bootstrap.findDownloadItemByKey('e-789'), undefined);
    const persisted = new Map(runtime.persistence.map((current) => [current.gid, current]));
    assert.deepEqual([...persisted.keys()].sort((a, b) => a - b), [123, 456, 999]);
    assert.equal(persisted.get(123).downloaded, 42);
    assert.equal(persisted.get(999).title, 'Early new task');
    assert.equal(persisted.get(456).status, 'paused');
    const preferenceItems = JSON.parse(runtime.preferences.get('download_items'));
    assert.deepEqual(preferenceItems.map((current) => current.gid).sort((a, b) => a - b), [123, 456, 999]);
  });
}

test('bootstrap falls back to preference tasks without reviving removals or merging equal IDs across sites', async () => {
  const runtime = createRuntime();
  const items = deferred();
  runtime.preferences.set('download_items', JSON.stringify([
    item({ gid: 321, status: 'waiting', downloaded: 9 }),
    item({ site: 'ex', status: 'failed', downloaded: 25, error: 'Stored failure' }),
    item({ gid: 789, status: 'done', downloaded: 100 })
  ]));
  const bootstrap = runtime.page([], runtime.dao({ loadItems: () => items.promise }));
  const load = bootstrap.loadDownloadState();
  const earlyPage = runtime.page([], null);
  earlyPage.replaceDownloadItem(item({ status: 'paused', downloaded: 42 }));
  earlyPage.markDownloadKeyRemoved('e-789');
  items.resolve([]);
  await load;
  await runtime.flushPersistence();
  assert.deepEqual(Array.from(bootstrap.downloadItemsSource(), (current) =>
    bootstrap.downloadKey(current.gid, current.site)).sort(), ['e-123', 'e-321', 'ex-123']);
  assert.equal(bootstrap.findDownloadItemByKey('e-123').downloaded, 42);
  assert.equal(bootstrap.findDownloadItemByKey('ex-123').downloaded, 25);
  assert.equal(bootstrap.findDownloadItemByKey('ex-123').error, 'Stored failure');
  assert.equal(bootstrap.findDownloadItemByKey('e-321').status, 'paused');
  assert.equal(bootstrap.findDownloadItemByKey('e-321').downloaded, 9);
  assert.equal(bootstrap.findDownloadItemByKey('e-789'), undefined);
  assert.equal(runtime.persistence.some((current) => current.gid === 789), false);
});
