import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/pages/admin/add_user_page.dart';
import 'package:camos/pages/admin/admin_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminPage extends StatelessWidget {
  static const routeName = '/admin-page';

  AdminPage({super.key});

  final AdminState controller = Get.put(AdminState());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          height: 70,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, AddUserPage.routeName);
            },
            backgroundColor: green00968A,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            label: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Add User",
                  style: getWhiteTextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              decoration: const BoxDecoration(
                color: green00968A,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'CAMOS Administration',
                              style: getWhiteTextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: controller.searchC,
                      onChanged: (value) {
                        controller.searchUser(value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search name, email or SN.....',
                        hintStyle: getBlackTextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ).copyWith(
                          color: Colors.grey,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(
                () => ListView.separated(
                  padding: const EdgeInsets.only(top: 8, bottom: 86),
                  itemCount: controller.users.length,
                  separatorBuilder: (context, index) => const Divider(
                    thickness: 1,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final user = controller.users[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: user['image'].isNotEmpty &&
                                                  user['image'] != 'image'
                                              ? Image.network(
                                                  user['image'],
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  padding:
                                                      const EdgeInsets.all(20),
                                                  color:
                                                      const Color(0xFFEAEAEA),
                                                  child: Image.asset(
                                                    'assets/images/maskot.png',
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.pop(context);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 42,
                                  backgroundColor: const Color(0xFFEAEAEA),
                                  child: ClipOval(
                                    child: user['image'].isNotEmpty &&
                                            user['image'] != 'image'
                                        ? Image.network(
                                            user['image'],
                                            width: 84,
                                            height: 84,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 84,
                                            height: 84,
                                            color: const Color(0xFFEAEAEA),
                                            child: Image.asset(
                                              'assets/images/maskot.png',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                // IconButton(
                                //   onPressed: () {},
                                //   style: IconButton.styleFrom(
                                //     backgroundColor: const Color(0xffE8F8F2),
                                //     padding: const EdgeInsets.all(12),
                                //   ),
                                //   icon: Row(
                                //     children: [
                                //       Text(
                                //         'Edit',
                                //         style: getGreenTextStyle(),
                                //       ),
                                //       const SizedBox(
                                //         width: 4,
                                //       ),
                                //       const Icon(
                                //         Icons.edit_rounded,
                                //         size: 12,
                                //         color: green00968A,
                                //       ),
                                //     ],
                                //   ),
                                // )
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['username'],
                                  style: getBlackTextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "SN ${user['sn']}",
                                  style: getBlackTextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  user['position'],
                                  style: getBlackTextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.email,
                                      size: 18,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        user['email'],
                                        style: getBlackTextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete User'),
                                      content: Text(
                                        'Yakin ingin menghapus ${user['username']}?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await controller
                                        .softDeleteUser(user['doc_id']);
                                  }
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
