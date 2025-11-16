import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../enums/timezone_option.dart';

/// A Google-style date picker widget with dropdown selectors
class GoogleStyleDatePicker extends StatefulWidget {
  /// Locale for month name formatting (e.g., 'en_US', 'id_ID')
  final String locale;

  /// Initial date to display (defaults to current date if null)
  final DateTime? initialDate;

  /// Minimum selectable date
  final DateTime minDate;

  /// Maximum selectable date
  final DateTime maxDate;

  /// Timezone conversion option
  final TimeZoneOption timeZoneOption;

  /// Specific timezone name (required when timeZoneOption is forceSpecific)
  /// Example: 'Asia/Jakarta', 'America/New_York'
  final String? specificTimeZone;

  /// Make the picker read-only (displays values but prevents modification)
  final bool readOnly;

  /// Callback when date is selected
  final Function(DateTime) onDateSelected;

  const GoogleStyleDatePicker({
    Key? key,
    required this.locale,
    this.initialDate,
    required this.minDate,
    required this.maxDate,
    this.timeZoneOption = TimeZoneOption.keepUnchanged,
    this.specificTimeZone,
    this.readOnly = false,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  State<GoogleStyleDatePicker> createState() => _GoogleStyleDatePickerState();
}

class _GoogleStyleDatePickerState extends State<GoogleStyleDatePicker> {
  late int selectedDay;
  late int selectedMonth;
  late int selectedYear;
  late List<String> monthNames;

  @override
  void initState() {
    super.initState();
    final date = widget.initialDate ?? DateTime.now();
    selectedDay = date.day;
    selectedMonth = date.month;
    selectedYear = date.year;
    monthNames = _generateMonthNames();
  }

  List<String> _generateMonthNames() {
    final List<String> months = [];
    final DateFormat formatter = DateFormat.MMMM(widget.locale);

    for (int i = 1; i <= 12; i++) {
      final date = DateTime(2024, i, 1);
      months.add(formatter.format(date));
    }

    return months;
  }

  bool isDateValid(int day, int month, int year) {
    try {
      final date = DateTime(year, month, day);
      return date.isAfter(widget.minDate.subtract(const Duration(days: 1))) &&
          date.isBefore(widget.maxDate.add(const Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }

  int getDaysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }

  void _validateAndSubmit() {
    if (widget.readOnly) {
      Navigator.of(context).pop();
      return;
    }

    final maxDays = getDaysInMonth(selectedMonth, selectedYear);
    if (selectedDay > maxDays) {
      selectedDay = maxDays;
    }

    if (!isDateValid(selectedDay, selectedMonth, selectedYear)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Date must be between ${widget.minDate.day}/${widget.minDate.month}/${widget.minDate.year} and ${widget.maxDate.day}/${widget.maxDate.month}/${widget.maxDate.year}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    DateTime selectedDate = DateTime(selectedYear, selectedMonth, selectedDay);
    selectedDate = _applyTimeZone(selectedDate);

    widget.onDateSelected(selectedDate);
    Navigator.of(context).pop();
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.readOnly ? 'Date' : 'Select Date',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (widget.readOnly) ...[
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
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Day',
                    value: selectedDay.toString(),
                    items: List.generate(31, (i) => (i + 1).toString()),
                    onChanged: widget.readOnly ? null : (val) => setState(() => selectedDay = int.parse(val!)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildDropdown(
                    label: 'Month',
                    value: monthNames[selectedMonth - 1],
                    items: monthNames,
                    onChanged: widget.readOnly ? null : (val) => setState(() =>
                    selectedMonth = monthNames.indexOf(val!) + 1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Year',
                    value: selectedYear.toString(),
                    items: List.generate(
                      widget.maxDate.year - widget.minDate.year + 1,
                          (i) => (widget.minDate.year + i).toString(),
                    ),
                    onChanged: widget.readOnly ? null : (val) => setState(() => selectedYear = int.parse(val!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(widget.readOnly ? 'Close' : 'Cancel'),
                ),
                if (!widget.readOnly) ...[
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