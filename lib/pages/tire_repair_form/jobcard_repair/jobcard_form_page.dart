import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/jobcard_repair.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:flutter/material.dart';

class JobcardFormPage extends StatefulWidget {
  static const routeName = '/jobcard-form-page';
  const JobcardFormPage({super.key});

  @override
  State<JobcardFormPage> createState() => _JobcardFormPageState();
}

class _JobcardFormPageState extends State<JobcardFormPage>
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
          'Jobcard Repair (${JobcardRepair.jobName[0]})',
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
          children: const [
            TireDetail(),
            ProcessRepair(),
          ],
        ),
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

class ProcessRepair extends StatelessWidget {
  const ProcessRepair({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        BoxFormProcess(
          title: 'Injuries',
          isLargeInput: true,
        ),
        const SizedBox(
          height: 12,
        ),
        BoxFormProcess(
          title: 'Date',
        ),
        const SizedBox(
          height: 12,
        ),
        BoxFormProcess(
          title: 'Material',
        ),
        const SizedBox(
          height: 12,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 120,
              child: BoxFormProcess(
                title: 'QTY (KG)',
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 80,
                  child: BoxFormProcess(
                    title: 'Hours',
                  ),
                ),
                Text(
                  ' : ',
                  style: getBlackTextStyle(fontSize: 32),
                ),
                SizedBox(
                  width: 80,
                  child: BoxFormProcess(
                    title: 'Minutes',
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        BoxFormProcess(
          title: 'By Whom',
        ),
        const SizedBox(
          height: 12,
        ),
        ButtonWidget(
            color: green359B7B,
            name: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.save,
                  color: white,
                ),
                const SizedBox(
                  width: 12,
                ),
                Text(
                  'Save',
                  style: getWhiteTextStyle(),
                ),
              ],
            ),
            function: () {})
      ]),
    );
  }
}

class BoxFormProcess extends StatelessWidget {
  bool isLargeInput;
  String title;

  BoxFormProcess({
    super.key,
    this.isLargeInput = false,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Text(title,
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
          child: (isLargeInput)
              ? TextField(
                  controller: TextEditingController(),
                  maxLines: null,
                  minLines: 5,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: EdgeInsets.only(left: 20, top: 40),
                  ),
                )
              : TextField(
                  controller: TextEditingController(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    contentPadding: EdgeInsets.only(left: 20),
                  ),
                ),
        ),
      ],
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
