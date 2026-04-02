import 'package:connectivity_plus/connectivity_plus.dart';

/// Checks network connectivity state.
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService(this._connectivity);

  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;
}
