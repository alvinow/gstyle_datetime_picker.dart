import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../enums/timezone_option.dart';

/// A Google-style time picker widget with 12-hour or 24-hour format
class GoogleStyleTimePicker extends StatefulWidget {
  /// Initial time to display
  final TimeOfDay initialTime;

  /// Use 24-hour format (true) or 12-hour format with AM/PM (false)
  final bool use24HourFormat;

  /// Timezone conversion option
  final TimeZoneOption timeZoneOption;

  /// Specific timezone name (required when timeZoneOption is forceSpecific)
  final String? specificTimeZone;

  /// Callback when time is selected
  final Function(TimeOfDay) onTimeSelected;

  const GoogleStyleTimePicker({
    Key? key,
    required this.initialTime,
    this.use24HourFormat = false,
    this.timeZoneOption = TimeZoneOption.keepUnchanged,
    this.specificTimeZone,
    required this.onTimeSelected,
  }) : super(key: key);

  @override
  State<GoogleStyleTimePicker> createState() => _GoogleStyleTimePickerState();
}

class _GoogleStyleTimePickerState extends State<GoogleStyleTimePicker> {
  late int selectedHour;
  late int selectedMinute;
  late String selectedPeriod;

  @override
  void initState() {
    super.initState();
    if (widget.use24HourFormat) {
      selectedHour = widget.initialTime.hour;
      selectedMinute = widget.initialTime.minute;
      selectedPeriod = '';
    } else {
      selectedHour = widget.initialTime.hourOfPeriod == 0 ? 12 : widget.initialTime.hourOfPeriod;
      selectedMinute = widget.initialTime.minute;
      selectedPeriod = widget.initialTime.period == DayPeriod.am ? 'AM' : 'PM';
    }
  }

  void _validateAndSubmit() {
    int hour24;

    if (widget.use24HourFormat) {
      hour24 = selectedHour;
    } else {
      hour24 = selectedHour;
      if (selectedPeriod == 'PM' && selectedHour != 12) {
        hour24 = selectedHour + 12;
      } else if (selectedPeriod == 'AM' && selectedHour == 12) {
        hour24 = 0;
      }
    }

    TimeOfDay time = TimeOfDay(hour: hour24, minute: selectedMinute);
    time = _applyTimeZone(time);

    widget.onTimeSelected(time);
    Navigator.of(context).pop();
  }

  TimeOfDay _applyTimeZone(TimeOfDay time) {
    final now = DateTime.now();
    DateTime dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);

    switch (widget.timeZoneOption) {
      case TimeZoneOption.keepUnchanged:
        return time;
      case TimeZoneOption.forceSystemTimeZone:
        dateTime = dateTime.toLocal();
        return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
      case TimeZoneOption.forceSpecific:
        if (widget.specificTimeZone != null) {
          final location = tz.getLocation(widget.specificTimeZone!);
          final tzDateTime = tz.TZDateTime.from(dateTime, location);
          return TimeOfDay(hour: tzDateTime.hour, minute: tzDateTime.minute);
        }
        return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Time',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Hour',
                    value: selectedHour.toString().padLeft(widget.use24HourFormat ? 2 : 1, '0'),
                    items: widget.use24HourFormat
                        ? List.generate(24, (i) => i.toString().padLeft(2, '0'))
                        : List.generate(12, (i) => (i + 1).toString()),
                    onChanged: (val) => setState(() => selectedHour = int.parse(val!)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Minute',
                    value: selectedMinute.toString().padLeft(2, '0'),
                    items: List.generate(60, (i) => i.toString().padLeft(2, '0')),
                    onChanged: (val) => setState(() => selectedMinute = int.parse(val!)),
                  ),
                ),
                if (!widget.use24HourFormat) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Period',
                      value: selectedPeriod,
                      items: const ['AM', 'PM'],
                      onChanged: (val) => setState(() => selectedPeriod = val!),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _validateAndSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}