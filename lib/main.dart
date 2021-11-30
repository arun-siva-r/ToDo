import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To Do App',
      debugShowCheckedModeBanner: false,
      home: _ToDoApp(),
    );
  }
}

class _ToDoApp extends StatefulWidget {
  @override
  ToDoAppState createState() => ToDoAppState();
}

class ToDoAppState extends State<_ToDoApp> {
  final List<_ToDo> _listItems = <_ToDo>[];
  var fireBaseInstance = FirebaseDatabase.instance.reference();
  DataSnapshot? _querySnapshot;
  late Query _toDoQuery;

  @override
  void initState() {
    _toDoQuery = fireBaseInstance.child("ToDoList").orderByKey();
    getDataFromDatabase().then((results) {
      setState(() {
        if (results != null) {
          _querySnapshot = results;

          Map<dynamic, dynamic>? values = _querySnapshot!.value;
          List<dynamic>? key = values?.keys.toList();
          if (values != null && key != null) {
            for (int i = 0; i < key.length; i++) {
              var data = values[key[i]];
              _listItems.add(_ToDo.map(data, key[i]));
              _listItems.sort((_ToDo item1, _ToDo item2) {
                int value = -1, value2 = -1;
                if(item1.status == _ToDoStatus.done){
                  value = 1;
                }else if(item2.status == _ToDoStatus.done){
                  value2 = 1;
                }

                return value.compareTo(value2);
              });
            }
          }
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }


  getDataFromDatabase() async {
    var getValue = await _toDoQuery.once();
    return getValue;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _querySnapshot?.value == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ReorderableListView.builder(
                itemCount: _listItems.length,
                onReorder: (int oldIndex, int newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    _ToDo item = _listItems.removeAt(oldIndex);
                    if (newIndex - 1 >= 0 &&
                        _listItems[newIndex - 1].status == _ToDoStatus.done) {
                      item = item.copyWith(status: _ToDoStatus.done);
                      fireBaseInstance
                          .child("ToDoList")
                          .child(item.key!)
                          .update({
                        'Status': 'Done',
                      });
                    }
                    _listItems.insert(newIndex, item);
                  });
                },
                itemBuilder: (BuildContext context, int index) {
                  final _ToDo item = _listItems[index];
                  if (item.status == _ToDoStatus.pending) {
                    return Dismissible(
                      key: Key(item.key!),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: <Color>[
                              Colors.orange,
                              Colors.orangeAccent,
                              Colors.deepOrange,
                              Colors.deepOrangeAccent
                            ]),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 5)
                            ]),
                        child: Text(
                          item.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      background: Container(
                        alignment: Alignment.centerLeft,
                        color: Colors.black,
                        child: const Icon(
                          Icons.done,
                          size: 25,
                          color: Colors.white,
                        ),
                      ),
                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        color: Colors.black,
                        child: const Icon(
                          Icons.close,
                          size: 25,
                          color: Colors.red,
                        ),
                      ),
                      onDismissed: (DismissDirection direction) {
                        _listItems.removeAt(index);
                        fireBaseInstance
                            .child("ToDoList")
                            .child(item.key!)
                            .remove();
                        setState(() {});
                      },
                      confirmDismiss: (DismissDirection direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          setState(() {
                            _listItems.removeAt(index);
                            _listItems
                                .add(item.copyWith(status: _ToDoStatus.done));
                            fireBaseInstance
                                .child("ToDoList")
                                .child(item.key!)
                                .update({
                              'Status': 'Done',
                            });
                          });

                          return false;
                        }

                        return true;
                      },
                    );
                  } else {
                    return Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      key: UniqueKey(),
                      color: Colors.black,
                      child: Text(
                        item.title,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            decoration: TextDecoration.lineThrough),
                      ),
                    );
                  }
                }),
      ),
    );
  }
}

class _ToDo {
  _ToDo({this.title = '', this.date, this.status = _ToDoStatus.pending, this.key});

  final String title;
  final String? date;
  final _ToDoStatus status;
  String? key;

  _ToDo copyWith({String? title, String? date, _ToDoStatus? status, String? key}) {
    return _ToDo(
        title: title ?? this.title,
        date: date ?? this.date,
        key: key?? this.key,
        status: status ?? this.status);
  }

  static _ToDo fromSnapShot(DataSnapshot dataSnapshot) {
    return _ToDo(
        title: dataSnapshot.value['Title'],
        date: dataSnapshot.value['Date'],
        key: dataSnapshot.key,
        status: dataSnapshot.value['Status'] == 'Pending'
            ? _ToDoStatus.pending
            : _ToDoStatus.done);
  }

  static _ToDo map(dynamic data, String key) {
    return _ToDo(
        title: data['Title'],
        date: data['Date'],
        key: key,
        status: data['Status'] == 'Pending'
            ? _ToDoStatus.pending
            : _ToDoStatus.done);
  }
}

enum _ToDoStatus { done, pending }
