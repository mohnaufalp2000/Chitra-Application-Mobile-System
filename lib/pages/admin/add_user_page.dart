import 'package:camos/pages/admin/add_user_state.dart';
import 'package:camos/pages/admin/admin_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/styles/color.dart';
import '../../../core/styles/text_manager.dart';

class AddUserPage extends StatelessWidget {
  static const routeName = '/add-user-page';
  AddUserPage({super.key});

  final AddUserState controller = Get.put(AddUserState());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFCFF7D3),
              Color(0xFFEAFBF0),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                /// BACK BUTTON
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: const Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// TITLE
                Text(
                  'Add User',
                  style: getBlackTextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Please provide the details below\nto create user account',
                  textAlign: TextAlign.center,
                  style: getBlackTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ).copyWith(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 40),

                /// USERNAME
                customTextField(
                  controller: controller.usernameC,
                  hint: 'Full Name',
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 18),

                /// EMAIL
                customTextField(
                  controller: controller.emailC,
                  hint: 'Email Address',
                  icon: Icons.email_outlined,
                ),

                const SizedBox(height: 18),

                /// SN
                customTextField(
                  controller: controller.snC,
                  hint: 'SN',
                  icon: Icons.confirmation_number_outlined,
                ),

                const SizedBox(height: 18),

                /// POSITION
                customTextField(
                  controller: controller.positionC,
                  hint: 'Position',
                  icon: Icons.work_outline,
                ),

                const SizedBox(height: 18),

                /// AGE
                customTextField(
                  controller: controller.ageC,
                  hint: 'Age',
                  icon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 18),

                const SizedBox(height: 40),

                /// BUTTON
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () {
                              controller.addUser();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green00968A,
                        elevation: 0,
                        disabledBackgroundColor: green00968A.withOpacity(0.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              'Create Account',
                              style: getWhiteTextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget customTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black38,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: getBlackTextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            icon,
            color: Colors.grey,
          ),
          hintText: hint,
          hintStyle: getBlackTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ).copyWith(
            color: Colors.grey,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
