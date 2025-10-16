import '../../core/blocs/site/site_bloc.dart';
import '../../core/styles/color.dart';
import '../../core/styles/text_manager.dart';
import '../../core/widgets/appbar_widget.dart';
import '../../core/widgets/custom_error_widget.dart';
import '../../core/widgets/network_checker_widget.dart';
import '../home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class SitePage extends StatefulWidget {
  static const routeName = '/site-page';
  const SitePage({super.key});

  @override
  State<SitePage> createState() => _SitePageState();
}

class _SitePageState extends State<SitePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('Site Page', context),
      body: SafeArea(
          child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  NetworkCheckerWidget(),
                  BlocBuilder<SiteBloc, SiteState>(
                    builder: (context, state) {
                      if (state is SiteLoadingState) {
                        return CircularProgressIndicator();
                      } else if (state is SiteErrorState) {
                        return CustomErrorWidget(
                            errorMessage: state.message,
                            onRefresh: () {
                              context.read<SiteBloc>().add(GetAllSiteEvent());
                            });
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
                                  return InkWell(
                                    onTap: () {
                                      Navigator.pushReplacementNamed(
                                          context, HomePage.routeName,
                                          arguments: {
                                            'idSite': site.idSite,
                                            'siteName': site.site,
                                          });
                                    },
                                    child: Container(
                                      margin:
                                          EdgeInsets.symmetric(vertical: 8.0),
                                      padding:
                                          EdgeInsets.symmetric(vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
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
                                          padding: const EdgeInsets.only(
                                              bottom: 4.0),
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
                  ),
                ],
              ))),
    );
  }
}
