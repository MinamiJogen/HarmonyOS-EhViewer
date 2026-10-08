import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../entry/src/main/ets/pages/Index.ets', import.meta.url), 'utf8');

function method(name) {
  const start = source.indexOf(`  private ${name}(`);
  assert.notEqual(start, -1, `Missing production method ${name}`);
  const end = source.indexOf('\n  }', start);
  assert.notEqual(end, -1);
  return source.slice(start, end + 5);
}

const Harness = vm.runInNewContext(stripTypeScriptTypes(`(class {
  ${['currentFilterRule', 'updateFilterRuleEnabledInState', 'animateManagedListChange', 'removeBookmark'].map(method).join('\n')}
})`), { Curve: { EaseOut: 'ease-out' } });

test('stable rule identity reads replacement snapshots and a failed-toggle rollback', () => {
  const page = new Harness();
  const captured = { id: 7, mode: 1, text: 'original', enabled: true };
  page.filterRules = [captured];
  page.updateFilterRuleEnabledInState(7, false);
  assert.notEqual(page.currentFilterRule(captured), captured);
  assert.equal(page.currentFilterRule(captured).enabled, false);
  page.updateFilterRuleEnabledInState(7, true);
  assert.equal(page.currentFilterRule(captured).enabled, true);
  page.filterRules = [{ ...captured, text: 'reloaded', enabled: false }];
  assert.equal(page.currentFilterRule(captured).text, 'reloaded');
  assert.equal(page.currentFilterRule(captured).enabled, false);
});

test('an exiting rule retains its display snapshot without resolving another row', () => {
  const page = new Harness();
  const exiting = { id: 7, mode: 1, text: 'removed', enabled: true };
  page.filterRules = [{ ...exiting, id: 8, text: 'remaining' }];
  assert.equal(page.currentFilterRule(exiting), exiting);
});

test('bookmark deletion animates only UI state and persists after the animation transaction', () => {
  const page = new Harness();
  const events = [];
  page.bookmarks = [{ url: 'a' }, { url: 'b' }];
  page.getUIContext = () => ({
    animateTo(options, update) {
      assert.equal(options.duration, 200);
      events.push('animation-start');
      update();
      events.push('animation-end');
    }
  });
  page.saveBookmarks = () => {
    events.push('persist');
    assert.equal(page.bookmarks.length, 1);
    assert.equal(page.bookmarks[0].url, 'b');
  };
  page.removeBookmark('a');
  assert.deepEqual(events, ['animation-start', 'animation-end', 'persist']);
});
