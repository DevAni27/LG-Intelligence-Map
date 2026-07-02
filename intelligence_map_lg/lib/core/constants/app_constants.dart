/// Application-wide constants for LG Intelligence Map.

class AppConstants {
  AppConstants._();

  static const String appName = 'LG Intelligence Map';
  static const String appTagline = 'Monitoring global events in real-time';

  // SSH defaults (user will override in Settings)
  static const int defaultSSHPort = 22;
  static const String defaultSSHUser = 'lg';
  static const String defaultSSHPassword = 'lg';
  static const int defaultNumberOfRigs = 3;

  // Data refresh intervals
  static const Duration dataRefreshInterval = Duration(minutes: 5);
  static const Duration kmlRefreshInterval = Duration(seconds: 30);

  // KML constants
  static const String kmlFileName = 'global_pulse_events.kml';
  static const String kmlLogoFileName = 'global_pulse_logo.kml';
  static const double defaultAltitude = 0;
  static const double highSeverityHeight = 500000; // meters
  static const double mediumSeverityHeight = 250000;
  static const double lowSeverityHeight = 100000;

  // Hive box names
  static const String eventsBox = 'events_box';
  static const String settingsBox = 'settings_box';

  // Settings keys
  static const String keySSHHost = 'ssh_host';
  static const String keySSHPort = 'ssh_port';
  static const String keySSHUser = 'ssh_user';
  static const String keySSHPassword = 'ssh_password';
  static const String keyNumberOfRigs = 'number_of_rigs';
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyLanguage = 'language';
}

class ApiEndpoints {
  ApiEndpoints._();

  // USGS Earthquake API
  static const String usgsBase = 'https://earthquake.usgs.gov/earthquakes/feed/v1.0';
  static const String usgsAllDay = '$usgsBase/summary/all_day.geojson';
  static const String usgsAllWeek = '$usgsBase/summary/all_week.geojson';
  static const String usgsAllMonth = '$usgsBase/summary/all_month.geojson';
  static const String usgsSignificantDay = '$usgsBase/summary/significant_day.geojson';
  static const String usgsQuery = 'https://earthquake.usgs.gov/fdsnws/event/1/query';

  // NASA EONET
  static const String nasaEonetEvents = 'https://eonet.gsfc.nasa.gov/api/v3/events';
  static const String nasaEonetCategories = 'https://eonet.gsfc.nasa.gov/api/v3/categories';

  // WHO Disease Outbreak News (RSS)
  static const String who = "https://www.who.int/api/news/diseaseoutbreaknews?sf_culture=en&\$orderby=PublicationDate+desc&\$top=100";
}
