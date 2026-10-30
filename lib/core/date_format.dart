const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

// Example: 15 October 2026 (used on the review screen)
String formatLongDate(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  return '$day ${_months[d.month - 1]} ${d.year}';
}

// Example: 10/15/2026 (used inside the form field, like Figma)
String formatShortDate(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$m/$day/${d.year}';
}