// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputFormWidget extends StatefulWidget {
  const InputFormWidget(
      {Key? key,
      required this.controller,
      required this.hint,
      this.type = TextInputType.name,
      this.onChng,
      this.width,
      this.height,
      this.isReadOnly = false,
      this.isObscure = false,
      this.isDigitOnly = false,
      this.isDecimalOnly = false,
      this.isLargeInput = false})
      : super(key: key);

  final double? width;
  final double? height;

  final bool isReadOnly;
  final TextEditingController controller;
  final String hint;
  final bool isObscure;
  final TextInputType type;
  final bool isDigitOnly;
  final bool isDecimalOnly;
  final bool isLargeInput;
  final Function(String)? onChng;

  @override
  State<InputFormWidget> createState() => _InputFormWidgetState();
}

class _InputFormWidgetState extends State<InputFormWidget> {
  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    isPasswordVisible = false;
  }

  @override
  void dispose() {
    widget.controller.clear();
    widget.controller.dispose();
    super.dispose();
  }

  formatter() {
    if (widget.isDigitOnly) {
      List<TextInputFormatter>? format = [
        FilteringTextInputFormatter.digitsOnly
      ];
      return format;
    } else if (widget.isDecimalOnly) {
      List<TextInputFormatter>? format = [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        _DecimalInputFormatter(decimalRegExp: RegExp(r'^\d{0,10}\.?\d{0,10}$')),
      ];
      return format;
    } else {
      List<TextInputFormatter>? format = [];
      return format;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: widget.height,
      child: TextFormField(
        readOnly: widget.isReadOnly,
        onChanged: widget.onChng,
        controller: widget.controller,
        keyboardType: widget.type,
        maxLines: (widget.isLargeInput) ? 7 : 1,
        autofocus: false,
        obscureText: (widget.isObscure) ? !isPasswordVisible : false,
        decoration: InputDecoration(
          filled: true,
          fillColor: greyF7F8F9,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: greyDADADA),
          ),
          hintText: widget.hint,
          hintStyle: getGreyTextStyle(grey8391A1),
          suffixIcon: (widget.isObscure)
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ))
              : null,
        ),
        inputFormatters: formatter(),
      ),
    );
  }
}

class _DecimalInputFormatter extends TextInputFormatter {
  final RegExp decimalRegExp;

  _DecimalInputFormatter({required this.decimalRegExp});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (decimalRegExp.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}
