/// Enum for timezone conversion options
enum TimeZoneOption {
  /// Keep the datetime unchanged without any timezone conversion
  keepUnchanged,

  /// Convert to the system's local timezone
  forceSystemTimeZone,

  /// Convert to a specific timezone (requires specificTimeZone parameter)
  forceSpecific,
}