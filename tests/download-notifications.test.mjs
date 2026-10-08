import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';

// Execute Index's production notification/background synchronization methods.
// Deferred service replies and deterministic timers model races across routed
// pages. This does not validate device permissions, OS services, or UI visuals.
// Run with Node.js 22.13+: node --test tests/download-notifications.test.mjs
const source = readFileSync(new URL('../entry/src/main/ets/pages/Index.ets', import.meta.url), 'utf8');
const modelSource = readFileSync(new URL('../entry/src/main/ets/download/DownloadModels.ets', import.meta.url), 'utf8');
const appSource = readFileSync(new URL('../entry/src/main/ets/constants/AppConstants.ets', import.meta.url), 'utf8');

function productionMethod(name) {
  const start = source.search(new RegExp(`\\n  private (?:async )?${name}\\(`));
  assert.notEqual(start, -1, `Missing production method: ${name}`);
  const tail = source.slice(start + 1);
  const end = tail.slice(1).search(/\n  (?:private |aboutTo|@Builder)/);
  assert.notEqual(end, -1, `Missing end of production method: ${name}`);
  return tail.slice(0, end + 1);
}

const globals = source.split('\n')
  .filter((line) => /^(?:let|const) (?:sharedDownload\w+|DOWNLOAD_RUNTIME_\w+|DIAG_DOMAIN|DIAG_TAG)\b/.test(line)).join('\n');
const constants = [...modelSource.split('\n'), ...appSource.split('\n')]
  .filter((line) => /^export const (?:DOWNLOAD_(?:STATUS_\w+|DEFAULT_LABEL|NOTIFICATION_\w+|BACKGROUND_MODE|ROUTE_ACTION_\w+)|APP_(?:BUNDLE|ABILITY)_NAME|LIBRARY_DOWNLOADS)\b/.test(line))
  .join('\n').replace(/^export /gm, '');
const fieldNames = [
  'downloadItems', 'downloadWorkerRunning', 'downloadActiveKey', 'downloadWaitKeys',
  'downloadCancelKeys', 'downloadRemovedKeys', 'downloadStartRequestedKeys', 'downloadRunGenerations',
  'downloadPageTransferFractions', 'downloadActiveRequests', 'downloadNotificationPermissionAsked',
  'downloadRuntimeHeartbeatLastWriteAt', 'downloadQueueRevision', 'downloadManagerStatus',
  'downloadRuntimeItemsJson', 'downloadRuntimeActiveKey', 'downloadRuntimeWorkerRunning', 'downloadRuntimeRevision'
];
const fields = fieldNames.map((name) => {
  const field = source.split('\n').find((line) =>
    new RegExp(`\\b${name}\\??\\s*:`).test(line) && line.trimEnd().endsWith(';'));
  assert.ok(field, `Missing production field: ${name}`);
  return field;
}).join('\n').replace(/@\w+(?:\([^)]*\))?\s*/g, '');
const methods = [
  'downloadKey', 'toDownloadItem', 'cloneDownloadItem', 'normalizeDownloadStatus',
  'runtimeStringArray', 'updateRuntimeStringArray', 'isRuntimeStringArrayMarked',
  'publishDownloadRuntimeStorage', 'writeDownloadRuntimeHeartbeat', 'runtimeDownloadItemsSnapshot',
  'findDownloadItem', 'findDownloadItemByKey', 'downloadItemsSource', 'downloadDisplayItem',
  'isDownloadKeyCancelled', 'isDownloadKeyRemoved', 'markDownloadKeyRemoved',
  'isDownloadKeyRunningInCurrentProcess', 'activeDownloadRuntimeKey', 'isDownloadItemRunning', 'isDownloadItemQueued',
  'publishSharedDownloadItems', 'saveDownloadItems', 'bumpDownloadQueueRevision',
  'replaceDownloadItem', 'replaceDownloadItemInternal', 'currentDownloadRunGeneration', 'bumpDownloadRunGeneration',
  'pauseDownloadItem', 'pauseAllDownloads', 'removeSharedDownloadWaitKey', 'clearDownloadTransferProgress', 'cancelDownloadActiveRequests',
  'activeDownloadItem', 'downloadRuntimeActive', 'downloadPageTransferFractionSum',
  'downloadProgressRatio', 'downloadProgressText'
];
// Include every helper in the production notification/background block so
// method refactoring cannot silently replace the synchronization with a stub.
const runtimeStart = source.indexOf('\n  private shortDownloadNotificationText(');
const runtimeEnd = source.indexOf('\n  private updateDownloadStatePolling(', runtimeStart);
assert.ok(runtimeStart >= 0 && runtimeEnd > runtimeStart, 'Missing production notification/runtime block');
const runtimeMethods = source.slice(runtimeStart, runtimeEnd);
const harnessSource = stripTypeScriptTypes(`(() => {
  ${globals}
  ${constants}
  return {
    Harness: class DownloadNotificationHarness {
      ${fields}
      ${methods.map(productionMethod).join('\n')}
      ${runtimeMethods}
    },
    seed(items: DownloadQueueItem[], running: boolean = false, activeKey: string = '', waitKeys: string[] = []): void {
      sharedDownloadItemsSnapshot = items;
      sharedDownloadItemsInitialized = true;
      sharedDownloadWorkerRunning = running;
      sharedDownloadActiveKey = activeKey;
      sharedDownloadWaitKeys = waitKeys;
    },
    tracking(key: string): object {
      return { id: sharedDownloadNotificationIds.get(key), label: sharedDownloadNotificationLabels.get(key),
        state: sharedDownloadNotificationStates.get(key), lastAt: sharedDownloadNotificationLastAt.get(key) };
    },
    background(): object {
      return { running: sharedDownloadBackgroundRunning, starting: sharedDownloadBackgroundStarting,
        taskId: sharedDownloadBackgroundTaskId, context: sharedDownloadBackgroundContext,
        notificationId: sharedDownloadBackgroundNotificationId,
        handles: Array.from(sharedDownloadBackgroundTaskHandles.entries()),
        retired: Array.from(sharedDownloadBackgroundRetiredIds),
        notificationIds: Array.from(sharedDownloadBackgroundNotificationIds.entries()) };
    },
    trackingKeys(): string[] { return Array.from(sharedDownloadNotificationIds.keys()); },
    syncing(): object {
      return { inFlight: sharedDownloadRuntimeSyncInFlight, pending: sharedDownloadRuntimeSyncPending,
        force: sharedDownloadRuntimeSyncPendingForce };
    },
    config: { group: DOWNLOAD_NOTIFICATION_GROUP, prefix: DOWNLOAD_NOTIFICATION_LABEL_PREFIX,
      backgroundMode: DOWNLOAD_BACKGROUND_MODE, bundle: APP_BUNDLE_NAME, ability: APP_ABILITY_NAME }
  };
})()`);

function item(overrides = {}) {
  return {
    gid: 123, site: 'e', token: 'token', title: 'Gallery', titleJpn: '', cover: '',
    detailUrl: 'https://gallery.example/g/123/token/', uploader: 'uploader',
    categoryLabel: 'Manga', posted: 'posted', pages: 100, language: 'Japanese', rating: 4,
    status: 'downloading', label: 'default', queuedAt: 'queued', lastAction: 'downloading',
    downloaded: 12, total: 100, failedCount: 0, archiveUri: '', createdAt: 'created',
    updatedAt: 'updated', currentPage: 12, currentPageLabel: '12/100',
    speedBytesPerSecond: 4096, remainingSeconds: 30, downloadDir: '/public/e-123',
    error: '', pageErrors: [], ...overrides
  };
}

function deferred() {
  let resolve;
  const promise = new Promise((accept) => { resolve = accept; });
  return { promise, resolve };
}

async function settle() {
  for (let count = 0; count < 40; count++) await Promise.resolve();
}

function createRuntime(options = {}) {
  const storage = new Map();
  const preferences = new Map();
  const notifications = new Map();
  const backgroundTasks = new Map();
  const cancelledTaskIds = new Set();
  const cancelListeners = new Set();
  const timers = new Map();
  const calls = { permission: [], agents: [], publish: [], cancel: [], notificationQueries: [],
    start: [], stop: [], backgroundQueries: [], subscriptions: [] };
  const plans = Object.fromEntries(['permission', 'agent', 'publish', 'cancel', 'notificationQuery', 'start', 'stop', 'backgroundQuery']
    .map((name) => [name, [...(options[`${name}Plans`] ?? [])]]));
  let nextTimerId = 1;
  let nextTaskId = 7;
  let nowLabel = 0;
  let runtime;
  const notificationKey = (id, label) => `${id}:${label}`;
  async function reply(name, fallback, ...args) {
    const next = plans[name].length > 0 ? plans[name].shift() : fallback;
    if (next instanceof Error) throw next;
    return await (typeof next === 'function' ? next(...args) : next);
  }
  function taskInfo(id, context, overrides = {}) {
    return {
      continuousTaskId: id, context, abilityName: runtime.config.ability,
      notificationId: 4000 + id,
      wantAgentBundleName: runtime.config.bundle, wantAgentAbilityName: runtime.config.ability,
      isFromWebView: false, backgroundModes: [runtime.config.backgroundMode], ...overrides
    };
  }
  function liveNotification(id, label = `bgmode_${id}`, overrides = {}) {
    return { id, label, content: { notificationContentType: 4,
      systemLiveView: { typeCode: 8, title: 'Service download' } }, ...overrides };
  }
  function emitCancel(id) {
    cancelledTaskIds.add(id);
    backgroundTasks.delete(id);
    for (const callback of cancelListeners) callback({ id });
  }
  class ContinuousTaskRequest {}
  runtime = vm.runInNewContext(harnessSource, {
    AppStorage: {
      get: (key) => storage.get(key), setOrCreate: (key, value) => storage.set(key, value)
    },
    clampNumber: (value, minimum, maximum) => Math.min(Math.max(value, minimum), maximum),
    formatBytesPerSecond: (value) => `${value} B/s`, formatRemainingSeconds: (value) => `${value}s`,
    hilog: { info() {}, warn() {}, error() {} },
    setTimeout(callback, delay) {
      const id = nextTimerId++;
      timers.set(id, { callback, delay });
      return id;
    },
    clearTimeout: (id) => timers.delete(id),
    wantAgent: {
      OperationType: { START_ABILITY: 1 }, WantAgentFlags: { UPDATE_PRESENT_FLAG: 1 },
      async getWantAgent(info) {
        calls.agents.push(info);
        return await reply('agent', { requestCode: info.requestCode }, info);
      }
    },
    notificationManager: {
      SlotType: { LIVE_VIEW: 4 }, ContentType: { NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW: 4 },
      async addSlot() {}, async requestEnableNotification() {},
      async isNotificationEnabled() { calls.permission.push(true); return await reply('permission', true); },
      async publish(request) {
        calls.publish.push(request);
        await reply('publish', undefined, request);
        // Service completion can arrive after a cancellation of the same handle.
        const existing = Array.from(notifications.values()).find((entry) => entry.id === request.id);
        const serviceLabel = request.label === '' ? (existing?.label ?? `bgmode_${request.id}`) : request.label;
        notifications.set(notificationKey(request.id, serviceLabel), { ...request, label: serviceLabel });
      },
      async cancel(id, label) {
        calls.cancel.push({ id, label });
        await reply('cancel', undefined, id, label);
        const key = notificationKey(id, label ?? '');
        if (!notifications.has(key)) throw new Error('No notification matches the requested ID and label');
        notifications.delete(key);
      },
      async getActiveNotifications() {
        calls.notificationQueries.push(true);
        return await reply('notificationQuery', Array.from(notifications.values()));
      }
    },
    backgroundTaskManager: {
      ContinuousTaskRequest,
      BackgroundTaskMode: { MODE_DATA_TRANSFER: 1 },
      BackgroundTaskSubmode: { SUBMODE_LIVE_VIEW_NOTIFICATION: 3 },
      on(event, callback) { calls.subscriptions.push(event); cancelListeners.add(callback); },
      async startBackgroundRunning(context, request, ...extra) {
        calls.start.push({ context, request, extra });
        const idForReply = nextTaskId++;
        const result = await reply('start', { continuousTaskId: idForReply, notificationId: 4000 + idForReply }, context, request);
        const id = result.continuousTaskId ?? -1;
        if (!cancelledTaskIds.has(id)) {
          backgroundTasks.set(id, taskInfo(id, context, { notificationId: result.notificationId }));
          const notification = liveNotification(result.notificationId);
          notifications.set(notificationKey(notification.id, notification.label), notification);
        }
        return result;
      },
      async stopBackgroundRunning(context, id) {
        calls.stop.push({ context, id });
        await reply('stop', undefined, context, id);
        if (id !== undefined) {
          backgroundTasks.delete(id);
          for (const callback of cancelListeners) callback({ id });
        } else {
          for (const [key, task] of backgroundTasks) {
            if (task.context === context) backgroundTasks.delete(key);
          }
        }
      },
      async getAllContinuousTasks(context, includeSuspended) {
        calls.backgroundQueries.push({ context, includeSuspended });
        return await reply('backgroundQuery', Array.from(backgroundTasks.values()), context, includeSuspended);
      }
    }
  });
  const links = {
    downloadRuntimeItemsJson: 'download_runtime_items_snapshot',
    downloadRuntimeActiveKey: 'download_runtime_active_key',
    downloadRuntimeWorkerRunning: 'download_runtime_worker_running',
    downloadRuntimeRevision: 'download_runtime_revision'
  };

  function page(context = { name: 'context' }) {
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
    page.readString = (key, fallback) => preferences.get(key) ?? fallback;
    page.writeValue = (key, value) => preferences.set(key, value);
    page.parseDownloadItems = (raw) => JSON.parse(raw);
    page.nowLabel = () => `updated-${++nowLabel}`;
    page.scheduleDownloadItemPersist = () => {};
    page.reconcileDownloadViewMode = () => {};
    page.updateDownloadStatePolling = () => {};
    page.uiAbilityContext = () => context;
    return page;
  }

  async function idle() {
    for (let count = 0; count < 300; count++) {
      await Promise.resolve();
      if (!runtime.syncing().inFlight) { await settle(); return; }
    }
    assert.fail('Production runtime drain did not become idle; resolve pending service replies first');
  }
  async function runTimers() {
    const pending = Array.from(timers.entries());
    for (const [id, timer] of pending) {
      timers.delete(id);
      timer.callback();
    }
    await idle();
  }
  return { ...runtime, page, idle, runTimers, calls, plans, storage, preferences, notifications, backgroundTasks,
    timers, taskInfo, liveNotification, emitCancel, notificationKey, ContinuousTaskRequest };
}

for (const stage of ['permission', 'agent']) {
  test(`pausing while notification ${stage} is pending prevents a new publication`, async () => {
    const gate = deferred();
    const runtime = createRuntime();
    runtime.seed([item()], true, 'e-123');
    const owner = runtime.page();
    const observer = runtime.page();
    await owner.startDownloadBackgroundTask();
    runtime.plans[stage].push(gate.promise);
    const baseline = stage === 'permission' ? runtime.calls.permission.length : runtime.calls.agents.length;
    const publish = owner.publishDownloadNotificationForItem(item(), true);
    await settle();
    assert.equal(stage === 'permission' ? runtime.calls.permission.length : runtime.calls.agents.length, baseline + 1);
    observer.pauseDownloadItem(item());
    await runtime.idle();
    gate.resolve(stage === 'permission' ? true : {});
    await publish;
    await runtime.idle();
    assert.equal(runtime.calls.publish.length, 0);
    assert.equal(runtime.calls.start.length, 1, 'The original task is stopped without starting another');
    assert.equal(runtime.backgroundTasks.size, 0);
    assert.equal(runtime.notifications.size, 0);
    assert.equal(runtime.tracking('e-123').id, undefined);
  });
}

test('progress changed during WantAgent creation updates the system notification from current canonical data', async () => {
  const gate = deferred();
  const runtime = createRuntime();
  runtime.seed([item()], true, 'e-123');
  const page = runtime.page();
  await page.startDownloadBackgroundTask();
  const systemId = runtime.background().notificationId;
  runtime.plans.agent.push(gate.promise);
  const publish = page.publishDownloadNotificationForItem(item(), true);
  await settle();
  page.replaceDownloadItem(item({ downloaded: 47, title: 'Latest title', lastAction: 'Latest action' }));
  gate.resolve({});
  await publish;
  assert.equal(runtime.calls.publish.length, 1);
  const request = runtime.calls.publish[0];
  assert.equal(request.id, systemId);
  assert.equal(request.label, '');
  assert.equal(request.content.notificationContentType, 4);
  assert.equal(request.content.systemLiveView.typeCode, 8);
  assert.equal(request.content.systemLiveView.progress.currentValue, 47);
  assert.equal(request.content.systemLiveView.progress.maxValue, 100);
  assert.equal(request.content.systemLiveView.title, 'Latest title');
  assert.equal(request.content.systemLiveView.additionalText, 'Latest action');
  assert.ok(request.content.systemLiveView.text.includes('47/100'));
  assert.equal(runtime.notifications.size, 1, 'An update replaces the service notification instead of making another');
  assert.equal(Array.from(runtime.notifications.values())[0].label, `bgmode_${systemId}`);
});

for (const stage of ['permission', 'agent']) {
  test(`a newer run generation invalidates a notification still awaiting ${stage}`, async () => {
    const gate = deferred();
    const runtime = createRuntime();
    runtime.seed([item()], true, 'e-123');
    const page = runtime.page();
    await page.startDownloadBackgroundTask();
    runtime.plans[stage].push(gate.promise);
    const publish = page.publishDownloadNotificationForItem(item(), true);
    await settle();
    page.bumpDownloadRunGeneration('e-123');
    page.replaceDownloadItem(item({ downloaded: 19 }));
    gate.resolve(stage === 'permission' ? true : {});
    await publish;
    assert.equal(page.currentDownloadNotificationItem('e-123')?.downloaded, 19);
    assert.equal(runtime.calls.publish.length, 0);
    assert.equal(runtime.background().running, true, 'The newer gallery run still owns the background task');
  });
}

test('a late successful publish restores its cleared handle and cancels the resurrected service notification', async () => {
  const gate = deferred();
  const runtime = createRuntime();
  runtime.seed([item()], true, 'e-123');
  const owner = runtime.page();
  const observer = runtime.page();
  await owner.startDownloadBackgroundTask();
  runtime.plans.publish.push(gate.promise);
  const publish = owner.publishDownloadNotificationForItem(item(), true);
  await settle();
  assert.equal(runtime.calls.publish.length, 1);
  const request = runtime.calls.publish[0];
  observer.pauseDownloadItem(item());
  await runtime.idle();
  assert.equal(runtime.tracking('e-123').id, undefined);
  assert.equal(runtime.notifications.size, 0);
  gate.resolve();
  await publish;
  await runtime.idle();
  assert.ok(runtime.calls.cancel.filter((call) => call.id === request.id && call.label === `bgmode_${request.id}`).length >= 2);
  assert.equal(runtime.notifications.size, 0);
  for (const value of Object.values(runtime.tracking('e-123'))) assert.equal(value, undefined);
});

test('failed empty-label cancellation discovers the real service label and retains it for a timer retry', async () => {
  const runtime = createRuntime();
  runtime.seed([item()], true, 'e-123');
  const page = runtime.page();
  await page.startDownloadBackgroundTask();
  await page.publishDownloadNotificationForItem(item(), true);
  const before = runtime.tracking('e-123');
  runtime.seed([item({ status: 'paused' })]);
  await page.stopDownloadBackgroundTask();
  runtime.plans.cancel.push(new Error('Empty label not found'), new Error('Service temporarily unavailable'));
  await page.cancelDownloadNotificationByKey('e-123');
  assert.equal(runtime.tracking('e-123').id, before.id);
  assert.equal(runtime.tracking('e-123').label, `bgmode_${before.id}`);
  assert.equal(runtime.tracking('e-123').state, before.state);
  assert.equal(runtime.notifications.size, 1);
  assert.equal(runtime.timers.size, 1);
  assert.deepEqual(runtime.calls.cancel.slice(-2), [{ id: before.id, label: undefined },
    { id: before.id, label: `bgmode_${before.id}` }]);
  await runtime.runTimers();
  assert.equal(runtime.notifications.size, 0);
  assert.equal(runtime.tracking('e-123').id, undefined);
  assert.equal(runtime.trackingKeys().length, 0);
  assert.equal(runtime.timers.size, 0);
});

for (const method of ['cancelAllDownloadNotifications', 'cancelStaleDownloadNotifications']) {
  test(`${method} rechecks each candidate after awaits and retains a newly active sibling`, async () => {
    const gate = deferred();
    const runtime = createRuntime({ cancelPlans: [gate.promise] });
    runtime.seed([item({ status: 'paused' }), item({ gid: 456, status: 'paused' })]);
    const page = runtime.page();
    for (const key of ['e-123', 'e-456']) {
      const id = page.downloadNotificationIdForKey(key);
      const label = page.downloadNotificationLabelForKey(key);
      runtime.notifications.set(runtime.notificationKey(id, label), { id, label, groupName: runtime.config.group });
    }
    const cancel = page[method]();
    await settle();
    assert.equal(runtime.calls.cancel.length, 1);
    runtime.seed([item({ status: 'paused' }), item({ gid: 456 })], true, 'e-456');
    gate.resolve();
    await cancel;
    assert.equal(runtime.calls.cancel.length, 1);
    const active = runtime.tracking('e-456');
    assert.equal(runtime.notifications.has(runtime.notificationKey(active.id, active.label)), true);
  });
}

test('recovery preserves the current live ID and unrelated notifications while removing legacy and live download orphans', async () => {
  const runtime = createRuntime();
  runtime.seed([item()], true, 'e-123');
  const page = runtime.page();
  await page.startDownloadBackgroundTask();
  const currentId = runtime.background().notificationId;
  const legacyCurrent = { id: page.downloadNotificationIdForKey('e-123'),
    label: page.downloadNotificationLabelForKey('e-123'), groupName: runtime.config.group };
  const entries = [
    legacyCurrent,
    { id: 20, label: `${runtime.config.prefix}old`, groupName: runtime.config.group },
    { id: 21, label: `${runtime.config.prefix}other`, groupName: 'other-group' },
    { id: 22, label: 'non-download', groupName: runtime.config.group },
    { label: `${runtime.config.prefix}missing-id`, groupName: runtime.config.group },
    runtime.liveNotification(23),
    runtime.liveNotification(24, 'app-live', { groupName: runtime.config.group }),
    runtime.liveNotification(25, 'other-live', { groupName: 'other-group' }),
    runtime.liveNotification(26, 'bgmode_other', { content: { notificationContentType: 4, systemLiveView: { typeCode: 2 } } })
  ];
  for (const entry of entries) runtime.notifications.set(runtime.notificationKey(entry.id, entry.label), entry);
  await page.recoverStaleDownloadNotifications();
  assert.deepEqual(runtime.calls.cancel.map((call) => call.id).sort((a, b) => a - b),
    [legacyCurrent.id, 20, 23, 24].sort((a, b) => a - b));
  assert.equal(runtime.notifications.size, 6);
  assert.equal(runtime.notifications.has(runtime.notificationKey(currentId, `bgmode_${currentId}`)), true);
});

test('recovery rechecks the current live ID when a background task starts during notification enumeration', async () => {
  const gate = deferred();
  const runtime = createRuntime({ notificationQueryPlans: [gate.promise] });
  runtime.seed([item()], true, 'e-123');
  const page = runtime.page();
  const recover = page.recoverStaleDownloadNotifications();
  await settle();
  await page.startDownloadBackgroundTask();
  const currentId = runtime.background().notificationId;
  gate.resolve(Array.from(runtime.notifications.values()));
  await recover;
  assert.equal(runtime.calls.cancel.length, 0);
  assert.equal(runtime.notifications.has(runtime.notificationKey(currentId, `bgmode_${currentId}`)), true);
});

test('two routed pages share one serial runtime drain, preserve pending force, and create one background task', async () => {
  const gate = deferred();
  const runtime = createRuntime({ publishPlans: [gate.promise] });
  runtime.seed([item()], true, 'e-123');
  const context = { name: 'owner' };
  const owner = runtime.page(context);
  const observer = runtime.page({ name: 'observer' });
  owner.queueDownloadRuntimeStateSync(false);
  await settle();
  assert.equal(runtime.calls.publish.length, 1);
  observer.queueDownloadRuntimeStateSync(true);
  await settle();
  assert.equal(runtime.calls.publish.length, 1, 'Observer cannot start a concurrent sync while publish is pending');
  assert.equal(runtime.syncing().inFlight, true);
  assert.equal(runtime.syncing().pending, true);
  assert.equal(runtime.syncing().force, true);
  gate.resolve();
  await runtime.idle();
  assert.equal(runtime.calls.publish.length, 2, 'Pending force refreshes the unchanged notification');
  assert.equal(runtime.calls.start.length, 1);
  assert.equal(runtime.calls.start[0].context, context);
  assert.ok(runtime.calls.start[0].request instanceof runtime.ContinuousTaskRequest);
  assert.equal(runtime.calls.start[0].extra.length, 0);
  assert.deepEqual(Array.from(runtime.calls.start[0].request.backgroundTaskModes), [1]);
  assert.deepEqual(Array.from(runtime.calls.start[0].request.backgroundTaskSubmodes), [3]);
  assert.equal(runtime.calls.start[0].request.combinedTaskNotification, false);
  assert.equal(runtime.background().running, true);
  assert.equal(runtime.notifications.size, 1);
  assert.equal(runtime.syncing().inFlight, false);
  assert.equal(runtime.syncing().pending, false);
  assert.equal(runtime.calls.subscriptions.length, 1);
});

test('an observer pause queued during publication drains to no notification or background task', async () => {
  const gate = deferred();
  const runtime = createRuntime({ publishPlans: [gate.promise] });
  runtime.seed([item()], true, 'e-123');
  const owner = runtime.page();
  const observer = runtime.page();
  owner.queueDownloadRuntimeStateSync(true);
  await settle();
  assert.equal(runtime.calls.publish.length, 1);
  observer.pauseDownloadItem(item());
  assert.equal(runtime.syncing().pending, true);
  gate.resolve();
  await runtime.idle();
  assert.equal(runtime.notifications.size, 0);
  assert.equal(runtime.calls.start.length, 1);
  assert.equal(runtime.calls.stop.length, 1);
  assert.equal(runtime.backgroundTasks.size, 0);
  assert.equal(runtime.syncing().inFlight, false);
  assert.equal(runtime.syncing().pending, false);
});

test('switching galleries updates one live service ID without cancelling the shared background notification', async () => {
  const runtime = createRuntime();
  runtime.seed([item()], true, 'e-123');
  const page = runtime.page();
  await page.syncDownloadRuntimeState(true);
  const systemId = runtime.background().notificationId;
  const cancellationsBeforeSwitch = runtime.calls.cancel.length;
  runtime.seed([item({ status: 'complete', downloaded: 100 }),
    item({ gid: 456, title: 'Next gallery', downloaded: 25 })], true, 'e-456');
  await page.syncDownloadRuntimeState(true);
  assert.equal(runtime.calls.start.length, 1);
  assert.equal(runtime.calls.cancel.length, cancellationsBeforeSwitch);
  assert.equal(runtime.background().notificationId, systemId);
  assert.equal(runtime.notifications.size, 1);
  const live = Array.from(runtime.notifications.values())[0];
  assert.equal(live.id, systemId);
  assert.equal(live.label, `bgmode_${systemId}`);
  assert.equal(live.content.systemLiveView.title, 'Next gallery');
  assert.equal(live.content.systemLiveView.progress.currentValue, 25);
});

for (const taskId of [0, 7]) {
  test(`late background task ${taskId} is stopped through its original owner after an observer pause`, async () => {
    const gate = deferred();
    const runtime = createRuntime({ startPlans: [gate.promise] });
    runtime.seed([item()], true, 'e-123');
    const context = { name: 'owner' };
    const owner = runtime.page(context);
    const observer = runtime.page({ name: 'observer' });
    owner.queueDownloadRuntimeStateSync(true);
    await settle();
    assert.equal(runtime.calls.start.length, 1);
    await observer.startDownloadBackgroundTask();
    assert.equal(runtime.calls.start.length, 1, 'Global starting flag blocks a second routed owner');
    observer.pauseDownloadItem(item());
    gate.resolve({ continuousTaskId: taskId, notificationId: 4000 + taskId });
    await runtime.idle();
    assert.deepEqual(runtime.calls.stop, [{ context, id: taskId }]);
    assert.equal(runtime.backgroundTasks.size, 0);
    assert.equal(runtime.background().running, false);
    assert.equal(runtime.background().starting, false);
    assert.equal(runtime.background().handles.length, 0);
    assert.equal(runtime.notifications.size, 0);
  });
}

test('pausing while a background WantAgent is pending prevents startBackgroundRunning', async () => {
  const gate = deferred();
  const runtime = createRuntime({ agentPlans: [gate.promise] });
  runtime.seed([item()], true, 'e-123');
  const owner = runtime.page();
  owner.queueDownloadRuntimeStateSync(true);
  await settle();
  assert.equal(runtime.calls.agents.length, 1);
  owner.pauseDownloadItem(item());
  gate.resolve({});
  await runtime.idle();
  assert.equal(runtime.calls.start.length, 0);
  assert.equal(runtime.background().running, false);
  assert.equal(runtime.background().starting, false);
});

test('a rejected ContinuousTaskRequest never falls back to a legacy start or treats 9800005 as success', async () => {
  const failure = Object.assign(new Error('Continuous task verification failed'), { code: 9800005 });
  const runtime = createRuntime({ startPlans: [failure] });
  runtime.seed([item()], true, 'e-123');
  await runtime.page().startDownloadBackgroundTask();
  assert.equal(runtime.calls.start.length, 1);
  assert.ok(runtime.calls.start[0].request instanceof runtime.ContinuousTaskRequest);
  assert.equal(runtime.calls.start[0].extra.length, 0);
  assert.equal(runtime.background().running, false);
  assert.equal(runtime.backgroundTasks.size, 0);
});

test('failed precise stop retires its service handle and a timer retry uses the same owner and ID', async () => {
  const runtime = createRuntime({ stopPlans: [new Error('Stop unavailable')] });
  runtime.seed([item()], true, 'e-123');
  const context = { name: 'owner' };
  const owner = runtime.page(context);
  const observer = runtime.page({ name: 'observer' });
  await owner.startDownloadBackgroundTask();
  const taskId = runtime.background().taskId;
  runtime.seed([item({ status: 'paused' })]);
  await observer.stopDownloadBackgroundTask();
  assert.equal(runtime.background().running, false, 'A retired handle cannot authorize current notifications');
  assert.equal(runtime.background().handles.length, 1);
  assert.equal(runtime.background().handles[0][1], context);
  assert.deepEqual(Array.from(runtime.background().retired), [taskId]);
  assert.equal(runtime.backgroundTasks.size, 1);
  assert.equal(runtime.timers.size, 1);
  await runtime.runTimers();
  assert.deepEqual(runtime.calls.stop, [{ context, id: taskId }, { context, id: taskId }]);
  assert.equal(runtime.background().running, false);
  assert.equal(runtime.background().handles.length, 0);
  assert.equal(runtime.backgroundTasks.size, 0);
  assert.equal(runtime.notifications.size, 0);
  assert.equal(runtime.timers.size, 0);
});

test('a stop rejection for an absent task clears its handle and still cancels the never-published service notification', async () => {
  const runtime = createRuntime();
  runtime.seed([item()], true, 'e-123');
  const page = runtime.page();
  await page.startDownloadBackgroundTask();
  const taskId = runtime.background().taskId;
  const notificationId = runtime.background().notificationId;
  assert.equal(runtime.calls.publish.length, 0);
  runtime.backgroundTasks.delete(taskId);
  runtime.plans.stop.push(new Error('Task no longer exists'));
  runtime.seed([item({ status: 'paused' })]);
  await page.syncDownloadRuntimeState(true);
  assert.equal(runtime.calls.stop.length, 1);
  assert.equal(runtime.calls.stop[0].id, taskId);
  assert.equal(runtime.background().running, false);
  assert.equal(runtime.background().handles.length, 0);
  assert.equal(runtime.notifications.has(runtime.notificationKey(notificationId, `bgmode_${notificationId}`)), false);
  assert.equal(runtime.trackingKeys().length, 0);
  assert.equal(runtime.timers.size, 0);
});

test('process recovery stops matching old download tasks and preserves unrelated continuous tasks', async () => {
  const runtime = createRuntime();
  const context = { name: 'owner' };
  for (const id of [0, 7]) runtime.backgroundTasks.set(id, runtime.taskInfo(id, context));
  runtime.backgroundTasks.set(8, runtime.taskInfo(8, context, { abilityName: 'OtherAbility' }));
  runtime.backgroundTasks.set(9, runtime.taskInfo(9, context, { isFromWebView: true }));
  runtime.backgroundTasks.set(10, runtime.taskInfo(10, context, { backgroundModes: ['audioPlayback'] }));
  runtime.seed([]);
  await runtime.page(context).syncDownloadRuntimeState(true);
  assert.deepEqual(runtime.calls.stop.map((call) => call.id).sort((a, b) => a - b), [0, 7]);
  assert.deepEqual([...runtime.backgroundTasks.keys()].sort((a, b) => a - b), [8, 9, 10]);
  assert.equal(runtime.calls.stop.every((call) => call.context === context && call.id !== undefined), true);
  assert.equal(runtime.background().running, false);
  assert.equal(runtime.calls.backgroundQueries.every((call) => call.includeSuspended === true), true);
});

test('retired stop failures cannot authorize notifications or consume a cleanup retry while downloads remain active', async () => {
  const runtime = createRuntime({ stopPlans: [new Error('Still suspended'), new Error('Still suspended')] });
  const context = { name: 'owner' };
  runtime.backgroundTasks.set(3, runtime.taskInfo(3, context, { isSuspended: true }));
  runtime.seed([item()], true, 'e-123');
  const page = runtime.page(context);
  page.queueDownloadRuntimeStateSync(true);
  await runtime.idle();
  assert.equal(runtime.calls.start.length, 0);
  assert.equal(runtime.calls.publish.length, 0);
  assert.equal(runtime.background().running, false);
  assert.deepEqual(Array.from(runtime.background().retired), [3]);
  assert.equal(runtime.timers.size, 1);
  await runtime.runTimers();
  assert.equal(runtime.calls.start.length, 0);
  assert.equal(runtime.calls.publish.length, 0);
  assert.equal(runtime.timers.size, 1, 'Active runtime does not clear a still-needed retired cleanup retry');
  await runtime.runTimers();
  assert.equal(runtime.calls.start.length, 1);
  assert.equal(runtime.calls.publish.length, 1);
  assert.equal(runtime.background().running, true);
  assert.equal(runtime.background().retired.length, 0);
  assert.equal(runtime.timers.size, 0);
});

test('a system cancellation pauses real active and queued tasks and registers one global listener', async () => {
  const runtime = createRuntime();
  runtime.seed([item(), item({ gid: 456, status: 'waiting' }), item({ gid: 789, status: 'failed' })], true, 'e-123', ['e-456']);
  const owner = runtime.page();
  const observer = runtime.page();
  await owner.startDownloadBackgroundTask();
  observer.subscribeDownloadBackgroundCancellation();
  assert.equal(runtime.calls.subscriptions.length, 1);
  const taskId = runtime.background().taskId;
  runtime.emitCancel(taskId);
  await runtime.idle();
  assert.equal(owner.findDownloadItemByKey('e-123').status, 'paused');
  assert.equal(observer.findDownloadItemByKey('e-456').status, 'paused');
  assert.equal(observer.findDownloadItemByKey('e-789').status, 'failed');
  assert.equal(owner.currentDownloadRunGeneration('e-123'), 1);
  assert.equal(owner.currentDownloadRunGeneration('e-456'), 1);
  assert.equal(owner.isDownloadKeyCancelled('e-123'), true);
  assert.equal(owner.isDownloadKeyCancelled('e-456'), true);
  assert.equal(runtime.background().running, false);
  assert.equal(runtime.notifications.size, 0);
});

test('a cancellation callback caused by precise stop does not pause a newly active gallery', async () => {
  const gate = deferred();
  const runtime = createRuntime({ stopPlans: [gate.promise] });
  runtime.seed([item()], true, 'e-123');
  const page = runtime.page();
  await page.startDownloadBackgroundTask();
  runtime.seed([item({ status: 'paused' })]);
  const stop = page.stopDownloadBackgroundTask();
  await settle();
  runtime.seed([item({ gid: 456 })], true, 'e-456');
  gate.resolve();
  await stop;
  assert.equal(page.findDownloadItemByKey('e-456').status, 'downloading');
  assert.equal(page.currentDownloadRunGeneration('e-456'), 0);
  assert.equal(page.isDownloadKeyCancelled('e-456'), false);
  assert.equal(runtime.background().running, false);
});

test('an early system cancellation cannot be revived by the later background-start response', async () => {
  const gate = deferred();
  const runtime = createRuntime({ startPlans: [gate.promise] });
  runtime.seed([item()], true, 'e-123');
  const page = runtime.page();
  page.queueDownloadRuntimeStateSync(true);
  await settle();
  assert.equal(runtime.calls.start.length, 1);
  runtime.emitCancel(7);
  gate.resolve({ continuousTaskId: 7, notificationId: 4007 });
  await runtime.idle();
  assert.equal(runtime.backgroundTasks.size, 0);
  assert.equal(runtime.background().running, false);
  assert.equal(runtime.background().handles.length, 0);
  assert.equal(page.findDownloadItemByKey('e-123').status, 'paused');
  assert.equal(runtime.calls.publish.length, 0);
  assert.equal(runtime.notifications.size, 0);
});

for (const status of ['complete', 'failed', 'paused', 'waiting', 'deleted']) {
  test(`${status} canonical tasks cannot publish or start background work through a stale active key`, async () => {
    const runtime = createRuntime();
    runtime.seed([item({ status })], true, 'e-123');
    const page = runtime.page();
    assert.equal(page.currentDownloadNotificationItem('e-123'), undefined);
    page.queueDownloadRuntimeStateSync(true);
    await runtime.idle();
    assert.equal(runtime.calls.publish.length, 0);
    assert.equal(runtime.calls.start.length, 0);
    assert.equal(runtime.notifications.size, 0);
  });
}
