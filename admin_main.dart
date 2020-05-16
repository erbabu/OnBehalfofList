import 'package:flutter/material.dart';
import 'package:link/link.dart';
//cloud firestore
import 'package:cloud_firestore/cloud_firestore.dart';
//brotherlabelprintdart: ^0.1.0
import 'package:brotherlabelprintdart/print.dart';
import 'package:brotherlabelprintdart/printerModel.dart';
import 'package:brotherlabelprintdart/templateLabel.dart';
//data model
import 'package:onbehalfoflistadmin/datamodel.dart';

final firestoreInstance = Firestore.instance;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'On Behalf of List - Admin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MyHomePage(title: 'On Behalf of List: Admin View'),
        '/users': (context) => myUsers(),
        '/items': (context) => myItems(),
        '/newuser': (context) => myNewUser(),
        '/newitem': (context) => myNewItem(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //setting the order status
  _setorderrecordstatus(String OrderRef, String OrderStatus) {
    firestoreInstance
        .collection("OnBehalfListOrder")
        .document(OrderRef)
        .setData({
      "status": OrderStatus,
    }, merge: true).then((_) {
      print("success! data merged: " + "$OrderRef" + ' : ' + '$OrderStatus');
    });
    return;
  }

  fnprintorderdetails(String orderdetails) async {
    List<TemplateLabel> labels = List<TemplateLabel>();
    labels.add(TemplateLabel(3, ['', '', '', orderdetails]));
    String result;
    try {
      result = await Brotherlabelprintdart.printLabelFromTemplate(
          "192.168.1.28", PrinterModel.QL_820NWB, labels);
      print('Order details printed');
    } catch (e) {
      print("An error occured : $e");
    }
  }

  Future<void> _ackAlert(BuildContext context, String msg) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order Information'),
          content: Text('$msg'),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: Drawer(
          child: ListView(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              'On Behalf of List\nAdmin View',
              textScaleFactor: 1.4,
            ),
            currentAccountPicture: new CircleAvatar(
              backgroundImage: AssetImage('images/OnBehalfListAdmin.png'),
            ),
          ),
          Link(
              url: 'https://github.com/erbabu/OnBehalfofList',
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Instructions'),
              )),
          ListTile(
            title: new Text('Users'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/users');
            },
          ),
          ListTile(
            title: new Text('Items'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/items');
            },
          ),
        ],
      )),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(height: 600, child: _builditemsorderliststream(context)),
          ],
        ),
      ),
    );
  }

  Widget _builditemsorderliststream(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('OnBehalfListOrder')
          .where('status', isGreaterThan: 'Complete')
          .orderBy('status')
          .orderBy('created', descending: true)
          .snapshots(), //users OnBehalfListItem
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Text('Orders are not yet created.');
        return _buildorderList(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildorderList(
      BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 2.0),
      children:
          snapshot.map((data) => _buildorderListItem(context, data)).toList(),
    );
  }

  Widget _buildorderListItem(BuildContext context, DocumentSnapshot data) {
    final orderrecord = Order.fromSnapshot(data);
    String OrderDetails = '';
    //print(orderrecord.OrderRef);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          //isThreeLine: true,
          leading: IconButton(
            icon: Icon(Icons.directions_run),
            color: Colors.orange,
            tooltip: 'Processing',
            onPressed: () {
              //mark the order as processing
              _setorderrecordstatus(orderrecord.OrderRef, 'Processing');
              //print the order item list
              OrderDetails = orderrecord.Property + ' ' + orderrecord.Unit;
              OrderDetails = OrderDetails +
                  ' UserRef:' +
                  orderrecord.UserRefNumber +
                  ' Name:' +
                  orderrecord.UserName;
              OrderDetails =
                  OrderDetails + ' Order Total: \$' + orderrecord.OrderTotal;
              OrderDetails =
                  OrderDetails + ' ' + orderrecord.created.toString();
              OrderDetails =
                  OrderDetails + ' Status: ' + orderrecord.OrderStatus;
              OrderDetails = OrderDetails +
                  ' Device:' +
                  orderrecord.DeviceID +
                  ' Item : Price : Qty';
              print(orderrecord.OrderRef);
              firestoreInstance
                  .collection('OnBehalfListOrder')
                  .document(orderrecord.OrderRef)
                  .collection('items')
                  .getDocuments()
                  .then((value) {
                value.documents.forEach((element) {
                  print(element.data['item']);
                  //print(element.data.toString());
                  //OrderDetails = OrderDetails + '\n' + element.data.toString();
                  OrderDetails = OrderDetails +
                      ' ' +
                      element.data['item'] +
                      ' : \$' +
                      element.data['price'].toString() +
                      ' : ' +
                      element.data['qty'].toString() +
                      ' ;';
                });
                _ackAlert(context, OrderDetails);
                fnprintorderdetails(OrderDetails);
              });
            },
          ),
          title: Text(orderrecord.OrderRef + ' : ' + orderrecord.OrderStatus),
          subtitle: Text(orderrecord.created.toString() +
              ' Total: \$' +
              orderrecord.OrderTotal),
          trailing: IconButton(
            icon: Icon(Icons.call_end),
            tooltip: 'Completed',
            color: Colors.red,
            onPressed: () {
              _setorderrecordstatus(orderrecord.OrderRef, 'Complete');
            },
          ),
          onTap: () {
            OrderDetails = orderrecord.Property + '\n' + orderrecord.Unit;
            OrderDetails = OrderDetails +
                '\nUserRef:' +
                orderrecord.UserRefNumber +
                '\nName:' +
                orderrecord.UserName;
            OrderDetails =
                OrderDetails + '\nOrder Total: \$' + orderrecord.OrderTotal;
            OrderDetails = OrderDetails + '\n' + orderrecord.created.toString();
            OrderDetails =
                OrderDetails + '\nStatus: ' + orderrecord.OrderStatus;
            OrderDetails = OrderDetails +
                '\nDevice:' +
                orderrecord.DeviceID +
                '\n\nItem : Price : Qty';
            firestoreInstance
                .collection('OnBehalfListOrder')
                .document(orderrecord.OrderRef)
                .collection('items')
                .getDocuments()
                .then((value) {
              value.documents.forEach((element) {
                //print(element.data['item']);
                //print(element.data.toString());
                //OrderDetails = OrderDetails + '\n' + element.data.toString();
                OrderDetails = OrderDetails +
                    '\n' +
                    element.data['item'] +
                    ' : \$' +
                    element.data['price'].toString() +
                    ' : ' +
                    element.data['qty'].toString();
              });
              _ackAlert(context, OrderDetails);
            });
          },
        ),
      ),
    );
  }
}

class myUsers extends StatefulWidget {
  @override
  _myUsersState createState() => _myUsersState();
}

class _myUsersState extends State<myUsers> {
  //print user card
  fnPrintUserCard(String property, String unitcode, String userrefnumber,
      String username) async {
    //mock values
/*    _property = 'Mock Property 01';
    _unit = 'Mock Unit A101';
    _userrefnumber = 'Mock Ref 1234567890';
    _username = 'Mock User 01';
    _qrcodedata =
        _property + ':' + _unit + ':' + _userrefnumber + ':' + _username;*/

    String qrcodedata = '';
    qrcodedata =
        property + ':' + unitcode + ':' + userrefnumber + ':' + username;
    List<TemplateLabel> labels = List<TemplateLabel>();
    labels.add(TemplateLabel(
        2, [property, userrefnumber, username, unitcode, qrcodedata]));
    String result;
    try {
      result = await Brotherlabelprintdart.printLabelFromTemplate(
          "192.168.1.28", PrinterModel.QL_820NWB, labels);
      print('User card printed');
    } catch (e) {
      result = "An error occured : $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(height: 600, child: _builditemsuserliststream(context)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add new user',
        heroTag: 'fbutton',
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, '/newuser');
        },
      ),
    );
  }

  Widget _builditemsuserliststream(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('OnBehalfListUser')
          .orderBy('created', descending: true)
          .snapshots(), //users OnBehalfListItem
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Text('Users are not yet created.');
        return _builduserList(context, snapshot.data.documents);
      },
    );
  }

  Widget _builduserList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 2.0),
      children:
          snapshot.map((data) => _builduserListItem(context, data)).toList(),
    );
  }

  Widget _builduserListItem(BuildContext context, DocumentSnapshot data) {
    final user = User.fromSnapshot(data);
    //print(user.created);
    return Padding(
      key: ValueKey(user.userid),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
            //isThreeLine: true,
            title: Text(user.userrefnumber),
            subtitle: Text(user.username +
                ' [' +
                user.propertyname +
                ':' +
                user.unitcode +
                ']'),
            trailing: IconButton(
              icon: Icon(Icons.print),
              onPressed: () {
                fnPrintUserCard(user.propertyname, user.unitcode,
                    user.userrefnumber, user.username);
              },
            )),
      ),
    );
  }
}

class myItems extends StatefulWidget {
  @override
  _myItemsState createState() => _myItemsState();
}

class _myItemsState extends State<myItems> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Items'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(height: 600, child: _builditemsliststream(context)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add new item',
        heroTag: 'fbutton',
        child: Icon(Icons.add),
        backgroundColor: Colors.orange,
        onPressed: () {
          Navigator.pushNamed(context, '/newitem');
        },
      ),
    );
  }

  Widget _builditemsliststream(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('OnBehalfListItem')
          .orderBy('orderofcategory')
          .snapshots(), //users OnBehalfListItem
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        return _buildList(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 2.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);
    //print(record.id);
    return Padding(
      key: ValueKey(record.id),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          //isThreeLine: true,
          leading: IconButton(
              icon: Icon(Icons.delete),
              color: Colors.red,
              tooltip: 'Delete',
              onPressed: () {
                //action for delete
              }),
          title: Text(record.item),
          subtitle:
              Text(record.category + '\t' + '\$' + record.price.toString()),
          trailing: IconButton(
              icon: Icon(Icons.chevron_right),
              color: Colors.green,
              tooltip: 'Delete',
              onPressed: () {
                //action for delete
              }),
        ),
      ),
    );
  }
}

class myNewUser extends StatefulWidget {
  @override
  _myNewUserState createState() => _myNewUserState();
}

class _myNewUserState extends State<myNewUser> {
  String _propertyname = '';
  String _unitcode = '';
  String _userrefnumber = '';
  String _username = '';
  //fields: created, active are having default values
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void _showScaffold(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  Future<void> _ackAlert(BuildContext context, String msg) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('User'),
          content: Text('$msg'),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _savenewuser() {
    if (_propertyname == '') {
      _showScaffold('Property Name can not be empty');
      return;
    } else {
      if (_unitcode == '') {
        _showScaffold('Unit Code can not be empty');
        return;
      } else {
        if (_username == '') {
          _showScaffold('User Name can not be empty');
          return;
        } else {
          String docid = '';
          docid = firestoreInstance
              .collection("OnBehalfListUser")
              .document()
              .documentID;
          firestoreInstance
              .collection("OnBehalfListUser")
              .document(docid)
              .setData({
            "propertyname": _propertyname,
            "unitcode": _unitcode,
            "userrefnumber": _userrefnumber,
            "username": _username,
            "created": FieldValue.serverTimestamp(),
            "active": true
          }).then((_) {
            print("user success! " + "$docid");
          });
//          _showScaffold('New user created successfully.' + '$docid');
          Navigator.of(context).pop();
          _ackAlert(
              context,
              'New user created successfully - ' +
                  '$docid' +
                  ' - ' +
                  '$_userrefnumber');
        }
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    String newRefNum = utils.CreateRandomDigitsString(12);
    setState(() {
      _userrefnumber = newRefNum;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('New User'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('User Ref Number:'),
                SizedBox(
                  width: 2,
                ),
                Text(_userrefnumber),
              ],
            ),
            Row(
              children: <Widget>[
                Text('Property Name:'),
                SizedBox(
                  width: 2,
                ),
                Container(
                  width: 200,
                  height: 50,
                  child: Padding(
                    padding: EdgeInsets.all(5.0),
                    child: TextField(
                      onChanged: (String property) {
                        setState(() {
                          _propertyname = property;
                        });
                      },
                      textAlign: TextAlign.start,
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Text('Unit Code:'),
                SizedBox(
                  width: 2,
                ),
                Container(
                  width: 200,
                  height: 50,
                  child: Padding(
                    padding: EdgeInsets.all(5.0),
                    child: TextField(
                      onChanged: (String unitcode) {
                        setState(() {
                          _unitcode = unitcode;
                        });
                      },
                      textAlign: TextAlign.start,
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Text('User Name:'),
                SizedBox(
                  width: 2,
                ),
                Container(
                  width: 200,
                  height: 50,
                  child: Padding(
                    padding: EdgeInsets.all(5.0),
                    child: TextField(
                      onChanged: (String username) {
                        setState(() {
                          _username = username;
                        });
                      },
                      textAlign: TextAlign.start,
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            RaisedButton(
                onPressed: () {
                  _savenewuser();
                },
                color: Colors.blue,
                textColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: Text("Create User")),
          ],
        ),
      ),
    );
  }
}

class myNewItem extends StatefulWidget {
  @override
  _myNewItemState createState() => _myNewItemState();
}

class _myNewItemState extends State<myNewItem> {
  String _item = '';
  String _category = '';
  int _orderofcategory = 0;
  int _price = 0;
  //fields: itemdescription, active are having default values

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void _showScaffold(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  Future<void> _ackAlert(BuildContext context, String msg) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Item'),
          content: Text('$msg'),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _savenewitem() {
    if (_item == '') {
      _showScaffold('Item name can not be empty');
    } else {
      if (_category == '') {
        _showScaffold('Category can not be empty');
      } else {
        if (_orderofcategory == 0) {
          _showScaffold('Order of category can not be empty');
        } else {
          if (_price == 0) {
            _showScaffold('Price can not be empty');
          } else {
            String docid = '';
            docid = firestoreInstance
                .collection("OnBehalfListItem")
                .document()
                .documentID;
            firestoreInstance
                .collection("OnBehalfListItem")
                .document(docid)
                .setData({
              "item": _item,
              "itemdescription": _item,
              "category": _category,
              "orderofcategory": _orderofcategory,
              "price": _price,
              "active": true
            }).then((_) {
              print("item success! " + "$docid");
            });
//            _showScaffold('New item created successfully - ' + '$docid');
            Navigator.of(context).pop();
            _ackAlert(
                context,
                'New item created successfully - ' +
                    '$docid' +
                    ' - ' +
                    '$_item');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('New Item'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('Item Name:'),
                SizedBox(
                  width: 2,
                ),
                Container(
                  width: 200,
                  height: 50,
                  child: Padding(
                    padding: EdgeInsets.all(5.0),
                    child: TextField(
                      onChanged: (String item) {
                        setState(() {
                          _item = item;
                        });
                      },
                      textAlign: TextAlign.start,
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Text('Category Name:'),
                SizedBox(
                  width: 2,
                ),
                Container(
                  width: 200,
                  height: 50,
                  child: Padding(
                    padding: EdgeInsets.all(5.0),
                    child: TextField(
                      onChanged: (String category) {
                        setState(() {
                          _category = category;
                        });
                      },
                      textAlign: TextAlign.start,
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Text('Display Order of category:'),
                SizedBox(
                  width: 2,
                ),
                Container(
                  width: 200,
                  height: 50,
                  child: Padding(
                    padding: EdgeInsets.all(5.0),
                    child: TextField(
                      onChanged: (String orderofcategory) {
                        setState(() {
                          _orderofcategory = int.parse(orderofcategory);
                        });
                      },
                      textAlign: TextAlign.start,
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Text('Price:'),
                SizedBox(
                  width: 2,
                ),
                Container(
                  width: 200,
                  height: 50,
                  child: Padding(
                    padding: EdgeInsets.all(5.0),
                    child: TextField(
                      onChanged: (String price) {
                        setState(() {
                          _price = int.parse(price);
                        });
                      },
                      textAlign: TextAlign.start,
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            RaisedButton(
                onPressed: () {
                  _savenewitem();
                },
                color: Colors.blue,
                textColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: Text("Create Item")),
          ],
        ),
      ),
    );
  }
}
