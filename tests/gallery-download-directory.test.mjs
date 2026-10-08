import assert from 'node:assert/strict';
import {
  closeSync, existsSync, mkdirSync, mkdtempSync, openSync, readFileSync,
  readdirSync, renameSync, rmSync, statSync, unlinkSync, writeFileSync, writeSync
} from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import vm from 'node:vm';

// Run the production module against real temporary directories. The adapter
// translates HarmonyOS synchronous fileIo calls; fault injection checks that
// errors cannot overwrite or strand existing downloaded images. Native grants
// and virtual document-provider paths still require a device check.
const source = readFileSync(new URL(
  '../entry/src/main/ets/download/GalleryDownloadDirectory.ets', import.meta.url), 'utf8');
const harnessSource = stripTypeScriptTypes(`(() => {
  ${source.replace(/^import .+;\s*$/gm, '').replace(/\bexport /g, '')}
  return { galleryDirectorySegment, chooseGalleryDirectory, findGalleryDirectory,
    migrateGalleryDirectory, isGalleryDirectory, writeGalleryDirectoryIdentity };
})()`);
const MARKER = '.e-harmony-gallery.json';

function item(overrides = {}) {
  return { gid: 123, site: 'e', token: 'token', title: 'Gallery', ...overrides };
}

function createModule(t, { root: existingRoot } = {}) {
  const root = existingRoot ?? mkdtempSync(join(tmpdir(), 'eh-gallery-directory-'));
  if (!existingRoot) t.after(() => rmSync(root, { recursive: true, force: true }));
  const calls = [];
  const faults = {};
  const descriptors = new Map();
  const module = vm.runInNewContext(harnessSource, {
    fileIo: {
      OpenMode: { READ_WRITE: 2, CREATE: 64, TRUNC: 512 },
      accessSync(path) {
        calls.push({ operation: 'access', path });
        if (faults.accessPath === path) throw new Error('Controlled access error');
        return existsSync(path);
      },
      statSync(path) {
        calls.push({ operation: 'stat', path });
        return statSync(path);
      },
      listFileSync(path) {
        calls.push({ operation: 'list', path });
        if (faults.list) throw new Error('Controlled listing error');
        return readdirSync(path);
      },
      readTextSync(path) {
        calls.push({ operation: 'read', path });
        return readFileSync(path, 'utf8');
      },
      openSync(path) {
        calls.push({ operation: 'open', path });
        if (faults.open) throw new Error('Controlled open error');
        const fd = openSync(path, 'w+');
        descriptors.set(fd, path);
        return { fd };
      },
      writeSync(fd, value) {
        calls.push({ operation: 'write', path: descriptors.get(fd), value });
        if (faults.write) throw new Error('Controlled write error');
        if (faults.shortWrite) return writeSync(fd, value.substring(0, value.length - 1));
        return writeSync(fd, value);
      },
      closeSync(fd) {
        calls.push({ operation: 'close', path: descriptors.get(fd) });
        if (faults.close) {
          faults.close = false;
          throw new Error('Controlled close error');
        }
        closeSync(fd);
        descriptors.delete(fd);
        faults.afterClose?.();
      },
      renameSync(from, to) {
        calls.push({ operation: 'rename', from, to });
        if ((statSync(from).isDirectory() && faults.directoryRename) ||
          (!statSync(from).isDirectory() && faults.markerRename)) {
          throw new Error('Controlled rename error');
        }
        // The production module must reject existing paths before this call.
        assert.equal(existsSync(to), false, 'Production attempted to overwrite a path');
        renameSync(from, to);
      },
      unlinkSync(path) {
        calls.push({ operation: 'unlink', path });
        unlinkSync(path);
      }
    }
  });
  return { ...module, root, calls, faults };
}

function makeDirectory(module, name, identity) {
  const path = join(module.root, name);
  mkdirSync(path);
  if (identity) writeFileSync(join(path, MARKER), JSON.stringify(identity));
  return path;
}

function directoryRenames(module) {
  return module.calls.filter((call) => call.operation === 'rename' && !call.from.endsWith('.json.tmp'));
}

test('gallery names retain Chinese, Japanese, spaces and complete emoji', (t) => {
  const module = createModule(t);
  assert.equal(module.galleryDirectorySegment(' 画廊 漫画 📚 サンプル ', 123), '画廊 漫画 📚 サンプル');
  assert.equal(module.galleryDirectorySegment('.. My  Gallery. ', 123), 'My Gallery');
});

test('unsafe path characters and control bytes cannot create subdirectories', (t) => {
  const module = createModule(t);
  const name = module.galleryDirectorySegment('A/B\\C:D*E?F"G<H>I|J\0\nK', 123);
  assert.equal(name, 'A_B_C_D_E_F_G_H_I_J__K');
  assert.equal(module.galleryDirectorySegment(' ..  ', 123), '画廊 123');
});

test('long Unicode names stay within 180 UTF-8 bytes without broken code points', (t) => {
  const module = createModule(t);
  assert.equal(module.galleryDirectorySegment('中'.repeat(100), 123), '中'.repeat(60));
  assert.equal(module.galleryDirectorySegment('📚'.repeat(100), 123), '📚'.repeat(45));
  const mixed = module.galleryDirectorySegment('A' + '📚'.repeat(100), 123);
  assert.equal(Buffer.byteLength(mixed), 177);
  assert.ok(!mixed.endsWith('\ud83d'));
  assert.equal(module.galleryDirectorySegment('A\ud83dB', 123), 'A_B');
});

test('an unoccupied destination uses the title without an ID suffix', (t) => {
  const module = createModule(t);
  assert.equal(module.chooseGalleryDirectory(module.root, item({ title: '中文名' }), []),
    join(module.root, '中文名'));
  assert.equal(readdirSync(module.root).length, 0);
});

test('a same-name ordinary file is preserved and forces an identity suffix', (t) => {
  const module = createModule(t);
  writeFileSync(join(module.root, 'Gallery'), 'unrelated file');
  assert.equal(module.chooseGalleryDirectory(module.root, item(), []), join(module.root, 'Gallery [e-123]'));
  assert.equal(readFileSync(join(module.root, 'Gallery'), 'utf8'), 'unrelated file');
});

test('existing directories are not borrowed even with a matching marker', (t) => {
  const module = createModule(t);
  const plain = makeDirectory(module, 'Gallery', item());
  assert.equal(module.chooseGalleryDirectory(module.root, item(), []), join(module.root, 'Gallery [e-123]'));
  assert.equal(module.findGalleryDirectory(module.root, item()), plain);
  assert.equal(module.chooseGalleryDirectory(module.root, item(), [], plain), plain);
});

test('other tasks reserve names before filesystem creation', (t) => {
  const module = createModule(t);
  const plain = join(module.root, 'Gallery');
  assert.equal(module.chooseGalleryDirectory(module.root, item(), [plain]), join(module.root, 'Gallery [e-123]'));
  assert.equal(module.chooseGalleryDirectory(module.root, item({ site: 'ex' }), [plain]),
    join(module.root, 'Gallery [ex-123]'));
});

test('further collisions use numbered suffixes without overwriting any directory', (t) => {
  const module = createModule(t);
  makeDirectory(module, 'Gallery');
  makeDirectory(module, 'Gallery [e-123]');
  makeDirectory(module, 'Gallery [e-123] (2)');
  assert.equal(module.chooseGalleryDirectory(module.root, item(), []), join(module.root, 'Gallery [e-123] (3)'));
  assert.equal(readdirSync(module.root).length, 3);
});

test('collision suffixes count toward the 180-byte UTF-8 segment limit', (t) => {
  const module = createModule(t);
  const title = '📚'.repeat(100);
  const current = item({ title });
  makeDirectory(module, module.galleryDirectorySegment(title, current.gid));
  const selected = module.chooseGalleryDirectory(module.root, current, []);
  assert.ok(selected.endsWith(' [e-123]'));
  assert.ok(Buffer.byteLength(selected.slice(module.root.length + 1)) <= 180);
});

test('invalid, unavailable and inaccessible paths cannot become free destinations', (t) => {
  const module = createModule(t);
  assert.equal(module.chooseGalleryDirectory('', item(), []), '');
  assert.equal(module.chooseGalleryDirectory('relative/path', item(), []), '');
  assert.equal(module.chooseGalleryDirectory(`${module.root}/../other`, item(), []), '');
  assert.equal(module.chooseGalleryDirectory(`${module.root}/missing`, item(), []), '');
  module.faults.accessPath = join(module.root, 'Gallery');
  assert.equal(module.chooseGalleryDirectory(module.root, item(), []), '');
});

test('identity is fully written and closed before its atomic marker commit', (t) => {
  const module = createModule(t);
  const directory = makeDirectory(module, 'Gallery');
  const current = item({ token: '中文token' });
  assert.equal(module.writeGalleryDirectoryIdentity(directory, current), true);
  assert.deepEqual(JSON.parse(readFileSync(join(directory, MARKER), 'utf8')),
    { gid: current.gid, site: current.site, token: current.token });
  const close = module.calls.findIndex((call) => call.operation === 'close');
  const commit = module.calls.findIndex((call) => call.operation === 'rename');
  assert.ok(close >= 0 && commit > close);
  assert.equal(existsSync(join(directory, `${MARKER}.tmp`)), false);
});

test('matching identity needs no write, close or rename during repeated reconciliation', (t) => {
  const module = createModule(t);
  const directory = makeDirectory(module, 'Gallery', item());
  assert.equal(module.writeGalleryDirectoryIdentity(directory, item()), true);
  assert.equal(module.migrateGalleryDirectory(directory, item(), []), directory);
  assert.ok(module.calls.every((call) => !['open', 'write', 'close', 'rename'].includes(call.operation)));
});

test('foreign, malformed and cross-site markers cannot be overwritten', (t) => {
  const module = createModule(t);
  const directory = makeDirectory(module, 'Gallery', item({ site: 'ex' }));
  const before = readFileSync(join(directory, MARKER), 'utf8');
  assert.equal(module.writeGalleryDirectoryIdentity(directory, item()), false);
  assert.equal(readFileSync(join(directory, MARKER), 'utf8'), before);
  writeFileSync(join(directory, MARKER), '{partial');
  assert.equal(module.writeGalleryDirectoryIdentity(directory, item()), false);
  assert.equal(readFileSync(join(directory, MARKER), 'utf8'), '{partial');
  assert.ok(module.calls.every((call) => !['open', 'write', 'rename'].includes(call.operation)));
});

for (const failure of ['open', 'write', 'shortWrite', 'close', 'markerRename']) {
  test(`a ${failure} marker failure leaves the image directory in place and can be retried`, (t) => {
    const module = createModule(t);
    const old = makeDirectory(module, 'e-123');
    writeFileSync(join(old, '00000001.jpg'), 'original image');
    module.faults[failure] = true;
    assert.equal(module.migrateGalleryDirectory(old, item(), []), old);
    assert.equal(readFileSync(join(old, '00000001.jpg'), 'utf8'), 'original image');
    assert.equal(existsSync(join(module.root, 'Gallery')), false);
    assert.equal(existsSync(join(old, MARKER)), false);
    assert.equal(existsSync(join(old, `${MARKER}.tmp`)), false);
    assert.equal(directoryRenames(module).length, 0);
    module.faults[failure] = false;
    assert.equal(module.migrateGalleryDirectory(old, item(), []), join(module.root, 'Gallery'));
  });
}

test('successful migration preserves complete and temporary image bytes and closes before rename', (t) => {
  const module = createModule(t);
  const old = makeDirectory(module, 'e-123');
  const image = Buffer.from([0xFF, 0xD8, 0x01, 0x82, 0xFF, 0xD9]);
  writeFileSync(join(old, '00000001.jpg'), image);
  writeFileSync(join(old, '00000002.png.tmp'), 'partial image');
  writeFileSync(join(old, '.ehviewer'), 'legacy gallery metadata');
  const moved = module.migrateGalleryDirectory(old, item({ title: '画廊名字' }), []);
  assert.equal(moved, join(module.root, '画廊名字'));
  assert.equal(existsSync(old), false);
  assert.deepEqual(readFileSync(join(moved, '00000001.jpg')), image);
  assert.equal(readFileSync(join(moved, '00000002.png.tmp'), 'utf8'), 'partial image');
  assert.equal(readFileSync(join(moved, '.ehviewer'), 'utf8'), 'legacy gallery metadata');
  const rename = module.calls.findIndex((call) => call.operation === 'rename' && call.from === old);
  assert.ok(module.calls.findIndex((call) => call.operation === 'close') < rename);
});

test('renamed directory is recoverable after a restart before task metadata is persisted', (t) => {
  const module = createModule(t);
  const old = makeDirectory(module, 'e-123');
  writeFileSync(join(old, '00000001.png'), 'saved image');
  const current = item({ title: '画廊名字' });
  const moved = module.migrateGalleryDirectory(old, current, []);
  const restarted = createModule(t, { root: module.root });
  assert.equal(restarted.findGalleryDirectory(module.root, current), moved);
  assert.equal(readFileSync(join(moved, '00000001.png'), 'utf8'), 'saved image');
  assert.equal(restarted.findGalleryDirectory(module.root, item({ site: 'ex', title: current.title })), '');
  assert.equal(restarted.findGalleryDirectory(module.root, item({ token: 'different', title: current.title })), '');
});

test('directory rename failure keeps both images and identity at their original location', (t) => {
  const module = createModule(t);
  const old = makeDirectory(module, 'e-123');
  writeFileSync(join(old, '00000001.jpg'), 'saved image');
  module.faults.directoryRename = true;
  assert.equal(module.migrateGalleryDirectory(old, item(), []), old);
  assert.equal(readFileSync(join(old, '00000001.jpg'), 'utf8'), 'saved image');
  assert.equal(module.findGalleryDirectory(module.root, item()), old);
  module.faults.directoryRename = false;
  assert.equal(module.migrateGalleryDirectory(old, item(), []), join(module.root, 'Gallery'));
});

test('same-name galleries migrate separately and never merge their images', (t) => {
  const module = createModule(t);
  const first = makeDirectory(module, 'e-123');
  const second = makeDirectory(module, 'ex-123');
  writeFileSync(join(first, '00000001.jpg'), 'e image');
  writeFileSync(join(second, '00000001.jpg'), 'ex image');
  const e = module.migrateGalleryDirectory(first, item(), []);
  const ex = module.migrateGalleryDirectory(second, item({ site: 'ex' }), [e]);
  assert.equal(e, join(module.root, 'Gallery'));
  assert.equal(ex, join(module.root, 'Gallery [ex-123]'));
  assert.equal(readFileSync(join(e, '00000001.jpg'), 'utf8'), 'e image');
  assert.equal(readFileSync(join(ex, '00000001.jpg'), 'utf8'), 'ex image');
});

test('a destination appearing after marker close is not overwritten', (t) => {
  const module = createModule(t);
  const old = makeDirectory(module, 'e-123');
  writeFileSync(join(old, '00000001.jpg'), 'saved image');
  module.faults.afterClose = () => {
    module.faults.afterClose = undefined;
    mkdirSync(join(module.root, 'Gallery'));
    writeFileSync(join(module.root, 'Gallery', 'unrelated'), 'other files');
  };
  assert.equal(module.migrateGalleryDirectory(old, item(), []), old);
  assert.equal(directoryRenames(module).length, 0);
  assert.equal(readFileSync(join(old, '00000001.jpg'), 'utf8'), 'saved image');
  assert.equal(readFileSync(join(module.root, 'Gallery', 'unrelated'), 'utf8'), 'other files');
});

test('reserved directories cannot be claimed or migrated by another task', (t) => {
  const module = createModule(t);
  const old = makeDirectory(module, 'e-123', item());
  assert.equal(module.findGalleryDirectory(module.root, item(), [old]), '');
  assert.equal(module.migrateGalleryDirectory(old, item(), [old]), old);
  assert.equal(directoryRenames(module).length, 0);
});

test('recovery accepts only directories with exact complete identity', (t) => {
  const module = createModule(t);
  makeDirectory(module, 'unmarked');
  const malformed = makeDirectory(module, 'malformed');
  writeFileSync(join(malformed, MARKER), 'null');
  makeDirectory(module, 'wrong id', item({ gid: 456 }));
  makeDirectory(module, 'wrong token', item({ token: 'other' }));
  makeDirectory(module, 'wrong site', item({ site: 'ex' }));
  writeFileSync(join(module.root, 'ordinary file'), JSON.stringify(item()));
  assert.equal(module.findGalleryDirectory(module.root, item()), '');
  const matching = makeDirectory(module, 'renamed manually', item());
  assert.equal(module.findGalleryDirectory(module.root, item()), matching);
  module.faults.list = true;
  assert.equal(module.findGalleryDirectory(module.root, item()), '');
});

test('file and absent paths are rejected as gallery directories without mutating them', (t) => {
  const module = createModule(t);
  const file = join(module.root, 'ordinary file');
  writeFileSync(file, 'saved content');
  assert.equal(module.isGalleryDirectory(module.root), true);
  assert.equal(module.isGalleryDirectory(file), false);
  assert.equal(module.isGalleryDirectory(join(module.root, 'missing')), false);
  assert.equal(module.writeGalleryDirectoryIdentity(file, item()), false);
  assert.equal(module.migrateGalleryDirectory(file, item(), []), file);
  assert.equal(readFileSync(file, 'utf8'), 'saved content');
});
