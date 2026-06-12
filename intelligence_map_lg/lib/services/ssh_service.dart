import 'package:dartssh2/dartssh2.dart';
import 'dart:typed_data';

/// Manages SSH connections to the Liquid Galaxy master node.
///
/// Handles:
/// - Connecting/disconnecting to the LG rig
/// - Sending KML files to the master
/// - Executing flyto navigation commands
/// - LG system commands (clear KML, reboot, shutdown)
class SSHService {
  SSHClient? _client;
  String? _host;
  int _port = 22;
  String? _username;
  String? _password;
  int _numberOfRigs = 3;

  bool get isConnected => _client != null;
  String? get host => _host;

  /// Establishes SSH connection to the LG master node.
  Future<bool> connect({
    required String host,
    int port = 22,
    required String username,
    required String password,
    int numberOfRigs = 3,
  }) async {
    try {
      // Disconnect existing connection if any
      disconnect();

      _host = host;
      _port = port;
      _username = username;
      _password = password;
      _numberOfRigs = numberOfRigs;

      final socket = await SSHSocket.connect(host, port);
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      return true;
    } catch (e) {
      _client = null;
      return false;
    }
  }

  /// Disconnects from the LG master node.
  void disconnect() {
    _client?.close();
    _client = null;
  }

  /// Reconnects using the last known credentials.
  Future<bool> reconnect() async {
    if (_host == null || _username == null || _password == null) {
      return false;
    }
    return connect(
      host: _host!,
      port: _port,
      username: _username!,
      password: _password!,
      numberOfRigs: _numberOfRigs,
    );
  }

  /// Executes a shell command on the LG master.
  Future<String?> execute(String command) async {
    if (_client == null) return null;

    try {
      final result = await _client!.run(command);
      return String.fromCharCodes(result);
    } catch (e) {
      return null;
    }
  }

  /// Sends a KML string to the LG master and loads it in Google Earth.
  /// The KML is written to /var/www/html/ and loaded via a NetworkLink
  /// on the master's kmls.txt.
  Future<bool> sendKML(String kmlContent, {String fileName = 'global_pulse.kml'}) async {
    if (_client == null) return false;

    try {
      // Write KML to the master's web server directory
      final filePath = '/var/www/html/$fileName';
      final escaped = kmlContent.replaceAll("'", "'\\''");
      await execute("echo '$escaped' > $filePath");

      // Add to kmls.txt so Google Earth picks it up
      // The LG system loads KMLs listed in this file
      await execute(
        'echo "http://localhost:81/$fileName" > /var/www/html/kmls.txt',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sends a KML file via SFTP for larger payloads.
  Future<bool> uploadKML(String kmlContent, {String fileName = 'global_pulse.kml'}) async {
    if (_client == null) return false;

    try {
      final sftp = await _client!.sftp();
      final file = await sftp.open(
        '/var/www/html/$fileName',
        mode: SftpFileOpenMode.create |
            SftpFileOpenMode.truncate |
            SftpFileOpenMode.write,
      );
      await file.write(
        Stream.value(Uint8List.fromList(kmlContent.codeUnits)),
      );
      await file.close();

      // Register in kmls.txt
      await execute(
        'echo "http://localhost:81/$fileName" > /var/www/html/kmls.txt',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sends a flyto command to navigate the LG camera to a specific
  /// latitude, longitude, altitude, heading, tilt, and range.
  Future<bool> flyTo({
    required double latitude,
    required double longitude,
    double altitude = 0,
    double heading = 0,
    double tilt = 0,
    double range = 1500000,
  }) async {
    final flyToKml = '''
flytoview=<LookAt>
  <longitude>$longitude</longitude>
  <latitude>$latitude</latitude>
  <altitude>$altitude</altitude>
  <heading>$heading</heading>
  <tilt>$tilt</tilt>
  <range>$range</range>
  <altitudeMode>relativeToGround</altitudeMode>
</LookAt>
''';

    return await execute(
          'echo "$flyToKml" > /tmp/query.txt',
        ) !=
        null;
  }

  /// Clears all KML overlays from the LG rig.
  Future<bool> clearKML() async {
    if (_client == null) return false;

    try {
      await execute('echo "" > /var/www/html/kmls.txt');
      // Also clear the temporary query file
      await execute('echo "" > /tmp/query.txt');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clears the logo overlay from the LG slave screens.
  Future<bool> clearLogo() async {
    if (_client == null) return false;

    for (int i = 2; i <= _numberOfRigs; i++) {
      await execute(
        'sshpass -p "$_password" ssh -o StrictHostKeyChecking=no '
        '$_username@lg$i "echo \'\' > /var/www/html/kml/slave_$i.kml"',
      );
    }
    return true;
  }

  /// Reboots the entire LG rig (all screens).
  Future<bool> reboot() async {
    if (_client == null) return false;

    for (int i = _numberOfRigs; i >= 1; i--) {
      if (i == 1) {
        await execute('sudo reboot');
      } else {
        await execute(
          'sshpass -p "$_password" ssh -o StrictHostKeyChecking=no '
          '$_username@lg$i "sudo reboot"',
        );
      }
    }
    return true;
  }

  /// Shuts down the entire LG rig.
  Future<bool> shutdown() async {
    if (_client == null) return false;

    for (int i = _numberOfRigs; i >= 1; i--) {
      if (i == 1) {
        await execute('sudo poweroff');
      } else {
        await execute(
          'sshpass -p "$_password" ssh -o StrictHostKeyChecking=no '
          '$_username@lg$i "sudo poweroff"',
        );
      }
    }
    return true;
  }

  /// Refreshes Google Earth on the LG rig.
  Future<bool> refresh() async {
    return await execute(
          'sshpass -p "$_password" ssh -o StrictHostKeyChecking=no '
          '$_username@lg1 "killall -SIGUSR1 googleearth-bin"',
        ) !=
        null;
  }
}
