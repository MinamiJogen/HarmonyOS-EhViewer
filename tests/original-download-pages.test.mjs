import assert from 'node:assert/strict';
import {
  closeSync, existsSync, fstatSync, mkdirSync, mkdtempSync, openSync, readFileSync,
  readdirSync, renameSync, rmSync, statSync, truncateSync, unlinkSync, writeFileSync, writeSync
} from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import vm from 'node:vm';

// Execute the production receipt logic with real temporary files. The adapter
// maps HarmonyOS fileIo calls to Node and injects incomplete writes and I/O
// failures; authorization and the real image endpoint require device checks.
const source = readFileSync(new URL(
  '../entry/src/main/ets/download/OriginalDownloadPages.ets', import.meta.url), 'utf8');
const constants = readFileSync(new URL(
  '../entry/src/main/ets/constants/AppConstants.ets', import.meta.url), 'utf8');
const extensions = JSON.parse(/READER_IMAGE_EXTENSIONS: string\[\] = (\[[^;]+\]);/.exec(constants)[1]
  .replaceAll("'", '"'));
const harnessSource = stripTypeScriptTypes(`(() => {
  ${source.replace(/^import .+;\s*$/gm, '').replace(/\bexport /g, '')}
  return { verifiedOriginalDownloadPath, recordOriginalDownloadPage };
})()`);

function identity(overrides = {}) {
  return { gid: 123, site: 'e', token: 'token', title: '画廊 Gallery', ...overrides };
}

function marker(dir, pageIndex = 0) {
  return join(dir, `.${String(pageIndex + 1).padStart(8, '0')}.original.json`);
}

function receipt(result, pageIndex = 0, overrides = {}) {
  return { gid: 123, site: 'e', token: 'token', pageIndex,
    fileName: result.path.slice(result.path.lastIndexOf('/') + 1), bytes: result.bytes,
    sourceUrl: result.sourceUrl, ...overrides };
}

function createModule(t) {
  const root = mkdtempSync(join(tmpdir(), 'eh-original-page-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const calls = [];
  const faults = {};
  const descriptors = new Map();
  const module = vm.runInNewContext(harnessSource, {
    READER_IMAGE_EXTENSIONS: extensions,
    url: { URL },
    fileIo: {
      OpenMode: { READ_WRITE: 2, CREATE: 64, TRUNC: 512 },
      accessSync(path) {
        if (faults.accessPath === path) throw new Error('Controlled access error');
        return existsSync(path);
      },
      statSync(path) {
        if (faults.statPath === path) throw new Error('Controlled stat error');
        return typeof path === 'number' ? fstatSync(path) : statSync(path);
      },
      readTextSync(path) {
        if (faults.readPath === path) throw new Error('Controlled read error');
        return readFileSync(path, 'utf8');
      },
      openSync(path) {
        calls.push({ operation: 'open', path });
        if (faults.open) throw new Error('Controlled open error');
        const fd = openSync(path, 'w+');
        descriptors.set(fd, path);
        return { fd };
      },
      writeSync(fd, text) {
        calls.push({ operation: 'write', path: descriptors.get(fd) });
        if (faults.write) throw new Error('Controlled write error');
        const bytes = Buffer.from(text);
        if (faults.shortWrite) return writeSync(fd, bytes.subarray(0, bytes.length - 1));
        if (faults.falseCompleteWrite) {
          writeSync(fd, bytes.subarray(0, bytes.length - 1));
          return bytes.length;
        }
        return writeSync(fd, bytes);
      },
      closeSync(fd) {
        calls.push({ operation: 'close', path: descriptors.get(fd) });
        if (faults.close) {
          faults.close = false;
          throw new Error('Controlled close error');
        }
        closeSync(fd);
        descriptors.delete(fd);
        const hook = faults.afterClose;
        faults.afterClose = undefined;
        hook?.();
      },
      renameSync(from, to) {
        calls.push({ operation: 'rename', from, to });
        if (faults.rename) throw new Error('Controlled rename error');
        renameSync(from, to);
      },
      unlinkSync(path) {
        calls.push({ operation: 'unlink', path });
        unlinkSync(path);
      }
    }
  });
  t.after(() => {
    for (const fd of descriptors.keys()) {
      try { closeSync(fd); } catch {}
    }
  });
  return { ...module, root, calls, faults };
}

function image(module, name = '00000001.jpg', bytes = Buffer.from('complete original image')) {
  const path = join(module.root, name);
  writeFileSync(path, bytes);
  return { path, bytes: bytes.length, sourceUrl: 'https://cdn.example/full.png?token=original' };
}

test('unmarked compressed images are never accepted as verified originals', (t) => {
  const module = createModule(t);
  const result = image(module);
  assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), '');
  assert.equal(readFileSync(result.path, 'utf8'), 'complete original image');
});

test('a successful original is recorded atomically with its identity, URL and exact file bytes', (t) => {
  const module = createModule(t);
  const result = image(module);
  assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0, result), true);
  assert.deepEqual(JSON.parse(readFileSync(marker(module.root), 'utf8')), receipt(result));
  assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), result.path);
  assert.deepEqual(module.calls.map((call) => call.operation), ['open', 'write', 'close', 'rename']);
  assert.equal(existsSync(`${marker(module.root)}.tmp`), false);
});

test('UTF-8 tokens and URLs use byte lengths and survive a process restart', (t) => {
  const first = createModule(t);
  const result = image(first);
  result.sourceUrl = 'https://cdn.example/原图.png?key=原始';
  const gallery = identity({ token: '中文 📚' });
  assert.equal(first.recordOriginalDownloadPage(first.root, gallery, 0, result), true);
  const reopened = vm.runInNewContext(harnessSource, {
    READER_IMAGE_EXTENSIONS: extensions, url: { URL },
    fileIo: { statSync, readTextSync: (path) => readFileSync(path, 'utf8') }
  });
  assert.equal(reopened.verifiedOriginalDownloadPath(first.root, gallery, 0), result.path);
});

test('every supported image extension and historical page-number format verifies', (t) => {
  const module = createModule(t);
  for (const extension of extensions) {
    for (const stem of ['13', '00013', '00000013']) {
      const result = image(module, `${stem}${extension}`);
      assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 12, result), true);
      assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 12), result.path);
    }
  }
});

test('receipts are independent for concurrent gallery pages', (t) => {
  const module = createModule(t);
  const first = image(module, '00000001.png');
  const second = image(module, '00000002.jpg');
  assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0, first), true);
  assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 1, second), true);
  assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), first.path);
  assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 1), second.path);
});

for (const [label, overrides] of [
  ['gallery', { gid: 456 }], ['site', { site: 'ex' }], ['token', { token: 'new-token' }]
]) {
  test(`a conflicting ${label} cannot reuse or overwrite another original receipt`, (t) => {
    const module = createModule(t);
    const result = image(module);
    assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0, result), true);
    const previous = readFileSync(marker(module.root), 'utf8');
    assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(overrides), 0), '');
    assert.equal(module.recordOriginalDownloadPage(module.root, identity(overrides), 0, result), false);
    assert.equal(readFileSync(marker(module.root), 'utf8'), previous);
    assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), result.path);
  });
}

test('changed page numbers and unsafe or unrelated file names cannot point outside the gallery', (t) => {
  const module = createModule(t);
  const result = image(module);
  for (const overrides of [
    { pageIndex: 1 }, { pageIndex: '0' }, { fileName: '../00000001.jpg' },
    { fileName: '/00000001.jpg' }, { fileName: 'subdir/00000001.jpg' },
    { fileName: '00000002.jpg' }, { fileName: '000001.jpg' },
    { fileName: '00000001.jpg.tmp' }, { fileName: '00000001.svg' }
  ]) {
    writeFileSync(marker(module.root), JSON.stringify(receipt(result, 0, overrides)));
    assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), '');
  }
});

test('damaged receipts and mismatched, missing, empty or nonregular images fail verification', (t) => {
  const module = createModule(t);
  const result = image(module);
  for (const value of ['{unfinished', 'null', 'false', '[]', '"page"']) {
    writeFileSync(marker(module.root), value);
    assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), '');
  }
  for (const bytes of [0, -1, result.bytes - 1, String(result.bytes), 1.5]) {
    writeFileSync(marker(module.root), JSON.stringify(receipt(result, 0, { bytes })));
    assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), '');
  }
  writeFileSync(marker(module.root), JSON.stringify(receipt(result)));
  truncateSync(result.path, 0);
  assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), '');
  unlinkSync(result.path);
  assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), '');
  mkdirSync(result.path);
  assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), '');
});

test('non-HTTP source URLs cannot certify or reuse an original image', (t) => {
  const module = createModule(t);
  const result = image(module);
  for (const sourceUrl of ['', 'file:///tmp/original.png', 'javascript:alert(1)',
    'data:image/png;base64,x', 'https://', ' https://cdn.example/original.png',
    'https://cdn.example/has space.png']) {
    const rejected = { ...result, sourceUrl };
    assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0, rejected), false);
    writeFileSync(marker(module.root), JSON.stringify(receipt(rejected)));
    assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), '');
  }
  assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0,
    { ...result, sourceUrl: 'http://cdn.example/original.jpg' }), true);
});

test('invalid directories, page indexes and target paths never create receipts', (t) => {
  const module = createModule(t);
  const result = image(module);
  for (const directory of ['', '/', 'relative', `${module.root}/../other`, `${module.root}\0extra`]) {
    assert.equal(module.recordOriginalDownloadPage(directory, identity(), 0, result), false);
    assert.equal(module.verifiedOriginalDownloadPath(directory, identity(), 0), '');
  }
  for (const index of [-1, 0.5, NaN, Infinity, Number.MAX_SAFE_INTEGER]) {
    assert.equal(module.recordOriginalDownloadPage(module.root, identity(), index, result), false);
    assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), index), '');
  }
  for (const path of [join(module.root, '00000002.jpg'), `${module.root}/../00000001.jpg`,
    `${module.root}/sub/00000001.jpg`, `${module.root}/00000001.jpg.tmp`, undefined]) {
    assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0, { ...result, path }), false);
  }
  assert.equal(existsSync(marker(module.root)), false);
  assert.equal(module.calls.length, 0);
});

test('an image must already be committed with the recorded number of bytes', (t) => {
  const module = createModule(t);
  const result = image(module);
  for (const bytes of [0, -1, result.bytes + 1, 1.5, '22']) {
    assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0, { ...result, bytes }), false);
  }
  unlinkSync(result.path);
  assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0, result), false);
  mkdirSync(result.path);
  assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0, result), false);
  assert.equal(existsSync(marker(module.root)), false);
});

for (const failure of ['open', 'write', 'shortWrite', 'falseCompleteWrite', 'close', 'rename']) {
  test(`${failure} failure retains the image and cannot leave a verified or partial receipt`, (t) => {
    const module = createModule(t);
    const result = image(module);
    const previousImage = readFileSync(result.path);
    module.faults[failure] = true;
    assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0, result), false);
    assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), '');
    assert.deepEqual(readFileSync(result.path), previousImage);
    assert.equal(existsSync(marker(module.root)), false);
    assert.equal(existsSync(`${marker(module.root)}.tmp`), false);
  });
}

test('a failed replacement preserves the previous valid receipt and old page variant', (t) => {
  const module = createModule(t);
  const previous = image(module, '00000001.jpg', Buffer.from('old verified image'));
  assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0, previous), true);
  const oldReceipt = readFileSync(marker(module.root), 'utf8');
  const next = image(module, '00000001.png');
  module.faults.rename = true;
  assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0, next), false);
  assert.equal(readFileSync(marker(module.root), 'utf8'), oldReceipt);
  assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), previous.path);
  assert.equal(existsSync(next.path), true);
  assert.equal(existsSync(previous.path), true);
  assert.equal(existsSync(`${marker(module.root)}.tmp`), false);
});

test('successful replacement selects the new original and leaves alternative images to the caller', (t) => {
  const module = createModule(t);
  const previous = image(module, '00000001.jpg', Buffer.from('old compressed image'));
  const next = image(module, '00000001.png');
  writeFileSync(marker(module.root), '{damaged receipt');
  assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0, next), true);
  assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), next.path);
  assert.equal(existsSync(previous.path), true);
  assert.equal(readdirSync(module.root).length, 3);
});

test('a conflicting receipt appearing before atomic commit is preserved', (t) => {
  const module = createModule(t);
  const result = image(module);
  const conflict = JSON.stringify(receipt(result, 0, { gid: 456 }));
  module.faults.afterClose = () => writeFileSync(marker(module.root), conflict);
  assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0, result), false);
  assert.equal(readFileSync(marker(module.root), 'utf8'), conflict);
  assert.equal(existsSync(result.path), true);
  assert.equal(existsSync(`${marker(module.root)}.tmp`), false);
  assert.equal(module.calls.some((call) => call.operation === 'rename'), false);
});

test('a receipt path occupied by a directory is never removed or overwritten', (t) => {
  const module = createModule(t);
  const result = image(module);
  mkdirSync(marker(module.root));
  writeFileSync(join(marker(module.root), 'keep.txt'), 'unrelated');
  assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0, result), false);
  assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), '');
  assert.equal(readFileSync(join(marker(module.root), 'keep.txt'), 'utf8'), 'unrelated');
});

test('verification fails safely when filesystem access becomes unavailable', (t) => {
  const module = createModule(t);
  const result = image(module);
  assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0, result), true);
  module.faults.readPath = marker(module.root);
  assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), '');
  const oldReceipt = readFileSync(marker(module.root), 'utf8');
  assert.equal(module.recordOriginalDownloadPage(module.root, identity(), 0, result), false);
  assert.equal(readFileSync(marker(module.root), 'utf8'), oldReceipt);
  module.faults.readPath = undefined;
  module.faults.statPath = result.path;
  assert.equal(module.verifiedOriginalDownloadPath(module.root, identity(), 0), '');
});
