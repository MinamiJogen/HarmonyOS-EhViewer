import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';

// Run production quality-selection and download-control methods in a shared VM.
// Dialog delivery, reactive storage, and worker startup are simulated boundaries;
// these checks do not render ArkUI or transfer real images.
// Run with Node.js 22.13+: node --test tests/download-quality.test.mjs
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
  'toggleGalleryQueue', 'importDownloadCsv', 'parseDownloadItems', 'shouldStopDownload',
  'updateDownloadStatus', 'markDownloadItemRunning',
  ...[...source.matchAll(/\n  private (?:async )?([A-Za-z]*ImageQuality|downloadUsesOriginalImage|addGalleryDownload|startDownloadItems)\(/g)].map((match) => match[1])
];
const selectedMaterial = Object.freeze({ marker: 'immersive-dialog-material' });
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

function createRuntime() {
  const storage = new Map();
  const preferences = new Map();
  const persistence = [];
  const workerStarts = [];
  const toasts = [];
  const dialogs = [];
  let dialogThrows = false;
  let revision = 0;
  const runtime = vm.runInNewContext(harnessSource, {
    IMMERSIVE_DIALOG_MATERIAL: selectedMaterial,
    $r: (name) => ({ resource: name }),
    DialogButtonStyle: { DEFAULT: 'default', HIGHLIGHT: 'highlight' },
    DialogAlignment: { Default: 'default' },
    DialogButtonDirection: { VERTICAL: 'vertical' },
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
    page.downloadStatusLabel = (status) => status;
    page.getUIContext = () => ({
      showAlertDialog: (options) => {
        if (dialogThrows) throw new Error('dialog unavailable');
        dialogs.push(options);
      }
    });
    return page;
  }
  return { ...runtime, page, storage, preferences, persistence, workerStarts, toasts, dialogs,
    setDialogThrows(value) { dialogThrows = value; } };
}

async function settleDialogs() {
  for (let turn = 0; turn < 6; turn++) await Promise.resolve();
}

function pendingCsv(overrides = {}) {
  return item({ imageQuality: '', status: 'waiting', downloaded: 0, currentPage: 0,
    downloadDir: '', lastAction: '从 Android CSV 导入', ...overrides });
}

test('new download waits for an immersive quality dialog before it joins the queue', async () => {
  const runtime = createRuntime();
  const page = runtime.page();
  page.toggleGalleryQueue(item({ gid: 501 }));

  assert.equal(runtime.dialogs.length, 1);
  assert.equal(runtime.dialogs[0].systemMaterial, selectedMaterial);
  assert.equal(runtime.dialogs[0].title, '选择下载画质');
  assert.equal(runtime.dialogs[0].message, '');
  assert.deepEqual(Array.from(runtime.dialogs[0].buttons, (button) => button.value), ['原图', '压缩图', '取消']);
  assert.equal(page.downloadItemsSource().length, 0);
  assert.equal(runtime.workerStarts.length, 0);
  assert.equal(runtime.persistence.length, 0);

  runtime.dialogs[0].buttons[0].action();
  await settleDialogs();
  assert.equal(page.downloadItemsSource().length, 1);
  assert.equal(page.downloadItemsSource()[0].imageQuality, 'original');
  assert.equal(runtime.workerStarts.length, 1);
});

for (const [index, quality] of [[0, 'original'], [1, 'compressed']]) {
  test(`dialog selection stores ${quality} on only the requested gallery`, async () => {
    const runtime = createRuntime();
    runtime.preferences.set('download_original_image', false);
    const page = runtime.page();
    page.toggleGalleryQueue(item({ gid: 510 }));
    runtime.dialogs[0].buttons[index].action();
    await settleDialogs();
    const queued = page.downloadItemsSource()[0];
    assert.equal(queued.imageQuality, quality);
    assert.equal(page.downloadUsesOriginalImage(queued), quality === 'original');
    assert.equal(JSON.parse(runtime.preferences.get('download_items'))[0].imageQuality, quality);
    assert.equal(runtime.preferences.get('download_original_image'), false);
  });
}

for (const outcome of ['cancel', 'dismiss', 'unavailable']) {
  test(`${outcome} dialog leaves no task, worker, or persistence and allows a new click`, async () => {
    const runtime = createRuntime();
    const page = runtime.page();
    runtime.setDialogThrows(outcome === 'unavailable');
    page.toggleGalleryQueue(item({ gid: 520 }));
    if (outcome === 'cancel') runtime.dialogs[0].buttons[2].action();
    if (outcome === 'dismiss') runtime.dialogs[0].cancel();
    await settleDialogs();
    assert.equal(page.downloadItemsSource().length, 0);
    assert.equal(runtime.workerStarts.length, 0);
    assert.equal(runtime.persistence.length, 0);
    runtime.setDialogThrows(false);
    page.toggleGalleryQueue(item({ gid: 520 }));
    assert.equal(runtime.dialogs.length, outcome === 'unavailable' ? 1 : 2);
  });
}

test('repeated clicks across routed views open one dialog for the same gallery', async () => {
  const runtime = createRuntime();
  const first = runtime.page();
  const second = runtime.page();
  first.toggleGalleryQueue(item({ gid: 530 }));
  first.toggleGalleryQueue(item({ gid: 530 }));
  second.toggleGalleryQueue(item({ gid: 530 }));
  assert.equal(runtime.dialogs.length, 1);
  runtime.dialogs[0].buttons[1].action();
  await settleDialogs();
  assert.equal(first.downloadItemsSource().length, 1);
  assert.equal(second.downloadItemsSource()[0].imageQuality, 'compressed');
  assert.equal(runtime.workerStarts.length, 1);
});

test('a late selection preserves a task that another view already created', async () => {
  const runtime = createRuntime();
  const first = runtime.page();
  const second = runtime.page();
  first.toggleGalleryQueue(item({ gid: 540 }));
  second.addGalleryDownload(item({ gid: 540 }), 'compressed');
  const created = second.downloadItemsSource()[0];
  runtime.dialogs[0].buttons[0].action();
  await settleDialogs();
  assert.equal(first.downloadItemsSource().length, 1);
  assert.equal(first.downloadItemsSource()[0].imageQuality, 'compressed');
  assert.equal(first.downloadItemsSource()[0].queuedAt, created.queuedAt);
  assert.equal(runtime.workerStarts.length, 1);
});

test('an existing gallery click retains the existing remove action without a quality prompt', () => {
  const runtime = createRuntime();
  const existing = item({ gid: 550, imageQuality: 'original' });
  runtime.seed([existing], false, '');
  const page = runtime.page();
  const removed = [];
  page.removeDownloadItem = (current) => removed.push(current);
  page.toggleGalleryQueue(existing);
  assert.equal(runtime.dialogs.length, 0);
  assert.equal(removed.length, 1);
  assert.equal(removed[0].gid, 550);
});

test('different galleries keep independent selected modes when dialog responses arrive out of order', async () => {
  const runtime = createRuntime();
  const page = runtime.page();
  page.toggleGalleryQueue(item({ gid: 560 }));
  page.toggleGalleryQueue(item({ gid: 561 }));
  runtime.dialogs[1].buttons[1].action();
  runtime.dialogs[0].buttons[0].action();
  await settleDialogs();
  assert.equal(page.findDownloadItem(560, 'e').imageQuality, 'original');
  assert.equal(page.findDownloadItem(561, 'e').imageQuality, 'compressed');
  assert.equal(runtime.workerStarts.length, 2);
});

for (const quality of ['original', 'compressed']) {
  test(`${quality} survives cloning, status transitions, pause, and continuation`, () => {
    const runtime = createRuntime();
    const selected = item({ imageQuality: quality });
    runtime.seed([selected], true, 'e-123');
    const owner = runtime.page();
    const observer = runtime.page();
    assert.equal(owner.cloneDownloadItem(selected).imageQuality, quality);
    owner.updateDownloadStatus(123, 'e', 'downloading');
    assert.equal(observer.findDownloadItem(123, 'e').imageQuality, quality);
    observer.pauseDownloadItem(selected);
    assert.equal(owner.findDownloadItem(123, 'e').status, 'paused');
    assert.equal(owner.findDownloadItem(123, 'e').imageQuality, quality);
    owner.startDownloadItem(selected);
    assert.equal(observer.findDownloadItem(123, 'e').imageQuality, quality);
    assert.equal(observer.findDownloadItem(123, 'e').status, 'waiting');
    assert.equal(runtime.dialogs.length, 0);
    assert.equal(owner.downloadUsesOriginalImage(observer.findDownloadItem(123, 'e')), quality === 'original');
  });
}

test('backup parsing preserves each selected quality while legacy entries retain the unspecified mode', () => {
  const runtime = createRuntime();
  const page = runtime.page();
  const records = page.parseDownloadItems(JSON.stringify([
    item({ gid: 570, imageQuality: 'original' }),
    item({ gid: 571, imageQuality: 'compressed' }),
    item({ gid: 572, imageQuality: '' })
  ]));
  assert.deepEqual(Array.from(records, (record) => record.imageQuality), ['original', 'compressed', '']);
});

test('starting an imported unselected gallery waits for its quality, then resumes exactly that task', async () => {
  const runtime = createRuntime();
  const imported = pendingCsv({ gid: 580 });
  const selected = item({ gid: 581, imageQuality: 'original', status: 'paused' });
  runtime.seed([imported, selected], false, '');
  const page = runtime.page();
  page.startDownloadItem(imported);
  assert.equal(runtime.dialogs.length, 1);
  assert.equal(runtime.workerStarts.length, 0);
  assert.equal(page.findDownloadItem(580, 'e').imageQuality, '');
  runtime.dialogs[0].buttons[1].action();
  await settleDialogs();
  assert.equal(page.findDownloadItem(580, 'e').imageQuality, 'compressed');
  assert.equal(page.findDownloadItem(581, 'e').imageQuality, 'original');
  assert.equal(page.findDownloadItem(581, 'e').status, 'paused');
  assert.equal(runtime.workerStarts.length, 1);
});

test('canceling the quality choice for an imported task leaves it idle and unchanged', async () => {
  const runtime = createRuntime();
  const imported = pendingCsv({ gid: 590 });
  runtime.seed([imported], false, '');
  const page = runtime.page();
  page.startDownloadItem(imported);
  runtime.dialogs[0].buttons[2].action();
  await settleDialogs();
  assert.equal(page.findDownloadItem(590, 'e').imageQuality, '');
  assert.equal(page.findDownloadItem(590, 'e').lastAction, imported.lastAction);
  assert.equal(runtime.workerStarts.length, 0);
  assert.equal(runtime.persistence.length, 0);
});

test('bulk start makes one choice for unselected galleries and preserves earlier choices', async () => {
  const runtime = createRuntime();
  const records = [pendingCsv({ gid: 600 }), pendingCsv({ gid: 601 }),
    item({ gid: 602, imageQuality: 'original', status: 'paused' }),
    item({ gid: 603, imageQuality: 'compressed', status: 'complete' })];
  runtime.seed(records, false, '');
  const page = runtime.page();
  page.startAllDownloads();
  assert.equal(runtime.dialogs.length, 1);
  runtime.dialogs[0].buttons[1].action();
  await settleDialogs();
  assert.equal(page.findDownloadItem(600, 'e').imageQuality, 'compressed');
  assert.equal(page.findDownloadItem(601, 'e').imageQuality, 'compressed');
  assert.equal(page.findDownloadItem(602, 'e').imageQuality, 'original');
  assert.equal(page.findDownloadItem(603, 'e').imageQuality, 'compressed');
  assert.equal(page.findDownloadItem(603, 'e').status, 'complete');
  assert.ok(runtime.workerStarts.length > 0);
});

for (const quality of ['original', 'compressed']) {
  test(`an explicit ${quality} task overrides a conflicting old download preference`, () => {
    const runtime = createRuntime();
    const page = runtime.page();
    const selected = item({ imageQuality: quality });
    page.readBoolean = () => quality !== 'original';
    assert.equal(page.downloadUsesOriginalImage(selected), quality === 'original');
  });
}

test('a delayed imported quality selection cannot resurrect a task removed by another page', async () => {
  const runtime = createRuntime();
  const imported = pendingCsv({ gid: 610 });
  runtime.seed([imported], false, '');
  const first = runtime.page();
  const second = runtime.page();
  first.startDownloadItem(imported);
  second.markDownloadKeyRemoved('e-610');
  runtime.dialogs[0].buttons[0].action();
  await settleDialogs();
  assert.equal(first.findDownloadItem(610, 'e'), undefined);
  assert.equal(first.downloadItemsSource().length, 0);
  assert.equal(runtime.workerStarts.length, 0);
});

test('download quality uses only the task selection and never reads the reader preference', () => {
  const runtime = createRuntime();
  const page = runtime.page();
  page.readBoolean = () => { assert.fail('Download quality must not read a global preference'); };
  assert.equal(page.downloadUsesOriginalImage(item({ imageQuality: 'original' })), true);
  assert.equal(page.downloadUsesOriginalImage(item({ imageQuality: 'compressed' })), false);
  assert.equal(page.requiresDownloadImageQuality(item({ imageQuality: '', downloaded: 3, downloadDir: '/saved' })), true);
});

test('actual CSV import preserves the undecided mode and first start asks for quality', async () => {
  const runtime = createRuntime();
  const page = runtime.page();
  page.siteMode = 'e';
  page.downloadImportExportText = '620,token,Imported,,cover,Manga,posted,uploader,4,false,ja,,,,,,,,,100';
  page.importDownloadCsv();
  const imported = page.findDownloadItem(620, 'e');
  assert.ok(imported);
  assert.equal(imported.imageQuality, '');
  assert.equal(runtime.dialogs.length, 0);
  assert.equal(runtime.workerStarts.length, 0);
  page.startDownloadItem(imported);
  assert.equal(runtime.dialogs.length, 1);
  runtime.dialogs[0].buttons[0].action();
  await settleDialogs();
  assert.equal(page.findDownloadItem(620, 'e').imageQuality, 'original');
  assert.equal(runtime.workerStarts.length, 1);
});

test('canceling bulk quality choice starts none of the waiting or paused tasks', async () => {
  const runtime = createRuntime();
  const records = [pendingCsv({ gid: 630 }), item({ gid: 631, status: 'paused' })];
  runtime.seed(records, false, '');
  const page = runtime.page();
  page.startAllDownloads();
  runtime.dialogs[0].buttons[2].action();
  await settleDialogs();
  assert.equal(page.findDownloadItem(630, 'e').imageQuality, '');
  assert.equal(page.findDownloadItem(631, 'e').status, 'paused');
  assert.equal(runtime.workerStarts.length, 0);
});

test('a bulk quality callback preserves another view’s newer explicit quality choice', async () => {
  const runtime = createRuntime();
  const firstItem = pendingCsv({ gid: 640 });
  const secondItem = pendingCsv({ gid: 641 });
  runtime.seed([firstItem, secondItem], false, '');
  const first = runtime.page();
  const second = runtime.page();
  first.startAllDownloads();
  const updated = second.cloneDownloadItem(second.findDownloadItem(641, 'e'));
  updated.imageQuality = 'original';
  second.replaceDownloadItem(updated);
  runtime.dialogs[0].buttons[1].action();
  await settleDialogs();
  assert.equal(first.findDownloadItem(640, 'e').imageQuality, 'compressed');
  assert.equal(first.findDownloadItem(641, 'e').imageQuality, 'original');
});

test('an imported queue recovered after restart still asks for its first quality choice', async () => {
  const runtime = createRuntime();
  const imported = pendingCsv({ gid: 650 });
  runtime.seed([imported], false, '');
  const page = runtime.page();
  const recovered = page.recoverInterruptedDownloads([imported]);
  assert.equal(recovered[0].status, 'paused');
  assert.equal(recovered[0].imageQuality, '');
  runtime.seed(recovered, false, '');
  page.startDownloadItem(recovered[0]);
  assert.equal(runtime.dialogs.length, 1);
  assert.equal(runtime.workerStarts.length, 0);
  runtime.dialogs[0].buttons[0].action();
  await settleDialogs();
  assert.equal(page.findDownloadItem(650, 'e').imageQuality, 'original');
  assert.equal(page.findDownloadItem(650, 'e').status, 'waiting');
});

test('bulk dialog completion cannot restart a task another page paused while the dialog was open', async () => {
  const runtime = createRuntime();
  const waiting = pendingCsv({ gid: 660 });
  const running = item({ gid: 661, imageQuality: 'original', status: 'downloading' });
  runtime.seed([waiting, running], true, 'e-661');
  const first = runtime.page();
  const second = runtime.page();
  first.startAllDownloads();
  assert.equal(runtime.dialogs.length, 1);
  second.pauseDownloadItem(running);
  const pausedGeneration = second.currentDownloadRunGeneration('e-661');
  runtime.dialogs[0].buttons[1].action();
  await settleDialogs();
  assert.equal(first.findDownloadItem(660, 'e').imageQuality, 'compressed');
  assert.equal(first.findDownloadItem(661, 'e').status, 'paused');
  assert.equal(first.currentDownloadRunGeneration('e-661'), pausedGeneration);
  assert.equal(first.isDownloadItemQueued(first.findDownloadItem(661, 'e')), false);
});

for (const action of ['single', 'bulk']) {
  test(`a delayed ${action} quality callback cannot override or restart a newly re-added task with the same key`, async () => {
    const runtime = createRuntime();
    const imported = pendingCsv({ gid: 670 });
    runtime.seed([imported], false, '');
    const first = runtime.page();
    const second = runtime.page();
    if (action === 'single') first.startDownloadItem(imported);
    else first.startAllDownloads();
    assert.equal(runtime.dialogs.length, 1);
    second.bumpDownloadRunGeneration('e-670');
    second.markDownloadKeyRemoved('e-670');
    second.addGalleryDownload(item({ gid: 670 }), 'original');
    const freshGeneration = second.currentDownloadRunGeneration('e-670');
    const freshTask = second.findDownloadItem(670, 'e');
    runtime.dialogs[0].buttons[1].action();
    await settleDialogs();
    assert.equal(first.findDownloadItem(670, 'e').imageQuality, 'original');
    assert.equal(first.findDownloadItem(670, 'e').queuedAt, freshTask.queuedAt);
    assert.equal(first.currentDownloadRunGeneration('e-670'), freshGeneration);
  });
}

for (const action of ['single', 'bulk']) {
  test(`a delayed ${action} quality callback cannot configure a newly imported undecided task with a reused key`, async () => {
    const runtime = createRuntime();
    const original = pendingCsv({ gid: 680 });
    runtime.seed([original], false, '');
    const first = runtime.page();
    const second = runtime.page();
    if (action === 'single') first.startDownloadItem(original);
    else first.startAllDownloads();
    second.bumpDownloadRunGeneration('e-680');
    second.markDownloadKeyRemoved('e-680');
    second.siteMode = 'e';
    second.downloadImportExportText = '680,new-token,Reimported,,cover,Manga,posted,uploader,4,false,ja,,,,,,,,,100';
    second.importDownloadCsv();
    const freshTask = second.findDownloadItem(680, 'e');
    const freshGeneration = second.currentDownloadRunGeneration('e-680');
    assert.ok(freshTask);
    assert.equal(freshTask.imageQuality, '');
    assert.equal(freshTask.token, 'new-token');
    runtime.dialogs[0].buttons[0].action();
    await settleDialogs();
    assert.equal(first.findDownloadItem(680, 'e').imageQuality, '');
    assert.equal(first.findDownloadItem(680, 'e').queuedAt, freshTask.queuedAt);
    assert.equal(first.findDownloadItem(680, 'e').lastAction, '从 Android CSV 导入');
    assert.equal(first.currentDownloadRunGeneration('e-680'), freshGeneration);
    assert.equal(first.downloadStartRequestedKeys.has('e-680'), false);
    assert.equal(first.downloadWaitKeys.includes('e-680'), false);
  });
}


test('interactive back dismissal releases the pending gallery and permits another quality prompt', () => {
  const runtime = createRuntime();
  const page = runtime.page();
  page.toggleGalleryQueue(item({ gid: 690 }));
  assert.equal(runtime.dialogs.length, 1);
  let dismissCalls = 0;
  runtime.dialogs[0].onWillDismiss({ reason: 0, dismiss() { dismissCalls++; } });
  assert.equal(dismissCalls, 1);
  assert.equal(page.downloadItemsSource().length, 0);
  assert.equal(runtime.workerStarts.length, 0);
  assert.equal(runtime.persistence.length, 0);
  page.toggleGalleryQueue(item({ gid: 690 }));
  assert.equal(runtime.dialogs.length, 2);
  runtime.dialogs[1].buttons[0].action();
  assert.equal(page.findDownloadItem(690, 'e').imageQuality, 'original');
});


test('late disappearance of an old dialog cannot release a reopened gallery quality prompt', () => {
  const runtime = createRuntime();
  const page = runtime.page();
  const gallery = item({ gid: 691 });
  page.toggleGalleryQueue(gallery);
  const oldDialog = runtime.dialogs[0];
  oldDialog.cancel();
  page.toggleGalleryQueue(gallery);
  assert.equal(runtime.dialogs.length, 2);
  oldDialog.onDidDisappear();
  page.toggleGalleryQueue(gallery);
  assert.equal(runtime.dialogs.length, 2);
  assert.equal(page.downloadItemsSource().length, 0);
  runtime.dialogs[1].buttons[0].action();
  assert.equal(page.findDownloadItem(691, 'e').imageQuality, 'original');
  assert.equal(runtime.workerStarts.length, 1);
});
