import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:quick_task_sukriti/screens/register.dart';
import 'package:quick_task_sukriti/screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const keyApplicationId = 'HUTQem8fvt6L7YGR6TwgGUYhzwXv5dFl2YPXBe0C';
  const keyClientKey = 'jIVWNoaUn6zpKHbGw5Oya9f30Cn1wMEp72wBlrQg';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(
    keyApplicationId,
    keyParseServerUrl,
    clientKey: keyClientKey,
    autoSendSessionId: true,
    liveQueryUrl: 'mybitsassignment.b4a.io',
    debug: true,
  );
  final currentUser = await ParseUser.currentUser();
  Widget initialScreen = LoginPage();

  runApp(MaterialApp(
      home: initialScreen,
      debugShowCheckedModeBanner: false,
      theme: new ThemeData(
        scaffoldBackgroundColor: Colors.green[100],
        snackBarTheme: SnackBarThemeData(
          actionTextColor: Colors.white,
        ),
      )));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<ParseObject> taskList = [];
  late StreamController<List<ParseObject>> streamController;
  late LiveQuery liveQuery;
  late Subscription<ParseObject> subscription;
  Color _deleteIconColor = Colors.red;
  bool showCompletedTasks = true;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    streamController = StreamController<List<ParseObject>>();
    liveQuery = LiveQuery(debug: true);
    getTaskList();
    startLiveQuery();
  }

  void startLiveQuery() async {
    final QueryBuilder<ParseObject> queryTask =
        QueryBuilder<ParseObject>(ParseObject('Task'))
          ..orderByDescending('completedAt')
          ..orderByDescending('createdAt')
          ..setAmountToSkip(0);

    subscription = await liveQuery.client.subscribe(queryTask);

    subscription.on(LiveQueryEvent.create, (value) {
      debugPrint('*** CREATE ***: $value ');
      taskList.add(value);
      streamController.add(taskList);
    });

    subscription.on(LiveQueryEvent.update, (value) {
      debugPrint('*** UPDATE ***: $value ');
      taskList[taskList
          .indexWhere((element) => element.objectId == value.objectId)] = value;
      streamController.add(taskList);
    });

    subscription.on(LiveQueryEvent.delete, (value) {
      debugPrint('*** DELETE ***: $value ');
      taskList.removeWhere((element) => element.objectId == value.objectId);
      streamController.add(taskList);
    });
  }

  void cancelLiveQuery() async {
    liveQuery.client.unSubscribe(subscription);
  }

  Future<void> saveTask(
      String title, String description, DateTime dueDate) async {
    final task = ParseObject('Task')
      ..set('title', title)
      ..set('description', description)
      ..set('done', false)
      ..set('dueDate', dueDate);
    await task.save();
  }

  Future<void> getTaskList() async {
    setState(() {
      taskList.clear();
    });

    final QueryBuilder<ParseObject> queryTask =
        QueryBuilder<ParseObject>(ParseObject('Task'))
          ..orderByDescending('completedAt')
          ..orderByDescending('createdAt')
          ..setAmountToSkip(0);

    final ParseResponse apiResponse = await queryTask.query();

    if (apiResponse.success && apiResponse.results != null) {
      taskList =
          List<ParseObject>.from(apiResponse.results as List<ParseObject>);
      streamController.add(taskList);
    }
  }

  Future<void> updateTask(String id, bool done) async {
    var task = ParseObject('Task')..objectId = id;

    if (done) {
      // Set the completed timestamp when the task is marked as done
      task
        ..set('done', true)
        ..set('completedAt', DateTime.now());
    } else {
      task..set('done', false);
    }

    await task.save();
    getTaskList();
  }

  Future<void> deleteTask(String id) async {
    var task = ParseObject('Task')..objectId = id;
    await task.delete();
    getTaskList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quick Task",
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: Colors.green[700],
        centerTitle: true,
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.filter_list),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  title: Text("Completed Tasks"),
                  trailing: Checkbox(
                    value: showCompletedTasks,
                    onChanged: (value) {
                      setState(() {
                        showCompletedTasks = value!;
                        getTaskList();
                        Navigator.pop(context);
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 18,
          ),
          Center(
            child: const Text('Your Shortcut to Success!',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black54)),
          ),
          SizedBox(
            height: 20,
          ),
          Center(
            child: const Text('Name: Sukriti Dhar',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ),
          Center(
            child: const Text('Student ID: 2021mt70511',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ),
          SizedBox(
            height: 20,
          ),
          Expanded(
            child: StreamBuilder<List<ParseObject>>(
              stream: streamController.stream,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return const Center(
                      child: Text("Welcome to Quick Task"),
                    );
                  default:
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("Error..."),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text("Loading..."),
                      );
                    } else {
                      // Filter tasks based on completion status
                      final filteredTasks = snapshot.data!
                          .where((task) =>
                              showCompletedTasks || !task.get<bool>('done')!)
                          .toList();

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(top: 10.0),
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                final varTask = filteredTasks[index];
                                final varTitle = varTask.get<String>('title');
                                final varDescription =
                                    varTask.get<String>('description');
                                final varDone =
                                    varTask.get<bool>('done') ?? false;
                                final dueAt = varTask.get<DateTime>('dueDate');
                                final createdAt =
                                    varTask.get<DateTime>('createdAt');
                                final completedAt =
                                    varTask.get<DateTime>('completedAt');

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditTaskScreen(
                                            taskId: varTask.objectId!,
                                            initialTitle:
                                                varTask.get<String>('title')!,
                                            initialDescription: varTask
                                                .get<String>('description')!,
                                            dueDate: varTask
                                                .get<DateTime>('dueDate')!),
                                      ),
                                    ).then((value) {
                                      if (value == true) {
                                        getTaskList();
                                      }
                                    });
                                  },
                                  child: ListTile(
                                    title: Text(varTitle ?? ''),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(varDescription ?? ''),
                                        Text('Due At: ${dueAt?.toString()}'),
                                      ],
                                    ),
                                    leading: AnimatedContainer(
                                      duration: Duration(milliseconds: 500),
                                      curve: Curves.easeInOut,
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: varDone
                                            ? const Color.fromRGBO(
                                                76, 175, 80, 1)
                                            : const Color.fromRGBO(
                                                255, 0, 38, 255),
                                      ),
                                      child: Icon(
                                        varDone ? Icons.check : Icons.error,
                                        color: Colors.green,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Switch(
                                          value: varDone,
                                          onChanged: (value) async {
                                            await updateTask(
                                                varTask.objectId!, !value);
                                          },
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            await deleteTask(varTask.objectId!);
                                            const snackBar = SnackBar(
                                              content: Text("Task deleted!"),
                                              backgroundColor: Colors.green,
                                              duration: Duration(seconds: 2),
                                            );
                                            ScaffoldMessenger.of(context)
                                              ..removeCurrentSnackBar()
                                              ..showSnackBar(snackBar);
                                          },
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: AnimatedContainer(
                                              duration:
                                                  Duration(milliseconds: 300),
                                              padding: EdgeInsets.all(8.0),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _deleteIconColor,
                                              ),
                                              child: Icon(
                                                Icons.delete,
                                                color: Colors.white,
                                              ),
                                            ),
                                            onEnter: (_) {
                                              setState(() {
                                                _deleteIconColor = Colors.red;
                                              });
                                            },
                                            onExit: (_) {
                                              setState(() {
                                                _deleteIconColor = Colors.red;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }
                }
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        foregroundColor: Colors.white,
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen()),
          ).then((value) {
            if (value == true) {
              getTaskList();
            }
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    cancelLiveQuery();
    streamController.close();
    super.dispose();
  }
}

class EditTaskScreen extends StatefulWidget {
  final String taskId;
  final String initialTitle;
  final String initialDescription;
  final DateTime dueDate;

  const EditTaskScreen({
    required this.taskId,
    required this.initialTitle,
    required this.initialDescription,
    required this.dueDate,
    Key? key,
  }) : super(key: key);

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController taskController;
  late TextEditingController descriptionController;
  late TextEditingController dateController;

  @override
  void initState() {
    super.initState();
    taskController = TextEditingController(text: widget.initialTitle);
    descriptionController =
        TextEditingController(text: widget.initialDescription);
    dateController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Quick Task',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          backgroundColor: Colors.green[700],
          centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 2,
            ),
            Center(
              child: const Text('Your Shortcut to Success!',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black54)),
            ),
            SizedBox(
              height: 20,
            ),
            Center(
              child: const Text('Name: Sukriti Dhar',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ),
            Center(
              child: const Text('Student ID: 2021mt70511',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ),
            SizedBox(
              height: 20,
            ),
            Center(
              child: const Text('Edit',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: Colors.black)),
            ),
            SizedBox(
              height: 26,
            ),
            TextField(
              autocorrect: true,
              textCapitalization: TextCapitalization.sentences,
              controller: taskController,
              decoration: const InputDecoration(
                labelText: "Task Title",
              ),
            ),
            TextField(
              autocorrect: true,
              textCapitalization: TextCapitalization.sentences,
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Task Description",
              ),
            ),
            TextFormField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  hintText: 'YYYY-MM-DD',
                ),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a due date';
                  }
                  return null;
                },
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      dateController.text =
                          pickedDate.toString().substring(0, 10);
                    });
                  }
                }),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
              ),
              onPressed: () async {
                await saveTask(
                    widget.taskId,
                    taskController.text,
                    descriptionController.text,
                    DateTime.parse(dateController.text));
                Navigator.pop(context, true);
              },
              child: const Text("SAVE",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveTask(
      String taskId, String title, String description, DateTime dueDate) async {
    final task = ParseObject('Task')
      ..objectId = taskId
      ..set('title', title)
      ..set('description', description)
      ..set('done', false)
      ..set('dueDate', dueDate);
    await task.save();
  }
}

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({Key? key}) : super(key: key);

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final taskController = TextEditingController();
  final descriptionController = TextEditingController();
  final dateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Quick Task',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          backgroundColor: Colors.green[700],
          centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 2,
            ),
            Center(
              child: const Text('Your Shortcut to Success!',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black54)),
            ),
            SizedBox(
              height: 20,
            ),
            Center(
              child: const Text('Name: Sukriti Dhar',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ),
            Center(
              child: const Text('Student ID: 2021mt70511',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ),
            SizedBox(
              height: 20,
            ),
            Center(
              child: const Text('Add',
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: Colors.black)),
            ),
            SizedBox(
              height: 26,
            ),
            TextField(
              autocorrect: true,
              textCapitalization: TextCapitalization.sentences,
              controller: taskController,
              decoration: const InputDecoration(
                labelText: "Task Title",
              ),
            ),
            TextField(
              autocorrect: true,
              textCapitalization: TextCapitalization.sentences,
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Task Description",
              ),
            ),
            TextFormField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: 'Due Date',
                  hintText: 'YYYY-MM-DD',
                ),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a due date';
                  }
                  return null;
                },
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    dateController.text =
                        pickedDate.toString().substring(0, 10);
                  }
                }),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Background color
              ),
              onPressed: () async {
                await saveTask(taskController.text, descriptionController.text,
                    DateTime.parse(dateController.text));
                Navigator.pop(context, true);
              },
              child: const Text("ADD",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveTask(
      String title, String description, DateTime dueDate) async {
    final task = ParseObject('Task')
      ..set('title', title)
      ..set('description', description)
      ..set('done', false)
      ..set('dueDate', dueDate);
    await task.save();
  }
}
