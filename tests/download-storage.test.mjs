import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';

// Execute Index's production path selection, legacy recovery, and offline page
// lookup against a filesystem double. This checks storage routing and directory
// migrations; it does not grant public access, touch actual files, or run on a device.
// Run with Node.js 22.13+: node --test tests/download-storage.test.mjs
const source = readFileSync(new URL('../entry/src/main/ets/pages/Index.ets', import.meta.url), 'utf8');
const appConstants = readFileSync(new URL('../entry/src/main/ets/constants/AppConstants.ets', import.meta.url), 'utf8');
const modelConstants = readFileSync(new URL('../entry/src/main/ets/download/DownloadModels.ets', import.meta.url), 'utf8');
const directoryModule = readFileSync(new URL('../entry/src/main/ets/download/GalleryDownloadDirectory.ets', import.meta.url), 'utf8')
  .replace(/^import[^\n]+\n/gm, '').replace(/^export /gm, '');
const originalPageModule = readFileSync(new URL('../entry/src/main/ets/download/OriginalDownloadPages.ets', import.meta.url), 'utf8')
  .replace(/^import[^\n]+\n/gm, '').replace(/^export /gm, '');
const constants = [...appConstants.split('\n'), ...modelConstants.split('\n')]
  .filter((line) => /^export const (?:READER_DOWNLOAD_DIR_NAME|READER_IMAGE_EXTENSIONS|DOWNLOAD_INFO_FILENAME|DOWNLOAD_DEFAULT_LABEL|DOWNLOAD_STATUS_[A-Z_]+)\b/.test(line))
  .join('\n').replace(/^export /gm, '');

function productionMethod(name) {
  const start = source.search(new RegExp(`\\n  private ${name}\\(`));
  assert.notEqual(start, -1, `Missing download storage method: ${name}`);
  const tail = source.slice(start + 1);
  const end = tail.slice(1).search(/\n  (?:private |aboutTo|@Builder)/);
  assert.notEqual(end, -1, `Missing end of download storage method: ${name}`);
  return tail.slice(0, end + 1);
}

const methodNames = [
  'downloadRoot', 'galleryDownloadDir', 'existingDownloadPath', 'downloadTargetPath',
  'legacyGalleryDownloadDirs', 'galleryDirectoryIdentity', 'reservedGalleryDownloadDirs', 'restoreExistingDownloadDirectory',
  'readerDownloadedImageUri', 'fileUri', 'readerSafeSegment', 'readerImageExtensionFromUrl',
  'downloadKey', 'findDownloadIndex', 'findDownloadItem', 'toDownloadItem', 'cloneDownloadItem',
  'normalizeDownloadStatus', 'parseReaderPagePosition', 'createLocalReaderPageIfAvailable',
  'downloadUsesOriginalImage', 'downloadedFileCountForItem', 'reconcileDownloadItemsWithLocalFiles'
];
const harnessSource = stripTypeScriptTypes(`(() => {
  ${constants}
  ${directoryModule}
  ${originalPageModule}
  return {
    downloadDirName: READER_DOWNLOAD_DIR_NAME,
    Harness: class DownloadStorageHarness {
      ${methodNames.map(productionMethod).join('\n')}
    }
  };
})()`);

function item(overrides = {}) {
  return {
    gid: 123, site: 'e', token: 'token', title: 'Gallery', titleJpn: '', cover: '',
    detailUrl: 'https://gallery.example/g/123/token/', uploader: 'uploader',
    categoryLabel: 'Manga', posted: 'posted', pages: 10, language: 'Japanese', rating: 4,
    status: 'paused', label: 'default', queuedAt: 'queued', lastAction: 'paused',
    downloaded: 2, total: 10, failedCount: 1, archiveUri: '', createdAt: 'created',
    updatedAt: 'updated', currentPage: 2, currentPageLabel: '2/10',
    speedBytesPerSecond: 0, remainingSeconds: -1, downloadDir: '', error: 'page error',
    pageErrors: [{ page: 3, message: 'page error', updatedAt: 'updated' }],
    ...overrides
  };
}

function createPage({ root = '/public/Download/EhViewer', legacyRoot = '', filesDir = '/sandbox/files',
  files = [], directories = {}, inaccessible = [], unlistable = [], publicUris = {},
  fileSizes = {}, fileTexts = {}, unstatable = [], renameFailures = [], runningKeys = [], activeRequests = {},
  tasks = [], detail = item(), site = detail.site } = {}) {
  const presentFiles = new Set([...files, ...Object.keys(fileTexts), ...Object.entries(directories)
    .flatMap(([directory, names]) => names.map((name) => `${directory}/${name}`))]);
  const entries = new Map(Object.entries(directories).map(([path, names]) => [path, [...names]]));
  if (root.trim().length > 0 && !entries.has(root.trim())) entries.set(root.trim(), []);
  const texts = new Map(Object.entries(fileTexts));
  const openedFiles = new Map();
  let nextFd = 1;
  const accessFailures = new Set(inaccessible);
  const listFailures = new Set(unlistable);
  const statFailures = new Set(unstatable);
  const failedRenames = new Set(renameFailures);
  const accesses = [];
  const lists = [];
  const stats = [];
  const renames = [];
  const writes = [];
  const uriCalls = [];
  const parent = (path) => path.slice(0, path.lastIndexOf('/'));
  const basename = (path) => path.slice(path.lastIndexOf('/') + 1);
  function registerEntry(path) {
    const directory = parent(path);
    if (!directory) return;
    if (!entries.has(directory)) {
      entries.set(directory, []);
      registerEntry(directory);
    }
    const names = entries.get(directory);
    if (!names.includes(basename(path))) names.push(basename(path));
  }
  for (const path of [...entries.keys(), ...presentFiles]) registerEntry(path);
  const fileSystem = {
    OpenMode: { READ_ONLY: 0, READ_WRITE: 2, CREATE: 64, TRUNC: 512 },
    accessSync(path) {
      accesses.push(path);
      if (accessFailures.has(path)) throw new Error('Access denied');
      return presentFiles.has(path) || entries.has(path);
    },
    listFileSync(path) {
      lists.push(path);
      if (listFailures.has(path)) throw new Error('Listing denied');
      return [...(entries.get(path) ?? [])];
    },
    statSync(path) {
      if (typeof path === 'number') path = openedFiles.get(path);
      stats.push(path);
      if (statFailures.has(path)) throw new Error('Stat denied');
      if (!presentFiles.has(path) && !entries.has(path)) throw new Error('File absent');
      const regular = presentFiles.has(path) && !entries.has(path);
      return {
        isFile: () => regular, isDirectory: () => entries.has(path),
        size: fileSizes[path] ?? (texts.has(path) ? Buffer.byteLength(texts.get(path)) : (regular ? 1024 : 4096))
      };
    },
    openSync(path, mode = 0) {
      if (accessFailures.has(path)) throw new Error('Open denied');
      if (!presentFiles.has(path)) {
        if ((mode & fileSystem.OpenMode.CREATE) === 0) throw new Error('File absent');
        presentFiles.add(path);
        texts.set(path, '');
        registerEntry(path);
      }
      if ((mode & fileSystem.OpenMode.TRUNC) !== 0) texts.set(path, '');
      const fd = nextFd++;
      openedFiles.set(fd, path);
      return { fd };
    },
    writeSync(fd, content) {
      const path = openedFiles.get(typeof fd === 'number' ? fd : fd.fd);
      if (!path) throw new Error('File descriptor absent');
      const value = typeof content === 'string' ? content : Buffer.from(content).toString('utf8');
      texts.set(path, value);
      writes.push(path);
      return Buffer.byteLength(value);
    },
    readTextSync(path) {
      if (accessFailures.has(path)) throw new Error('Read denied');
      if (!presentFiles.has(path)) throw new Error('File absent');
      return texts.get(path) ?? '';
    },
    closeSync(fd) {
      openedFiles.delete(typeof fd === 'number' ? fd : fd.fd);
    },
    unlinkSync(path) {
      presentFiles.delete(path);
      texts.delete(path);
      const directory = parent(path);
      if (entries.has(directory)) entries.set(directory,
        entries.get(directory).filter((name) => name !== basename(path)));
    },
    renameSync(from, to) {
      if (failedRenames.has(from)) throw new Error('Rename denied');
      if (entries.has(to)) throw new Error('Target directory exists');
      if (presentFiles.has(to)) {
        if (!presentFiles.has(from) || entries.has(from)) throw new Error('Target exists');
        presentFiles.delete(to);
        texts.delete(to);
      }
      if (!presentFiles.has(from) && !entries.has(from)) throw new Error('Source absent');
      renames.push({ from, to });
      const sourceParent = parent(from);
      if (entries.has(sourceParent)) entries.set(sourceParent,
        entries.get(sourceParent).filter((name) => name !== basename(from)));
      for (const path of [...entries.keys()]) {
        if (path === from || path.startsWith(`${from}/`)) {
          entries.set(`${to}${path.slice(from.length)}`, entries.get(path));
          entries.delete(path);
        }
      }
      for (const path of [...presentFiles]) {
        if (path === from || path.startsWith(`${from}/`)) {
          const destination = `${to}${path.slice(from.length)}`;
          presentFiles.delete(path);
          presentFiles.add(destination);
          if (texts.has(path)) {
            texts.set(destination, texts.get(path));
            texts.delete(path);
          }
          if (Object.hasOwn(fileSizes, path)) fileSizes[destination] = fileSizes[path];
        }
      }
      registerEntry(to);
    }
  };
  const { Harness, downloadDirName } = vm.runInNewContext(harnessSource, {
    fileIo: fileSystem,
    url: { URL },
    publicDownloadFileUri(path) {
      uriCalls.push(path);
      return publicUris[path] ?? '';
    },
    clampNumber: (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum)
  });
  const page = new Harness();
  page.downloadDirectoryPath = root;
  page.legacyDownloadDirectoryPath = legacyRoot;
  page.downloadItems = tasks;
  // Canonical cross-route task ownership is covered by download-runtime tests.
  // Supply its lookup boundary here so this harness tests storage routing only.
  const tasksByKey = new Map(tasks.map((task) => [page.downloadKey(task.gid, task.site), task]));
  page.findDownloadItemByKey = (key) => tasksByKey.get(key);
  page.downloadItemsSource = () => page.downloadItems;
  page.isDownloadKeyRunningInCurrentProcess = (key) => runningKeys.includes(key);
  page.isDownloadItemRunning = (task) => runningKeys.includes(page.downloadKey(task.gid, task.site));
  page.readBoolean = () => false;
  const persisted = [];
  page.scheduleDownloadItemPersist = (task) => persisted.push(task);
  page.downloadActiveRequests = new Map(Object.entries(activeRequests));
  page.nativeDetail = detail;
  page.siteMode = site;
  page.abilityFilesDir = () => filesDir;
  page.nowLabel = () => 'now';
  return { page, downloadDirName, accesses, lists, stats, uriCalls, renames, writes,
    presentFiles, directories: entries, fileTexts: texts, persisted };
}

test('only the prepared public root supplies the default directory, with no sandbox fallback', () => {
  const { page } = createPage({ root: '  /public/Download/EhViewer  ' });
  assert.equal(page.downloadRoot(), '/public/Download/EhViewer');
  for (const empty of ['', '   ']) {
    page.downloadDirectoryPath = empty;
    assert.equal(page.downloadRoot(), '');
  }
});

test('stored task directories stay fixed when the public default changes or becomes unavailable', () => {
  const { page } = createPage();
  const legacyTask = item({ downloadDir: '  /old/custom/e-123  ' });
  assert.equal(page.galleryDownloadDir(legacyTask), '/old/custom/e-123');
  page.downloadDirectoryPath = '/another/public/root';
  assert.equal(page.downloadTargetPath(legacyTask, 0, 'https://image.example/page.png'),
    '/old/custom/e-123/00000001.png');
  page.downloadDirectoryPath = '';
  assert.equal(page.galleryDownloadDir(legacyTask), '/old/custom/e-123');
  assert.equal(page.downloadTargetPath(legacyTask, 1, 'https://image.example/page.jpg'),
    '/old/custom/e-123/00000002.jpg');
});

test('an unavailable public root cannot produce a root-level target or probe root-level files', () => {
  const { page, accesses } = createPage({ root: '', files: ['/00000001.jpg'] });
  const fresh = item();
  assert.equal(page.galleryDownloadDir(fresh), '');
  assert.equal(page.downloadTargetPath(fresh, 0, 'https://image.example/page.jpg'), '');
  assert.equal(page.existingDownloadPath(fresh, 0), '');
  assert.deepEqual(accesses, []);
});

test('new tasks use the readable gallery title and reserve equal-title galleries on other sites separately', () => {
  const root = '/public/Download/EhViewer';
  const own = item({ site: 'e', downloadDir: `${root}/Gallery` });
  const { page } = createPage({ tasks: [own] });
  assert.equal(page.galleryDownloadDir(item({ site: 'e' })), `${root}/Gallery`);
  assert.equal(page.galleryDownloadDir(item({ site: 'ex' })), `${root}/Gallery [ex-123]`);
  assert.equal(page.downloadTargetPath(item({ site: 'ex' }), 8, 'https://image.example/page.JPEG?token=1#image'),
    `${root}/Gallery [ex-123]/00000009.jpg`);
});

test('gallery directory reservation uses canonical tasks and excludes only the current gallery key', () => {
  const task = item({ downloadDir: ' /reserved/current ' });
  const other = item({ gid: 456, downloadDir: ' /reserved/other ' });
  const otherSite = item({ site: 'ex', downloadDir: '/reserved/ex' });
  const { page } = createPage({ tasks: [task, other, otherSite, item({ gid: 789 })] });
  assert.deepEqual(Array.from(page.reservedGalleryDownloadDirs(task.gid, task.site)), ['/reserved/other', '/reserved/ex']);
});

test('legacy lookup retains the previous custom root and all five historical sandbox layouts', () => {
  const { page, downloadDirName } = createPage({ legacyRoot: ' /previous/custom ', detail: item({ title: 'Legacy/Title' }) });
  assert.deepEqual(Array.from(page.legacyGalleryDownloadDirs(123, 'ex', 'Legacy/Title')), [
    '/public/Download/EhViewer/ex-123',
    '/previous/custom/ex-123',
    `/sandbox/files/${downloadDirName}/ex-123`,
    `/sandbox/files/${downloadDirName}/123`,
    `/sandbox/files/${downloadDirName}/Legacy_Title`,
    '/sandbox/files/download/ex-123',
    '/sandbox/files/download/123'
  ]);
  page.abilityFilesDir = () => '';
  assert.deepEqual(Array.from(page.legacyGalleryDownloadDirs(123, 'e', '')), [
    '/public/Download/EhViewer/e-123', '/previous/custom/e-123'
  ]);
});

test('a missing stored directory remains unchanged when no marker or historical image directory can be recovered', () => {
  const { page, accesses, renames, writes } = createPage();
  const stored = Object.freeze(item({ downloadDir: '/old/stored/e-123' }));
  assert.equal(page.restoreExistingDownloadDirectory(stored), stored);
  assert.ok(accesses.includes('/old/stored/e-123'));
  assert.deepEqual(renames, []);
  assert.deepEqual(writes, []);
});

test('a blank old task adopts the first legacy directory containing an image without mutating the record', () => {
  const { page } = createPage({ legacyRoot: '/old/custom', directories: {
    '/old/custom/e-123': ['.ehviewer', '00000001.JPG', '00000002.jpg.tmp']
  } });
  const old = Object.freeze(item({ downloadDir: '  ' }));
  const oldBefore = JSON.stringify(old);
  const recovered = page.restoreExistingDownloadDirectory(old);
  assert.notEqual(recovered, old);
  assert.equal(recovered.downloadDir, '/old/custom/Gallery');
  assert.equal(old.downloadDir, '  ');
  assert.equal(Object.hasOwn(old, 'imageQuality'), false, 'The legacy input must retain its original shape');
  assert.equal(JSON.stringify(old), oldBefore, 'Recovery must not mutate any legacy field or page error');
  assert.equal(recovered.imageQuality, '', 'Cloning a legacy task supplies the standard empty quality');
  assert.deepEqual({ ...recovered, downloadDir: old.downloadDir }, { ...old, imageQuality: '' });
  page.downloadDirectoryPath = '/changed/public';
  assert.equal(page.galleryDownloadDir(recovered), '/old/custom/Gallery');
});

test('metadata and unfinished files do not pin a blank task to an otherwise empty old directory', () => {
  const { page, downloadDirName } = createPage({ legacyRoot: '/old/custom' });
  const actualDir = `/sandbox/files/${downloadDirName}/e-123`;
  const harness = createPage({ legacyRoot: '/old/custom', directories: {
    '/old/custom/e-123': ['.ehviewer', '00000001.jpg.tmp', 'notes.txt'],
    [actualDir]: ['00001.webp']
  } });
  const recovered = harness.page.restoreExistingDownloadDirectory(item());
  assert.equal(recovered.downloadDir, actualDir.slice(0, actualDir.lastIndexOf('/')) + '/Gallery');
  assert.equal(page.restoreExistingDownloadDirectory(item()).downloadDir, '');
});

test('blank-task recovery includes the historical public site-ID directory and tolerates unavailable older copies', () => {
  const old = Object.freeze(item());
  const { page } = createPage({ legacyRoot: '/old/custom', inaccessible: ['/old/custom/e-123'],
    directories: { '/public/Download/EhViewer/e-123': ['00000001.jpg'] } });
  assert.equal(page.restoreExistingDownloadDirectory(old).downloadDir, '/public/Download/EhViewer/Gallery');
  const retry = createPage({ legacyRoot: '/old/custom', unlistable: ['/old/custom/e-123'], directories: {
    '/old/custom/e-123': ['00000001.jpg'], '/sandbox/files/download/e-123': ['1.png']
  } });
  assert.equal(retry.page.restoreExistingDownloadDirectory(old).downloadDir, '/sandbox/files/download/Gallery');
});

test('stored gallery migration keeps its parent, existing image bytes, progress, quality, and page errors', () => {
  const previous = '/custom/download/e-123';
  const title = '画廊名字 日本語';
  const old = Object.freeze(item({ downloadDir: previous, title, imageQuality: 'original' }));
  const before = JSON.stringify(old);
  const { page, presentFiles, fileTexts, renames } = createPage({
    root: '/new/public', tasks: [old], directories: { [previous]: ['00000001.jpg'] },
    fileTexts: { [`${previous}/00000001.jpg`]: 'existing image bytes' }
  });
  const migrated = page.restoreExistingDownloadDirectory(old);
  const named = `/custom/download/${title}`;
  assert.notEqual(migrated, old);
  assert.equal(migrated.downloadDir, named);
  assert.equal(JSON.stringify(old), before);
  assert.deepEqual({ ...migrated, downloadDir: previous }, { ...old });
  assert.ok(presentFiles.has(`${named}/00000001.jpg`));
  assert.ok(!presentFiles.has(`${previous}/00000001.jpg`));
  assert.equal(fileTexts.get(`${named}/00000001.jpg`), 'existing image bytes');
  assert.ok(renames.some(({ from, to }) => from === previous && to === named));
  assert.deepEqual(JSON.parse(fileTexts.get(`${named}/.e-harmony-gallery.json`)),
    { site: 'e', gid: 123, token: 'token' });
});

test('migration never moves a running task until its request-free worker preparation explicitly allows it', () => {
  const old = item({ downloadDir: '/custom/e-123' });
  const { page, accesses, renames } = createPage({ tasks: [old], runningKeys: ['e-123'],
    directories: { '/custom/e-123': ['1.jpg'] } });
  assert.equal(page.restoreExistingDownloadDirectory(old), old);
  assert.deepEqual(accesses, []);
  assert.deepEqual(renames, []);
  assert.equal(page.restoreExistingDownloadDirectory(old, true).downloadDir, '/custom/Gallery');
});

test('outstanding image requests prohibit migration even with the worker preparation override', () => {
  const old = item({ downloadDir: '/custom/e-123' });
  const { page, accesses, renames, writes } = createPage({ tasks: [old],
    activeRequests: { 'e-123': [{ request: 'in flight' }] },
    directories: { '/custom/e-123': ['1.jpg'] } });
  assert.equal(page.restoreExistingDownloadDirectory(old), old);
  assert.equal(page.restoreExistingDownloadDirectory(old, true), old);
  assert.deepEqual(accesses, []);
  assert.deepEqual(renames, []);
  assert.deepEqual(writes, []);
});

test('a reserved directory belonging to a different task is never migrated or adopted', () => {
  const old = item({ downloadDir: '/custom/shared' });
  const other = item({ gid: 456, downloadDir: '/custom/shared' });
  const { page, renames, writes } = createPage({ tasks: [old, other],
    directories: { '/custom/shared': ['1.jpg'] } });
  assert.equal(page.restoreExistingDownloadDirectory(old), old);
  assert.deepEqual(renames, []);
  assert.deepEqual(writes, []);
});

test('a failed rename keeps the old stored path and existing pages usable', () => {
  const old = item({ downloadDir: '/custom/e-123' });
  const { page, presentFiles } = createPage({ tasks: [old],
    directories: { '/custom/e-123': ['00000001.jpg'] }, renameFailures: ['/custom/e-123'] });
  assert.equal(page.restoreExistingDownloadDirectory(old), old);
  assert.ok(presentFiles.has('/custom/e-123/00000001.jpg'));
  assert.equal(page.existingDownloadPath(old, 0), '/custom/e-123/00000001.jpg');
});

test('a restart after rename recovers the marker from the previous parent and keeps gallery metadata', () => {
  const old = Object.freeze(item({ downloadDir: '/custom/e-123', title: 'New title', imageQuality: 'compressed' }));
  const marker = '/custom/Previous title/.e-harmony-gallery.json';
  const { page, presentFiles } = createPage({ tasks: [old],
    directories: { '/custom/Previous title': ['00000001.jpg', '.e-harmony-gallery.json'] },
    fileTexts: { [marker]: JSON.stringify({ site: 'e', gid: 123, token: 'token' }) } });
  const recovered = page.restoreExistingDownloadDirectory(old);
  assert.equal(recovered.downloadDir, '/custom/New title');
  assert.deepEqual({ ...recovered, downloadDir: old.downloadDir }, { ...old });
  assert.ok(presentFiles.has('/custom/New title/00000001.jpg'));
});

test('existing-page detection checks the fixed task location and accepts historical page names', () => {
  for (const fileName of ['00000001.jpg', '00001.webp', '1.png']) {
    const oldPath = `/old/e-123/${fileName}`;
    const { page, accesses } = createPage({ files: [oldPath, '/public/Download/EhViewer/e-123/00000001.jpg'] });
    assert.equal(page.existingDownloadPath(item({ downloadDir: '/old/e-123' }), 0), oldPath);
    assert.ok(accesses.every((path) => path.startsWith('/old/e-123/')));
  }
});

test('zero-byte files and image-named directories never qualify as existing downloaded pages', () => {
  const zeroPath = '/old/e-123/00000001.jpg';
  const directoryPath = '/old/e-123/00001.jpg';
  const { page, stats } = createPage({ files: [zeroPath], fileSizes: { [zeroPath]: 0 },
    directories: { [directoryPath]: [] } });
  assert.equal(page.existingDownloadPath(item({ downloadDir: '/old/e-123' }), 0), '');
  assert.deepEqual(stats, [zeroPath, directoryPath]);
});

test('existing-page detection skips invalid candidates and accepts a later nonempty historical name', () => {
  const zeroPath = '/old/e-123/00000001.jpg';
  const directoryPath = '/old/e-123/00001.jpg';
  const validPath = '/old/e-123/1.png';
  const { page, stats } = createPage({ files: [zeroPath, validPath], fileSizes: { [zeroPath]: 0 },
    directories: { [directoryPath]: [] } });
  assert.equal(page.existingDownloadPath(item({ downloadDir: '/old/e-123' }), 0), validPath);
  assert.ok(stats.includes(zeroPath));
  assert.ok(stats.includes(directoryPath));
  assert.equal(stats.at(-1), validPath);
});

test('inaccessible file metadata does not prevent checking later downloaded page candidates', () => {
  const unavailablePath = '/old/e-123/00000001.jpg';
  const validPath = '/old/e-123/00001.webp';
  const { page, stats } = createPage({ files: [unavailablePath, validPath], unstatable: [unavailablePath] });
  assert.equal(page.existingDownloadPath(item({ downloadDir: '/old/e-123' }), 0), validPath);
  assert.ok(stats.includes(unavailablePath));
  assert.equal(stats.at(-1), validPath);
});

test('reader lookup prefers a stored task page to current public and historical copies', () => {
  const storedPath = '/saved/public/e-123/00000001.png';
  const { page, uriCalls } = createPage({
    tasks: [item({ downloadDir: '/saved/public/e-123' })],
    files: [storedPath, '/public/Download/EhViewer/e-123/00000001.jpg', '/sandbox/files/download/e-123/1.jpg'],
    publicUris: { [storedPath]: 'file://docs/stored-page' }
  });
  assert.equal(page.readerDownloadedImageUri(0), 'file://docs/stored-page');
  assert.deepEqual(uriCalls, [storedPath]);
});

test('reader lookup finds a title directory by gallery identity without a persisted task record', () => {
  const named = '/public/Download/EhViewer/画廊标题';
  const publicPath = `${named}/00000001.jpg`;
  const { page, uriCalls } = createPage({
    directories: { [named]: ['00000001.jpg', '.e-harmony-gallery.json'] },
    fileTexts: { [`${named}/.e-harmony-gallery.json`]: JSON.stringify({ site: 'e', gid: 123, token: 'token' }) },
    publicUris: { [publicPath]: 'file://docs/title-page' }
  });
  assert.equal(page.readerDownloadedImageUri(0), 'file://docs/title-page');
  assert.deepEqual(uriCalls, [publicPath]);
});

test('reader identity lookup rejects a different site or token and ignores title alone', () => {
  for (const identity of [
    { site: 'ex', gid: 123, token: 'token' }, { site: 'e', gid: 123, token: 'different token' }
  ]) {
    const named = '/public/Download/EhViewer/Gallery';
    const { page, uriCalls } = createPage({
      directories: { [named]: ['00000001.jpg', '.e-harmony-gallery.json'] },
      fileTexts: { [`${named}/.e-harmony-gallery.json`]: JSON.stringify(identity) }
    });
    assert.equal(page.readerDownloadedImageUri(0), '');
    assert.deepEqual(uriCalls, []);
  }
});

test('reader lookup falls back from a missing stored page to current public before legacy pages', () => {
  const publicPath = '/public/Download/EhViewer/e-123/00000001.jpg';
  const { page } = createPage({ tasks: [item({ downloadDir: '/old/e-123' })],
    files: [publicPath, '/sandbox/files/download/e-123/1.jpg'],
    publicUris: { [publicPath]: 'file://docs/current-page' } });
  assert.equal(page.readerDownloadedImageUri(0), 'file://docs/current-page');
});

test('reader lookup skips zero-byte stored pages and public directories before a valid legacy page', () => {
  const zeroPath = '/stored/e-123/00000001.jpg';
  const directoryPath = '/public/Download/EhViewer/e-123/00000001.jpg';
  const validPath = '/sandbox/files/download/e-123/1.png';
  const { page, uriCalls, stats } = createPage({ tasks: [item({ downloadDir: '/stored/e-123' })],
    files: [zeroPath, validPath], fileSizes: { [zeroPath]: 0 }, directories: { [directoryPath]: [] } });
  assert.equal(page.readerDownloadedImageUri(0), `file://${validPath}`);
  assert.deepEqual(uriCalls, [validPath]);
  assert.ok(stats.includes(zeroPath));
  assert.ok(stats.includes(directoryPath));
  assert.equal(stats.at(-1), validPath);
});

test('invalid local page candidates do not create an offline reader page', () => {
  const zeroPath = '/stored/e-123/00000001.jpg';
  const directoryPath = '/public/Download/EhViewer/e-123/00000001.jpg';
  const { page, uriCalls } = createPage({ tasks: [item({ downloadDir: '/stored/e-123' })],
    files: [zeroPath], fileSizes: { [zeroPath]: 0 }, directories: { [directoryPath]: [] } });
  assert.equal(page.readerDownloadedImageUri(0), '');
  assert.equal(page.createLocalReaderPageIfAvailable('local://reader/123/1'), undefined);
  assert.deepEqual(uriCalls, []);
});

test('reader task and public-directory selection keep equal gallery IDs on different sites isolated', () => {
  const ePath = '/saved/e-123/00000001.jpg';
  const exPath = '/saved/ex-123/00000001.jpg';
  const { page, accesses } = createPage({ site: 'ex', tasks: [
    item({ site: 'e', downloadDir: '/saved/e-123' }),
    item({ site: 'ex', downloadDir: '/saved/ex-123' })
  ], files: [ePath, exPath], publicUris: { [ePath]: 'file://docs/e-page', [exPath]: 'file://docs/ex-page' } });
  assert.equal(page.readerDownloadedImageUri(0), 'file://docs/ex-page');
  assert.ok(!accesses.includes(ePath));
});

test('offline lookup still finds an old custom directory when the public root is unavailable', () => {
  const oldPath = '/previous/custom/ex-123/00003.gif';
  const { page } = createPage({ root: '', legacyRoot: '/previous/custom', site: 'ex', files: [oldPath] });
  assert.equal(page.readerDownloadedImageUri(2), `file://${oldPath}`);
});

test('offline reader pages use the resolved local URI without fetching a remote page', () => {
  const oldPath = '/sandbox/files/download/e-123/2.webp';
  const { page } = createPage({ root: '', files: [oldPath] });
  const local = page.createLocalReaderPageIfAvailable('local://reader/123/2');
  assert.deepEqual({ ...local }, {
    pageIndex: 1, pageLabel: '2', pageUrl: 'local://reader/123/2',
    imageUrl: `file://${oldPath}`, originImageUrl: ''
  });
  assert.equal(page.createLocalReaderPageIfAvailable('local://reader/123/3'), undefined);
  assert.equal(page.createLocalReaderPageIfAvailable('invalid-page-url'), undefined);
});

test('missing gallery detail URLs do not prevent legacy offline image lookup', () => {
  const oldPath = '/sandbox/files/download/e-123/1.jpg';
  const { page } = createPage({ root: '', detail: item({ detailUrl: '' }), files: [oldPath] });
  assert.equal(page.readerDownloadedImageUri(0), `file://${oldPath}`);
});

test('an absent reader gallery does not probe files or construct a URI', () => {
  const { page, accesses, uriCalls } = createPage({ detail: item({ gid: 0 }) });
  assert.equal(page.readerDownloadedImageUri(0), '');
  assert.deepEqual(accesses, []);
  assert.deepEqual(uriCalls, []);
});

function originalReceipt(task, fileName, bytes = 1024) {
  return JSON.stringify({ gid: task.gid, site: task.site, token: task.token, pageIndex: 0,
    fileName, bytes, sourceUrl: 'https://original.example/full-page.png' });
}

test('an original task cannot count or skip an unverified older compressed page', () => {
  const dir = '/public/Download/EhViewer/Gallery';
  const task = item({ imageQuality: 'original', downloadDir: dir });
  const { page } = createPage({ tasks: [task], directories: { [dir]: ['00000001.jpg'] } });
  assert.equal(page.existingDownloadPath(task, 0), '');
  assert.equal(page.downloadedFileCountForItem(task), 0);
});

test('an original receipt selects its PNG ahead of an older same-page JPG for resume and reading', () => {
  const dir = '/public/Download/EhViewer/Gallery';
  const task = item({ imageQuality: 'original', downloadDir: dir });
  const path = `${dir}/00000001.png`;
  const { page } = createPage({ tasks: [task], directories: {
    [dir]: ['00000001.jpg', '00000001.png', '.00000001.original.json']
  }, fileTexts: { [`${dir}/.00000001.original.json`]: originalReceipt(task, '00000001.png') },
  publicUris: { [path]: 'file://docs/verified-original' } });
  assert.equal(page.existingDownloadPath(task, 0), path);
  assert.equal(page.downloadedFileCountForItem(task), 1, 'Count a verified page once across image formats');
  assert.equal(page.readerDownloadedImageUri(0), 'file://docs/verified-original');
});

test('completed tasks are not migrated into a separate legacy repair workflow', () => {
  const dir = '/public/Download/EhViewer/Gallery';
  const task = Object.freeze(item({ imageQuality: 'original', downloadDir: dir,
    status: 'complete', downloaded: 1, total: 1, pages: 1 }));
  const { page, presentFiles, persisted } = createPage({ tasks: [task], directories: {
    [dir]: ['00000001.jpg']
  } });
  const [next] = page.reconcileDownloadItemsWithLocalFiles([task]);
  assert.equal(next.status, 'complete');
  assert.equal(next.downloaded, 1);
  assert.equal(next.imageQuality, 'original');
  assert.equal(next.downloadDir, dir);
  assert.ok(presentFiles.has(`${dir}/00000001.jpg`), 'Keep the existing image until its replacement succeeds');
  assert.equal(task.status, 'complete', 'Do not mutate the previous persisted snapshot');
  assert.equal(persisted.some((saved) => saved.status === 'paused'), false);
});

test('verified originals and completed compressed tasks do not turn into repair requests', () => {
  const dir = '/public/Download/EhViewer/Gallery';
  for (const imageQuality of ['original', 'compressed']) {
    const task = item({ imageQuality, downloadDir: dir, status: 'complete', downloaded: 1, total: 1, pages: 1 });
    const { page } = createPage({ tasks: [task], directories: { [dir]: ['00000001.png'] },
      fileTexts: imageQuality === 'original'
        ? { [`${dir}/.00000001.original.json`]: originalReceipt(task, '00000001.png') } : {} });
    const [next] = page.reconcileDownloadItemsWithLocalFiles([task]);
    assert.equal(next.status, 'complete');
    assert.equal(next.downloaded, 1);
  }
});
