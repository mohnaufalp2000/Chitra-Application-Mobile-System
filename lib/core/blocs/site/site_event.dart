// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'site_bloc.dart';

@immutable
abstract class SiteEvent {}

class GetAllSiteEvent extends SiteEvent {}

class GetSiteEvent extends SiteEvent {
  final String idSite;
  GetSiteEvent({
    required this.idSite,
  });
}
