import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/features/sync/data/household_repository_provider.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';

export 'package:my_sweet_home/features/sync/data/household_repository_provider.dart'
    show
        householdRepositoryProvider,
        householdKeyStoreProvider,
        createHouseholdUseCaseProvider,
        leaveHouseholdUseCaseProvider,
        setAreasUseCaseProvider,
        joinHouseholdUseCaseProvider,
        syncNowUseCaseProvider,
        removeMemberUseCaseProvider,
        pairingChannelProvider,
        calendarOwnerGuardProvider,
        lanSyncTransportProvider,
        remoteSyncTransportProvider,
        compositeSyncTransportProvider,
        bundleSyncTransportProvider;

final householdStreamProvider = StreamProvider<Household?>((ref) {
  final repo = ref.watch(householdRepositoryProvider);
  return repo.watchHousehold();
});

final householdMembersStreamProvider = StreamProvider<List<Member>>((ref) {
  final repo = ref.watch(householdRepositoryProvider);
  return repo.watchMembers();
});

final householdPendingChangesProvider = FutureProvider<bool>((ref) {
  final repo = ref.watch(householdRepositoryProvider);
  return repo.hasPendingLocalChanges().then((r) => r.valueOrNull ?? false);
});
