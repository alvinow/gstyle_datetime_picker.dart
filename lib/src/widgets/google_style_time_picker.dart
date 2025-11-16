import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../enums/timezone_option.dart';

/// A Google-style time picker widget with 12-hour or 24-hour format
class GoogleStyleTimePicker extends StatefulWidget {
  /// Initial time to display (defaults to current time if null)
  final DateTime? initialTime;

  /// Use 24-hour format (true) or 12-hour format with AM/PM (false)
  final bool use24HourFormat;

  /// Timezone conversion option
  final TimeZoneOption timeZoneOption;

  /// Specific timezone name (required when timeZoneOption is forceSpecific)
  final String? specificTimeZone;

  /// Make the picker read-only (displays values but prevents modification)
  final bool readOnly;

  /// Callback when time is selected
  final void Function(DateTime) onTimeSelected;

  /// Callback when time is changed (called on every dropdown change)
  final void Function(DateTime)? onChanged;

  const GoogleStyleTimePicker({
    Key? key,
    this.initialTime,
    this.use24HourFormat = false,
    this.timeZoneOption = TimeZoneOption.keepUnchanged,
    this.specificTimeZone,
    this.readOnly = false,
    required this.onTimeSelected,
    this.onChanged,
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
    final time = widget.initialTime ?? DateTime.now();
    if (widget.use24HourFormat) {
      selectedHour = time.hour;
      selectedMinute = time.minute;
      selectedPeriod = '';
    } else {
      final hourOfPeriod = time.hour % 12;
      selectedHour = hourOfPeriod == 0 ? 12 : hourOfPeriod;
      selectedMinute = time.minute;
      selectedPeriod = time.hour >= 12 ? 'PM' : 'AM';
    }
  }

  void _validateAndSubmit() {
    if (widget.readOnly) return;

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

    final now = DateTime.now();
    DateTime selectedDateTime = DateTime(now.year, now.month, now.day, hour24, selectedMinute);
    selectedDateTime = _applyTimeZone(selectedDateTime);

    widget.onTimeSelected(selectedDateTime);
    widget.onChanged?.call(selectedDateTime);
  }

  DateTime _applyTimeZone(DateTime dateTime) {
    switch (widget.timeZoneOption) {
      case TimeZoneOption.keepUnchanged:
        return dateTime;
      case TimeZoneOption.forceSystemTimeZone:
        return dateTime.toLocal();
      case TimeZoneOption.forceSpecific:
        if (widget.specificTimeZone != null) {
          final location = tz.getLocation(widget.specificTimeZone!);
          final tzDateTime = tz.TZDateTime.from(dateTime, location);
          return tzDateTime;
        }
        return dateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.readOnly)
          Row(
            children: [
              const Text(
                'Time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Read Only',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
        if (widget.readOnly) const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: 'Hour',
                value: selectedHour.toString().padLeft(widget.use24HourFormat ? 2 : 1, '0'),
                items: widget.use24HourFormat
                    ? List.generate(24, (i) => i.toString().padLeft(2, '0'))
                    : List.generate(12, (i) => (i + 1).toString()),
                onChanged: widget.readOnly ? null : (val) {
                  setState(() => selectedHour = int.parse(val!));
                  _validateAndSubmit();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown(
                label: 'Minute',
                value: selectedMinute.toString().padLeft(2, '0'),
                items: List.generate(60, (i) => i.toString().padLeft(2, '0')),
                onChanged: widget.readOnly ? null : (val) {
                  setState(() => selectedMinute = int.parse(val!));
                  _validateAndSubmit();
                },
              ),
            ),
            if (!widget.use24HourFormat) ...[
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Period',
                  value: selectedPeriod,
                  items: const ['AM', 'PM'],
                  onChanged: widget.readOnly ? null : (val) {
                    setState(() => selectedPeriod = val!);
                    _validateAndSubmit();
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?)? onChanged,
  }) {
    final isDisabled = onChanged == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDisabled ? Colors.grey[400] : Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDisabled ? Colors.grey[300]! : Colors.grey[400]!,
            ),
            borderRadius: BorderRadius.circular(4),
            color: isDisabled ? Colors.grey[100] : Colors.white,
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                enabled: !isDisabled,
                child: Text(
                  item,
                  style: TextStyle(
                    color: isDisabled ? Colors.grey[600] : Colors.black,
                  ),
                ),
              );
            }).toList(),
            onChanged: isDisabled ? null : onChanged,
            disabledHint: Text(
              value,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      ],
    );
  }
}