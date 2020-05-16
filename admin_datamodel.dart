import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:convert';

class Order {
  final String OrderRef;
  final String OrderTotal;
  final String OrderStatus;
  final String DeviceID;
  final String UserRefNumber;
  final String UserName;
  final String Property;
  final String Unit;
  final DateTime created;

  Order.fromMap(Map<String, dynamic> map, String docid)
      : assert(map['orderref'] != null),
        assert(map['ordertotal'] != null),
        assert(map['status'] != null),
        assert(map['deviceid'] != null),
        assert(map['userreferencenumber'] != null),
        assert(map['username'] != null),
        assert(map['property'] != null),
        assert(map['unit'] != null),
        //assert(map['created'] != null),
        OrderRef = map['orderref'], //docid
        OrderTotal = map['ordertotal'],
        OrderStatus = map['status'],
        DeviceID = map['deviceid'],
        UserRefNumber = map['userreferencenumber'],
        UserName = map['username'],
        Property = map['property'],
        Unit = map['unit'],
        created =
            (map['created'] != null ? map['created'].toDate() : DateTime.now());

  //DateTime.parse(timestamp.toDate().toString())

  Order.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, snapshot.documentID);
}

class User {
  final String userid;
  final String userrefnumber;
  final String username;
  final String propertyname;
  final String unitcode;
  final DateTime created;

  User.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, snapshot.documentID);

  User.fromMap(Map<String, dynamic> map, String docid)
      : assert(map['userrefnumber'] != null),
        assert(map['username'] != null),
        assert(map['propertyname'] != null),
        assert(map['unitcode'] != null),
        //assert(map['created'] != null),
        userid = docid,
        userrefnumber = map['userrefnumber'],
        username = map['username'],
        propertyname = map['propertyname'],
        unitcode = map['unitcode'],
        created =
            (map['created'] != null ? map['created'].toDate() : DateTime.now());
}

class Item {
  final String itemid;
  final String item;
  final String category;
  final int orderofcategory;
  final int price;

  Item.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, snapshot.documentID);

  Item.fromMap(Map<String, dynamic> map, String docid)
      : assert(map['item'] != null),
        assert(map['category'] != null),
        assert(map['orderofcategory'] != null),
        assert(map['price'] != null),
        itemid = docid,
        item = map['item'],
        category = map['category'],
        orderofcategory = map['orderofcategory'],
        price = map['price'];
}

class OrderItem {
  final String itemid;
  final String item;
  final int price;
  final int qty;

  OrderItem.fromMap(Map<String, dynamic> map, String docid)
      : assert(map['item'] != null),
        assert(map['price'] != null),
        assert(map['qty'] != null),
        itemid = docid,
        item = map['item'],
        price = map['price'],
        qty = map['qty'];

  OrderItem.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, snapshot.documentID);
}

class Record {
  final String item;
  final String category;
  final int price;
  final String id;
  int qty = 1;

  Record.fromMap(Map<String, dynamic> map, String docid)
      : assert(map['item'] != null),
        assert(map['category'] != null),
        assert(map['price'] != null),
        id = docid,
        item = map['item'],
        category = map['category'],
        price = map['price'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, snapshot.documentID);

/*
  final DocumentReference reference;
  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['item'] != null),
        assert(map['category'] != null),
        assert(map['price'] != null),
        id = reference.documentID,
        item = map['item'],
        category = map['category'],
        price = map['price'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);
*/

  @override
  String toString() => "Record<$id:$item:$category:$price>";
}

class utils {
  static final Random _random = Random.secure();

  static String CreateRandomDigitsString([int length = 19]) {
    var values = List<int>.generate(length, (i) => _random.nextInt(10));

    return values.join();
  }

  static String CreateCryptoRandomString([int length = 32]) {
    var values = List<int>.generate(length, (i) => _random.nextInt(256));

    return base64Url.encode(values);
  }
}
