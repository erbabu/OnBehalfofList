import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:link/link.dart';
import 'package:onbehalfoflistuser/cartpage.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:onbehalfoflistuser/cartmodel.dart';
import 'dart:io';
import 'dart:async';
import 'package:device_id/device_id.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

final firestoreInstance = Firestore.instance;

void main() {
  //SharedPreferences.setMockInitialValues(      {}); //https://github.com/Baseflow/flutter_cached_network_image/issues/50
  runApp(MyApp(
    model: CartModel(),
  ));
}

class MyApp extends StatelessWidget {
  final CartModel model;

  const MyApp({Key key, @required this.model}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ScopedModel<CartModel>(
        model: model,
        child: MaterialApp(
          title: 'On Behalf of List User',
          initialRoute: '/',
          //home: myhomepage(),
          routes: {
            '/': (context) => myhomepage(),
            '/neworder': (context) => myneworder(),
            '/cart': (context) => CartPage(),
            '/aboutpage': (context) => myaboutpage(),
            '/aboutuser': (context) => myaboutuser(),
          },
        ));
  }
}

class myneworder extends StatefulWidget {
  @override
  _myneworderState createState() => _myneworderState();
}

class _myneworderState extends State<myneworder> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Order Request'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          )
        ],
      ),
      body: ScopedModelDescendant<CartModel>(builder: (context, child, model) {
        return (SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(height: 600, child: _builditemsliststream(context)),
            ],
          ),
        ));
      }),
    );
  }

  Widget _builditemslist(BuildContext context) {
    firestoreInstance
        .collection("OnBehalfListItem")
        .orderBy('orderofcategory')
//        .where("active", isEqualTo: true)
        .getDocuments()
        .then((value) {
      return _buildList(context, value.documents);
//      value.documents.forEach((result) {
//        print(result.data);
//      });
    });
  }

  Widget _builditemsliststream(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('OnBehalfListItem')
          .orderBy('orderofcategory')
          .where("active", isEqualTo: true)
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
    return ScopedModelDescendant<CartModel>(builder: (context, child, model) {
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
            title: Text(record.item),
            subtitle:
                Text(record.category + '\t' + '\$' + record.price.toString()),
            trailing: FlatButton(
              color: Colors.blue,
              textColor: Colors.white,
              disabledColor: Colors.grey,
              disabledTextColor: Colors.black,
              padding: EdgeInsets.all(8.0),
              splashColor: Colors.blueAccent,
              onPressed: () {
                model.addProduct(record);
                Scaffold.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully Added')));
              },
              child: Text(
                "Add",
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class myaboutpage extends StatefulWidget {
  @override
  _myaboutpageState createState() => _myaboutpageState();
}

class _myaboutpageState extends State<myaboutpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About the app'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Text('About the app explanation in full detail.'),
          ],
        ),
      ),
    );
  }
}

class myaboutuser extends StatefulWidget {
  @override
  _myaboutuserState createState() => _myaboutuserState();
}

class _myaboutuserState extends State<myaboutuser> {
  String _propertyname = '';
  String _unitnumber = '';
  String _userreferencenumber = '';
  String _username = '';
  String _deviceid = '';

  @override
  void initState() {
    super.initState();
    _readfromlocalstorage();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void _showScaffold(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  _readfromlocalstorage() async {
    String t_propertyname = '';
    String t_unitnumber = '';
    String t_userreferencenumber = '';
    String t_username = '';
    String t_deviceid = '';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    t_propertyname = (prefs.getString('propertyname') ?? _propertyname);
    t_unitnumber = (prefs.getString('unitnumber') ?? _unitnumber);
    t_userreferencenumber =
        (prefs.getString('userreferencenumber') ?? _userreferencenumber);
    t_username = (prefs.getString('username') ?? _username);
    t_deviceid = await DeviceId.getID;
    print('Local storage read complete');
    setState(() {
      _propertyname = t_propertyname;
      _unitnumber = t_unitnumber;
      _userreferencenumber = t_userreferencenumber;
      _username = t_username;
      _deviceid = t_deviceid;
      return;
    });
  }

  _setmockvalues() async {
    print('Mock values applied');
    setState(() {
      _propertyname = 'Mock Property 01';
      _unitnumber = 'Mock Unit A101';
      _userreferencenumber = 'Mock UserRef 1234567890';
      _username = 'Mock Name 01';
      _showScaffold("Mock values applied");
      return;
    });
  }

  _writetolocalstorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String t_userreferencenumber = '';
    t_userreferencenumber =
        (prefs.getString('userreferencenumber') ?? _userreferencenumber);
    if (t_userreferencenumber == '') {
      print('User reference number can not be empty.');
      return;
    } else {
      prefs.setString('propertyname', _propertyname);
      prefs.setString('unitnumber', _unitnumber);
      prefs.setString('userreferencenumber', _userreferencenumber);
      prefs.setString('username', _username);
      prefs.setString('deviceid', _deviceid);
      print('Local storage write complete');
      _showScaffold("Local storage write complete");
      return;
    }
  }

  //scan the QR code
  Future<void> scanQR() async {
    String barcodeScanRes;
    String t_propertyname = '';
    String t_unitnumber = '';
    String t_userreferencenumber = '';
    String t_username = '';
    List<String> result;

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.QR);
      print(barcodeScanRes);
      result = barcodeScanRes.split(':');
      print(result.length);
      print(result[0]);
      print(result[1]);
      print(result[2]);
      print(result[3]);
      t_propertyname = result[0];
      t_unitnumber = result[1];
      t_userreferencenumber = result[2];
      t_username = result[3];
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    setState(() {
      _propertyname = t_propertyname;
      _unitnumber = t_unitnumber;
      _userreferencenumber = t_userreferencenumber;
      _username = t_username;
      return;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('About user'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'About the user details.',
                textScaleFactor: 1.5,
              ),
            ),
            Text('Property: ' + '$_propertyname'),
            Text('Unit Number: ' + '$_unitnumber'),
            Text('User Reference: ' + '$_userreferencenumber'),
            Text('User Name: ' + '$_username'),
            Text('DeviceID: ' + '$_deviceid'),
            FlatButton(
              color: Colors.blue,
              textColor: Colors.white,
              disabledColor: Colors.grey,
              disabledTextColor: Colors.black,
              padding: EdgeInsets.all(8.0),
              splashColor: Colors.blueAccent,
              onPressed: () {
                scanQR();
              },
              child: Text(
                "Read User QR Code",
                style: TextStyle(fontSize: 16.0),
              ),
            ),
            FlatButton(
              color: Colors.blue,
              textColor: Colors.white,
              disabledColor: Colors.grey,
              disabledTextColor: Colors.black,
              padding: EdgeInsets.all(8.0),
              splashColor: Colors.blueAccent,
              onPressed: () {
                _writetolocalstorage();
              },
              child: Text(
                "Save User Settings",
                style: TextStyle(fontSize: 16.0),
              ),
            ),
            FlatButton(
              color: Colors.blue,
              textColor: Colors.white,
              disabledColor: Colors.grey,
              disabledTextColor: Colors.black,
              padding: EdgeInsets.all(8.0),
              splashColor: Colors.blueAccent,
              onPressed: () {
                _setmockvalues();
              },
              child: Text(
                "Use Mock Values",
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class myhomepage extends StatefulWidget {
  @override
  _myhomepageState createState() => _myhomepageState();
}

class _myhomepageState extends State<myhomepage> {
  String _userreferencenumber = '';

  _getuserreferencenumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String t_userreferencenumber = '';
    t_userreferencenumber = (prefs.getString('userreferencenumber') ?? '');
    setState(() {
      _userreferencenumber = t_userreferencenumber;
    });
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
        title: Text('On Behalf of List: User View'),
      ),
      drawer: Drawer(
          child: ListView(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              'On Behalf of List\nUser View',
              textScaleFactor: 1.4,
            ),
            currentAccountPicture: new CircleAvatar(
              backgroundImage: AssetImage('images/OnBehalfList_small.png'),
            ),
          ),
          Link(
              url: 'https://github.com/erbabu/OnBehalfofList',
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Instructions'),
              )),
          ListTile(
            title: new Text('About User'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/aboutuser');
            },
          ),
          ListTile(
            title: new Text('About App'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/aboutpage');
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/neworder');
        },
        tooltip: 'New Order Request',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _builditemsorderliststream(BuildContext context) {
    _getuserreferencenumber();
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('OnBehalfListOrder')
          .orderBy('created', descending: true)
          .where("userreferencenumber", isEqualTo: _userreferencenumber)
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
          title: Text(orderrecord.OrderRef + ' : ' + orderrecord.OrderStatus),
          subtitle: Text(orderrecord.created.toString()),
          trailing: Text('\$' + orderrecord.OrderTotal),
          onTap: () {
            OrderDetails = orderrecord.Property + '\n' + orderrecord.Unit;
            OrderDetails = OrderDetails +
                '\nUserRef:' +
                orderrecord.UserRefNumber +
                '\nName:' +
                orderrecord.UserName;
            OrderDetails = OrderDetails + '\nDevice:' + orderrecord.DeviceID;
            firestoreInstance
                .collection('OnBehalfListOrder')
                .document(orderrecord.OrderRef)
                .collection('items')
                .getDocuments()
                .then((value) {
              value.documents.forEach((element) {
                //print(element.data.toString());
                OrderDetails = OrderDetails + '\n' + element.data.toString();
              });
              _ackAlert(context, OrderDetails);
            });
          },
        ),
      ),
    );
  }
}
