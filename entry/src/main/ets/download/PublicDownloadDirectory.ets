import { common } from '@kit.AbilityKit';
import { fileIo, fileUri, picker } from '@kit.CoreFileKit';

export class PublicDownloadDirectory {
  uri: string;
  path: string;

  constructor(uri: string, path: string) {
    this.uri = uri;
    this.path = path;
  }
}

// Share one authorization request across routed Index instances.
let sharedDirectory: PublicDownloadDirectory | undefined = undefined;
let directoryRequest: Promise<PublicDownloadDirectory> | undefined = undefined;

async function directoryAvailable(directory: PublicDownloadDirectory): Promise<boolean> {
  try {
    if (!await fileIo.access(directory.path, fileIo.AccessModeType.READ_WRITE)) {
      return false;
    }
    return (await fileIo.stat(directory.path)).isDirectory();
  } catch (error) {
    return false;
  }
}

function directoryFromUri(uri: string): PublicDownloadDirectory {
  if (!uri.startsWith('file://') || uri.indexOf('?') >= 0 || uri.indexOf('#') >= 0) {
    throw new Error('系统未返回有效的公共下载目录 URI');
  }
  const parsed: fileUri.FileUri = new fileUri.FileUri(uri);
  const path = parsed.path.replace(/\/+$/, '');
  if (parsed.scheme !== 'file' || !path.startsWith('/') || path.indexOf('\0') >= 0) {
    throw new Error('系统未返回有效的公共下载目录路径');
  }
  for (const segment of path.split('/')) {
    if (segment === '.' || segment === '..') {
      throw new Error('系统未返回有效的公共下载目录路径');
    }
  }
  return new PublicDownloadDirectory(uri, path);
}

async function resolveDirectory(context: common.UIAbilityContext): Promise<PublicDownloadDirectory> {
  const cached = sharedDirectory;
  if (cached) {
    if (await directoryAvailable(cached)) {
      return cached;
    }
    sharedDirectory = undefined;
  }

  // DOWNLOAD creates Download/<bundle name> and grants persistent access.
  // The system returns the already-created directory, not a private fallback.
  // https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/save-user-file
  const documentPicker = new picker.DocumentViewPicker(context);
  const options: picker.DocumentSaveOptions = { pickerMode: picker.DocumentPickerMode.DOWNLOAD };
  const results: string[] = await documentPicker.save(options);
  if (results.length === 0) {
    throw new Error('系统未返回公共下载目录');
  }
  const directory = directoryFromUri(results[0]);
  if (!await directoryAvailable(directory)) {
    throw new Error('公共下载目录不存在或没有读写权限');
  }
  sharedDirectory = directory;
  return directory;
}

export function getPublicDownloadDirectory(context: common.UIAbilityContext): Promise<PublicDownloadDirectory> {
  const pending = directoryRequest;
  if (pending) {
    return pending;
  }
  const request = resolveDirectory(context).finally((): void => {
    directoryRequest = undefined;
  });
  directoryRequest = request;
  return request;
}

export async function openPublicDownloadDirectory(context: common.UIAbilityContext): Promise<PublicDownloadDirectory> {
  const directory = await getPublicDownloadDirectory(context);
  // The system File Manager deep link takes a document URI, not a sandbox path.
  // https://developer.huawei.com/consumer/cn/doc/harmonyos-faqs/faqs-ability-116
  await context.openLink('filemanager://openDirectory', {
    appLinkingOnly: false,
    parameters: { fileUri: directory.uri }
  });
  return directory;
}

export function publicDownloadFileUri(path: string): string {
  const directory = sharedDirectory;
  if (!directory || path.indexOf('\0') >= 0) {
    return '';
  }
  if (path === directory.path) {
    return directory.uri;
  }
  const rootPrefix = `${directory.path}/`;
  if (!path.startsWith(rootPrefix)) {
    return '';
  }
  const encodedSegments: string[] = [];
  for (const segment of path.slice(rootPrefix.length).split('/')) {
    if (segment.length === 0 || segment === '.' || segment === '..') {
      return '';
    }
    encodedSegments.push(encodeURIComponent(segment));
  }
  return `${directory.uri.replace(/\/+$/, '')}/${encodedSegments.join('/')}`;
}
