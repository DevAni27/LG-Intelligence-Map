import '../data/models/global_event.dart';
import 'dart:convert';
/// Generates KML strings from [GlobalEvent] objects for rendering
/// on the Liquid Galaxy rig.
///
/// Each event becomes a 3D extruded placemark with:
/// - Color based on category (red=earthquake, blue=flood, etc.)
/// - Height based on severity (critical events are taller)
/// - Description balloon with event details
/// - Custom icon styling
class KMLService {
  /// Generates a complete KML document containing all provided events
  /// as 3D placemarks.
  String generateEventsKML(List<GlobalEvent> events) {
    // Filter out events with invalid coordinates
    final validEvents = events.where((e) =>
        e.latitude >= -90 &&
        e.latitude <= 90 &&
        e.longitude >= -180 &&
        e.longitude <= 180).toList();
    final placemarks = validEvents.map(_eventToPlacemark).join('\n');

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Global Pulse Events</name>
    <description>AI-Powered World Intelligence Map</description>
    <open>1</open>
$placemarks
  </Document>
</kml>''';
  }

  /// Generates a KML LookAt element for camera navigation.
  String generateLookAt({
    required double latitude,
    required double longitude,
    double altitude = 0,
    double heading = 0,
    double tilt = 45,
    double range = 1500000,
  }) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <Placemark>
      <LookAt>
        <longitude>$longitude</longitude>
        <latitude>$latitude</latitude>
        <altitude>$altitude</altitude>
        <heading>$heading</heading>
        <tilt>$tilt</tilt>
        <range>$range</range>
        <altitudeMode>relativeToGround</altitudeMode>
      </LookAt>
    </Placemark>
  </Document>
</kml>''';
  }

  /// Generates a blank KML to clear the display.
  String generateBlankKML() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Global Pulse</name>
  </Document>
</kml>''';
  }

  /// Generates the Global Pulse logo overlay KML for the leftmost slave screen.
  String generateLogoKML({int slaveNumber = 2}) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Global Pulse Logo</name>
    <ScreenOverlay>
      <name>Logo</name>
      <Icon>
        <href>https://raw.githubusercontent.com/YOUR_USERNAME/global_pulse/main/assets/logo.png</href>
      </Icon>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.02" y="0.95" xunits="fraction" yunits="fraction"/>
      <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
      <size x="0.15" y="0" xunits="fraction" yunits="fraction"/>
    </ScreenOverlay>
  </Document>
</kml>''';
  }

  /// Converts a single [GlobalEvent] into a KML Placemark string.
  
  String _eventToPlacemark(GlobalEvent event) {
    final color = _kmlColorForCategory(event.category);
    final icon = _iconForCategory(event.category);
    final scale = _scaleForSeverity(event.severity);

    return '''
    <Placemark id="${event.id}">
      <name>${_escapeXml(event.title)}</name>
      <description>${_escapeXml(event.description)}</description>
      <Style>
        <IconStyle>
          <color>$color</color>
          <scale>$scale</scale>
          <Icon>
            <href>$icon</href>
          </Icon>
        </IconStyle>
      </Style>
      <Point>
        <coordinates>${event.longitude},${event.latitude},0</coordinates>
      </Point>
    </Placemark>''';
  }

  /// Builds the HTML content for the placemark's description balloon.
  


  String _kmlColorForCategory(EventCategory category) {
    switch (category) {
      case EventCategory.earthquake:
        return 'ff0000ff'; // red
      case EventCategory.floodStorm:
        return 'ffff0000'; // blue
      case EventCategory.wildfire:
        return 'ff00a5ff'; // orange
      case EventCategory.diseaseOutbreak:
        return 'ffff00ff'; // purple
      case EventCategory.conflict:
        return 'ff00ffff'; // yellow
    }
  }

  String _iconForCategory(EventCategory category) {
    switch (category) {
      case EventCategory.earthquake:
        return 'http://maps.google.com/mapfiles/kml/paddle/red-circle.png';
      case EventCategory.floodStorm:
        return 'http://maps.google.com/mapfiles/kml/paddle/blu-circle.png';
      case EventCategory.wildfire:
        return 'http://maps.google.com/mapfiles/kml/paddle/orange-circle.png';
      case EventCategory.diseaseOutbreak:
        return 'http://maps.google.com/mapfiles/kml/paddle/purple-circle.png';
      case EventCategory.conflict:
        return 'http://maps.google.com/mapfiles/kml/paddle/ylw-circle.png';
    }
  }

  double _scaleForSeverity(EventSeverity severity) {
    switch (severity) {
      case EventSeverity.critical:
        return 2.0;
      case EventSeverity.high:
        return 1.6;
      case EventSeverity.medium:
        return 1.2;
      case EventSeverity.low:
        return 0.8;
    }
  }
  double _rangeForSeverity(EventSeverity severity) {
    switch (severity) {
      case EventSeverity.critical:
        return 500000;
      case EventSeverity.high:
        return 800000;
      case EventSeverity.medium:
        return 1200000;
      case EventSeverity.low:
        return 2000000;
    }
  }

  

  /// Escapes special XML characters to prevent KML parsing errors.
  /// Removes or escapes characters that break XML/KML parsing.
  String _escapeXml(String text) {
    // First replace & (must be first, before adding &-based escapes)
    var escaped = text.replaceAll('&', '&amp;');
    escaped = escaped.replaceAll('<', '&lt;');
    escaped = escaped.replaceAll('>', '&gt;');
    escaped = escaped.replaceAll('"', '&quot;');
    escaped = escaped.replaceAll("'", '&apos;');
    
    // Remove any control characters (bytes 0x00-0x1F except tab/newline/CR)
    // These are invalid in XML and will cause parsing failures
    escaped = escaped.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    
    return escaped;
  }
}
