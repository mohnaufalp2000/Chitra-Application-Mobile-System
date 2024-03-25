import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/site.dart';
import 'package:meta/meta.dart';

part 'site_event.dart';
part 'site_state.dart';

class SiteBloc extends Bloc<SiteEvent, SiteState> {
  SiteBloc() : super(SiteInitial()) {
    on<GetAllSiteEvent>((event, emit) async {
      try {
        emit(SiteLoadingState());
        final listSite = await ApiService.getAllSite();
        listSite.sort((a, b) {
          return a.site!.toLowerCase().compareTo(b.site!.toLowerCase());
        });
        listSite.insert(
          0,
          Site(idSite: '1', site: 'Office', lastUpdate: '2023-10-16'),
        );
        listSite.insert(
          1,
          Site(idSite: '2', site: 'All-CK', lastUpdate: '2023-10-16'),
        );
        emit(SiteLoadedState(listSite: listSite));
      } catch (e) {
        emit(SiteErrorState(message: e.toString()));
      }
    });
    on<GetSiteEvent>((event, emit) async {
      try {
        emit(SiteLoadingState());
        final site = await ApiService.getSite(event.idSite);
        emit(SiteOneLoadedState(site: site));
      } catch (e) {
        emit(SiteErrorState(message: e.toString()));
      }
    });
  }
}
