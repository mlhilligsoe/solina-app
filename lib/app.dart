import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final entryController = TextEditingController();

  User? user;

  void register() async {
    try {
      UserCredential result = await auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      setState(() => user = result.user);
    } catch (e) {
      print('Register error: $e');
    }
  }

  void login() async {
    try {
      UserCredential result = await auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      setState(() => user = result.user);
    } catch (e) {
      print('Login error: $e');
    }
  }

  void addEntry() async {
    if (user != null) {
      await firestore
          .collection('users')
          .doc(user!.uid)
          .collection('entries')
          .add({'text': entryController.text, 'timestamp': Timestamp.now()});
      entryController.clear();
    }
  }

  Stream<QuerySnapshot> getEntries() {
    return firestore
        .collection('users')
        .doc(user!.uid)
        .collection('entries')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Firestore Demo')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: user == null
              ? Column(
                  children: [
                    TextField(
                        controller: emailController,
                        decoration: InputDecoration(labelText: 'Email')),
                    TextField(
                        controller: passwordController,
                        decoration: InputDecoration(labelText: 'Password'),
                        obscureText: true),
                    Row(
                      children: [
                        ElevatedButton(
                            onPressed: register, child: Text('Register')),
                        SizedBox(width: 10),
                        ElevatedButton(onPressed: login, child: Text('Login')),
                      ],
                    )
                  ],
                )
              : Column(
                  children: [
                    Text('Logged in as: ${user!.email}'),
                    TextField(
                        controller: entryController,
                        decoration: InputDecoration(labelText: 'New Entry')),
                    ElevatedButton(
                        onPressed: addEntry, child: Text('Add Entry')),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: getEntries(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return CircularProgressIndicator();
                          return ListView(
                            children: snapshot.data!.docs.map((doc) {
                              return ListTile(
                                title: Text(doc['text']),
                                subtitle:
                                    Text(doc['timestamp'].toDate().toString()),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
