import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import { setImmediate } from 'node:timers/promises';
import vm from 'node:vm';

// Execute the production module with controlled picker and file-system results.
// These tests validate authorization/cache/URI logic, not real device grants,
// Downloads visibility, file-system writes, or native FileUri implementation.
// Run with Node.js 22.13+: node --test tests/public-download-directory.test.mjs
const source = readFileSync(new URL('../entry/src/main/ets/download/PublicDownloadDirectory.ets', import.meta.url), 'utf8');
const harnessSource = stripTypeScriptTypes(`(() => {
  ${source.replace(/^import .+;\s*$/gm, '').replace(/\bexport /g, '')}
  return { PublicDownloadDirectory, getPublicDownloadDirectory, openPublicDownloadDirectory, publicDownloadFileUri };
})()`);
const ROOT_URI = 'file://docs/storage/Users/currentUser/Download/com.example.eh';
const ROOT_PATH = '/storage/Users/currentUser/Download/com.example.eh';

function deferred() {
  let resolve;
  let reject;
  const promise = new Promise((resolvePromise, rejectPromise) => {
    resolve = resolvePromise;
    reject = rejectPromise;
  });
  return { promise, resolve, reject };
}

function createModule() {
  const saveCalls = [];
  const accessCalls = [];
  const statCalls = [];
  const mutationCalls = [];
  const saveResults = [];
  const constructorErrors = [];
  const directories = new Map([[ROOT_PATH, { readableWritable: true, directory: true }]]);
  const pathOverrides = new Map();
  const module = vm.runInNewContext(harnessSource, {
    picker: {
      DocumentPickerMode: { DOWNLOAD: 1 },
      DocumentViewPicker: class DocumentViewPicker {
        constructor(context) {
          const error = constructorErrors.shift();
          if (error) throw error;
          this.context = context;
        }
        async save(options) {
          saveCalls.push({ context: this.context, options });
          const result = saveResults.length > 0 ? saveResults.shift() : [ROOT_URI];
          if (result instanceof Error) throw result;
          return result;
        }
      }
    },
    fileUri: {
      FileUri: class FileUri {
        constructor(uri) {
          const parsed = new URL(uri);
          this.scheme = parsed.protocol.slice(0, -1);
          this.path = pathOverrides.has(uri) ? pathOverrides.get(uri) : decodeURIComponent(parsed.pathname);
        }
      }
    },
    fileIo: {
      AccessModeType: { READ_WRITE: 6 },
      async mkdir(...args) {
        mutationCalls.push({ operation: 'mkdir', args });
        throw new Error('unexpected public-directory creation');
      },
      async rename(...args) {
        mutationCalls.push({ operation: 'rename', args });
        throw new Error('unexpected public-directory rename');
      },
      async access(path, mode) {
        accessCalls.push({ path, mode });
        const directory = directories.get(path);
        if (directory?.accessError) throw directory.accessError;
        return directory?.readableWritable ?? false;
      },
      async stat(path) {
        statCalls.push(path);
        const directory = directories.get(path);
        if (!directory) throw new Error('directory deleted');
        if (directory.statError) throw directory.statError;
        return { isDirectory: () => directory.directory };
      }
    }
  });
  return { ...module, saveCalls, accessCalls, statCalls, mutationCalls, saveResults, constructorErrors, directories, pathOverrides };
}

test('concurrent routed callers share one DOWNLOAD picker and the same result', async () => {
  const module = createModule();
  const selection = deferred();
  module.saveResults.push(selection.promise);
  const firstContext = { name: 'first Index' };
  const first = module.getPublicDownloadDirectory(firstContext);
  const second = module.getPublicDownloadDirectory({ name: 'second Index' });
  assert.equal(first, second);
  assert.equal(module.saveCalls.length, 1);
  assert.equal(module.saveCalls[0].context, firstContext);
  assert.deepEqual(Object.keys(module.saveCalls[0].options), ['pickerMode']);
  assert.equal(module.saveCalls[0].options.pickerMode, 1);

  selection.resolve([ROOT_URI]);
  const directory = await first;
  assert.equal(await second, directory);
  assert.ok(directory instanceof module.PublicDownloadDirectory);
  assert.equal(directory.uri, ROOT_URI);
  assert.equal(directory.path, ROOT_PATH);
  assert.deepEqual(module.accessCalls, [{ path: ROOT_PATH, mode: 6 }]);
  assert.deepEqual(module.statCalls, [ROOT_PATH]);
});

test('a cached directory is checked for read/write access and directory type before reuse', async () => {
  const module = createModule();
  const directory = await module.getPublicDownloadDirectory({});
  const reused = await module.getPublicDownloadDirectory({});
  assert.equal(reused, directory);
  assert.equal(module.saveCalls.length, 1);
  assert.equal(module.accessCalls.length, 2);
  assert.equal(module.statCalls.length, 2);
  for (const call of module.accessCalls) assert.equal(call.mode, 6);
});

test('a rejected shared request clears the in-flight promise so callers can retry', async () => {
  const module = createModule();
  const selection = deferred();
  module.saveResults.push(selection.promise);
  const first = module.getPublicDownloadDirectory({});
  const second = module.getPublicDownloadDirectory({});
  const results = Promise.allSettled([first, second]);
  selection.reject(new Error('user cancelled'));
  assert.deepEqual((await results).map((result) => result.status), ['rejected', 'rejected']);
  assert.equal(module.publicDownloadFileUri(`${ROOT_PATH}/page.jpg`), '');
  const retried = await module.getPublicDownloadDirectory({});
  assert.equal(retried.path, ROOT_PATH);
  assert.equal(module.saveCalls.length, 2);
});

test('empty and invalid picker results reject without a private fallback and allow retry', async () => {
  const module = createModule();
  for (const result of [[], [''], ['/data/storage/el2/base/files'], ['content://docs/a'],
    ['file://docs/'], [`${ROOT_URI}?query=x`], [`${ROOT_URI}#fragment`], ['file://docs/%ZZ']]) {
    module.saveResults.push(result);
    await assert.rejects(module.getPublicDownloadDirectory({ filesDir: '/private/files' }));
    assert.equal(module.publicDownloadFileUri('/private/files/a.jpg'), '');
  }
  assert.equal((await module.getPublicDownloadDirectory({})).path, ROOT_PATH);
});

test('a parser result with an empty or relative path cannot become the shared root', async () => {
  const module = createModule();
  for (const path of ['', 'relative/download', '/storage/../private']) {
    module.pathOverrides.set(ROOT_URI, path);
    await assert.rejects(module.getPublicDownloadDirectory({}));
    assert.equal(module.publicDownloadFileUri(`${ROOT_PATH}/a.jpg`), '');
  }
  module.pathOverrides.delete(ROOT_URI);
  assert.equal((await module.getPublicDownloadDirectory({})).path, ROOT_PATH);
});

test('files, missing directories, and denied directory access are rejected and retryable', async () => {
  const module = createModule();
  module.directories.set(ROOT_PATH, { readableWritable: true, directory: false });
  await assert.rejects(module.getPublicDownloadDirectory({}), /公共下载目录/);
  module.directories.delete(ROOT_PATH);
  await assert.rejects(module.getPublicDownloadDirectory({}), /公共下载目录/);
  module.directories.set(ROOT_PATH, { readableWritable: true, directory: true,
    accessError: new Error('permission denied') });
  await assert.rejects(module.getPublicDownloadDirectory({}), /公共下载目录/);
  assert.equal(module.publicDownloadFileUri(`${ROOT_PATH}/a.jpg`), '');
  module.directories.set(ROOT_PATH, { readableWritable: true, directory: true });
  assert.equal((await module.getPublicDownloadDirectory({})).path, ROOT_PATH);
});

test('synchronous picker creation failure also releases the in-flight request for retry', async () => {
  const module = createModule();
  module.constructorErrors.push(new Error('invalid UIAbility context'));
  await assert.rejects(module.getPublicDownloadDirectory({}), /invalid UIAbility/);
  assert.equal((await module.getPublicDownloadDirectory({})).path, ROOT_PATH);
  assert.equal(module.saveCalls.length, 1);
});

test('deleting a cached root invalidates its URI mapping and coalesces directory reacquisition', async () => {
  const module = createModule();
  await module.getPublicDownloadDirectory({});
  module.directories.delete(ROOT_PATH);
  const selection = deferred();
  module.saveResults.push(selection.promise);
  const first = module.getPublicDownloadDirectory({});
  const second = module.getPublicDownloadDirectory({});
  assert.equal(first, second);
  // Drain both host and VM microtask chains before inspecting the pending picker.
  await setImmediate();
  assert.equal(module.saveCalls.length, 2);
  assert.equal(module.publicDownloadFileUri(`${ROOT_PATH}/a.jpg`), '');
  module.directories.set(ROOT_PATH, { readableWritable: true, directory: true });
  selection.resolve([ROOT_URI]);
  assert.equal((await first).path, ROOT_PATH);
});

test('permission loss discards the cached grant and a failed refresh remains retryable', async () => {
  const module = createModule();
  await module.getPublicDownloadDirectory({});
  module.directories.set(ROOT_PATH, { readableWritable: true, directory: true,
    accessError: new Error('permission revoked') });
  module.saveResults.push(new Error('picker unavailable'));
  await assert.rejects(module.getPublicDownloadDirectory({}), /picker unavailable/);
  assert.equal(module.publicDownloadFileUri(`${ROOT_PATH}/a.jpg`), '');
  module.directories.set(ROOT_PATH, { readableWritable: true, directory: true });
  assert.equal((await module.getPublicDownloadDirectory({})).path, ROOT_PATH);
  assert.equal(module.saveCalls.length, 3);
});

test('public child URIs preserve the picker authority and encode each relative segment once', async () => {
  const module = createModule();
  const rootPath = `${ROOT_PATH}/带 空格`;
  const rootUri = `${ROOT_URI}/%E5%B8%A6%20%E7%A9%BA%E6%A0%BC/`;
  module.saveResults.push([rootUri]);
  module.directories.set(rootPath, { readableWritable: true, directory: true });
  const directory = await module.getPublicDownloadDirectory({});
  assert.equal(directory.path, rootPath);
  assert.equal(module.publicDownloadFileUri(rootPath), rootUri);
  assert.equal(module.publicDownloadFileUri(`${rootPath}/书名 01/100% #封面?.jpg`),
    `${rootUri.slice(0, -1)}/%E4%B9%A6%E5%90%8D%2001/100%25%20%23%E5%B0%81%E9%9D%A2%3F.jpg`);
});

test('unrelated, prefix-collision, and traversal paths never borrow the public grant', async () => {
  const module = createModule();
  assert.equal(module.publicDownloadFileUri(`${ROOT_PATH}/a.jpg`), '');
  await module.getPublicDownloadDirectory({});
  for (const path of ['/data/storage/el2/base/files/page.jpg', 'relative/page.jpg',
    `${ROOT_PATH}-other/a.jpg`, `${ROOT_PATH}/../other/a.jpg`, `${ROOT_PATH}/a/../../page.jpg`,
    `${ROOT_PATH}/./page.jpg`, `${ROOT_PATH}//page.jpg`, `${ROOT_PATH}/page\0.jpg`, ROOT_URI]) {
    assert.equal(module.publicDownloadFileUri(path), '', path);
  }
  assert.equal(module.publicDownloadFileUri(`${ROOT_PATH}/e-123/1.jpg`), `${ROOT_URI}/e-123/1.jpg`);
});

test('opening an unprepared directory waits for the DOWNLOAD grant before using the File Manager link', async () => {
  const module = createModule();
  const selection = deferred();
  const launches = [];
  const context = {
    async openLink(link, options) {
      launches.push({ link, options: structuredClone(options) });
    }
  };
  module.saveResults.push(selection.promise);
  const opening = module.openPublicDownloadDirectory(context);
  assert.equal(module.saveCalls.length, 1);
  assert.equal(module.saveCalls[0].context, context);
  assert.deepEqual(launches, []);

  selection.resolve([ROOT_URI]);
  const directory = await opening;
  assert.equal(directory.path, ROOT_PATH);
  assert.equal(directory.uri, ROOT_URI);
  assert.equal(await module.getPublicDownloadDirectory(context), directory);
  assert.deepEqual(launches, [{
    link: 'filemanager://openDirectory',
    options: { appLinkingOnly: false, parameters: { fileUri: ROOT_URI } }
  }]);
  assert.equal(module.saveCalls.length, 1);
  assert.deepEqual(module.mutationCalls, []);
});

test('opening a cached directory passes the original encoded picker URI and its trailing slash unchanged', async () => {
  const module = createModule();
  const rootPath = `${ROOT_PATH}/带 空格`;
  const rootUri = `${ROOT_URI}/%E5%B8%A6%20%E7%A9%BA%E6%A0%BC/`;
  const launches = [];
  const context = {
    async openLink(link, options) {
      launches.push({ link, options: structuredClone(options) });
    }
  };
  module.saveResults.push([rootUri]);
  module.directories.set(rootPath, { readableWritable: true, directory: true });
  const prepared = await module.getPublicDownloadDirectory(context);
  const opened = await module.openPublicDownloadDirectory(context);
  assert.equal(opened, prepared);
  assert.equal(module.saveCalls.length, 1);
  assert.equal(launches[0].options.parameters.fileUri, rootUri);
  assert.notEqual(launches[0].options.parameters.fileUri, rootPath);
  assert.deepEqual(Object.keys(launches[0].options.parameters), ['fileUri']);
  assert.deepEqual(module.mutationCalls, []);
});

test('opening reacquires a revoked grant and launches only with the newly returned directory URI', async () => {
  const module = createModule();
  const selection = deferred();
  const replacementUri = `${ROOT_URI}/authorized-again/`;
  const replacementPath = `${ROOT_PATH}/authorized-again`;
  const launches = [];
  const context = {
    async openLink(link, options) {
      launches.push({ link, options: structuredClone(options) });
    }
  };
  await module.getPublicDownloadDirectory(context);
  module.directories.set(ROOT_PATH, { readableWritable: true, directory: true,
    accessError: new Error('permission revoked') });
  module.saveResults.push(selection.promise);
  const opening = module.openPublicDownloadDirectory(context);
  await setImmediate();
  assert.equal(module.saveCalls.length, 2);
  assert.deepEqual(launches, []);
  assert.equal(module.publicDownloadFileUri(`${ROOT_PATH}/a.jpg`), '');

  module.directories.set(replacementPath, { readableWritable: true, directory: true });
  selection.resolve([replacementUri]);
  const directory = await opening;
  assert.equal(directory.uri, replacementUri);
  assert.equal(launches[0].options.parameters.fileUri, replacementUri);
  assert.deepEqual(module.mutationCalls, []);
});

test('opening never launches for missing, unreadable, or non-directory picker results', async (t) => {
  for (const [name, state] of [
    ['missing', undefined],
    ['read/write denied', { readableWritable: false, directory: true }],
    ['permission error', { readableWritable: true, directory: true, accessError: new Error('permission denied') }],
    ['regular file', { readableWritable: true, directory: false }]
  ]) {
    await t.test(name, async () => {
      const module = createModule();
      let launchCount = 0;
      const context = { async openLink() { launchCount += 1; } };
      if (state) module.directories.set(ROOT_PATH, state);
      else module.directories.delete(ROOT_PATH);
      await assert.rejects(module.openPublicDownloadDirectory(context), /公共下载目录/);
      assert.equal(launchCount, 0);
      assert.deepEqual(module.mutationCalls, []);
    });
  }
});

test('opening does not launch a stale cached URI when permission refresh fails', async () => {
  const module = createModule();
  let launchCount = 0;
  const context = { async openLink() { launchCount += 1; } };
  await module.getPublicDownloadDirectory(context);
  module.directories.delete(ROOT_PATH);
  module.saveResults.push(new Error('DOWNLOAD authorization failed'));
  await assert.rejects(module.openPublicDownloadDirectory(context), /DOWNLOAD authorization failed/);
  assert.equal(launchCount, 0);
  assert.equal(module.publicDownloadFileUri(`${ROOT_PATH}/a.jpg`), '');
  assert.deepEqual(module.mutationCalls, []);
});

test('synchronous and asynchronous File Manager failures reject and retain the valid grant for retry', async (t) => {
  for (const [name, fail] of [
    ['synchronous throw', () => { throw new Error('File Manager unavailable'); }],
    ['asynchronous rejection', async () => { throw new Error('File Manager unavailable'); }]
  ]) {
    await t.test(name, async () => {
      const module = createModule();
      const context = { openLink: fail };
      const prepared = await module.getPublicDownloadDirectory(context);
      await assert.rejects(module.openPublicDownloadDirectory(context), /File Manager unavailable/);
      assert.equal(module.publicDownloadFileUri(`${ROOT_PATH}/a.jpg`), `${ROOT_URI}/a.jpg`);
      assert.equal(await module.getPublicDownloadDirectory(context), prepared);
      assert.equal(module.saveCalls.length, 1);

      let successfulLaunchCount = 0;
      context.openLink = async () => { successfulLaunchCount += 1; };
      assert.equal(await module.openPublicDownloadDirectory(context), prepared);
      assert.equal(successfulLaunchCount, 1);
      assert.equal(module.saveCalls.length, 1);
      assert.deepEqual(module.mutationCalls, []);
    });
  }
});
