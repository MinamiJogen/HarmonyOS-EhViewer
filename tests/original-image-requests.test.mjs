import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';

// Run the real reader parser, original-image resolver, and native cookie helpers.
// Node URL stands in for @ohos.url; HTTP and WebCookieManager are controlled
// platform boundaries. This does not validate live E/EX access or GP balances.
// Node.js 22.13+: node --test tests/original-image-requests.test.mjs
const source = readFileSync(new URL('../entry/src/main/ets/ehviewer/EhNative.ets', import.meta.url), 'utf8');
const androidHtml = readFileSync(new URL('../EhviewerAndroid/app/src/test/resources/com/hippo/ehviewer/client/parser/GalleryPageParserTest.html', import.meta.url), 'utf8');
const pageUrl = 'https://e-hentai.org/s/49c9e58c17/1363978-10';
const originUrl = 'https://e-hentai.org/fullimg.php?gid=1363978&page=10&key=qt2hwrx98a4';
const originAnchor = '<a href="https://e-hentai.org/fullimg.php?gid=1363978&amp;page=10&amp;key=qt2hwrx98a4">';
// The current upstream Android parser recognizes /fullimg/ rather than the
// legacy PHP route: https://github.com/FooIbar/EhViewer/blob/main/app/src/main/kotlin/com/hippo/ehviewer/client/parser/GalleryPageParser.kt
const modernOriginUrl = 'https://e-hentai.org/fullimg/3196787/1/bnhsuf1acar/121594728_p00.jpg';

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

const patterns = source.split('\n').filter((line) =>
  /^const (?:IMAGE_URL_PATTERN|ORIGIN_IMAGE_URL_PATTERN|SKIP_HATH_KEY_PATTERN|PAGE_URL_PATTERN):/.test(line)).join('\n');
const nativeStart = source.indexOf('export class NativeEhClient {') + 'export class NativeEhClient {'.length;
const nativeHeadersEnd = source.indexOf('\n  private static async requestText(', nativeStart);
assert.ok(nativeStart >= 'export class NativeEhClient {'.length && nativeHeadersEnd > nativeStart,
  'Missing production native header/cookie methods');
const ehDomains = source.split('\n').filter((line) => /^  static readonly DOMAIN_(?:E|EX|FORUMS):/.test(line)).join('\n');
const harnessSource = stripTypeScriptTypes(`(() => {
  const DOMAIN = 0x0000;
  const LOG_TAG = 'EhNative';
  ${patterns}
  ${['decodeHtml', 'parsePageIndexFromUrl', 'readerPageUrlWithSkipHathKey', 'parseReaderPage',
    'isMeaningfulErrorMessage', 'nativeRequestErrorMessage'].map(productionFunction).join('\n')}
  class EhUrl { ${ehDomains} }
  class NativeEhClient {
    ${source.slice(nativeStart, nativeHeadersEnd)}
    ${productionMethod('fetchOriginalImageUrl')}
  }
  return { client: NativeEhClient, parse: parseReaderPage, domains: EhUrl };
})()`);

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((accept, decline) => { resolve = accept; reject = decline; });
  return { promise, resolve, reject };
}

function response({ code = 302, location = 'https://images.example/original.png', headers = {}, cookies = '' } = {}) {
  return { responseCode: code, result: '', cookies,
    header: { ...(location == null ? {} : { Location: location }), ...headers } };
}

function createNative({ rejectOnDestroy = false } = {}) {
  const requests = [];
  const cookieReads = [];
  const cookieWrites = [];
  const cookieStore = new Map();
  const errors = [];
  const timers = new Set();
  const timerDelays = [];
  let cookieSaves = 0;
  const proxy = { host: '127.0.0.1', port: 1080 };
  const native = vm.runInNewContext(harnessSource, {
    setTimeout(callback, delay) {
      timerDelays.push(delay);
      const timer = setTimeout(() => { timers.delete(timer); callback(); }, delay);
      timers.add(timer);
      return timer;
    },
    clearTimeout(timer) { timers.delete(timer); clearTimeout(timer); },
    url: { URL },
    GallerySite: { E: 'e', EX: 'ex' },
    AppNetworkProxy: { requestProxy: () => proxy },
    hilog: { error: (...args) => errors.push(args), warn() {}, info() {} },
    webview: { WebCookieManager: {
      fetchCookieSync(url) {
        cookieReads.push(url);
        return cookieStore.get(url) ?? cookieStore.get(new URL(url).origin) ?? '';
      },
      configCookieSync(url, value) { cookieWrites.push({ url, value }); },
      saveCookieSync() { cookieSaves++; }
    } },
    http: {
      RequestMethod: { GET: 'GET' }, HttpDataType: { STRING: 'string' },
      createHttp() {
        const pending = deferred();
        const request = {
          pending, calls: [], destroyCount: 0, listeners: new Map(), listenerEvents: [],
          on(type, callback) {
            this.listenerEvents.push({ kind: 'on', type, callback });
            this.listeners.set(type, callback);
          },
          off(type, callback) {
            this.listenerEvents.push({ kind: 'off', type, callback });
            if (this.listeners.get(type) === callback) this.listeners.delete(type);
          },
          emitHeaders(header) { this.listeners.get('headersReceive')?.(header); },
          request(url, options) { this.calls.push({ url, options }); return pending.promise; },
          destroy() {
            this.destroyCount++;
            if (rejectOnDestroy && this.calls.length > 0) pending.reject(new Error('Native HTTP destroyed'));
          }
        };
        requests.push(request);
        return request;
      }
    }
  });

  function createControl({ withSignal = true, cancelOnStart = false } = {}) {
    let cancelled = false;
    const signal = deferred();
    const active = new Set();
    const started = [];
    const finished = [];
    const control = {
      isCancelled: () => cancelled,
      onStart(request) { started.push(request); active.add(request); if (cancelOnStart) cancel(); },
      onFinish(request) { finished.push(request); active.delete(request); }
    };
    if (withSignal) control.cancelled = signal.promise;
    function cancel() {
      cancelled = true;
      signal.resolve();
      for (const request of active) request.destroy();
    }
    return { control, cancel, started, finished, active };
  }
  return { ...native, requests, createControl, cookieReads, cookieWrites, cookieStore,
    cookieSaves: () => cookieSaves, errors, proxy, timers, timerDelays };
}

test('the real Android HTML distinguishes the display image from the decoded full-size original link', () => {
  const native = createNative();
  const page = native.parse(androidHtml, pageUrl);
  assert.equal(page.pageIndex, 9);
  assert.equal(page.pageLabel, '10');
  assert.ok(page.imageUrl.includes('1280-879-jpg/'));
  assert.ok(page.imageUrl.includes('xres=1280/10.jpg'));
  assert.equal(page.originImageUrl, originUrl);
  assert.equal(page.skipHathKey, '26664-430636');
  assert.equal(page.originalWidth, 4893);
  assert.equal(page.originalHeight, 3360);
  assert.notEqual(page.imageUrl, page.originImageUrl);
});

test('reader parsing selects the real image by id when an earlier advert also has a styled src', () => {
  const native = createNative();
  const parsed = native.parse('<img src="https://ads.example/small.jpg" style="width:32px">' + androidHtml, pageUrl);
  assert.ok(parsed.imageUrl.includes('xres=1280/10.jpg'));
  assert.equal(parsed.originImageUrl, originUrl);
  assert.equal(parsed.originalWidth, 4893);
});

for (const tag of [
  "<img src='https://images.example/display.jpg' alt='page' id='img' class='reader'>",
  '<img class="reader" style="width:1280px" id="img" src="https://images.example/display.jpg">',
  '<img data-kind="reader" id = "img" src = "https://images.example/display.jpg">'
]) {
  test(`reader image attributes can vary without selecting an advert: ${tag}`, () => {
    const native = createNative();
    const parsed = native.parse(androidHtml.replace(/<img id="img"[^>]*>/, tag), pageUrl);
    assert.equal(parsed.imageUrl, 'https://images.example/display.jpg');
    assert.equal(parsed.originImageUrl, originUrl);
  });
}

test('original dimensions preserve the source size with markup, commas, and a multiplication sign', () => {
  const native = createNative();
  const parsed = native.parse(androidHtml.replace('Download original 4893 x 3360',
    'Download original <strong>4,893 × 3,360</strong>'), pageUrl);
  assert.equal(parsed.originalWidth, 4893);
  assert.equal(parsed.originalHeight, 3360);
});

test('reader parsing does not invent original dimensions when the original link contains no size', () => {
  const native = createNative();
  const parsed = native.parse(androidHtml.replace('Download original 4893 x 3360 15.05 MB source',
    'Download original'), pageUrl);
  assert.equal(parsed.originImageUrl, originUrl);
  assert.equal(parsed.originalWidth, undefined);
  assert.equal(parsed.originalHeight, undefined);
});

test('data-id and data-src do not impersonate the reader image or its real src', () => {
  const native = createNative();
  const html = '<img data-id="img" src="https://ads.example/tiny.jpg" style="width:32px">' +
    androidHtml.replace('<img id="img" src="', '<img id="img" data-src="https://images.example/preview.jpg" src="');
  const parsed = native.parse(html, pageUrl);
  assert.ok(parsed.imageUrl.includes('xres=1280/10.jpg'));
});

for (const [site, anchor, expected] of [
  ['e', `<a href="${modernOriginUrl}">`, modernOriginUrl],
  ['e', '<a class="original" href="/fullimg/3196787/1/bnhsuf1acar/121594728_p00.jpg">', modernOriginUrl],
  ['ex', `<a rel='nofollow' href='${modernOriginUrl.replace('e-hentai.org', 'exhentai.org')}'>`,
    modernOriginUrl.replace('e-hentai.org', 'exhentai.org')]
]) {
  test(`current ${site} /fullimg/ original links are parsed and resolved instead of downloading the resampled page`, async () => {
    const native = createNative();
    const readerUrl = site === 'ex' ? pageUrl.replace('e-hentai.org', 'exhentai.org') : pageUrl;
    const parsed = native.parse(androidHtml.replace(originAnchor, anchor), readerUrl);
    assert.equal(parsed.originImageUrl, expected);
    assert.equal(parsed.originalWidth, 4893);
    assert.equal(parsed.originalHeight, 3360);
    const resolving = native.client.fetchOriginalImageUrl(site, parsed);
    assert.equal(native.requests.length, 1);
    const call = native.requests[0].calls[0];
    assert.equal(new URL(call.url).pathname, '/fullimg/3196787/1/bnhsuf1acar/121594728_p00.jpg');
    assert.equal(new URL(call.url).searchParams.get('nl'), parsed.skipHathKey);
    assert.equal(call.options.maxRedirects, 0);
    native.requests[0].pending.resolve(response({ location: 'https://images.example/full-resolution.png' }));
    assert.equal(await resolving, 'https://images.example/full-resolution.png');
  });
}

test('an original action with an unsupported entry route cannot silently masquerade as a page without originals', () => {
  const native = createNative();
  const html = androidHtml.replace(originAnchor, '<a href="/new-original-route/1363978/10/source">');
  assert.throws(() => native.parse(html, pageUrl), /原图入口解析失败/);
});

for (const entry of [
  'https://e-hentai.org/fullimg/3196787/1/bnhsuf1acar',
  'https://e-hentai.org/fullimg/3196787/1/bnhsuf1acar/nested/file.png'
]) {
  test(`an authenticated fullimg route is resolved without imposing a made-up path segment count: ${entry}`, async () => {
    const native = createNative();
    const page = native.parse(androidHtml.replace(originAnchor, `<a href="${entry}">`), pageUrl);
    const resolving = native.client.fetchOriginalImageUrl('e', page);
    assert.equal(new URL(native.requests[0].calls[0].url).pathname, new URL(entry).pathname);
    native.requests[0].pending.resolve(response({ location: 'https://images.example/full.png' }));
    assert.equal(await resolving, 'https://images.example/full.png');
  });
}

for (const [name, anchor] of [
  ['attributes before href', '<a class="original" rel="nofollow" href="https://e-hentai.org/fullimg.php?gid=1363978&amp;page=10&amp;key=qt2hwrx98a4" data-kind="source">'],
  ['single-quoted href', "<a class='original' href='https://e-hentai.org/fullimg.php?gid=1363978&amp;page=10&amp;key=qt2hwrx98a4' rel='nofollow'>"],
  ['relative href', '<a href="/fullimg.php?gid=1363978&amp;page=10&amp;key=qt2hwrx98a4" class="original">']
]) {
  test(`the real reader parser retains an original link with ${name}`, () => {
    const native = createNative();
    assert.ok(androidHtml.includes(originAnchor));
    const parsed = native.parse(androidHtml.replace(originAnchor, anchor), pageUrl);
    assert.ok(parsed.originImageUrl.length > 0);
    assert.equal(new URL(parsed.originImageUrl, pageUrl).href, originUrl);
    assert.ok(parsed.imageUrl.includes('xres=1280/10.jpg'));
  });
}

for (const code of [301, 302, 303, 307, 308]) {
  test(`HTTP ${code} resolves the original redirect without following it or falling back to the display image`, async () => {
    const native = createNative();
    const page = native.parse(androidHtml, pageUrl);
    const tracker = native.createControl();
    native.client.configureCookieHeader('ipb_member_id=42; ipb_pass_hash=token');
    const resolving = native.client.fetchOriginalImageUrl('e', page, tracker.control);
    assert.equal(native.requests.length, 1);
    const request = native.requests[0];
    const call = request.calls[0];
    const requested = new URL(call.url);
    assert.equal(requested.origin, 'https://e-hentai.org');
    assert.equal(requested.pathname, '/fullimg.php');
    assert.equal(requested.searchParams.get('nl'), page.skipHathKey);
    assert.equal(call.options.maxRedirects, 0);
    assert.equal(call.options.expectDataType, 'string');
    assert.equal(call.options.method, 'GET');
    assert.equal(call.options.usingCache, false);
    assert.equal(call.options.usingProxy, native.proxy);
    assert.equal(call.options.header.Referer, pageUrl);
    assert.equal(call.options.header['User-Agent'], native.client.DOWNLOAD_USER_AGENT);
    assert.equal(call.options.header.Accept, native.client.DOWNLOAD_ACCEPT);
    assert.equal(call.options.header['Accept-Language'], native.client.DOWNLOAD_ACCEPT_LANGUAGE);
    assert.ok(call.options.header.Cookie.includes('ipb_member_id=42'));
    assert.ok(call.options.header.Cookie.includes('ipb_pass_hash=token'));
    request.pending.resolve(response({ code, cookies: 'session=updated; Path=/; HttpOnly' }));
    assert.equal(await resolving, 'https://images.example/original.png');
    assert.equal(native.requests.length, 1, 'Resolving an entry must not start a second image HTTP request');
    assert.equal(tracker.finished.length, 1);
    assert.equal(tracker.active.size, 0);
    assert.equal(request.destroyCount, 1);
    assert.equal(native.timerDelays.length, 0, 'Already captured Location must not wait for a deadline');
    assert.equal(native.cookieWrites.length, 1);
    assert.equal(native.cookieWrites[0].value, 'session=updated; Path=/; HttpOnly');
    assert.equal(native.cookieSaves(), 1);
  });
}

for (const [name, location, expected] of [
  ['root relative', '/original/image.webp?download=1', 'https://e-hentai.org/original/image.webp?download=1'],
  ['path relative', 'original/image.gif', 'https://e-hentai.org/original/image.gif'],
  ['protocol relative', '//images.example/full.webp', 'https://images.example/full.webp']
]) {
  test(`the original resolver normalizes a ${name} Location against the original entry URL`, async () => {
    const native = createNative();
    const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl));
    native.requests[0].pending.resolve(response({ location }));
    assert.equal(await resolving, expected);
  });
}

for (const [name, headers] of [
  ['NetStack HTTP status line as a key', { 'HTTP/2 302': '', location: 'https://images.example/full.png' }],
  ['status-line value', { 'status-line': 'HTTP/1.1 302 Found', Location: 'https://images.example/full.png' }],
  ['Location alone', { lOcAtIoN: 'https://images.example/full.png' }]
]) {
  test(`maxRedirects=0 curl error 2300047 still resolves the already-received original Location: ${name}`, async () => {
    const native = createNative();
    const tracker = native.createControl();
    const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl), tracker.control);
    const request = native.requests[0];
    assert.equal(request.calls[0].options.maxRedirects, 0);
    assert.ok(request.listeners.has('headersReceive'), 'Register response headers before issuing HTTP');
    request.emitHeaders(headers);
    request.pending.reject({ code: 2300047, message: 'The number of redirections reaches the maximum allowed.' });
    assert.equal(await resolving, 'https://images.example/full.png');
    assert.equal(native.requests.length, 1, 'The resolver must not follow the image redirect itself');
    assert.equal(request.listeners.size, 0);
    assert.equal(request.listenerEvents[0].kind, 'on');
    assert.equal(request.listenerEvents.at(-1).kind, 'off');
    assert.equal(request.listenerEvents[0].callback, request.listenerEvents.at(-1).callback);
    assert.equal(request.destroyCount, 1);
    assert.equal(tracker.finished.length, 1);
    assert.equal(tracker.active.size, 0);
  });
}

test('a NetStack redirect-limit result preserves response cookies and normalizes its relative image Location', async () => {
  const native = createNative();
  const page = native.parse(androidHtml.replace(originAnchor, `<a href="${modernOriginUrl}">`), pageUrl);
  const resolving = native.client.fetchOriginalImageUrl('e', page);
  const request = native.requests[0];
  request.emitHeaders({ 'HTTP/1.1 302 Found': '', location: '/images/original.png',
    'set-cookie': 'session=updated; Path=/; HttpOnly\nrefresh=valid; Path=/' });
  request.pending.reject({ code: '2300047', message: 'The number of redirections reaches the maximum allowed.' });
  assert.equal(await resolving, 'https://e-hentai.org/images/original.png');
  assert.deepEqual(native.cookieWrites.map(({ value }) => value), [
    'session=updated; Path=/; HttpOnly', 'refresh=valid; Path=/'
  ]);
  assert.equal(native.cookieSaves(), 1);
});

test('NetStack headersReceive Set-Cookie arrays keep expiry-date commas intact during redirect-limit recovery', async () => {
  const native = createNative();
  const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl));
  const request = native.requests[0];
  request.emitHeaders({ location: 'https://images.example/full.png', 'set-cookie': [
    'session=updated; Expires=Tue, 20 Oct 2026 07:28:00 GMT; Path=/',
    'refresh=valid; Path=/'
  ] });
  request.pending.reject({ code: 2300047 });
  assert.equal(await resolving, 'https://images.example/full.png');
  assert.deepEqual(native.cookieWrites.map(({ value }) => value), [
    'session=updated; Expires=Tue, 20 Oct 2026 07:28:00 GMT; Path=/',
    'refresh=valid; Path=/'
  ]);
});

for (const [name, headers, error] of [
  ['no captured Location', { 'HTTP/2 302': '' }, { code: 2300047 }],
  ['an explicit HTTP 500 status', { 'HTTP/2 500': '', location: 'https://images.example/error.png' }, { code: 2300047 }],
  ['an explicit auth status', { 'status-line': 'HTTP/1.1 403 Forbidden', location: '/login' }, { code: 2300047 }],
  ['an invalid redirect scheme', { 'HTTP/2 302': '', location: 'file:///images/original.png' }, { code: 2300047 }],
  ['another native error', { 'HTTP/2 302': '', location: 'https://images.example/full.png' }, { code: 2300028 }],
  ['an absent native error', { 'HTTP/2 302': '', location: 'https://images.example/full.png' }, undefined]
]) {
  test(`a captured redirect is not accepted after ${name}`, async () => {
    const native = createNative();
    const tracker = native.createControl();
    const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl), tracker.control);
    const request = native.requests[0];
    request.emitHeaders(headers);
    request.pending.reject(error);
    await assert.rejects(resolving);
    assert.equal(request.listeners.size, 0);
    assert.equal(request.destroyCount, 1);
    assert.equal(tracker.finished.length, 1);
    assert.equal(tracker.active.size, 0);
    assert.equal(native.cookieWrites.length, 0);
  });
}

test('a later nonredirect header block cannot reuse an earlier redirect Location', async () => {
  const native = createNative();
  const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl));
  const request = native.requests[0];
  request.emitHeaders({ 'HTTP/2 302': '', location: 'https://images.example/full.png' });
  request.emitHeaders({ 'HTTP/2 401': '', 'set-cookie': 'session=invalid; Path=/' });
  request.pending.reject({ code: 2300047 });
  await assert.rejects(resolving, /2300047/);
  assert.equal(native.cookieWrites.length, 0);
});

test('cancellation wins after redirect headers arrive and before NetStack returns its redirect-limit error', async () => {
  const native = createNative();
  const tracker = native.createControl();
  const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl), tracker.control);
  const request = native.requests[0];
  request.emitHeaders({ 'HTTP/2 302': '', location: 'https://images.example/full.png', 'set-cookie': 'session=late; Path=/' });
  request.pending.reject({ code: 2300047 });
  tracker.cancel();
  await assert.rejects(resolving, /请求已取消/);
  assert.equal(request.listeners.size, 0);
  assert.equal(tracker.finished.length, 1);
  assert.equal(tracker.active.size, 0);
  assert.equal(native.cookieWrites.length, 0);
});

test('normal HttpResponse headers remain authoritative after an earlier event and do not activate error recovery', async () => {
  const native = createNative();
  const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl));
  const request = native.requests[0];
  request.emitHeaders({ 'HTTP/2 302': '', location: 'https://images.example/earlier.png' });
  request.pending.resolve(response({ location: 'https://images.example/current.png' }));
  assert.equal(await resolving, 'https://images.example/current.png');
  assert.equal(request.listeners.size, 0);
});

for (const scheduling of ['microtask', 'timer']) {
  test(`redirect-limit rejection before a ${scheduling} header event retains the listener and finishes without a retry`, async () => {
    const native = createNative();
    const tracker = native.createControl();
    const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl), tracker.control);
    const request = native.requests[0];
    request.pending.reject({ code: 2300047, message: 'The number of redirections reaches the maximum allowed.' });
    await new Promise((resolve) => setImmediate(resolve));
    assert.ok(request.listeners.has('headersReceive'), 'Do not remove the still-pending response header listener');
    assert.equal(native.timers.size, 1);
    assert.equal(tracker.active.size, 1);
    const emitHeader = () => request.emitHeaders({ 'HTTP/2 302': '', location: 'https://images.example/late-original.png' });
    if (scheduling === 'microtask') queueMicrotask(emitHeader);
    else setTimeout(emitHeader, 0);
    assert.equal(await resolving, 'https://images.example/late-original.png');
    assert.equal(native.requests.length, 1);
    assert.equal(request.listeners.size, 0);
    assert.equal(native.timers.size, 0);
    assert.equal(request.destroyCount, 1);
    assert.equal(tracker.finished.length, 1);
    assert.equal(tracker.active.size, 0);
  });
}

test('an earlier proxy CONNECT or informational header block does not end waiting for the origin redirect', async () => {
  const native = createNative();
  const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl));
  const request = native.requests[0];
  request.emitHeaders({ 'HTTP/1.1 100 Continue': '' });
  request.emitHeaders({ 'HTTP/1.1 200 Connection established': '' });
  request.pending.reject({ code: 2300047 });
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(native.timers.size, 1);
  assert.ok(request.listeners.has('headersReceive'));
  request.emitHeaders({ 'HTTP/2 302': '', location: 'https://images.example/from-origin.png' });
  assert.equal(await resolving, 'https://images.example/from-origin.png');
  assert.equal(native.timers.size, 0);
  assert.equal(request.listeners.size, 0);
});

test('cancellation while waiting for delayed redirect headers releases the request immediately', { timeout: 1000 }, async () => {
  const native = createNative();
  const tracker = native.createControl();
  const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl), tracker.control);
  const rejection = assert.rejects(resolving, /请求已取消/);
  const request = native.requests[0];
  request.pending.reject({ code: 2300047 });
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(native.timers.size, 1);
  assert.equal(tracker.active.size, 1);
  tracker.cancel();
  await Promise.race([rejection, new Promise((_, reject) => {
    const timeout = setTimeout(() => reject(new Error('Cancellation waited for the 500 ms header deadline')), 100);
    timeout.unref();
  })]);
  assert.equal(native.timers.size, 0);
  assert.equal(request.listeners.size, 0);
  assert.equal(tracker.finished.length, 1);
  assert.equal(tracker.active.size, 0);
  assert.equal(native.cookieWrites.length, 0);
});

test('missing redirect headers reach their bounded deadline and release every native resource', { timeout: 1500 }, async () => {
  const native = createNative();
  const tracker = native.createControl();
  const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl), tracker.control);
  const request = native.requests[0];
  request.pending.reject({ code: 2300047, message: 'The number of redirections reaches the maximum allowed.' });
  await assert.rejects(resolving, /2300047/);
  assert.deepEqual(native.timerDelays, [500]);
  assert.equal(native.timers.size, 0);
  assert.equal(request.listeners.size, 0);
  assert.equal(request.destroyCount, 1);
  assert.equal(tracker.finished.length, 1);
  assert.equal(tracker.active.size, 0);
  assert.equal(native.cookieWrites.length, 0);
});

test('a delayed known authentication failure aborts header waiting without using the full deadline', { timeout: 1000 }, async () => {
  const native = createNative();
  const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl));
  const rejection = assert.rejects(resolving, /2300047/);
  const request = native.requests[0];
  request.pending.reject({ code: 2300047 });
  await new Promise((resolve) => setImmediate(resolve));
  request.emitHeaders({ 'HTTP/2 403': '', 'set-cookie': 'session=invalid; Path=/' });
  await Promise.race([rejection, new Promise((_, reject) => {
    const timeout = setTimeout(() => reject(new Error('Known auth failure waited for the 500 ms header deadline')), 100);
    timeout.unref();
  })]);
  assert.equal(native.timers.size, 0);
  assert.equal(request.listeners.size, 0);
  assert.equal(native.cookieWrites.length, 0);
});

test('a relative original entry is resolved and its old nl value is replaced without corrupting the skip key', async () => {
  const native = createNative();
  const page = { ...native.parse(androidHtml, pageUrl),
    originImageUrl: '/fullimg.php?gid=1363978&page=10&key=source&nl=old&keep=1#entry', skipHathKey: 'new key/+&=' };
  const resolving = native.client.fetchOriginalImageUrl('e', page);
  const requested = new URL(native.requests[0].calls[0].url);
  assert.equal(requested.pathname, '/fullimg.php');
  assert.deepEqual(requested.searchParams.getAll('nl'), [page.skipHathKey]);
  assert.equal(requested.searchParams.get('keep'), '1');
  native.requests[0].pending.resolve(response());
  await resolving;
});

test('EX original entry uses the task site and native stable auth when WebCookieManager is empty', async () => {
  const native = createNative();
  const page = { ...native.parse(androidHtml, pageUrl), pageUrl: pageUrl.replace('e-hentai.org', 'exhentai.org'),
    originImageUrl: originUrl.replace('e-hentai.org', 'exhentai.org'), skipHathKey: '' };
  native.client.configureCookieHeader('ipb_member_id=42; ipb_pass_hash=token; igneous=valid; cf_clearance=discard');
  const resolving = native.client.fetchOriginalImageUrl('ex', page);
  const call = native.requests[0].calls[0];
  assert.equal(new URL(call.url).origin, 'https://exhentai.org');
  assert.equal(new URL(call.url).searchParams.has('nl'), false);
  assert.equal(call.options.header.Referer, page.pageUrl);
  assert.ok(call.options.header.Cookie.includes('igneous=valid'));
  assert.equal(call.options.header.Cookie.includes('cf_clearance'), false);
  assert.ok(native.cookieReads.includes(native.domains.DOMAIN_EX));
  native.requests[0].pending.resolve(response());
  await resolving;
});

for (const [name, site, entry] of [
  ['third-party fullimg host', 'e', 'https://other.example/fullimg.php?gid=1363978'],
  ['gallery host disguised as userinfo', 'e', 'https://e-hentai.org@other.example/fullimg.php?gid=1363978'],
  ['gallery host used as a third-party suffix', 'e', 'https://e-hentai.org.other.example/fullimg.php?gid=1363978'],
  ['untrusted gallery subdomain', 'e', 'https://other.e-hentai.org/fullimg.php?gid=1363978'],
  ['EX entry for an E task', 'e', 'https://exhentai.org/fullimg.php?gid=1363978'],
  ['E entry for an EX task', 'ex', originUrl],
  ['relative E entry for an EX task', 'ex', '/fullimg.php?gid=1363978'],
  ['fullimg filename under another path', 'e', 'https://e-hentai.org/images/fullimg.php?gid=1363978'],
  ['fullimg path with an extra segment', 'e', 'https://e-hentai.org/fullimg.php/other?gid=1363978'],
  ['fullimg string only in a query', 'e', 'https://e-hentai.org/other.php?source=fullimg.php'],
  ['nondefault HTTPS port', 'e', 'https://e-hentai.org:8443/fullimg.php?gid=1363978'],
  ['nondefault HTTP port', 'e', 'http://e-hentai.org:8080/fullimg.php?gid=1363978'],
  ['userinfo for an otherwise trusted host', 'e', 'https://name:password@e-hentai.org/fullimg.php?gid=1363978'],
  ['protocol-relative third-party entry', 'e', '//other.example/fullimg.php?gid=1363978'],
  ['third-party modern route', 'e', modernOriginUrl.replace('e-hentai.org', 'other.example')],
  ['modern route under another directory', 'e', modernOriginUrl.replace('/fullimg/', '/other/fullimg/')],
  ['empty modern route', 'e', 'https://e-hentai.org/fullimg/']
]) {
  test(`${name} is rejected before creating HTTP or reading authentication cookies`, async () => {
    const native = createNative();
    native.client.configureCookieHeader('ipb_member_id=42; ipb_pass_hash=private; igneous=private');
    const page = { ...native.parse(androidHtml, pageUrl), originImageUrl: entry };
    const tracker = native.createControl();
    await assert.rejects(native.client.fetchOriginalImageUrl(site, page, tracker.control), /原图入口地址无效/);
    assert.equal(native.requests.length, 0);
    assert.equal(native.cookieReads.length, 0);
    assert.equal(native.cookieWrites.length, 0);
    assert.equal(native.cookieSaves(), 0);
    assert.equal(tracker.started.length, 0);
    assert.equal(tracker.finished.length, 0);
    assert.equal(tracker.active.size, 0);
  });
}

for (const [site, entry] of [
  ['e', originUrl.replace('https:', 'http:')],
  ['e', originUrl.replace('https://e-hentai.org', 'http://e-hentai.org:80')],
  ['ex', modernOriginUrl.replace('https://e-hentai.org', 'http://exhentai.org')]
]) {
  test(`same-site HTTP original entries use the Android URL without imposing HTTPS: ${entry}`, async () => {
    const native = createNative();
    const page = { ...native.parse(androidHtml, pageUrl), originImageUrl: entry };
    const resolving = native.client.fetchOriginalImageUrl(site, page);
    assert.equal(new URL(native.requests[0].calls[0].url).hostname, new URL(entry).hostname);
    assert.equal(new URL(native.requests[0].calls[0].url).protocol, 'http:');
    native.requests[0].pending.resolve(response());
    assert.equal(await resolving, 'https://images.example/original.png');
  });
}

test('a third-party fullimg link received by the real HTML parser cannot access native credentials', async () => {
  const native = createNative();
  native.client.configureCookieHeader('ipb_member_id=42; ipb_pass_hash=private');
  const parsed = native.parse(androidHtml.replace(originAnchor,
    '<a class="original" href="https://other.example/fullimg.php?gid=1363978">'), pageUrl);
  assert.equal(parsed.originImageUrl, 'https://other.example/fullimg.php?gid=1363978');
  await assert.rejects(native.client.fetchOriginalImageUrl('e', parsed), /原图入口地址无效/);
  assert.equal(native.requests.length, 0);
  assert.equal(native.cookieReads.length, 0);
});

for (const [name, site, readerPageUrl, entry, expectedOrigin] of [
  ['relative EX entry', 'ex', pageUrl.replace('e-hentai.org', 'exhentai.org'),
    '/fullimg.php?gid=1363978&page=10&key=source', 'https://exhentai.org'],
  ['normalized default HTTPS port', 'e', pageUrl,
    'https://e-hentai.org:443/fullimg.php?gid=1363978&page=10&key=source', 'https://e-hentai.org']
]) {
  test(`${name} remains a valid authenticated original entry`, async () => {
    const native = createNative();
    native.client.configureCookieHeader('ipb_member_id=42; ipb_pass_hash=token; igneous=valid');
    const page = { ...native.parse(androidHtml, pageUrl), pageUrl: readerPageUrl, originImageUrl: entry };
    const resolving = native.client.fetchOriginalImageUrl(site, page);
    assert.equal(native.requests.length, 1);
    const call = native.requests[0].calls[0];
    const requested = new URL(call.url);
    assert.equal(requested.origin, expectedOrigin);
    assert.equal(requested.pathname, '/fullimg.php');
    assert.equal(requested.searchParams.get('nl'), page.skipHathKey);
    assert.equal(call.options.header.Referer, readerPageUrl);
    assert.ok(call.options.header.Cookie.includes('ipb_pass_hash=token'));
    native.requests[0].pending.resolve(response({ location: '//images.example/original.webp' }));
    assert.equal(await resolving, 'https://images.example/original.webp');
  });
}

for (const [name, reply] of [
  ['missing Location', { responseCode: 302, result: '', cookies: '', header: {} }],
  ['empty Location', response({ location: '  ' })],
  ['nonredirect successful HTML', response({ code: 200, location: null })],
  ['forbidden response', response({ code: 403, location: null })],
  ['invalid redirect scheme', response({ location: 'javascript:alert(1)' })],
  ['file redirect', response({ location: 'file:///data/original.jpg' })],
  ['malformed redirect URL', response({ location: 'https://' })]
]) {
  test(`${name} rejects the original entry rather than returning the compressed image URL`, async () => {
    const native = createNative();
    const tracker = native.createControl();
    const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl), tracker.control);
    const rejection = assert.rejects(resolving);
    native.requests[0].pending.resolve(reply);
    await rejection;
    assert.equal(native.requests.length, 1);
    assert.equal(tracker.finished.length, 1);
    assert.equal(tracker.active.size, 0);
    assert.equal(native.requests[0].destroyCount, 1);
  });
}

test('Location matching is case insensitive and preserves target query parameters', async () => {
  const native = createNative();
  const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl));
  native.requests[0].pending.resolve({ responseCode: 302, cookies: '', result: '',
    header: { lOcAtIoN: '/original.png?key=one&download=1' } });
  assert.equal(await resolving, 'https://e-hentai.org/original.png?key=one&download=1');
});

test('an original entry may resolve to the page image URL when the page already displays original quality', async () => {
  const native = createNative();
  const page = native.parse(androidHtml, pageUrl);
  const tracker = native.createControl();
  const resolving = native.client.fetchOriginalImageUrl('e', page, tracker.control);
  native.requests[0].pending.resolve(response({ location: page.imageUrl }));
  assert.equal(await resolving, page.imageUrl,
    'Match Android: an authenticated original entry decides the source, not equality with the display URL');
  assert.equal(tracker.finished.length, 1);
  assert.equal(tracker.active.size, 0);
  assert.equal(native.requests.length, 1);
  assert.equal(native.requests[0].destroyCount, 1);
});

test('a page without an original entry remains readable but cannot start a compressed fallback download', async () => {
  const native = createNative();
  const page = native.parse(androidHtml.replace(/<div id="i7"[\s\S]*?<\/div>/, ''), pageUrl);
  assert.equal(page.originImageUrl, '');
  assert.ok(page.imageUrl.includes('xres=1280/10.jpg'));
  const tracker = native.createControl();
  await assert.rejects(native.client.fetchOriginalImageUrl('e', page, tracker.control), /原图/);
  assert.equal(native.requests.length, 0);
  assert.equal(tracker.started.length, 0);
  assert.equal(tracker.finished.length, 0);
});

test('the original resolver accepts a plain HTTP image target as well as HTTPS', async () => {
  const native = createNative();
  const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl));
  native.requests[0].pending.resolve(response({ location: 'http://images.example/original.gif?token=one' }));
  assert.equal(await resolving, 'http://images.example/original.gif?token=one');
});

test('pre-cancellation avoids creating or registering an original HTTP request', async () => {
  const native = createNative();
  const tracker = native.createControl();
  tracker.cancel();
  await assert.rejects(native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl), tracker.control), /取消/);
  assert.equal(native.requests.length, 0);
  assert.equal(tracker.started.length, 0);
  assert.equal(tracker.finished.length, 0);
  assert.equal(native.cookieWrites.length, 0);
});

test('cancellation while registering an original request prevents HTTP dispatch and still deregisters', async () => {
  const native = createNative();
  const tracker = native.createControl({ cancelOnStart: true });
  await assert.rejects(native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl), tracker.control), /取消/);
  assert.equal(native.requests.length, 1);
  assert.equal(native.requests[0].calls.length, 0);
  assert.equal(tracker.finished.length, 1);
  assert.equal(tracker.active.size, 0);
  assert.equal(native.cookieWrites.length, 0);
});

test('an independent cancellation signal completes cleanup even when native HTTP never settles', { timeout: 1000 }, async () => {
  const native = createNative();
  const tracker = native.createControl();
  const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl), tracker.control);
  const rejection = assert.rejects(resolving, /取消/);
  assert.equal(tracker.active.size, 1);
  tracker.cancel();
  await rejection;
  assert.equal(tracker.finished.length, 1);
  assert.equal(tracker.active.size, 0);
  assert.equal(native.requests[0].destroyCount, 2);
  assert.equal(native.cookieWrites.length, 0);
});

test('native HTTP rejecting during destroy still reports cancellation and finishes the registered request once', async () => {
  const native = createNative({ rejectOnDestroy: true });
  const tracker = native.createControl();
  const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl), tracker.control);
  const rejection = assert.rejects(resolving, /取消/);
  tracker.cancel();
  await rejection;
  assert.equal(tracker.finished.length, 1);
  assert.equal(tracker.active.size, 0);
  assert.equal(native.cookieWrites.length, 0);
});

test('an original response resolved immediately before pause cannot capture cookies or return a download URL', async () => {
  const native = createNative();
  const tracker = native.createControl({ withSignal: false });
  const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl), tracker.control);
  const rejection = assert.rejects(resolving, /取消/);
  native.requests[0].pending.resolve(response({ cookies: 'late=forbidden' }));
  tracker.cancel();
  await rejection;
  assert.equal(native.cookieWrites.length, 0);
  assert.equal(native.requests.length, 1);
  assert.equal(tracker.finished.length, 1);
});

for (const lateReply of ['success', 'failure']) {
  test(`late native ${lateReply} after signal cancellation cannot produce an original URL, capture cookies, or finish twice`,
    { timeout: 1000 }, async () => {
      const native = createNative();
      const tracker = native.createControl();
      let continued = false;
      const resolving = native.client.fetchOriginalImageUrl('e', native.parse(androidHtml, pageUrl), tracker.control)
        .then((value) => { continued = true; return value; });
      const rejection = assert.rejects(resolving, /取消/);
      tracker.cancel();
      await rejection;
      const unhandled = [];
      const onUnhandled = (error) => unhandled.push(error);
      process.on('unhandledRejection', onUnhandled);
      try {
        if (lateReply === 'success') native.requests[0].pending.resolve(response({ cookies: 'late=forbidden' }));
        else native.requests[0].pending.reject(new Error('Late original HTTP failure'));
        await new Promise((resolve) => setImmediate(resolve));
        assert.equal(continued, false);
        assert.equal(native.cookieWrites.length, 0);
        assert.equal(native.cookieSaves(), 0);
        assert.equal(tracker.finished.length, 1);
        assert.equal(tracker.active.size, 0);
        assert.equal(native.requests.length, 1);
        assert.equal(unhandled.length, 0);
      } finally {
        process.removeListener('unhandledRejection', onUnhandled);
      }
    });
}
