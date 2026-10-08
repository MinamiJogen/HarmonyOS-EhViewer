import assert from 'node:assert/strict';
import {
  closeSync, existsSync, fstatSync, mkdirSync, mkdtempSync, openSync,
  readFileSync, readdirSync, renameSync, rmSync, statSync, unlinkSync, writeSync
} from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import vm from 'node:vm';
import { deflateSync, inflateSync } from 'node:zlib';

// This runs the complete production page parser, request methods, download,
// atomic image write, and original receipt in one VM with real temporary files.
// HTTP responses are local fixtures; no gallery, credentials, or GP are used.
// The SDK URL(input, base), closeSync(number | File), and writeSync signatures
// are represented by Node adapters. ImageSource is a platform boundary: its
// adapter validates a real PNG (CRC and decompression), then reads the IHDR.
// This cannot verify live endpoint access or the HarmonyOS image decoder.
const nativeSource = readFileSync(new URL('../entry/src/main/ets/ehviewer/EhNative.ets', import.meta.url), 'utf8');
const indexSource = readFileSync(new URL('../entry/src/main/ets/pages/Index.ets', import.meta.url), 'utf8');
const receiptSource = readFileSync(new URL('../entry/src/main/ets/download/OriginalDownloadPages.ets', import.meta.url), 'utf8');
const modelSource = readFileSync(new URL('../entry/src/main/ets/download/DownloadModels.ets', import.meta.url), 'utf8');
const constantsSource = readFileSync(new URL('../entry/src/main/ets/constants/AppConstants.ets', import.meta.url), 'utf8');
const androidHtml = readFileSync(new URL('../EhviewerAndroid/app/src/test/resources/com/hippo/ehviewer/client/parser/GalleryPageParserTest.html', import.meta.url), 'utf8');
const pageUrl = 'https://e-hentai.org/s/49c9e58c17/1363978-10';
const legacyEntry = 'https://e-hentai.org/fullimg.php?gid=1363978&amp;page=10&amp;key=qt2hwrx98a4';
const modernEntry = 'https://e-hentai.org/fullimg/1363978/10/qt2hwrx98a4/10.png';
const imageUrl = 'https://originals.example/画廊%20原图/10.png?token=fixture';

function indexMethod(name) {
  const start = indexSource.search(new RegExp(`\\n  private (?:async )?${name}\\(`));
  assert.notEqual(start, -1, `Missing Index production method ${name}`);
  const tail = indexSource.slice(start + 1);
  const end = tail.slice(1).search(/\n  (?:private |aboutTo|@Builder)/);
  assert.notEqual(end, -1, `Missing Index production method end ${name}`);
  return tail.slice(0, end + 1);
}

function nativeMethod(name) {
  const start = nativeSource.search(new RegExp(`\\n  (?:private|public) static (?:async )?${name}\\(`));
  assert.notEqual(start, -1, `Missing native production method ${name}`);
  const tail = nativeSource.slice(start + 1);
  const end = tail.indexOf('\n  }');
  assert.notEqual(end, -1, `Missing native production method end ${name}`);
  return tail.slice(0, end + 4);
}

function nativeFunction(name) {
  const start = nativeSource.indexOf(`function ${name}(`);
  assert.notEqual(start, -1, `Missing native production function ${name}`);
  const tail = nativeSource.slice(start);
  const end = tail.indexOf('\n}');
  assert.notEqual(end, -1, `Missing native production function end ${name}`);
  return tail.slice(0, end + 2);
}

const constants = [...indexSource.split('\n'), ...modelSource.split('\n'), ...constantsSource.split('\n')]
  .filter((line) => /^(?:export )?const (?:sharedDownload(?:CancelKeys|RemovedKeys|RunGenerations|ActiveRequests|RequestCancelSignals)|DOWNLOAD_RUNTIME_(?:CANCEL|REMOVED)_KEYS_KEY|DOWNLOAD_STATUS_[A-Z_]+|DOWNLOAD_IMAGE_RESPONSE_MAX_BYTES|READER_IMAGE_EXTENSIONS)\b/.test(line))
  .join('\n').replace(/^export /gm, '');
const patterns = nativeSource.split('\n').filter((line) =>
  /^const (?:IMAGE_URL_PATTERN|ORIGIN_IMAGE_URL_PATTERN|SKIP_HATH_KEY_PATTERN|PAGE_URL_PATTERN):/.test(line)).join('\n');
const nativeStart = nativeSource.indexOf('export class NativeEhClient {') + 'export class NativeEhClient {'.length;
const nativeHeaderEnd = nativeSource.indexOf('\n  public static async fetchOriginalImageUrl(', nativeStart);
assert.ok(nativeHeaderEnd > nativeStart);
const domains = nativeSource.split('\n').filter((line) => /^  static readonly DOMAIN_(?:E|EX|FORUMS):/.test(line)).join('\n');
const registryField = indexSource.split('\n').find((line) => /private (?:readonly )?downloadActiveRequests\s*:/.test(line));
assert.ok(registryField);
const methods = [
  'downloadKey', 'findDownloadIndex', 'currentDownloadRunGeneration', 'runtimeStringArray',
  'isRuntimeStringArrayMarked', 'isDownloadKeyCancelled', 'isDownloadKeyRemoved',
  'shouldStopDownload', 'assertDownloadRunActive', 'registerDownloadActiveRequest',
  'unregisterDownloadActiveRequest', 'createDownloadRequestControl', 'ensureLocalDirectory',
  'downloadSinglePage', 'downloadImageFile', 'downloadUsesOriginalImage', 'downloadTargetPath',
  'galleryDownloadDir', 'downloadRoot', 'readerImageExtensionFromUrl', 'galleryDirectoryIdentity',
  'existingDownloadPath', 'removeReplacedDownloadPageFiles', 'downloadCookieHeader',
  'appendDownloadCookieSource', 'appendReaderCookieSource', 'readerHostFromUrl'
];
const harnessSource = stripTypeScriptTypes(`(() => {
  const DOMAIN = 0;
  const LOG_TAG = 'fixture';
  ${constants}
  ${patterns}
  ${['decodeHtml', 'parsePageIndexFromUrl', 'readerPageUrlWithSkipHathKey', 'parseReaderPage',
    'isMeaningfulErrorMessage', 'nativeRequestErrorMessage'].map(nativeFunction).join('\n')}
  class EhUrl { ${domains} }
  class NativeEhClient {
    ${nativeSource.slice(nativeStart, nativeHeaderEnd)}
    ${['fetchOriginalImageUrl', 'requestText', 'fetchReaderPage'].map(nativeMethod).join('\n')}
  }
  ${receiptSource.replace(/^import .+;\s*$/gm, '').replace(/\bexport /g, '')}
  class DownloadHarness {
    ${registryField}
    ${methods.map(indexMethod).join('\n')}
  }
  return { NativeEhClient, DownloadHarness, parseReaderPage,
    generations: sharedDownloadRunGenerations,
    activeRequests: sharedDownloadActiveRequests,
    cancelSignals: sharedDownloadRequestCancelSignals,
    verifiedOriginalDownloadPath };
})()`);

function crc32(bytes) {
  let crc = 0xFFFFFFFF;
  for (const byte of bytes) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xEDB88320 : 0);
  }
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

function pngChunk(type, bytes) {
  const name = Buffer.from(type);
  const chunk = Buffer.alloc(12 + bytes.length);
  chunk.writeUInt32BE(bytes.length);
  name.copy(chunk, 4);
  bytes.copy(chunk, 8);
  chunk.writeUInt32BE(crc32(Buffer.concat([name, bytes])), 8 + bytes.length);
  return chunk;
}

function png(width, height) {
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0);
  header.writeUInt32BE(height, 4);
  header[8] = 8;
  header[9] = 0; // 8-bit grayscale, no interlace; filter byte 0 on every row.
  return Buffer.concat([
    Buffer.from('89504e470d0a1a0a', 'hex'), pngChunk('IHDR', header),
    pngChunk('IDAT', deflateSync(Buffer.alloc((width + 1) * height))),
    pngChunk('IEND', Buffer.alloc(0))
  ]);
}

const originalPng = png(4893, 3360);
const reducedPng = png(1280, 879);

function inspectPng(data) {
  const bytes = Buffer.from(data);
  assert.equal(bytes.subarray(0, 8).toString('hex'), '89504e470d0a1a0a');
  const payloads = [];
  let width;
  let height;
  let ended = false;
  for (let offset = 8; offset < bytes.length;) {
    const length = bytes.readUInt32BE(offset);
    const type = bytes.subarray(offset + 4, offset + 8).toString();
    const payload = bytes.subarray(offset + 8, offset + 8 + length);
    assert.equal(bytes.readUInt32BE(offset + 8 + length),
      crc32(bytes.subarray(offset + 4, offset + 8 + length)));
    if (type === 'IHDR') {
      width = payload.readUInt32BE(0);
      height = payload.readUInt32BE(4);
      assert.equal(payload[8], 8);
      assert.equal(payload[9], 0);
    } else if (type === 'IDAT') payloads.push(payload);
    else if (type === 'IEND') ended = true;
    offset += length + 12;
  }
  assert.equal(ended, true);
  const decoded = inflateSync(Buffer.concat(payloads));
  assert.equal(decoded.length, (width + 1) * height);
  return { width, height };
}

function createPipeline(t, { html = androidHtml, site = 'e', quality = 'original',
  bytes = originalPng, location = imageUrl, originalCode = 302, originalCookies = '',
  binaryHeaders = {}, gateway = undefined, imageDecoderError = undefined } = {}) {
  const root = mkdtempSync(join(tmpdir(), 'eh-original-pipeline-'));
  const dir = join(root, '画廊名字');
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const cookieJar = new Map([
    ['https://e-hentai.org', 'ipb_member_id=fixture; ipb_pass_hash=fixture-pass'],
    ['https://exhentai.org', 'igneous=fixture-igneous'],
    ['https://originals.example', 'image_token=fixture-image-cookie']
  ]);
  const calls = [];
  const requests = [];
  const descriptorPaths = new Map();
  const operations = [];
  const metadata = [];
  const platform = {
    setTimeout, clearTimeout,
    url: { URL },
    GallerySite: { E: 'e', EX: 'ex' },
    AppStorage: { get: () => undefined },
    AppNetworkProxy: { requestProxy: () => false },
    hilog: { error() {}, warn() {}, info() {} },
    webview: { WebCookieManager: {
      fetchCookieSync(value) { return cookieJar.get(new URL(value).origin) ?? ''; },
      configCookieSync(value, cookie) {
        const source = new URL(value);
        const domain = /(?:^|;)\s*Domain=([^;]+)/i.exec(cookie)?.[1]?.replace(/^\./, '');
        if (domain && source.hostname !== domain && !source.hostname.endsWith(`.${domain}`)) return;
        const pair = cookie.split(';')[0];
        const pairs = (cookieJar.get(source.origin) ?? '').split(';').map((part) => part.trim()).filter(Boolean);
        const name = pair.split('=')[0];
        cookieJar.set(source.origin, [...pairs.filter((part) => part.split('=')[0] !== name), pair].join('; '));
      },
      saveCookieSync() {}
    } },
    image: { createImageSource(data) {
      return { async getImageInfo() {
        if (imageDecoderError) throw imageDecoderError;
        const size = inspectPng(data);
        metadata.push(size);
        return { size };
      }, async release() {} };
    } },
    http: {
      RequestMethod: { GET: 'GET', POST: 'POST' },
      HttpDataType: { STRING: 'STRING', ARRAY_BUFFER: 'ARRAY_BUFFER' },
      createHttp() {
        const callbacks = new Map();
        const request = {
          destroyCount: 0, callbacks,
          on(name, callback) {
            assert.equal(callbacks.has(name), false, 'Only one subscription per event in this request');
            callbacks.set(name, callback);
          },
          off(name, callback) {
            assert.equal(callbacks.get(name), callback, 'Remove the original event subscription');
            callbacks.delete(name);
          },
          async request(value, options) {
            calls.push({ url: value, options });
            const parsed = new URL(value);
            if (parsed.pathname.startsWith('/s/')) {
              assert.equal(options.expectDataType, 'STRING');
              return { responseCode: 200, header: { 'Content-Type': 'text/html' }, cookies: '', result: html };
            }
            if (parsed.pathname.startsWith('/fullimg')) {
              if (gateway) return gateway(value, options,
                (name, data) => callbacks.get(name)?.(data));
              assert.equal(options.expectDataType, 'STRING');
              return { responseCode: originalCode, header: { Location: location }, cookies: originalCookies, result: '' };
            }
            assert.equal(options.expectDataType, 'ARRAY_BUFFER');
            return { responseCode: 200, cookies: '', header: {
              'Content-Type': 'image/png', 'Content-Length': `${bytes.length}`, ...binaryHeaders
            }, result: bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) };
          },
          destroy() { this.destroyCount++; }
        };
        requests.push(request);
        return request;
      }
    },
    fileIo: {
      OpenMode: { READ_WRITE: 2, CREATE: 64, TRUNC: 512 },
      accessSync: existsSync,
      mkdirSync(path, recursive) { mkdirSync(path, { recursive }); },
      statSync(path) { return typeof path === 'number' ? fstatSync(path) : statSync(path); },
      listFileSync: readdirSync,
      readTextSync(path) { return readFileSync(path, 'utf8'); },
      openSync(path) {
        const fd = openSync(path, 'w+');
        descriptorPaths.set(fd, path);
        operations.push({ kind: 'open', path });
        return { fd };
      },
      writeSync(fd, data, options = {}) {
        const buffer = typeof data === 'string' ? Buffer.from(data, 'utf8') : Buffer.from(data);
        operations.push({ kind: 'write', path: descriptorPaths.get(fd), bytes: buffer.length });
        return writeSync(fd, buffer, 0, options.length ?? buffer.length);
      },
      closeSync(file) {
        const fd = typeof file === 'number' ? file : file.fd;
        closeSync(fd);
        descriptorPaths.delete(fd);
      },
      renameSync(from, to) { operations.push({ kind: 'rename', from, to }); renameSync(from, to); },
      unlinkSync
    }
  };
  const production = vm.runInNewContext(harnessSource, platform);
  const task = { gid: 1363978, site, token: '88616cdd73', title: '画廊名字',
    status: 'downloading', imageQuality: quality, downloadDir: dir };
  production.generations.set(`${site}-${task.gid}`, 1);
  const page = new production.DownloadHarness();
  // Task lookup and persistent settings are not involved in the original-image
  // protocol. The production cancellation logic reads this current task source.
  page.downloadItems = [task];
  page.findDownloadItem = () => page.downloadItems[0];
  page.downloadCancelKeys = new Set();
  page.downloadRemovedKeys = new Set();
  page.readString = (key, fallback) => fallback;
  return {
    root, dir, calls, requests, operations, metadata, task, page, production,
    async download(index = 9) { return page.downloadSinglePage(task,
      site === 'ex' ? pageUrl.replace('e-hentai.org', 'exhentai.org') : pageUrl, index, 1); }
  };
}

function assertCommittedOriginal(harness, result, index = 9, extension = 'png') {
  assert.equal(result.bytes, originalPng.length);
  assert.equal(result.path, join(harness.dir, `${String(index + 1).padStart(8, '0')}.${extension}`));
  assert.deepEqual(readFileSync(result.path), originalPng);
  assert.equal(harness.production.verifiedOriginalDownloadPath(harness.dir,
    harness.page.galleryDirectoryIdentity(harness.task), index), result.path);
  assert.equal(harness.page.existingDownloadPath(harness.task, index), result.path);
  assert.equal(readdirSync(harness.dir).some((name) => name.endsWith('.tmp')), false);
  assert.equal(harness.production.activeRequests.size, 0);
  assert.equal(harness.production.cancelSignals.size, 0);
  assert.equal(harness.requests.every((request) => request.destroyCount === 1), true);
  assert.equal(harness.requests.every((request) => request.callbacks.size === 0), true);
}

test('Android HTML follows fullimg redirect and commits an original PNG plus a real resumable receipt', async (t) => {
  const harness = createPipeline(t, { originalCookies: 'hath_session=fixture-session; Path=/; HttpOnly' });
  const result = await harness.download();
  assertCommittedOriginal(harness, result);
  assert.equal(harness.calls.length, 3);
  assert.ok(new URL(harness.calls[1].url).pathname.startsWith('/fullimg'));
  assert.equal(harness.calls[1].options.maxRedirects, 0);
  assert.equal(harness.calls[1].options.header.Referer, pageUrl);
  assert.ok(harness.calls[1].options.header.Cookie.includes('ipb_member_id=fixture'));
  assert.equal(harness.calls[2].url, new URL(imageUrl).toString());
  assert.equal(harness.calls[2].options.header.Cookie, 'image_token=fixture-image-cookie');
  assert.equal(harness.calls[2].options.header.Host, undefined);
});

for (const [label, site, entry] of [
  ['modern E route', 'e', modernEntry],
  ['modern EX route', 'ex', modernEntry.replace('e-hentai.org', 'exhentai.org')],
  ['relative modern route', 'e', '/fullimg/1363978/10/qt2hwrx98a4/10.png']
]) {
  test(`${label} uses the production chain through image and receipt commits`, async (t) => {
    const html = androidHtml.replace(legacyEntry, entry).replaceAll('e-hentai.org',
      site === 'ex' ? 'exhentai.org' : 'e-hentai.org');
    const harness = createPipeline(t, { html, site });
    assertCommittedOriginal(harness, await harness.download());
    if (site === 'ex') assert.ok(harness.calls[1].options.header.Cookie.includes('igneous=fixture-igneous'));
  });
}

test('a valid highly compressible original can be small without losing the original dimensions', async (t) => {
  assert.ok(originalPng.length < 100_000);
  assert.deepEqual(inspectPng(originalPng), { width: 4893, height: 3360 });
  const harness = createPipeline(t);
  assertCommittedOriginal(harness, await harness.download());
});

test('compressed mode uses the display URL and never creates an original receipt', async (t) => {
  const harness = createPipeline(t, { quality: 'compressed', bytes: reducedPng });
  const result = await harness.download();
  assert.equal(harness.calls.length, 2);
  assert.ok(harness.calls[1].url.includes('xres=1280/10.jpg'));
  assert.deepEqual(readFileSync(result.path), reducedPng);
  assert.equal(harness.production.verifiedOriginalDownloadPath(harness.dir,
    harness.page.galleryDirectoryIdentity(harness.task), 9), '');
});

test('an HTTP entry on the selected gallery host can resolve an original like the Android request builder', async (t) => {
  const harness = createPipeline(t, { html: androidHtml.replace(legacyEntry,
    legacyEntry.replace('https:', 'http:')) });
  assertCommittedOriginal(harness, await harness.download());
});

for (const [label, site, entry] of [
  ['Android PHP entry', 'e', legacyEntry],
  ['current route on EX', 'ex', modernEntry.replace('e-hentai.org', 'exhentai.org')]
]) {
  test(`${label}: SDK headersReceive plus 2300047 completes the real original pipeline`, async (t) => {
    const html = androidHtml.replace(legacyEntry, entry).replaceAll('e-hentai.org',
      site === 'ex' ? 'exhentai.org' : 'e-hentai.org');
    const harness = createPipeline(t, { html, site, gateway: (value, options, emit) => {
      assert.equal(options.maxRedirects, 0);
      emit('headersReceive', { 'HTTP/2 302': '', location: imageUrl });
      throw { code: 2300047, message: 'The number of redirections reaches the maximum allowed.' };
    } });
    assertCommittedOriginal(harness, await harness.download());
    assert.equal(harness.calls.length, 3);
    assert.equal(harness.calls[2].url, new URL(imageUrl).toString());
    assert.equal(harness.calls[2].options.expectDataType, 'ARRAY_BUFFER');
  });
}

test('SDK redirect-limit failure without Location never downloads a display image or writes a receipt', async (t) => {
  const harness = createPipeline(t, { gateway: (value, options, emit) => {
    emit('headersReceive', { 'content-type': 'text/html' });
    throw { code: 2300047, message: 'The number of redirections reaches the maximum allowed.' };
  } });
  await assert.rejects(harness.download());
  assert.equal(harness.calls.length, 2);
  assert.equal(harness.operations.length, 0);
  assert.equal(harness.production.activeRequests.size, 0);
  assert.equal(harness.production.cancelSignals.size, 0);
  assert.equal(harness.requests.every((request) => request.callbacks.size === 0), true);
});

test('a different network failure cannot use a captured Location to commit a false success', async (t) => {
  const harness = createPipeline(t, { gateway: (value, options, emit) => {
    emit('headersReceive', { location: imageUrl });
    throw { code: 2300028, message: 'Operation timed out.' };
  } });
  await assert.rejects(harness.download());
  assert.equal(harness.calls.length, 2);
  assert.equal(harness.operations.length, 0);
});

test('an unsupported system image decode does not discard the original endpoint response', async (t) => {
  const harness = createPipeline(t, { imageDecoderError: { code: 62980103, message: 'Unsupported image format.' } });
  assertCommittedOriginal(harness, await harness.download());
});

test('a decoded reduced image cannot pass as an original with explicit larger dimensions', async (t) => {
  const harness = createPipeline(t, { bytes: reducedPng });
  await assert.rejects(harness.download(), /原图尺寸不匹配/);
  assert.equal(harness.operations.length, 0);
  assert.deepEqual(harness.metadata, [{ width: 1280, height: 879 }]);
});

test('SDK redirect-limit headers preserve Set-Cookie for the subsequent same-host image request', async (t) => {
  const target = 'https://e-hentai.org/original-fixture/10.png';
  const harness = createPipeline(t, { gateway: (value, options, emit) => {
    emit('headersReceive', { 'HTTP/2 302': '', Location: target,
      'Set-Cookie': 'original_session=fixture-redirect-cookie; Path=/; HttpOnly' });
    throw { code: 2300047, message: 'The number of redirections reaches the maximum allowed.' };
  } });
  assertCommittedOriginal(harness, await harness.download());
  assert.equal(harness.calls[2].url, target);
  assert.ok(harness.calls[2].options.header.Cookie.includes('original_session=fixture-redirect-cookie'));
  assert.ok(harness.calls[2].options.header.Cookie.includes('ipb_member_id=fixture'));
});

test('Android accepts a Location equal to the display URL when fullimg supplies that original endpoint', async (t) => {
  const displayed = /<img id="img" src="([^"]+)"/.exec(androidHtml)[1];
  const harness = createPipeline(t, { location: displayed });
  assertCommittedOriginal(harness, await harness.download(), 9, 'jpg');
  assert.equal(harness.calls.length, 3);
  assert.equal(harness.calls[2].url, displayed);
});

test('a page without a separate original anchor saves the displayed original as Android does', async (t) => {
  const displayed = /<img id="img" src="([^"]+)"/.exec(androidHtml)[1];
  const html = androidHtml.replace(/<a href="[^\"]*fullimg\.php[^\"]*">Download original[^<]*<\/a>/, '')
    .replace(displayed, imageUrl);
  const harness = createPipeline(t, { html });
  const parsed = harness.production.parseReaderPage(html, pageUrl);
  assert.equal(parsed.originImageUrl, '');
  assertCommittedOriginal(harness, await harness.download());
  assert.equal(harness.calls.length, 2);
  assert.equal(harness.calls[1].url, imageUrl);
});

test('SDK headersReceive delivered after redirect-limit rejection still completes the original and receipt', async (t) => {
  let lateHeadersTimer;
  t.after(() => clearTimeout(lateHeadersTimer));
  const harness = createPipeline(t, { gateway: (value, options, emit) => {
    // NetStack queues the rejected request promise and headersReceive callback
    // through separate uv tasks. Reproduce the observed promise-first order.
    lateHeadersTimer = setTimeout(() => {
      emit('headersReceive', { 'HTTP/2 302': '', Location: imageUrl });
    }, 0);
    throw { code: 2300047, message: 'The number of redirections reaches the maximum allowed.' };
  } });
  assertCommittedOriginal(harness, await harness.download());
  assert.equal(harness.calls.length, 3);
  assert.equal(harness.calls[2].url, new URL(imageUrl).toString());
});
