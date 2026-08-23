/// Durations shown on a clock face.
///
/// Every screen used to roll its own `mm:ss`, and none of them rolled over
/// into hours — so a puzzle left open for an afternoon read "299:09" instead
/// of "4:59:09". Sudoku is a game people put down and pick up days later, so
/// the hour case is normal rather than exotic.
String clockTime(int seconds) {
  if (seconds < 0) seconds = 0;
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  // No leading zero on the hour: 4:59:09 reads as a duration, 04:59:09 reads
  // as a time of day.
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

/// A duration in words, for screen readers and prose.
///
/// "04:12" is read aloud as "four twelve", which is not a length of time.
String spokenDuration(int seconds) {
  if (seconds <= 0) return 'no time yet';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final parts = <String>[
    if (h > 0) '$h hour${h == 1 ? '' : 's'}',
    if (m > 0) '$m minute${m == 1 ? '' : 's'}',
    // Seconds are noise once it has run to hours.
    if (s > 0 && h == 0) '$s second${s == 1 ? '' : 's'}',
  ];
  return parts.join(' ');
}

/// A difference between two times, signed and compact.
///
/// Not a clock face: "−02:05" reads as a stopwatch, and the sign is the point.
/// Rolls into hours for the same reason [clockTime] does — "−94m 12s" is a
/// number you have to do arithmetic on before it means anything.
///
/// A positive [seconds] means faster, and prints with a minus: shaving time
/// off is the good direction, and the sign has to agree with that or the
/// number reads backwards.
String deltaTime(int seconds) {
  final sign = seconds >= 0 ? '\u2212' : '+';
  final abs = seconds.abs();
  final h = abs ~/ 3600;
  final m = (abs % 3600) ~/ 60;
  final s = abs % 60;
  if (h > 0) return '$sign${h}h ${m.toString().padLeft(2, '0')}m';
  if (m > 0) return '$sign${m}m ${s.toString().padLeft(2, '0')}s';
  return '$sign${s}s';
}
