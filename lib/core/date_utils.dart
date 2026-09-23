String formatDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day.toString().padLeft(2, '0')} '
      '${months[date.month - 1]} ${date.year}';
}

String formatShortDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

String dayName(DateTime date) {
  const days = <String>[
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  return days[date.weekday - 1];
}

String relativeDayLabel(DateTime date, [DateTime? referenceDate]) {
  final ref = dateOnly(referenceDate ?? DateTime.now());
  final target = dateOnly(date);
  final diffDays = target.difference(ref).inDays;
  if (diffDays == 0) return 'Hari Ini';
  if (diffDays == -1) return 'Kemarin';
  if (diffDays == -2) return '2 Hari Lalu';
  if (diffDays == 1) return 'Besok';
  return dayName(date);
}

String toDateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
