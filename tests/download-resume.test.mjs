import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';

// Execute production collection, gallery workers, retries, progress accounting,
// and cancellation guards. Network/page commits are controlled doubles; these
// tests do not run HTTP, write files, or verify public-directory grants.
// Run with Node.js 22.13+: node --test tests/download-resume.test.mjs
const source = readFileSync(new URL('../entry/src/main/ets/pages/Index.ets', import.meta.url), 'utf8');
const modelSource = readFileSync(new URL('../entry/src/main/ets/download/DownloadModels.ets', import.meta.url), 'utf8');
const appSource = readFileSync(new URL('../entry/src/main/ets/constants/AppConstants.ets', import.meta.url), 'utf8');

function productionMethod(name) {
  const start = source.search(new RegExp(`\\n  private (?:async )?${name}\\(`));
  assert.notEqual(start, -1, `Missing download resume method: ${name}`);
  const tail = source.slice(start + 1);
  const end = tail.slice(1).search(/\n  (?:private |aboutTo|@Builder)/);
  assert.notEqual(end, -1, `Missing end of download resume method: ${name}`);
  return tail.slice(0, end + 1);
}

const constants = [...source.split('\n'), ...modelSource.split('\n'), ...appSource.split('\n')]
  .filter((line) => /^(?:export )?(?:const|let) (?:sharedDownload(?:WorkerRunning|ActiveKey|CancelKeys|RemovedKeys|StartRequestedKeys|RunGenerations|PageTransferFractions)|DOWNLOAD_RUNTIME_(?:CANCEL|REMOVED)_KEYS_KEY|READER_IMAGE_EXTENSIONS|DOWNLOAD_STATUS_[A-Z_]+|DOWNLOAD_(?:PAGE_RETRY_LIMIT|DEFAULT_LABEL|MAX_CONCURRENCY|PROGRESS_UI_INTERVAL_MS|PROGRESS_PERSIST_INTERVAL_MS))\b/.test(line))
  .join('\n').replace(/^export /gm, '');
const fieldNames = ['downloadPageUrlCache', 'downloadPageTransferFractions'];
const fields = fieldNames.map((name) => {
  const line = source.split('\n').find((candidate) => new RegExp(`private (?:readonly )?${name}\\s*:`).test(candidate));
  assert.ok(line, `Missing production field: ${name}`);
  return line;
}).join('\n');
const methods = [
  'downloadKey', 'currentDownloadRunGeneration', 'isDownloadKeyCancelled', 'isDownloadKeyRemoved',
  'shouldStopDownload', 'assertDownloadRunActive', 'toDownloadItem', 'cloneDownloadItem',
  'normalizeDownloadStatus', 'updateDownloadProgress', 'updateDownloadPageTransferFraction',
  'clearDownloadPageTransferFraction', 'clearDownloadTransferProgress', 'downloadPageTransferFractionSum',
  'fetchDownloadDetail', 'collectDownloadPageUrls', 'downloadPageWithRetry', 'runGalleryDownload',
  'existingDownloadPath', 'downloadUsesOriginalImage'
];
const harnessSource = stripTypeScriptTypes(`(() => {
  ${constants}
  return {
    Harness: class DownloadResumeHarness {
      ${fields}
      ${methods.map(productionMethod).join('\n')}
    },
    generations: sharedDownloadRunGenerations,
    cancelKeys: sharedDownloadCancelKeys,
    retryLimit: DOWNLOAD_PAGE_RETRY_LIMIT,
    runtimeCancelKey: DOWNLOAD_RUNTIME_CANCEL_KEYS_KEY
  };
})()`);

const urlFor = (index) => `https://gallery.example/s/0123456789/123-${index + 1}`;
const dir = '/public/Download/EhViewer/e-123';

function item(overrides = {}) {
  return {
    gid: 123, token: 'token', title: 'Gallery', titleJpn: '', cover: '',
    detailUrl: 'https://gallery.example/g/123/token/', site: 'e', uploader: 'uploader',
    categoryLabel: 'Manga', posted: 'posted', pages: 3, language: 'Japanese', rating: 4,
    imageQuality: 'compressed', status: 'downloading', label: 'default', queuedAt: 'queued', lastAction: '',
    downloaded: 0, total: 3, failedCount: 0, archiveUri: '', createdAt: 'created',
    updatedAt: 'updated', currentPage: 0, currentPageLabel: '', speedBytesPerSecond: 0,
    remainingSeconds: -1, downloadDir: dir, error: '', pageErrors: [],
    ...overrides
  };
}

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((accept, decline) => { resolve = accept; reject = decline; });
  return { promise, resolve, reject };
}

async function until(predicate) {
  for (let count = 0; count < 120; count++) {
    if (predicate()) return;
    await Promise.resolve();
  }
  assert.fail('Expected controlled async stage was not reached');
}

function createGallery({ pages = 3, existing = [], previewPlans = [], singlePlans = {},
  failures = {}, detailPlan = undefined, concurrency = 1, taskOverrides = {},
  verifiedExisting = existing } = {}) {
  const task = item({ pages, total: pages, ...taskOverrides });
  const detail = { ...task, previewPageCount: 1 };
  const files = new Map(existing.map((index) => [index, { original: true, page: index }]));
  const verified = new Set(verifiedExisting);
  const previewCalls = [];
  const singleCalls = [];
  const attempts = new Map();
  const replacements = [];
  const managerWrites = [];
  const runtimeWrites = [];
  const cancelled = new Set();
  const plans = [...previewPlans];
  let activeSingles = 0;
  let maxActiveSingles = 0;
  let gallery;
  const production = vm.runInNewContext(harnessSource, {
    // Directory identity writes and migration are exercised against the real
    // filesystem adapter in gallery-download-directory/download-storage tests.
    writeGalleryDirectoryIdentity: () => true,
    verifiedOriginalDownloadPath: (_directory, _identity, index) =>
      files.has(index) && verified.has(index) ? `${dir}/${`${index + 1}`.padStart(8, '0')}.jpg` : '',
    fileIo: {
      accessSync(path) {
        const match = /\/(\d{8})\.jpg$/.exec(path);
        return !!match && files.has(Number(match[1]) - 1);
      },
      statSync() { return { isFile: () => true, size: 100 }; }
    },
    clampNumber: (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum),
    formatByteSize: (value) => `${value}B`,
    NativeEhClient: {
      async fetchGalleryDetail() { return detailPlan ? await detailPlan() : detail; },
      async fetchGalleryPreviewPage(site, detailUrl, pageIndex, control) {
        previewCalls.push({ site, detailUrl, pageIndex, control });
        const plan = plans.shift() ?? { pageCount: 1,
          items: Array.from({ length: pages }, (_, position) => ({ position, pageUrl: urlFor(position) })) };
        return typeof plan === 'function' ? await plan(gallery) : plan;
      }
    }
  });
  const key = 'e-123';
  production.generations.set(key, 4);
  const page = new Proxy(new production.Harness(), {
    set(target, property, value) {
      if (property === 'downloadManagerStatus') managerWrites.push(value);
      target[property] = value;
      return true;
    }
  });
  page.downloadItems = [task];
  page.downloadCancelKeys = new Set();
  page.downloadRemovedKeys = new Set();
  page.downloadStartRequestedKeys = new Set();
  page.downloadConcurrency = concurrency;
  page.downloadDirectoryStatus = '';
  page.downloadActiveKey = '';
  page.isRuntimeStringArrayMarked = (kind, candidate) => kind === production.runtimeCancelKey && cancelled.has(candidate);
  page.updateRuntimeStringArray = (kind, candidate, enabled) => {
    runtimeWrites.push({ kind, candidate, enabled });
    if (enabled) cancelled.add(candidate); else cancelled.delete(candidate);
  };
  page.findDownloadItem = (gid, site) => page.downloadItems.find((current) => current.gid === gid && current.site === site);
  page.nowLabel = () => 'now';
  page.downloadSiteReady = () => true;
  page.toNativeSummary = (record) => record;
  page.createDownloadRequestControl = (record, generation) => ({
    isCancelled: () => page.shouldStopDownload(record, generation)
  });
  page.restoreExistingDownloadDirectory = (record) => record;
  page.galleryDirectoryIdentity = (record) => ({
    gid: record.gid, site: record.site, token: record.token, title: record.title
  });
  page.preparePublicDownloadDirectory = async () => true;
  page.galleryDownloadDir = (record) => record.downloadDir || dir;
  page.ensureLocalDirectory = () => true;
  page.writeDownloadMetadata = () => {};
  page.replaceDownloadItemInternal = (next) => {
    page.downloadItems = [next];
    replacements.push({ ...next, pageErrors: Array.from(next.pageErrors, (error) => ({ ...error })) });
  };
  page.replaceDownloadItem = (next) => page.replaceDownloadItemInternal(next);
  page.activeDownloadRuntimeKey = () => page.downloadActiveKey;
  page.refreshDownloadRuntimeState = () => {};
  page.publishDownloadRuntimeStorage = () => {};
  page.toast = () => {};
  page.updateDownloadStatus = (_gid, _site, status) => { page.downloadItems[0].status = status; };
  page.downloadSinglePage = async (record, url, index, generation, onProgress) => {
    page.assertDownloadRunActive(record, generation);
    const attempt = (attempts.get(index) ?? 0) + 1;
    attempts.set(index, attempt);
    singleCalls.push({ index, url, generation, attempt, imageQuality: record.imageQuality });
    activeSingles++;
    maxActiveSingles = Math.max(maxActiveSingles, activeSingles);
    try {
      if (attempt <= (failures[index] ?? 0)) throw new Error(`Page ${index + 1} failed`);
      if (singlePlans[index]) await singlePlans[index](gallery, onProgress, attempt);
      page.assertDownloadRunActive(record, generation);
      files.set(index, { original: false, page: index, url });
      if (record.imageQuality === 'original') verified.add(index);
      return { path: `${dir}/${index + 1}.jpg`, bytes: 100, sourceUrl: url };
    } finally {
      activeSingles--;
    }
  };
  gallery = {
    page, task, detail, files, previewCalls, singleCalls, attempts, replacements,
    managerWrites, runtimeWrites, failures,
    get current() { return page.downloadItems[0]; },
    get maximumConcurrency() { return maxActiveSingles; },
    get generation() { return production.generations.get(key); },
    get cancelled() { return cancelled.has(key) || production.cancelKeys.has(key); },
    run() { return page.runGalleryDownload(gallery.current, gallery.generation); },
    collect() { return page.collectDownloadPageUrls(gallery.current, detail, gallery.generation); },
    pause() {
      production.generations.set(key, gallery.generation + 1);
      production.cancelKeys.add(key);
      cancelled.add(key);
      page.downloadItems = [{ ...gallery.current, status: 'paused', lastAction: '已暂停' }];
      page.downloadManagerStatus = '已暂停';
    },
    requeue() {
      production.generations.set(key, gallery.generation + 1);
      production.cancelKeys.delete(key);
      cancelled.delete(key);
      page.downloadItems = [{ ...gallery.current, status: 'waiting', lastAction: '等待下载', error: '' }];
      page.downloadManagerStatus = '等待新一轮下载';
    }
  };
  return gallery;
}

test('collector preserves a missing middle position and refetches until its cache is complete', async () => {
  const gallery = createGallery({ previewPlans: [
    { pageCount: 1, items: [{ position: 0, pageUrl: urlFor(0) }, { position: 2, pageUrl: urlFor(2) }] },
    { pageCount: 1, items: [0, 1, 2].map((position) => ({ position, pageUrl: urlFor(position) })) }
  ] });
  assert.deepEqual(Array.from(await gallery.collect()), [urlFor(0), '', urlFor(2)]);
  assert.equal(gallery.page.downloadPageUrlCache.size, 0);
  assert.deepEqual(Array.from(await gallery.collect()), [urlFor(0), urlFor(1), urlFor(2)]);
  assert.equal(gallery.page.downloadPageUrlCache.size, 1);
  assert.equal(gallery.previewCalls.length, 2);
  assert.deepEqual(Array.from(await gallery.collect()), [urlFor(0), urlFor(1), urlFor(2)]);
  assert.equal(gallery.previewCalls.length, 2);
});

test('a missing middle link fails only that page and never shifts later image numbers', async () => {
  const gallery = createGallery({ previewPlans: [{ pageCount: 1,
    items: [{ position: 0, pageUrl: urlFor(0) }, { position: 2, pageUrl: urlFor(2) }] }] });
  await gallery.run();
  assert.deepEqual(gallery.singleCalls.map(({ index, url }) => ({ index, url })), [
    { index: 0, url: urlFor(0) }, { index: 2, url: urlFor(2) }
  ]);
  assert.deepEqual([...gallery.files.keys()].sort(), [0, 2]);
  assert.equal(gallery.current.status, 'failed');
  assert.equal(gallery.current.downloaded, 2);
  assert.equal(gallery.current.failedCount, 1);
  assert.deepEqual(Array.from(gallery.current.pageErrors, ({ page }) => page), [2]);
});

test('preexisting pages zero and two are retained while only page one is downloaded', async () => {
  const gallery = createGallery({ existing: [0, 2] });
  const first = gallery.files.get(0);
  const third = gallery.files.get(2);
  await gallery.run();
  assert.deepEqual(gallery.singleCalls.map(({ index }) => index), [1]);
  assert.equal(gallery.files.get(0), first);
  assert.equal(gallery.files.get(2), third);
  assert.equal(gallery.current.status, 'complete');
  assert.equal(gallery.current.downloaded, 3);
  const checked = gallery.replacements.findIndex(({ lastAction }) => lastAction === '已检查本地文件，正在继续下载');
  assert.notEqual(checked, -1);
  assert.ok(gallery.replacements.slice(checked).every(({ downloaded }) => downloaded >= 2 && downloaded <= 3));
});

test('an original run replaces an unverified small page while retaining a proven original', async () => {
  const gallery = createGallery({ existing: [0, 2], verifiedExisting: [2],
    taskOverrides: { imageQuality: 'original' } });
  const unverified = gallery.files.get(0);
  const verified = gallery.files.get(2);
  await gallery.run();
  assert.deepEqual(gallery.singleCalls.map(({ index }) => index), [0, 1]);
  assert.notEqual(gallery.files.get(0), unverified);
  assert.equal(gallery.files.get(2), verified);
  assert.equal(gallery.current.status, 'complete');
  assert.equal(gallery.current.downloaded, 3);
  const calls = gallery.singleCalls.length;
  gallery.requeue();
  await gallery.run();
  assert.equal(gallery.singleCalls.length, calls, 'A second run reuses the now-verified original pages');
});

test('a failed original replacement retains the unverified image without counting it as completed', async () => {
  const gallery = createGallery({ pages: 1, existing: [0], verifiedExisting: [], failures: { 0: Infinity },
    taskOverrides: { imageQuality: 'original' } });
  const previous = gallery.files.get(0);
  await gallery.run();
  assert.equal(gallery.files.get(0), previous);
  assert.equal(gallery.current.status, 'failed');
  assert.equal(gallery.current.downloaded, 0);
  assert.equal(gallery.current.failedCount, 1);
});

test('a failed page exhausts retries while the other completed files and exact page error survive', async () => {
  const gallery = createGallery({ failures: { 1: Infinity } });
  await gallery.run();
  assert.equal(gallery.attempts.get(1), 3);
  assert.equal(gallery.attempts.get(0), 1);
  assert.equal(gallery.attempts.get(2), 1);
  assert.deepEqual([...gallery.files.keys()].sort(), [0, 2]);
  assert.equal(gallery.current.status, 'failed');
  assert.equal(gallery.current.downloaded, 2);
  assert.equal(gallery.current.failedCount, 1);
  assert.match(gallery.current.error, /页失败.*Page 2 failed/,
    'Show the concrete page failure rather than replacing it with only a failed-page count');
  assert.deepEqual(Array.from(gallery.current.pageErrors, ({ page }) => page), [2]);
});

test('manual retry downloads only the failed page and clears stale task and page errors', async () => {
  const gallery = createGallery({ failures: { 1: Infinity } });
  await gallery.run();
  const beforeRetry = gallery.singleCalls.length;
  const first = gallery.files.get(0);
  const third = gallery.files.get(2);
  gallery.failures[1] = 0;
  gallery.requeue();
  await gallery.run();
  assert.deepEqual(gallery.singleCalls.slice(beforeRetry).map(({ index }) => index), [1]);
  assert.equal(gallery.files.get(0), first);
  assert.equal(gallery.files.get(2), third);
  assert.equal(gallery.current.status, 'complete');
  assert.equal(gallery.current.error, '');
  assert.equal(gallery.current.failedCount, 0);
  assert.equal(gallery.current.pageErrors.length, 0);
});

test('manual retry refetches missing links and downloads only the previously missing page', async () => {
  const gallery = createGallery({ previewPlans: [
    { pageCount: 1, items: [{ position: 0, pageUrl: urlFor(0) }, { position: 2, pageUrl: urlFor(2) }] },
    { pageCount: 1, items: [0, 1, 2].map((position) => ({ position, pageUrl: urlFor(position) })) }
  ] });
  await gallery.run();
  const firstRunCalls = gallery.singleCalls.length;
  gallery.requeue();
  await gallery.run();
  assert.equal(gallery.previewCalls.length, 2);
  assert.deepEqual(gallery.singleCalls.slice(firstRunCalls).map(({ index, url }) => ({ index, url })), [
    { index: 1, url: urlFor(1) }
  ]);
  assert.equal(gallery.current.status, 'complete');
  assert.equal(gallery.current.downloaded, 3);
  assert.equal(gallery.current.error, '');
  assert.equal(gallery.current.pageErrors.length, 0);
});

test('three concurrent workers claim every page once and count out-of-order completions correctly', async () => {
  const pending = Array.from({ length: 6 }, () => deferred());
  const gallery = createGallery({ pages: 6, concurrency: 3,
    singlePlans: Object.fromEntries(pending.map((promise, index) => [index, () => promise.promise])) });
  const work = gallery.run();
  await until(() => gallery.singleCalls.length === 3);
  assert.deepEqual(gallery.singleCalls.map(({ index }) => index), [0, 1, 2]);
  pending[2].resolve();
  await until(() => gallery.singleCalls.length === 4);
  pending[0].resolve();
  await until(() => gallery.singleCalls.length === 5);
  pending[1].resolve();
  await until(() => gallery.singleCalls.length === 6);
  for (const index of [4, 3, 5]) pending[index].resolve();
  await work;
  assert.equal(gallery.maximumConcurrency, 3);
  assert.deepEqual(gallery.singleCalls.map(({ index }) => index).sort(), [0, 1, 2, 3, 4, 5]);
  assert.ok([...gallery.attempts.values()].every((count) => count === 1));
  assert.equal(gallery.current.status, 'complete');
  assert.equal(gallery.current.downloaded, 6);
  assert.equal(gallery.files.size, 6);
  const checked = gallery.replacements.findIndex(({ lastAction }) => lastAction === '已检查本地文件，正在继续下载');
  const counts = gallery.replacements.slice(checked).map(({ downloaded }) => downloaded);
  assert.ok(counts.every((count, index) => count >= 0 && count <= 6 && (index === 0 || count >= counts[index - 1])));
});

test('pause during gallery metadata parsing prevents progress or failure state from being written back', async () => {
  const pending = deferred();
  let metadataStarted = false;
  const gallery = createGallery({ detailPlan: () => { metadataStarted = true; return pending.promise; } });
  const work = gallery.run();
  await until(() => metadataStarted);
  gallery.pause();
  const previousWrites = gallery.replacements.length;
  pending.reject(new Error('Metadata request cancelled'));
  await work;
  assert.equal(gallery.current.status, 'paused');
  assert.equal(gallery.replacements.length, previousWrites);
  assert.equal(gallery.singleCalls.length, 0);
  assert.equal(gallery.cancelled, true);
  assert.equal(gallery.runtimeWrites.length, 0);
});

test('a queued newer generation keeps its controls and cancellation markers after old metadata settles', async () => {
  const pending = deferred();
  let metadataStarted = false;
  const gallery = createGallery({ detailPlan: () => { metadataStarted = true; return pending.promise; } });
  const work = gallery.run();
  await until(() => metadataStarted);
  gallery.pause();
  gallery.requeue();
  const previousWrites = gallery.replacements.length;
  const previousRuntimeWrites = gallery.runtimeWrites.length;
  pending.resolve(gallery.detail);
  await work;
  assert.equal(gallery.current.status, 'waiting');
  assert.equal(gallery.current.lastAction, '等待下载');
  assert.equal(gallery.page.downloadManagerStatus, '等待新一轮下载');
  assert.equal(gallery.replacements.length, previousWrites);
  assert.equal(gallery.runtimeWrites.length, previousRuntimeWrites);
  assert.equal(gallery.singleCalls.length, 0);
});

test('an obsolete metadata completion cannot clear a newer pause marker after rapid pause, resume, and pause', async () => {
  const pending = deferred();
  let metadataStarted = false;
  const gallery = createGallery({ detailPlan: () => { metadataStarted = true; return pending.promise; } });
  const work = gallery.run();
  await until(() => metadataStarted);
  gallery.pause();
  gallery.requeue();
  gallery.pause();
  const previousWrites = gallery.replacements.length;
  pending.reject(new Error('Old request cancelled'));
  await work;
  assert.equal(gallery.current.status, 'paused');
  assert.equal(gallery.cancelled, true);
  assert.equal(gallery.runtimeWrites.length, 0);
  assert.equal(gallery.replacements.length, previousWrites);
});

test('pausing during preview collection prevents a stale completed result from entering the cache', async () => {
  const pending = deferred();
  const gallery = createGallery({ previewPlans: [() => pending.promise] });
  const work = gallery.collect();
  assert.equal(gallery.previewCalls.length, 1);
  gallery.pause();
  pending.resolve({ pageCount: 1,
    items: [0, 1, 2].map((position) => ({ position, pageUrl: urlFor(position) })) });
  await assert.rejects(work, /已取消/);
  assert.equal(gallery.page.downloadPageUrlCache.size, 0);
  assert.equal(gallery.singleCalls.length, 0);
});

for (const imageQuality of ['original', 'compressed']) {
  test(`${imageQuality} remains attached throughout detail refresh, page workers, and completion`, async () => {
    const metadata = deferred();
    let detailStarted = false;
    const gallery = createGallery({ taskOverrides: { imageQuality },
      detailPlan: () => { detailStarted = true; return metadata.promise; } });
    const work = gallery.run();
    await until(() => detailStarted);
    assert.equal(gallery.current.imageQuality, imageQuality);
    assert.ok(gallery.replacements.every((replacement) => replacement.imageQuality === imageQuality));
    // The gallery detail API is metadata-only. It does not supply the queue's
    // selected quality, so the production metadata replacement must retain it.
    const fetchedDetail = { ...gallery.detail };
    delete fetchedDetail.imageQuality;
    metadata.resolve(fetchedDetail);
    await work;
    assert.equal(gallery.singleCalls.length, 3);
    assert.ok(gallery.singleCalls.every((call) => call.imageQuality === imageQuality));
    assert.ok(gallery.replacements.every((replacement) => replacement.imageQuality === imageQuality));
    assert.equal(gallery.current.status, 'complete');
    assert.equal(gallery.current.imageQuality, imageQuality);
  });

  test(`${imageQuality} survives pause, resume, metadata replacement, and completed-page reuse`, async () => {
    const pendingPage = deferred();
    const gallery = createGallery({ existing: [0], taskOverrides: { imageQuality },
      singlePlans: { 1: (_gallery, _progress, attempt) => attempt === 1 ? pendingPage.promise : Promise.resolve() } });
    const firstPage = gallery.files.get(0);
    const work = gallery.run();
    await until(() => gallery.singleCalls.length === 1);
    gallery.pause();
    pendingPage.resolve();
    await work;
    assert.equal(gallery.current.status, 'paused');
    assert.equal(gallery.current.imageQuality, imageQuality);
    assert.equal(gallery.files.get(0), firstPage);
    assert.equal(gallery.files.size, 1);
    const beforeResume = gallery.singleCalls.length;
    gallery.requeue();
    await gallery.run();
    assert.equal(gallery.current.status, 'complete');
    assert.equal(gallery.current.imageQuality, imageQuality);
    assert.equal(gallery.files.get(0), firstPage);
    assert.deepEqual(gallery.singleCalls.slice(beforeResume).map(({ index }) => index), [1, 2]);
    assert.ok(gallery.singleCalls.every((call) => call.imageQuality === imageQuality));
    assert.ok(gallery.replacements.every((replacement) => replacement.imageQuality === imageQuality));
  });
}
