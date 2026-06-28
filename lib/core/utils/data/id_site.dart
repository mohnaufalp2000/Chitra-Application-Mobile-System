import 'package:cloud_firestore/cloud_firestore.dart';

IdSite officeChitra = IdSite(nameSite: 'Office', idSite: 'officeChitra');
IdSite allCK = IdSite(nameSite: 'All-CK', idSite: 'allCK');

// ID Site Lama
// IdSite admoMining =
//     IdSite(nameSite: 'ADMO Mining', idSite: '1', idCompany: '1');
// IdSite admoHauling =
//     IdSite(nameSite: 'ADMO Hauling', idSite: '2', idCompany: '1');
// IdSite seraMining =
//     IdSite(nameSite: 'SERA Mining', idSite: '3', idCompany: '1');
// IdSite macoMining =
//     IdSite(nameSite: 'MACO Mining', idSite: '4', idCompany: '1');

Future<List<IdSite>> getIdSiteSIS() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('id_sis')
      .where('id_company', isEqualTo: '1')
      .get();

  final sites = snapshot.docs.map((doc) {
    return IdSite.fromFirestore(doc.data());
  }).toList();

  return sites.where((site) {
    return site.nameSite == 'ADMO Hauling' ||
        site.nameSite == 'ADMO Training' ||
        site.nameSite == 'SERA Mining' ||
        site.nameSite == 'MACO Mining';
  }).toList();
}

IdSite bmbsitarum = IdSite(nameSite: 'CK-BMB Sitarum', idSite: '52');
IdSite bmbtabuhan = IdSite(nameSite: 'CK-BMB Tabuhan', idSite: '35');
IdSite bmbhauling = IdSite(nameSite: 'CK-BMB Hauling', idSite: '137');
IdSite bibkgb = IdSite(nameSite: 'CK-BIB KGB', idSite: '65');
IdSite bibgh = IdSite(nameSite: 'CK-BIB GH', idSite: '166');
IdSite bibkgbhauling = IdSite(nameSite: 'CK-BIB KGB HAULING', idSite: '174');
IdSite bibghhauling = IdSite(nameSite: 'CK-BIB GH HAULING', idSite: '172');
IdSite mhumining = IdSite(nameSite: 'CK-MHU MINING', idSite: '32');
IdSite mhuhauling = IdSite(nameSite: 'CK-MHU HAULING', idSite: '130');
IdSite amn = IdSite(nameSite: 'AMN', idSite: '230');

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

final List<IdSite> allSites = [
  officeChitra,
  allCK,
  bmbsitarum,
  bmbtabuhan,
  bmbhauling,
  bibkgb,
  bibgh,
  bibkgbhauling,
  bibghhauling,
  mhumining,
  mhuhauling,
  amn,
  office,
  ck,
  pama,
];

IdSite office = IdSite(nameSite: 'Office,', idSite: 'officeChitra');
IdSite ck = IdSite(nameSite: 'All-CK,', idSite: '2');
IdSite pama = IdSite(nameSite: 'PAMA,', idSite: '3');

class IdSite {
  final String nameSite;
  final String idSite;
  String idCompany;

  IdSite({required this.nameSite, required this.idSite, this.idCompany = '0'});

  factory IdSite.fromFirestore(Map<String, dynamic> data) {
    return IdSite(
      nameSite: data['site'] ?? '',
      idSite: data['id_site']?.toString() ?? '',
      idCompany: data['id_company']?.toString() ?? '0',
    );
  }
}

Future<List<IdSite>> getSitesFromFirebase() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('id_sis')
      .where('id_company', isEqualTo: '1')
      .get();

  return snapshot.docs.map((doc) {
    return IdSite.fromFirestore(doc.data());
  }).toList();
}
