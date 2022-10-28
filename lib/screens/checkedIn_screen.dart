import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class CheckedInScreen extends StatefulWidget {
  String dateTime,
      country,
      district,
      image_url,
      lat,
      long,
      postal_code,
      deviceId;

  CheckedInScreen(
      {Key? key,
      required this.dateTime,
      required this.country,
      required this.district,
      required this.image_url,
      required this.lat,
      required this.long,
      required this.postal_code,
      required this.deviceId})
      : super(key: key);

  @override
  State<CheckedInScreen> createState() => _CheckedInScreenState();
}

class _CheckedInScreenState extends State<CheckedInScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Checked In Time"),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  "Current Checkin Time",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 10,
                ),
                Image.file(
                  File(widget.image_url),
                  height: 300,
                ),
                const SizedBox(
                  height: 20,
                ),
                Text("Date time : ${widget.dateTime}"),
                const SizedBox(
                  height: 10,
                ),
                Text("Country ${widget.country}"),
                const SizedBox(
                  height: 10,
                ),
                Text("District : ${widget.district}"),
                const SizedBox(
                  height: 10,
                ),
                Text("Postal Code : ${widget.postal_code}"),
                const SizedBox(
                  height: 10,
                ),
                Text("Lat : ${widget.lat}"),
                const SizedBox(
                  height: 10,
                ),
                Text("Long : ${widget.long}"),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  "Past Checkin Time",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection(widget.deviceId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text("There is no past check in time");
                      return Expanded(
                        child: ListView(
                            shrinkWrap: true,
                            children: getPastCheckInTime(snapshot)),
                      );
                    }),
              ],
            ),
          ),
        ));
  }

  getPastCheckInTime(AsyncSnapshot<QuerySnapshot> snapshot) {
    return snapshot.data?.docs.map((doc) {
     // ListTile(title:  Text(doc["checkin_timestamp"]), subtitle:  Text(doc["district"].toString()))
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(doc['image_url']),
              backgroundColor: Colors.red.shade800,
              radius: 30,
            ),
            Column(
              children: [
                Text("TimeStamp : ${doc["checkin_timestamp"]}"),
                const SizedBox(
                  height: 10,
                ),
                Text("Country : ${doc["country"]}"),
                const SizedBox(
                  height: 10,
                ),
                Text("District : ${doc["district"]}"),
                const SizedBox(
                  height: 10,
                ),
                Text("Postal Code : ${doc["postal_code"]}"),
                const SizedBox(
                  height: 10,
                ),
                Text("Lat :  ${doc["lat"]}"),
                const SizedBox(
                  height: 10,
                ),
                Text("Long :  ${doc["long"]}"),
                const Divider(
                  color: Colors.black,
                  height: 20,
                  thickness: 2,
                  indent: 10,
                  endIndent: 10,
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}
