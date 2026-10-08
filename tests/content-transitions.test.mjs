import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';

// Execute the production fields, lifecycle methods, watcher, and frame callback.
// The harness only delivers ArkUI-style key changes and queued frames. It does
// not render ArkUI or verify device animation, child layout, or scroll position.
// Run with Node.js 22.13+: node --test tests/content-transitions.test.mjs
const source = readFileSync(new URL('../entry/src/main/ets/components/ContentTransition.ets', import.meta.url), 'utf8');
const componentStart = source.indexOf('export struct ContentTransition {');
assert.notEqual(componentStart, -1, 'Missing ContentTransition');
const componentSource = source.slice(componentStart);
const fieldsStart = componentSource.indexOf('{') + 1;
const fieldsEnd = componentSource.indexOf('\n  aboutToAppear(');
assert.notEqual(fieldsEnd, -1, 'Missing ContentTransition lifecycle');
const keyWatcher = componentSource.match(/@Watch\('([^']+)'\)\s+changeKey\s*:/)?.[1];
assert.ok(keyWatcher, 'Missing changeKey watcher');
const fields = componentSource.slice(fieldsStart, fieldsEnd)
  .replace(/@(?:Prop|State|BuilderParam)\b\s*/g, '')
  .replace(/@Watch\('[^']*'\)\s*/g, '');

function componentMethod(name) {
  const start = componentSource.search(new RegExp(`\\n  (?:private )?${name}\\(`));
  assert.notEqual(start, -1, `Missing transition method: ${name}`);
  const tail = componentSource.slice(start + 1);
  const nextMethod = tail.slice(1).search(/\n  (?:private |aboutTo|@Builder)/);
  assert.notEqual(nextMethod, -1, `Missing end of transition method: ${name}`);
  return tail.slice(0, nextMethod + 1);
}

const callbackStart = source.indexOf('class ContentTransitionFrameCallback extends FrameCallback {');
assert.notEqual(callbackStart, -1, 'Missing production frame callback');
const callbackEnd = source.indexOf('\n}\n', callbackStart);
assert.notEqual(callbackEnd, -1, 'Missing end of production frame callback');
const callbackSource = source.slice(callbackStart, callbackEnd + 3);
const harnessSource = stripTypeScriptTypes(`(() => {
  ${callbackSource}
  return {
    TransitionFrameCallback: ContentTransitionFrameCallback,
    Harness: class TransitionHarness {
      ${fields}
      ${['aboutToAppear', 'aboutToDisappear', keyWatcher].map(componentMethod).join('\n')}
    }
  };
})()`);

function createTransition({ animateOnAppear = true } = {}) {
  const frames = [];
  const animations = [];
  const writes = [];
  const { Harness, TransitionFrameCallback } = vm.runInNewContext(harnessSource, {
    FrameCallback: class FrameCallback {},
    Curve: { EaseOut: 'ease-out' }
  });
  const component = new Proxy(new Harness(), {
    set(target, property, value) {
      writes.push(property);
      target[property] = value;
      return true;
    }
  });
  component.animateOnAppear = animateOnAppear;
  component.getUIContext = () => ({
    postFrameCallback(callback) {
      assert.ok(callback instanceof TransitionFrameCallback, 'Use the production frame callback');
      frames.push(callback);
    },
    animateTo(options, mutation) {
      assert.equal(options.duration, 200, 'Content changes animate for 200 ms');
      assert.equal(options.curve, 'ease-out');
      animations.push(options);
      mutation();
    }
  });
  writes.length = 0;

  return {
    component,
    frames,
    animations,
    writes,
    deliverFrame() {
      const callback = frames.shift();
      assert.ok(callback, 'Missing pending frame');
      callback.onFrame(0);
    },
    setKey(value) {
      // Emulate @Watch delivery, without implementing the production animation.
      if (component.changeKey !== value) {
        component.changeKey = value;
        component[keyWatcher]();
      }
    }
  };
}

function snapshot(component) {
  return {
    active: component.active,
    generation: component.generation,
    opacity: component.contentOpacity,
    offsetY: component.contentOffsetY
  };
}

test('initial mounting prepares the content before its 200 ms entrance starts on the next frame', () => {
  const harness = createTransition();
  const { component } = harness;
  assert.equal(component.animateOnAppear, true);
  assert.deepEqual(snapshot(component), { active: false, generation: 0, opacity: 1, offsetY: 0 });

  component.aboutToAppear();
  assert.deepEqual(snapshot(component), { active: true, generation: 1, opacity: 0, offsetY: 8 });
  assert.equal(harness.frames.length, 1);
  assert.equal(harness.animations.length, 0);

  harness.deliverFrame();
  assert.deepEqual(snapshot(component), { active: true, generation: 1, opacity: 1, offsetY: 0 });
  assert.equal(harness.animations.length, 1);
  assert.equal(harness.animations[0].duration, 200);
});

test('disabling the initial entrance still animates later semantic key changes', () => {
  const harness = createTransition({ animateOnAppear: false });
  const { component } = harness;
  component.aboutToAppear();
  assert.deepEqual(snapshot(component), { active: true, generation: 0, opacity: 1, offsetY: 0 });
  assert.equal(harness.frames.length, 0);
  assert.equal(harness.animations.length, 0);

  harness.setKey('search:categories');
  assert.deepEqual(snapshot(component), { active: true, generation: 1, opacity: 0, offsetY: 8 });
  harness.deliverFrame();
  assert.equal(component.contentOpacity, 1);
  assert.equal(component.contentOffsetY, 0);
  assert.equal(harness.animations.length, 1);
});

test('rapid key changes invalidate all older queued frames without state writes', () => {
  const harness = createTransition();
  const { component } = harness;
  component.aboutToAppear();
  harness.setKey('home:default');
  harness.setKey('home:top:day');
  harness.setKey('home:top:month');
  assert.equal(harness.frames.length, 4);
  const latest = snapshot(component);

  for (let index = 0; index < 3; index++) {
    harness.writes.length = 0;
    harness.deliverFrame();
    assert.deepEqual(harness.writes, []);
    assert.deepEqual(snapshot(component), latest);
    assert.equal(harness.animations.length, 0);
  }

  harness.deliverFrame();
  assert.equal(component.contentOpacity, 1);
  assert.equal(component.contentOffsetY, 0);
  assert.equal(harness.animations.length, 1);
});

test('unmounting prevents queued callbacks and inactive key changes from mutating animation state', () => {
  const harness = createTransition();
  const { component } = harness;
  component.aboutToAppear();
  component.aboutToDisappear();
  const disappeared = snapshot(component);
  harness.setKey('home:top');
  assert.deepEqual(snapshot(component), disappeared);
  assert.equal(harness.frames.length, 1);

  harness.writes.length = 0;
  harness.deliverFrame();
  assert.deepEqual(harness.writes, []);
  assert.deepEqual(snapshot(component), disappeared);
  assert.equal(harness.animations.length, 0);
});

test('remounting the same component invalidates frames from its previous lifetime', () => {
  const harness = createTransition();
  const { component } = harness;
  component.aboutToAppear();
  component.aboutToDisappear();
  component.aboutToAppear();
  assert.equal(harness.frames.length, 2);
  const remounted = snapshot(component);

  harness.writes.length = 0;
  harness.deliverFrame();
  assert.deepEqual(harness.writes, []);
  assert.deepEqual(snapshot(component), remounted);
  assert.equal(harness.animations.length, 0);

  harness.deliverFrame();
  assert.equal(component.active, true);
  assert.equal(component.contentOpacity, 1);
  assert.equal(component.contentOffsetY, 0);
  assert.equal(harness.animations.length, 1);
});

test('content and progress updates with the same key do not restart the transition', () => {
  const harness = createTransition();
  const { component } = harness;
  harness.setKey('downloads:active');
  component.aboutToAppear();
  harness.deliverFrame();
  const appeared = snapshot(component);
  const payload = { progress: 12, items: ['first'] };
  component.content = () => payload;

  payload.progress = 50;
  payload.items.push('next');
  harness.setKey('downloads:active');
  component.fillHeight = true;
  assert.equal(component.content().progress, 50);
  assert.equal(component.content().items.length, 2);
  assert.deepEqual(snapshot(component), appeared);
  assert.equal(harness.frames.length, 0);
  assert.equal(harness.animations.length, 1);

  harness.setKey('downloads:completed');
  assert.equal(component.generation, appeared.generation + 1);
  assert.equal(harness.frames.length, 1);
  harness.deliverFrame();
  assert.equal(harness.animations.length, 2);
});
