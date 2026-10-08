import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';

// Execute the production cancellation, retry, HTTP, and page-commit methods.
// Also execute the native original-image resolver in the Index page pipeline.
// Controlled HTTP/cookie adapters and a byte-level filesystem double model
// cancellation races and partial writes; this does not use real networking,
// verify image quality on a device, or obtain public-directory grants.
// Run with Node.js 22.13+: node --test tests/download-cancellation.test.mjs
const source = readFileSync(new URL('../entry/src/main/ets/pages/Index.ets', import.meta.url), 'utf8');
const modelSource = readFileSync(new URL('../entry/src/main/ets/download/DownloadModels.ets', import.meta.url), 'utf8');
const appConstants = readFileSync(new URL('../entry/src/main/ets/constants/AppConstants.ets', import.meta.url), 'utf8');
const nativeSource = readFileSync(new URL('../entry/src/main/ets/ehviewer/EhNative.ets', import.meta.url), 'utf8');

function productionMethod(name) {
  const start = source.search(new RegExp(`\\n  private (?:async )?${name}\\(`));
  assert.notEqual(start, -1, `Missing download method: ${name}`);
  const tail = source.slice(start + 1);
  const end = tail.slice(1).search(/\n  (?:private |aboutTo|@Builder)/);
  assert.notEqual(end, -1, `Missing end of download method: ${name}`);
  return tail.slice(0, end + 1);
}

function nativeMethod(name) {
  const start = nativeSource.search(new RegExp(`\\n  (?:private|public) static (?:async )?${name}\\(`));
  assert.notEqual(start, -1, `Missing native method: ${name}`);
  const tail = nativeSource.slice(start + 1);
  const end = tail.indexOf('\n  }');
  assert.notEqual(end, -1, `Missing native method end: ${name}`);
  return tail.slice(0, end + 4);
}

function nativeFunction(name) {
  const start = nativeSource.indexOf(`function ${name}(`);
  assert.notEqual(start, -1, `Missing native function: ${name}`);
  const tail = nativeSource.slice(start);
  const end = tail.indexOf('\n}');
  assert.notEqual(end, -1, `Missing native function end: ${name}`);
  return tail.slice(0, end + 2);
}

const constants = [...source.split('\n'), ...modelSource.split('\n'), ...appConstants.split('\n')]
  .filter((line) => /^(?:export )?const (?:sharedDownload(?:CancelKeys|RemovedKeys|RunGenerations|ActiveRequests|RequestCancelSignals)|DOWNLOAD_RUNTIME_(?:CANCEL|REMOVED)_KEYS_KEY|DOWNLOAD_STATUS_[A-Z_]+|DOWNLOAD_PAGE_RETRY_LIMIT|DOWNLOAD_IMAGE_RESPONSE_MAX_BYTES|READER_IMAGE_EXTENSIONS)\b/.test(line))
  .join('\n').replace(/^export /gm, '');
const methods = [
  'downloadKey', 'findDownloadIndex', 'findDownloadItem', 'currentDownloadRunGeneration',
  'isDownloadKeyCancelled', 'isDownloadKeyRemoved', 'shouldStopDownload', 'assertDownloadRunActive',
  'registerDownloadActiveRequest', 'unregisterDownloadActiveRequest', 'cancelDownloadActiveRequests',
  'createDownloadRequestControl',
  'downloadImageFile', 'downloadSinglePage', 'downloadPageWithRetry', 'downloadUsesOriginalImage',
  'downloadTargetPath', 'readerImageExtensionFromUrl', 'galleryDownloadDir', 'downloadRoot',
  'galleryDirectoryIdentity', 'removeReplacedDownloadPageFiles',
  'downloadCookieHeader', 'appendDownloadCookieSource', 'appendReaderCookieSource', 'readerHostFromUrl'
];
const requestRegistryField = source.split('\n').find((line) => /private (?:readonly )?downloadActiveRequests\s*:/.test(line));
assert.ok(requestRegistryField, 'Missing production request registry field');
const harnessSource = stripTypeScriptTypes(`(() => {
  ${constants}
  ${['isMeaningfulErrorMessage', 'nativeRequestErrorMessage', 'readerPageUrlWithSkipHathKey'].map(nativeFunction).join('\n')}
  class NativeOriginalRequest {
    ${nativeMethod('fetchOriginalImageUrl')}
  }
  class EhUrl {
    ${nativeSource.split('\n').filter((line) => /^  static readonly DOMAIN_(?:E|EX|FORUMS):/.test(line)).join('\n')}
  }
  return {
    Harness: class DownloadHarness {
      ${requestRegistryField}
      ${methods.map(productionMethod).join('\n')}
    },
    cancelKeys: sharedDownloadCancelKeys,
    removedKeys: sharedDownloadRemovedKeys,
    generations: sharedDownloadRunGenerations,
    retryLimit: DOWNLOAD_PAGE_RETRY_LIMIT,
    runtimeCancelKey: DOWNLOAD_RUNTIME_CANCEL_KEYS_KEY,
    runtimeRemovedKey: DOWNLOAD_RUNTIME_REMOVED_KEYS_KEY,
    fetchOriginalImageUrl: NativeOriginalRequest.fetchOriginalImageUrl,
    activeRequests: sharedDownloadActiveRequests,
    cancelSignals: sharedDownloadRequestCancelSignals
  };
})()`);

const targetPath = '/public/Download/EhViewer/e-123/00000001.jpg';
const tempPath = `${targetPath}.tmp`;
const imageBytes = Uint8Array.from([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3, 4, 5, 6]);
const pageUrl = 'https://gallery.example/s/0123456789/123-1';

function response({ status = 200, bytes = imageBytes, headers = {} } = {}) {
  return { responseCode: status, result: bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength), header: headers };
}

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((accept, decline) => { resolve = accept; reject = decline; });
  return { promise, resolve, reject };
}

async function settleMicrotasks() {
  for (let count = 0; count < 8; count++) await Promise.resolve();
}

function createDownload({ plans = [], originalPlans = [], metadata = undefined, writeResults = [],
  statSizeDelta = 0, renameThrows = false, oldPage = undefined, afterOn = undefined,
  taskOverrides = {}, globalOriginal = false, cookies = {}, imageInfo = undefined,
  originalReceiptResult = true, imageReleaseError = undefined } = {}) {
  const files = new Map(oldPage ? [[targetPath, Uint8Array.from(oldPage)]] : []);
  const descriptors = new Map();
  const operations = [];
  const requests = [];
  const requestCalls = [];
  const metadataCalls = [];
  const originalCalls = [];
  const cookieSources = [];
  const originalReceipts = [];
  const imageInspections = [];
  const runtimeCancelled = new Set();
  const runtimeRemoved = new Set();
  const pendingPlans = [...plans];
  const pendingOriginalPlans = [...originalPlans];
  const pendingWrites = [...writeResults];
  let nextDescriptor = 1;
  let harness;
  const production = vm.runInNewContext(harnessSource, {
    setTimeout, clearTimeout,
    recordOriginalDownloadPage(dir, identity, pageIndex, result) {
      originalReceipts.push({ dir, identity, pageIndex, result });
      return originalReceiptResult;
    },
    image: {
      createImageSource(data) {
        const inspection = { data, released: false };
        imageInspections.push(inspection);
        return {
          async getImageInfo() {
            if (imageInfo instanceof Error) throw imageInfo;
            assert.ok(imageInfo, 'Provide dimensions for an original-size inspection');
            return { size: imageInfo };
          },
          async release() {
            inspection.released = true;
            if (imageReleaseError) throw imageReleaseError;
          }
        };
      }
    },
    http: {
      RequestMethod: { GET: 'GET' }, HttpDataType: { ARRAY_BUFFER: 'ARRAY_BUFFER', STRING: 'STRING' },
      createHttp() {
        const callbacks = new Map();
        const request = {
          callbacks, destroyCount: 0, pendingReject: undefined,
          on(name, callback) { callbacks.set(name, callback); afterOn?.(harness); },
          off(name) { callbacks.delete(name); },
          request(url, options) {
            requestCalls.push({ url, options });
            const plan = options.expectDataType === 'STRING' ?
              pendingOriginalPlans.shift() ?? { responseCode: 302, result: '', header: { Location: 'https://image.example/original.png' } } :
              pendingPlans.shift() ?? response();
            if (plan instanceof Error) return Promise.reject(plan);
            if (typeof plan === 'function') return Promise.resolve(plan(request));
            return Promise.resolve(plan);
          },
          destroy() {
            this.destroyCount++;
            this.pendingReject?.(new Error('Request destroyed'));
          }
        };
        requests.push(request);
        return request;
      }
    },
    NativeEhClient: {
      USER_AGENT: 'test-user-agent',
      REQUEST_USER_AGENT: 'test-user-agent', REQUEST_ACCEPT_LANGUAGE: 'test-language',
      DOWNLOAD_USER_AGENT: 'test-user-agent', DOWNLOAD_ACCEPT_LANGUAGE: 'test-language',
      DOWNLOAD_ACCEPT: 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
      readCookie: () => '', captureResponseCookies: () => {}, captureCookieHeader: () => {},
      async fetchReaderPage(site, url, skipHathKey, control) {
        metadataCalls.push({ site, url, skipHathKey, control });
        if (metadata) return await metadata(site, url, control);
        return { pageUrl: url, imageUrl: 'https://image.example/page.jpg', originImageUrl: '' };
      },
      async fetchOriginalImageUrl(site, page, control) {
        originalCalls.push({ site, page, control });
        return await production.fetchOriginalImageUrl(site, page, control);
      }
    },
    GallerySite: { E: 'e', EX: 'ex' },
    url: { URL },
    webview: { WebCookieManager: { fetchCookieSync(url) {
      cookieSources.push(url);
      return cookies[url] ?? '';
    } } },
    AppNetworkProxy: { requestProxy: () => ({}) },
    fileIo: {
      OpenMode: { READ_WRITE: 2, CREATE: 64, TRUNC: 512 },
      openSync(path) {
        operations.push({ kind: 'open', path });
        files.set(path, new Uint8Array());
        const fd = nextDescriptor++;
        descriptors.set(fd, { path, position: 0 });
        return { fd };
      },
      writeSync(fd, buffer, options = {}) {
        const descriptor = descriptors.get(fd);
        assert.ok(descriptor, 'Write only through an open file descriptor');
        const bytes = new Uint8Array(buffer);
        operations.push({ kind: 'write', bytes: Array.from(bytes), options });
        assert.equal(options.offset, undefined, 'Use the current file pointer rather than adding a relative offset');
        assert.equal(options.length, bytes.byteLength);
        const planned = pendingWrites.shift() ?? bytes.byteLength;
        if (planned instanceof Error) throw planned;
        if (planned <= 0 || planned > bytes.byteLength) return planned;
        const current = files.get(descriptor.path);
        const next = new Uint8Array(Math.max(current.length, descriptor.position + planned));
        next.set(current);
        next.set(bytes.subarray(0, planned), descriptor.position);
        files.set(descriptor.path, next);
        descriptor.position += planned;
        return planned;
      },
      statSync(fd) {
        const path = typeof fd === 'number' ? descriptors.get(fd)?.path : fd;
        assert.ok(path && files.has(path), 'Validate an existing file or open temporary file');
        return { isFile: () => true, size: files.get(path).length + statSizeDelta };
      },
      listFileSync(dir) {
        return [...files.keys()].filter((path) => path.startsWith(`${dir}/`) &&
          !path.slice(dir.length + 1).includes('/')).map((path) => path.slice(dir.length + 1));
      },
      closeSync(file) {
        operations.push({ kind: 'close', fd: file.fd });
        descriptors.delete(file.fd);
      },
      accessSync(path) { return files.has(path); },
      unlinkSync(path) { operations.push({ kind: 'unlink', path }); files.delete(path); },
      renameSync(from, to) {
        operations.push({ kind: 'rename', from, to });
        if (renameThrows) throw new Error('Rename failed');
        assert.ok(files.has(from));
        files.set(to, files.get(from));
        files.delete(from);
      }
    }
  });
  const task = { gid: 123, site: 'e', imageQuality: 'compressed', status: 'downloading',
    downloadDir: '/public/Download/EhViewer/e-123', ...taskOverrides };
  const key = 'e-123';
  production.generations.set(key, 4);

  function configure(page) {
    page.downloadItems = [{ ...task }];
    page.downloadCancelKeys = new Set();
    page.downloadRemovedKeys = new Set();
    page.readBoolean = (key, fallback) => key === 'download_origin_image' ? globalOriginal : fallback;
    page.findDownloadItemByKey = (candidate) => page.downloadItems.find((item) => `${item.site}-${item.gid}` === candidate);
    page.isRuntimeStringArrayMarked = (kind, candidate) =>
      (kind === production.runtimeCancelKey ? runtimeCancelled : runtimeRemoved).has(candidate);
    page.ensureLocalDirectory = (path) => { operations.push({ kind: 'directory', path }); return true; };
    page.stringToArrayBuffer = (value) => Uint8Array.from(value, (character) => character.charCodeAt(0)).buffer;
    return page;
  }

  const page = configure(new production.Harness());
  harness = {
    page, task, key, files, operations, requests, requestCalls, metadataCalls, originalCalls, cookieSources,
    originalReceipts, imageInspections,
    activeRequests: production.activeRequests, cancelSignals: production.cancelSignals,
    retryLimit: production.retryLimit,
    start(progress) { return page.downloadPageWithRetry(task, pageUrl, 0, 4, progress); },
    image(progress) { return page.downloadImageFile(task, 4, 'https://image.example/page.jpg', pageUrl, targetPath, progress); },
    pause({ destroy = false, anotherPage = false } = {}) {
      const controller = anotherPage ? configure(new production.Harness()) : page;
      controller.downloadItems[0].status = 'paused';
      production.cancelKeys.add(key);
      production.generations.set(key, production.generations.get(key) + 1);
      if (destroy) controller.cancelDownloadActiveRequests(key);
    },
    runtimeCancel() { runtimeCancelled.add(key); },
    removeAndReadd() {
      production.removedKeys.add(key);
      page.downloadItems = [];
      production.generations.set(key, 5);
      production.removedKeys.delete(key);
      production.cancelKeys.delete(key);
      page.downloadItems = [{ ...task }];
      production.generations.set(key, 6);
    }
  };
  return harness;
}

function assertNoCommit(harness) {
  assert.equal(harness.operations.some((operation) => operation.kind === 'rename'), false);
  assert.equal(harness.files.has(tempPath), false);
  assert.equal(harness.operations.some((operation) => operation.kind === 'unlink' && operation.path === targetPath), false);
}

test('pausing during page metadata parsing prevents any subsequent image request or file write', async () => {
  const pending = deferred();
  const harness = createDownload({ metadata: () => pending.promise });
  const work = harness.start();
  await settleMicrotasks();
  harness.pause();
  pending.resolve({ pageUrl, imageUrl: 'https://image.example/page.jpg', originImageUrl: '' });
  await assert.rejects(work, /已取消/);
  assert.equal(harness.metadataCalls.length, 1);
  assert.equal(harness.requests.length, 0);
  assertNoCommit(harness);
});

test('destroying a paused request from another page does not trigger a new retry', async () => {
  const pending = deferred();
  const harness = createDownload({ plans: [(request) => {
    request.pendingReject = pending.reject;
    return pending.promise;
  }] });
  const work = harness.start();
  await settleMicrotasks();
  assert.equal(harness.requestCalls.length, 1);
  harness.pause({ destroy: true, anotherPage: true });
  await assert.rejects(work, /已取消/);
  assert.equal(harness.requests.length, 1);
  assert.equal(harness.metadataCalls.length, 1);
  assert.ok(harness.requests[0].destroyCount >= 1);
  assertNoCommit(harness);
});

test('a response resolved immediately before pause cannot commit a page', async () => {
  const pending = deferred();
  const harness = createDownload({ plans: [() => pending.promise] });
  const work = harness.image();
  pending.resolve(response());
  harness.pause();
  await assert.rejects(work, /已取消/);
  assert.equal(harness.operations.some((operation) => operation.kind === 'open'), false);
  assertNoCommit(harness);
});

test('removing and readding the same gallery does not reactivate an older generation response', async () => {
  const pending = deferred();
  const harness = createDownload({ plans: [() => pending.promise] });
  const work = harness.start();
  await settleMicrotasks();
  harness.removeAndReadd();
  pending.resolve(response());
  await assert.rejects(work, /已取消/);
  assert.equal(harness.requests.length, 1);
  assertNoCommit(harness);
});

test('global runtime cancellation stops an active attempt even without local cancellation markers', async () => {
  const pending = deferred();
  const harness = createDownload({ plans: [() => pending.promise] });
  const work = harness.image();
  harness.runtimeCancel();
  pending.resolve(response());
  await assert.rejects(work, /已取消/);
  assertNoCommit(harness);
});

test('late HTTP progress is filtered after pause or a stale generation', async () => {
  const pending = deferred();
  const progress = [];
  const harness = createDownload({ plans: [() => pending.promise] });
  const work = harness.image((received, total) => progress.push([received, total]));
  const callback = harness.requests[0].callbacks.get('dataReceiveProgress');
  callback({ receiveSize: 3, totalSize: 10 });
  harness.pause();
  callback({ receiveSize: 9, totalSize: 10 });
  assert.deepEqual(progress, [[3, 10]]);
  pending.resolve(response());
  await assert.rejects(work, /已取消/);
  assertNoCommit(harness);
});

test('cancellation before HTTP dispatch closes the created request without starting network work', async () => {
  const harness = createDownload({ afterOn: (active) => active.pause() });
  await assert.rejects(harness.image(() => {}), /已取消/);
  assert.equal(harness.requestCalls.length, 0);
  assert.ok(harness.requests[0].destroyCount > 0);
  assertNoCommit(harness);
});

test('ordinary network failures retry and then commit a complete page', async () => {
  const harness = createDownload({ plans: [new Error('Temporary network failure'), response()] });
  const result = await harness.start();
  assert.equal(harness.metadataCalls.length, 2);
  assert.equal(harness.requestCalls.length, 2);
  assert.equal(result.path, targetPath);
  assert.equal(result.bytes, imageBytes.length);
  assert.deepEqual(Array.from(harness.files.get(targetPath)), Array.from(imageBytes));
  assert.equal(harness.files.has(tempPath), false);
  assert.ok(harness.requests.every((request) => request.destroyCount > 0));
});

test('ordinary persistent failures honor the production retry limit', async () => {
  const harness = createDownload({ plans: Array.from({ length: 8 }, () => new Error('Network unavailable')) });
  await assert.rejects(harness.start(), /Network unavailable/);
  assert.equal(harness.metadataCalls.length, harness.retryLimit + 1);
  assert.equal(harness.requestCalls.length, harness.retryLimit + 1);
  assertNoCommit(harness);
});

test('non-2xx and obvious HTML responses never create an image file', async () => {
  for (const invalid of [
    response({ status: 302 }), response({ status: 404 }),
    response({ headers: { 'Content-Type': 'text/html; charset=UTF-8' } }),
    response({ bytes: Uint8Array.from(Buffer.from('  <!DOCTYPE html><html>Login required</html>')) })
  ]) {
    const harness = createDownload({ plans: [invalid] });
    await assert.rejects(harness.image(), /HTTP|HTML/);
    assert.equal(harness.operations.some((operation) => operation.kind === 'open'), false);
    assertNoCommit(harness);
  }
});

test('an incomplete uncompressed response is rejected while a decoded compressed response remains valid', async () => {
  for (const encoding of ['', 'identity']) {
    const harness = createDownload({ plans: [response({ headers: {
      'Content-Length': '20', 'Content-Encoding': encoding
    } })] });
    await assert.rejects(harness.image(), /响应长度不完整/);
    assertNoCommit(harness);
  }
  const compressed = createDownload({ plans: [response({ headers: {
    'Content-Length': '20', 'Content-Encoding': 'gzip'
  } })] });
  await compressed.image();
  assert.deepEqual(Array.from(compressed.files.get(targetPath)), Array.from(imageBytes));
});

test('short writes continue from the unwritten bytes without adding holes or replacing the previous page early', async () => {
  const harness = createDownload({ writeResults: [3, 2], oldPage: [9, 9, 9] });
  await harness.image();
  const writes = harness.operations.filter((operation) => operation.kind === 'write');
  assert.deepEqual(writes.map((operation) => operation.bytes), [
    Array.from(imageBytes), Array.from(imageBytes.slice(3)), Array.from(imageBytes.slice(5))
  ]);
  assert.deepEqual(Array.from(harness.files.get(targetPath)), Array.from(imageBytes));
  assert.equal(harness.operations.some((operation) => operation.kind === 'unlink' && operation.path === targetPath), false);
  assert.equal(harness.files.has(tempPath), false);
});

test('a zero-byte write or write exception removes the temporary fragment and preserves the previous complete page', async () => {
  for (const failure of [0, new Error('Disk full')]) {
    const harness = createDownload({ writeResults: [3, failure], oldPage: [9, 8, 7] });
    await assert.rejects(harness.image(), /写入不完整|Disk full/);
    assertNoCommit(harness);
    assert.deepEqual(Array.from(harness.files.get(targetPath)), [9, 8, 7]);
    assert.ok(harness.operations.some((operation) => operation.kind === 'unlink' && operation.path === tempPath));
  }
});

test('an incorrect final temporary-file size prevents commit even after successful writes', async () => {
  const harness = createDownload({ statSizeDelta: -1, oldPage: [9, 8, 7] });
  await assert.rejects(harness.image(), /文件长度不完整/);
  assertNoCommit(harness);
  assert.deepEqual(Array.from(harness.files.get(targetPath)), [9, 8, 7]);
});

test('rename failure cleans the completed temporary file and keeps the old page intact', async () => {
  const harness = createDownload({ renameThrows: true, oldPage: [9, 8, 7] });
  await assert.rejects(harness.image(), /Rename failed/);
  assert.deepEqual(Array.from(harness.files.get(targetPath)), [9, 8, 7]);
  assert.equal(harness.files.has(tempPath), false);
  assert.equal(harness.operations.some((operation) => operation.kind === 'unlink' && operation.path === targetPath), false);
});

test('cross-page pause finishes even if destroying the native image request never settles its promise', { timeout: 1000 }, async () => {
  const pending = deferred();
  const harness = createDownload({ plans: [() => pending.promise], oldPage: [9, 8, 7] });
  const work = harness.start();
  await settleMicrotasks();
  assert.equal(harness.requestCalls.length, 1);
  harness.pause({ destroy: true, anotherPage: true });
  await assert.rejects(work, /已取消/);
  assert.equal(harness.requests.length, 1);
  assertNoCommit(harness);
  pending.resolve(response());
  await settleMicrotasks();
  assertNoCommit(harness);
  assert.deepEqual(Array.from(harness.files.get(targetPath)), [9, 8, 7]);
});

test('a new generation can commit while the old native image request remains pending', { timeout: 1000 }, async () => {
  const pending = deferred();
  const harness = createDownload({ plans: [() => pending.promise] });
  const oldWork = harness.start();
  await settleMicrotasks();
  harness.pause({ destroy: true, anotherPage: true });
  await assert.rejects(oldWork, /已取消/);
  harness.removeAndReadd();
  await harness.page.downloadPageWithRetry(harness.task, pageUrl, 0, 6);
  assert.equal(harness.requestCalls.length, 2);
  assert.deepEqual(Array.from(harness.files.get(targetPath)), Array.from(imageBytes));
  pending.resolve(response({ bytes: Uint8Array.from([8, 8, 8]) }));
  await settleMicrotasks();
  assert.deepEqual(Array.from(harness.files.get(targetPath)), Array.from(imageBytes));
  assert.equal(harness.operations.filter((operation) => operation.kind === 'rename').length, 1);
});

const originalEntry = 'https://e-hentai.org/fullimg.php?gid=123&page=1&key=original-key';
const originalPage = (overrides = {}) => ({
  pageUrl, imageUrl: 'https://image.example/resampled.jpg', originImageUrl: originalEntry,
  skipHathKey: 'skip-key', ...overrides
});
const imageCalls = (harness) => harness.requestCalls.filter((call) => call.options.expectDataType === 'ARRAY_BUFFER');
const originalHttpCalls = (harness) => harness.requestCalls.filter((call) => call.options.expectDataType === 'STRING');

test('explicit original selection overrides a compressed preference and downloads the resolved URL with its extension', async () => {
  const resolvedUrl = 'https://cdn.example/full-resolution.png?token=source';
  const harness = createDownload({
    taskOverrides: { imageQuality: 'original' }, globalOriginal: false,
    metadata: () => originalPage(),
    originalPlans: [{ responseCode: 302, result: '', header: { Location: resolvedUrl } }]
  });
  const result = await harness.page.downloadPageWithRetry(harness.task, pageUrl, 3, 4);
  assert.equal(harness.metadataCalls.length, 1);
  assert.equal(harness.originalCalls.length, 1);
  assert.equal(harness.originalCalls[0].site, 'e');
  assert.equal(harness.originalCalls[0].page.originImageUrl, originalEntry);
  assert.equal(originalHttpCalls(harness)[0].url, `${originalEntry}&nl=skip-key`);
  assert.equal(originalHttpCalls(harness)[0].options.maxRedirects, 0);
  assert.equal(imageCalls(harness)[0].url, resolvedUrl);
  assert.equal(imageCalls(harness)[0].options.header.Referer, pageUrl);
  assert.equal(result.sourceUrl, resolvedUrl);
  assert.equal(result.path, '/public/Download/EhViewer/e-123/00000004.png');
  assert.deepEqual(Array.from(harness.files.get(result.path)), Array.from(imageBytes));
  assert.equal(harness.files.has(targetPath), false, 'Do not reuse the display-image extension for an original PNG');
});

test('explicit compressed selection overrides an original preference and does not request the original entry', async () => {
  const harness = createDownload({
    taskOverrides: { imageQuality: 'compressed' }, globalOriginal: true,
    metadata: () => originalPage()
  });
  const result = await harness.start();
  assert.equal(harness.originalCalls.length, 0);
  assert.equal(originalHttpCalls(harness).length, 0);
  assert.equal(imageCalls(harness).length, 1);
  assert.equal(result.sourceUrl, 'https://image.example/resampled.jpg');
  assert.equal(imageCalls(harness)[0].options.header.Referer, pageUrl);
});

test('a task without a selected quality never starts an image request or reads global quality', async () => {
  for (const imageQuality of [undefined, '']) {
    const harness = createDownload({
      taskOverrides: { imageQuality }, globalOriginal: true,
      metadata: () => originalPage()
    });
    await assert.rejects(harness.start(), /请先选择下载画质/);
    assert.equal(harness.metadataCalls.length, 0);
    assert.equal(harness.originalCalls.length, 0);
    assert.equal(imageCalls(harness).length, 0);
    assertNoCommit(harness);
  }
});

test('an original task with no original entry uses the page image as the best available version', async () => {
  const bestUrl = 'https://image.example/already-original.gif?key=page';
  const harness = createDownload({
    taskOverrides: { imageQuality: 'original' }, globalOriginal: false,
    metadata: () => originalPage({ originImageUrl: '', imageUrl: bestUrl })
  });
  const result = await harness.page.downloadPageWithRetry(harness.task, pageUrl, 2, 4);
  assert.equal(harness.originalCalls.length, 0);
  assert.equal(originalHttpCalls(harness).length, 0);
  assert.equal(imageCalls(harness)[0].url, bestUrl);
  assert.equal(result.path, '/public/Download/EhViewer/e-123/00000003.gif');
  assert.equal(result.sourceUrl, bestUrl);
  assert.equal(harness.originalReceipts.length, 1);
});

test('the modern fullimg route reaches the original request and records the committed page', async () => {
  const entry = 'https://e-hentai.org/fullimg/123/1/key/original.png';
  const harness = createDownload({ taskOverrides: { imageQuality: 'original', token: 'token', title: 'Gallery' },
    metadata: () => originalPage({ originImageUrl: entry }), oldPage: imageBytes });
  const result = await harness.start();
  assert.equal(originalHttpCalls(harness)[0].url, `${entry}?nl=skip-key`);
  assert.equal(imageCalls(harness)[0].url, 'https://image.example/original.png');
  assert.equal(harness.originalReceipts.length, 1);
  assert.equal(harness.originalReceipts[0].pageIndex, 0);
  assert.equal(harness.originalReceipts[0].result.path, result.path);
  assert.equal(harness.originalReceipts[0].identity.token, 'token');
  assert.equal(harness.files.has(targetPath), false, 'Remove the old JPG only after the new PNG has its receipt');
  assert.ok(harness.files.has(result.path));
});

test('a smaller returned image cannot replace an original with declared larger dimensions', async () => {
  const harness = createDownload({ taskOverrides: { imageQuality: 'original' }, oldPage: imageBytes,
    metadata: () => originalPage({ originalWidth: 4893, originalHeight: 3360 }),
    imageInfo: { width: 1280, height: 879 } });
  await assert.rejects(harness.start(), /原图尺寸不匹配/);
  assert.equal(harness.originalReceipts.length, 0);
  assert.equal(harness.imageInspections.length, harness.retryLimit + 1);
  assert.ok(harness.imageInspections.every((inspection) => inspection.released));
  assert.deepEqual(Array.from(harness.files.get(targetPath)), Array.from(imageBytes));
  assertNoCommit(harness);
});

test('a matching original is inspected and released before committing its file and receipt', async () => {
  const harness = createDownload({ taskOverrides: { imageQuality: 'original' },
    metadata: () => originalPage({ originalWidth: 4893, originalHeight: 3360 }),
    imageInfo: { width: 4893, height: 3360 } });
  const result = await harness.start();
  assert.equal(harness.imageInspections.length, 1);
  assert.equal(harness.imageInspections[0].released, true);
  assert.equal(harness.originalReceipts[0].result.path, result.path);
  assert.deepEqual(Array.from(new Uint8Array(harness.imageInspections[0].data)), Array.from(imageBytes));
});

test('original bytes remain downloadable when the platform decoder or its cleanup fails', async () => {
  for (const options of [
    { imageInfo: new Error('Image format not supported') },
    { imageInfo: { width: 4893, height: 3360 }, imageReleaseError: new Error('Decoder release failed') }
  ]) {
    const harness = createDownload({ taskOverrides: { imageQuality: 'original' },
      metadata: () => originalPage({ originalWidth: 4893, originalHeight: 3360 }), ...options });
    const result = await harness.start();
    assert.equal(harness.imageInspections[0].released, true);
    assert.equal(harness.originalReceipts[0].result.path, result.path);
    assert.deepEqual(Array.from(harness.files.get(result.path)), Array.from(imageBytes));
  }
});

test('a failed original receipt leaves the older image intact and does not report the page as successful', async () => {
  const harness = createDownload({ taskOverrides: { imageQuality: 'original' }, oldPage: imageBytes,
    metadata: () => originalPage(), originalReceiptResult: false });
  await assert.rejects(harness.start(), /无法保存原图校验记录/);
  assert.equal(harness.originalReceipts.length, harness.retryLimit + 1);
  assert.deepEqual(Array.from(harness.files.get(targetPath)), Array.from(imageBytes));
  assert.equal(harness.operations.some((operation) => operation.kind === 'unlink' && operation.path === targetPath), false);
});

test('original login or quota failures retry the same page and never fall back to the compressed image', async () => {
  const retryPageUrl = 'https://gallery.example/s/0123456789/123-8';
  for (const failure of [
    { responseCode: 200, result: '<html>Login required</html>', header: {} },
    { responseCode: 403, result: 'Insufficient GP', header: {} }
  ]) {
    const harness = createDownload({
      taskOverrides: { imageQuality: 'original' },
      metadata: () => originalPage({ pageUrl: retryPageUrl }),
      originalPlans: Array.from({ length: 8 }, () => failure)
    });
    await assert.rejects(harness.page.downloadPageWithRetry(harness.task, retryPageUrl, 7, 4), /登录状态或原图额度/);
    assert.equal(harness.metadataCalls.length, harness.retryLimit + 1);
    assert.equal(harness.originalCalls.length, harness.retryLimit + 1);
    assert.ok(harness.metadataCalls.every((call) => call.url === retryPageUrl));
    assert.equal(imageCalls(harness).length, 0);
    assert.equal(harness.operations.some((operation) => operation.kind === 'open'), false);
    assertNoCommit(harness);
  }
});

test('a transient original-entry failure refetches and commits the original at the correct page index', async () => {
  const retryPageUrl = 'https://gallery.example/s/0123456789/123-8';
  const resolvedUrl = 'https://cdn.example/original.webp?token=retry';
  const harness = createDownload({
    taskOverrides: { imageQuality: 'original' },
    metadata: () => originalPage({ pageUrl: retryPageUrl }),
    originalPlans: [
      new Error('Temporary original request failure'),
      { responseCode: 302, result: '', header: { Location: resolvedUrl } }
    ]
  });
  const result = await harness.page.downloadPageWithRetry(harness.task, retryPageUrl, 7, 4);
  assert.equal(harness.metadataCalls.length, 2);
  assert.equal(harness.originalCalls.length, 2);
  assert.equal(imageCalls(harness).length, 1);
  assert.equal(imageCalls(harness)[0].url, resolvedUrl);
  assert.equal(imageCalls(harness)[0].options.header.Referer, retryPageUrl);
  assert.equal(result.path, '/public/Download/EhViewer/e-123/00000008.webp');
});

test('cross-view cancellation immediately releases a pending original resolver without dispatching binary data', { timeout: 1000 }, async () => {
  const pending = deferred();
  const harness = createDownload({
    taskOverrides: { imageQuality: 'original' },
    metadata: () => originalPage(), originalPlans: [() => pending.promise]
  });
  const work = harness.start();
  await settleMicrotasks();
  assert.equal(originalHttpCalls(harness).length, 1);
  assert.equal(harness.activeRequests.get(harness.key).length, 1);
  harness.pause({ destroy: true, anotherPage: true });
  await assert.rejects(work, /已取消/);
  assert.equal(harness.originalCalls.length, 1, 'Cancellation must not start another original attempt');
  assert.equal(harness.metadataCalls.length, 1);
  assert.equal(harness.activeRequests.has(harness.key), false);
  assert.equal(harness.cancelSignals.size, 0);
  assert.equal(imageCalls(harness).length, 0);
  pending.resolve({ responseCode: 302, result: '', header: { Location: 'https://cdn.example/late.png' } });
  await settleMicrotasks();
  assert.equal(imageCalls(harness).length, 0);
  assertNoCommit(harness);
});

test('binary image requests allow 100 MiB and derive Host through the HTTP client rather than an application header', async () => {
  const harness = createDownload({
    taskOverrides: { imageQuality: 'original' }, metadata: () => originalPage()
  });
  await harness.start();
  const binary = imageCalls(harness)[0];
  assert.equal(binary.options.maxLimit, 100 * 1024 * 1024);
  assert.equal(Object.keys(binary.options.header).some((name) => name.toLowerCase() === 'host'), false);
  assert.equal(binary.options.usingCache, false);
});

test('CDN binary requests use only cookies matched to that target and do not merge gallery login cookies', async () => {
  const cdnUrl = 'https://cdn.example/original.png?key=source';
  for (const targetCookie of ['', 'cdn_access=target']) {
    const harness = createDownload({
      taskOverrides: { imageQuality: 'compressed' },
      metadata: () => originalPage({ imageUrl: cdnUrl }),
      cookies: {
        'https://forums.e-hentai.org/': 'ipb_pass_hash=forum-secret',
        'https://e-hentai.org/': 'ipb_member_id=gallery-secret; session=e',
        'https://exhentai.org/': 'igneous=ex-secret',
        [cdnUrl]: targetCookie
      }
    });
    await harness.start();
    assert.deepEqual(harness.cookieSources, [cdnUrl]);
    const headers = imageCalls(harness)[0].options.header;
    assert.equal(headers.Cookie, targetCookie || undefined);
    assert.equal(headers.Referer, pageUrl);
  }
});

for (const invalid of [
  { name: 'plain-text quota error', contentType: 'text/plain; charset=UTF-8', body: 'Insufficient GP to download the original image' },
  { name: 'JSON error', contentType: 'application/json; charset=UTF-8', body: '{"error":"Original image quota exceeded"}' }
]) {
  test(`an original CDN ${invalid.name} exhausts retries without replacing the previous complete image`, async () => {
    const originalUrl = 'https://cdn.example/original.jpg';
    const failure = response({
      bytes: Uint8Array.from(Buffer.from(invalid.body)), headers: { 'Content-Type': invalid.contentType }
    });
    const harness = createDownload({
      taskOverrides: { imageQuality: 'original' }, metadata: () => originalPage(), oldPage: [9, 8, 7],
      originalPlans: Array.from({ length: 8 }, () => ({
        responseCode: 302, result: '', header: { Location: originalUrl }
      })),
      plans: Array.from({ length: 8 }, () => failure)
    });
    await assert.rejects(harness.start(), /图片响应为错误文本/);
    assert.equal(harness.metadataCalls.length, harness.retryLimit + 1);
    assert.equal(harness.originalCalls.length, harness.retryLimit + 1);
    assert.equal(imageCalls(harness).length, harness.retryLimit + 1);
    assert.ok(imageCalls(harness).every((call) => call.url === originalUrl));
    assert.equal(harness.operations.some((operation) => operation.kind === 'open'), false);
    assert.deepEqual(Array.from(harness.files.get(targetPath)), [9, 8, 7]);
    assert.equal(harness.activeRequests.has(harness.key), false);
    assert.equal(harness.cancelSignals.size, 0);
    assertNoCommit(harness);
  });
}
