import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  String _newText = '';
  var fireBaseInstance = FirebaseDatabase.instance.reference();
  DataSnapshot? _querySnapshot;
  late Query _toDoQuery;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

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
                if (item1.status == _ToDoStatus.done) {
                  value = 1;
                } else if (item2.status == _ToDoStatus.done) {
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
            : RefreshIndicator(
                child: AnimatedList(
                    key: _listKey,
                    initialItemCount: _listItems.length,
                    itemBuilder: (BuildContext context, int index,
                        Animation<double> animation) {
                      return _draggableWidget(context, index, animation);
                    }),
                onRefresh: () async {
                  _newText = '';
                  return Future.delayed(const Duration(microseconds: 1), () {
                    final dbRef = fireBaseInstance.child("ToDoList");
                    dbRef.push().set({
                      "Title": '',
                      "Date": '',
                      "Status": 'Edit',
                    });
                    dbRef.get().then((value) {
                      Map<dynamic, dynamic> values = value.value;
                      List<dynamic> key = values.keys.toList();
                      for (int i = 0; i < key.length; i++) {
                        if (values[key[i]]['Status'] == 'Edit') {
                          _listItems.insert(
                              0,
                              _ToDo(
                                  title: '',
                                  status: _ToDoStatus.edit,
                                  key: key[i]));
                          break;
                        }
                      }
                      _listKey.currentState?.insertItem(0);
                    });
                  });
                }),
      ),
    );
  }

  Widget _draggableWidget(
      BuildContext context, int index, Animation<double> animation) {
    final _ToDo toDo = _listItems[index];
    final Widget tile = Dismissible(
      key: Key(toDo.key!),
      child: Container(
        height: toDo.date != null && toDo.date!.isNotEmpty ? 70 : 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        decoration: const BoxDecoration(
            gradient: LinearGradient(colors: <Color>[
              Colors.orange,
              Colors.orangeAccent,
              Colors.deepOrange,
              Colors.deepOrangeAccent
            ]),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              toDo.title,
              style: const TextStyle(color: Colors.white),
            ),
            toDo.date != null && toDo.date!.isNotEmpty
                ? Text(
                    toDo.date!,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  )
                : Container()
          ],
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
        _listKey.currentState?.removeItem(
            index,
            (context, animation) => const SizedBox(
                  width: 0,
                  height: 0,
                ));
        fireBaseInstance.child("ToDoList").child(toDo.key!).remove();
        setState(() {});
      },
      confirmDismiss: (DismissDirection direction) async {
        if (direction == DismissDirection.startToEnd) {
          setState(() {
            _listItems.removeAt(index);
            _listItems.add(toDo.copyWith(status: _ToDoStatus.done));
            fireBaseInstance.child("ToDoList").child(toDo.key!).update({
              'Status': 'Done',
            });
          });

          return false;
        }

        return true;
      },
    );

    Draggable draggable = LongPressDraggable<_ToDo>(
        data: toDo,
        axis: Axis.vertical,
        maxSimultaneousDrags: 1,
        child: tile,
        childWhenDragging: tile,
        feedback: Material(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
            child: tile,
          ),
          elevation: 4.0,
        ));

    return DragTarget<_ToDo>(onWillAccept: (dynamic data) {
      return true;
    }, onAccept: (dynamic data) {
      int oldIndex = _listItems.indexOf(data);
      setState(() {
        // if (oldIndex < index) {
        //   index -= 1;
        // }
        _ToDo item = _listItems.removeAt(oldIndex);
        if (index - 1 >= 0 &&
            _listItems[index - 1].status == _ToDoStatus.done) {
          item = item.copyWith(status: _ToDoStatus.done);
          fireBaseInstance.child("ToDoList").child(item.key!).update({
            'Status': 'Done',
          });
        }
        _listItems.insert(index, item);
      });
    }, builder: (BuildContext context, List<dynamic> candidateData,
        List<dynamic> rejectedData) {
      if (toDo.status == _ToDoStatus.done) {
        return Container(
          height: toDo.date != null && toDo.date!.isNotEmpty ? 70 : 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          key: Key(toDo.key!),
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(toDo.title,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      decoration: TextDecoration.lineThrough)),
              toDo.date != null && toDo.date!.isNotEmpty
                  ? Text(
                      toDo.date!,
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          decoration: TextDecoration.lineThrough),
                    )
                  : Container()
            ],
          ),
        );
      } else if (toDo.status == _ToDoStatus.edit) {
        return SizeTransition(
          axis: Axis.vertical,
          sizeFactor: animation,
          child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: <Color>[
                    Colors.orange,
                    Colors.orangeAccent,
                    Colors.deepOrange,
                    Colors.deepOrangeAccent
                  ]),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    controller: TextEditingController(text: _newText),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (String value) {
                      _ToDo _editableItem = _listItems[0];
                      _newText = value;
                      _ToDoStatus status = _ToDoStatus.edit;
                      if (_editableItem.date != null) {
                        status = _ToDoStatus.pending;
                      }

                      _listItems.remove(_editableItem);
                      _listItems.insert(
                          0,
                          _editableItem.copyWith(
                              title: _newText, status: status));
                      fireBaseInstance
                          .child("ToDoList")
                          .child(_editableItem.key!)
                          .update({
                        'Status':
                            status == _ToDoStatus.pending ? 'Pending' : 'Edit',
                        'Title': _newText,
                      });
                    },
                    autofocus: _newText.isEmpty,
                    decoration: const InputDecoration(
                        border: InputBorder.none, isCollapsed: true),
                  ),
                  TextButton(
                      onPressed: () async {
                        final DateTime? date = await showDialog<DateTime?>(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              DateTime selectedDate = DateTime.now();
                              return Center(
                                  child: SizedBox(
                                width: 350,
                                height: 400,
                                child: Card(
                                  shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(4))),
                                  child: Column(
                                    children: <Widget>[
                                      Expanded(
                                        child: CupertinoDatePicker(
                                          onDateTimeChanged: (DateTime date) {
                                            selectedDate = date;
                                          },
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: <Widget>[
                                          TextButton(
                                            child: const Text(
                                              'Cancel',
                                              style:
                                                  TextStyle(color: Colors.blue),
                                            ),
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(selectedDate);
                                            },
                                          ),
                                          TextButton(
                                            child: const Text(
                                              'Okay',
                                              style:
                                                  TextStyle(color: Colors.blue),
                                            ),
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(selectedDate);
                                            },
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ));
                            });

                        _ToDo _editableItem = _listItems[0];
                        _ToDoStatus status = _ToDoStatus.edit;
                        if (_editableItem.title.isNotEmpty && date != null) {
                          status = _ToDoStatus.pending;
                        }

                        _listItems.remove(_editableItem);
                        final String dateString = _getDateString(date!);
                        _listItems.insert(
                            0,
                            _editableItem.copyWith(
                                date: dateString, status: status));
                        fireBaseInstance
                            .child("ToDoList")
                            .child(_editableItem.key!)
                            .update({
                          'Status': status == _ToDoStatus.pending
                              ? 'Pending'
                              : 'Edit',
                          'Date': dateString,
                        });
                        setState(() {});
                      },
                      child: Text(
                        toDo.date != null && toDo.date!.isNotEmpty
                            ? _listItems[0].date!
                            : 'Add Reminder',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ))
                ],
              )),
        );
      }
      return draggable;
    });
  }

  String _getDateString(DateTime date) {
    final DateTime today = DateTime.now();
    return _isSameDate(date, today)
        ? 'Today at' + DateFormat('h:mm a').format(date)
        : _isSameDate(date, today.subtract(const Duration(days: 1)))
            ? 'Yesterday at' + DateFormat('h:mm a').format(date)
            : _isSameDate(date, today.add(const Duration(days: 1)))
                ? 'Tomorrow at' + DateFormat('h:mm a').format(date)
                : DateFormat('EEE, dd MMM h:mm a').format(date);
  }

  bool _isSameDate(DateTime date, DateTime date2) {
    return date.day == date2.day &&
        date.month == date2.month &&
        date.year == date2.year;
  }
}

class _ToDo {
  _ToDo(
      {this.title = '',
      this.date,
      this.status = _ToDoStatus.pending,
      this.key});

  final String title;
  final String? date;
  final _ToDoStatus status;
  String? key;

  _ToDo copyWith(
      {String? title, String? date, _ToDoStatus? status, String? key}) {
    return _ToDo(
        title: title ?? this.title,
        date: date ?? this.date,
        key: key ?? this.key,
        status: status ?? this.status);
  }

  static _ToDo fromSnapShot(DataSnapshot dataSnapshot) {
    return _ToDo(
        title: dataSnapshot.value['Title'],
        date: dataSnapshot.value['Date'],
        key: dataSnapshot.key,
        status: dataSnapshot.value['Status'] == 'Pending'
            ? _ToDoStatus.pending
            : dataSnapshot.value['Status'] == 'Edit'
                ? _ToDoStatus.edit
                : _ToDoStatus.done);
  }

  static _ToDo map(dynamic data, String key) {
    return _ToDo(
        title: data['Title'],
        date: data['Date'],
        key: key,
        status: data['Status'] == 'Pending'
            ? _ToDoStatus.pending
            : data['Status'] == 'Edit'
                ? _ToDoStatus.edit
                : _ToDoStatus.done);
  }
}

enum _ToDoStatus { done, pending, edit }
