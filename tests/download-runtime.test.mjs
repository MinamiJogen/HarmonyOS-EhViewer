import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';

// Execute Index's production runtime, recovery, and control methods in a shared
// VM. Multiple harness instances model routed Index views and reactive storage.
// This does not run ArkUI, real network requests, database I/O, or device tasks.
// Run with Node.js 22.13+: node --test tests/download-runtime.test.mjs
const source = readFileSync(new URL('../entry/src/main/ets/pages/Index.ets', import.meta.url), 'utf8');
const appConstants = readFileSync(new URL('../entry/src/main/ets/constants/AppConstants.ets', import.meta.url), 'utf8');
const modelConstants = readFileSync(new URL('../entry/src/main/ets/download/DownloadModels.ets', import.meta.url), 'utf8');
const queueView = readFileSync(new URL('../entry/src/main/ets/download/DownloadQueueView.ets', import.meta.url), 'utf8');
const parserSource = readFileSync(new URL('../entry/src/main/ets/storage/PreferenceParsers.ets', import.meta.url), 'utf8');
const recordSource = readFileSync(new URL('../entry/src/main/ets/utils/RecordUtils.ets', import.meta.url), 'utf8');
const globals = source.split('\n')
  .filter((line) => /^(?:let|const) (?:sharedDownload\w+|DOWNLOAD_RUNTIME_\w+)\b/.test(line)).join('\n');
const constants = [...appConstants.split('\n'), ...modelConstants.split('\n'), ...queueView.split('\n')]
  .filter((line) => /^export const (?:DOWNLOAD_STATUS_\w+|DOWNLOAD_VIEW_\w+|DOWNLOAD_DEFAULT_LABEL|DOWNLOAD_ROUTE_\w+|LIBRARY_DOWNLOADS)\b/.test(line))
  .join('\n').replace(/^export /gm, '');

function productionMethod(name) {
  const start = source.search(new RegExp(`\\n  private (?:async )?${name}\\(`));
  assert.notEqual(start, -1, `Missing production download method: ${name}`);
  const tail = source.slice(start + 1);
  const end = tail.slice(1).search(/\n  (?:private |aboutTo|@Builder)/);
  assert.notEqual(end, -1, `Missing end of production download method: ${name}`);
  return tail.slice(0, end + 1);
}

function productionFunction(text, name) {
  const start = text.search(new RegExp(`(?:^|\\n)export function ${name}\\(`));
  assert.notEqual(start, -1, `Missing production function: ${name}`);
  const tail = text.slice(start).trimStart();
  const end = tail.slice(1).search(/\n(?:export )?function /);
  return (end < 0 ? tail : tail.slice(0, end + 1)).replace(/^export /, '');
}

const parserFunctions = [
  ...['readObjectString', 'readObjectNumber'].map((name) => productionFunction(recordSource, name)),
  ...['parseLocalGalleryRecord', 'normalizeDownloadPageErrors', 'parseDownloadPageErrors',
    'parseDownloadPageErrorsFromObject'].map((name) => productionFunction(parserSource, name))
];

const fieldNames = [
  'downloadItems', 'downloadWorkerRunning', 'downloadActiveKey', 'downloadWaitKeys',
  'downloadCancelKeys', 'downloadRemovedKeys', 'downloadStartRequestedKeys', 'downloadRunGenerations',
  'downloadPageTransferFractions', 'downloadActiveRequests', 'downloadPersistVersions', 'downloadPersistQueue',
  'downloadRuntimeHeartbeatLastWriteAt', 'downloadQueueRevision', 'downloadManagerStatus',
  'downloadRuntimeItemsJson', 'downloadRuntimeActiveKey', 'downloadRuntimeWorkerRunning', 'downloadRuntimeRevision',
  'siteMode', 'downloadImportExportText'
];
const fields = fieldNames.map((name) => source.split('\n').find((line) =>
  new RegExp(`\\b${name}\\s*:`).test(line) && line.trimEnd().endsWith(';')) ?? '')
  .join('\n').replace(/@\w+(?:\([^)]*\))?\s*/g, '');
const methods = [
  'ensureDownloadRuntimeStorageDefaults', 'runtimeStringArray', 'updateRuntimeStringArray', 'isRuntimeStringArrayMarked',
  'publishDownloadRuntimeStorage', 'writeDownloadRuntimeHeartbeat',
  'downloadKey', 'toDownloadItem', 'cloneDownloadItem', 'normalizeDownloadStatus',
  'runtimeDownloadItemsSnapshot', 'findDownloadItem', 'findDownloadItemByKey', 'sharedDownloadItemByKey',
  'isDownloadKeyCancelled', 'isDownloadKeyRemoved', 'markDownloadKeyRemoved', 'clearDownloadKeyRemoved',
  'filterRemovedDownloadItems', 'isDownloadKeyRunningInCurrentProcess', 'latestDownloadItem',
  'activeDownloadRuntimeKey', 'downloadItemsSource', 'downloadDisplayItem',
  'publishSharedDownloadItems', 'saveDownloadItems', 'bumpDownloadQueueRevision',
  'recoverInterruptedDownloads', 'replaceDownloadItem', 'replaceDownloadItemInternal', 'updateDownloadProgress',
  'enqueueSharedDownloadWaitKey', 'removeSharedDownloadWaitKey', 'enqueueDownloadWaitKey',
  'currentDownloadRunGeneration', 'bumpDownloadRunGeneration', 'startDownloadItem', 'pauseDownloadItem',
  'startAllDownloads', 'pauseAllDownloads', 'scheduleDownloadItemPersist', 'scheduleDownloadItemDelete',
  'invalidateDownloadPersistForKey', 'upsertDownloadItemToDatabase', 'deleteDownloadItemFromDatabase',
  'isDownloadItemRunning', 'isDownloadItemQueued', 'updateDownloadPageTransferFraction',
  'clearDownloadPageTransferFraction', 'clearDownloadTransferProgress', 'downloadPageTransferFractionSum',
  'registerDownloadActiveRequest', 'unregisterDownloadActiveRequest', 'cancelDownloadActiveRequests',
  'toggleGalleryQueue', 'addGalleryDownload', 'importDownloadCsv', 'parseDownloadItems', 'shouldStopDownload',
  ...[...source.matchAll(/\n  private (?:async )?([A-Za-z]*ImageQuality|downloadUsesOriginalImage|startDownloadItems)\(/g)].map((match) => match[1])
];
const harnessSource = stripTypeScriptTypes(`(() => {
  ${globals}
  ${constants}
  ${parserFunctions.join('\n')}
  return {
    Harness: class DownloadRuntimeHarness {
      ${fields}
      ${methods.map(productionMethod).join('\n')}
    },
    seed(items: DownloadQueueItem[], running: boolean, activeKey: string,
      waitKeys: string[] = [], startKeys: string[] = []): void {
      sharedDownloadItemsSnapshot = items;
      sharedDownloadItemsInitialized = true;
      sharedDownloadWorkerRunning = running;
      sharedDownloadActiveKey = activeKey;
      sharedDownloadWaitKeys = waitKeys;
      sharedDownloadStartRequestedKeys.clear();
      for (const key of startKeys) sharedDownloadStartRequestedKeys.add(key);
    },
    worker(running: boolean, activeKey: string): void {
      sharedDownloadWorkerRunning = running;
      sharedDownloadActiveKey = activeKey;
    },
    flushPersistence(): Promise<void> {
      return sharedDownloadPersistQueue;
    }
  };
})()`);

function item(overrides = {}) {
  return {
    gid: 123, site: 'e', token: 'token', title: 'Gallery', titleJpn: '', cover: '',
    detailUrl: 'https://gallery.example/g/123/token/', uploader: 'uploader',
    categoryLabel: 'Manga', posted: 'posted', pages: 100, language: 'Japanese', rating: 4,
    imageQuality: 'compressed', status: 'downloading', label: 'default', queuedAt: 'queued', lastAction: 'downloading',
    downloaded: 12, total: 100, failedCount: 0, archiveUri: '', createdAt: 'created',
    updatedAt: 'updated', currentPage: 12, currentPageLabel: '12/100',
    speedBytesPerSecond: 4096, remainingSeconds: 30, downloadDir: '/public/e-123',
    error: '', pageErrors: [], ...overrides
  };
}

function deferred() {
  let resolve;
  const promise = new Promise((resolvePromise) => { resolve = resolvePromise; });
  return { promise, resolve };
}

function createRuntime() {
  const storage = new Map();
  const preferences = new Map();
  const persistence = [];
  const workerStarts = [];
  const toasts = [];
  let revision = 0;
  const runtime = vm.runInNewContext(harnessSource, {
    AppStorage: {
      has: (key) => storage.has(key),
      get: (key) => storage.get(key),
      set: (key, value) => storage.set(key, value),
      setOrCreate: (key, value) => storage.set(key, value)
    },
    clampNumber: (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum),
    GallerySite: { E: 'e', EX: 'ex' },
    EhUrl: { galleryDetail: (site, gid, token) => `https://${site}.example/g/${gid}/${token}/` }
  });
  const links = {
    downloadRuntimeItemsJson: 'download_runtime_items_snapshot',
    downloadRuntimeActiveKey: 'download_runtime_active_key',
    downloadRuntimeWorkerRunning: 'download_runtime_worker_running',
    downloadRuntimeRevision: 'download_runtime_revision'
  };

  function page(items = [], { realPersistence = false } = {}) {
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
    page.libraryPanel = -1;
    page.readString = (key, fallback) => preferences.get(key) ?? fallback;
    page.readBoolean = (key, fallback) => preferences.get(key) ?? fallback;
    page.readNumber = (key, fallback) => preferences.get(key) ?? fallback;
    page.writeValue = (key, value) => preferences.set(key, value);
    page.nowLabel = () => `updated-${++revision}`;
    if (!realPersistence) page.scheduleDownloadItemPersist = (current) => persistence.push(current);
    page.reconcileDownloadViewMode = () => {};
    page.refreshDownloadRuntimeState = () => {};
    page.setDownloadViewMode = () => {};
    page.ensureDownloadLabelExists = () => {};
    page.toast = (message) => toasts.push(message);
    page.ensureDownloadWorker = () => workerStarts.push(page);
    return page;
  }
  return { ...runtime, page, storage, preferences, persistence, workerStarts, toasts };
}

test('opening another Index initializes only absent storage keys and preserves active controls', () => {
  const runtime = createRuntime();
  const first = runtime.page();
  first.ensureDownloadRuntimeStorageDefaults();
  for (const [key, value] of [
    ['download_runtime_items_snapshot', '[{"gid":123}]'], ['download_runtime_active_key', 'e-123'],
    ['download_runtime_worker_running', true], ['download_runtime_revision', 17],
    ['download_runtime_cancel_keys', '["e-999"]'], ['download_runtime_removed_keys', '["e-888"]'],
    ['download_route_event_id', 5], ['download_route_target', 'active']
  ]) runtime.storage.set(key, value);
  const before = [...runtime.storage.entries()];
  runtime.page().ensureDownloadRuntimeStorageDefaults();
  assert.deepEqual([...runtime.storage.entries()], before);
});

test('stopping the shared worker explicitly publishes false despite stale local and storage flags', () => {
  const runtime = createRuntime();
  const owner = runtime.page();
  runtime.seed([item()], true, 'e-123');
  owner.publishDownloadRuntimeStorage();
  assert.equal(runtime.storage.get('download_runtime_worker_running'), true);
  owner.downloadWorkerRunning = true;
  owner.downloadActiveKey = 'e-123';
  runtime.worker(false, '');
  owner.publishDownloadRuntimeStorage(undefined, true);
  assert.equal(runtime.storage.get('download_runtime_worker_running'), false);
  assert.equal(runtime.storage.get('download_runtime_active_key'), '');
  assert.equal(runtime.preferences.get('download_runtime_worker_running'), false);
  assert.equal(runtime.preferences.get('download_runtime_heartbeat_at'), 0);
});

test('another active task and a fresh persisted heartbeat cannot make an interrupted task running', () => {
  const runtime = createRuntime();
  const interrupted = item();
  const active = item({ gid: 456 });
  runtime.seed([interrupted, active], true, 'e-456');
  runtime.preferences.set('download_runtime_worker_running', true);
  runtime.preferences.set('download_runtime_active_key', 'e-123');
  runtime.preferences.set('download_runtime_heartbeat_at', Date.now());
  const observer = runtime.page([interrupted, active]);
  observer.downloadWorkerRunning = true;
  observer.downloadActiveKey = 'e-123';
  assert.equal(observer.isDownloadKeyRunningInCurrentProcess('e-123'), false);
  assert.equal(observer.isDownloadItemRunning(interrupted), false);
  assert.equal(observer.isDownloadItemRunning(active), true);
  assert.equal(observer.isDownloadItemRunning({ ...active, status: 'paused' }), false);
  assert.equal(observer.isDownloadItemRunning({ ...active, status: 'complete' }), false);
});

test('waiting means an actual live queue entry, rather than a persisted waiting status alone', () => {
  const runtime = createRuntime();
  const waiting = item({ status: 'waiting' });
  runtime.seed([waiting], false, '', ['e-123'], ['e-123']);
  const observer = runtime.page();
  assert.equal(observer.isDownloadItemQueued(waiting), false);
  runtime.worker(true, 'e-456');
  assert.equal(observer.isDownloadItemQueued(waiting), true);
  assert.equal(observer.isDownloadItemRunning(waiting), false);
  assert.equal(observer.isDownloadItemQueued(item({ gid: 789, status: 'waiting' })), false);
});

test('process recovery makes interrupted downloading and waiting records restartable without losing progress', () => {
  const runtime = createRuntime();
  runtime.seed([], false, '');
  runtime.preferences.set('download_runtime_worker_running', true);
  runtime.preferences.set('download_runtime_active_key', 'e-123');
  runtime.preferences.set('download_runtime_heartbeat_at', Date.now());
  const originals = [item(), item({ gid: 456, status: 'waiting', downloaded: 0 })];
  const recovered = runtime.page().recoverInterruptedDownloads(originals);
  for (let index = 0; index < recovered.length; index++) {
    assert.equal(recovered[index].status, 'paused');
    assert.equal(recovered[index].downloaded, originals[index].downloaded);
    assert.equal(recovered[index].downloadDir, originals[index].downloadDir);
  }
  const observer = runtime.page(recovered);
  assert.equal(observer.isDownloadItemRunning(recovered[0]), false);
  assert.equal(observer.isDownloadItemQueued(recovered[1]), false);
  observer.saveDownloadItems();
  observer.startDownloadItem(recovered[1]);
  assert.equal(runtime.workerStarts.length, 1);
  assert.equal(observer.latestDownloadItem(recovered[1]).status, 'waiting');
});

test('recovery preserves a real shared active task and its queued sibling', () => {
  const runtime = createRuntime();
  const active = item();
  const waiting = item({ gid: 456, status: 'waiting' });
  runtime.seed([active, waiting], true, 'e-123', ['e-456'], ['e-456']);
  const recovered = runtime.page().recoverInterruptedDownloads([active, waiting]);
  assert.equal(recovered[0].status, 'downloading');
  assert.equal(recovered[1].status, 'waiting');
});

test('observer pause and continue resolve the latest item, retain sibling progress, and cancel the owner request', () => {
  const runtime = createRuntime();
  const staleA = item();
  const staleB = item({ gid: 456, status: 'paused', downloaded: 2 });
  runtime.seed([staleA, staleB], true, 'e-123');
  const owner = runtime.page([staleA, staleB]);
  const observer = runtime.page([staleA, staleB]);
  let destroyed = 0;
  owner.registerDownloadActiveRequest('e-123', { destroy: () => destroyed++ });
  owner.updateDownloadProgress(staleA, 'downloading', 60, 100, 0, 'page 60', 60,
    8000, 10, staleA.downloadDir, '', []);
  owner.replaceDownloadItem({ ...staleB, downloaded: 40, lastAction: 'new sibling progress' });

  observer.pauseDownloadItem(staleA);
  assert.equal(destroyed, 1);
  assert.equal(owner.latestDownloadItem(staleA).status, 'paused');
  assert.equal(owner.latestDownloadItem(staleA).downloaded, 60);
  assert.equal(owner.latestDownloadItem(staleB).downloaded, 40);
  assert.equal(owner.isDownloadItemRunning(owner.latestDownloadItem(staleA)), false);

  observer.startDownloadItem(staleA);
  assert.equal(owner.latestDownloadItem(staleA).status, 'waiting');
  assert.equal(owner.latestDownloadItem(staleA).downloaded, 60);
  assert.equal(owner.latestDownloadItem(staleB).downloaded, 40);
  assert.equal(observer.currentDownloadRunGeneration('e-123'), 2);
});

test('owner pause then observer continue clears cancellation and shares the new run generation in every view', () => {
  const runtime = createRuntime();
  const original = item();
  runtime.seed([original], true, 'e-123');
  const owner = runtime.page([original]);
  const observer = runtime.page([original]);
  const thirdView = runtime.page([original]);

  owner.pauseDownloadItem(original);
  for (const page of [owner, observer, thirdView]) {
    assert.equal(page.isDownloadKeyCancelled('e-123'), true);
    assert.equal(page.currentDownloadRunGeneration('e-123'), 1);
    assert.equal(page.downloadRunGenerations.get('e-123'), 1);
    assert.equal(page.downloadStartRequestedKeys.has('e-123'), false);
  }

  observer.startDownloadItem(original);
  for (const page of [owner, observer, thirdView, runtime.page([original])]) {
    assert.equal(page.isDownloadKeyCancelled('e-123'), false, 'The former owner must allow the resumed run');
    assert.equal(page.downloadCancelKeys.has('e-123'), false);
    assert.equal(page.currentDownloadRunGeneration('e-123'), 2);
    assert.equal(page.downloadRunGenerations.get('e-123'), 2);
    assert.equal(page.downloadStartRequestedKeys.has('e-123'), true);
    assert.equal(page.latestDownloadItem(original).status, 'waiting');
  }
  assert.equal(runtime.workerStarts.length, 1);
});

test('observer clearing an owner removal makes a re-added task visible in every existing and new view', () => {
  const runtime = createRuntime();
  const original = item();
  const otherSite = item({ site: 'ex' });
  runtime.seed([original, otherSite], true, 'e-123');
  const owner = runtime.page([original, otherSite]);
  const observer = runtime.page([original, otherSite]);
  const thirdView = runtime.page([original, otherSite]);
  owner.markDownloadKeyRemoved('e-123');
  owner.markDownloadKeyRemoved('ex-123');
  for (const page of [owner, observer, thirdView]) {
    assert.equal(page.isDownloadKeyRemoved('e-123'), true);
    assert.equal(page.filterRemovedDownloadItems([original]).length, 0);
  }

  observer.clearDownloadKeyRemoved('e-123');
  const readded = item({ status: 'waiting', downloaded: 0, lastAction: 'new task' });
  observer.replaceDownloadItem(readded);
  for (const page of [owner, observer, thirdView, runtime.page([original, otherSite])]) {
    assert.equal(page.isDownloadKeyRemoved('e-123'), false, 'The former owner must not retain a private removal flag');
    assert.equal(page.downloadRemovedKeys.has('e-123'), false);
    assert.equal(page.filterRemovedDownloadItems([readded]).length, 1);
    assert.equal(page.findDownloadItemByKey('e-123').lastAction, 'new task');
    assert.equal(page.findDownloadItemByKey('e-123').downloaded, 0);
    assert.equal(page.isDownloadKeyRemoved('ex-123'), true, 'Clearing one site must not clear the same gid on another site');
  }
});

test('a progress update from a stale observer cannot replace other tasks with its old local snapshot', () => {
  const runtime = createRuntime();
  const staleA = item();
  const staleB = item({ gid: 456, downloaded: 2 });
  runtime.seed([{ ...staleA, downloaded: 70 }, staleB], true, 'e-456');
  const observer = runtime.page([staleA, staleB]);
  observer.updateDownloadProgress(staleB, 'downloading', 35, 100, 0, 'page 35', 35,
    4096, 30, staleB.downloadDir, '', []);
  assert.equal(observer.latestDownloadItem(staleA).downloaded, 70);
  assert.equal(observer.latestDownloadItem(staleB).downloaded, 35);
});

test('an initialized empty shared snapshot cannot resurrect old local or AppStorage tasks', () => {
  const runtime = createRuntime();
  const stale = item();
  runtime.seed([], false, '');
  runtime.storage.set('download_runtime_items_snapshot', JSON.stringify([stale]));
  const observer = runtime.page([stale]);
  assert.equal(observer.downloadItemsSource().length, 0);
  assert.equal(observer.findDownloadItemByKey('e-123'), undefined);
});

test('page transfer fractions are shared across views and clearing one task leaves another intact', () => {
  const runtime = createRuntime();
  const owner = runtime.page();
  const observer = runtime.page();
  const first = item();
  const second = item({ site: 'ex' });
  owner.updateDownloadPageTransferFraction(first, 0, 0.3);
  owner.updateDownloadPageTransferFraction(first, 1, 0.4);
  observer.updateDownloadPageTransferFraction(second, 0, 0.2);
  assert.equal(observer.downloadPageTransferFractionSum(first), 0.7);
  assert.equal(owner.downloadPageTransferFractionSum(second), 0.2);
  observer.clearDownloadPageTransferFraction(first, 0);
  assert.equal(owner.downloadPageTransferFractionSum(first), 0.4);
  observer.clearDownloadTransferProgress(first);
  assert.equal(owner.downloadPageTransferFractionSum(first), 0);
  assert.equal(owner.downloadPageTransferFractionSum(second), 0.2);
});

test('repeated pause and continue requests do not restart an already applied control transition', () => {
  const runtime = createRuntime();
  const original = item();
  runtime.seed([original], true, 'e-123');
  const observer = runtime.page([original]);
  observer.pauseDownloadItem(original);
  assert.equal(observer.currentDownloadRunGeneration('e-123'), 1);
  observer.pauseDownloadItem(original);
  assert.equal(observer.currentDownloadRunGeneration('e-123'), 1);
  observer.startDownloadItem(original);
  assert.equal(observer.currentDownloadRunGeneration('e-123'), 2);
  assert.equal(observer.isDownloadItemQueued(observer.latestDownloadItem(original)), true);
  observer.startDownloadItem(original);
  assert.equal(observer.currentDownloadRunGeneration('e-123'), 2);
  assert.equal(runtime.workerStarts.length, 1);
});

test('start all includes interrupted records while preserving a real active and already queued task', () => {
  const runtime = createRuntime();
  const tasks = [
    item(), item({ gid: 456, status: 'waiting' }), item({ gid: 789 }),
    item({ gid: 800, status: 'failed' }), item({ gid: 900, status: 'paused' }),
    item({ gid: 999, status: 'complete', downloaded: 100 })
  ];
  runtime.seed(tasks, true, 'e-123', ['e-456'], ['e-456']);
  const observer = runtime.page(tasks.map((task) => ({ ...task, downloaded: 0 })));
  observer.startAllDownloads();
  assert.deepEqual(Array.from(observer.downloadItemsSource(), (task) => task.status),
    ['downloading', 'waiting', 'waiting', 'waiting', 'waiting', 'complete']);
  assert.equal(observer.currentDownloadRunGeneration('e-123'), 0);
  assert.equal(observer.currentDownloadRunGeneration('e-456'), 0);
  for (const key of ['e-789', 'e-800', 'e-900']) {
    assert.equal(observer.currentDownloadRunGeneration(key), 1);
    assert.equal(observer.isDownloadItemQueued(observer.findDownloadItemByKey(key)), true);
  }
  assert.equal(observer.findDownloadItemByKey('e-999').downloaded, 100);
});

test('pause all acts only on live active and queued tasks, leaving interrupted and completed records intact', () => {
  const runtime = createRuntime();
  const tasks = [item(), item({ gid: 456, status: 'waiting' }), item({ gid: 789 }),
    item({ gid: 999, status: 'complete', downloaded: 100 })];
  runtime.seed(tasks, true, 'e-123', ['e-456'], ['e-456']);
  const observer = runtime.page();
  observer.pauseAllDownloads();
  assert.deepEqual(Array.from(observer.downloadItemsSource(), (task) => task.status),
    ['paused', 'paused', 'downloading', 'complete']);
  assert.equal(observer.currentDownloadRunGeneration('e-123'), 1);
  assert.equal(observer.currentDownloadRunGeneration('e-456'), 1);
  assert.equal(observer.currentDownloadRunGeneration('e-789'), 0);
});

test('a later observer persistence version cancels an owner progress job still waiting in the shared queue', async () => {
  const runtime = createRuntime();
  const gate = deferred();
  const started = deferred();
  const committed = [];
  const dao = {
    async upsertDownloadItem(current) {
      if (current.gid === 999) {
        started.resolve();
        await gate.promise;
      }
      committed.push(current);
    }
  };
  const owner = runtime.page([], { realPersistence: true });
  const observer = runtime.page([], { realPersistence: true });
  owner.localDao = dao;
  observer.localDao = dao;
  owner.scheduleDownloadItemPersist(item({ gid: 999 }));
  await started.promise;
  owner.scheduleDownloadItemPersist(item({ downloaded: 60 }));
  observer.scheduleDownloadItemPersist(item({ downloaded: 60, status: 'paused' }));
  gate.resolve();
  await runtime.flushPersistence();
  assert.deepEqual(committed.map((current) => [current.gid, current.status]),
    [[999, 'downloading'], [123, 'paused']]);
});

test('an already in-flight old DB write completes before the newer observer pause write', async () => {
  const runtime = createRuntime();
  const gate = deferred();
  const started = deferred();
  const committed = [];
  const dao = {
    async upsertDownloadItem(current) {
      if (current.status === 'downloading') {
        started.resolve();
        await gate.promise;
      }
      committed.push(current);
    }
  };
  const owner = runtime.page([], { realPersistence: true });
  const observer = runtime.page([], { realPersistence: true });
  owner.localDao = dao;
  observer.localDao = dao;
  owner.scheduleDownloadItemPersist(item({ downloaded: 60 }));
  await started.promise;
  observer.scheduleDownloadItemPersist(item({ downloaded: 60, status: 'paused' }));
  gate.resolve();
  await runtime.flushPersistence();
  assert.deepEqual(committed.map((current) => current.status), ['downloading', 'paused']);
  assert.equal(committed.at(-1).downloaded, 60);
});

test('delete then immediate re-add invalidates an old pending write and commits the fresh record last', async () => {
  const runtime = createRuntime();
  const gate = deferred();
  const started = deferred();
  const events = [];
  const dao = {
    async upsertDownloadItem(current) {
      if (current.gid === 999) {
        started.resolve();
        await gate.promise;
      }
      events.push(['upsert', current.gid, current.status]);
    },
    async deleteDownloadItem(current) {
      events.push(['delete', current.gid]);
    }
  };
  const owner = runtime.page([], { realPersistence: true });
  const observer = runtime.page([], { realPersistence: true });
  owner.localDao = dao;
  observer.localDao = dao;
  owner.scheduleDownloadItemPersist(item({ gid: 999 }));
  await started.promise;
  owner.scheduleDownloadItemPersist(item({ downloaded: 60 }));
  observer.scheduleDownloadItemDelete(item());
  observer.clearDownloadKeyRemoved('e-123');
  observer.scheduleDownloadItemPersist(item({ downloaded: 0, status: 'waiting' }));
  gate.resolve();
  await runtime.flushPersistence();
  assert.deepEqual(events, [['upsert', 999, 'downloading'], ['delete', 123], ['upsert', 123, 'waiting']]);
});

test('adding a gallery to more than 80 tasks retains a running tail task and its cross-view controls', () => {
  const runtime = createRuntime();
  const active = item({ gid: 9000, downloaded: 61 });
  const tasks = [
    ...Array.from({ length: 81 }, (_, index) => item({ gid: index + 1, status: 'paused' })),
    active
  ];
  runtime.seed(tasks, true, 'e-9000');
  const owner = runtime.page(tasks);
  const observer = runtime.page([active]);
  let destroyed = 0;
  owner.registerDownloadActiveRequest('e-9000', { destroy: () => destroyed++ });
  observer.addGalleryDownload(item({ gid: 10000 }), 'compressed');

  assert.equal(owner.downloadItemsSource().length, tasks.length + 1);
  assert.equal(owner.downloadItemsSource().at(-1).gid, active.gid);
  assert.equal(owner.latestDownloadItem(active).downloaded, 61);
  assert.equal(owner.isDownloadItemRunning(owner.latestDownloadItem(active)), true);
  assert.equal(owner.shouldStopDownload(active, 0), false, 'Adding a task must not silently stop the existing worker');
  assert.equal(JSON.parse(runtime.preferences.get('download_items')).length, tasks.length + 1);

  observer.pauseDownloadItem(active);
  assert.equal(destroyed, 1);
  assert.equal(owner.latestDownloadItem(active).status, 'paused');
  assert.equal(owner.shouldStopDownload(active, 0), true);
  owner.startDownloadItem(active);
  assert.equal(observer.latestDownloadItem(active).status, 'waiting');
  assert.equal(observer.isDownloadItemQueued(observer.latestDownloadItem(active)), true);
  assert.equal(observer.isDownloadKeyCancelled('e-9000'), false);
  assert.equal(observer.currentDownloadRunGeneration('e-9000'), 2);
  assert.equal(owner.downloadItemsSource().length, tasks.length + 1);
});

test('CSV import beyond 120 tasks preserves the running tail, deduplicates each batch, and retains pause/continue', () => {
  const runtime = createRuntime();
  const active = item({ gid: 9000, downloaded: 72 });
  const tasks = [
    ...Array.from({ length: 125 }, (_, index) => item({ gid: index + 1, status: 'paused' })),
    active
  ];
  runtime.seed(tasks, true, 'e-9000');
  const owner = runtime.page(tasks);
  const observer = runtime.page([]);
  const csvLine = (gid, title) => [
    gid, 'csv-token', title, '', '', 'Manga', '', 'uploader', 4, '',
    'Japanese', '', '', '', '', '', '', '', '', 100
  ].join(',');
  observer.downloadImportExportText = [
    csvLine(10000, 'first'), csvLine(10000, 'duplicate'),
    csvLine(10001, 'second'), csvLine(active.gid, 'must keep existing')
  ].join('\n');
  observer.importDownloadCsv();

  const merged = owner.downloadItemsSource();
  assert.equal(merged.length, tasks.length + 2);
  assert.equal(merged.filter((current) => current.gid === 10000).length, 1);
  assert.equal(owner.findDownloadItemByKey('e-10000').title, 'first');
  assert.equal(merged.at(-1).gid, active.gid);
  assert.equal(owner.latestDownloadItem(active).downloaded, 72);
  assert.equal(owner.latestDownloadItem(active).title, active.title);
  assert.equal(owner.isDownloadItemRunning(owner.latestDownloadItem(active)), true);
  assert.equal(owner.shouldStopDownload(active, 0), false);
  assert.equal(runtime.toasts.at(-1), '已导入 2 个下载');
  assert.equal(JSON.parse(runtime.preferences.get('download_items')).length, tasks.length + 2);

  observer.pauseDownloadItem(active);
  assert.equal(owner.latestDownloadItem(active).status, 'paused');
  owner.startDownloadItem(active);
  assert.equal(observer.latestDownloadItem(active).status, 'waiting');
  assert.equal(observer.isDownloadItemQueued(observer.latestDownloadItem(active)), true);
  assert.equal(observer.latestDownloadItem(active).downloaded, 72);
  assert.equal(observer.currentDownloadRunGeneration('e-9000'), 2);
  assert.equal(owner.downloadItemsSource().length, tasks.length + 2);
});

test('the production preferences parser restores every task in a queue beyond the former caps', () => {
  const runtime = createRuntime();
  const tasks = Array.from({ length: 261 }, (_, index) => item({
    gid: index + 1, status: 'paused', downloaded: index % 100,
    downloadDir: `/public/e-${index + 1}`,
    pageErrors: [{ page: 80, message: 'retry this page', updatedAt: 'before restart' }]
  }));
  const parsed = runtime.page().parseDownloadItems(JSON.stringify(tasks));
  assert.equal(parsed.length, tasks.length);
  assert.deepEqual(Array.from(parsed, (current) => current.gid), tasks.map((current) => current.gid));
  assert.equal(parsed.at(-1).downloaded, tasks.at(-1).downloaded);
  assert.equal(parsed.at(-1).downloadDir, tasks.at(-1).downloadDir);
  assert.equal(parsed.at(-1).pageErrors[0].message, 'retry this page');
});
