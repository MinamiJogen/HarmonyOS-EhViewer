import { fileIo } from '@kit.CoreFileKit';

export interface GalleryDirectoryIdentity {
  gid: number;
  site: string;
  token: string;
  title: string;
}

interface GalleryDirectoryMarker {
  gid: number;
  site: string;
  token: string;
}

const GALLERY_DIRECTORY_IDENTITY_FILE: string = '.e-harmony-gallery.json';
const GALLERY_DIRECTORY_SEGMENT_MAX_BYTES: number = 180;

function utf8Length(value: string): number {
  let bytes = 0;
  for (let index = 0; index < value.length; index++) {
    const code = value.charCodeAt(index);
    if (code < 0x80) {
      bytes++;
    } else if (code < 0x800) {
      bytes += 2;
    } else if (code >= 0xD800 && code <= 0xDBFF && index + 1 < value.length &&
      value.charCodeAt(index + 1) >= 0xDC00 && value.charCodeAt(index + 1) <= 0xDFFF) {
      bytes += 4;
      index++;
    } else {
      bytes += 3;
    }
  }
  return bytes;
}

function truncateUtf8(value: string, limit: number): string {
  let bytes = 0;
  let result = '';
  for (let index = 0; index < value.length; index++) {
    const code = value.charCodeAt(index);
    let character = value.charAt(index);
    if (code >= 0xD800 && code <= 0xDBFF && index + 1 < value.length &&
      value.charCodeAt(index + 1) >= 0xDC00 && value.charCodeAt(index + 1) <= 0xDFFF) {
      character += value.charAt(index + 1);
      index++;
    } else if (code >= 0xD800 && code <= 0xDFFF) {
      character = '_';
    }
    const length = utf8Length(character);
    if (bytes + length > limit) {
      break;
    }
    result += character;
    bytes += length;
  }
  return result;
}

export function galleryDirectorySegment(title: string, gid: number): string {
  const cleaned = title.replace(/[\/\\:*?"<>|\u0000-\u001f\u007f]/g, '_')
    .replace(/\s+/g, ' ').replace(/^[.\s]+|[.\s]+$/g, '');
  const result = truncateUtf8(cleaned, GALLERY_DIRECTORY_SEGMENT_MAX_BYTES).replace(/[.\s]+$/, '');
  return result.length > 0 ? result : `画廊 ${gid}`;
}

function normalizedDirectory(path: string): string {
  const value = path.trim().replace(/\/+$/, '') || (path.trim() === '/' ? '/' : '');
  if (!value.startsWith('/') || value.indexOf('\0') >= 0) {
    return '';
  }
  for (const segment of value.split('/')) {
    if (segment === '.' || segment === '..') {
      return '';
    }
  }
  return value;
}

function childDirectory(parent: string, segment: string): string {
  return parent === '/' ? `/${segment}` : `${parent}/${segment}`;
}

export function isGalleryDirectory(path: string): boolean {
  const directory = normalizedDirectory(path);
  if (directory.length === 0) {
    return false;
  }
  try {
    return fileIo.accessSync(directory) && fileIo.statSync(directory).isDirectory();
  } catch (error) {
    return false;
  }
}

function matchingGalleryIdentity(directory: string, item: GalleryDirectoryIdentity): boolean {
  try {
    const identity = JSON.parse(fileIo.readTextSync(
      childDirectory(directory, GALLERY_DIRECTORY_IDENTITY_FILE))) as GalleryDirectoryMarker;
    return identity !== null && typeof identity.gid === 'number' && Number.isInteger(identity.gid) &&
      identity.gid === item.gid && typeof identity.site === 'string' && identity.site === item.site &&
      typeof identity.token === 'string' && identity.token === item.token;
  } catch (error) {
    return false;
  }
}

function reservedDirectory(path: string, reservedPaths: string[]): boolean {
  return reservedPaths.some((reserved: string): boolean => normalizedDirectory(reserved) === path);
}

export function writeGalleryDirectoryIdentity(directoryValue: string, item: GalleryDirectoryIdentity): boolean {
  const directory = normalizedDirectory(directoryValue);
  if (!isGalleryDirectory(directory) || !Number.isInteger(item.gid) || item.gid <= 0 || item.site.length === 0) {
    return false;
  }
  const marker = childDirectory(directory, GALLERY_DIRECTORY_IDENTITY_FILE);
  const temporary = `${marker}.tmp`;
  let file: fileIo.File | undefined = undefined;
  let temporaryCreated = false;
  try {
    if (fileIo.accessSync(marker)) {
      return matchingGalleryIdentity(directory, item);
    }
    const identity: GalleryDirectoryMarker = { gid: item.gid, site: item.site, token: item.token };
    const text = JSON.stringify(identity);
    file = fileIo.openSync(temporary, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    temporaryCreated = true;
    const written = fileIo.writeSync(file.fd, text);
    fileIo.closeSync(file.fd);
    file = undefined;
    if (written !== utf8Length(text)) {
      return false;
    }
    // A failed write never leaves a partial identity file behind.
    if (fileIo.accessSync(marker)) {
      return matchingGalleryIdentity(directory, item);
    }
    fileIo.renameSync(temporary, marker);
    temporaryCreated = false;
    return matchingGalleryIdentity(directory, item);
  } catch (error) {
    return false;
  } finally {
    if (file) {
      try {
        fileIo.closeSync(file.fd);
      } catch (error) {
      }
    }
    if (temporaryCreated) {
      try {
        fileIo.unlinkSync(temporary);
      } catch (error) {
      }
    }
  }
}

export function chooseGalleryDirectory(
  parentValue: string,
  item: GalleryDirectoryIdentity,
  reservedPaths: string[],
  currentDirValue: string = ''
): string {
  const parent = normalizedDirectory(parentValue);
  const currentDir = normalizedDirectory(currentDirValue);
  if (!isGalleryDirectory(parent)) {
    return '';
  }
  const segment = galleryDirectorySegment(item.title, item.gid);
  const identitySuffix = ` [${item.site.replace(/[^A-Za-z0-9_-]/g, '_')}-${item.gid}]`;
  for (let index = 0; index < 10000; index++) {
    const suffix = index === 0 ? '' : `${identitySuffix}${index > 1 ? ` (${index})` : ''}`;
    const candidateSegment = truncateUtf8(segment,
      GALLERY_DIRECTORY_SEGMENT_MAX_BYTES - utf8Length(suffix)).replace(/[.\s]+$/, '') + suffix;
    const candidate = childDirectory(parent, candidateSegment);
    if (reservedDirectory(candidate, reservedPaths)) {
      continue;
    }
    try {
      const exists = fileIo.accessSync(candidate);
      if (!exists || (candidate === currentDir && fileIo.statSync(candidate).isDirectory())) {
        return candidate;
      }
    } catch (error) {
      // An inaccessible candidate must never be treated as a free destination.
      return '';
    }
  }
  return '';
}

export function findGalleryDirectory(
  parentValue: string,
  item: GalleryDirectoryIdentity,
  reservedPaths: string[] = []
): string {
  const parent = normalizedDirectory(parentValue);
  if (!isGalleryDirectory(parent)) {
    return '';
  }
  try {
    for (const name of fileIo.listFileSync(parent)) {
      if (name.length === 0 || name === '.' || name === '..' || name.indexOf('/') >= 0 || name.indexOf('\0') >= 0) {
        continue;
      }
      const directory = childDirectory(parent, name);
      if (!reservedDirectory(directory, reservedPaths) && isGalleryDirectory(directory) &&
        matchingGalleryIdentity(directory, item)) {
        return directory;
      }
    }
  } catch (error) {
  }
  return '';
}

export function migrateGalleryDirectory(
  currentDirValue: string,
  item: GalleryDirectoryIdentity,
  reservedPaths: string[]
): string {
  const currentDir = normalizedDirectory(currentDirValue);
  if (currentDir.length === 0 || currentDir === '/' || !isGalleryDirectory(currentDir) ||
    reservedDirectory(currentDir, reservedPaths)) {
    return currentDirValue.trim();
  }
  const slash = currentDir.lastIndexOf('/');
  const parent = slash === 0 ? '/' : currentDir.substring(0, slash);
  const target = chooseGalleryDirectory(parent, item, reservedPaths, currentDir);
  if (target.length === 0 || !writeGalleryDirectoryIdentity(currentDir, item)) {
    return currentDir;
  }
  if (target === currentDir) {
    return currentDir;
  }
  try {
    if (fileIo.accessSync(target) || reservedDirectory(target, reservedPaths)) {
      return currentDir;
    }
    // Preserve image files and the recoverable identity in one directory rename.
    fileIo.renameSync(currentDir, target);
    return target;
  } catch (error) {
    return currentDir;
  }
}
