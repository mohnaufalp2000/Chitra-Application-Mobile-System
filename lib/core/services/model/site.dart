// ignore_for_file: public_member_api_docs, sort_constructors_first
class Site {
  String? idSite;
  String? site;
  String? lastUpdate;

  Site({this.idSite, this.site, this.lastUpdate});

  Site.fromJson(Map<String, dynamic> json) {
    idSite = json['id_site'];
    site = json['site'];
    lastUpdate = json['last_update'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id_site'] = this.idSite;
    data['site'] = this.site;
    data['last_update'] = this.lastUpdate;
    return data;
  }

  @override
  String toString() =>
      'Site(idSite: $idSite, site: $site, lastUpdate: $lastUpdate)';
}
