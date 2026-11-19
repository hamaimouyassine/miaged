let classifier;

globalThis.miagedPickActivityImage = (maxBytes) => new Promise((resolve, reject) => {
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = '.jpg,.jpeg,.png,.webp';
  input.hidden = true;

  input.addEventListener('cancel', () => {
    input.remove();
    resolve(null);
  }, { once: true });

  input.addEventListener('change', async () => {
    const file = input.files[0];
    input.remove();
    try {
      if (!file) {
        resolve(null);
        return;
      }
      if (file.size > maxBytes) throw new Error('Image trop volumineuse');
      resolve(new Uint8Array(await file.arrayBuffer()));
    } catch (error) {
      reject(error);
    }
  }, { once: true });

  document.body.append(input);
  try {
    input.showPicker();
  } catch (error) {
    input.remove();
    reject(error);
  }
});

globalThis.miagedDownloadActivityImage = async (url, maxBytes) => {
  const response = await fetch(url, {
    credentials: 'omit',
    signal: AbortSignal.timeout(20000),
  });
  if (!response.ok || !response.body) throw new Error('Image inaccessible');

  const reader = response.body.getReader();
  const chunks = [];
  let size = 0;
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    size += value.length;
    if (size > maxBytes) {
      await reader.cancel();
      throw new Error('Image trop volumineuse');
    }
    chunks.push(value);
  }
  return new Uint8Array(await new Blob(chunks).arrayBuffer());
};

const categories = {
  'playing a sport or exercising': 'Sport',
  'shopping in a store or at a market': 'Shopping',
  'visiting a museum or attending a concert or theatre show': 'Culture',
  'hiking in nature or enjoying outdoor scenery': 'Plein air',
  'cooking or dining at a restaurant': 'Gastronomie',
  'playing a game or doing a recreational hobby': 'Loisirs',
  'an unrelated object or scene': 'Autre',
};

globalThis.miagedClassifyActivity = async (imageUrl) => {
  classifier ??= import(
    'https://cdn.jsdelivr.net/npm/@huggingface/transformers@3.8.1'
  ).then(({ pipeline, env }) => {
    env.allowLocalModels = false;
    env.backends.onnx.wasm.numThreads = 1;
    return pipeline('zero-shot-image-classification',
      'Xenova/clip-vit-base-patch32', { device: 'wasm', dtype: 'q8' });
  }).catch((error) => {
    classifier = undefined;
    throw error;
  });

  const classify = await classifier;
  const predictions = await classify(imageUrl, Object.keys(categories));
  return categories[predictions[0].label];
};
