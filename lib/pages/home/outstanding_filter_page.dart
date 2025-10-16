import 'dart:developer';

import '../../core/styles/text_manager.dart';
import '../../core/widgets/appbar_widget.dart';
import '../../core/widgets/check_box_modal_widget.dart';
import 'package:flutter/material.dart';

class OutstandingFilterPage extends StatefulWidget {
  static const routeName = '/outstanding-filter-page';
  const OutstandingFilterPage({super.key});

  @override
  State<OutstandingFilterPage> createState() => _OutstandingFilterPageState();
}

class _OutstandingFilterPageState extends State<OutstandingFilterPage> {
  final allChecked = CheckBoxModalWidget(title: 'All');
  final checkBoxList = [];

  onAllClicked(CheckBoxModalWidget ckbItem) {
    final newValue = !ckbItem.value;

    ckbItem.value = newValue;
    checkBoxList.forEach((element) {
      element.value = newValue;
    });

    // if (ckbItem.value) {
    //   checkBoxTitleSelected.add(ckbItem.title);
    // } else {
    //   checkBoxTitleSelected.removeWhere((element) {
    //     return element == ckbItem.title;
    //   });
    // }
  }

  onItemClicked(CheckBoxModalWidget ckbItem) {
    final newValue = !ckbItem.value;

    ckbItem.value = newValue;

    if (!newValue) {
      allChecked.value = false;
    } else {
      final allListChecked = checkBoxList.every((element) => element.value);
      allChecked.value = allListChecked;
    }

    // if (ckbItem.value) {
    //   checkBoxTitleSelected.add(ckbItem.title);
    // } else {
    //   checkBoxTitleSelected.removeWhere((element) {
    //     return element == ckbItem.title;
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    final data =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    checkBoxList.clear();
    checkBoxList.addAll(data['checkBoxList']);

    return Scaffold(
      appBar: appBarWidget('Filter', context),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            children: [
              const SizedBox(
                height: 24,
              ),
              ListTile(
                onTap: () {
                  setState(() {
                    onAllClicked(allChecked);
                  });
                },
                leading: Checkbox(
                  value: allChecked.value,
                  onChanged: (value) {
                    setState(() {
                      onAllClicked(allChecked);
                    });
                  },
                ),
                title: Text(
                  'All',
                  style: getBlackTextStyle(),
                ),
              ),
              ...data['checkBoxList'].map((item) {
                return ListTile(
                  onTap: () {
                    setState(() {
                      onItemClicked(item);
                    });
                  },
                  leading: Checkbox(
                    value: item.value,
                    onChanged: (value) {
                      setState(() {
                        onItemClicked(item);
                      });
                    },
                  ),
                  title: Text(
                    item.title,
                    style: getBlackTextStyle(),
                  ),
                );
              }),
            ],
          ),
        ),
      )),
    );
  }
}
