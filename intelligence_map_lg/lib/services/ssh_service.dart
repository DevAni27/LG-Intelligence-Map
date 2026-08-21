import 'package:dartssh2/dartssh2.dart';
import 'dart:convert';
import '../helpers/kml_helper.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Manages SSH connections to the Liquid Galaxy master node.
/// Patterns matched from production LG app store applications.
class SSHService extends ChangeNotifier {
  SSHClient? _client;
  String? _host;
  int _port = 22;
  String? _username;
  String? _password;
  int _numberOfRigs = 3;

  bool get isConnected => _client != null;
  String? get host => _host;
  String? get password => _password;

  /// Establishes SSH connection to the LG master node.
  Future<bool> connect({
    required String host,
    int port = 22,
    required String username,
    required String password,
    int numberOfRigs = 3,
  }) async {
    try {
      disconnect();

      _host = host;
      _port = port;
      _username = username;
      _password = password;
      _numberOfRigs = numberOfRigs;

      final socket = await SSHSocket.connect(host, port).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw Exception("Connection timed out"),
      );
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      notifyListeners();
      await sendLogo();

      return true;
    } catch (e) {
      _client = null;
      rethrow;
    }
  }

  void disconnect() {
    _client?.close();
    _client = null;
    notifyListeners();
  }

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
  /// Uses _client!.execute() matching the production app pattern.
  // Add this at the top of SSHService class
  Future<String?> execute(String command) async {
    if (_client == null) return null;

    try {
      final result = await _client!.run(command);
      return utf8.decode(result);
    } catch (e) {
      // Try to reconnect once
      final reconnected = await _reconnect();
      if (!reconnected) return null;
      // Retry the command after reconnect
      try {
        final result = await _client!.run(command);
        return utf8.decode(result);
      } catch (e2) {
        return null;
      }
    }
  }

  Future<bool> _reconnect() async {
    if (_host == null) return false;
    try {
      disconnect();
      await Future.delayed(const Duration(seconds: 1));
      return await connect(
        host: _host!,
        port: _port!,
        username: _username!,
        password: _password!,
        numberOfRigs: _numberOfRigs,
      );
    } catch (e) {
      return false;
    }
  }

  // KML OPERATIONS

  /// Sends KML to the LG rig.
  /// ONLY writes to the KML file and kmls.txt.
  /// NEVER write to master.kml — sync_nlc.php handles loading on all screens.
  Future<bool> sendKML(
    String kmlContent, {
    String fileName = 'global_pulse.kml',
  }) async {
    if (_client == null || _host == null) return false;

    try {
      // 1. Upload file to /var/www/html/
      final sftp = await _client!.sftp();
      final file = await sftp.open(
        '/var/www/html/$fileName',
        mode:
            SftpFileOpenMode.create |
            SftpFileOpenMode.truncate |
            SftpFileOpenMode.write,
      );
      await file.write(
        Stream.value(Uint8List.fromList(utf8.encode(kmlContent))),
      );
      await file.close();

      // 2. Write URL to kmls.txt
      await execute('echo "http://lg1:81/$fileName" > /var/www/html/kmls.txt');

      return true;
    } catch (e) {
      return false;
    }
  }

  int _getRightSlaveScreen() {
    return (_numberOfRigs / 2).floor() + 1;
  }

  //method to send screen overlay to the right most screen in the rig

  Future<bool> sendOverlayKML(String kmlContent) async {
    try {
      final rightScreen = _getRightSlaveScreen();
      final fileName = 'slave_$rightScreen.kml';
      final remotePath = '/var/www/html/kml/$fileName';

      final sftp = await _client!.sftp();
      final file = await sftp.open(
        remotePath,
        mode:
            SftpFileOpenMode.create |
            SftpFileOpenMode.truncate |
            SftpFileOpenMode.write,
      );
      await file.writeBytes(utf8.encode(kmlContent));
      await file.close();

      // ← ADD THIS — tells Google Earth to reload the overlay
      await _setSlaveRefresh(rightScreen);

      return true;
    } catch (e) {
      return false;
    }
  }

  //method to clear the screen overlay

  Future<bool> clearoverlayKML(String KmlContent) async {
    final rightScreen = _getRightSlaveScreen();

    String kmlContent = KmlHelper.generateBlankKml('slave_$rightScreen');
    final result = await execute(
      "echo '$kmlContent' > /var/www/html/kml/slave_$rightScreen.kml",
    );

    return result != null;
  }

  Future<bool> clearKML() async {
    if (_client == null) return false;

    try {
      await execute('echo "" > /var/www/html/kmls.txt');
      await execute('echo "" > /tmp/query.txt');
      await execute('rm -f /var/www/html/global_pulse.kml');
      await clearoverlayKML('');
      return true;
    } catch (e) {
      return false;
    }
  }

  // SLAVE REFRESH

  /// Sets refresh interval on a slave's myplaces.kml so Google Earth
  /// periodically re-reads slave_X.kml. Idempotent: removes existing
  /// refresh tags first, then adds a single clean set.
  Future<void> _setSlaveRefresh(int screenNumber) async {
    final search =
        '<href>##LG_PHPIFACE##kml\\/slave_$screenNumber.kml<\\/href>';
    final replace =
        '<href>##LG_PHPIFACE##kml\\/slave_$screenNumber.kml<\\/href>'
        '<refreshMode>onInterval<\\/refreshMode>'
        '<refreshInterval>2<\\/refreshInterval>';

    await execute(
      'sshpass -p $_password ssh -o StrictHostKeyChecking=no lg$screenNumber '
      "\"echo $_password | sudo -S sed -i 's/$replace/$search/g' ~/earth/kml/slave/myplaces.kml\"",
    );
    await execute(
      'sshpass -p $_password ssh -o StrictHostKeyChecking=no lg$screenNumber '
      "\"echo $_password | sudo -S sed -i 's/$search/$replace/g' ~/earth/kml/slave/myplaces.kml\"",
    );
  }

  Future<void> _uploadLogoImage() async {
    try {
      final byteData = await rootBundle.load('assets/images/lg_rig_logo.png');
      final imageBytes = byteData.buffer.asUint8List();

      final sftp = await _client!.sftp();
      final file = await sftp.open(
        '/var/www/html/lg_rig_logo.png',
        mode:
            SftpFileOpenMode.create |
            SftpFileOpenMode.truncate |
            SftpFileOpenMode.write,
      );
      await file.writeBytes(imageBytes);
      await file.close();
    } catch (e) {
      // Silently ignored
    }
  }

  int _getLeftSlaveScreen() {
    return (_numberOfRigs / 2).floor() + 2;
  }

  /// Sends the Global Pulse logo to the leftmost slave screen.
  Future<bool> sendLogo() async {
    if (_client == null) return false;

    try {
      final leftScreen = _getLeftSlaveScreen();

      await _uploadLogoImage();

      final logoKml = KmlHelper.generateLogoKML();
      await execute(
        "echo '$logoKml' > /var/www/html/kml/slave_$leftScreen.kml",
      );

      await _setSlaveRefresh(leftScreen);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clears the logo from the leftmost slave screen.
  Future<bool> clearLogo() async {
    if (_client == null) return false;

    try {
      final leftScreen = _getLeftSlaveScreen();
      const emptyKml =
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<kml xmlns="http://www.opengis.net/kml/2.2">'
          '<Document><name>Empty</name></Document></kml>';

      await execute(
        "echo '$emptyKml' > /var/www/html/kml/slave_$leftScreen.kml",
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // NAVIGATION

  Future<void> flyToDefault() async {
    await flyTo(latitude: 0, longitude: 0, range: 25000000, tilt: 0);
  }

  /// Sends a flyto command to navigate the LG camera.
  Future<bool> flyTo({
    required double latitude,
    required double longitude,
    double altitude = 0,
    double heading = 0,
    double tilt = 0,
    double range = 1500000,
  }) async {
    if (_client == null) return false;

    final lookAt =
        'flytoview=<LookAt><longitude>$longitude</longitude>'
        '<latitude>$latitude</latitude><altitude>$altitude</altitude>'
        '<heading>$heading</heading><tilt>$tilt</tilt>'
        '<range>$range</range>'
        '<altitudeMode>relativeToGround</altitudeMode></LookAt>';

    // Clear first then write — prevents stale content
    await execute('echo "" > /tmp/query.txt');
    await Future.delayed(const Duration(milliseconds: 500));
    final result = await execute("echo '$lookAt' > /tmp/query.txt");
    return result != null;
  }

  /// Reboots the entire LG rig.
  /// Uses sshpass + ssh -t pattern from production app.
  Future<bool> reboot() async {
    if (_client == null) return false;

    try {
      for (int i = _numberOfRigs; i >= 1; i--) {
        await execute(
          'sshpass -p $_password ssh -t lg$i "echo $_password | sudo -S reboot"',
        );
        if (i > 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Shuts down the entire LG rig.
  Future<bool> shutdown() async {
    if (_client == null) return false;

    try {
      for (int i = _numberOfRigs; i >= 1; i--) {
        await execute(
          'sshpass -p $_password ssh -t lg$i "echo $_password | sudo -S shutdown now"',
        );
        if (i > 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Relaunches Google Earth by restarting lightdm.
  Future<bool> refresh() async {
    if (_client == null) return false;

    try {
      final cmd =
          """
        RELAUNCH_CMD="\\
        if [ -f /etc/init/lxdm.conf ]; then
          export SERVICE=lxdm
        elif [ -f /etc/init/lightdm.conf ]; then
          export SERVICE=lightdm
        else
          exit 1
        fi

        if [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]]; then
          echo $_password | sudo -S service \\\${SERVICE} start
        else
          echo $_password | sudo -S service \\\${SERVICE} restart
        fi
        " && sshpass -p $_password ssh -x -t lg@lg1 "\$RELAUNCH_CMD\"""";

      await execute(cmd);
      return true;
    } catch (e) {
      return false;
    }
  }
}
