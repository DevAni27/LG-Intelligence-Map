import '../data/models/global_event.dart';

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
    final placemarks = events.map(_eventToPlacemark).join('\n');

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>Global Pulse Events</name>
    <description>AI-Powered World Intelligence Map</description>
    <open>1</open>
${_generateStyles()}
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
    final styleId = _styleIdForCategory(event.category);
    final description = _buildBalloonDescription(event);

    return '''
    <Placemark id="${event.id}">
      <name>${_escapeXml(event.title)}</name>
      <description><![CDATA[$description]]></description>
      <styleUrl>#$styleId</styleUrl>
      <LookAt>
        <longitude>${event.longitude}</longitude>
        <latitude>${event.latitude}</latitude>
        <altitude>0</altitude>
        <heading>0</heading>
        <tilt>45</tilt>
        <range>${_rangeForSeverity(event.severity)}</range>
        <altitudeMode>relativeToGround</altitudeMode>
      </LookAt>
      <Point>
        <extrude>1</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <coordinates>${event.longitude},${event.latitude},${event.kmlAltitude}</coordinates>
      </Point>
    </Placemark>''';
  }

  /// Builds the HTML content for the placemark's description balloon.
  String _buildBalloonDescription(GlobalEvent event) {
    final severityColor = _htmlColorForSeverity(event.severity);

    return '''
<div style="font-family: Arial, sans-serif; max-width: 350px; padding: 8px;">
  <h3 style="margin: 0 0 8px 0; color: #333;">${_escapeXml(event.title)}</h3>
  <div style="display: inline-block; padding: 2px 8px; border-radius: 4px;
    background: $severityColor; color: white; font-size: 12px; font-weight: bold;
    margin-bottom: 8px;">
    ${event.severity.label}
  </div>
  <p style="margin: 8px 0; color: #555; font-size: 13px;">
    ${_escapeXml(event.description)}
  </p>
  <table style="font-size: 12px; color: #666;">
    <tr><td style="padding-right: 8px;"><b>Category:</b></td>
        <td>${event.category.label}</td></tr>
    <tr><td style="padding-right: 8px;"><b>Location:</b></td>
        <td>${_escapeXml(event.locationName)}</td></tr>
    <tr><td style="padding-right: 8px;"><b>Time:</b></td>
        <td>${event.timeAgo}</td></tr>
    <tr><td style="padding-right: 8px;"><b>Source:</b></td>
        <td>${event.source.label}</td></tr>
  </table>
</div>''';
  }

  /// Generates KML Style elements for each event category.
  String _generateStyles() {
    final categories = EventCategory.values;
    final styles = StringBuffer();

    for (final category in categories) {
      styles.writeln('''
    <Style id="${_styleIdForCategory(category)}">
      <IconStyle>
        <color>${category.kmlColor}</color>
        <scale>1.2</scale>
        <Icon>
          <href>http://maps.google.com/mapfiles/kml/shapes/shaded_dot.png</href>
        </Icon>
      </IconStyle>
      <LineStyle>
        <color>${category.kmlColor}</color>
        <width>2</width>
      </LineStyle>
      <PolyStyle>
        <color>80${category.kmlColor.substring(2)}</color>
      </PolyStyle>
      <BalloonStyle>
        <bgColor>ffffffff</bgColor>
        <textColor>ff000000</textColor>
      </BalloonStyle>
    </Style>''');
    }

    return styles.toString();
  }

  String _styleIdForCategory(EventCategory category) {
    switch (category) {
      case EventCategory.earthquake:
        return 'style_earthquake';
      case EventCategory.floodStorm:
        return 'style_flood';
      case EventCategory.wildfire:
        return 'style_wildfire';
      case EventCategory.diseaseOutbreak:
        return 'style_disease';
      case EventCategory.conflict:
        return 'style_conflict';
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

  String _htmlColorForSeverity(EventSeverity severity) {
    switch (severity) {
      case EventSeverity.critical:
        return '#EF4444';
      case EventSeverity.high:
        return '#F97316';
      case EventSeverity.medium:
        return '#EAB308';
      case EventSeverity.low:
        return '#6B7280';
    }
  }

  /// Escapes special XML characters to prevent KML parsing errors.
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
