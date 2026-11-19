const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const { test } = require('node:test');

const source = fs.readFileSync(
  require('node:path').join(__dirname, '../web/activity_classifier.js'), 'utf8',
);

function loadClassifier(fetch) {
  const context = vm.createContext({
    fetch, AbortSignal, console: { warn() {} },
  });
  vm.runInContext(source, context);
  context.miagedClassifyActivity = async () => 'Culture';
  return context.miagedAnalyzeActivity;
}

test('Ollama reçoit l’image et renvoie catégorie et titre', async () => {
  const analyze = loadClassifier(async (url, options) => {
    if (url.endsWith('/api/tags')) {
      return { ok: true, json: async () => ({ models: [{ name: 'qwen2.5vl:3b' }] }) };
    }
    const body = JSON.parse(options.body);
    assert.equal(body.messages[0].images[0], 'aW1hZ2U=');
    assert.equal(body.stream, false);
    assert.ok(body.format.properties.category.enum.includes('Sport'));
    return { ok: true, json: async () => ({
      message: { content: JSON.stringify({ category: 'Sport', title: 'Yoga au parc' }) },
    }) };
  });
  const result = JSON.parse(await analyze('data:image/jpeg;base64,aW1hZ2U='));
  assert.deepEqual(result, { category: 'Sport', title: 'Yoga au parc', source: 'Ollama' });
});

test('Ollama absent laisse CLIP calculer la catégorie', async () => {
  const analyze = loadClassifier(async () => { throw new Error('Connexion refusée'); });
  const result = JSON.parse(await analyze('data:image/jpeg;base64,aW1hZ2U='));
  assert.equal(result.source, 'CLIP');
  assert.equal(result.category, 'Culture');
  assert.equal(result.title, '');
  assert.ok(result.warning);
});

test('Une catégorie Ollama invalide déclenche le repli CLIP', async () => {
  const analyze = loadClassifier(async (url) => ({
    ok: true,
    json: async () => url.endsWith('/api/tags')
      ? { models: [{ name: 'qwen2.5vl:3b' }] }
      : { message: { content: '{"category":"Inconnue","title":"Une sortie"}' } },
  }));
  const result = JSON.parse(await analyze('data:image/jpeg;base64,aW1hZ2U='));
  assert.equal(result.source, 'CLIP');
  assert.equal(result.category, 'Culture');
});
