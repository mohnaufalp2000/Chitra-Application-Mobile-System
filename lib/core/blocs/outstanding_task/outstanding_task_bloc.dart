import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/local_database/outstanding_task/outstanding_task_entity.dart';
import 'package:camos/main.dart';
import 'package:camos/objectbox.g.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:camos/core/services/model/outstanding_task.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

part 'outstanding_task_event.dart';
part 'outstanding_task_state.dart';

class OutstandingTaskBloc
    extends Bloc<OutstandingTaskEvent, OutstandingTaskState> {
  final Box<OutstandingTaskEntity> box = store.box<OutstandingTaskEntity>();

  OutstandingTaskBloc() : super(OutstandingTaskInitial()) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    CollectionReference taskCollection = firestore.collection('task');

    on<AddOutStandingTaskEvent>((event, emit) async {
      final connectivityResult = await Connectivity().checkConnectivity();

      final task = event.task;
      final List<String> listImage = [];
      try {
        // send ke firebase
        if (task.images!.isNotEmpty) {
          // add tire image to firebase storage
          // task.images?.forEach((image) async {
          //   final id = Uuid();
          //   final path =
          //       'task/${id.v1().substring(0, 8)}-${task.idSite}-${task.user}-${task.unit}-${task.id}';
          //   final ref = FirebaseStorage.instance.ref().child(path);
          //   UploadTask? uploadTask = ref.putFile(image);

          //   final snapshot = await uploadTask.whenComplete(() {});

          //   final url = await snapshot.ref.getDownloadURL();
          //   listImage.add(url);
          //   log('daftar image : $listImage');
          // });

          // final uploadTasks = task.images?.map((image) async {
          //   final id = Uuid();
          //   final path =
          //       'task/${id.v1().substring(0, 8)}-${task.idSite}-${task.user}-${task.unit}-${task.id}';
          //   final ref = FirebaseStorage.instance.ref().child(path);
          //   UploadTask uploadTask = ref.putFile(image);

          //   final snapshot = await uploadTask.whenComplete(() {});

          //   return await snapshot.ref.getDownloadURL();
          // });
          // final List<String> urls = await Future.wait(uploadTasks!);

          // listImage.addAll(urls);
        }

        final querySnapshot = await taskCollection
            .where('kunci_unit', isEqualTo: task.kunciUnit)
            .where('kunci_tire', isEqualTo: task.kunciTire)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Update the existing document
          final docId = querySnapshot.docs.first.id;
          await taskCollection.doc(docId).update({
            'id': task.id,
            'id_site': task.idSite,
            'user': task.user,
            'unit': task.unit,
            'serial_number': task.serialNumber,
            'condition': task.condition,
            'tire_size': task.tireSize,
            'position': task.position,
            'brand': task.brand,
            'tire_damage': task.tireDamage,
            'remarks': task.remarks,
            'rtd': task.rtd,
            'pressure': task.pressure,
            'last_update': task.lastUpdate,
            'is_done': task.isDone,
            'images': task.images,
            'sn': task.sn,
            'kunci_unit': task.kunciUnit,
            'kunci_tire': task.kunciTire,
          });
        } else {
          await taskCollection.add({
            'id': task.id,
            'id_site': task.idSite,
            'user': task.user,
            'unit': task.unit,
            'serial_number': task.serialNumber,
            'condition': task.condition,
            'tire_size': task.tireSize,
            'position': task.position,
            'brand': task.brand,
            'tire_damage': task.tireDamage,
            'remarks': task.remarks,
            'rtd': task.rtd,
            'pressure': task.pressure,
            'last_update': task.lastUpdate,
            'is_done': task.isDone,
            'images': task.images,
            'sn': task.sn,
            'kunci_unit': task.kunciUnit,
            'kunci_tire': task.kunciTire,
          });
        }

        // await taskCollection.add({
        //   'id': task.id,
        //   'id_site': task.idSite,
        //   'user': task.user,
        //   'unit': task.unit,
        //   'serial_number': task.serialNumber,
        //   'condition': task.condition,
        //   'tire_size': task.tireSize,
        //   'position': task.position,
        //   'brand': task.brand,
        //   'tire_damage': task.tireDamage,
        //   'remarks': task.remarks,
        //   'rtd': task.rtd,
        //   'pressure': task.pressure,
        //   'last_update': task.lastUpdate,
        //   'is_done': task.isDone,
        //   'images': task.images,
        //   'sn': task.sn,
        //   'kunci_unit': task.kunciUnit,
        //   'kunci_tire': task.kunciTire,
        // });

        // send ke local
        // box.put(OutstandingTaskEntity(
        //   idTask: event.task.id,
        //   idSite: event.task.idSite,
        //   user: event.task.user,
        //   unit: event.task.unit,
        //   position: event.task.position,
        //   brand: event.task.brand,
        //   serialNumber: event.task.serialNumber,
        //   tireSize: event.task.tireSize,
        //   condition: (event.task.condition)
        //       .map((category) => category.toString())
        //       .toList(),
        //   tireDamage: event.task.tireDamage,
        //   remarks: event.task.remarks,
        //   pressure: event.task.pressure,
        //   lastUpdate: event.task.lastUpdate,
        //   isDone: false,
        // ));
      } catch (e) {}
    });
    on<ReadOutStandingTaskEvent>((event, emit) {
      if (event.selectedDate.isEmpty) {
        final tasks = box.getAll();
        log('non filtered task' + tasks.toString());
        emit(OutStandingTaskLoadedState(
            initialTasks: tasks, tasks: tasks, timeStamp: DateTime.now()));
      } else {
        final tasks = box.getAll();
        final dates = event.selectedDate;
        DateFormat inputFormat = DateFormat('EEEE, d MMMM y, H:m:s');

        final formatedDates = dates.map((date) {
          DateTime inputDate = inputFormat.parse(date);
          DateFormat outputFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSS");
          String outputDateString = outputFormat.format(inputDate);
          List<String> splittedDate = outputDateString.split('T');
          return splittedDate[0];
        }).toList();

        final filteredTask = tasks.where((task) {
          List<String> splittedDate = task.lastUpdate.split('T');
          return formatedDates.contains(splittedDate[0]);
        }).toList();
        log('filtered task' + filteredTask.toString());

        // log('filtered task ${filteredTask}');

        // emit(OutStandingTaskFilteredLoadedState(tasks: filteredTask));
        emit(OutStandingTaskLoadedState(
            initialTasks: tasks,
            tasks: filteredTask,
            timeStamp: DateTime.now()));
      }
    });
    on<DeleteOutStandingTaskEvent>((event, emit) async {
      await taskCollection
          .where('id', isEqualTo: event.id)
          .get()
          .then((QuerySnapshot querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          doc.reference.update({'is_done': true});
        });
      }).catchError((error) {
        print("Error saat menghapus data: $error");
      });
    });
  }
}
