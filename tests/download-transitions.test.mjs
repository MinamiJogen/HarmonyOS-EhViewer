import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';

// Execute DownloadQueueView's production snapshot methods and item callbacks,
// plus Index's actual running/pending resolvers against controlled worker state.
// This models retained ForEach item closures after immutable array replacements;
// it does not render ArkUI, validate transition appearance, or run downloads.
// Run with Node.js 22.13+: node --test tests/download-transitions.test.mjs
const source = readFileSync(new URL('../entry/src/main/ets/download/DownloadQueueView.ets', import.meta.url), 'utf8');
const modelSource = readFileSync(new URL('../entry/src/main/ets/download/DownloadModels.ets', import.meta.url), 'utf8');
const pageSource = readFileSync(new URL('../entry/src/main/ets/pages/Index.ets', import.meta.url), 'utf8');
const componentStart = source.indexOf('export struct DownloadQueueView {');
assert.notEqual(componentStart, -1, 'Missing DownloadQueueView');
const componentSource = source.slice(componentStart);
const fieldsStart = componentSource.indexOf('{') + 1;
const methodsEnd = componentSource.indexOf('\n  @Builder');
assert.notEqual(methodsEnd, -1, 'Missing end of production state methods');
const watcher = componentSource.match(/@Watch\('([^']+)'\)\s+items\s*:/)?.[1];
assert.ok(watcher, 'Missing items watcher');
const stateMethods = componentSource.slice(fieldsStart, methodsEnd)
  .replace(/@(?:Prop|State|BuilderParam)\b\s*/g, '')
  .replace(/@Watch\('[^']*'\)\s*/g, '');

function builderSource(name) {
  const start = componentSource.indexOf(`\n  private ${name}(`);
  assert.notEqual(start, -1, `Missing item builder: ${name}`);
  const end = componentSource.indexOf('\n  @Builder', start);
  assert.notEqual(end, -1, `Missing end of item builder: ${name}`);
  return componentSource.slice(start, end);
}

function arrowAt(builder, start) {
  assert.notEqual(start, -1, 'Missing production item callback');
  const bodyStart = builder.indexOf('{', start);
  let depth = 0;
  for (let index = bodyStart; index < builder.length; index++) {
    if (builder[index] === '{') depth++;
    if (builder[index] === '}' && --depth === 0) {
      return builder.slice(start, index + 1);
    }
  }
  assert.fail('Missing end of production item callback');
}

function clickAction(builderName, callbackName) {
  const builder = builderSource(builderName);
  const handlerStart = builder.indexOf(`this.${callbackName}(this.latestItem(item));`);
  assert.notEqual(handlerStart, -1, `Missing production action: ${callbackName}`);
  return arrowAt(builder, builder.lastIndexOf('() => {', handlerStart));
}

const card = builderSource('ActiveItemCard');
const commandStart = card.indexOf('if (this.shouldPauseItem(item))');
assert.notEqual(commandStart, -1, 'Missing production command dispatch');
const commandAction = arrowAt(card, card.lastIndexOf('() => {', commandStart));
const commandButtonStart = card.indexOf('this.TextActionButton(');
assert.notEqual(commandButtonStart, -1, 'Missing production command button');
const commandButtonEnd = card.indexOf('\n        );', commandButtonStart);
assert.notEqual(commandButtonEnd, -1, 'Missing end of production command button');
const commandButtonCall = card.slice(commandButtonStart, commandButtonEnd + '\n        );'.length);
const constants = [...source.split('\n'), ...modelSource.split('\n')]
  .filter((line) => /^(?:export )?const DOWNLOAD_(?:VIEW_|WATERFALL_|STATUS_)/.test(line))
  .join('\n').replace(/^export /gm, '');
const harnessSource = stripTypeScriptTypes(`(() => {
  ${constants}
  return class DownloadHarness {
    ${stateMethods}
    captureCommandAction(item: DownloadQueueItem): () => void { return ${commandAction}; }
    captureCommandButton(item: DownloadQueueItem) {
      let captured;
      this.TextActionButton = (...values) => { captured = values; };
      ${commandButtonCall}
      return captured;
    }
    captureDetailAction(item: DownloadQueueItem): () => void {
      return ${clickAction('ActiveItemHeader', 'onOpenItemDetail')};
    }
    captureRemoveAction(item: DownloadQueueItem): () => void {
      return ${clickAction('ActiveItemCard', 'onRemoveItem')};
    }
  };
})()`);

function pageMethod(name) {
  const start = pageSource.indexOf(`\n  private ${name}(`);
  assert.notEqual(start, -1, `Missing production runtime method: ${name}`);
  const tail = pageSource.slice(start + 1);
  const end = tail.slice(1).search(/\n  (?:private |@Builder)/);
  assert.notEqual(end, -1, `Missing end of production runtime method: ${name}`);
  return tail.slice(0, end + 1);
}

const runtimeConstants = pageSource.split('\n')
  .filter((line) => /^const DOWNLOAD_RUNTIME_(?:CANCEL|REMOVED)_KEYS_KEY:/.test(line))
  .join('\n');
const runtimeFields = pageSource.match(/^  private readonly download(?:Cancel|Removed)Keys:[^\n]+/gm);
assert.equal(runtimeFields?.length, 2, 'Missing production cancellation/removal fields');

function runtimeResolverBinding(name) {
  const match = pageSource.match(new RegExp(`^\\s+${name}: ([^\\n]+)$`, 'm'));
  assert.ok(match, `Missing production Queue resolver binding: ${name}`);
  return match[1].replace(/,\s*$/, '');
}

const runtimeHarnessSource = stripTypeScriptTypes(`(() => {
  ${constants}
  ${runtimeConstants}
  return class DownloadRuntimeHarness {
    ${runtimeFields.join('\n')}
    ${['downloadKey', 'isRuntimeStringArrayMarked', 'isDownloadKeyCancelled', 'isDownloadKeyRemoved',
      'isDownloadKeyRunningInCurrentProcess', 'isDownloadItemRunning', 'isDownloadItemQueued'].map(pageMethod).join('\n')}
    captureRunningResolver() { return ${runtimeResolverBinding('isItemRunning')}; }
    captureQueuedResolver() { return ${runtimeResolverBinding('isItemQueued')}; }
  };
})()`);

function item(overrides = {}) {
  return {
    gid: 123,
    site: 'e',
    title: 'Gallery',
    status: 'waiting',
    pages: 100,
    total: 100,
    downloaded: 0,
    speedBytesPerSecond: 0,
    remainingSeconds: 0,
    queuedAt: 'queued',
    lastAction: '',
    error: '',
    ...overrides
  };
}

function createQueue(items) {
  const Harness = vm.runInNewContext(harnessSource, {
    Scroller: class Scroller {},
    $r: (name) => name
  });
  const queue = new Harness();
  const runtimeContext = {
    sharedDownloadWorkerRunning: false,
    sharedDownloadActiveKey: '',
    sharedDownloadWaitKeys: [],
    sharedDownloadStartRequestedKeys: new Set(),
    sharedDownloadCancelKeys: new Set(),
    sharedDownloadRemovedKeys: new Set()
  };
  const RuntimeHarness = vm.runInNewContext(runtimeHarnessSource, runtimeContext);
  const runtime = new RuntimeHarness();
  // Persistent runtime storage is an external input; these tests start unmarked.
  runtime.runtimeStringArray = (_key) => [];
  const actions = [];
  queue.items = items;
  queue.statusLabelForItem = (current) => current.status;
  queue.statusColorForItem = (current) => `status:${current.status}`;
  queue.progressRatioForItem = (current) => current.downloaded / current.total;
  queue.progressTextForItem = (current) => `${current.downloaded}/${current.total}`;
  queue.speedTextForItem = (current) => `${current.speedBytesPerSecond}`;
  queue.remainingTextForItem = (current) => `${current.remainingSeconds}`;
  queue.isItemRunning = runtime.captureRunningResolver();
  queue.isItemQueued = runtime.captureQueuedResolver();
  for (const [handler, kind] of [
    ['onStartItem', 'start'], ['onPauseItem', 'pause'],
    ['onOpenItemDetail', 'open'], ['onRemoveItem', 'remove']
  ]) {
    queue[handler] = (current) => actions.push({ kind, item: current });
  }
  queue.aboutToAppear();
  return {
    queue,
    actions,
    runtime,
    runtimeContext,
    configureRuntime({ workerRunning = false, activeItem, pendingItems = [], startRequestedItems = [] } = {}) {
      const key = (current) => runtime.downloadKey(current.gid, current.site);
      runtimeContext.sharedDownloadWorkerRunning = workerRunning;
      runtimeContext.sharedDownloadActiveKey = activeItem ? key(activeItem) : '';
      runtimeContext.sharedDownloadWaitKeys = pendingItems.map(key);
      runtimeContext.sharedDownloadStartRequestedKeys = new Set(startRequestedItems.map(key));
      queue.revision++;
    },
    replaceItems(nextItems) {
      queue.items = nextItems;
      // Deliver the production @Watch method for the new array snapshot.
      queue[watcher]();
      queue.revision++;
    }
  };
}

test('retained item closures read replaced status, progress, speed, and remaining snapshots', () => {
  const original = Object.freeze(item());
  const harness = createQueue([original]);
  const { queue } = harness;
  const stableKey = queue.itemRenderKey(original);
  assert.equal(queue.latestItem(original), original);
  assert.equal(queue.itemCommandLabel(original), '开始');

  const replacement = item({ status: 'downloading', downloaded: 47.5,
    speedBytesPerSecond: 4096, remainingSeconds: 30 });
  harness.replaceItems([replacement]);
  harness.configureRuntime({ workerRunning: true, activeItem: replacement });
  assert.equal(queue.itemRenderKey(replacement), stableKey);
  assert.equal(queue.latestItem(original), replacement);
  assert.equal(queue.itemStatusLabelLive(original), 'downloading');
  assert.equal(queue.itemStatusColorLive(original), 'status:downloading');
  assert.equal(queue.itemProgressPercentLive(original), 48);
  assert.equal(queue.itemProgressTextLive(original), '47.5/100');
  assert.equal(queue.itemSpeedTextLive(original), '4096');
  assert.equal(queue.itemRemainingTextLive(original), '30');
  assert.equal(queue.shouldPauseItem(original), true);
  assert.equal(original.downloaded, 0);
});

test('button and error feedback follow the latest snapshot without changing task identity', () => {
  const original = item();
  const harness = createQueue([original]);
  const { queue } = harness;
  const failed = item({ status: 'failed', error: 'page failed', lastAction: 'retrying' });
  harness.replaceItems([failed]);
  assert.equal(queue.shouldPauseItem(original), false);
  assert.equal(queue.itemCommandLabel(original), '重试');
  assert.equal(queue.itemActionTextLive(original), 'page failed');
  assert.equal(queue.itemActionColorLive(original), 'sys.color.ohos_id_color_warning');
  assert.equal(queue.itemActionKindLive(original), 'error');

  harness.replaceItems([item({ status: 'paused', downloaded: 20, lastAction: 'user paused' })]);
  assert.equal(queue.itemCommandLabel(original), '继续');
  assert.equal(queue.itemActionTextLive(original), 'user paused');
  assert.equal(queue.itemActionColorLive(original), 'sys.color.font_secondary');
  assert.equal(queue.itemActionKindLive(original), 'action');

  harness.replaceItems([item({ status: 'paused' })]);
  assert.equal(queue.itemActionTextLive(original), 'queued');
  harness.replaceItems([item({ status: 'idle' })]);
  assert.equal(queue.itemCommandLabel(original), '开始');
});

test('retained production callbacks dispatch current items through repeated running, paused, pending, and failed states', () => {
  const original = item();
  const harness = createQueue([original]);
  const { queue, actions } = harness;
  const command = queue.captureCommandAction(original);
  const open = queue.captureDetailAction(original);
  const remove = queue.captureRemoveAction(original);
  for (let cycle = 0; cycle < 2; cycle++) {
    const running = item({ status: 'downloading', downloaded: 12 + cycle });
    const paused = item({ status: 'paused', downloaded: 12 + cycle });
    const pending = item({ status: 'waiting', downloaded: 12 + cycle });
    const failed = item({ status: 'failed', error: `retry required ${cycle}` });
    for (const [current, runtimeState, label, kind] of [
      [running, { workerRunning: true, activeItem: running }, '暂停', 'pause'],
      [paused, {}, '继续', 'start'],
      [pending, { workerRunning: true, pendingItems: [pending] }, '暂停', 'pause'],
      [failed, {}, '重试', 'start']
    ]) {
      harness.replaceItems([current]);
      harness.configureRuntime(runtimeState);
      assert.equal(queue.itemCommandLabel(original), label);
      command();
      open();
      remove();
      assert.deepEqual(actions.slice(-3).map((action) => action.kind), [kind, 'open', 'remove']);
      for (const action of actions.slice(-3)) assert.equal(action.item, current);
    }
  }
});

test('equal gallery IDs on different sites retain isolated snapshots and action closures', () => {
  const originalE = item({ site: 'e' });
  const originalEx = item({ site: 'ex' });
  const harness = createQueue([originalE, originalEx]);
  const { queue, actions } = harness;
  assert.notEqual(queue.itemRenderKey(originalE), queue.itemRenderKey(originalEx));
  const commandE = queue.captureCommandAction(originalE);
  const commandEx = queue.captureCommandAction(originalEx);
  const latestE = item({ site: 'e', status: 'downloading', downloaded: 60 });
  const latestEx = item({ site: 'ex', status: 'failed', downloaded: 10 });
  harness.replaceItems([latestEx, latestE]);
  harness.configureRuntime({ workerRunning: true, activeItem: latestE });
  assert.equal(queue.itemProgressPercentLive(originalE), 60);
  assert.equal(queue.itemProgressPercentLive(originalEx), 10);
  commandE();
  commandEx();
  assert.deepEqual(actions.map((action) => action.kind), ['pause', 'start']);
  assert.equal(actions[0].item, latestE);
  assert.equal(actions[1].item, latestEx);
});

test('snapshot replacement removes departed task entries rather than retaining their previous clones', () => {
  const original = item();
  const harness = createQueue([original]);
  const replacement = item({ status: 'paused', downloaded: 20 });
  harness.replaceItems([replacement]);
  assert.equal(harness.queue.latestItem(original), replacement);
  harness.replaceItems([]);
  assert.equal(harness.queue.itemsByKey.size, 0);
  assert.equal(harness.queue.latestItem(original), original);
});

test('cold-start waiting snapshots show start and cannot pause until actually scheduled', () => {
  const waiting = item();
  const harness = createQueue([waiting]);
  const { queue, actions } = harness;
  const command = queue.captureCommandAction(waiting);
  assert.equal(queue.shouldPauseItem(waiting), false);
  assert.equal(queue.itemCommandLabel(waiting), '开始');
  assert.equal(queue.canStartAll(), true);
  assert.equal(queue.canPauseAll(), false);
  command();
  assert.equal(actions.at(-1).kind, 'start');

  // A live worker alone does not schedule every persisted waiting snapshot.
  harness.configureRuntime({ workerRunning: true });
  assert.equal(queue.shouldPauseItem(waiting), false);
  assert.equal(queue.canStartAll(), true);
  assert.equal(queue.canPauseAll(), false);
});

test('actual pending keys and start-requested keys both enable pause and disable redundant start-all', () => {
  const original = item();
  const harness = createQueue([original]);
  const { queue, actions } = harness;
  const command = queue.captureCommandAction(original);
  for (const schedulingField of ['pendingItems', 'startRequestedItems']) {
    const pending = item({ lastAction: schedulingField });
    harness.replaceItems([pending]);
    harness.configureRuntime({ workerRunning: true, [schedulingField]: [pending] });
    assert.equal(queue.shouldPauseItem(original), true);
    assert.equal(queue.itemCommandLabel(original), '暂停');
    assert.equal(queue.canStartAll(), false);
    assert.equal(queue.canPauseAll(), true);
    command();
    assert.equal(actions.at(-1).kind, 'pause');
    assert.equal(actions.at(-1).item, pending);
  }
});

test('retained waiting callback switches back to start when worker stops despite leftover pending keys', () => {
  const original = item();
  const harness = createQueue([original]);
  const { queue, actions } = harness;
  const command = queue.captureCommandAction(original);
  const pending = item({ lastAction: 'scheduled' });
  harness.replaceItems([pending]);
  harness.configureRuntime({ workerRunning: true, pendingItems: [pending] });
  command();
  assert.equal(actions.at(-1).kind, 'pause');

  harness.configureRuntime({ pendingItems: [pending], startRequestedItems: [pending] });
  assert.equal(queue.shouldPauseItem(original), false);
  assert.equal(queue.itemCommandLabel(original), '开始');
  assert.equal(queue.canStartAll(), true);
  assert.equal(queue.canPauseAll(), false);
  command();
  assert.equal(actions.at(-1).kind, 'start');
  assert.equal(actions.at(-1).item, pending);

  const partial = item({ downloaded: 20 });
  harness.replaceItems([partial]);
  harness.configureRuntime({ pendingItems: [partial] });
  assert.equal(queue.shouldPauseItem(original), false);
  assert.equal(queue.itemCommandLabel(original), '继续');
  assert.equal(queue.canPauseAll(), false);
  command();
  assert.equal(actions.at(-1).kind, 'start');
  assert.equal(actions.at(-1).item, partial);
});

test('bulk availability follows actual running/pending tasks while paused and failed tasks stay startable', () => {
  const running = item({ gid: 1, status: 'downloading' });
  const pending = item({ gid: 2 });
  const complete = item({ gid: 3, status: 'complete' });
  const deleted = item({ gid: 4, status: 'deleted' });
  const harness = createQueue([running, pending, complete, deleted]);
  const { queue } = harness;
  harness.configureRuntime({ workerRunning: true, activeItem: running, pendingItems: [pending] });
  assert.equal(queue.canStartAll(), false);
  assert.equal(queue.canPauseAll(), true);

  const paused = item({ gid: 5, status: 'paused', downloaded: 10 });
  const failed = item({ gid: 6, status: 'failed', error: 'retry' });
  harness.replaceItems([running, pending, complete, deleted, paused, failed]);
  assert.equal(queue.itemCommandLabel(paused), '继续');
  assert.equal(queue.itemCommandLabel(failed), '重试');
  assert.equal(queue.canStartAll(), true);
  assert.equal(queue.canPauseAll(), true);

  harness.replaceItems([paused, failed, complete, deleted]);
  assert.equal(queue.canStartAll(), true);
  assert.equal(queue.canPauseAll(), false);
  harness.replaceItems([complete, deleted]);
  assert.equal(queue.canStartAll(), false);
  assert.equal(queue.canPauseAll(), false);
});

test('persisted downloading state without an active worker/key is resumable rather than pausable', () => {
  const running = item({ status: 'downloading', downloaded: 20 });
  const other = item({ gid: 999, status: 'downloading' });
  const harness = createQueue([running]);
  const { queue, actions } = harness;
  const command = queue.captureCommandAction(running);
  for (const runtimeState of [{ activeItem: running }, { workerRunning: true, activeItem: other }]) {
    harness.configureRuntime(runtimeState);
    assert.equal(queue.shouldPauseItem(running), false);
    assert.equal(queue.itemCommandLabel(running), '继续');
    assert.equal(queue.canPauseAll(), false);
    assert.equal(queue.canStartAll(), true);
    command();
    assert.equal(actions.at(-1).kind, 'start');
  }
  harness.configureRuntime({ workerRunning: true, activeItem: running });
  assert.equal(queue.itemCommandLabel(running), '暂停');
  command();
  assert.equal(actions.at(-1).kind, 'pause');
});

test('retained command button passes live getters through resume, progress, pause, and retry updates', () => {
  const paused = item({ status: 'paused', downloaded: 20 });
  const harness = createQueue([paused]);
  const { queue, actions } = harness;
  const [symbol, label, primary, command, enabled, animated] = queue.captureCommandButton(paused);
  for (const resolver of [symbol, label, primary, enabled]) assert.equal(typeof resolver, 'function');
  assert.equal(animated, true);
  const stableKey = queue.itemRenderKey(paused);
  assert.equal(label(), '继续');
  assert.equal(symbol(), 'sys.symbol.play_fill');
  assert.equal(primary(), true);

  const running = item({ status: 'downloading', downloaded: 21 });
  harness.replaceItems([running]);
  harness.configureRuntime({ workerRunning: true, activeItem: running });
  assert.equal(label(), '暂停');
  assert.equal(symbol(), 'sys.symbol.pause_fill');
  assert.equal(primary(), false);
  command();
  assert.equal(actions.at(-1).kind, 'pause');
  assert.equal(actions.at(-1).item, running);

  for (let downloaded = 22; downloaded <= 26; downloaded++) {
    const progress = item({ status: 'downloading', downloaded });
    harness.replaceItems([progress]);
    assert.equal(queue.itemRenderKey(progress), stableKey);
    assert.equal(label(), '暂停');
    assert.equal(primary(), false);
  }

  const pausedAgain = item({ status: 'paused', downloaded: 26 });
  harness.replaceItems([pausedAgain]);
  harness.configureRuntime();
  assert.equal(label(), '继续');
  assert.equal(symbol(), 'sys.symbol.play_fill');
  assert.equal(primary(), true);
  assert.equal(enabled(), true);
  command();
  assert.equal(actions.at(-1).kind, 'start');
  assert.equal(actions.at(-1).item, pausedAgain);

  const failed = item({ status: 'failed', downloaded: 26, error: 'network error' });
  harness.replaceItems([failed]);
  assert.equal(label(), '重试');
  assert.equal(primary(), true);
});

test('cancelled and removed keys cannot remain pausable through stale pending membership', () => {
  const pending = item();
  const harness = createQueue([pending]);
  const { queue, runtime, runtimeContext } = harness;
  const key = runtime.downloadKey(pending.gid, pending.site);
  harness.configureRuntime({ workerRunning: true, pendingItems: [pending], startRequestedItems: [pending] });
  assert.equal(queue.shouldPauseItem(pending), true);
  for (const markedKeys of [runtimeContext.sharedDownloadCancelKeys, runtimeContext.sharedDownloadRemovedKeys,
    runtime.downloadCancelKeys, runtime.downloadRemovedKeys]) {
    markedKeys.add(key);
    assert.equal(queue.shouldPauseItem(pending), false);
    assert.equal(queue.itemCommandLabel(pending), '开始');
    assert.equal(queue.canPauseAll(), false);
    markedKeys.delete(key);
    assert.equal(queue.shouldPauseItem(pending), true);
  }
});
