import 'dart:developer';

import 'package:bloc/bloc.dart';
import '../../services/api_service.dart';
import '../../services/shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc() : super(AuthenticatioLogoutState()) {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore fireStore = FirebaseFirestore.instance;
    CollectionReference users = fireStore.collection('users');

    on<AuthenticationEventLogin>((event, emit) async {
      // login
      try {
        emit(AuthenticatioLoadingState());
        await ApiService.getAllSite();
        await auth.signInWithEmailAndPassword(
            email: event.email, password: event.password);
        emit(AuthenticatioLoginState());
      } on FirebaseAuthException catch (e) {
        emit(AuthenticationErrorState(errorMessage: e.message ?? ''));
      } catch (e) {
        emit(AuthenticationErrorState(errorMessage: e.toString()));
      }
    });
    on<AuthenticationEventLogout>((event, emit) async {
      // logout
      try {
        // emit(AuthenticatioLoadingState());
        if (event.isDelete) {
          await auth.currentUser?.delete();
        }
        final prefs = await getSharedPreferences();
        await prefs.clear();
        await auth.signOut();
      } on FirebaseAuthException catch (e) {
        emit(AuthenticationErrorState(errorMessage: e.message ?? ''));
      } catch (e) {
        emit(AuthenticationErrorState(errorMessage: e.toString()));
      }
    });
    on<AuthenticationEventRegister>((event, emit) async {
      // Register
      try {
        emit(AuthenticatioLoadingState());
        await auth
            .createUserWithEmailAndPassword(
                email: event.email, password: event.password)
            .then((value) {
          try {
            String uid = auth.currentUser!.uid;

            print('identitasku (bloc) : $uid');
            users.doc(uid).set({
              'email': event.email,
              'username': 'username',
              'sn': event.sn,
              'image': 'image',
              'age': 0,
              'position': 'position',
              'id_site': event.idSite,
              'created_at': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            });
            // users.add({
            //   'email': event.email,
            //   'username': 'username',
            //   'image': 'image',
            //   'age': 0,
            //   'position': 'position',
            //   'id_site': event.idSite
            // }).then((value) => print('Akun berhasil dibuat!'));
          } catch (e) {
            emit(AuthenticationErrorState(errorMessage: e.toString()));
          }
        });

        emit(AuthenticatioRegisterState());
      } on FirebaseAuthException catch (e) {
        emit(AuthenticationErrorState(errorMessage: e.message ?? ''));
      } catch (e) {
        emit(AuthenticationErrorState(errorMessage: e.toString()));
      }
    });
    on<AuthenticationEventChangePassword>((event, emit) async {
      // forgot password
      try {
        emit(AuthenticatioLoadingState());
        await auth.sendPasswordResetEmail(email: event.email);
        emit(AuthenticationChangePasswordState());
      } on FirebaseAuthException catch (e) {
        emit(AuthenticationErrorState(errorMessage: e.message ?? ''));
      } catch (e) {
        emit(AuthenticationErrorState(errorMessage: e.toString()));
      }
    });
    on<AuthenticationEventVerifyEmail>((event, emit) async {
      // verify email
      try {
        emit(AuthenticatioLoadingState());
        if (auth.currentUser != null) {
          auth.currentUser?.sendEmailVerification();
        }

        emit(AuthenticationVerifyEmailState());
        print('berhasil');
      } on FirebaseAuthException catch (e) {
        print('gagal1');
        emit(AuthenticationErrorState(errorMessage: e.message ?? ''));
      } catch (e) {
        print('gagal2');
        emit(AuthenticationErrorState(errorMessage: e.toString()));
      }
    });

    on<AuthenticationEventUploadPhoto>((event, emit) async {
      try {
        emit(AuthenticatioLoadingState());
        await ApiService.getAllSite();
        // upload image path to firestore
        await users
            .where('email', isEqualTo: auth.currentUser!.email)
            .get()
            .then((value) {
          value.docs.forEach((element) {
            print('id element : ' + element.id);
            users.doc(element.id).update({
              'image': event.path,
            });
          });
        });
        emit(AuthenticationCompleteProfileState());
      } catch (e) {
        emit(AuthenticationErrorState(errorMessage: e.toString()));
      }
    });

    on<AuthenticationEventUpdate>((event, emit) async {
      try {
        emit(AuthenticatioLoadingState());
        await users
            .where('email', isEqualTo: auth.currentUser!.email)
            .get()
            .then((value) {
          value.docs.forEach((element) {
            Map<String, dynamic>? profile =
                element.data() as Map<String, dynamic>?;

            // if (profile != null) {
            //   print('data update ${profile['username']}');
            //   if (event.username != '' ||
            //       event.username != profile['username']) {
            //     users.doc(element.id).update({
            //       'username': event.username,
            //     });
            //   }

            //   if (event.position != '' ||
            //       event.username != profile['position']) {
            //     users.doc(element.id).update({
            //       'position': event.position,
            //     });
            //   }

            //   if (event.age != 0 || event.age != profile['age']) {
            //     users.doc(element.id).update({
            //       'position': event.position,
            //     });
            //   }

            //   if (event.image != '' || event.image != profile['image']) {
            //     users.doc(element.id).update({
            //       'image': event.image,
            //     });
            //   }
            // }

            users.doc(element.id).update({
              'username': event.username,
              'position': event.position,
              'age': event.age,
              'image': event.image,
            });
          });
        });
        emit(AuthenticationCompleteProfileState());
      } catch (e) {
        emit(AuthenticationErrorState(errorMessage: e.toString()));
      }
    });
  }
}
