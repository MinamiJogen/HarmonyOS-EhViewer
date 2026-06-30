import connection from '@ohos.net.connection';

export class AppNetworkProxy {
  static requestProxy(): boolean | connection.HttpProxy {
    return true;
  }
}
