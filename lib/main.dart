import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Infinite Scrolling',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new InfiniteListView(),
    );
  }
}

class Item {
  int id;
  String name;

  Item({this.id, this.name});
}

Future<List<Item>> _loadItems(int offset, int limit) {
  var random = new Random();
  return Future.delayed(new Duration(seconds: 2 + random.nextInt(3)), () {
    return List.generate(limit, (index) {
      var id = offset + index;
      return new Item(id: id, name: "Item $id");
    });
  });
}

var total = 105;
var pageSize = 20;

var completers = new List<Completer<Item>>();

Widget _loadItem(int itemIndex) {
  if (itemIndex >= completers.length) {
    int toLoad = min(total - itemIndex, pageSize);
    completers.addAll(List.generate(toLoad, (index) {
      return new Completer();
    }));
    _loadItems(itemIndex, toLoad).then((items) {
      items.asMap().forEach((index, item) {
        completers[itemIndex + index].complete(item);
      });
    }).catchError((error) {
      completers.sublist(itemIndex, itemIndex + toLoad).forEach((completer) {
        completer.completeError(error);
      });
    });
  }

  var future = completers[itemIndex].future;
  return new FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return new Container(
              padding: const EdgeInsets.all(8.0),
              child: new Placeholder(fallbackHeight: 100.0),
            );
          case ConnectionState.done:
            if (snapshot.hasData) {
              return _generateItem(snapshot.data);
            } else if (snapshot.hasError) {
              return new Text(
                '${snapshot.error}',
                style: TextStyle(color: Colors.red),
              );
            }
            return new Text('');
          default:
            return new Text('');
        }
      });
}

Widget _generateItem(Item item) {
  return new Container(
    padding: const EdgeInsets.all(8.0),
    child: new Row(
      children: <Widget>[
        new Image.network(
          'http://via.placeholder.com/200x100?text=Item${item.id}',
          width: 200.0,
          height: 100.0,
        ),
        new Expanded(child: new Text(item.name))
      ],
    ),
  );
}

class InfiniteListView extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Infinite Scrolling')),
      body: new ListView.builder(
          itemCount: total,
          itemBuilder: (BuildContext context, int index) => _loadItem(index)),
    );
  }
}
