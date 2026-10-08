import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

// Run explicitly after a successful SDK build; node --test tests/*.test.mjs
// intentionally excludes this compiler-output check. This verifies ArkUI's
// generated reactive branches, without claiming device rendering validation.
// node tests/check-download-view-compiled.mjs
const projectRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const buildRoot = join(projectRoot, 'entry', 'build');

function walkFiles(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    return entry.isDirectory() ? walkFiles(path) : entry.isFile() ? [path] : [];
  });
}

let files;
try {
  files = execFileSync('rg', ['--files', '--hidden', '--no-ignore', buildRoot], {
    encoding: 'utf8', maxBuffer: 16 * 1024 * 1024
  }).trim().split('\n');
} catch {
  files = walkFiles(buildRoot);
}
const candidates = files.filter((path) => /(?:^|[/\\])DownloadQueueView\.(?:ts|js)$/.test(path))
  .sort((left, right) => Number(right.endsWith('.ts')) - Number(left.endsWith('.ts')) ||
    statSync(right).mtimeMs - statSync(left).mtimeMs);
assert.ok(candidates.length, 'No compiled DownloadQueueView found under entry/build; build the HAP first');
const compiledPath = candidates[0];
const compiled = readFileSync(compiledPath, 'utf8');

// Generated function/object blocks contain strings and comments. Ignore their
// braces so metadata paths and compiler comments do not affect extraction.
function blockAt(source, opening) {
  assert.equal(source[opening], '{', 'Expected an opening brace');
  let depth = 0;
  let quote = '';
  let comment = '';
  for (let index = opening; index < source.length; index++) {
    const character = source[index];
    const next = source[index + 1];
    if (comment === 'line') {
      if (character === '\n') comment = '';
      continue;
    }
    if (comment === 'block') {
      if (character === '*' && next === '/') { comment = ''; index++; }
      continue;
    }
    if (quote) {
      if (character === '\\') index++;
      else if (character === quote) quote = '';
      continue;
    }
    if (character === '/' && next === '/') { comment = 'line'; index++; continue; }
    if (character === '/' && next === '*') { comment = 'block'; index++; continue; }
    if (character === '"' || character === "'" || character === '`') { quote = character; continue; }
    if (character === '{') depth++;
    if (character === '}' && --depth === 0) return source.slice(opening + 1, index);
  }
  assert.fail('Unclosed generated function/object block');
}

const initialRenderMatch = /\binitialRender\s*\(\s*\)\s*\{/.exec(compiled);
assert.ok(initialRenderMatch, 'Missing compiled initialRender()');
const initialRender = blockAt(compiled, initialRenderMatch.index + initialRenderMatch[0].lastIndexOf('{'));
const observerPattern = /this\.observeComponentCreation2\s*\(\s*\([^)]*\)\s*=>\s*\{/g;
const observers = [...initialRender.matchAll(observerPattern)]
  .map((match) => blockAt(initialRender, match.index + match[0].lastIndexOf('{')));
const modeObserver = observers.find((body) => /\bIf\.create\s*\(\s*\)/.test(body) &&
  /\bif\s*\(\s*this\.viewMode\s*===\s*DOWNLOAD_VIEW_ACTIVE\s*\)/.test(body));
assert.ok(modeObserver,
  'Download mode must be observed by an ArkUI If node, not selected inside an unobserved content callback');
assert.match(initialRender, /\bIf\.pop\s*\(\s*\)/, 'Generated download-mode If node must be closed');

const branchPattern = /this\.ifElseBranchUpdateFunction\s*\(\s*(\d+)\s*,\s*\(\s*\)\s*=>\s*\{/g;
const branches = [...modeObserver.matchAll(branchPattern)].map((match) => ({
  index: Number(match[1]),
  body: blockAt(modeObserver, match.index + match[0].lastIndexOf('{'))
}));
assert.equal(branches.length, 2, 'Download-mode If must have distinct active and downloaded branches');
assert.deepEqual(branches.map((branch) => branch.index), [0, 1]);

for (const [branchIndex, mode, page] of [
  [0, 'DOWNLOAD_VIEW_ACTIVE', 'ActivePage'],
  [1, 'DOWNLOAD_VIEW_DOWNLOADED', 'DownloadedPage']
]) {
  const branch = branches.find((current) => current.index === branchIndex);
  const constructorMatch = /\bnew\s+ContentTransition\s*\(\s*this\s*,\s*\{/.exec(branch.body);
  assert.ok(constructorMatch, `Missing ContentTransition in ${mode} branch`);
  const parameters = blockAt(branch.body,
    constructorMatch.index + constructorMatch[0].lastIndexOf('{'));
  assert.match(parameters, new RegExp(`\\bchangeKey\\s*:\\s*${mode}\\b`),
    `${mode} must use its own fixed transition key`);
  const contentMatch = /\bcontent\s*:\s*\(\s*\)\s*(?::\s*void\s*)?=>\s*\{/.exec(parameters);
  assert.ok(contentMatch, `Missing content callback in ${mode} branch`);
  const content = blockAt(parameters, contentMatch.index + contentMatch[0].lastIndexOf('{'));
  assert.match(content, new RegExp(`this\\.${page}(?:\\.bind\\(this\\))?\\s*\\(\\s*\\)`),
    `${mode} transition must render ${page}`);
  assert.doesNotMatch(content, /\bif\s*\(|\bviewMode\b/,
    'Transition content must not retain a nonreactive download-mode condition');
  const otherPage = page === 'ActivePage' ? 'DownloadedPage' : 'ActivePage';
  assert.doesNotMatch(content, new RegExp(`this\\.${otherPage}\\b`),
    `${mode} transition must not render the other download page`);
}

function compiledMethod(name) {
  const match = new RegExp(`(?:private\\s+)?${name}\\s*\\(`).exec(compiled);
  assert.ok(match, `Missing compiled ${name}()`);
  const opening = compiled.indexOf('{', match.index);
  const signature = compiled.slice(match.index, opening).replace(/^private\s+/, '');
  return `${signature}{${blockAt(compiled, opening)}}`;
}

const buttonMethod = compiledMethod('TextActionButton');
const labelMethod = compiledMethod('ActionButtonLabel');
assert.match(buttonMethod, /Button\.backgroundColor\(primary\(\)/,
  'Button color must resolve current state in its observed update');
assert.match(buttonMethod, /Button\.enabled\(enabled\(\)\)/,
  'Bulk-button availability must resolve current state in its observed update');
assert.match(buttonMethod, /Button\.accessibilityText\(label\(\)\)/,
  'Button accessibility must resolve the current command in its observed update');
assert.match(buttonMethod, /forEachUpdateFunction\(elmtId,\s*\[label\(\)\]/,
  'Animated labels must observe their current value, not a captured primitive');
assert.match(labelMethod, /SymbolGlyph\.create\(symbol\(\)\)/,
  'Command symbol must resolve current state in its observed update');

// Execute the SDK-generated builder callbacks. Getters register their current
// observation node; a state change reruns only those observed callbacks. This
// catches the original primitive-argument freeze that method-only tests missed.
// Native rendering and animation timing remain simulated boundaries.
const nativeNodes = new Map();
let currentHost;
function nativeComponent(name) {
  return new Proxy({}, {
    get: (_target, operation) => (...values) => {
      const id = currentHost?.observing;
      if (id === undefined || operation === 'pop') return;
      const key = `${name}:${id}`;
      const node = nativeNodes.get(key) || { id, component: name, values: new Map() };
      node.values.set(operation, values);
      nativeNodes.set(key, node);
    }
  });
}
const context = {
  ButtonType: { Normal: 'normal' }, Curve: { EaseOut: 'easeOut' },
  FlexAlign: { Center: 'center' }, FontWeight: { Medium: 'medium' },
  TextAlign: { Center: 'center' }, TransitionEffect: { IDENTITY: 'identity' },
  listItemTransition: () => 'transition', Context: { animation: () => {} }
};
for (const name of ['Button', 'Stack', 'If', 'ForEach', 'Row', 'SymbolGlyph', 'Text']) {
  context[name] = nativeComponent(name);
}
const GeneratedBuilders = vm.runInNewContext(stripTypeScriptTypes(`(class {
  ${buttonMethod}
  ${labelMethod}
})`), context);
const host = new GeneratedBuilders();
currentHost = host;
host.observing = undefined;
host.nextId = 0;
host.callbacks = new Map();
host.dependencies = new Set();
host.forEachChildren = new Map();
host.labelGenerations = 0;
host.state = { label: '继续', symbol: 'play', primary: true, enabled: true };
host.observeComponentCreation2 = function (callback) {
  const id = ++this.nextId;
  this.callbacks.set(id, callback);
  this.runObserved(id, true);
};
host.runObserved = function (id, initial = false) {
  const previous = this.observing;
  this.observing = id;
  this.callbacks.get(id)?.(id, initial);
  this.observing = previous;
};
host.readState = function () {
  if (this.observing !== undefined) this.dependencies.add(this.observing);
  return this.state;
};
host.ifElseBranchUpdateFunction = (_branch, action) => action();
host.forEachUpdateFunction = function (id, values, generate, keyForValue) {
  const children = this.forEachChildren.get(id) || new Map();
  const currentKeys = new Set(values.map(keyForValue));
  for (const [key, ids] of children) {
    if (currentKeys.has(key)) continue;
    for (const childId of ids) {
      this.callbacks.delete(childId);
      this.dependencies.delete(childId);
      for (const [nodeKey, node] of nativeNodes) if (node.id === childId) nativeNodes.delete(nodeKey);
    }
    children.delete(key);
  }
  for (const value of values) {
    const key = keyForValue(value);
    if (children.has(key)) continue;
    const before = this.nextId;
    generate(value);
    children.set(key, Array.from({ length: this.nextId - before }, (_unused, index) => before + index + 1));
    this.labelGenerations++;
  }
  this.forEachChildren.set(id, children);
};
host.TextActionButton(() => host.readState().symbol, () => host.readState().label,
  () => host.readState().primary, () => {}, () => host.readState().enabled, true);
const initialButton = [...nativeNodes.values()].find((node) => node.component === 'Button');
assert.ok(initialButton);
const buttonId = initialButton.id;
for (const state of [
  { label: '暂停', symbol: 'pause', primary: false, enabled: true },
  { label: '暂停', symbol: 'pause', primary: false, enabled: true }, // Progress-only update.
  { label: '继续', symbol: 'play', primary: true, enabled: true },
  { label: '重试', symbol: 'play', primary: true, enabled: false }
]) {
  const previousGenerations = host.labelGenerations;
  const previousLabel = host.state.label;
  host.state = state;
  for (const id of [...host.dependencies]) if (host.callbacks.has(id)) host.runObserved(id);
  const button = [...nativeNodes.values()].find((node) => node.component === 'Button');
  const glyph = [...nativeNodes.values()].find((node) => node.component === 'SymbolGlyph');
  const text = [...nativeNodes.values()].find((node) => node.component === 'Text');
  assert.equal(button.id, buttonId, 'Command changes must retain the native Button');
  assert.equal(button.values.get('accessibilityText')[0], state.label);
  assert.equal(button.values.get('enabled')[0], state.enabled);
  assert.equal(button.values.get('backgroundColor')[0] === '#C86B8C', state.primary);
  assert.equal(glyph.values.get('create')[0], state.symbol);
  assert.equal(text.values.get('create')[0], state.label);
  if (state.label === previousLabel) {
    assert.equal(host.labelGenerations, previousGenerations, 'Progress must not recreate the command label');
  }
}

console.log(`PASS: ${relative(projectRoot, compiledPath)}`);
console.log('Download mode uses reactive ArkUI If branches; each transition renders its fixed page.');
console.log('SDK-generated control updates refresh command, symbol, color and enabled state without remounting the Button.');
