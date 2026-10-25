String formatDuration(double seconds) {
  if (seconds.isNaN || seconds <= 0) return '0:00';
  final d = Duration(milliseconds: (seconds * 1000).round());
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

String formatBytes(num bytes) {
  const units = ['o', 'Ko', 'Mo', 'Go', 'To'];
  var v = bytes.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
}

/// Short resolution label as shown by Stash (e.g. "1080p", "4K").
String? resolutionLabel(int width, int height) {
  final p = width < height ? width : height;
  if (p <= 0) return null;
  if (p >= 4320) return '8K';
  if (p >= 2880) return '5K';
  if (p >= 2160) return '4K';
  if (p >= 1440) return '1440p';
  if (p >= 1080) return '1080p';
  if (p >= 720) return '720p';
  if (p >= 480) return '480p';
  return '${p}p';
}

/// Rating 1-100 displayed as 0-5 stars.
double starsFromRating(int? rating100) =>
    rating100 == null ? 0 : (rating100 / 20).clamp(0, 5).toDouble();

String genderLabel(String? g) => switch (g) {
  'MALE' => 'Homme',
  'FEMALE' => 'Femme',
  'TRANSGENDER_MALE' => 'Homme trans',
  'TRANSGENDER_FEMALE' => 'Femme trans',
  'INTERSEX' => 'Intersexe',
  'NON_BINARY' => 'Non-binaire',
  _ => '',
};

/// Age in years from a `YYYY-MM-DD` birthdate.
int? ageFrom(String? birthdate) {
  final b = birthdate == null ? null : DateTime.tryParse(birthdate);
  if (b == null) return null;
  final now = DateTime.now();
  var age = now.year - b.year;
  if (now.month < b.month || (now.month == b.month && now.day < b.day)) age--;
  return age;
}
