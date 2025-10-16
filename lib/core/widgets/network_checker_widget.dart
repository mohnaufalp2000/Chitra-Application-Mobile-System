import '../blocs/network/network_bloc.dart';
import '../styles/color.dart';
import '../styles/text_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NetworkCheckerWidget extends StatefulWidget {
  const NetworkCheckerWidget({super.key});

  @override
  State<NetworkCheckerWidget> createState() => _NetworkCheckerWidgetState();
}

class _NetworkCheckerWidgetState extends State<NetworkCheckerWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NetworkBloc, NetworkState>(
      listener: (context, state) {
        // if (state is NetworkConnected) {
        //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        //     content: Text(
        //       'Ada internet',
        //       style: getWhiteTextStyle(
        //         fontWeight: w700,
        //       ),
        //     ),
        //     backgroundColor: green35C2C1,
        //   ));
        // } else if (state is NetworkDisconnected) {
        //   showDialog(
        //     context: context,
        //     builder: (BuildContext context) {
        //       return AlertDialog(
        //         title: Text('Tidak ada koneksi internet'),
        //         content: Text('Aktifkan koneksi internet anda terlebih dahulu'),
        //         actions: <Widget>[],
        //       );
        //     },
        //   );
        // } else {
        //   null;
        // }
      },
      builder: (context, state) {
        if (state is NetworkDisconnected) {
          return Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 12),
              color: Colors.red,
              child: Center(
                child: Text(
                  'Tidak Ada internet',
                  style: getWhiteTextStyle(fontWeight: w700),
                ),
              ));
        } else {
          return Container();
        }
      },
    );
  }
}
