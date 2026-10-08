import { fileIo } from '@kit.CoreFileKit';
import { url } from '@kit.ArkTS';
import { READER_IMAGE_EXTENSIONS } from '../constants/AppConstants';
import { GalleryDirectoryIdentity } from './GalleryDownloadDirectory';
import { DownloadPageResult } from './DownloadModels';

interface OriginalDownloadPage {
  gid: number;
  site: string;
  token: string;
  pageIndex: number;
  fileName: string;
  bytes: number;
  sourceUrl: string;
}

function originalPageDirectory(value: string): string {
  const directory = value.trim().replace(/\/+$/, '');
  if (!directory.startsWith('/') || directory.indexOf('\0') >= 0 ||
    directory.split('/').some((segment: string): boolean => segment === '.' || segment === '..')) {
    return '';
  }
  return directory;
}

function validOriginalPageIdentity(identity: GalleryDirectoryIdentity, pageIndex: number): boolean {
  return Number.isSafeInteger(identity.gid) && identity.gid > 0 && typeof identity.site === 'string' &&
    identity.site.length > 0 && typeof identity.token === 'string' &&
    Number.isSafeInteger(pageIndex) && Number.isSafeInteger(pageIndex + 1) && pageIndex >= 0;
}

function originalPageMarker(directory: string, pageIndex: number): string {
  return `${directory}/.${`${pageIndex + 1}`.padStart(8, '0')}.original.json`;
}

function originalPageFileName(name: string, pageIndex: number): boolean {
  const page = `${pageIndex + 1}`;
  const stems: string[] = [page, page.padStart(5, '0'), page.padStart(8, '0')];
  return READER_IMAGE_EXTENSIONS.some((extension: string): boolean =>
    stems.some((stem: string): boolean => name === `${stem}${extension}`));
}

function originalPageSource(value: string): boolean {
  if (typeof value !== 'string' || value.length === 0 || value !== value.trim() || /\s/.test(value)) {
    return false;
  }
  try {
    const source = new url.URL(value);
    return (source.protocol === 'https:' || source.protocol === 'http:') && source.hostname.length > 0;
  } catch (error) {
    return false;
  }
}

function matchingOriginalPageIdentity(page: OriginalDownloadPage, identity: GalleryDirectoryIdentity): boolean {
  return page !== null && typeof page === 'object' && typeof page.gid === 'number' &&
    page.gid === identity.gid && typeof page.site === 'string' && page.site === identity.site &&
    typeof page.token === 'string' && page.token === identity.token;
}

function replaceableOriginalPageMarker(marker: string, identity: GalleryDirectoryIdentity): boolean {
  if (!fileIo.accessSync(marker)) {
    return true;
  }
  if (!fileIo.statSync(marker).isFile()) {
    return false;
  }
  const text = fileIo.readTextSync(marker);
  try {
    const existing = JSON.parse(text) as OriginalDownloadPage;
    return existing === null || typeof existing !== 'object' || typeof existing.gid !== 'number' ||
      typeof existing.site !== 'string' || typeof existing.token !== 'string' ||
      matchingOriginalPageIdentity(existing, identity);
  } catch (error) {
    return true;
  }
}

function utf8ByteLength(value: string): number {
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

// A filename or the task's selected quality alone cannot prove that an older
// download contains the original. Receipts are committed only after an
// original request has produced a complete, atomically committed image.
export function verifiedOriginalDownloadPath(
  directoryValue: string,
  identity: GalleryDirectoryIdentity,
  pageIndex: number
): string {
  const directory = originalPageDirectory(directoryValue);
  if (directory.length === 0 || !validOriginalPageIdentity(identity, pageIndex)) {
    return '';
  }
  try {
    const marker = originalPageMarker(directory, pageIndex);
    const markerStat = fileIo.statSync(marker);
    if (!markerStat.isFile() || markerStat.size <= 0) {
      return '';
    }
    const page = JSON.parse(fileIo.readTextSync(marker)) as OriginalDownloadPage;
    if (!matchingOriginalPageIdentity(page, identity) || page.pageIndex !== pageIndex ||
      typeof page.fileName !== 'string' || !originalPageFileName(page.fileName, pageIndex) ||
      typeof page.bytes !== 'number' || !Number.isSafeInteger(page.bytes) || page.bytes <= 0 ||
      !originalPageSource(page.sourceUrl)) {
      return '';
    }
    const path = `${directory}/${page.fileName}`;
    const stat = fileIo.statSync(path);
    return stat.isFile() && stat.size === page.bytes ? path : '';
  } catch (error) {
    return '';
  }
}

export function recordOriginalDownloadPage(
  directoryValue: string,
  identity: GalleryDirectoryIdentity,
  pageIndex: number,
  result: DownloadPageResult
): boolean {
  const directory = originalPageDirectory(directoryValue);
  if (directory.length === 0 || !validOriginalPageIdentity(identity, pageIndex) ||
    !Number.isSafeInteger(result.bytes) || result.bytes <= 0 || !originalPageSource(result.sourceUrl) ||
    typeof result.path !== 'string' || !result.path.startsWith(`${directory}/`)) {
    return false;
  }
  const fileName = result.path.substring(directory.length + 1);
  if (!originalPageFileName(fileName, pageIndex)) {
    return false;
  }
  const marker = originalPageMarker(directory, pageIndex);
  const temporary = `${marker}.tmp`;
  let file: fileIo.File | undefined = undefined;
  let temporaryCreated = false;
  try {
    const stat = fileIo.statSync(result.path);
    if (!stat.isFile() || stat.size !== result.bytes) {
      return false;
    }
    // Never overwrite another gallery's receipt. An invalid receipt owned by
    // this directory can be repaired after a successful original download.
    if (!replaceableOriginalPageMarker(marker, identity)) {
      return false;
    }
    const page: OriginalDownloadPage = {
      gid: identity.gid,
      site: identity.site,
      token: identity.token,
      pageIndex,
      fileName,
      bytes: result.bytes,
      sourceUrl: result.sourceUrl
    };
    const text = JSON.stringify(page);
    file = fileIo.openSync(temporary, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    temporaryCreated = true;
    const written = fileIo.writeSync(file.fd, text);
    const temporaryStat = fileIo.statSync(file.fd);
    if (written !== utf8ByteLength(text) || !temporaryStat.isFile() || temporaryStat.size !== written) {
      return false;
    }
    fileIo.closeSync(file.fd);
    file = undefined;
    if (!replaceableOriginalPageMarker(marker, identity)) {
      return false;
    }
    fileIo.renameSync(temporary, marker);
    temporaryCreated = false;
    return verifiedOriginalDownloadPath(directory, identity, pageIndex) === result.path;
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
