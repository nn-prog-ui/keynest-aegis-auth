import 'package:local_auth/local_auth.dart';

class DeviceAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isDeviceAuthAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) {
        return false;
      }
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        return true;
      }
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({required String reason}) async {
    final available = await isDeviceAuthAvailable();
    if (!available) {
      return true;
    }

    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
