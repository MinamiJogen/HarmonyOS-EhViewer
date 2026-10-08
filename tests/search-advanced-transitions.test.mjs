import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';

// Execute production state, watcher methods, and the production frame callback.
// Controlled frames and completions verify lifecycle and race handling only;
// this does not render ArkUI or verify device layout, material, or keyboard focus.
// Run with Node.js 22.13+: node --test tests/search-advanced-transitions.test.mjs
const source = readFileSync(new URL('../entry/src/main/ets/pages/Index.ets', import.meta.url), 'utf8');
const fieldNames = [
  'searchAdvancedEnabled',
  'searchFilterSheetVisible',
  'searchAdvancedSheetActive',
  'searchAdvancedAnimationGeneration',
  'searchAdvancedContentMounted',
  'searchAdvancedContentOpacity',
  'searchAdvancedHeaderHeight',
  'searchAdvancedChipHeight',
  'searchAdvancedFieldsHeight',
  'searchAdvancedInputFocused'
];
const fieldLines = fieldNames.map((name) => {
  const line = source.split('\n').find((candidate) => new RegExp(`\\b${name}\\s*:`).test(candidate));
  assert.ok(line, `Missing production field: ${name}`);
  return line;
});
const watcherNames = new Map(fieldLines.map((line, index) => [
  fieldNames[index], line.match(/@Watch\('([^']+)'\)/)?.[1]
]));
assert.equal(watcherNames.get('searchAdvancedEnabled'), 'syncSearchAdvancedVisibility');
assert.equal(watcherNames.get('searchFilterSheetVisible'), 'syncSearchAdvancedVisibility');
const fields = fieldLines.join('\n')
  .replace(/@(?:State|Prop)\b\s*/g, '')
  .replace(/@Watch\('[^']*'\)\s*/g, '');

function productionMethod(name) {
  const start = source.search(new RegExp(`\\n  private ${name}\\(`));
  assert.notEqual(start, -1, `Missing search transition method: ${name}`);
  const tail = source.slice(start + 1);
  const nextMethod = tail.slice(1).search(/\n  (?:private |aboutTo|@Builder)/);
  assert.notEqual(nextMethod, -1, `Missing end of production method: ${name}`);
  return tail.slice(0, nextMethod + 1);
}

const callbackStart = source.indexOf('class SearchAdvancedFrameCallback extends FrameCallback {');
assert.notEqual(callbackStart, -1, 'Missing production frame callback');
const callbackEnd = source.indexOf('\n}\n', callbackStart);
assert.notEqual(callbackEnd, -1, 'Missing end of production frame callback');
const callbackSource = source.slice(callbackStart, callbackEnd + 3);
const harnessSource = stripTypeScriptTypes(`(() => {
  ${callbackSource}
  return {
    SearchFrameCallback: SearchAdvancedFrameCallback,
    Harness: class SearchHarness {
      ${fields}
      ${[
        'resetSearchAdvancedPresentation',
        'activateSearchAdvancedTransitions',
        'deactivateSearchAdvancedTransitions',
        'syncSearchAdvancedVisibility',
        'animateSearchAdvancedVisibility'
      ].map(productionMethod).join('\n')}
    }
  };
})()`);

function createSearch({ enabled = true, sheetVisible = true, focusThrows = false,
  focusClearThrows = false } = {}) {
  const frames = [];
  const animations = [];
  const writes = [];
  const focusRequests = [];
  const focusClears = [];
  const { Harness, SearchFrameCallback } = vm.runInNewContext(harnessSource, {
    FrameCallback: class FrameCallback {},
    Curve: { EaseOut: 'ease-out' }
  });
  const page = new Proxy(new Harness(), {
    set(target, property, value) {
      writes.push(property);
      target[property] = value;
      return true;
    }
  });
  page.searchAdvancedEnabled = enabled;
  page.searchFilterSheetVisible = sheetVisible;
  const focusController = {
    requestFocus(id) {
      focusRequests.push(id);
      if (focusThrows) {
        throw new Error('Focus request unavailable');
      }
    },
    clearFocus() {
      focusClears.push(true);
      if (focusClearThrows) {
        throw new Error('Focus clearing unavailable');
      }
    }
  };
  page.getUIContext = () => ({
    postFrameCallback(callback) {
      assert.ok(callback instanceof SearchFrameCallback, 'Use the production frame callback');
      frames.push(callback);
    },
    animateTo(options, mutation) {
      assert.equal(options.duration, 200);
      assert.equal(options.curve, 'ease-out');
      assert.equal(typeof options.onFinish, 'function');
      animations.push({ finish: options.onFinish, finished: false });
      mutation();
    },
    getFocusController() {
      return focusController;
    }
  });
  writes.length = 0;

  function finish(animation) {
    assert.ok(animation, 'Missing pending animation');
    assert.equal(animation.finished, false, 'Animation already completed');
    animation.finished = true;
    animation.finish();
  }

  return {
    page, frames, animations, writes, focusRequests, focusClears, finish,
    deliverFrame() {
      const frame = frames.shift();
      assert.ok(frame, 'Missing pending frame');
      frame.onFrame(0);
    },
    flushFrames() {
      while (frames.length > 0) {
        frames.shift().onFrame(0);
      }
    },
    finishAll() {
      for (const animation of animations) {
        if (!animation.finished) {
          finish(animation);
        }
      }
    },
    setEnabled(value) {
      if (page.searchAdvancedEnabled !== value) {
        page.searchAdvancedEnabled = value;
        page[watcherNames.get('searchAdvancedEnabled')]();
      }
    },
    setSheetVisible(value) {
      if (page.searchFilterSheetVisible !== value) {
        page.searchFilterSheetVisible = value;
        page[watcherNames.get('searchFilterSheetVisible')]();
      }
    },
    openSheet() {
      this.setSheetVisible(true);
      page.activateSearchAdvancedTransitions();
    },
    closeSheet() {
      this.setSheetVisible(false);
      page.deactivateSearchAdvancedTransitions();
    }
  };
}

function presentation(page) {
  return {
    mounted: page.searchAdvancedContentMounted,
    opacity: page.searchAdvancedContentOpacity,
    headerHeight: page.searchAdvancedHeaderHeight,
    chipHeight: page.searchAdvancedChipHeight,
    fieldsHeight: page.searchAdvancedFieldsHeight
  };
}

function snapshot(page) {
  return {
    ...presentation(page),
    enabled: page.searchAdvancedEnabled,
    sheetVisible: page.searchFilterSheetVisible,
    active: page.searchAdvancedSheetActive,
    generation: page.searchAdvancedAnimationGeneration,
    focused: page.searchAdvancedInputFocused
  };
}

const expanded = { mounted: true, opacity: 1, headerHeight: 108, chipHeight: 52, fieldsHeight: 84 };
const collapsed = { mounted: false, opacity: 0, headerHeight: 56, chipHeight: 0, fieldsHeight: 0 };

test('show mounts before its frame, and hide retains content until its completion', () => {
  const harness = createSearch({ enabled: false });
  const { page } = harness;
  page.activateSearchAdvancedTransitions();
  assert.deepEqual(presentation(page), collapsed);

  harness.setEnabled(true);
  assert.deepEqual(presentation(page), { ...collapsed, mounted: true });
  assert.equal(harness.animations.length, 0);
  assert.equal(harness.frames.length, 1);
  harness.flushFrames();
  assert.deepEqual(presentation(page), expanded);
  harness.finishAll();

  harness.setEnabled(false);
  assert.equal(page.searchAdvancedContentMounted, true);
  harness.flushFrames();
  assert.deepEqual(presentation(page), { ...collapsed, mounted: true });
  harness.finishAll();
  assert.deepEqual(presentation(page), collapsed);
});

test('reopening invalidates an older hide completion before the entrance frame runs', () => {
  const harness = createSearch();
  const { page } = harness;
  page.activateSearchAdvancedTransitions();
  harness.setEnabled(false);
  harness.flushFrames();
  const oldHide = harness.animations.at(-1);
  harness.setEnabled(true);
  const reopened = snapshot(page);

  harness.writes.length = 0;
  harness.finish(oldHide);
  assert.deepEqual(harness.writes, []);
  assert.deepEqual(snapshot(page), reopened);
  harness.flushFrames();
  harness.finishAll();
  assert.deepEqual(presentation(page), expanded);
});

test('rapid toggles invalidate every superseded queued frame without writes', () => {
  const harness = createSearch({ enabled: false });
  const { page } = harness;
  page.activateSearchAdvancedTransitions();
  for (const enabled of [true, false, true, false, true]) {
    harness.setEnabled(enabled);
  }
  assert.equal(harness.frames.length, 5);
  const latest = snapshot(page);
  for (let index = 0; index < 4; index++) {
    harness.writes.length = 0;
    harness.deliverFrame();
    assert.deepEqual(harness.writes, []);
    assert.deepEqual(snapshot(page), latest);
    assert.equal(harness.animations.length, 0);
  }
  harness.deliverFrame();
  assert.equal(harness.animations.length, 1);
  harness.finishAll();
  assert.deepEqual(presentation(page), expanded);
});

test('an old hide completion cannot shorten a newer exit after an intervening reopen', () => {
  const harness = createSearch();
  const { page } = harness;
  page.activateSearchAdvancedTransitions();
  harness.setEnabled(false);
  harness.flushFrames();
  const oldHide = harness.animations.at(-1);
  harness.setEnabled(true);
  harness.flushFrames();
  harness.setEnabled(false);
  harness.flushFrames();
  const latestExit = snapshot(page);

  harness.writes.length = 0;
  harness.finish(oldHide);
  assert.deepEqual(harness.writes, []);
  assert.deepEqual(snapshot(page), latestExit);
  assert.equal(page.searchAdvancedContentMounted, true);
  harness.finishAll();
  assert.deepEqual(presentation(page), collapsed);
});

for (const [active, sheetVisible] of [[false, false], [true, false], [false, true]]) {
  test(`non-visible sheet snaps without animations (active=${active}, visible=${sheetVisible})`, () => {
    const harness = createSearch({ sheetVisible });
    const { page } = harness;
    page.searchAdvancedSheetActive = active;
    harness.setEnabled(false);
    assert.deepEqual(presentation(page), collapsed);
    harness.setEnabled(true);
    assert.deepEqual(presentation(page), expanded);
    assert.equal(harness.frames.length, 0);
    assert.equal(harness.animations.length, 0);
  });
}

for (const phase of ['queued frame', 'pending completion']) {
  test(`closing the sheet invalidates its ${phase} without later state writes`, () => {
    const harness = createSearch();
    const { page } = harness;
    page.activateSearchAdvancedTransitions();
    harness.setEnabled(false);
    if (phase === 'pending completion') {
      harness.flushFrames();
    }
    harness.closeSheet();
    const closed = snapshot(page);
    harness.writes.length = 0;
    harness.flushFrames();
    harness.finishAll();
    assert.deepEqual(harness.writes, []);
    assert.deepEqual(snapshot(page), closed);
    assert.equal(page.searchAdvancedSheetActive, false);
  });
}

test('reopening the sheet protects the new lifecycle from an old hide completion', () => {
  const harness = createSearch();
  const { page } = harness;
  page.activateSearchAdvancedTransitions();
  harness.setEnabled(false);
  harness.flushFrames();
  const oldHide = harness.animations.at(-1);
  harness.closeSheet();
  page.searchAdvancedInputFocused = true;
  harness.openSheet();
  assert.equal(page.searchAdvancedInputFocused, false);
  assert.deepEqual(presentation(page), collapsed);
  harness.setEnabled(true);
  const reopened = snapshot(page);

  harness.writes.length = 0;
  harness.finish(oldHide);
  assert.deepEqual(harness.writes, []);
  assert.deepEqual(snapshot(page), reopened);
  harness.flushFrames();
  harness.finishAll();
  assert.deepEqual(presentation(page), expanded);
});

test('hiding a focused input moves focus to the persistent advanced switch', () => {
  const harness = createSearch();
  const { page } = harness;
  page.activateSearchAdvancedTransitions();
  page.searchAdvancedInputFocused = true;
  harness.setEnabled(false);
  assert.deepEqual(harness.focusRequests, ['search-advanced-switch']);
  assert.deepEqual(harness.focusClears, []);
  assert.equal(page.searchAdvancedInputFocused, false);
  page.syncSearchAdvancedVisibility();
  assert.equal(harness.focusRequests.length, 1);
});

test('a throwing focus request falls back to clearFocus before hiding the input', () => {
  const harness = createSearch({ focusThrows: true });
  const { page } = harness;
  page.activateSearchAdvancedTransitions();
  page.searchAdvancedInputFocused = true;
  assert.doesNotThrow(() => harness.setEnabled(false));
  assert.deepEqual(harness.focusRequests, ['search-advanced-switch']);
  assert.equal(harness.focusClears.length, 1);
  assert.equal(page.searchAdvancedInputFocused, false);
  harness.flushFrames();
  harness.finishAll();
  assert.deepEqual(presentation(page), collapsed);
});

test('hiding without input focus leaves the focus controller untouched', () => {
  const harness = createSearch();
  harness.page.activateSearchAdvancedTransitions();
  harness.setEnabled(false);
  assert.deepEqual(harness.focusRequests, []);
  assert.deepEqual(harness.focusClears, []);
});

test('unavailable focus movement and clearing do not prevent the exit animation', () => {
  const harness = createSearch({ focusThrows: true, focusClearThrows: true });
  const { page } = harness;
  page.activateSearchAdvancedTransitions();
  page.searchAdvancedInputFocused = true;
  assert.doesNotThrow(() => harness.setEnabled(false));
  assert.deepEqual(harness.focusRequests, ['search-advanced-switch']);
  assert.equal(harness.focusClears.length, 1);
  assert.equal(page.searchAdvancedInputFocused, false);
  assert.equal(harness.frames.length, 1);
  harness.flushFrames();
  harness.finishAll();
  assert.deepEqual(presentation(page), collapsed);
});
