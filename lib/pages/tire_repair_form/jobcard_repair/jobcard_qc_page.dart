import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/jobcard_repair.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:flutter/material.dart';

class JobcardQCPage extends StatefulWidget {
  static const routeName = '/jobcard-qc-page';
  const JobcardQCPage({super.key});

  @override
  State<JobcardQCPage> createState() => _JobcardQCPageState();
}

class _JobcardQCPageState extends State<JobcardQCPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jobcard Repair',
          style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
        ),
        backgroundColor: green359B7B,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: white,
          tabs: const [
            Tab(text: 'Tire Detail'),
            Tab(text: 'Process Repair (1)'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: const [TireDetail(), DetailRepair()],
        ),
      ),
    );
  }
}

class DetailRepair extends StatelessWidget {
  const DetailRepair({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text('Injuries',
                style: getBlackTextStyle(
                  fontSize: 18,
                  fontWeight: w700,
                )),
          ),
          const SizedBox(height: 10),
          Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                readOnly: true,
                controller: TextEditingController(),
                maxLines: null,
                minLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: EdgeInsets.only(left: 20, top: 40),
                ),
              )),
          const SizedBox(height: 12),
          Column(
            children: List.generate(JobcardRepair.jobName.length, (index) {
              final name = JobcardRepair.jobName[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: getBlackTextStyle(),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Divider(
                    color: grey6A707C,
                  )
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class TireDetail extends StatelessWidget {
  const TireDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        BoxForm(
          title: 'W/O #',
          textEditingControllerForm: TextEditingController(),
        ),
        BoxForm(
          title: 'W/O # Date',
          textEditingControllerForm: TextEditingController(),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: Divider(
            color: grey8391A1,
          ),
        ),
        BoxForm(
          title: 'Tire Size',
          textEditingControllerForm: TextEditingController(),
        ),
        BoxForm(
          title: 'Brand',
          textEditingControllerForm: TextEditingController(),
        ),
        BoxForm(
          title: 'Serial Number',
          textEditingControllerForm: TextEditingController(),
        ),
        BoxForm(
          title: 'Pattern',
          textEditingControllerForm: TextEditingController(),
        ),
        BoxForm(
          title: 'Tire Construction',
          textEditingControllerForm: TextEditingController(),
        ),
      ]),
    );
  }
}

class BoxForm extends StatelessWidget {
  final String title;
  final TextEditingController textEditingControllerForm;
  final bool isLargeInput;
  final bool isReadOnly;
  final double height;

  BoxForm({
    super.key,
    required this.title,
    required this.textEditingControllerForm,
    this.isLargeInput = false,
    this.isReadOnly = true,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: getBlackTextStyle(
              fontWeight: w700,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: InputFormWidget(
                  isReadOnly: isReadOnly,
                  isLargeInput: isLargeInput,
                  height: height,
                  controller: textEditingControllerForm,
                  hint: '')),
        ],
      ),
    );
  }
}
