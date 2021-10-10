import 'package:flutter/material.dart';
import 'package:todo/data/database.dart';
import 'package:todo/data/util.dart';
import 'package:todo/write.dart';

import 'data/todo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final dbHelper = DatabaseHelper.instance;

  int selectIndex = 0;

  @override
  void initState() {
    print('++++++++');
    setTodayTodos();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          child: AppBar(),
          preferredSize: Size.fromHeight(0)), // appBar 가 아예 없으면 맨 위에서부터 시작함
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addTodo();
        },
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      body: getPage(),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.today_outlined), label: "오늘"),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined), label: "기록"),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: "더보기"),
        ],
        currentIndex: selectIndex,
        onTap: (idx) {
          if (idx == 1) {
            getAllTodo();
          }

          setState(() {
            selectIndex = idx;
          });
        },
      ),
    );
  }

  Widget getPage() {
    if (selectIndex == 0) {
      return getMain();
    } else {
      return getHistory();
    }
  }

  Widget getMain() {
    return ListView.builder(
      // 기기마다 화면 크기가 달라서 리스트뷰로 가장 바깥을 감싸주는게 좋음
      itemBuilder: (ctx, idx) {
        if (idx == 0) {
          return Container(
            child: Text(
              "오늘하루",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            margin: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          );
        } else if (idx == 1) {
          List<Todo> undones = todayTodos.where((t) {
            return t.done == 0;
          }).toList();
          return Container(
            child: Column(
              children: List.generate(undones.length, (_idx) {
                Todo t = undones[_idx];

                return InkWell(
                  child: TodoCardWidget(t: t),
                  onTap: () async {
                    setState(() {
                      if (t.done == 0) {
                        t.done = 1;
                      } else {
                        t.done = 0;
                      }
                    });

                    await dbHelper.insertTodo(t);
                  },
                  onLongPress: () {
                    modifyTodo(t);
                  },
                );
              }),
            ),
          );
        } else if (idx == 2) {
          return Container(
            child: Text(
              "완료된 하루",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            margin: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          );
        } else if (idx == 3) {
          List<Todo> dones = todayTodos.where((t) {
            return t.done == 1;
          }).toList();

          return Container(
            child: Column(
              children: List.generate(dones.length, (_idx) {
                Todo t = dones[_idx];
                return InkWell(
                  child: TodoCardWidget(t: t),
                  onTap: () async {
                    setState(() {
                      if (t.done == 0) {
                        t.done = 1;
                      } else {
                        t.done = 0;
                      }
                    });

                    await dbHelper.insertTodo(t);
                  },
                  onLongPress: () {
                    modifyTodo(t);
                  },
                );
              }),
            ),
          );
        }

        return Container();
      },
      itemCount: 4,
    );
  }

  List<Todo> allTodo = [];

  Widget getHistory() {
    setDistinctTodoDates();
    print('distinctTodoDates: $distinctTodoDates');
    setTodosByDate();
    int countOfDate = getCountOfDates();
    print('###########');
    print(countOfDate);
    return ListView.builder(
      itemBuilder: (ctx, idx) {
        print('=========');
        print('idx: $idx');
        print(allTodo);
        DateTime date = distinctTodoDates[idx];
        print('date: $date');
        print(todosByDate);
        List<Todo> todos = todosByDate[date] ?? [];
        print(todos);
        return Container(
          child: Column(
            children: List.generate(todos.length + 1, (_idx) {
              print('idx@@@@@@@@@@@@');
              print(_idx);
              if (_idx == 0) {
                print('0!!!!!!!!!!!!');
                return Text(
                  date.toString(),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                );
              } else {
                Todo t = todos[_idx - 1];
                return InkWell(
                  child: TodoCardWidget(t: t),
                  onTap: () async {
                    setState(() {
                      if (t.done == 0) {
                        t.done = 1;
                      } else {
                        t.done = 0;
                      }
                    });

                    await dbHelper.insertTodo(t);
                  },
                  onLongPress: () {
                    modifyTodo(t);
                  },
                );
              }
            }),
          ),
        );
      },
      itemCount: countOfDate,
    );
  }

  // 투두 추가
  void addTodo() async {
    // async: 비동기 함수라는걸 알려줘서 await 사용가능
    // 화면 이동
    // await으로 todo값을 넘겨줄때까지 함수 실행을 기다려야함
    print('addTodo');
    Todo todo = await Navigator.of(context).push(MaterialPageRoute(
        builder: (ctx) => TodoWritePage(
            todo: Todo(
                title: "",
                color: Color(0xFF80d3f4).value,
                memo: "",
                done: 0,
                category: "운동",
                // date: Utils.getFormatTime(DateTime.now().subtract(Duration(days: 3)))))));
                date: Utils.getFormatTime(DateTime.now())))));
    print(todo);
    setTodayTodos();
  }

  // 투두 수정
  void modifyTodo(t) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (ctx) => TodoWritePage(todo: t)));
    setTodayTodos();
  }

  // 오늘의 투두리스트 표현하는
  List<Todo> todayTodos = [];

  // 날짜별 투두리스트 표현하는
  var todosByDate = new Map<DateTime, List<Todo>>();

  // 날짜들
  List<DateTime> distinctTodoDates = [];

  void setTodayTodos() async {
    todayTodos =
        await dbHelper.getTodoByDate(Utils.getFormatTime(DateTime.now()));
    setState(() {});
  }

  void setTodosByDate() async {
    for (var i = 0; i < distinctTodoDates.length; i++) {
      DateTime date = distinctTodoDates[i];
      todosByDate[date] =
          await dbHelper.getTodoByDate(Utils.getFormatTime(date));
    }
    setState(() {});
  }

  void getAllTodo() async {
    allTodo = await dbHelper.getAllTodo();
    setState(() {});
  }

  int getCountOfDates() {
    return distinctTodoDates.length;
  }

  void setDistinctTodoDates() {
    List<DateTime> dates = [];
    for (var todo in allTodo) {
      dates.add(Utils.numToDateTime(todo.date));
    }
    distinctTodoDates = dates.toSet().toList();
  }
}

class TodoCardWidget extends StatelessWidget {
  final Todo t;

  TodoCardWidget({Key? key, required this.t}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int now = Utils.getFormatTime(DateTime.now());
    DateTime time = Utils.numToDateTime(t.date);

    return Container(
      decoration: BoxDecoration(
          color: Color(t.color), borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.title,
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                t.done == 0 ? "미완료" : "완료",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          Container(height: 8),
          Text(t.memo, style: TextStyle(color: Colors.white)),
          now == t.date
              ? Container()
              : Text(
                  "${time.month}월 ${time.day}일",
                  style: TextStyle(color: Colors.white),
                )
        ],
      ),
    );
  }
}
