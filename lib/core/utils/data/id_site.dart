IdSite bmbsitarum = IdSite(nameSite: 'CK-BMB Sitarum', idSite: '52');
IdSite bmbtabuhan = IdSite(nameSite: 'CK-BMB Tabuhan', idSite: '35');
IdSite bmbhauling = IdSite(nameSite: 'CK-BMB Hauling', idSite: '137');
IdSite bibkgb = IdSite(nameSite: 'CK-BIB KGB', idSite: '65');
IdSite bibgh = IdSite(nameSite: 'CK-BIB GH', idSite: '166');
IdSite bibkgbhauling = IdSite(nameSite: 'CK-BIB KGB HAULING', idSite: '174');
IdSite bibghhauling = IdSite(nameSite: 'CK-BIB GH HAULING', idSite: '172');
IdSite mhumining = IdSite(nameSite: 'CK-MHU MINING', idSite: '32');
IdSite mhuhauling = IdSite(nameSite: 'CK-MHU HAULING', idSite: '130');

final List<IdSite> bmbSites = [
  IdSite(nameSite: 'CK-BMB Sitarum', idSite: '52'),
  IdSite(nameSite: 'CK-BMB Tabuhan', idSite: '35'),
  IdSite(nameSite: 'CK-BMB Hauling', idSite: '137'),
];

final List<IdSite> bibSites = [
  IdSite(nameSite: 'CK-BIB KGB', idSite: '65'),
  IdSite(nameSite: 'CK-BIB GH', idSite: '166'),
  IdSite(nameSite: 'CK-BIB KGB HAULING', idSite: '174'),
  IdSite(nameSite: 'CK-BIB GH HAULING', idSite: '172'),
];

final List<IdSite> mhuSites = [
  IdSite(nameSite: 'CK-MHU MINING', idSite: '32'),
  IdSite(nameSite: 'CK-MHU HAULING', idSite: '130'),
];

IdSite office = IdSite(nameSite: 'Office,', idSite: '1');
IdSite ck = IdSite(nameSite: 'All-CK,', idSite: '2');
IdSite pama = IdSite(nameSite: 'PAMA,', idSite: '3');

class IdSite {
  final String nameSite;
  final String idSite;

  IdSite({required this.nameSite, required this.idSite});
}
