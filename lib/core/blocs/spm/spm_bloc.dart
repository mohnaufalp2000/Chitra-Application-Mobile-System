import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/site.dart';
import 'package:camos/core/utils/data/spm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

part 'spm_event.dart';
part 'spm_state.dart';

class SpmBloc extends Bloc<SpmEvent, SpmState> {
  SpmBloc() : super(SpmInitial()) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    on<GetListSpmEvent>((event, emit) async {
      emit(SpmLoadingState());
      List<Site> allSites = await ApiService.getCachedAllSites();

      if (allSites.isEmpty || allSites == null) {
        allSites = await ApiService.getAllSite();
      }

      final idCompany = allSites
          .firstWhere((site) => site.idSite == event.idSite,
              orElse: () => Site(idSite: '', idCompany: ''))
          .idCompany;

      if (idCompany!.isEmpty) {
        emit(SpmLoadedState(listSpm: [], isShowMore: []));
        return;
      }

      final responseQuery = await firestore
          .collection('url_spm')
          .where('id_company', isEqualTo: idCompany)
          .get();

      final response = responseQuery.docs.first.data()['url'];

      final apiListSpm = await ApiService.getApiSpm(event.idSite, response);
      List<Spm> actualList = apiListSpm;

      List<Spm> list =
          actualList.where((spm) => spm.idSite == event.idSite).toList();

      List<bool> isShowMore = List.generate(list.length, (index) => false);
      emit(SpmLoadedState(listSpm: list, isShowMore: isShowMore));
    });
  }
}
