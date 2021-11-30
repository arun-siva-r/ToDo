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

  @override
  void initState() {
    super.initState();
    _getToDoList();
  }

  void _getToDoList() {
    _listItems.add(_ToDo(title: 'Swipe right To Complete'));
    _listItems.add(_ToDo(title: 'Swipe left to remove'));
    _listItems.add(_ToDo(title: 'Tap and hold to pick up'));
    _listItems.add(_ToDo(title: 'Pull down to create new one'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ReorderableListView.builder(
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
                }
                _listItems.insert(newIndex, item);
              });
            },
            itemBuilder: (BuildContext context, int index) {
              final _ToDo item = _listItems[index];
              if (item.status == _ToDoStatus.pending) {
                return Dismissible(
                  key: Key(item.title),
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
                    setState(() {});
                  },
                  confirmDismiss: (DismissDirection direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      setState(() {
                        _listItems.removeAt(index);
                        _listItems.add(item.copyWith(status: _ToDoStatus.done));
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
                  key: Key(item.title),
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
  _ToDo({this.title = '', this.date, this.status = _ToDoStatus.pending});

  final String title;
  final DateTime? date;
  final _ToDoStatus status;

  _ToDo copyWith({String? title, DateTime? date, _ToDoStatus? status}) {
    return _ToDo(
        title: title ?? this.title,
        date: date ?? this.date,
        status: status ?? this.status);
  }
}

enum _ToDoStatus { done, pending }
