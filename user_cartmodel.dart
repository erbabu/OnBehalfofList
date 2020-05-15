import 'package:scoped_model/scoped_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CartModel extends Model {
  List<Record> cart = [];
  double totalCartValue = 0;

  int get total => cart.length;

  /// Wraps [ScopedModel.of] for this [Model].
  static CartModel of(BuildContext context) =>
      ScopedModel.of<CartModel>(context);

  void addProduct(product) {
    int index = cart.indexWhere((i) => i.id == product.id);
    print(index);
    if (index != -1)
      updateProduct(product, product.qty + 1);
    else {
      cart.add(product);
      calculateTotal();
      notifyListeners();
    }
  }

  void removeProduct(product) {
    int index = cart.indexWhere((i) => i.id == product.id);
    cart[index].qty = 1;
    cart.removeWhere((item) => item.id == product.id);
    calculateTotal();
    notifyListeners();
  }

  void updateProduct(product, qty) {
    int index = cart.indexWhere((i) => i.id == product.id);
    cart[index].qty = qty;
    if (cart[index].qty == 0) removeProduct(product);

    calculateTotal();
    notifyListeners();
  }

  void clearCart() {
    cart.forEach((f) => f.qty = 1);
    cart = [];
    notifyListeners();
  }

  void calculateTotal() {
    totalCartValue = 0;
    cart.forEach((f) {
      totalCartValue += f.price * f.qty;
    });
  }
}

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
        assert(map['created'] != null),
        OrderRef = map['orderref'], //docid
        OrderTotal = map['ordertotal'],
        OrderStatus = map['status'],
        DeviceID = map['deviceid'],
        UserRefNumber = map['userreferencenumber'],
        UserName = map['username'],
        Property = map['property'],
        Unit = map['unit'],
        created = map['created'].toDate();

  //DateTime.parse(timestamp.toDate().toString())

  Order.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, snapshot.documentID);
}

class OrderItem {
  final String itemid;
  final String item;
  final double price;
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
