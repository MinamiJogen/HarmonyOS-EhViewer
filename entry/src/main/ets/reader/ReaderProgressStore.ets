export function parseReaderProgress(raw: string): Map<string, number> {
  const progressByGallery: Map<string, number> = new Map();
  try {
    const parsed = JSON.parse(raw) as Record<string, Object>;
    if (!parsed || Array.isArray(parsed)) {
      return progressByGallery;
    }
    for (const key of Object.keys(parsed)) {
      const value = parsed[key];
      let page = 0;
      if (typeof value === 'number') {
        page = value;
      } else if (typeof value === 'string') {
        page = Number(value);
      }
      if (key.length > 0 && Number.isFinite(page) && page > 0) {
        progressByGallery.set(key, Math.floor(page));
      }
    }
  } catch (error) {
  }
  return progressByGallery;
}

export function readerProgressSnapshot(progressByGallery: Map<string, number>): Record<string, number> {
  const snapshot: Record<string, number> = {};
  for (const key of progressByGallery.keys()) {
    const page = progressByGallery.get(key);
    if (page !== undefined && page > 0) {
      snapshot[key] = Math.floor(page);
    }
  }
  return snapshot;
}
