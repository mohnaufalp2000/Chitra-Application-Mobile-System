import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/model/site.dart';
import 'package:camos/core/utils/data/id_site.dart';
import 'package:camos/pages/dashboard/dashboard_page.dart';
import 'package:camos/pages/home/trial/home_page_trial.dart';
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

    // on<AuthenticationEventLogin>((event, emit) async {
    //   // login
    //   try {
    //     emit(AuthenticatioLoadingState());
    //     await ApiService.getAllSite();
    //     await auth.signInWithEmailAndPassword(
    //         email: event.email, password: event.password);
    //     emit(AuthenticatioLoginState());
    //   } on FirebaseAuthException catch (e) {
    //     emit(AuthenticationErrorState(errorMessage: e.message ?? ''));
    //   } catch (e) {
    //     emit(AuthenticationErrorState(errorMessage: e.toString()));
    //   }
    // });
    on<AuthenticationEventLogin>((event, emit) async {
      try {
        emit(AuthenticatioLoadingState());

        await auth.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );

        if (!auth.currentUser!.emailVerified) {
          emit(AuthenticationEmailNotVerifiedState());
          return;
        }

        final userQuery = await fireStore
            .collection('users')
            .where('email', isEqualTo: auth.currentUser!.email)
            .get();

        if (userQuery.docs.isEmpty) {
          emit(AuthenticationErrorState(errorMessage: 'User tidak ditemukan'));
          return;
        }

        final userData = userQuery.docs.first.data();

        final bool isDeleted = userData['isDelete'] == true;

        // user yang sudah didelete tidak bisa login
        if (isDeleted) {
          await auth.signOut();

          emit(
            AuthenticationErrorState(
              errorMessage: 'Account is no longer active',
            ),
          );
          return;
        }

        // save preference dulu
        saveIdSitePreferences(userData['id_site']);
        saveManpowerShiftPreferences(shift: 'morning');
        saveUserPreferences(userData);

        final listCustPgDigital =
            await fireStore.collection('list_site_pgdigital').get();

        final listCustPgDigitalData =
            listCustPgDigital.docs.map((e) => e.data()).toList();

        await saveListCustomer(listCustPgDigitalData);

        final String userIdSite = userData['id_site'];

        // sekarang idSite sudah ada
        List<Site> allSites = await ApiService.getCachedAllSites();

        if (allSites.isEmpty) {
          allSites = await ApiService.getAllSite();
        }

        final isCTS = allSites
            .firstWhere(
              (site) => site.idSite == userIdSite,
              orElse: () => Site(
                idSite: userIdSite,
                cts: '0',
              ),
            )
            .cts;

        final isSPM = allSites
            .firstWhere(
              (site) => site.idSite == userIdSite,
              orElse: () => Site(
                idSite: userIdSite,
                spm: '0',
              ),
            )
            .spm;

        log('isCTS : $isCTS isSPM : $isSPM');

        final isSitePGInList =
            listCustPgDigitalData.any((e) => e['id_site'] == userIdSite);

        if (isCTS == '0') {
          if (userIdSite == '15') {
            emit(AuthenticationSuccessState(
              targetRoute: DashboardPage.routeName,
            ));
            return;
          }

          final targetRoute = (userIdSite == officeChitra.idSite)
              ? DashboardPage.routeName
              : HomePageTrial.routeName;

          print('route name : $targetRoute');

          final arguments = (userIdSite == officeChitra.idSite)
              ? null
              : {
                  'idSite': userIdSite,
                  'isSPM': isSPM == '1',
                  'isCTS': isCTS == '1',
                  'isPG': isSitePGInList,
                };

          emit(
            AuthenticationSuccessState(
              targetRoute: targetRoute,
              arguments: arguments,
            ),
          );
        } else {
          emit(
            AuthenticationSuccessState(
              targetRoute: DashboardPage.routeName,
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        emit(
          AuthenticationErrorState(
            errorMessage: e.message ?? '',
          ),
        );
      } catch (e) {
        emit(
          AuthenticationErrorState(
            errorMessage: e.toString(),
          ),
        );
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
