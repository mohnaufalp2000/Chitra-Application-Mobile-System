import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryJobcardRepairPage extends StatefulWidget {
  static const routeName = '/history-jobcard-repair';
  const HistoryJobcardRepairPage({super.key});

  @override
  State<HistoryJobcardRepairPage> createState() =>
      _HistoryJobcardRepairPageState();
}

class _HistoryJobcardRepairPageState extends State<HistoryJobcardRepairPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 12, vsync: this, initialIndex: 11);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Tab> generateLast12MonthsTabs(DateTime fromDate) {
    return List.generate(12, (index) {
      DateTime month = DateTime(fromDate.year, fromDate.month - index);
      String monthName = DateFormat('MMMM yyyy').format(month);
      return Tab(text: monthName);
    }).reversed.toList(); // Agar urutannya dari lama ke terbaru
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'History Jobcard Repair',
          style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
        ),
        backgroundColor: green359B7B,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Row(
              children: [
                Text(
                  'Filter',
                  style: getWhiteTextStyle(),
                ),
                const Icon(Icons.filter_alt),
              ],
            ),
            color: Colors.white,
            tooltip: 'Filter',
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: white,
          tabs: generateLast12MonthsTabs(DateTime.now()),
        ),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              TextField(
                onChanged: (value) {
                  // setState(() {
                  //   searchQuery = value;
                  // });
                },
                decoration: InputDecoration(
                    hintText: 'Search... ',
                    hintStyle: getGreyTextStyle(grey8391A1),
                    prefixIcon: Icon(Icons.search)),
              ),
            ],
          ),
        ),
      )),
    );
  }
}
