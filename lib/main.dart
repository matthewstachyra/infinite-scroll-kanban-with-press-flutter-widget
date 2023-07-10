import 'package:flutter/material.dart';
import 'dart:collection';

void main() async {
  runApp(App());
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'test',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      routes: {},
      home: Feed(),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class Feed extends StatefulWidget {
  @override
  State createState() => _FeedState();
}

////////////////////////////////////////////////////////////////////////////////

class _FeedState extends State<Feed> {
  // test: these need default values
  int verticalIndex = 0;
  int horizontalIndex = 0;

  LinkedHashMap<String, List<String>> posts =
      LinkedHashMap<String, List<String>>.from({
    'Post 1': [
      '0, 0',
      '0, 1',
      '0, 2',
      '0, 3',
    ],
    'Post 2': [
      '1, 0',
      '1, 1',
      '1, 2',
      '1, 3',
    ],
    'Post 3': [
      '2, 0',
      '2, 1',
      '2, 2',
      '2, 3',
    ],
  });

  void _updateFeedState(vindex, hindex) {
    setState(() {
      verticalIndex = vindex;
      horizontalIndex = hindex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      color: Colors.amber,
      child: Column(
        children: <Widget>[
          Kanban(
              horizontalIndex: horizontalIndex,
              verticalIndex: verticalIndex,
              updateFeedState: _updateFeedState),
          Expanded(
            child: Post(
              horizontalIndex: horizontalIndex,
              verticalIndex: verticalIndex,
              updateFeedState: _updateFeedState,
            ),
          )
        ],
      ),
    ));
  }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class Kanban extends StatefulWidget {
  final int verticalIndex;
  final int horizontalIndex;
  final void Function(dynamic, dynamic) updateFeedState;

  const Kanban(
      {Key? key,
      required this.verticalIndex,
      required this.horizontalIndex,
      required this.updateFeedState})
      : super(key: key);

  @override
  State createState() {
    return KanbanState();
  }
}

////////////////////////////////////////////////////////////////////////////////

class KanbanState extends State<Kanban> {
  late int horizontalIndex;
  late int verticalIndex;

  @override
  void initState() {
    super.initState();
    horizontalIndex = widget.horizontalIndex;
    verticalIndex = widget.verticalIndex;
  }

  @override
  void didUpdateWidget(Kanban oldWidget) {
    // This checks whether Kanban's variables have changed value.
    // Those variables get their value from the parent, Feed. And,
    // Feed changes whenver we call the callback that is defined first
    // within Feed. That callback calls setState() which triggers a rebuild.
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verticalIndex != widget.verticalIndex ||
        oldWidget.horizontalIndex != widget.horizontalIndex) {
      setState(() {
        verticalIndex = widget.verticalIndex;
        horizontalIndex = widget.horizontalIndex;
      });
    }
  }

  List<Widget> _generateActionChips(String text, int num) {
    return List.generate(
      num, // Number of action chips to generate
      (index) => ActionChip(
        label: Text(text),
        onPressed: () {
          // calculate the horizontal index based on the number action chip
          // TODO

          setState(() {
            widget.updateFeedState(verticalIndex, horizontalIndex);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      height: 100.0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          Row(
              children:
                  _generateActionChips(widget.verticalIndex.toString(), 15))
        ],
      ),
    );
  }
}

enum SwipeDirection {
  up,
  down,
  left,
  right,
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

class Post extends StatefulWidget {
  final int verticalIndex;
  final int horizontalIndex;
  final void Function(dynamic, dynamic) updateFeedState;

  const Post(
      {Key? key,
      required this.verticalIndex,
      required this.horizontalIndex,
      required this.updateFeedState})
      : super(key: key);

  @override
  State createState() => _PostState();
}

////////////////////////////////////////////////////////////////////////////////

class _PostState extends State<Post> {
  late int horizontalIndex;
  late int verticalIndex;
  late SwipeDirection type;

  LinkedHashMap<String, List<String>> posts =
      LinkedHashMap<String, List<String>>.from({
    'Post 1': [
      '0, 0',
      '0, 1',
      '0, 2',
      '0, 3',
    ],
    'Post 2': [
      '1, 0',
      '1, 1',
      '1, 2',
      '1, 3',
    ],
    'Post 3': [
      '2, 0',
      '2, 1',
      '2, 2',
      '2, 3',
    ],
  });

  @override
  void initState() {
    super.initState();
    horizontalIndex = widget.horizontalIndex;
    verticalIndex = widget.verticalIndex;
  }

  @override
  void didUpdateWidget(Post oldWidget) {
    // This checks whether Kanban's variables have changed value.
    // Those variables get their value from the parent, Feed. And,
    // Feed changes whenver we call the callback that is defined first
    // within Feed. That callback calls setState() which triggers a rebuild.
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verticalIndex != widget.verticalIndex ||
        oldWidget.horizontalIndex != widget.horizontalIndex) {
      setState(() {
        verticalIndex = widget.verticalIndex;
        horizontalIndex = widget.horizontalIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // vertical scrolling
        body: PageView.builder(itemBuilder: (context, index) {
      return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! < 0 &&
                verticalIndex < posts.length - 1 &&
                horizontalIndex == 0) {
              // Swiped downwards
              type = SwipeDirection.down;
              setState(() {
                verticalIndex++;
                // new post changes the entire kanban
                widget.updateFeedState(verticalIndex, 0);
              });
            } else if (details.primaryVelocity! > 0 &&
                verticalIndex > 0 &&
                horizontalIndex == 0) {
              // Swiped upwards
              type = SwipeDirection.up;
              setState(() {
                verticalIndex -= 1;

                // new post changes the entire kanban
                widget.updateFeedState(verticalIndex, 0);
              });
            }
          },
          onHorizontalDragEnd: (details) {
            int numRelatedPosts =
                posts[posts.keys.toList()[verticalIndex]]!.length;
            if (details.primaryVelocity! < 0) {
              // Swiped to the right
              type = SwipeDirection.right;
              setState(() {
                horizontalIndex++;
                horizontalIndex = horizontalIndex % numRelatedPosts;
                widget.updateFeedState(verticalIndex, horizontalIndex);
              });
            } else if (details.primaryVelocity! > 0 && horizontalIndex > 0) {
              // Swiped to the left
              type = SwipeDirection.left;
              setState(() {
                horizontalIndex--;
                horizontalIndex = horizontalIndex % numRelatedPosts;
                widget.updateFeedState(verticalIndex, horizontalIndex);
              });
            }
          },
          child: Builder(builder: (context) {
            if (posts[posts.keys.toList()[verticalIndex]] != null) {
              return Align(
                  child: Text(
                      posts[posts.keys.toList()[verticalIndex]]![
                          horizontalIndex],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                      )));
            }
            return const Text("Error.");
          }));
    }));
  }
}
