import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:flutter/material.dart';

class TireDetail extends StatelessWidget {
  final Map<String, dynamic> tireDetail;

  const TireDetail({super.key, required this.tireDetail});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        BoxForm(
          title: 'Customer',
          textEditingControllerForm:
              TextEditingController(text: tireDetail['customer']),
        ),
        BoxForm(
          title: 'Repair Location',
          textEditingControllerForm:
              TextEditingController(text: tireDetail['repair_location']),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 12.0),
          child: Divider(
            color: grey8391A1,
          ),
        ),
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
          textEditingControllerForm:
              TextEditingController(text: tireDetail['tire_size']),
        ),
        BoxForm(
          title: 'Brand',
          textEditingControllerForm:
              TextEditingController(text: tireDetail['brand']),
        ),
        BoxForm(
          title: 'Serial Number',
          textEditingControllerForm:
              TextEditingController(text: tireDetail['sn']),
        ),
        BoxForm(
          title: 'Pattern',
          textEditingControllerForm:
              TextEditingController(text: tireDetail['pattern']),
        ),
        BoxForm(
          title: 'Tire Construction',
          textEditingControllerForm:
              TextEditingController(text: tireDetail['type_construction']),
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
