import 'dart:developer';

import '../../core/blocs/detail_tire_condition/detail_tire_condition_bloc.dart';
import '../../core/blocs/site/site_bloc.dart';
import '../../core/blocs/tire_condition/tire_condition_bloc.dart';
import '../../core/services/shared_preferences/shared_preferences.dart';
import '../../core/styles/color.dart';
import '../../core/styles/text_manager.dart';
import '../../core/widgets/appbar_widget.dart';
import '../../core/widgets/button_widget.dart';
import '../../core/widgets/text_button_widget.dart';
import 'detail_tire_condition_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TireConditionPage extends StatefulWidget {
  static const routeName = '/tire-condition-page';
  const TireConditionPage({super.key});

  @override
  State<TireConditionPage> createState() => _TireConditionPageState();
}

class _TireConditionPageState extends State<TireConditionPage> {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String idSite = '';

  @override
  void initState() {
    super.initState();
    // callTires();
    callSite();
  }

  void callTires() async {
    String id = await getIdSitePreferences();
    context.read<TireConditionBloc>().add(GetTireConditionEvent(idSite: id));
  }

  void callSite() async {
    String id = await getSelectedIdSitePreferences();
    log('id site conditon :$id');
    idSite = id;
    context.read<SiteBloc>().add(GetSiteEvent(idSite: id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('Tire Running Condition', context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                BlocBuilder<TireConditionBloc, TireConditionState>(
                  builder: (context, state) {
                    if (state is TireConditionLoadingState) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (state is TireConditionLoadedState) {
                      List<Map<String, dynamic>> tires = state.listSize;

                      return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: tires.length,
                          itemBuilder: (context, index) {
                            log('ban running : $tires');

                            List<String> value =
                                (tires[index].values.first as List<dynamic>)
                                    .cast<String>();

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    green00968A,
                                    blue344BEF,
                                  ]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Tire of ${tires[index].keys.first}',
                                      style: getWhiteTextStyle(
                                          fontWeight: w700, fontSize: 20),
                                    ),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Card(
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.17,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.1,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                LayoutBuilder(builder:
                                                    (context, constraints) {
                                                  double fontSize =
                                                      constraints.maxWidth *
                                                          0.2;
                                                  return Text(
                                                    'Rating A',
                                                    style: getBlackTextStyle(
                                                        fontWeight: w700,
                                                        fontSize: fontSize),
                                                  );
                                                }),
                                                const SizedBox(
                                                  height: 12,
                                                ),
                                                Text(
                                                  '${value.where((element) => element == 'A').length}',
                                                  textAlign: TextAlign.center,
                                                  style: getBlackTextStyle(
                                                    fontSize: 10,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        Card(
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.17,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.1,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                LayoutBuilder(builder:
                                                    (context, constraints) {
                                                  double fontSize =
                                                      constraints.maxWidth *
                                                          0.2;
                                                  return Text(
                                                    'Rating B',
                                                    style: getBlackTextStyle(
                                                        fontWeight: w700,
                                                        fontSize: fontSize),
                                                  );
                                                }),
                                                const SizedBox(
                                                  height: 12,
                                                ),
                                                Text(
                                                  '${value.where((element) => element == 'B').length}',
                                                  textAlign: TextAlign.center,
                                                  style: getBlackTextStyle(
                                                    fontSize: 10,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        Card(
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.17,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.1,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                LayoutBuilder(builder:
                                                    (context, constraints) {
                                                  double fontSize =
                                                      constraints.maxWidth *
                                                          0.2;
                                                  return Text(
                                                    'Rating C',
                                                    style: getBlackTextStyle(
                                                        fontWeight: w700,
                                                        fontSize: fontSize),
                                                  );
                                                }),
                                                const SizedBox(
                                                  height: 12,
                                                ),
                                                Text(
                                                  '${value.where((element) => element == 'C').length}',
                                                  textAlign: TextAlign.center,
                                                  style: getBlackTextStyle(
                                                    fontSize: 10,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        Card(
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.17,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.1,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                LayoutBuilder(builder:
                                                    (context, constraints) {
                                                  double fontSize =
                                                      constraints.maxWidth *
                                                          0.2;
                                                  return Text(
                                                    'Rating X',
                                                    style: getBlackTextStyle(
                                                        fontWeight: w700,
                                                        fontSize: fontSize),
                                                  );
                                                }),
                                                const SizedBox(
                                                  height: 12,
                                                ),
                                                Text(
                                                  '${value.where((element) => element == 'X').length}',
                                                  textAlign: TextAlign.center,
                                                  style: getBlackTextStyle(
                                                    fontSize: 10,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 12,
                                    ),

                                    SizedBox(
                                        width: double.infinity,
                                        child: ButtonWidget(
                                            name: Text(
                                              'Detail',
                                              style: getWhiteTextStyle(),
                                            ),
                                            function: () {
                                              Navigator.pushNamed(
                                                  context,
                                                  DetailTireConditionPage
                                                      .routeName,
                                                  arguments: {
                                                    'idSite': idSite,
                                                    'data':
                                                        tires[index].keys.first,
                                                  });
                                            })),
                                    // SizedBox(
                                    //   height: 45,
                                    //   child: ButtonWidget(
                                    //       name: Row(
                                    //         mainAxisAlignment:
                                    //             MainAxisAlignment.spaceBetween,
                                    //         children: [
                                    //           InkWell(
                                    //             onTap: () {},
                                    //             child: Text(
                                    //               'Detail',
                                    //               style: getWhiteTextStyle(),
                                    //             ),
                                    //           ),
                                    //           Icon(
                                    //             Icons.arrow_forward_ios,
                                    //             size: 12,
                                    //           ),
                                    //         ],
                                    //       ),
                                    //       function: () {}),
                                    // ),
                                  ],
                                ),
                              ),
                            );
                          });

                      // return Column(
                      //   children: [
                      //     Card(
                      //       elevation: 2,
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //       child: Container(
                      //         width: double.infinity,
                      //         padding: EdgeInsets.all(12),
                      //         child: Column(
                      //           children: [
                      //             Text(
                      //               'Tire of 20.5R25',
                      //               style: getBlackTextStyle(fontWeight: w700),
                      //             ),
                      //             const SizedBox(
                      //               height: 12,
                      //             ),
                      //             Row(
                      //               mainAxisAlignment:
                      //                   MainAxisAlignment.spaceBetween,
                      //               children: [
                      //                 Card(
                      //                   elevation: 2,
                      //                   shape: RoundedRectangleBorder(
                      //                     borderRadius: BorderRadius.circular(12),
                      //                   ),
                      //                   child: Container(
                      //                     padding: const EdgeInsets.all(12),
                      //                     child: Column(
                      //                       crossAxisAlignment:
                      //                           CrossAxisAlignment.center,
                      //                       mainAxisAlignment:
                      //                           MainAxisAlignment.spaceBetween,
                      //                       children: [
                      //                         Text(
                      //                           'Rating A',
                      //                           style: getBlackTextStyle(
                      //                               fontWeight: w700),
                      //                         ),
                      //                         const SizedBox(
                      //                           height: 12,
                      //                         ),
                      //                         Text(
                      //                           '1',
                      //                           textAlign: TextAlign.center,
                      //                           style: getBlackTextStyle(
                      //                             fontSize: 12,
                      //                           ),
                      //                         )
                      //                       ],
                      //                     ),
                      //                   ),
                      //                 ),
                      //                 Card(
                      //                   elevation: 2,
                      //                   shape: RoundedRectangleBorder(
                      //                     borderRadius: BorderRadius.circular(12),
                      //                   ),
                      //                   child: Container(
                      //                     padding: const EdgeInsets.all(12),
                      //                     child: Column(
                      //                       crossAxisAlignment:
                      //                           CrossAxisAlignment.center,
                      //                       mainAxisAlignment:
                      //                           MainAxisAlignment.spaceBetween,
                      //                       children: [
                      //                         Text(
                      //                           'Rating B',
                      //                           style: getBlackTextStyle(
                      //                               fontWeight: w700),
                      //                         ),
                      //                         const SizedBox(
                      //                           height: 12,
                      //                         ),
                      //                         Text(
                      //                           '1',
                      //                           textAlign: TextAlign.center,
                      //                           style: getBlackTextStyle(
                      //                             fontSize: 12,
                      //                           ),
                      //                         )
                      //                       ],
                      //                     ),
                      //                   ),
                      //                 ),
                      //                 Card(
                      //                   elevation: 2,
                      //                   shape: RoundedRectangleBorder(
                      //                     borderRadius: BorderRadius.circular(12),
                      //                   ),
                      //                   child: Container(
                      //                     padding: const EdgeInsets.all(12),
                      //                     child: Column(
                      //                       crossAxisAlignment:
                      //                           CrossAxisAlignment.center,
                      //                       mainAxisAlignment:
                      //                           MainAxisAlignment.spaceBetween,
                      //                       children: [
                      //                         Text(
                      //                           'Rating C',
                      //                           style: getBlackTextStyle(
                      //                               fontWeight: w700),
                      //                         ),
                      //                         const SizedBox(
                      //                           height: 12,
                      //                         ),
                      //                         Text(
                      //                           '1',
                      //                           textAlign: TextAlign.center,
                      //                           style: getBlackTextStyle(
                      //                             fontSize: 12,
                      //                           ),
                      //                         )
                      //                       ],
                      //                     ),
                      //                   ),
                      //                 ),
                      //                 Card(
                      //                   elevation: 2,
                      //                   shape: RoundedRectangleBorder(
                      //                     borderRadius: BorderRadius.circular(12),
                      //                   ),
                      //                   child: Container(
                      //                     padding: const EdgeInsets.all(12),
                      //                     child: Column(
                      //                       crossAxisAlignment:
                      //                           CrossAxisAlignment.center,
                      //                       mainAxisAlignment:
                      //                           MainAxisAlignment.spaceBetween,
                      //                       children: [
                      //                         Text(
                      //                           'Rating X',
                      //                           style: getBlackTextStyle(
                      //                               fontWeight: w700),
                      //                         ),
                      //                         const SizedBox(
                      //                           height: 12,
                      //                         ),
                      //                         Text(
                      //                           '1',
                      //                           textAlign: TextAlign.center,
                      //                           style: getBlackTextStyle(
                      //                             fontSize: 12,
                      //                           ),
                      //                         )
                      //                       ],
                      //                     ),
                      //                   ),
                      //                 ),
                      //               ],
                      //             ),
                      //             const SizedBox(
                      //               height: 12,
                      //             ),
                      //             SizedBox(
                      //               height: 45,
                      //               child: ButtonWidget(
                      //                   name: Row(
                      //                     mainAxisAlignment:
                      //                         MainAxisAlignment.spaceBetween,
                      //                     children: [
                      //                       Text(
                      //                         'Detail',
                      //                         style: getWhiteTextStyle(),
                      //                       ),
                      //                       Icon(
                      //                         Icons.arrow_forward_ios,
                      //                         size: 12,
                      //                       ),
                      //                     ],
                      //                   ),
                      //                   function: () {}),
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      //     ),
                      //   ],
                      // );
                    }

                    return Container();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
