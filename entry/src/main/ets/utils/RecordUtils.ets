export function readObjectString(item: Record<string, Object>, key: string, fallback: string = ''): string {
  const value = item[key];
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'number') {
    return `${value}`;
  }
  return fallback;
}

export function readObjectNumber(item: Record<string, Object>, key: string, fallback: number = 0): number {
  const value = item[key];
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string') {
    const numericValue = Number(value);
    return Number.isFinite(numericValue) ? numericValue : fallback;
  }
  return fallback;
}

export function readObjectBoolean(item: Record<string, Object>, key: string, fallback: boolean = false): boolean {
  const value = item[key];
  if (typeof value === 'boolean') {
    return value;
  }
  if (typeof value === 'number') {
    return value !== 0;
  }
  if (typeof value === 'string') {
    return value === 'true' || value === '1';
  }
  return fallback;
}
