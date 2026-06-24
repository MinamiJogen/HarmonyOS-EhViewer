export function rawBytesToString(bytes: Uint8Array): string {
  let result = '';
  const chunkSize = 8192;
  for (let offset = 0; offset < bytes.length; offset += chunkSize) {
    let chunk = '';
    const end = Math.min(offset + chunkSize, bytes.length);
    for (let index = offset; index < end; index++) {
      chunk += String.fromCharCode(bytes[index]);
    }
    result += chunk;
  }
  return result;
}

export function safeFileName(value: string, fallback: string): string {
  const cleaned = value
    .replace(/[\\/:*?"<>|]/g, '_')
    .replace(/\s+/g, ' ')
    .trim()
    .substring(0, 120);
  return cleaned.length > 0 ? cleaned : fallback;
}
