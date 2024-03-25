import 'dart:developer';

import 'package:camos/core/blocs/detail_tire_condition/detail_tire_condition_bloc.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DetailTireConditionPage extends StatefulWidget {
  static const routeName = '/detail-tire-condition-page';
  const DetailTireConditionPage({super.key});

  @override
  State<DetailTireConditionPage> createState() =>
      _DetailTireConditionPageState();
}

class _DetailTireConditionPageState extends State<DetailTireConditionPage> {
  List<String> _ratingFilters = [
    'A',
    'B',
    'C',
    'X',
  ];
  List<String> _positionFilters = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
  ];

  Set<String> _selectedRatingFilters = Set<String>();
  Set<String> _selectedPositionFilters = Set<String>();

  bool _isRatingFilterSelected(String filter) {
    return _selectedRatingFilters.contains(filter);
  }

  void _toggleRatingFilter(String filter) {
    if (_isRatingFilterSelected(filter)) {
      _selectedRatingFilters.remove(filter);
    } else {
      _selectedRatingFilters.add(filter);
    }
  }

  bool _isPositionFilterSelected(String filter) {
    return _selectedPositionFilters.contains(filter);
  }

  void _togglePositionFilter(String filter) {
    if (_isPositionFilterSelected(filter)) {
      _selectedPositionFilters.remove(filter);
    } else {
      _selectedPositionFilters.add(filter);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final data =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    context.read<DetailTireConditionBloc>().add(GetDetailTireConditionEvent(
        size: data['data'], idSite: data['idSite']));

    return Scaffold(
      appBar: appBarWidget('Detail Tire Condition', context),
      body: SafeArea(child: SingleChildScrollView(
        child: BlocBuilder<DetailTireConditionBloc, DetailTireConditionState>(
          builder: (context, state) {
            if (state is DetailTireConditionLoadingState) {
              return Center(child: CircularProgressIndicator());
            }

            if (state is DetailTireConditionLoadedState) {
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      'Tire Rating of ${state.units[0].size}',
                      style: getBlackTextStyle(),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Rating',
                          style:
                              getBlackTextStyle(fontWeight: w700, fontSize: 16),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _ratingFilters.map((filter) {
                              return FilterChip(
                                  label: Text(filter),
                                  selected: _isRatingFilterSelected(filter),
                                  selectedColor: green35C2C1,
                                  onSelected: (_) {
                                    setState(() {});
                                    _toggleRatingFilter(filter);
                                  });
                            }).toList()),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          'Position',
                          style:
                              getBlackTextStyle(fontWeight: w700, fontSize: 16),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: _positionFilters.map((filter) {
                              return FilterChip(
                                  label: Text(filter),
                                  selected: _isPositionFilterSelected(filter),
                                  selectedColor: green35C2C1,
                                  onSelected: (_) {
                                    setState(() {});
                                    _togglePositionFilter(filter);
                                  });
                            }).toList()),
                        const SizedBox(
                          height: 12,
                        ),
                      ],
                    ),
                    Column(
                      children: state.units
                          .where((unit) =>
                              _selectedRatingFilters.isEmpty ||
                              _selectedRatingFilters.contains(unit.rating))
                          .where((unit) =>
                              _selectedPositionFilters.isEmpty ||
                              _selectedPositionFilters.contains(unit.posisi))
                          .map((unit) {
                        return Card(
                          elevation: 2,
                          child: Container(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Unit Number',
                                      style: getBlackTextStyle(),
                                    ),
                                    Text(unit.unitNumber ?? '',
                                        style: getBlackTextStyle())
                                  ],
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Position',
                                      style: getBlackTextStyle(),
                                    ),
                                    Text(unit.posisi ?? '',
                                        style: getBlackTextStyle())
                                  ],
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Lifetime',
                                      style: getBlackTextStyle(),
                                    ),
                                    Text(unit.lifetime ?? '',
                                        style: getBlackTextStyle())
                                  ],
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Size',
                                      style: getBlackTextStyle(),
                                    ),
                                    Text(unit.size ?? '',
                                        style: getBlackTextStyle())
                                  ],
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rating',
                                      style: getBlackTextStyle(),
                                    ),
                                    Text(unit.rating ?? '',
                                        style: getBlackTextStyle())
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }
            return Container();
          },
        ),
      )),
    );
  }
}
