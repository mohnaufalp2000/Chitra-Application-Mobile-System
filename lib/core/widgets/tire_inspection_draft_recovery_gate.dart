import 'dart:async';
import 'dart:developer';

import 'package:camos/core/services/tire_inspection_draft_service.dart';
import 'package:camos/pages/home/home_state.dart';
import 'package:camos/pages/pressure_gauge_digital/tire_inspection_form_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shows a single recovery prompt after Home is ready following a cold start.
class TireInspectionDraftRecoveryGate extends StatefulWidget {
  const TireInspectionDraftRecoveryGate({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<TireInspectionDraftRecoveryGate> createState() =>
      _TireInspectionDraftRecoveryGateState();
}

class _TireInspectionDraftRecoveryGateState
    extends State<TireInspectionDraftRecoveryGate> {
  static final Set<String> _promptedDraftTokens = <String>{};
  static bool _promptInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_offerDraftRecovery());
    });
  }

  Future<void> _offerDraftRecovery() async {
    if (_promptInProgress) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid.trim().isEmpty) return;

    try {
      final draft =
          await TireInspectionDraftService.instance.loadMostRecentDraft(
        userId: user.uid,
        inspectionDate: DateTime.now(),
      );
      if (draft == null || !mounted) return;

      final token = draft.key.storageToken;
      if (_promptedDraftTokens.contains(token)) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;

      _promptedDraftTokens.add(token);
      _promptInProgress = true;

      final action = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Lanjutkan Tire Inspection?'),
          content: Text(
            'Terdapat draft Tire Inspection unit ${draft.key.unitNumber} '
            'yang belum disimpan. Anda dapat melanjutkan dari isian terakhir.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'later'),
              child: const Text('Nanti'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'discard'),
              child: const Text('Buang'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, 'continue'),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );

      if (action == 'discard') {
        await TireInspectionDraftService.instance.deleteDraft(draft.key);
        return;
      }

      if (action != 'continue' || !mounted) return;

      final homeState = Get.isRegistered<HomeState>()
          ? Get.find<HomeState>()
          : Get.put(HomeState());
      homeState.currentSiteIdRx.value = draft.key.siteId;

      final draftCompanyId =
          draft.navigationData['idCompany']?.toString().trim() ?? '';
      if (draftCompanyId.isNotEmpty) {
        homeState.userAccessCompanyId.value = draftCompanyId;
      }

      final arguments = <String, dynamic>{
        ...draft.navigationData,
        'unitNumber': draft.key.unitNumber,
        'idSite': draft.key.siteId,
        'draftInspectionDate': draft.key.inspectionDate,
        if (draft.hm.isNotEmpty) 'hm': draft.hm,
      };

      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        TireInspectionFormPage.routeName,
        arguments: arguments,
      );
    } catch (e, stackTrace) {
      log(
        'Offer Tire Inspection draft recovery failed: $e',
        stackTrace: stackTrace,
      );
    } finally {
      _promptInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
