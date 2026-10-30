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
// Example: 30 September 2026 · 2:12 PM
String formatDateTime(DateTime d) {
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final period = d.hour >= 12 ? 'PM' : 'AM';
  return '${formatLongDate(d)} · $hour12:$minute $period';
}