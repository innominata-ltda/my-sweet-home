import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/mascot/data/repositories/drift_mascot_repository.dart';
import 'package:my_sweet_home/features/mascot/data/resolvers/mascot_asset_resolver_impl.dart';
import 'package:my_sweet_home/features/mascot/domain/entities/mascot_config.dart';
import 'package:my_sweet_home/features/mascot/domain/ports/mascot_asset_resolver.dart';
import 'package:my_sweet_home/features/mascot/domain/ports/mascot_repository.dart';

/// Mascot repository port provider.
final mascotRepositoryProvider = Provider<MascotRepository>((ref) {
  return DriftMascotRepository(
    db: ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  );
});

/// Provedor do resolvedor de assets da mascote.
final mascotAssetResolverProvider = Provider<MascotAssetResolver>((ref) {
  return const MascotAssetResolverImpl();
});

/// Stream provider reacting in real time to mascot changes (CA-110.3).
final mascotConfigStreamProvider = StreamProvider<MascotConfig>((ref) {
  final repository = ref.watch(mascotRepositoryProvider);
  return repository.watchConfig();
});
