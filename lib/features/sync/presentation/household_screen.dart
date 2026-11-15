import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/settings/settings_providers.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/design_system/components/app_button.dart';
import 'package:my_sweet_home/design_system/components/app_card.dart';
import 'package:my_sweet_home/design_system/components/app_empty_state.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';
import 'package:my_sweet_home/design_system/icons/app_icons.dart';
import 'package:my_sweet_home/design_system/theme/spacing.dart';
import 'package:my_sweet_home/features/sync/domain/models/household.dart';
import 'package:my_sweet_home/features/sync/domain/ports/household_repository.dart';
import 'package:my_sweet_home/features/sync/domain/ports/pairing_channel.dart';
import 'package:my_sweet_home/features/sync/domain/ports/sync_transport_port.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';
import 'package:my_sweet_home/features/sync/presentation/bundle/bundle_import_dialog.dart';
import 'package:my_sweet_home/features/sync/presentation/bundle/bundle_share_dialog.dart';
import 'package:my_sweet_home/features/sync/presentation/household_tutorial_dialog.dart';
import 'package:my_sweet_home/features/sync/presentation/join_preview.dart';
import 'package:my_sweet_home/features/sync/presentation/leave_dialog.dart';
import 'package:my_sweet_home/features/sync/presentation/providers/household_providers.dart';
import 'package:my_sweet_home/features/sync/presentation/qr_scanner_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Shared household management screen (P2P sync) (RF-120..127, CA-4.1..4.4).
class HouseholdScreen extends ConsumerStatefulWidget {
  const HouseholdScreen({super.key, this.initialInviteUri});

  final String? initialInviteUri;

  @override
  ConsumerState<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends ConsumerState<HouseholdScreen> {
  bool _syncing = false;
  bool _householdSyncRemote = false;
  bool _calendarOwner = true;
  bool _preferencesLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLanTransportIfActive();
      final invite = widget.initialInviteUri;
      if (mounted && invite != null && invite.isNotEmpty) {
        _showJoinHouseholdDialog(context, null, initialInvite: invite);
      }
    });
  }

  void _startLanTransportIfActive() {
    try {
      ref.listenManual(householdStreamProvider, (prev, next) {
        if (next.value != null) {
          ref.read(lanSyncTransportProvider).start();
        }
      }, fireImmediately: true);
    } catch (_) {}
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_preferencesLoaded) {
      _loadPreferences();
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final settings = ref.read(settingsRepositoryProvider);
      final remote = await settings.isHouseholdSyncRemoteAllowed();
      bool isOwner = true;
      try {
        final guard = ref.read(calendarOwnerGuardProvider);
        isOwner = await guard.canLinkGoogleCalendar();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _householdSyncRemote = remote;
          _calendarOwner = isOwner;
          _preferencesLoaded = true;
        });
      }
    } catch (_) {
      // Ignore in tests without complete Drift repository
    }
  }

  Future<void> _toggleRemoteSync(bool value) async {
    setState(() => _householdSyncRemote = value);
    try {
      final settings = ref.read(settingsRepositoryProvider);
      await settings.setHouseholdSyncRemoteAllowed(value);
    } catch (_) {}
  }

  Future<void> _toggleCalendarOwner(bool value) async {
    setState(() => _calendarOwner = value);
    try {
      final guard = ref.read(calendarOwnerGuardProvider);
      if (value) {
        await guard.claimCalendarOwnership();
      } else {
        await guard.releaseCalendarOwnership();
      }
    } catch (_) {}
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      try {
        final transport = ref.read(lanSyncTransportProvider);
        await transport.start();
      } catch (_) {
        // Ignore absence of lanTransport in environments without socket/Drift
      }

      final l10n = AppLocalizations.of(context)!;
      final useCase = ref.read(syncNowUseCaseProvider);
      final report = await useCase.execute();
      if (mounted) {
        if (report.isErr) {
          final err = report.failureOrNull;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.householdSyncFailure(_formatFailure(err, l10n)),
              ),
            ),
          );
        } else {
          final r = report.valueOrNull!;
          if (r.peersContactedCount > 0) {
            final summary =
                (r.appliedChangesCount > 0 && r.sentChangesCount > 0)
                ? l10n.householdSyncBothSuffix(
                    r.sentChangesCount,
                    r.appliedChangesCount,
                  )
                : (r.appliedChangesCount > 0)
                ? l10n.householdSyncAppliedSuffix(r.appliedChangesCount)
                : l10n.householdSyncSentSuffix(r.sentChangesCount);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.householdSyncPeersCompleted(
                    r.peersContactedCount,
                    summary,
                  ),
                ),
              ),
            );
          } else if (r.sentChangesCount > 0 || r.appliedChangesCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.householdSyncCompleted(
                    r.sentChangesCount,
                    r.appliedChangesCount,
                  ),
                ),
              ),
            );
          } else if (_householdSyncRemote) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.householdCloudSyncNoChanges)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.householdSyncNoPeersFound)),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.householdSyncUnexpectedError('$e'))),
        );
      }
    }
    if (mounted) {
      ref.invalidate(householdPendingChangesProvider);
      setState(() => _syncing = false);
    }
  }

  Future<void> _maybeShowFirstTimeTutorial() async {
    try {
      final settings = ref.read(settingsRepositoryProvider);
      final seen = await settings.isHouseholdTutorialCompleted();
      if (!seen && mounted) {
        await _showTutorialDialog(context);
      }
    } catch (_) {}
  }

  Future<void> _showTutorialDialog(BuildContext context) async {
    if (!mounted) return;
    await showDialog<bool>(
      context: context,
      builder: (ctx) => HouseholdTutorialDialog(
        initialRemoteSyncEnabled: _householdSyncRemote,
        onComplete: (enableRemote) async {
          await _toggleRemoteSync(enableRemote);
          try {
            final settings = ref.read(settingsRepositoryProvider);
            await settings.setHouseholdTutorialCompleted(true);
          } catch (_) {}
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final householdAsync = ref.watch(householdStreamProvider);

    ref.listen<AsyncValue<Household?>>(householdStreamProvider, (prev, next) {
      final household = next.value;
      if (household != null) {
        try {
          ref.read(lanSyncTransportProvider).start();
        } catch (_) {}
      } else {
        try {
          ref.read(lanSyncTransportProvider).stop();
        } catch (_) {}
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.householdTitle ?? 'Casa compartilhada'),
        leading: const BackButton(),
        actions: [
          IconButton(
            key: const Key('household_tutorial_button'),
            icon: const Icon(AppIcons.info),
            tooltip: l10n?.householdHowSyncWorksTooltip,
            onPressed: () => _showTutorialDialog(context),
          ),
        ],
      ),
      body: householdAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (err, _) => Center(
          child: Text(
            l10n!.householdLoadError('$err'),
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (household) {
          if (household == null) {
            return _buildEmptyState(context, l10n);
          }
          return _buildHouseholdContent(context, household, l10n);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppEmptyState(
              icon: AppIcons.household,
              title: l10n?.householdEmptyTitle ?? 'Compartilhe a sua casa',
              description: l10n?.householdEmptyDescription ?? 'Sincronize com quem mora com você sem intermediários, sem criar conta e com segurança de ponta a ponta na rede local.',
            ),
            const SizedBox(height: Spacing.xl),
            AppButton.primary(
              key: const Key('create_household_button'),
              label: l10n?.householdCreateButton ?? 'Criar casa',
              icon: const Icon(AppIcons.add),
              fullWidth: true,
              onPressed: () => _showCreateHouseholdDialog(context, l10n),
            ),
            const SizedBox(height: Spacing.md),
            AppButton.secondary(
              key: const Key('join_household_button'),
              label: l10n?.householdJoinButton ?? 'Entrar numa casa',
              icon: const Icon(AppIcons.qrScanner),
              fullWidth: true,
              onPressed: () => _showJoinHouseholdDialog(context, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseholdContent(
    BuildContext context,
    Household household,
    AppLocalizations? l10n,
  ) {
    final membersAsync = ref.watch(householdMembersStreamProvider);
    final pendingChangesAsync = ref.watch(householdPendingChangesProvider);
    final hasPending = pendingChangesAsync.value ?? false;

    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        // 1. Header with name and synchronization state (CA-6.1)
        AppCard(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(AppIcons.household, size: 28),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      household.name,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Container(
                key: const Key('sync_status_badge'),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: hasPending
                      ? Theme.of(context).colorScheme.tertiaryContainer
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(Radius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasPending ? AppIcons.syncConflict : AppIcons.check,
                      size: 16,
                      color: hasPending
                          ? Theme.of(context).colorScheme.onTertiaryContainer
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Text(
                      hasPending
                          ? (l10n?.householdOnlyThisDevice ??
                                'Mudanças só neste aparelho')
                          : (l10n?.householdAllSynced ?? 'Tudo sincronizado'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasPending
                            ? Theme.of(context).colorScheme.onTertiaryContainer
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),

        // 2. Quick actions (Sync, Invite device, Bundles)
        Row(
          children: [
            Expanded(
              child: AppButton.primary(
                key: const Key('sync_now_button'),
                label: _syncing
                    ? (l10n?.householdSyncing ?? 'Sincronizando...')
                    : (l10n?.householdSyncNowButton ?? 'Sincronizar agora'),
                icon: const Icon(AppIcons.sync),
                onPressed: _syncNow,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: AppButton.secondary(
                key: const Key('invite_device_button'),
                label: l10n?.householdInviteButton ?? 'Convidar aparelho',
                icon: const Icon(AppIcons.qrCode),
                onPressed: () => _showInviteDeviceDialog(context, household),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                key: const Key('generate_bundle_button'),
                label: l10n?.householdGenerateBundleButton ?? 'Gerar pacote',
                icon: const Icon(AppIcons.fileExport),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => BundleShareDialog(
                      onGenerateBundle: () async {
                        final transport = ref.read(bundleSyncTransportProvider);
                        final res = await transport.generateBundle();
                        return res.valueOrNull;
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: AppButton.secondary(
                key: const Key('import_bundle_button'),
                label: l10n!.householdImportBundleButton,
                icon: const Icon(AppIcons.fileImport),
                onPressed: () => _showImportBundleDialog(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),

        // Remote sync and Calendar Owner
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                key: const Key('household_sync_remote_switch'),
                secondary: const Icon(AppIcons.sync),
                title: Text(l10n.householdCloudSyncTitle),
                subtitle: Text(l10n.householdCloudSyncSubtitle),
                value: _householdSyncRemote,
                onChanged: _toggleRemoteSync,
              ),
              const Divider(height: 1),
              SwitchListTile(
                key: const Key('calendar_owner_switch'),
                secondary: const Icon(AppIcons.calendar),
                title: Text(l10n.householdCalendarLocalTitle),
                subtitle: Text(l10n.householdCalendarLocalSubtitle),
                value: _calendarOwner,
                onChanged: _toggleCalendarOwner,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // 3. Section: Household members
        Text(
          l10n?.householdMembersTitle ?? 'Aparelhos na casa',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: Spacing.xs),
        membersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Spacing.md),
            child: AppLoading(),
          ),
          error: (err, _) => Text(l10n.householdMembersLoadError('$err')),
          data: (members) {
            return Column(
              children: members.map((member) {
                final isSelf = member.siteId == household.localSiteId;
                return AppCard(
                  key: Key('member_card_${member.id}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(AppIcons.wifi, size: 20),
                    ),
                    title: Text(member.name),
                    subtitle: Text(
                      isSelf
                          ? l10n.householdThisDevice
                          : l10n.householdLastSeen(
                              member.lastSeenAt != null
                                  ? member.lastSeenAt!.toIso8601String()
                                  : l10n.householdNeverSynced,
                            ),
                      style: TextStyle(
                        color: isSelf
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: isSelf
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelf
                        ? null
                        : IconButton(
                            key: Key('remove_member_button_${member.id}'),
                            icon: const Icon(AppIcons.delete),
                            tooltip: l10n.householdRemoveMemberTooltip,
                            onPressed: () =>
                                _confirmRemoveMember(context, member),
                          ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: Spacing.lg),

        // 4. Section: Shared areas
        Text(
          l10n?.householdAreasTitle ?? 'Áreas compartilhadas',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: Spacing.xs),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                key: const Key('area_toggle_home'),
                title: Text(
                  l10n?.householdAreaHome ??
                      'Casa (Tarefas, Estoque, Receitas)',
                ),
                value: household.sharedAreas.contains(SyncArea.home),
                onChanged: (val) {
                  final newAreas = Set<SyncArea>.from(household.sharedAreas);
                  if (val) {
                    newAreas.add(SyncArea.home);
                  } else {
                    newAreas.remove(SyncArea.home);
                  }
                  ref
                      .read(householdRepositoryProvider)
                      .updateSharedAreas(newAreas);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                key: const Key('area_toggle_finance'),
                title: Text(
                  l10n?.householdAreaFinance ??
                      'Finanças (Despesas, Contas, Preços)',
                ),
                value: household.sharedAreas.contains(SyncArea.finance),
                onChanged: (val) {
                  final newAreas = Set<SyncArea>.from(household.sharedAreas);
                  if (val) {
                    newAreas.add(SyncArea.finance);
                  } else {
                    newAreas.remove(SyncArea.finance);
                  }
                  ref
                      .read(householdRepositoryProvider)
                      .updateSharedAreas(newAreas);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.xl),

        // 5. Leave household button (T-15, RF-126)
        AppButton.danger(
          key: const Key('leave_household_button'),
          label: l10n?.householdLeaveButton ?? 'Sair da casa',
          icon: const Icon(AppIcons.deleteForever),
          fullWidth: true,
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (ctx) => LeaveHouseholdDialog(
                onConfirm: ({required bool keepCopy}) async {
                  final useCase = ref.read(leaveHouseholdUseCaseProvider);
                  await useCase.execute(keepCopy: keepCopy);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  void _showCreateHouseholdDialog(
    BuildContext context,
    AppLocalizations? l10n,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CreateHouseholdDialog(
        l10n: l10n,
        onCreateSuccess: _maybeShowFirstTimeTutorial,
      ),
    );
  }

  void _showJoinHouseholdDialog(
    BuildContext context,
    AppLocalizations? l10n, {
    String? initialInvite,
  }) {
    final loc = l10n ?? AppLocalizations.of(context)!;
    final inviteController = TextEditingController(text: initialInvite ?? '');
    final deviceNameController = TextEditingController(
      text: loc.householdDefaultDeviceName,
    );

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(loc.householdJoinDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton.secondary(
                  key: const Key('scan_qr_invite_button'),
                  label: loc.householdScanQrButton,
                  icon: const Icon(AppIcons.qrScanner),
                  fullWidth: true,
                  onPressed: () async {
                    final scanned = await showDialog<String>(
                      context: ctx,
                      builder: (_) => const QrScannerDialog(),
                    );
                    if (scanned != null && scanned.isNotEmpty) {
                      inviteController.text = scanned;
                    }
                  },
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  key: const Key('join_invite_code_input'),
                  controller: inviteController,
                  decoration: InputDecoration(
                    labelText: loc.householdInviteCodeLabel,
                    hintText: loc.householdInviteCodeHint,
                    suffixIcon: IconButton(
                      key: const Key('paste_invite_code_button'),
                      icon: const Icon(AppIcons.paste),
                      tooltip: loc.householdPasteCodeTooltip,
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null && data!.text!.isNotEmpty) {
                          inviteController.text = data.text!.trim();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  key: const Key('join_device_name_input'),
                  controller: deviceNameController,
                  decoration: InputDecoration(
                    labelText: loc.householdDeviceNameLabel,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.commonCancel),
            ),
            FilledButton(
              key: const Key('confirm_join_preview_button'),
              onPressed: () async {
                final code = inviteController.text.trim();
                final deviceName = deviceNameController.text.trim();
                if (deviceName.isEmpty) return;

                Navigator.of(ctx).pop();

                Invite invite;
                try {
                  invite = Invite.fromQrString(code);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.householdInvalidInviteError)),
                    );
                  }
                  return;
                }

                String sasCode = invite.sasCode;
                HouseholdKey householdKey = HouseholdKey(
                  invite.publicKey.length == 32
                      ? invite.publicKey
                      : List.generate(32, (i) => (i + 7) & 0xff),
                );
                try {
                  final channel = ref.read(pairingChannelProvider);
                  final joinRes = await channel.join(invite);
                  if (joinRes.isErr) {
                    if (joinRes.failureOrNull is InviteExpiredFailure &&
                        context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${joinRes.failureOrNull}')),
                      );
                      return;
                    }
                  } else {
                    final session = joinRes.valueOrNull!;
                    sasCode = session.sasCode;
                    if (invite.sealedKey != null) {
                      final confirmRes = await channel.confirm(
                        session,
                        accepted: true,
                      );
                      if (confirmRes.isOk) {
                        householdKey = confirmRes.valueOrNull!;
                      }
                    }
                  }
                } catch (_) {}

                final sharedAreas = <SyncArea>{
                  SyncArea.catalog,
                  SyncArea.home,
                  SyncArea.finance,
                };
                if (invite.sharedAreas != null &&
                    invite.sharedAreas!.isNotEmpty) {
                  sharedAreas
                    ..clear()
                    ..add(SyncArea.catalog);
                  for (final name in invite.sharedAreas!) {
                    for (final area in SyncArea.values) {
                      if (area.name == name) {
                        sharedAreas.add(area);
                      }
                    }
                  }
                }

                if (invite.lanHost != null && invite.lanPort != null) {
                  ref
                      .read(lanSyncTransportProvider)
                      .registerPeer(
                        DiscoveredPeer(
                          siteId: invite.hostSiteId ?? 'host_peer',
                          name: invite.hostDeviceName,
                          address: invite.lanHost!,
                          port: invite.lanPort!,
                        ),
                      );
                }

                if (!context.mounted) return;
                await showDialog<void>(
                  context: context,
                  builder: (previewCtx) => JoinPreviewDialog(
                    key: const Key('join_preview_dialog'),
                    householdId: invite.householdId,
                    householdName: invite.householdName,
                    sharedAreas: sharedAreas,
                    householdKey: householdKey,
                    initialDeviceName: deviceName,
                    sasCode: sasCode,
                    useCase: ref.read(joinHouseholdUseCaseProvider),
                    existingMembers: [
                      if (invite.hostSiteId != null)
                        Member(
                          id: 'mem_${invite.hostSiteId}',
                          householdId: invite.householdId,
                          siteId: invite.hostSiteId!,
                          name:
                              invite.hostDeviceName ??
                              loc.householdHostDeviceFallback,
                          joinedAt: ref.read(clockProvider).nowUtc(),
                          lastSeenAt: ref.read(clockProvider).nowUtc(),
                        ),
                    ],
                    onJoined: () {
                      ref.invalidate(householdStreamProvider);
                      try {
                        ref.read(syncNowUseCaseProvider).execute();
                      } catch (_) {}
                      _maybeShowFirstTimeTutorial();
                    },
                  ),
                );
              },
              child: Text(loc.commonContinue),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _findLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _showInviteDeviceDialog(
    BuildContext context,
    Household household,
  ) async {
    String? ip;
    int? port;
    try {
      final transport = ref.read(lanSyncTransportProvider);
      port = transport.listeningPort;
      ip = await _findLocalIpAddress();
    } catch (_) {
      // LAN transport info is optional when generating a pairing invite.
    }

    Invite? invite;
    try {
      final channel = ref.read(pairingChannelProvider);
      final res = await channel.openInvite(lanHost: ip, lanPort: port);
      if (res.isErr) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('${res.failureOrNull}')));
        }
        return;
      }
      invite = res.valueOrNull;
    } catch (_) {
      if (context.mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.householdInviteGenerateError)),
        );
      }
      return;
    }

    if (invite == null) {
      if (context.mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.householdInviteGenerateError)),
        );
      }
      return;
    }

    final qrData = invite.toQrString();
    final sasCode = invite.sasCode;

    if (!context.mounted) return;
    final loc = AppLocalizations.of(context)!;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          key: const Key('pairing_invite_dialog'),
          title: Text(loc.householdInviteDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.householdInviteDialogPrompt,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.md),
                Container(
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: QrImageView(
                      key: const Key('pairing_qr_image'),
                      data: qrData,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                SelectableText(
                  qrData,
                  key: const Key('pairing_invite_code'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: Spacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      key: const Key('copy_invite_link_button'),
                      icon: const Icon(AppIcons.copy, size: 18),
                      label: Text(loc.householdCopyLinkButton),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: qrData));
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(loc.householdInviteLinkCopied),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: Spacing.xs),
                    TextButton.icon(
                      key: const Key('share_invite_link_button'),
                      icon: const Icon(AppIcons.share, size: 18),
                      label: Text(loc.householdBundleShareAction),
                      onPressed: () async {
                        try {
                          await SharePlus.instance.share(
                            ShareParams(text: qrData),
                          );
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                Text(loc.householdSasCodeLabel),
                Text(
                  sasCode,
                  key: const Key('pairing_sas_code'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.commonClose),
            ),
          ],
        );
      },
    );
  }

  void _showImportBundleDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => const BundleImportDialog(),
    );
  }

  void _confirmRemoveMember(BuildContext context, Member member) {
    final loc = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          key: const Key('confirm_remove_member_dialog'),
          title: Text(loc.householdRemoveMemberDialogTitle(member.name)),
          content: Text(loc.householdRemoveMemberDialogBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.commonCancel),
            ),
            FilledButton(
              key: const Key('confirm_remove_member_button'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  final useCase = ref.read(removeMemberUseCaseProvider);
                  await useCase.execute(memberId: member.id);
                  ref.invalidate(householdMembersStreamProvider);
                } catch (_) {}
              },
              child: Text(loc.householdRemoveMemberConfirm),
            ),
          ],
        );
      },
    );
  }
}

/// Stateful dialog for creating shared household with feedback and error handling (T-B01, RF-120).
class _CreateHouseholdDialog extends ConsumerStatefulWidget {
  final AppLocalizations? l10n;
  final VoidCallback onCreateSuccess;

  const _CreateHouseholdDialog({
    required this.l10n,
    required this.onCreateSuccess,
  });

  @override
  ConsumerState<_CreateHouseholdDialog> createState() =>
      _CreateHouseholdDialogState();
}

class _CreateHouseholdDialogState
    extends ConsumerState<_CreateHouseholdDialog> {
  late final TextEditingController _houseNameController;
  late final TextEditingController _deviceNameController;
  bool _initialized = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _houseNameController = TextEditingController(text: 'Minha Casa');
    _deviceNameController = TextEditingController(text: 'Meu Aparelho');
  }

  @override
  void dispose() {
    _houseNameController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final houseName = _houseNameController.text.trim();
    final deviceName = _deviceNameController.text.trim();

    if (houseName.isEmpty) {
      setState(() => _errorMessage = 'O nome da casa não pode ser vazio.');
      return;
    }
    if (deviceName.isEmpty) {
      setState(() => _errorMessage = 'O nome do aparelho não pode ser vazio.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final useCase = ref.read(createHouseholdUseCaseProvider);
      final result = await useCase.execute(
        householdName: houseName,
        deviceName: deviceName,
        sharedAreas: {SyncArea.catalog, SyncArea.home, SyncArea.finance},
      );

      if (!mounted) return;

      if (result.isErr) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = _formatFailure(result.failureOrNull);
        });
        return;
      }

      Navigator.of(context).pop();
      widget.onCreateSuccess();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Erro inesperado: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: AlertDialog(
        title: Text(widget.l10n?.householdCreateButton ?? 'Criar casa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('household_name_input'),
                controller: _houseNameController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(labelText: 'Nome da casa'),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                key: const Key('device_name_input'),
                controller: _deviceNameController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Nome deste aparelho',
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  _errorMessage!,
                  key: const Key('create_household_error_text'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ],
              if (_isSubmitting) ...[
                const SizedBox(height: Spacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppLoading.spinner(),
                    const SizedBox(width: Spacing.sm),
                    Flexible(
                      child: Text(
                        'Criando casa e preparando dados...',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('cancel_create_household_button'),
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm_create_household_button'),
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: AppLoading.spinner(size: 16),
                  )
                : const Text('Criar'),
          ),
        ],
      ),
    );
  }
}

String _formatFailure(Failure? err) {
  if (err == null) return 'Erro desconhecido.';
  if (err is HouseholdFailure) return err.message;
  if (err is StorageFailure) {
    final detail = err.detail.trim();
    if (detail.contains('/') ||
        detail.contains(r'\') ||
        detail.contains('Exception') ||
        detail.contains('Sqlite')) {
      return 'Não foi possível salvar ou carregar os dados. Tente novamente.';
    }
    return detail.isNotEmpty
        ? detail
        : 'Não foi possível acessar o armazenamento.';
  }
  if (err is ValidationFailure) return err.fields.values.join('; ');
  if (err is NetworkFailure) {
    return err.isOffline
        ? 'Sem conexão com a internet.'
        : 'Falha de comunicação na rede.';
  }
  if (err is PermissionFailure) {
    return 'Permissão necessária: ${err.permission}.';
  }
  if (err is CancelledFailure) return err.reason ?? 'Operação cancelada.';
  return 'Ocorreu um erro inesperado.';
}
