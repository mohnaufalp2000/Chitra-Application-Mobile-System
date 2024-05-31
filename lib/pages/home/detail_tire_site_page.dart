import 'dart:developer';

import 'package:camos/core/blocs/site/site_bloc.dart';
import 'package:camos/core/services/model/site.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/pages/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailTireSitePage extends StatefulWidget {
  static const routeName = '/detail-tire-site-page';
  const DetailTireSitePage({super.key});

  @override
  State<DetailTireSitePage> createState() => _DetailTireSitePageState();
}

class _DetailTireSitePageState extends State<DetailTireSitePage> {
  @override
  void initState() {
    context.read<SiteBloc>().add(GetAllSiteEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('Choose Site', context),
      body: SafeArea(
          child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: BlocBuilder<SiteBloc, SiteState>(
                builder: (context, state) {
                  if (state is SiteLoadingState) {
                    return Center(child: CircularProgressIndicator());
                  } else if (state is SiteLoadedState) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 12,
                          ),
                          Column(
                            children: state.listSite.map((site) {
                              final index = state.listSite.indexOf(site);
                              final siteData = state.listSite[index];
                              if (index == 0) {
                                return Container();
                              } else if (index == 1) {
                                return Container();
                              } else if (index == 2) {
                                return Container();
                              } else {
                                return InkWell(
                                  onTap: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();

                                    // prefs.remove('tire_spec');
                                    // prefs.remove('detail_tire_spec');

                                    Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        HomePage.routeName,
                                        (Route<dynamic> route) => route.isFirst,
                                        arguments: {
                                          'idSite': site.idSite,
                                          'siteName': site.site,
                                        });
                                  },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(vertical: 8.0),
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          spreadRadius: 2,
                                          blurRadius: 5,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.front_loader,
                                        color: Colors.orange,
                                      ),
                                      title: Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4.0),
                                        child: Text(
                                          siteData.site ?? '',
                                          style: getBlackTextStyle(
                                              fontWeight: w700),
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Last Update: ${siteData.lastUpdate}',
                                        style: getGreyTextStyle(grey6A707C),
                                      ),
                                      trailing: Icon(Icons.arrow_forward_ios),
                                    ),
                                  ),
                                );
                              }

                              return Container();
                            }).toList(),
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox();
                },
              ))),
    );
  }
}
