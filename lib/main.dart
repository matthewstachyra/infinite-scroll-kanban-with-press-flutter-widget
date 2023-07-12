import 'package:flutter/material.dart';
import 'package:infinite_listview/infinite_listview.dart';
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
  // these need default values for the initial build / insertion into tree
  // currently testing by setting to 'late'
  late int verticalIndex;
  late int horizontalIndex;
  late int numChips = 0;
  late LinkedHashMap<String, List<String>> posts;

  LinkedHashMap<String, List<String>> createPosts(int numKeys, int numValues) {
    LinkedHashMap<String, List<String>> map = LinkedHashMap();

    for (int i = 0; i < numKeys; i++) {
      List<String> values = [];
      for (int j = 0; j < numValues; j++) {
        values.add('$i,$j');
      }
      map[i.toString()] = values;
    }

    return map;
  }

  void _updateFeedState(vindex, hindex) {
    setState(() {
      verticalIndex = vindex;
      horizontalIndex = hindex;
    });
  }

  @override
  void initState() {
    super.initState();
    verticalIndex = 0;
    horizontalIndex = 0;

    // posts that will be displayed in kanban and in feed view
    posts = createPosts(50, 50);

    // length of the list of values for the vertical index
    dynamic key = posts.keys.toList()[verticalIndex];
    if (posts[key] != null) {
      numChips = posts[key]!.length;
    }
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
              numChips: numChips,
              updateFeedState: _updateFeedState),
          Expanded(
            child: Post(
              horizontalIndex: horizontalIndex,
              verticalIndex: verticalIndex,
              posts: posts,
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
  final int numChips;
  final void Function(dynamic, dynamic) updateFeedState;

  const Kanban(
      {Key? key,
      required this.verticalIndex,
      required this.horizontalIndex,
      required this.updateFeedState,
      required this.numChips})
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
  late int numChips;
  late List<Widget> actionChips;
  final InfiniteScrollController _scrollController = InfiniteScrollController();

  @override
  void initState() {
    super.initState();
    horizontalIndex = widget.horizontalIndex;
    verticalIndex = widget.verticalIndex;
    numChips = widget.numChips;
    actionChips = _generateActionChips(widget.numChips);
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
        numChips = widget.numChips;
        actionChips = _generateActionChips(widget.numChips);
        _scrollController.jumpTo(5.0);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Widget> _generateActionChips(int numChips) {
    return List.generate(
      numChips,
      (index) => ActionChip(
        // calculate the index to display inside the action chip
        label: Text(((horizontalIndex + index) % numChips).toString()),
        onPressed: () {
          setState(() {
            widget.updateFeedState(
                verticalIndex, (horizontalIndex + index) % numChips);
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
      child: InfiniteListView.builder(
          scrollDirection: Axis.horizontal,
          controller: _scrollController,
          itemBuilder: (context, index) {
            return Row(children: actionChips);
          }),
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
  final LinkedHashMap<String, List<String>> posts;
  final void Function(dynamic, dynamic) updateFeedState;

  const Post(
      {Key? key,
      required this.verticalIndex,
      required this.horizontalIndex,
      required this.posts,
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
  late LinkedHashMap<String, List<String>> posts;

  @override
  void initState() {
    super.initState();
    horizontalIndex = widget.horizontalIndex;
    verticalIndex = widget.verticalIndex;
    posts = widget.posts;
  }

  @override
  void didUpdateWidget(Post oldWidget) {
    // This checks whether Kanban's variables have changed value.
    // Those variables get their value from the parent, Feed. And,
    // Feed changes whenever we call the callback that is defined first
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
                verticalIndex < widget.posts.length - 1 &&
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
            } else if (details.primaryVelocity! > 0 && horizontalIndex >= 0) {
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
