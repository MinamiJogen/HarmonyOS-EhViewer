import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';

// Execute the production visibility methods and frame callback. Frame delivery
// and animation completion are controlled here; this does not render ArkUI or
// verify device animation, clipping, material appearance, or touch handling.
// Run with Node.js 22.13+: node --test tests/reader-controls.test.mjs
const pageSource = readFileSync(new URL('../entry/src/main/ets/pages/reader/ReaderPage.ets', import.meta.url), 'utf8');
const componentStart = pageSource.indexOf('export struct ReaderFullscreenPage {');
assert.notEqual(componentStart, -1, 'Missing ReaderFullscreenPage');
const componentSource = pageSource.slice(componentStart);
const fieldsStart = componentSource.indexOf('{') + 1;
const fieldsEnd = componentSource.indexOf('\n  aboutToAppear(');
assert.notEqual(fieldsEnd, -1, 'Missing ReaderFullscreenPage lifecycle');
const fields = componentSource.slice(fieldsStart, fieldsEnd)
  .replace(/@(?:Prop|State|BuilderParam)\b\s*/g, '')
  .replace(/@Watch\('[^']*'\)\s*/g, '');

const methodNames = [
  'aboutToAppear',
  'aboutToDisappear',
  'shouldDisplayBottomBar',
  'bottomBarHeight',
  'menuBarHeight',
  'syncBottomBarVisibility',
  'animateBottomBar',
  'animateMenuBar'
];

function pageMethod(name) {
  const start = componentSource.search(new RegExp(`\\n  (?:private )?${name}\\(`));
  assert.notEqual(start, -1, `Missing reader method: ${name}`);
  const tail = componentSource.slice(start + 1);
  const nextMethod = tail.slice(1).search(/\n  (?:private |aboutTo|@Builder)/);
  assert.notEqual(nextMethod, -1, `Missing end of reader method: ${name}`);
  return tail.slice(0, nextMethod + 1);
}

const callbackStart = pageSource.indexOf('class ReaderChromeFrameCallback extends FrameCallback {');
assert.notEqual(callbackStart, -1, 'Missing production frame callback');
const callbackEnd = pageSource.indexOf('\n}\n', callbackStart);
assert.notEqual(callbackEnd, -1, 'Missing end of production frame callback');
const callbackSource = pageSource.slice(callbackStart, callbackEnd + 3);
const constants = pageSource.split('\n').filter((line) => line.startsWith('const READER_CHROME_')).join('\n');
const harnessSource = stripTypeScriptTypes(`(() => {
  ${constants}
  ${callbackSource}
  return {
    ChromeFrameCallback: ReaderChromeFrameCallback,
    Harness: class ReaderHarness {
      ${fields}
      ${methodNames.map(pageMethod).join('\n')}
    }
  };
})()`);

function createPage({ statusVisible = false, menuVisible = false } = {}) {
  const frames = [];
  const animations = [];
  const writes = [];
  const { Harness, ChromeFrameCallback } = vm.runInNewContext(harnessSource, {
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
  page.bottomBarVisible = statusVisible;
  page.menuBarVisible = menuVisible;
  page.getUIContext = () => ({
    postFrameCallback(callback) {
      assert.ok(callback instanceof ChromeFrameCallback, 'Use the production frame callback');
      frames.push(callback);
    },
    animateTo(options, mutation) {
      animations.push({ finish: options.onFinish, finished: false });
      mutation();
    }
  });

  function finish(animation) {
    assert.ok(animation, 'Missing pending animation');
    assert.equal(animation.finished, false, 'Animation already completed');
    animation.finished = true;
    animation.finish();
  }

  return {
    page,
    frames,
    animations,
    writes,
    finish,
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
    setVisibility(statusVisible, menuVisible) {
      page.bottomBarVisible = statusVisible;
      page.menuBarVisible = menuVisible;
      page.syncBottomBarVisibility();
    }
  };
}

function snapshot(page) {
  return {
    active: page.chromeActive,
    generation: page.chromeAnimationGeneration,
    barMounted: page.bottomBarMounted,
    barOpacity: page.bottomBarOpacity,
    barOffset: page.bottomBarOffsetY,
    measuredHeight: page.bottomBarMeasuredHeight,
    menuMounted: page.menuBarMounted,
    menuOpacity: page.menuBarOpacity,
    menuOffset: page.menuBarOffsetY,
    menuMeasuredHeight: page.menuBarMeasuredHeight,
    menuHeightAutomatic: page.menuBarHeightAutomatic,
    menuAnimatedHeight: page.menuBarAnimatedHeight,
    menuHeight: page.menuBarHeight(),
    height: page.bottomBarHeight()
  };
}

test('the toolbar and menu mount before the next frame starts their entrance', () => {
  const harness = createPage({ menuVisible: true });
  const { page } = harness;
  assert.equal(page.shouldDisplayBottomBar(), true);
  assert.equal(page.bottomBarHeight(), 0);

  page.aboutToAppear();
  assert.equal(page.bottomBarMounted, true);
  assert.equal(page.menuBarMounted, true);
  assert.equal(page.bottomBarOpacity, 0);
  assert.equal(page.menuBarOpacity, 0);
  assert.equal(harness.animations.length, 0);
  assert.equal(harness.frames.length, 1);
  assert.equal(page.bottomBarHeight(), 'auto');

  harness.flushFrames();
  assert.equal(page.bottomBarOpacity, 1);
  assert.equal(page.menuBarOpacity, 1);
  harness.finishAll();
  assert.equal(page.bottomBarMounted, true);
  assert.equal(page.menuBarMounted, true);
});

test('exit keeps the toolbar mounted at its previous measured height until completion', () => {
  const harness = createPage({ menuVisible: true });
  const { page } = harness;
  page.aboutToAppear();
  harness.flushFrames();
  harness.finishAll();
  const previousHeight = 287;
  page.bottomBarMeasuredHeight = previousHeight;

  harness.setVisibility(false, false);
  assert.equal(page.shouldDisplayBottomBar(), false);
  assert.equal(page.bottomBarMounted, true);
  assert.equal(page.menuBarMounted, true);
  assert.equal(page.bottomBarHeight(), previousHeight);

  harness.flushFrames();
  assert.equal(page.bottomBarOpacity, 0);
  assert.equal(page.menuBarOpacity, 0);
  assert.equal(page.bottomBarMounted, true);
  assert.equal(page.bottomBarHeight(), previousHeight);

  harness.finishAll();
  assert.equal(page.bottomBarMounted, false);
  assert.equal(page.menuBarMounted, false);
  assert.equal(page.bottomBarMeasuredHeight, 0);
  assert.equal(page.bottomBarHeight(), 0);
});

test('reopening invalidates old exit completions before the new frame arrives', () => {
  const harness = createPage({ menuVisible: true });
  const { page } = harness;
  page.aboutToAppear();
  harness.flushFrames();
  harness.finishAll();

  const oldAnimationCount = harness.animations.length;
  harness.setVisibility(false, false);
  harness.flushFrames();
  const exits = harness.animations.slice(oldAnimationCount);
  assert.ok(exits.length > 0);
  harness.setVisibility(false, true);
  for (const exit of exits) {
    harness.finish(exit);
  }
  assert.equal(page.bottomBarMounted, true);
  assert.equal(page.menuBarMounted, true);

  harness.flushFrames();
  harness.finishAll();
  assert.equal(page.bottomBarMounted, true);
  assert.equal(page.menuBarMounted, true);
  assert.equal(page.bottomBarOpacity, 1);
  assert.equal(page.menuBarOpacity, 1);
});

test('a superseded queued hide frame cannot animate a reopened menu out', () => {
  const harness = createPage({ menuVisible: true });
  const { page } = harness;
  page.aboutToAppear();
  harness.flushFrames();
  harness.finishAll();
  const oldAnimationCount = harness.animations.length;

  harness.setVisibility(false, false);
  harness.setVisibility(false, true);
  assert.equal(harness.frames.length, 2);
  harness.frames.shift().onFrame(0);
  assert.equal(harness.animations.length, oldAnimationCount);
  assert.equal(page.bottomBarOpacity, 1);
  assert.equal(page.menuBarOpacity, 1);

  harness.flushFrames();
  harness.finishAll();
  assert.equal(page.bottomBarMounted, true);
  assert.equal(page.menuBarMounted, true);
});

test('an earlier exit completion cannot shorten a newer exit after an intervening reopen', () => {
  const harness = createPage({ menuVisible: true });
  const { page } = harness;
  page.aboutToAppear();
  harness.flushFrames();
  harness.finishAll();

  const oldAnimationCount = harness.animations.length;
  harness.setVisibility(false, false);
  harness.flushFrames();
  const oldExits = harness.animations.slice(oldAnimationCount);
  harness.setVisibility(false, true);
  harness.flushFrames();
  harness.setVisibility(false, false);
  harness.flushFrames();

  for (const exit of oldExits) {
    harness.finish(exit);
  }
  assert.equal(page.bottomBarMounted, true);
  assert.equal(page.menuBarMounted, true);
  harness.finishAll();
  assert.equal(page.bottomBarMounted, false);
  assert.equal(page.menuBarMounted, false);
});

for (const phase of ['queued frame', 'pending completion']) {
  test(`leaving the reader invalidates its ${phase} and resets presence`, () => {
    const harness = createPage({ menuVisible: true });
    const { page } = harness;
    page.aboutToAppear();
    harness.flushFrames();
    harness.finishAll();
    harness.setVisibility(false, false);
    if (phase === 'pending completion') {
      harness.flushFrames();
    }

    page.aboutToDisappear();
    const stateAfterLeaving = snapshot(page);
    assert.equal(page.bottomBarMounted, false);
    assert.equal(page.menuBarMounted, false);
    assert.equal(page.bottomBarHeight(), 0);
    harness.writes.length = 0;
    harness.flushFrames();
    harness.finishAll();
    page.syncBottomBarVisibility();
    assert.deepEqual(snapshot(page), stateAfterLeaving);
    assert.deepEqual(harness.writes, [], 'Old frames and completions must not write after route exit');
    assert.equal(harness.frames.length, 0);
  });
}

test('an old route completion cannot unmount controls after the reader reappears', () => {
  const harness = createPage({ menuVisible: true });
  const { page } = harness;
  page.aboutToAppear();
  harness.flushFrames();
  harness.finishAll();
  const oldAnimationCount = harness.animations.length;
  harness.setVisibility(false, false);
  harness.flushFrames();
  const oldRouteExits = harness.animations.slice(oldAnimationCount);
  page.aboutToDisappear();

  const newAnimationStart = harness.animations.length;
  page.menuBarVisible = true;
  page.aboutToAppear();
  harness.flushFrames();
  for (const entrance of harness.animations.slice(newAnimationStart)) {
    harness.finish(entrance);
  }
  harness.setVisibility(false, false);
  for (const exit of oldRouteExits) {
    harness.finish(exit);
  }
  assert.equal(page.bottomBarMounted, true);
  assert.equal(page.menuBarMounted, true);
  harness.flushFrames();
  harness.finishAll();
  assert.equal(page.bottomBarMounted, false);
  assert.equal(page.menuBarMounted, false);
});

test('a loading or error status keeps the bar present while the menu exits independently', () => {
  // Index passes status presence independently through bottomBarVisible for
  // loading/errors. This test exercises that production ReaderFullscreenPage
  // input, rather than replacing its visibility decision with a test function.
  const harness = createPage({ statusVisible: true, menuVisible: true });
  const { page } = harness;
  page.aboutToAppear();
  harness.flushFrames();
  harness.finishAll();
  const measuredMenuHeight = 220;
  page.menuBarMeasuredHeight = measuredMenuHeight;

  harness.setVisibility(true, false);
  assert.equal(page.menuBarHeight(), measuredMenuHeight);
  assert.equal(page.menuBarMounted, true);
  harness.flushFrames();
  assert.equal(page.shouldDisplayBottomBar(), true);
  assert.equal(page.bottomBarMounted, true);
  assert.equal(page.bottomBarOpacity, 1);
  assert.equal(page.menuBarMounted, true);
  assert.equal(page.menuBarOpacity, 0);
  assert.equal(page.menuBarHeight(), 0);
  assert.equal(page.menuBarMeasuredHeight, measuredMenuHeight);
  harness.finishAll();
  assert.equal(page.bottomBarMounted, true);
  assert.equal(page.menuBarMounted, false);
  assert.equal(page.menuBarMeasuredHeight, 0);
  assert.equal(page.menuBarHeightAutomatic, true);
  assert.equal(page.bottomBarHeight(), 'auto');

  harness.setVisibility(false, false);
  harness.flushFrames();
  harness.finishAll();
  assert.equal(page.bottomBarMounted, false);
  assert.equal(page.bottomBarHeight(), 0);
});

test('reopening a collapsing menu restores intrinsic height without stale exit cleanup', () => {
  const harness = createPage({ statusVisible: true, menuVisible: true });
  const { page } = harness;
  page.aboutToAppear();
  harness.flushFrames();
  harness.finishAll();
  const measuredMenuHeight = 220;
  page.menuBarMeasuredHeight = measuredMenuHeight;

  const oldAnimationCount = harness.animations.length;
  harness.setVisibility(true, false);
  harness.flushFrames();
  const oldExits = harness.animations.slice(oldAnimationCount);
  assert.equal(page.menuBarHeight(), 0);
  assert.equal(page.menuBarMounted, true);

  harness.setVisibility(true, true);
  harness.flushFrames();
  assert.equal(page.menuBarHeight(), 'auto');
  assert.equal(page.menuBarMeasuredHeight, measuredMenuHeight);
  const reopenedState = snapshot(page);
  for (const exit of oldExits) {
    harness.finish(exit);
  }
  assert.deepEqual(snapshot(page), reopenedState);
  harness.finishAll();
  assert.equal(page.menuBarMounted, true);
  assert.equal(page.menuBarHeight(), 'auto');

  harness.setVisibility(true, false);
  assert.equal(page.menuBarHeight(), measuredMenuHeight);
  harness.flushFrames();
  harness.finishAll();
  assert.equal(page.menuBarMounted, false);
  assert.equal(page.bottomBarMounted, true);
});
