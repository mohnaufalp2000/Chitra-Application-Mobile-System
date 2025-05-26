import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/jobcard_repair.dart';
import 'package:camos/pages/tire_repair_form/jobcard_repair/jobcard_form_page.dart';
import 'package:camos/pages/tire_repair_form/jobcard_repair/jobcard_qc_page.dart';
import 'package:flutter/material.dart';

class ListJobcardRepair extends StatefulWidget {
  static const routeName = '/list-jobcard-repair';
  const ListJobcardRepair({super.key});

  @override
  State<ListJobcardRepair> createState() => _ListJobcardRepairState();
}

class _ListJobcardRepairState extends State<ListJobcardRepair> {
  bool isChecked = false;
  final List<String> jobName = JobcardRepair.jobName;
  int selectedMenu = 0;

  List<bool> isCheckedList =
      List.generate(10, (_) => false); // Sesuaikan jumlah item

  void _onSkipPressed() {
    // Aksi saat tombol skip ditekan
    print("Skip button pressed");
  }

  void _onHistoryPressed() {
    Navigator.pushNamed(context, JobcardQCPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jobcard Repair',
          style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF359B7B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            color: Colors.white,
            tooltip: 'History',
            onPressed: _onHistoryPressed,
          ),
        ],
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Center(
                child: Card(
                  color: white,
                  elevation: 50,
                  shadowColor: black,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer : PT. Cipta Kridatama',
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Text(
                          'Repair Location : BSF',
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'W/O #',
                              style: getGreyTextStyle(const Color(0xff969696)),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              '80000033714',
                              style: getBlackTextStyle(
                                fontSize: 18,
                                fontWeight: w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Serial Number',
                                  style:
                                      getGreyTextStyle(const Color(0xff969696)),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  'FGR3463GRE',
                                  style: getBlackTextStyle(
                                    fontSize: 18,
                                    fontWeight: w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              width: 6,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tire Size',
                                  style:
                                      getGreyTextStyle(const Color(0xff969696)),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  '27.00R49',
                                  style: getBlackTextStyle(
                                    fontSize: 18,
                                    fontWeight: w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              width: 6,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: List.generate(jobName.length, (index) {
                            return InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                    context, JobcardFormPage.routeName);
                              },
                              child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey,
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          // (index == 0)
                                          //     ? SizedBox(
                                          //         width: 20,
                                          //         height: 20,
                                          //         child: Image.asset(
                                          //             '${iconPath}/accept.png'),
                                          //       )
                                          //     : Container(
                                          //         width: 20,
                                          //         height: 20,
                                          //         decoration: BoxDecoration(
                                          //             borderRadius:
                                          //                 BorderRadius.circular(
                                          //                     6),
                                          //             border: Border.all(
                                          //                 color: black)),
                                          //       ),
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border:
                                                    Border.all(color: black)),
                                          ),
                                          const SizedBox(
                                            width: 6,
                                          ),
                                          Text(
                                            jobName[index],
                                            style: getBlackTextStyle(),
                                          )
                                        ],
                                      ),
                                      SizedBox(
                                        width: 60,
                                        height: 25,
                                        child: TextButton(
                                          onPressed: () {
                                            print(
                                                "Skip ${jobName[index]} pressed");
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF35469B),
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.skip_next_outlined,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                                SizedBox(width: 2),
                                                Text(
                                                  'Skip',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      )),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedMenu,
          onTap: (index) {
            setState(() {
              selectedMenu = index;
            });
          },
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.tag), label: 'Waiting WO#'),
            BottomNavigationBarItem(
                icon: Icon(Icons.work_history), label: 'On Progress'),
            BottomNavigationBarItem(
                icon: Icon(Icons.fact_check), label: 'Waiting QC'),
          ]),
    );
  }
}
