import '../../core/styles/asset_path.dart';
import '../../core/styles/color.dart';
import '../../core/styles/text_manager.dart';
import '../../core/widgets/appbar_widget.dart';
import '../../core/widgets/button_widget.dart';
import '../../core/widgets/input_form_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class FeedbackPage extends StatefulWidget {
  static const routeName = '/feedback-page';
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  TextEditingController feedbackCtrl = TextEditingController(text: '');

  final ScrollController _scrollController = ScrollController();

  double rating = 5;

  void _scrollToBottom() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: appBarWidget('Give Your Feedback', context),
      body: SafeArea(
          child: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom * 0.1,
          ),
          child: Container(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(
                    height: 24,
                  ),
                  SizedBox(
                      width: 200,
                      height: 200,
                      child: Image.asset('$imagePath/feedback_image.png')),
                  const SizedBox(
                    height: 24,
                  ),
                  Card(
                    elevation: 2,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24),
                      child: ListView(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        // crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Please rate your experience',
                            style: getBlackTextStyle(
                                fontSize: 16, fontWeight: w500),
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          RatingBar.builder(
                            initialRating: 5.0,
                            itemCount: 5,
                            itemPadding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.02),
                            itemBuilder: (context, index) {
                              switch (index) {
                                case 0:
                                  return Icon(
                                    Icons.sentiment_very_dissatisfied,
                                    color: Colors.red,
                                  );
                                case 1:
                                  return Icon(
                                    Icons.sentiment_dissatisfied,
                                    color: Colors.redAccent,
                                  );
                                case 2:
                                  return Icon(
                                    Icons.sentiment_neutral,
                                    color: Colors.amber,
                                  );
                                case 3:
                                  return Icon(
                                    Icons.sentiment_satisfied,
                                    color: Colors.lightGreen,
                                  );
                                case 4:
                                  return Icon(
                                    Icons.sentiment_very_satisfied,
                                    color: Colors.green,
                                  );
                              }
                              return SizedBox();
                            },
                            onRatingUpdate: (rating) {
                              setState(() {
                                this.rating = rating;
                              });
                              print(rating);
                            },
                          ),
                          const SizedBox(
                            height: 32,
                          ),
                          Text(
                            'Care to share more about it',
                            style: getBlackTextStyle(),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          InkWell(
                            onTap: () {
                              _scrollToBottom();
                            },
                            child: InputFormWidget(
                                controller: feedbackCtrl,
                                isLargeInput: true,
                                hint: 'Feedback...'),
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          ButtonWidget(
                              name: Text(
                                'Send',
                                style: getWhiteTextStyle(),
                              ),
                              function: () {
                                try {
                                  firestore.collection('feedback').add({
                                    'user': auth.currentUser!.email,
                                    'rate': rating.toString(),
                                    'message': feedbackCtrl.text,
                                  });
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          backgroundColor: green00968A,
                                          content: Text(
                                            'Successful send data',
                                            style: getWhiteTextStyle(),
                                          )));
                                } catch (e) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          backgroundColor: Colors.red,
                                          content: Text(
                                            'Failed send data',
                                            style: getWhiteTextStyle(),
                                          )));
                                }
                              })
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )),
    );
  }
}
