// ignore_for_file: public_member_api_docs, sort_constructors_first
class Site {
  String? idSite;
  String? site;
  String? lastUpdate;
  String? spm;
  String? idCompany;
  String? cts;

  Site(
      {this.idSite,
      this.site,
      this.lastUpdate,
      this.spm,
      this.idCompany,
      this.cts});

  Site.fromJson(Map<String, dynamic> json) {
    idSite = json['id_site'];
    site = json['site'];
    lastUpdate = json['last_update'];
    spm = json['spm'];
    idCompany = json['id_company'];
    cts = json['cts'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id_site'] = this.idSite;
    data['site'] = this.site;
    data['last_update'] = this.lastUpdate;
    data['spm'] = this.spm;
    data['id_company'] = this.idCompany;
    data['cts'] = this.cts;
    return data;
  }

  @override
  String toString() =>
      'Site(idSite: $idSite, site: $site, lastUpdate: $lastUpdate, spm: $spm, idCompany: $idCompany, cts: $cts)';
}
