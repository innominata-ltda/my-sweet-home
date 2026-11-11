/// Pure converter of RRULE to readable phrase in pt-BR (SPEC-014, RN-353, CA-1.5).
final class RecommendedFrequencyPhrase {
  const RecommendedFrequencyPhrase();

  String toPtBr(String rrule) {
    final parts = rrule.toUpperCase().split(';');
    final map = <String, String>{};
    for (final part in parts) {
      final kv = part.split('=');
      if (kv.length == 2) {
        map[kv[0].trim()] = kv[1].trim();
      }
    }

    final freq = map['FREQ'] ?? 'DAILY';
    final interval = int.tryParse(map['INTERVAL'] ?? '1') ?? 1;

    switch (freq) {
      case 'DAILY':
        if (interval == 1) return 'todo dia';
        if (interval == 7) return 'toda semana';
        return 'a cada $interval dias';
      case 'WEEKLY':
        if (interval == 1) return 'toda semana';
        return 'a cada $interval semanas';
      case 'MONTHLY':
        if (interval == 1) return 'todo mês';
        return 'a cada $interval meses';
      case 'YEARLY':
        if (interval == 1) return 'todo ano';
        return 'a cada $interval anos';
      default:
        return 'a cada $interval dias';
    }
  }
}
