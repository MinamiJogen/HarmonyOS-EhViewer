import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';

// Run the real native text request and metadata wrapper methods. Only HarmonyOS
// HTTP, cookie, and parser adapters are mocked; these are lifecycle regressions,
// not device HTTP timing or ArkUI validation.
// Node.js 22.13+: node --test tests/native-download-requests.test.mjs
const source = readFileSync(new URL('../entry/src/main/ets/ehviewer/EhNative.ets', import.meta.url), 'utf8');

function productionMethod(name) {
  const start = source.search(new RegExp(`\\n  (?:private|public) static (?:async )?${name}\\(`));
  assert.notEqual(start, -1, `Missing production method: ${name}`);
  const tail = source.slice(start + 1);
  const end = tail.indexOf('\n  }');
  assert.notEqual(end, -1, `Missing end of production method: ${name}`);
  return tail.slice(0, end + 4);
}

function productionFunction(name) {
  const start = source.indexOf(`function ${name}(`);
  assert.notEqual(start, -1, `Missing production function: ${name}`);
  const tail = source.slice(start);
  const end = tail.indexOf('\n}');
  assert.notEqual(end, -1, `Missing end of production function: ${name}`);
  return tail.slice(0, end + 2);
}

const constantsStart = source.indexOf('  private static readonly REQUEST_USER_AGENT:');
const constantsEnd = source.indexOf('\n', source.indexOf('  private static readonly REQUEST_ACCEPT_LANGUAGE:', constantsStart));
assert.ok(constantsStart >= 0 && constantsEnd > constantsStart, 'Missing native request headers');
const harnessSource = stripTypeScriptTypes(`(() => {
  const DOMAIN = 0x0000;
  const LOG_TAG = 'EhNative';
  ${productionFunction('isMeaningfulErrorMessage')}
  ${productionFunction('nativeRequestErrorMessage')}
  class NativeEhClient {
    ${source.slice(constantsStart, constantsEnd)}
    ${['requestText', 'fetchGalleryDetail', 'fetchGalleryPreviewPage', 'fetchReaderPage'].map(productionMethod).join('\n')}
  }
  return NativeEhClient;
})()`);

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((onResolve, onReject) => { resolve = onResolve; reject = onReject; });
  return { promise, resolve, reject };
}

function createNative({ rejectOnDestroy = true, throwOnRepeatedDestroy = true } = {}) {
  const requests = [];
  const events = [];
  const errors = [];
  const parses = [];
  const cookies = [];
  const proxy = { host: '127.0.0.1', port: 1080 };
  const client = vm.runInNewContext(harnessSource, {
    http: {
      RequestMethod: { GET: 'GET', POST: 'POST' },
      HttpDataType: { STRING: 'string' },
      createHttp() {
        const pending = deferred();
        const request = {
          pending,
          calls: [],
          destroyCount: 0,
          request(url, options) {
            events.push('request');
            this.calls.push({ url, options });
            return pending.promise;
          },
          destroy() {
            events.push('destroy');
            this.destroyCount++;
            if (this.destroyCount > 1 && throwOnRepeatedDestroy) {
              throw new Error('HTTP object already destroyed');
            }
            if (rejectOnDestroy && this.calls.length > 0) {
              pending.reject(new Error('HTTP request destroyed'));
            }
          }
        };
        requests.push(request);
        return request;
      }
    },
    AppNetworkProxy: { requestProxy: () => proxy },
    EhUrl: { referer: (site) => `https://${site}.example/`, origin: (site) => `https://${site}.example` },
    hilog: { error: (...args) => errors.push(args) },
    createDetailFromSummary(summary) {
      parses.push({ kind: 'detail-summary', summary });
      return { ...summary };
    },
    mergeDetailHtml(detail, html, site) {
      parses.push({ kind: 'detail-html', html, site });
      return { ...detail, html, site };
    },
    buildPreviewPageUrl: (url, pageIndex) => `${url}?p=${pageIndex}`,
    parsePreviewItems(html, site) {
      parses.push({ kind: 'preview-items', html, site });
      return [{ pageUrl: 'https://e.example/s/preview' }];
    },
    parsePreviewPageCount(html) {
      parses.push({ kind: 'preview-count', html });
      return 4;
    },
    readerPageUrlWithSkipHathKey: (url, key) => key ? `${url}?nl=${key}` : url,
    parseReaderPage(html, pageUrl) {
      parses.push({ kind: 'reader', html, pageUrl });
      return { html, pageUrl };
    }
  });
  client.hostFromUrl = (url) => new URL(url).hostname;
  client.readCookie = () => 'session=native';
  client.captureResponseCookies = (url, response) => cookies.push({ url, response });

  function createControl({ cancelOnStart = false, cancelOnFinish = false, withSignal = false } = {}) {
    let cancelled = false;
    const cancelSignal = deferred();
    const active = new Set();
    const started = [];
    const finished = [];
    const control = {
      isCancelled: () => cancelled,
      onStart(request) {
        events.push('start');
        started.push(request);
        active.add(request);
        if (cancelOnStart) cancel();
      },
      onFinish(request) {
        events.push('finish');
        finished.push(request);
        active.delete(request);
        if (cancelOnFinish) cancelled = true;
      }
    };
    if (withSignal) control.cancelled = cancelSignal.promise;
    function cancel() {
      cancelled = true;
      cancelSignal.resolve();
      for (const request of active) request.destroy();
    }
    return { control, cancel, active, started, finished };
  }
  return { client, requests, events, errors, parses, cookies, proxy, createControl };
}

const summary = { gid: 42, token: 'token', detailUrl: 'https://e.example/g/42/token/' };
const metadataRequests = [
  {
    name: 'gallery detail',
    invoke: (native, control) => native.client.fetchGalleryDetail('e', summary, control),
    url: summary.detailUrl,
    referer: 'https://e.example/'
  },
  {
    name: 'gallery preview',
    invoke: (native, control) => native.client.fetchGalleryPreviewPage('e', summary.detailUrl, 2, control),
    url: `${summary.detailUrl}?p=2`,
    referer: summary.detailUrl
  },
  {
    name: 'reader HTML',
    invoke: (native, control) => native.client.fetchReaderPage('e', 'https://e.example/s/page', 'skip-key', control),
    url: 'https://e.example/s/page?nl=skip-key',
    referer: 'https://e.example/s/page'
  }
];

test('cancellation before creation skips HTTP registration and ordinary error logging', async () => {
  const native = createNative();
  const tracker = native.createControl();
  tracker.cancel();
  await assert.rejects(native.client.requestText(summary.detailUrl, 'e', 'GET', '', undefined, tracker.control),
    { message: '请求已取消' });
  assert.equal(native.requests.length, 0);
  assert.equal(tracker.started.length, 0);
  assert.equal(tracker.finished.length, 0);
  assert.equal(native.errors.length, 0);
});

test('cancellation while registering prevents starting HTTP and tolerates repeat destroy', async () => {
  const native = createNative();
  const tracker = native.createControl({ cancelOnStart: true });
  await assert.rejects(native.client.requestText(summary.detailUrl, 'e', 'GET', '', undefined, tracker.control),
    { message: '请求已取消' });
  assert.equal(native.requests.length, 1);
  assert.equal(native.requests[0].calls.length, 0);
  assert.equal(native.requests[0].destroyCount, 2);
  assert.equal(tracker.finished.length, 1);
  assert.equal(tracker.active.size, 0);
  assert.equal(native.errors.length, 0);
});

for (const metadata of metadataRequests) {
  test(`${metadata.name}: pending metadata remains registered until cancellation settles`, async () => {
    const native = createNative();
    const tracker = native.createControl();
    const task = metadata.invoke(native, tracker.control);
    const rejection = assert.rejects(task, { message: '请求已取消' });
    assert.equal(native.requests.length, 1);
    assert.equal(tracker.started.length, 1);
    assert.equal(tracker.finished.length, 0);
    assert.equal(tracker.active.size, 1);
    const request = native.requests[0];
    assert.equal(request.calls[0].url, metadata.url);
    assert.equal(request.calls[0].options.header.Referer, metadata.referer);
    assert.equal(request.calls[0].options.extraData, undefined);
    tracker.cancel();
    assert.equal(tracker.finished.length, 0, 'Cancellation must not deregister a still-pending request');
    await rejection;
    assert.equal(tracker.finished.length, 1);
    assert.equal(tracker.active.size, 0);
    assert.equal(request.destroyCount, 2, 'Finally cleanup survives an already-destroyed request');
    assert.equal(native.parses.length, 0);
    assert.equal(native.cookies.length, 0);
    assert.equal(native.errors.length, 0);
    assert.deepEqual(native.events, ['start', 'request', 'destroy', 'finish', 'destroy']);
  });

  test(`${metadata.name}: a response arriving after cancellation never reaches cookie capture or parser`, async () => {
    const native = createNative({ rejectOnDestroy: false });
    const tracker = native.createControl();
    const task = metadata.invoke(native, tracker.control);
    const rejection = assert.rejects(task, { message: '请求已取消' });
    tracker.cancel();
    assert.equal(tracker.active.size, 1);
    assert.equal(tracker.finished.length, 0);
    native.requests[0].pending.resolve({ responseCode: 200, result: 'LATE HTML' });
    await rejection;
    assert.equal(tracker.active.size, 0);
    assert.equal(tracker.finished.length, 1);
    assert.equal(native.parses.length, 0);
    assert.equal(native.cookies.length, 0);
    assert.equal(native.errors.length, 0);
  });

  test(`${metadata.name}: cancellation between request completion and wrapper parsing still aborts`, async () => {
    const native = createNative();
    const tracker = native.createControl({ cancelOnFinish: true });
    const task = metadata.invoke(native, tracker.control);
    native.requests[0].pending.resolve({ responseCode: 200, result: 'HTML' });
    await assert.rejects(task, { message: '请求已取消' });
    assert.equal(tracker.finished.length, 1);
    assert.equal(native.parses.length, 0);
    assert.equal(native.errors.length, 0);
  });

  test(`${metadata.name}: legacy callers without a control still resolve and parse HTML`, async () => {
    const native = createNative();
    const task = metadata.invoke(native, undefined);
    native.requests[0].pending.resolve({ responseCode: 200, result: 'NORMAL HTML' });
    const result = await task;
    assert.ok(result);
    assert.ok(native.parses.length > 0);
    assert.equal(native.cookies.length, 1);
    assert.equal(native.requests[0].destroyCount, 1);
    assert.equal(native.requests[0].calls[0].url, metadata.url);
    assert.equal(native.requests[0].calls[0].options.header.Referer, metadata.referer);
    assert.equal(native.errors.length, 0);
  });
}

test('normal controlled request deregisters only after success and preserves native request options', async () => {
  const native = createNative();
  const tracker = native.createControl();
  const task = native.client.requestText(summary.detailUrl, 'e', 'POST', 'https://e.example/form', '{"key":1}', tracker.control);
  const request = native.requests[0];
  assert.equal(tracker.active.size, 1);
  assert.equal(tracker.finished.length, 0);
  const options = request.calls[0].options;
  assert.equal(options.method, 'POST');
  assert.equal(options.expectDataType, 'string');
  assert.equal(options.usingCache, false);
  assert.equal(options.usingProxy, native.proxy);
  assert.equal(options.readTimeout, 20000);
  assert.equal(options.connectTimeout, 12000);
  assert.equal(options.extraData, '{"key":1}');
  assert.equal(options.header.Host, 'e.example');
  assert.equal(options.header.Cookie, 'session=native');
  assert.equal(options.header.Origin, 'https://e.example');
  assert.equal(options.header.Referer, 'https://e.example/form');
  assert.equal(options.header['Content-Type'], 'application/json; charset=UTF-8');
  assert.ok(options.header.Accept.length > 0);
  assert.ok(options.header['Accept-Language'].length > 0);
  assert.ok(options.header['User-Agent'].length > 0);
  request.pending.resolve({ responseCode: 200, result: 'OK' });
  assert.equal(await task, 'OK');
  assert.equal(tracker.finished.length, 1);
  assert.equal(tracker.active.size, 0);
  assert.equal(native.cookies.length, 1);
  assert.equal(request.destroyCount, 1);
  assert.deepEqual(native.events, ['start', 'request', 'finish', 'destroy']);
});

test('legacy body argument remains valid and ordinary HTTP failures log and clean up', async () => {
  const native = createNative();
  const task = native.client.requestText(summary.detailUrl, 'e', 'POST', '', 'legacy body');
  const rejection = assert.rejects(task, { message: 'HTTP 503' });
  assert.equal(native.requests[0].calls[0].options.extraData, 'legacy body');
  native.requests[0].pending.resolve({ responseCode: 503, result: 'Unavailable' });
  await rejection;
  assert.equal(native.errors.length, 1);
  assert.equal(native.errors[0].at(-1), 'HTTP 503');
  assert.equal(native.requests[0].destroyCount, 1);
});

test('a genuine network failure with a live control logs normally and deregisters once', async () => {
  const native = createNative();
  const tracker = native.createControl();
  const task = native.client.requestText(summary.detailUrl, 'e', 'GET', '', undefined, tracker.control);
  const rejection = assert.rejects(task, { message: 'Connection refused' });
  native.requests[0].pending.reject(new Error('Connection refused'));
  await rejection;
  assert.equal(native.errors.length, 1);
  assert.equal(native.errors[0].at(-1), 'Connection refused');
  assert.equal(tracker.finished.length, 1);
  assert.equal(tracker.active.size, 0);
  assert.equal(native.requests[0].destroyCount, 1);
});

test('independent cancellation settles and deregisters even when native HTTP never settles', { timeout: 1000 }, async () => {
  const native = createNative({ rejectOnDestroy: false });
  const tracker = native.createControl({ withSignal: true });
  const task = native.client.fetchGalleryDetail('e', summary, tracker.control);
  const rejection = assert.rejects(task, { message: '请求已取消' });
  assert.equal(tracker.active.size, 1);
  assert.equal(tracker.finished.length, 0);
  tracker.cancel();
  await rejection;
  assert.equal(tracker.finished.length, 1);
  assert.equal(tracker.active.size, 0);
  assert.equal(native.requests[0].destroyCount, 2);
  assert.equal(native.parses.length, 0);
  assert.equal(native.cookies.length, 0);
  assert.equal(native.errors.length, 0);
  // Deliberately leave the HTTP promise pending: the JS task already completed.
});

test('a late native success after signal cancellation never parses or finishes twice', { timeout: 1000 }, async () => {
  const native = createNative({ rejectOnDestroy: false });
  const tracker = native.createControl({ withSignal: true });
  const task = native.client.fetchGalleryPreviewPage('e', summary.detailUrl, 2, tracker.control);
  const rejection = assert.rejects(task, { message: '请求已取消' });
  tracker.cancel();
  await rejection;
  native.requests[0].pending.resolve({ responseCode: 200, result: 'LATE HTML' });
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(tracker.finished.length, 1);
  assert.equal(tracker.active.size, 0);
  assert.equal(native.parses.length, 0);
  assert.equal(native.cookies.length, 0);
  assert.equal(native.errors.length, 0);
});

test('a late native rejection after signal cancellation is handled and does not log a network failure', { timeout: 1000 }, async () => {
  const native = createNative({ rejectOnDestroy: false });
  const tracker = native.createControl({ withSignal: true });
  const task = native.client.fetchReaderPage('e', 'https://e.example/s/page', '', tracker.control);
  const rejection = assert.rejects(task, { message: '请求已取消' });
  const unhandled = [];
  const onUnhandled = (error) => unhandled.push(error);
  process.on('unhandledRejection', onUnhandled);
  try {
    tracker.cancel();
    await rejection;
    native.requests[0].pending.reject(new Error('Late native failure'));
    await new Promise((resolve) => setImmediate(resolve));
    assert.equal(unhandled.length, 0);
    assert.equal(tracker.finished.length, 1);
    assert.equal(tracker.active.size, 0);
    assert.equal(native.parses.length, 0);
    assert.equal(native.cookies.length, 0);
    assert.equal(native.errors.length, 0);
  } finally {
    process.removeListener('unhandledRejection', onUnhandled);
  }
});
