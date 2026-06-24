import { EhTagTranslator } from '../ehviewer/EhNative';

export function formatRating(value: number): string {
  return value >= 0 ? value.toFixed(1) : 'N/A';
}

export function compactTags(tags: string[]): string {
  const values = tags
    .slice(0, 4)
    .map((tag: string) => {
      const separatorIndex = tag.indexOf(':');
      if (separatorIndex < 0) {
        return EhTagTranslator.translateFullTag(tag);
      }
      const namespace = tag.substring(0, separatorIndex);
      const body = tag.substring(separatorIndex + 1);
      return EhTagTranslator.translateTag(namespace, body);
    });
  return values.join('  ·  ');
}

export function categoryColor(categoryLabel: string): string {
  switch (categoryLabel.toLowerCase()) {
    case 'doujinshi':
      return '#F44336';
    case 'manga':
      return '#FF9800';
    case 'artist cg sets':
    case 'artist cg':
    case 'artistcg':
      return '#FBC02D';
    case 'game cg sets':
    case 'game cg':
    case 'gamecg':
      return '#4CAF50';
    case 'western':
      return '#8BC34A';
    case 'non-h':
      return '#2196F3';
    case 'image sets':
    case 'image set':
    case 'imageset':
      return '#3F51B5';
    case 'cosplay':
      return '#9C27B0';
    case 'asian porn':
    case 'asianporn':
      return '#9575CD';
    case 'misc':
      return '#F06292';
    default:
      return '#757575';
  }
}

export function metaLine(label: string, value: string): string {
  return `${label}: ${value.length > 0 ? value : '-'}`;
}

export function formatByteSize(value: number): string {
  if (value <= 0) {
    return '0 B';
  }
  if (value >= 1024 * 1024) {
    return `${(value / 1024 / 1024).toFixed(1)} MB`;
  }
  if (value >= 1024) {
    return `${(value / 1024).toFixed(0)} KB`;
  }
  return `${Math.round(value)} B`;
}

export function formatBytesPerSecond(value: number): string {
  if (value <= 0) {
    return '--';
  }
  if (value >= 1024 * 1024) {
    return `${(value / 1024 / 1024).toFixed(1)} MB/s`;
  }
  if (value >= 1024) {
    return `${(value / 1024).toFixed(0)} KB/s`;
  }
  return `${Math.round(value)} B/s`;
}

export function formatRemainingSeconds(value: number): string {
  if (value < 0) {
    return '--';
  }
  if (value < 60) {
    return `${value}s`;
  }
  const minutes = Math.floor(value / 60);
  const seconds = value % 60;
  return `${minutes}m ${seconds}s`;
}
