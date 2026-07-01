// -- NEW HOME PAGE -- //

import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/site.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/utils/data/menu.dart';
import 'package:camos/core/widgets/contact_developer_widget.dart';
import 'package:camos/objectbox.g.dart';
import 'package:camos/pages/admin/admin_page.dart';
import 'package:camos/pages/authentication/login_page.dart';
import 'package:camos/pages/home/home_state.dart';
import 'package:camos/pages/home/widget/home_function.dart';
import 'package:camos/pages/home/widget/tire_condition_card_widget.dart';
import 'package:camos/pages/network/network_state.dart';
import 'package:camos/pages/settings/settings_page.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/shared_preferences/shared_preferences.dart';
import '../../core/styles/color.dart';
import '../../core/styles/text_manager.dart';
import '../../core/utils/data/id_site.dart';
import '../../core/widgets/box_tire_widget.dart';
import '../../core/widgets/button_widget.dart';
import '../../core/widgets/custom_error_widget.dart';
import '../tire_condition/tire_condition_page.dart';
import '../tire_inventory/tire_inventory_page.dart';
import 'package:http/http.dart' as http;

class HomePage extends GetView<HomeState> {
  static const routeName = '/home_page';
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeState controller = Get.find<HomeState>();

    return Scaffold(
      // backgroundColor: Color.fromARGB(255, 39, 194, 135),
      // Karena ini StatelessWidget, WillPopScope harus di luar.
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Obx(() {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () async {},
                          child: CircleAvatar(
                            backgroundImage: (controller.user['image'] == '' ||
                                    controller.user['image'] == null ||
                                    controller.user['image'] == 'image')
                                ? AssetImage(
                                        '$imagePath/default_user_image.png')
                                    as ImageProvider
                                : NetworkImage(controller.user['image']),
                            backgroundColor: Colors.grey.withOpacity(0.4),
                            radius: 30,
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good ${controller.greeting()}',
                              style: getBlackTextStyle(fontSize: 12),
                            ),
                            Text(controller.user['username'] ?? 'Username',
                                style: getBlackTextStyle(
                                    fontSize: 14, fontWeight: w700)),
                            // -- VERSION APP NUMBER
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('Version ' + controller.versionNumber,
                                  style: getBlackTextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ).copyWith(
                                      letterSpacing: 0.5,
                                      color: Colors.black54)),
                            ),
                          ],
                        ),
                        Spacer(),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                    context, SettingsPage.routeName);
                              },
                              child: Container(
                                  margin: EdgeInsets.only(right: 12),
                                  child: const Icon(
                                    LucideIcons.settings,
                                    color: Colors.grey,
                                  )),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            InkWell(
                              onTap: () {
                                HomeFunction.showLogoutConfirmation(
                                  context: context,
                                  onLogout: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.clear();
                                    Get.deleteAll(force: true);
                                    Get.put(InternetState());
                                    Get.offAllNamed(LoginPage.routeName);
                                  },
                                );
                              },
                              child: Container(
                                  margin: EdgeInsets.only(right: 12),
                                  child: const Icon(
                                    LucideIcons.logOut,
                                    color: Colors.red,
                                  )),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),
                  ContactDeveloperWidget(),
                  const SizedBox(
                    height: 12,
                  ),
                  // CAMOS Administrator
                  (controller.userAccessCompanyId.value == '1')
                      ? Container(
                          height: 55,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pushNamed(context, AdminPage.routeName);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFF8F1E7), // cream background
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: const BorderSide(
                                  color: Color(0xFFE6C79C), // border color
                                  width: 1.5,
                                ),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_circle,
                                  color: Color(0xFFD98A2B),
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "CAMOS Administrator",
                                  style: getWhiteTextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ).copyWith(
                                    color: const Color(0xFFD98A2B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(),
                  // --- PENGGANTIAN SITE DROPDOWN ---

                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Site',
                                style: getBlackTextStyle(
                                  fontSize: 14,
                                  fontWeight: w700,
                                ),
                              ),
                              Obx(() {
                                // if (controller.siteError.isNotEmpty) {
                                //   return CustomErrorWidget(
                                //     errorMessage: controller.siteError.value,
                                //     onRefresh: controller.fetchSites,
                                //   );
                                // }

                                // if (controller.isSiteLoading.isTrue) {
                                //   return const Padding(
                                //     padding: EdgeInsets.symmetric(vertical: 8),
                                //     child: Center(
                                //       child: SizedBox(
                                //         width: 20,
                                //         height: 20,
                                //         child: CircularProgressIndicator(
                                //             strokeWidth: 2),
                                //       ),
                                //     ),
                                //   );
                                // }

                                // === USER OFFICE ===
                                if (controller.isUserOffice &&
                                    controller.userAccessCompanyId.value ==
                                        '') {
                                  print('apakah berasal dari user office');
                                  // final List<Site> displayList =
                                  //     controller.listSite.length > 4
                                  //         ? controller.listSite.sublist(4)
                                  //         : controller.listSite;
                                  final List<Site> displayList =
                                      controller.listSite;
                                  final selectedSite =
                                      displayList.firstWhereOrNull(
                                    (s) => s.idSite == controller.currentSiteId,
                                  );

                                  return DropdownButton<String>(
                                    isExpanded: true,
                                    isDense: true,
                                    value: selectedSite?.idSite,
                                    hint: Text(
                                      'Choose Site',
                                      style: getGreenTextStyle(
                                          fontWeight: w700, fontSize: 16),
                                    ),
                                    style: getGreenTextStyle(
                                        fontWeight: w700, fontSize: 16),
                                    underline: Container(),
                                    items: displayList.map((site) {
                                      return DropdownMenuItem<String>(
                                        value: site.idSite,
                                        child: Text(site.site ?? ''),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      print('newValue : $newValue');
                                      if (newValue != null) {
                                        controller.fetchAllHomeData(
                                            idSite: newValue);
                                      }
                                    },
                                  );
                                }

                                // === USER NON-OFFICE DENGAN CLUSTER ===
                                final clusterSites = controller.clusterSites;

                                if (clusterSites.isEmpty) {
                                  // fallback jika user di luar cluster
                                  final onlySite = controller.listSite
                                      .firstWhereOrNull((s) =>
                                          s.idSite ==
                                          controller.userAccessId.value);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      onlySite?.site ?? '-',
                                      style: getGreenTextStyle(
                                          fontWeight: w700, fontSize: 16),
                                    ),
                                  );
                                }

                                // Kalau hanya 1 site di cluster → tampilkan text
                                if (clusterSites.length == 1) {
                                  final site = clusterSites.first;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      site.nameSite ?? '',
                                      style: getGreenTextStyle(
                                          fontWeight: w700, fontSize: 16),
                                    ),
                                  );
                                }

                                // Kalau lebih dari 1 site → tampilkan dropdown cluster
                                final selectedClusterSite =
                                    clusterSites.firstWhereOrNull(
                                  (s) => s.idSite == controller.currentSiteId,
                                );

                                return DropdownButton<String>(
                                  isExpanded: true,
                                  isDense: true,
                                  value: selectedClusterSite?.idSite ??
                                      controller.userAccessId.value,
                                  hint: Text(
                                    'Choose Site (${controller.clusterName})',
                                    style: getGreenTextStyle(
                                        fontWeight: w700, fontSize: 16),
                                  ),
                                  style: getGreenTextStyle(
                                      fontWeight: w700, fontSize: 16),
                                  underline: Container(),
                                  items: clusterSites.map((site) {
                                    return DropdownMenuItem<String>(
                                      value: site.idSite,
                                      child: Text(site.nameSite),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    print('newValue non-office: $newValue');

                                    if (newValue != null) {
                                      controller.fetchAllHomeData(
                                          idSite: newValue);
                                    }
                                  },
                                );
                              })
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // -- Tire Inventory -- //
                  (controller.shouldShowSiteWarning)
                      ? Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.orange, size: 60),
                                SizedBox(height: 12),
                                Text(
                                  'Site has not been selected.\nPlease select a site first.',
                                  textAlign: TextAlign.center,
                                  style: getBlackTextStyle(
                                    fontSize: 16,
                                    fontWeight: w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Obx(() {
                              if (controller.isInventLoading.value) {
                                return SizedBox(
                                  height: 150,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // 🔥 Loading animation modern
                                        LoadingAnimationWidget
                                            .staggeredDotsWave(
                                          color: Colors.redAccent,
                                          size: 50,
                                        ),
                                        const SizedBox(height: 10),
                                        // 🧮 Persentase loading
                                        Obx(() => Text(
                                              '${controller.inventLoadingPercent.value.toStringAsFixed(0)}%',
                                              style: const TextStyle(
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            )),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              if (controller.hasInventError.value) {
                                return HomeFunction.buildInlineError(
                                  message: controller.inventErrorMessage.value,
                                  onRetry: () => controller.retryFetch(
                                    type: 'inventory',
                                    idSite: controller.currentSiteId,
                                  ),
                                );
                              }

                              if (controller.tireInventData.isEmpty) {
                                return const SizedBox(
                                  height: 150,
                                  child: Center(
                                    child: Text(
                                      'No data available.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: [
                                  (controller.lastSyncInvent.value != '' ||
                                          controller
                                              .lastSyncInvent.value.isNotEmpty)
                                      ? Container(
                                          margin: EdgeInsets.only(
                                              right: 12, bottom: 6),
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            controller.lastSyncInvent.value,
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: controller
                                                      .lastSyncInvent.value
                                                      .contains('Offline')
                                                  ? Colors.orange
                                                  : Colors.green,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        )
                                      : Container(),
                                  SizedBox(
                                    height: 90, // 🔹 diperkecil dari 150 ke 90
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      itemCount:
                                          controller.tireInventData.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 10),
                                      itemBuilder: (context, index) {
                                        final item =
                                            controller.tireInventData[index];
                                        final status = item['status'] ?? '';
                                        final total =
                                            item['total']?.toString() ?? '0';

                                        // Warna & ikon
                                        final gradientColors =
                                            HomeFunction.getGradientColors(
                                                status);
                                        final icon =
                                            HomeFunction.getIconByStatus(
                                                status);

                                        // Judul
                                        final title = (status == 'Scrap')
                                            ? 'Lifetime Scrap'
                                            : '$status Tire'
                                                '${status == 'Repair' ? '\nProgress' : '\nStock'}';
                                        final value = (status == 'Scrap')
                                            ? total.split('|')[0]
                                            : '$total Pcs';

                                        return InkWell(
                                          onTap: () {
                                            controller.setInventorySelection(
                                              status: status,
                                              idSite: controller.currentSiteId,
                                              total: total,
                                            );
                                            Navigator.pushNamed(
                                              context,
                                              TireInventoryPage.routeName,
                                            );
                                          },
                                          child: Container(
                                            width: 160,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              gradient: LinearGradient(
                                                colors: gradientColors,
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                // 🔹 Icon di kiri
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(icon,
                                                      color: Colors.white,
                                                      size: 24),
                                                ),
                                                const SizedBox(width: 10),

                                                // 🔹 Text di kanan
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        title,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        value,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }),

                            // -- TIRE CONDITION -- /
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 6,
                                ),
                                TireConditionCardWidget(),
                              ],
                            ),
                          ],
                        ),

                  // -- QUICK ACTION -- //
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(
                          0xFFF3F5F9), // background lembut seperti Gojek
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(2, 4),
                        ),
                        const BoxShadow(
                          color: Colors.white,
                          offset: Offset(-2, -2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        // Baris pertama
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            HomeFunction.buildMenuItem(menus[0], context,
                                controller.currentSiteCompanyId),
                            HomeFunction.buildMenuItem(menus[1], context,
                                controller.currentSiteCompanyId),
                            HomeFunction.buildMenuItem(menus[2], context,
                                controller.currentSiteCompanyId),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Baris kedua
                        Row(
                          mainAxisAlignment:
                              (controller.userAccessCompanyId.value == '1')
                                  ? MainAxisAlignment.center
                                  : MainAxisAlignment.spaceEvenly,
                          children: [
                            HomeFunction.buildMenuItem(menus[3], context,
                                controller.userAccessCompanyId.value),
                            (controller.userAccessCompanyId.value == '1')
                                ? Container(
                                    width: 30,
                                  )
                                : HomeFunction.buildMenuItem(menus[4], context,
                                    controller.userAccessCompanyId.value),
                            HomeFunction.buildMenuItem(menus[5], context,
                                controller.userAccessCompanyId.value)
                          ],
                        ),
                      ],
                    ),
                  ),

                  // // --- LOGIKA CLUSTER LAMA (Menggunakan ID Site dari Controller) ---

                  // if (!isUserOffice)
                  //   Obx(() {
                  //     // Logika Cluster BMB
                  //     if (activeId == bmbsitarum.idSite ||
                  //         activeId == bmbtabuhan.idSite ||
                  //         activeId == bmbhauling.idSite) {
                  //       final listBmbSite = [
                  //         bmbsitarum,
                  //         bmbtabuhan,
                  //         bmbhauling
                  //       ];

                  //       // Ambil site yang sedang aktif (activeId)
                  //       final selectedSite = listBmbSite
                  //           .firstWhereOrNull((s) => s.idSite == activeId);

                  //       return DropdownButton<String>(
                  //         isExpanded: true,
                  //         padding: const EdgeInsets.symmetric(horizontal: 24),
                  //         // 🚀 Gunakan activeId dari Controller
                  //         value: selectedSite?.idSite,
                  //         hint: const Text('Choose Site'),
                  //         items: listBmbSite.map((site) {
                  //           return DropdownMenuItem<String>(
                  //             value: site.idSite,
                  //             child: Text(site.nameSite),
                  //           );
                  //         }).toList(),
                  //         onChanged: (newValue) {
                  //           if (newValue != null) {
                  //             // 🚀 Panggil fungsi global untuk update state
                  //             // Ini akan memperbarui currentSiteIdRx di controller dan memicu fetch data ban.
                  //             controller.fetchAllHomeData(idSite: newValue);
                  //             saveIdSitePreferences(
                  //                 newValue); // Pertahankan penyimpanan lokal
                  //           }
                  //         },
                  //       );
                  //     }

                  //     // Logika Cluster BIB
                  //     if (activeId == bibkgb.idSite ||
                  //         activeId == bibgh.idSite ||
                  //         activeId == bibghhauling.idSite) {
                  //       final listBIBSite = [
                  //         bibkgb,
                  //         bibgh,
                  //         bibkgbhauling,
                  //         bibghhauling
                  //       ];

                  //       final selectedSite = listBIBSite
                  //           .firstWhereOrNull((s) => s.idSite == activeId);

                  //       return DropdownButton<String>(
                  //         isExpanded: true,
                  //         padding: const EdgeInsets.symmetric(horizontal: 24),
                  //         // 🚀 Gunakan currentId dari Controller
                  //         value: selectedSite?.idSite,
                  //         hint: const Text('Choose Site'),
                  //         items: listBIBSite.map((site) {
                  //           return DropdownMenuItem<String>(
                  //             value: site.idSite,
                  //             child: Text(site.nameSite),
                  //           );
                  //         }).toList(),
                  //         onChanged: (newValue) {
                  //           if (newValue != null) {
                  //             // 🚀 Panggil fungsi global untuk update state
                  //             controller.fetchAllHomeData(idSite: newValue);
                  //             saveIdSitePreferences(
                  //                 newValue); // Pertahankan penyimpanan lokal
                  //           }
                  //         },
                  //       );
                  //     }

                  //     // Logika Cluster MHU
                  //     if (activeId == mhumining.idSite ||
                  //         activeId == mhuhauling.idSite) {
                  //       final listMHUSite = [
                  //         mhumining,
                  //         mhuhauling,
                  //       ];

                  //       final selectedSite = listMHUSite
                  //           .firstWhereOrNull((s) => s.idSite == activeId);

                  //       return DropdownButton<String>(
                  //         isExpanded: true,
                  //         padding: const EdgeInsets.symmetric(horizontal: 24),
                  //         // 🚀 Gunakan currentId dari Controller
                  //         value: selectedSite?.idSite,
                  //         hint: const Text('Choose Site'),
                  //         items: listMHUSite.map((site) {
                  //           return DropdownMenuItem<String>(
                  //             value: site.idSite,
                  //             child: Text(site.nameSite),
                  //           );
                  //         }).toList(),
                  //         onChanged: (newValue) {
                  //           if (newValue != null) {
                  //             // 🚀 Panggil fungsi global untuk update state
                  //             controller.fetchAllHomeData(idSite: newValue);
                  //             saveIdSitePreferences(
                  //                 newValue); // Pertahankan penyimpanan lokal
                  //           }
                  //         },
                  //       );
                  //     }

                  //     // Default jika bukan Office/All-CK dan bukan Cluster yang diketahui.
                  //     return Container();
                  //   }),

                  // // 🚀 BAGIAN 1: TIRE INVENTORY CARD
                  // Obx(() {
                  //   if (controller.inventErrorMessage.isNotEmpty) {
                  //     return CustomErrorWidget(
                  //         errorMessage: controller.inventErrorMessage.value,
                  //         onRefresh: () =>
                  //             controller.fetchTireInventory(activeId));
                  //   }

                  //   if (controller.isInventLoading.isTrue) {
                  //     return const Center(child: CircularProgressIndicator());
                  //   }

                  //   if (controller.tireInventData.isNotEmpty &&
                  //       isActiveSiteRegular) {
                  //     final siteNameDisplay =
                  //         controller.siteName; // 🚀 Gunakan getter siteName

                  //     return Column(
                  //       children: [
                  //         // Header Site Name
                  //         Container(
                  //           width: double.infinity,
                  //           padding: const EdgeInsets.all(12),
                  //           color: Colors.grey.withOpacity(0.1),
                  //           child: Row(
                  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //             children: [
                  //               Column(
                  //                 crossAxisAlignment: CrossAxisAlignment.start,
                  //                 children: [
                  //                   const Text('Site',
                  //                       style: TextStyle(
                  //                           fontSize: 20,
                  //                           fontWeight: FontWeight.w700)),
                  //                   Text(siteNameDisplay,
                  //                       style: getGreenTextStyle(
                  //                           fontSize: 16, fontWeight: w700)),
                  //                 ],
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //         const SizedBox(height: 12),
                  //         // Card Tire Inventory Content
                  //         Padding(
                  //           padding: const EdgeInsets.symmetric(horizontal: 12),
                  //           child: Container(
                  //             padding: const EdgeInsets.all(12),
                  //             decoration: BoxDecoration(
                  //               gradient: const LinearGradient(
                  //                   colors: [green00968A, blue344BEF]),
                  //               borderRadius: BorderRadius.circular(12),
                  //             ),
                  //             child: Row(
                  //               mainAxisAlignment:
                  //                   MainAxisAlignment.spaceBetween,
                  //               children: controller.tireInventData.map((tire) {
                  //                 final index =
                  //                     controller.tireInventData.indexOf(tire);
                  //                 return InkWell(
                  //                   onTap: () {
                  //                     final statusList = controller.statusList;
                  //                     Navigator.pushNamed(
                  //                       context,
                  //                       TireInventoryPage.routeName,
                  //                       arguments: {
                  //                         'idSite': activeId,
                  //                         'status': statusList[index],
                  //                         'total': (tire['status'] == 'Scrap')
                  //                             ? tire['total'].split('|')[1]
                  //                             : tire['total'],
                  //                       },
                  //                     );
                  //                   },
                  //                   child: BoxTireWidget(tire: tire),
                  //                 );
                  //               }).toList(),
                  //             ),
                  //           ),
                  //         ),
                  //       ],
                  //     );
                  //   }
                  //   return Container();
                  // }),

                  // const SizedBox(height: 12),

                  // // 🚀 BAGIAN 2: TIRE CONDITION CARD
                  // Obx(() {
                  //   if (controller.isConditionLoading.isTrue) {
                  //     return const Center(child: CircularProgressIndicator());
                  //   }

                  //   if (controller.conditionErrorMessage.isNotEmpty) {
                  //     return CustomErrorWidget(
                  //         errorMessage: controller.conditionErrorMessage.value,
                  //         onRefresh: () =>
                  //             controller.fetchTireCondition(activeId));
                  //   }

                  //   if (controller.mapRating.isNotEmpty &&
                  //       isActiveSiteRegular) {
                  //     final mapRating = controller.mapRating;

                  //     return Padding(
                  //       padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  //       child: Card(
                  //         elevation: 2,
                  //         shape: RoundedRectangleBorder(
                  //             borderRadius: BorderRadius.circular(12)),
                  //         child: Container(
                  //           padding: const EdgeInsets.all(12),
                  //           width: double.infinity,
                  //           decoration: BoxDecoration(
                  //               gradient: const LinearGradient(
                  //                   colors: [green00968A, blue344BEF]),
                  //               borderRadius: BorderRadius.circular(12)),
                  //           child: Column(
                  //             children: [
                  //               Text('Tire Running Condition',
                  //                   style: getWhiteTextStyle(fontWeight: w700)),
                  //               const SizedBox(height: 12),
                  //               Row(
                  //                 mainAxisAlignment:
                  //                     MainAxisAlignment.spaceBetween,
                  //                 children: mapRating.entries.map((rating) {
                  //                   return Card(
                  //                     // ... (UI Rating A, B, C, X)
                  //                     child: Container(
                  //                       // ...
                  //                       child: Column(
                  //                         children: [
                  //                           Text('Rating ${rating.key}'),
                  //                           Text(rating.value.toString()),
                  //                         ],
                  //                       ),
                  //                     ),
                  //                   );
                  //                 }).toList(),
                  //               ),
                  //               const SizedBox(height: 12),
                  //               SizedBox(
                  //                 width: double.infinity,
                  //                 child: ButtonWidget(
                  //                     name: Text('Detail',
                  //                         style: getWhiteTextStyle(
                  //                             fontWeight: w700)),
                  //                     function: () {
                  //                       Navigator.pushNamed(context,
                  //                           TireConditionPage.routeName);
                  //                     }),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //     );
                  //   }
                  //   return Container();
                  // }),

                  const SizedBox(height: 24),
                ],
              );
            }),
          ),
        ),
      ),

      // NOTE: BottomNavigationBar dan logika navigasi di sini
      // masih perlu disesuaikan karena HomePage kini StatelessWidget
      // dan tidak memiliki _selectedIndex.
    );
  }
}
