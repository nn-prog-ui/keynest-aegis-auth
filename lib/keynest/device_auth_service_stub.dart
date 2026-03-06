class DeviceAuthService {
  Future<bool> isDeviceAuthAvailable() async {
    return false;
  }

  Future<bool> authenticate({required String reason}) async {
    return true;
  }
}
