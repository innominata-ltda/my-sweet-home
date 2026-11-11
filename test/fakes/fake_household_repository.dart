import 'dart:async';

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

/// In-memory fake of [HouseholdRepository] for unit and widget tests.
class FakeHouseholdRepository implements HouseholdRepository {
  Household? _household;
  final List<Member> _members = [];
  bool hasPending = false;
  int backfilledCount = 0;

  final _householdController = StreamController<Household?>.broadcast();
  final _membersController = StreamController<List<Member>>.broadcast();

  FakeHouseholdRepository({
    Household? initialHousehold,
    List<Member>? initialMembers,
  }) {
    if (initialHousehold != null) {
      _household = initialHousehold;
    }
    if (initialMembers != null) {
      _members.addAll(initialMembers);
    }
  }

  Household? get household => _household;
  List<Member> get members => List.unmodifiable(_members);

  void setHousehold(Household? h) {
    _household = h;
    _householdController.add(_household);
  }

  void setMembers(List<Member> members) {
    _members.clear();
    _members.addAll(members);
    _membersController.add(List.unmodifiable(_members));
  }

  @override
  Future<Result<Household?, Failure>> getHousehold() async => Ok(_household);

  @override
  Stream<Household?> watchHousehold() async* {
    yield _household;
    yield* _householdController.stream;
  }

  @override
  Future<Result<List<Member>, Failure>> getMembers() async =>
      Ok(List.unmodifiable(_members));

  @override
  Stream<List<Member>> watchMembers() async* {
    yield List.unmodifiable(_members);
    yield* _membersController.stream;
  }

  @override
  Future<Result<Household, Failure>> createHousehold({
    required String name,
    required String deviceName,
    required Set<SyncArea> sharedAreas,
    required HouseholdKey key,
  }) async {
    final now = DateTime.utc(2026, 1, 1, 12, 0);
    final h = Household(
      id: 'household-123',
      name: name,
      localSiteId: 'site-self',
      sharedAreas: sharedAreas,
      createdAt: now,
      joinedAt: now,
      active: true,
    );
    final m = Member(
      id: 'member-self',
      householdId: h.id,
      siteId: h.localSiteId,
      name: deviceName,
      joinedAt: now,
      lastSeenAt: now,
      active: true,
    );

    _household = h;
    _members.add(m);
    _householdController.add(_household);
    _membersController.add(List.unmodifiable(_members));

    return Ok(h);
  }

  @override
  Future<Result<void, Failure>> updateSharedAreas(Set<SyncArea> areas) async {
    if (_household != null) {
      _household = _household!.copyWith(sharedAreas: areas);
      _householdController.add(_household);
    }
    return const Ok(null);
  }

  @override
  Future<Result<int, Failure>> runInitialBackfill(Household household) async {
    backfilledCount = 42;
    return Ok(backfilledCount);
  }

  @override
  Future<Result<bool, Failure>> hasPendingLocalChanges() async =>
      Ok(hasPending);

  @override
  Future<Result<void, Failure>> leaveHousehold({required bool keepCopy}) async {
    _household = null;
    _members.clear();
    _householdController.add(null);
    _membersController.add(const []);
    return const Ok(null);
  }

  HouseholdJoinPreviewData previewData = const HouseholdJoinPreviewData(
    homeRecordsCount: 5,
    financeRecordsCount: 10,
    catalogRecordsCount: 20,
  );

  @override
  Future<Result<HouseholdJoinPreviewData, Failure>>
  getJoinPreviewData() async => Ok(previewData);

  @override
  Future<Result<Household, Failure>> joinHousehold({
    required String householdId,
    required String householdName,
    required String deviceName,
    required Set<SyncArea> sharedAreas,
    required HouseholdKey key,
    List<Member> existingMembers = const [],
  }) async {
    final now = DateTime.utc(2026, 1, 1, 12, 0);
    final h = Household(
      id: householdId,
      name: householdName,
      localSiteId: 'site-joined',
      sharedAreas: sharedAreas,
      createdAt: now,
      joinedAt: now,
      active: true,
    );
    final selfMember = Member(
      id: 'member-joined-self',
      householdId: h.id,
      siteId: h.localSiteId,
      name: deviceName,
      joinedAt: now,
      lastSeenAt: now,
      active: true,
    );

    _household = h;
    _members.clear();
    _members.add(selfMember);
    _members.addAll(existingMembers);
    _householdController.add(_household);
    _membersController.add(List.unmodifiable(_members));

    return Ok(h);
  }

  @override
  Future<Result<void, Failure>> removeMember(String memberId) async {
    _members.removeWhere((m) => m.id == memberId);
    _membersController.add(List.unmodifiable(_members));
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> upsertMember({
    required String siteId,
    required String deviceName,
    DateTime? lastSeenAt,
  }) async {
    final now = lastSeenAt ?? DateTime.utc(2026, 1, 1, 12, 0);
    final idx = _members.indexWhere((m) => m.siteId == siteId);
    if (idx >= 0) {
      final old = _members[idx];
      _members[idx] = Member(
        id: old.id,
        householdId: old.householdId,
        siteId: siteId,
        name: deviceName.isNotEmpty ? deviceName : old.name,
        joinedAt: old.joinedAt,
        lastSeenAt: now,
        active: true,
      );
    } else {
      _members.add(
        Member(
          id: 'member-$siteId',
          householdId: _household?.id ?? 'household-123',
          siteId: siteId,
          name: deviceName.isNotEmpty ? deviceName : 'Aparelho',
          joinedAt: now,
          lastSeenAt: now,
          active: true,
        ),
      );
    }
    _membersController.add(List.unmodifiable(_members));
    return const Ok(null);
  }

  void dispose() {
    _householdController.close();
    _membersController.close();
  }
}
