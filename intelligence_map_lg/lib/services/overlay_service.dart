import '../data/models/global_event.dart';
import '../core/utils/top_region_helper.dart';
import 'gemini_service.dart';

class OverlayService {
  static String generateEventOverlayKml(GlobalEvent event) {
    final imageUrl = _getHeaderImageURL(event.category);
    final catColor = _categoryColorHex(event.category);
    final sevColor = _severityColorHex(event.severity);
    final categoryLabel = event.category.name.toUpperCase();
    final severityLabel = event.severity.name.toUpperCase();
    final insight = _getContextualInsight(event.category, event.severity);

    final date =
        '${event.timestamp.day}/${event.timestamp.month}/${event.timestamp.year}';

    final description = event.description.length > 300
        ? '${event.description.substring(0, 300)}...'
        : event.description;

    final lat = event.latitude.toStringAsFixed(4);
    final lon = event.longitude.toStringAsFixed(4);

    final source = event.source.name.toUpperCase();

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <Style id="event_style">
      <BalloonStyle>
        <bgColor>ff0f172a</bgColor>
        <text><![CDATA[
          <div style="font-family: Arial, sans-serif; width: 900px; background-color: #0f172a; color: #ffffff; border-radius: 12px; overflow: hidden;">
            
            <!-- Header Image -->
            <div style="width: 100%; height: 200px; overflow: hidden;">
              <img src="$imageUrl" style="width: 100%; height: 200px; object-fit: cover;" />
            </div>

            <!-- Category + Severity Row -->
            <div style="padding: 16px 20px 8px 20px; display: flex; gap: 10px;">
              <span style="background-color: ${catColor}22; color: $catColor; border: 1px solid $catColor; padding: 4px 10px; border-radius: 6px; font-size: 18px; font-weight: bold;">
                $categoryLabel
              </span>
              <span style="background-color: ${sevColor}22; color: $sevColor; border: 1px solid $sevColor; padding: 4px 10px; border-radius: 6px; font-size: 18px; font-weight: bold;">
                $severityLabel
              </span>
            </div>

            <!-- Title -->
            <div style="padding: 4px 20px 12px 20px;">
              <h2 style="color: #ffffff; font-size: 30px; margin: 0; line-height: 1.3;">
                ${event.title}
              </h2>
            </div>

            <!-- Location + Date -->
            <div style="padding: 0 20px 12px 20px; display: flex; justify-content: space-between;">
              <span style="color: #94a3b8; font-size: 20px;">📍 ${event.locationName}</span>
              <span style="color: #94a3b8; font-size: 20px;">$date</span>
            </div>

            <!-- Divider -->
            <div style="border-top: 1px solid #1e293b; margin: 0 20px;"></div>

            <!-- Description -->
            <div style="padding: 12px 20px;">
              <p style="color: #cbd5e1; font-size: 20px; line-height: 1.6; margin: 0;">
                $description
              </p>
            </div>

            <!-- Divider -->
            <div style="border-top: 1px solid #1e293b; margin: 0 20px;"></div>

            <div style="background-color: #1e293b; padding: 12px 16px; border-left: 3px solid $catColor; margin: 0 20px 12px 20px; border-radius: 4px;">
              <p style="color: #94a3b8; font-size: 16px; margin: 0 0 4px 0;">SITUATIONAL INSIGHT</p>
              <p style="color: #e2e8f0; font-size: 20px; line-height: 1.5; margin: 0;">$insight</p>
            </div>

            <!-- Divider -->
            <div style="border-top: 1px solid #1e293b; margin: 0 20px;"></div>

            <!-- Source + Coordinates -->
            <div style="padding: 12px 20px; display: flex; justify-content: space-between;">
              <span style="color: #64748b; font-size: 18px;">Source: $source</span>
              <span style="color: #64748b; font-size: 18px;">$lat, $lon</span>
            </div>

          </div>
        ]]></text>
      </BalloonStyle>
    </Style>

    <Placemark>
      <styleUrl>#event_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point>
        <coordinates>${event.longitude},${event.latitude},0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>''';
  }

  static Future<String> generateRegionOverlayKML(
    List<GlobalEvent> visibleEvents,
    GeminiService gemmmaService,
  ) async {
    final dominant = TopRegionHelper.getDominantCategory(visibleEvents);
    final imageURL = dominant != null
        ? _getHeaderImageURL(dominant)
        : 'https://images.unsplash.com/photo-1713098965471-d324f294a71d?q=80&w=2702&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';

    final categoryCount = TopRegionHelper.getCategoryCounts(visibleEvents);
    final severityCount = TopRegionHelper.getSeverityCounts(visibleEvents);
    final topEvent = TopRegionHelper.getTopEvent(visibleEvents);

    String geminiSummary;

    try {
      geminiSummary = await gemmmaService.generateRegionSummary(visibleEvents);
    } catch (e) {
      geminiSummary =
          'AI summary temporarily unavailable. ${visibleEvents.length} active events detected in this region.';
    }

    final categoryRows =
        [
              (EventCategory.earthquake, 'Earthquakes', '#EF4444'),
              (EventCategory.floodStorm, 'Floods / Storms', '#3B82F6'),
              (EventCategory.wildfire, 'Wildfires', '#F97316'),
              (EventCategory.diseaseOutbreak, 'Disease', '#A855F7'),
              (EventCategory.conflict, 'Conflicts', '#EAB308'),
            ]
            .map((row) {
              final count = categoryCount[row.$1] ?? 0;
              return '''
      <tr>
        <td style="padding: 6px 0;">
          <span style="display: inline-block; width: 10px; height: 10px; border-radius: 50%; background-color: ${row.$3}; margin-right: 8px;"></span>
          <span style="color: #94a3b8; font-size: 20px;">${row.$2}</span>
        </td>
        <td style="padding: 6px 0; text-align: right; color: #ffffff; font-size: 20px; font-weight: bold;">$count</td>
      </tr>''';
            })
            .join('');

    // Severity rows
    final severityRows =
        [
              (EventSeverity.critical, 'Critical', '#EF4444'),
              (EventSeverity.high, 'High', '#F97316'),
              (EventSeverity.medium, 'Medium', '#EAB308'),
              (EventSeverity.low, 'Low', '#22C55E'),
            ]
            .map((row) {
              final count = severityCount[row.$1] ?? 0;
              return '''
      <tr>
        <td style="padding: 6px 0;">
          <span style="display: inline-block; width: 10px; height: 10px; border-radius: 50%; background-color: ${row.$3}; margin-right: 8px;"></span>
          <span style="color: #94a3b8; font-size: 20px;">${row.$2}</span>
        </td>
        <td style="padding: 6px 0; text-align: right; color: #ffffff; font-size: 20px; font-weight: bold;">$count</td>
      </tr>''';
            })
            .join('');

    // Top event section
    final topEventHtml = topEvent != null
        ? '''
    <div style="background-color: #1e293b; border-radius: 8px; padding: 12px 14px; margin-bottom: 16px;">
      <p style="color: #64748b; font-size: 16px; margin: 0 0 6px 0; letter-spacing: 1px;">TOP EVENT IN REGION</p>
      <p style="color: #ffffff; font-size: 20px; font-weight: bold; margin: 0 0 6px 0;">${topEvent.title}</p>
      <div style="display: flex; gap: 8px;">
        <span style="background-color: ${_severityColorHex(topEvent.severity)}22; color: ${_severityColorHex(topEvent.severity)}; border: 1px solid ${_severityColorHex(topEvent.severity)}; padding: 2px 8px; border-radius: 4px; font-size: 16px; font-weight: bold;">
          ${topEvent.severity.name.toUpperCase()}
        </span>
        <span style="color: #64748b; font-size: 18px; line-height: 20px;">${topEvent.locationName}</span>
      </div>
    </div>'''
        : '';

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <Style id="region_style">
      <BalloonStyle>
        <bgColor>ff0f172a</bgColor>
        <text><![CDATA[
          <div style="font-family: Arial, sans-serif; width: 900px; background-color: #0f172a; color: #ffffff; border-radius: 12px; overflow: hidden;">

            <!-- Header Image -->
            <div style="width: 100%; height: 160px; overflow: hidden; position: relative;">
              <img src="$imageURL" style="width: 100%; height: 160px; object-fit: cover;" />
              <div style="position: absolute; bottom: 0; left: 0; right: 0; background: linear-gradient(transparent, #0f172a); height: 60px;"></div>
            </div>

            <!-- Title -->
            <div style="padding: 14px 20px 4px 20px;">
              <p style="color: #c5c6c7; font-size: 16px; margin: 0 0 4px 0; letter-spacing: 1px;">REGION OVERVIEW</p>
              <h2 style="color: #ffffff; font-size: 30px; margin: 0 0 4px 0;">Current Map View</h2>
              <p style="color: #94a3b8; font-size: 20px; margin: 0;">${visibleEvents.length} active events in this area</p>
            </div>

            <!-- Divider -->
            <div style="border-top: 1px solid #1e293b; margin: 12px 20px;"></div>

            <!-- Top Event -->
            <div style="padding: 0 20px;">
              $topEventHtml
            </div>

            <!-- Event Breakdown -->
            <div style="padding: 0 20px 12px 20px;">
              <p style="color: #c5c6c7; font-size: 16px; margin: 0 0 8px 0; letter-spacing: 1px;">EVENT BREAKDOWN</p>
              <table style="width: 100%; border-collapse: collapse;">
                $categoryRows
              </table>
            </div>

            <!-- Divider -->
            <div style="border-top: 1px solid #1e293b; margin: 0 20px 12px 20px;"></div>

            <!-- Severity Breakdown -->
            <div style="padding: 0 20px 12px 20px;">
              <p style="color: #c5c6c7; font-size: 16px; margin: 0 0 8px 0; letter-spacing: 1px;">SEVERITY BREAKDOWN</p>
              <table style="width: 100%; border-collapse: collapse;">
                $severityRows
              </table>
            </div>

            <!-- Divider -->
            <div style="border-top: 1px solid #1e293b; margin: 0 20px 12px 20px;"></div>

            <!-- AI Summary Placeholder -->
            <div style="padding: 0 20px 16px 20px;">
              <p style="color: #c5c6c7; font-size: 16px; margin: 0 0 8px 0; letter-spacing: 1px;">AI REGIONAL SUMMARY</p>
              <div style="background-color: #1e293b; border-radius: 8px; padding: 12px 14px; border-left: 3px solid #06b6d4;">
                <p style="color: #a9aaab; font-size: 20px; font-style: italic; margin: 0;">
                  $geminiSummary
                </p>
              </div>
            </div>

          </div>
        ]]></text>
      </BalloonStyle>
    </Style>

    <Placemark>
      <styleUrl>#region_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point>
        <coordinates>0,0,0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>''';
  }

  static String generateHistoricalOverlayKml(
    String eventName,
    String summary,
    String locationName,
  ) {
    String date = '';
    String location = '';
    String scale = '';
    String description = '';
    String significance = '';

    for (final line in summary.split('\n')) {
      if (line.startsWith('DATE:')) {
        date = line.replaceFirst('DATE:', '').trim();
      }

      if (line.startsWith('LOCATION:')) {
        location = line.replaceFirst('LOCATION:', '').trim();
      }

      if (line.startsWith('SCALE:')) {
        scale = line.replaceFirst('SCALE:', '').trim();
      }

      if (line.startsWith('DESCRIPTION:')) {
        description = line.replaceFirst('DESCRIPTION:', '').trim();
      }

      if (line.startsWith('SIGNIFICANCE:')) {
        significance = line.replaceFirst('SIGNIFICANCE:', '').trim();
      }
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <Style id="historical_style">
      <BalloonStyle>
        <bgColor>ff0f172a</bgColor>
        <text><![CDATA[
          <div style="font-family: Arial, sans-serif; width: 900px; background-color: #0f172a; color: #ffffff; border-radius: 12px; overflow: hidden;">

            <!-- Header -->
            <div style="background: linear-gradient(135deg, #1e293b, #0f172a); padding: 20px; border-bottom: 2px solid #06b6d4;">
              <p style="color: #06b6d4; font-size: 16px; margin: 0 0 6px 0; letter-spacing: 2px;">HISTORICAL EVENT</p>
              <h2 style="color: #ffffff; font-size: 30px; margin: 0; line-height: 1.3;">$eventName</h2>
              <p style="color: #94a3b8; font-size: 20px; margin: 8px 0 0 0;">📍 $locationName</p>
            </div>

            <!-- Key Facts -->
            <div style="padding: 16px 20px; background-color: #1e293b; margin: 12px 20px; border-radius: 8px;">
              <p style="color: #64748b; font-size: 16px; margin: 0 0 8px 0; letter-spacing: 1px;">KEY FACTS</p>
              <table style="width: 100%; border-collapse: collapse;">
                <tr>
                  <td style="color: #94a3b8; font-size: 18px; padding: 4px 0; width: 40%;">Date</td>
                  <td style="color: #ffffff; font-size: 18px; padding: 4px 0;">$date</td>
                </tr>
                <tr>
                  <td style="color: #94a3b8; font-size: 18px; padding: 4px 0;">Location</td>
                  <td style="color: #ffffff; font-size: 18px; padding: 4px 0;">$location</td>
                </tr>
                <tr>
                  <td style="color: #94a3b8; font-size: 18px; padding: 4px 0;">Scale</td>
                  <td style="color: #ffffff; font-size: 18px; padding: 4px 0;">$scale</td>
                </tr>
              </table>
            </div>

            <!-- Divider -->
            <div style="border-top: 1px solid #1e293b; margin: 0 20px;"></div>

            <!-- Description -->
            <div style="padding: 12px 20px;">
              <p style="color: #64748b; font-size: 16px; margin: 0 0 6px 0; letter-spacing: 1px;">WHAT HAPPENED</p>
              <p style="color: #cbd5e1; font-size: 20px; line-height: 1.6; margin: 0;">$description</p>
            </div>

            <!-- Divider -->
            <div style="border-top: 1px solid #1e293b; margin: 0 20px;"></div>

            <!-- Significance -->
            <div style="padding: 12px 20px 16px 20px;">
              <p style="color: #64748b; font-size: 16px; margin: 0 0 6px 0; letter-spacing: 1px;">HISTORICAL SIGNIFICANCE</p>
              <div style="background-color: #1e293b; border-left: 3px solid #06b6d4; padding: 10px 14px; border-radius: 4px;">
                <p style="color: #e2e8f0; font-size: 20px; font-style: italic; margin: 0; line-height: 1.5;">$significance</p>
              </div>
            </div>

          </div>
        ]]></text>
      </BalloonStyle>
    </Style>

    <Placemark>
      <styleUrl>#historical_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point>
        <coordinates>0,0,0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>''';
  }

  static String generateBriefingOverlayKml({
    required int totalEvents,
    required int earthquakeCount,
    required int disasterCount,
    required int diseaseCount,
    required int criticalCount,
    required int highCount,
    required int mediumCount,
    required int lowCount,
    required List<MapEntry<String, int>> topRegions,
    required String dateTime,
  }) {
    // Build top regions rows
    final regionRows = topRegions
        .take(5)
        .map(
          (r) =>
              '''
    <tr>
      <td style="color: #94a3b8; font-size: 20px; padding: 4px 0;">
        ${r.key}
      </td>
      <td style="color: #ffffff; font-size: 20px; padding: 4px 0; 
          text-align: right; font-weight: bold;">
        ${r.value}
      </td>
    </tr>
  ''',
        )
        .join('');

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <Style id="briefing_style">
      <BalloonStyle>
        <bgColor>ff0f172a</bgColor>
        <text><![CDATA[
          <div style="font-family: Arial, sans-serif; width: 900px; 
              background-color: #0f172a; color: #ffffff; 
              border-radius: 12px; overflow: hidden;">

            <!-- Header -->
            <div style="background: linear-gradient(135deg, #06b6d4, #0284c7); 
                padding: 16px 20px;">
              <p style="color: #ffffff; font-size: 16px; margin: 0 0 4px 0; 
                  letter-spacing: 2px; opacity: 0.8;">LIVE BROADCAST</p>
              <h2 style="color: #ffffff; font-size: 30px; margin: 0; 
                  font-weight: bold;">🌍 Daily Global Pulse</h2>
              <p style="color: #e0f7ff; font-size: 18px; margin: 4px 0 0 0;">
                AI-Generated Briefing · $dateTime
              </p>
            </div>

            <!-- Total Events -->
            <div style="padding: 14px 20px 10px 20px; 
                border-bottom: 1px solid #1e293b;">
              <p style="color: #64748b; font-size: 16px; margin: 0 0 8px 0; 
                  letter-spacing: 1px;">ACTIVE EVENTS WORLDWIDE</p>
              <p style="color: #06b6d4; font-size: 52px; font-weight: bold; 
                  margin: 0; line-height: 1;">$totalEvents</p>
            </div>

            <!-- Category Breakdown -->
            <div style="padding: 12px 20px; border-bottom: 1px solid #1e293b;">
              <p style="color: #64748b; font-size: 16px; margin: 0 0 8px 0; 
                  letter-spacing: 1px;">EVENT BREAKDOWN</p>
              <table style="width: 100%; border-collapse: collapse;">
                <tr>
                  <td style="padding: 4px 0;">
                    <span style="display: inline-block; width: 10px; 
                        height: 10px; border-radius: 50%; 
                        background-color: #EF4444; margin-right: 8px;">
                    </span>
                    <span style="color: #94a3b8; font-size: 20px;">
                      Earthquakes
                    </span>
                  </td>
                  <td style="color: #ffffff; font-size: 20px; 
                      text-align: right; font-weight: bold; padding: 4px 0;">
                    $earthquakeCount
                  </td>
                </tr>
                <tr>
                  <td style="padding: 4px 0;">
                    <span style="display: inline-block; width: 10px; 
                        height: 10px; border-radius: 50%; 
                        background-color: #F97316; margin-right: 8px;">
                    </span>
                    <span style="color: #94a3b8; font-size: 20px;">
                      Disasters
                    </span>
                  </td>
                  <td style="color: #ffffff; font-size: 20px; 
                      text-align: right; font-weight: bold; padding: 4px 0;">
                    $disasterCount
                  </td>
                </tr>
                <tr>
                  <td style="padding: 4px 0;">
                    <span style="display: inline-block; width: 10px; 
                        height: 10px; border-radius: 50%; 
                        background-color: #A855F7; margin-right: 8px;">
                    </span>
                    <span style="color: #94a3b8; font-size: 20px;">
                      Disease Alerts
                    </span>
                  </td>
                  <td style="color: #ffffff; font-size: 20px; 
                      text-align: right; font-weight: bold; padding: 4px 0;">
                    $diseaseCount
                  </td>
                </tr>
              </table>
            </div>

            <!-- Severity Breakdown -->
            <div style="padding: 12px 20px; border-bottom: 1px solid #1e293b;">
              <p style="color: #64748b; font-size: 16px; margin: 0 0 8px 0; 
                  letter-spacing: 1px;">SEVERITY BREAKDOWN</p>
              <table style="width: 100%; border-collapse: collapse;">
                <tr>
                  <td style="padding: 3px 0;">
                    <span style="display: inline-block; width: 10px; 
                        height: 10px; border-radius: 50%; 
                        background-color: #EF4444; margin-right: 8px;">
                    </span>
                    <span style="color: #94a3b8; font-size: 20px;">Critical</span>
                  </td>
                  <td style="color: #EF4444; font-size: 20px; 
                      text-align: right; font-weight: bold; padding: 3px 0;">
                    $criticalCount
                  </td>
                </tr>
                <tr>
                  <td style="padding: 3px 0;">
                    <span style="display: inline-block; width: 10px; 
                        height: 10px; border-radius: 50%; 
                        background-color: #F97316; margin-right: 8px;">
                    </span>
                    <span style="color: #94a3b8; font-size: 20px;">High</span>
                  </td>
                  <td style="color: #F97316; font-size: 20px; 
                      text-align: right; font-weight: bold; padding: 3px 0;">
                    $highCount
                  </td>
                </tr>
                <tr>
                  <td style="padding: 3px 0;">
                    <span style="display: inline-block; width: 10px; 
                        height: 10px; border-radius: 50%; 
                        background-color: #EAB308; margin-right: 8px;">
                    </span>
                    <span style="color: #94a3b8; font-size: 20px;">Medium</span>
                  </td>
                  <td style="color: #EAB308; font-size: 20px; 
                      text-align: right; font-weight: bold; padding: 3px 0;">
                    $mediumCount
                  </td>
                </tr>
                <tr>
                  <td style="padding: 3px 0;">
                    <span style="display: inline-block; width: 10px; 
                        height: 10px; border-radius: 50%; 
                        background-color: #22C55E; margin-right: 8px;">
                    </span>
                    <span style="color: #94a3b8; font-size: 20px;">Low</span>
                  </td>
                  <td style="color: #22C55E; font-size: 20px; 
                      text-align: right; font-weight: bold; padding: 3px 0;">
                    $lowCount
                  </td>
                </tr>
              </table>
            </div>

            <!-- Top Regions -->
            <div style="padding: 12px 20px; border-bottom: 1px solid #1e293b;">
              <p style="color: #64748b; font-size: 16px; margin: 0 0 8px 0; 
                  letter-spacing: 1px;">TOP ACTIVE REGIONS</p>
              <table style="width: 100%; border-collapse: collapse;">
                $regionRows
              </table>
            </div>

            <!-- AI Briefing Footer -->
            <div style="padding: 12px 20px; 
                background-color: #1e293b; text-align: center;">
              <p style="color: #06b6d4; font-size: 18px; margin: 0; 
                  font-style: italic;">
                ✦ AI Briefing In Progress...
              </p>
              <p style="color: #475569; font-size: 16px; margin: 4px 0 0 0;">
                Powered by Google Gemini 4 via Global Pulse
              </p>
            </div>

          </div>
        ]]></text>
      </BalloonStyle>
    </Style>

    <Placemark>
      <styleUrl>#briefing_style</styleUrl>
      <gx:balloonVisibility>1</gx:balloonVisibility>
      <Point>
        <coordinates>0,0,0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>''';
  }

  static String _getHeaderImageURL(EventCategory category) {
    switch (category) {
      case EventCategory.earthquake:
        return 'https://images.unsplash.com/photo-1677233860259-ce1a8e0f8498?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
      case EventCategory.floodStorm:
        return 'https://images.unsplash.com/photo-1470115209269-18dd2d7285cd?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
      case EventCategory.wildfire:
        return 'https://images.unsplash.com/photo-1615092296061-e2ccfeb2f3d6?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
      case EventCategory.diseaseOutbreak:
        return 'https://images.unsplash.com/photo-1584036561566-baf8f5f1b144?q=80&w=1932&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';
      default:
        return 'https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEgXmdNgBTXup6bdWew5RzgCmC9pPb7rK487CpiscWB2S8OlhwFHmeeACHIIjx4B5-Iv-t95mNUx0JhB_oATG3-Tq1gs8Uj0-Xb9Njye6rHtKKsnJQJlzZqJxMDnj_2TXX3eA5x6VSgc8aw/s1600/LOGO+LIQUID+GALAXY-sq1000-+OKnoline.png';
    }
  }

  static String _categoryColorHex(EventCategory category) {
    switch (category) {
      case EventCategory.earthquake:
        return '#EF4444';
      case EventCategory.floodStorm:
        return '#3B82F6';
      case EventCategory.wildfire:
        return '#F97316';
      case EventCategory.diseaseOutbreak:
        return '#A855F7';
      case EventCategory.conflict:
        return '#EAB308';
    }
  }

  static String _severityColorHex(EventSeverity severity) {
    switch (severity) {
      case EventSeverity.critical:
        return '#EF4444';
      case EventSeverity.high:
        return '#F97316';
      case EventSeverity.medium:
        return '#EAB308';
      case EventSeverity.low:
        return '#22C55E';
    }
  }

  static String _getContextualInsight(
    EventCategory category,
    EventSeverity severity,
  ) {
    switch (category) {
      case EventCategory.earthquake:
        switch (severity) {
          case EventSeverity.critical:
            return 'A critical magnitude earthquake poses immediate risk of structural collapse, tsunamis, and mass casualties. Emergency response teams are likely being deployed across the affected region.';
          case EventSeverity.high:
            return 'A high severity earthquake may cause significant structural damage and infrastructure disruption. Utilities and transport links in the region are likely affected.';
          case EventSeverity.medium:
            return 'A moderate earthquake may cause minor structural damage to older buildings. Aftershocks are possible in the coming hours and residents should stay alert.';
          case EventSeverity.low:
            return 'A minor seismic event unlikely to cause damage. May be felt by residents in the immediate area but poses no significant threat.';
        }

      case EventCategory.wildfire:
        switch (severity) {
          case EventSeverity.critical:
            return 'A critical wildfire is spreading rapidly across a large area, threatening lives, property, and ecosystems. Mass evacuations are likely underway and air quality is severely impacted across multiple regions.';
          case EventSeverity.high:
            return 'A high severity wildfire is actively burning across significant terrain. Containment efforts are underway but the fire poses a serious threat to nearby communities and infrastructure.';
          case EventSeverity.medium:
            return 'A moderate wildfire is burning in the affected area. Fire crews are working on containment. Smoke may affect air quality in surrounding communities.';
          case EventSeverity.low:
            return 'A minor fire event detected in the region. Currently being monitored. Limited threat to surrounding areas but conditions may change if winds increase.';
        }

      case EventCategory.floodStorm:
        switch (severity) {
          case EventSeverity.critical:
            return 'A critical flood or storm event is causing catastrophic damage to infrastructure, homes, and communities. Rescue operations are likely active and widespread displacement of residents is expected.';
          case EventSeverity.high:
            return 'A severe flood or storm is impacting the region with significant rainfall, strong winds, or storm surge. Road closures, power outages, and property damage are likely widespread.';
          case EventSeverity.medium:
            return 'A moderate flood or storm event is affecting the area. Some infrastructure disruption and localised flooding expected. Residents in low-lying areas should remain vigilant.';
          case EventSeverity.low:
            return 'A minor weather or flood event has been reported. Limited impact expected but conditions should be monitored as the situation may develop.';
        }

      case EventCategory.diseaseOutbreak:
        switch (severity) {
          case EventSeverity.critical:
            return 'A critical disease outbreak is spreading rapidly across the affected region. International health agencies are likely responding. Immediate public health containment measures including quarantine and travel restrictions may be in effect.';
          case EventSeverity.high:
            return 'A high severity disease outbreak is placing significant strain on local healthcare systems. WHO and national health authorities are actively monitoring and responding to contain further spread.';
          case EventSeverity.medium:
            return 'A moderate disease outbreak has been confirmed in the region. Health authorities have issued advisories and are working to trace contacts and contain transmission.';
          case EventSeverity.low:
            return 'A low-level disease outbreak has been reported. Currently under surveillance by local health authorities. Risk to the broader population remains limited at this stage.';
        }

      case EventCategory.conflict:
        switch (severity) {
          case EventSeverity.critical:
            return 'A critical conflict situation is causing widespread humanitarian impact. Civilian casualties, mass displacement, and infrastructure destruction are reported. International humanitarian agencies are likely mobilising emergency response.';
          case EventSeverity.high:
            return 'A high severity conflict is actively affecting the region with significant military or civil unrest activity. Movement restrictions and safety risks for civilians in the area are likely elevated.';
          case EventSeverity.medium:
            return 'A moderate conflict or civil unrest event has been reported. Localised disruption to daily life and movement is expected. Situation is being monitored by regional authorities.';
          case EventSeverity.low:
            return 'A low-level incident or tension has been reported in the region. Currently limited in scope but the situation should be monitored for any escalation.';
        }
    }
  }
}
