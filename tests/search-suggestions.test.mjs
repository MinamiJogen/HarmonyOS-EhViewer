import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import vm from 'node:vm';

// Execute the actual page methods with a deterministic timer and lightweight
// platform stubs. This covers event ordering without requiring an ArkUI device.
// Run with Node.js 22.13+: node --test tests/search-suggestions.test.mjs
const pageSource = readFileSync(new URL('../entry/src/main/ets/pages/Index.ets', import.meta.url), 'utf8');
const methodNames = [
  'cancelSearchInputBlurTimer',
  'hideSearchSuggestionOverlay',
  'hideSearchSuggestionOverlayKeepingInputActive',
  'handleSearchInputFocus',
  'handleSearchInputUserInteraction',
  'handleSearchInputBlur',
  'setNativeQuery',
  'setNativeQueryFromSearchInput',
  'applyTagSuggestion',
  'applyHistorySuggestion',
  'shouldShowSearchHistoryOverlay',
  'shouldShowSearchAutoCompleteOverlay',
  'shouldShowSearchSuggestionOverlay',
  'handleSearchScrollProgress'
];

function pageMethod(name) {
  const start = pageSource.indexOf(`\n  private ${name}(`);
  assert.notEqual(start, -1, `Missing page method: ${name}`);
  const tail = pageSource.slice(start + 1);
  const nextMethod = tail.slice(1).search(/\n  (?:private |@Builder)/);
  assert.notEqual(nextMethod, -1, `Missing end of page method: ${name}`);
  return tail.slice(0, nextMethod + 1);
}

const harnessSource = stripTypeScriptTypes(`(class SearchHarness {
  ${methodNames.map(pageMethod).join('\n')}
})`);
const ScrollState = { Idle: 0, Scroll: 1, Fling: 2 };

function createPage() {
  let now = 0;
  let nextTimerId = 0;
  const timers = new Map();
  const Harness = vm.runInNewContext(harnessSource, {
    NAV_SEARCH: 1,
    ScrollState,
    setTimeout(callback, delay) {
      const id = ++nextTimerId;
      timers.set(id, { callback, at: now + delay });
      return id;
    },
    clearTimeout(id) {
      timers.delete(id);
    }
  });
  const page = new Harness();
  Object.assign(page, {
    nativeQuery: '',
    searchInputFocused: false,
    searchSuggestionsVisible: false,
    searchInputBlurTimerId: -1,
    searchHistoryExpanded: false,
    searchHistoryQueries: ['cats'],
    searchHistorySuggestions: [],
    tagSuggestions: [],
    searchFilterSheetVisible: false,
    activeSection: 1,
    nativeViewMode: 'list',
    fullScreenWebUrl: '',
    isReady: true,
    loginGate: false,
    routeLoading: false,
    persistedQuery: '',
    writeValue(key, value) {
      assert.equal(key, 'native_query');
      this.persistedQuery = value;
    },
    updateSearchSuggestions() {
      this.searchHistorySuggestions = this.searchHistoryQueries.filter((query) =>
        query.startsWith(this.nativeQuery) && query !== this.nativeQuery);
      this.tagSuggestions = this.nativeQuery.trim().length > 0 ? [{ key: this.nativeQuery }] : [];
    },
    buildSearchTokenFromSuggestion(item) { return item.token; },
    replaceTagSuggestionTail(token) { return token; },
    shouldShowLoginGate() { return this.loginGate; },
    shouldShowNativeRouteLoading() { return this.routeLoading; },
    shouldAutoLoadSearchWaterfall() { return false; },
    shouldLoadWaterfallByRemainingContent() { return false; }
  });
  return {
    page,
    advance(ms) {
      now += ms;
      for (const [id, timer] of timers) {
        if (timer.at <= now) {
          timers.delete(id);
          timer.callback();
        }
      }
    }
  };
}

function assertOverlay(page, visible) {
  assert.equal(page.shouldShowSearchSuggestionOverlay(), visible);
}

test('typing opens suggestions after automatic focus without an additional touch', () => {
  const { page } = createPage();
  page.handleSearchInputFocus();
  assertOverlay(page, false);
  page.setNativeQueryFromSearchInput('cat');
  assertOverlay(page, true);
  assert.equal(page.persistedQuery, 'cat');
});

test('new typing invalidates a pending blur before its 120 ms deadline', () => {
  const { page, advance } = createPage();
  page.handleSearchInputUserInteraction();
  page.handleSearchInputBlur();
  advance(119);
  page.setNativeQueryFromSearchInput('cat');
  advance(1);
  assertOverlay(page, true);
  assert.equal(page.searchInputBlurTimerId, -1);
});

test('IME updates and pasted text recover after the old blur has already fired', () => {
  for (const value of ['mao', '猫', 'cats pasted from clipboard']) {
    const { page, advance } = createPage();
    page.handleSearchInputUserInteraction();
    page.handleSearchInputBlur();
    advance(120);
    assertOverlay(page, false);
    page.setNativeQueryFromSearchInput(value);
    assertOverlay(page, true);
    assert.equal(page.nativeQuery, value);
  }
});

test('IME preview activity recovers suggestions without persisting uncommitted text', () => {
  const { page, advance } = createPage();
  page.setNativeQuery('cats ');
  page.hideSearchSuggestionOverlay();
  page.handleSearchInputBlur();
  page.setNativeQueryFromSearchInput('cats ', { offset: 5, value: 'mao' });
  advance(120);
  assertOverlay(page, true);
  assert.equal(page.nativeQuery, 'cats ');
  assert.equal(page.persistedQuery, 'cats ');
  page.setNativeQueryFromSearchInput('cats 猫');
  assertOverlay(page, true);
  assert.equal(page.persistedQuery, 'cats 猫');
});

test('selecting history or a tag hides the overlay and the next edit reopens it', () => {
  for (const apply of [
    (page) => page.applyHistorySuggestion('cats'),
    (page) => page.applyTagSuggestion({ token: 'animal:"cat$"' })
  ]) {
    const { page, advance } = createPage();
    page.handleSearchInputUserInteraction();
    page.setNativeQueryFromSearchInput('cat');
    page.handleSearchInputBlur();
    apply(page);
    page.setNativeQueryFromSearchInput(page.nativeQuery);
    advance(120);
    assertOverlay(page, false);
    // A late native blur may also arrive after the suggestion's click callback.
    page.handleSearchInputBlur();
    page.setNativeQueryFromSearchInput(`${page.nativeQuery} dog`);
    advance(120);
    assertOverlay(page, true);
  }
});

test('clear restores history even if the input activity flag was dismissed', () => {
  const { page } = createPage();
  page.setNativeQuery('cats');
  page.hideSearchSuggestionOverlay();
  page.setNativeQueryFromSearchInput('');
  assertOverlay(page, true);
  assert.equal(page.shouldShowSearchHistoryOverlay(), true);
});

test('real blur still dismisses suggestions when there is no newer interaction', () => {
  const { page, advance } = createPage();
  page.handleSearchInputUserInteraction();
  page.setNativeQueryFromSearchInput('cat');
  page.handleSearchInputBlur();
  advance(119);
  assertOverlay(page, true);
  advance(1);
  assertOverlay(page, false);
});

test('restoring a query and focus after returning from detail does not open the overlay', () => {
  const { page, advance } = createPage();
  page.handleSearchInputUserInteraction();
  page.setNativeQueryFromSearchInput('cat');
  page.hideSearchSuggestionOverlay();
  page.nativeViewMode = 'detail';
  page.handleSearchInputBlur();
  page.nativeViewMode = 'list';
  page.setNativeQuery('cats');
  page.handleSearchInputFocus();
  page.setNativeQueryFromSearchInput('cats');
  advance(120);
  assertOverlay(page, false);
  page.setNativeQueryFromSearchInput('cats dog');
  assertOverlay(page, true);
});

test('a same-value echo after submission leaves the overlay dismissed', () => {
  const { page } = createPage();
  page.handleSearchInputUserInteraction();
  page.setNativeQueryFromSearchInput('cats');
  page.hideSearchSuggestionOverlay();
  page.setNativeQueryFromSearchInput('cats', { offset: -1, value: '' });
  assertOverlay(page, false);
});

test('layout and keyboard scroll callbacks preserve suggestions; a user scroll dismisses them', () => {
  const { page } = createPage();
  page.handleSearchInputUserInteraction();
  page.setNativeQueryFromSearchInput('cat');
  page.handleSearchScrollProgress(0, ScrollState.Idle);
  page.handleSearchScrollProgress(80, ScrollState.Idle);
  page.handleSearchScrollProgress(0, ScrollState.Scroll);
  page.handleSearchScrollProgress(30, ScrollState.Fling);
  assertOverlay(page, true);
  page.handleSearchScrollProgress(10, ScrollState.Scroll);
  assertOverlay(page, false);
  page.setNativeQueryFromSearchInput('cats');
  assertOverlay(page, true);
});

test('typing cannot expose suggestions over unrelated pages or blocking overlays', () => {
  for (const [key, value] of [
    ['activeSection', 0],
    ['nativeViewMode', 'detail'],
    ['fullScreenWebUrl', 'https://example.com'],
    ['isReady', false],
    ['loginGate', true],
    ['routeLoading', true]
  ]) {
    const { page } = createPage();
    page[key] = value;
    page.setNativeQueryFromSearchInput('cat');
    assertOverlay(page, false);
  }
});
