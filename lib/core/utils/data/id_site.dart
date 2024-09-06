IdSite bmbsitarum = IdSite(nameSite: 'CK-BMB Sitarum', idSite: '52');
IdSite bmbtabuhan = IdSite(nameSite: 'CK-BMB Tabuhan', idSite: '35');
IdSite bmbhauling = IdSite(nameSite: 'CK-BMB Hauling', idSite: '137');

IdSite office = IdSite(nameSite: 'Office,', idSite: '1');
IdSite ck = IdSite(nameSite: 'All-CK,', idSite: '2');
IdSite pama = IdSite(nameSite: 'PAMA,', idSite: '3');

class IdSite {
  final String nameSite;
  final String idSite;

  IdSite({required this.nameSite, required this.idSite});
}
