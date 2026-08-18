class KmlHelper {
  static String generateLogoKML() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" 
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>Global Pulse Logo</name>
    <ScreenOverlay>
      <name>Global Pulse Logo</name>
      <Icon>
        <href>http://lg1:81/lg_rig_logo.png</href>
      </Icon>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="0.02" y="0.95" xunits="fraction" yunits="fraction"/>
      <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
      <size x="554" y="500" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>''';
  }

  static String generateBlankKml(String name) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
    <Document id="$name">
    </Document>
</kml>''';
  }
}
