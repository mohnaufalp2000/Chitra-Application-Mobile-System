// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'site_bloc.dart';

@immutable
abstract class SiteState {}

class SiteInitial extends SiteState {}

class SiteLoadingState extends SiteState {}

class SiteLoadedState extends SiteState {
  final List<Site> listSite;
  SiteLoadedState({
    required this.listSite,
  });
}

class SiteOneLoadedState extends SiteState {
  final Site site;
  SiteOneLoadedState({
    required this.site,
  });
}

class SiteErrorState extends SiteState {
  final String message;
  SiteErrorState({
    required this.message,
  });
}
