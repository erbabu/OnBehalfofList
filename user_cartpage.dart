import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:onbehalfoflistuser/main.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:onbehalfoflistuser/cartmodel.dart';
import 'package:device_id/device_id.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';

class CartPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CartPageState();
  }
}

class _CartPageState extends State<CartPage> {
  Future<void> _ackAlert(BuildContext context, String msg) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('New Order Request'),
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

  String _propertyname = '';
  String _unitnumber = '';
  String _userreferencenumber = '';
  String _username = '';
  String _deviceid = '';

  _readfromlocalstorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String t_propertyname = '';
    String t_unitnumber = '';
    String t_userreferencenumber = '';
    String t_username = '';
    String t_deviceid = '';

    t_propertyname = (prefs.getString('propertyname') ?? _propertyname);
    t_unitnumber = (prefs.getString('unitnumber') ?? _unitnumber);
    t_userreferencenumber =
        (prefs.getString('userreferencenumber') ?? _userreferencenumber);
    t_username = (prefs.getString('username') ?? _username);
    t_deviceid = (prefs.getString('deviceid') ?? await DeviceId.getID);
    print('local storage read complete');
    setState(() {
      _propertyname = t_propertyname;
      _unitnumber = t_unitnumber;
      _userreferencenumber = t_userreferencenumber;
      _username = t_username;
      _deviceid = t_deviceid;
    });
  }

  void _submitorderrequest() async {
    //local storage data read
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String t_propertyname = '';
    String t_unitnumber = '';
    String t_userreferencenumber = '';
    String t_username = '';
    String t_deviceid = '';
    t_userreferencenumber = (prefs.getString('userreferencenumber') ?? '');
    print(t_userreferencenumber);
    if (t_userreferencenumber == '') {
      _ackAlert(context,
          'User is not registered in this device. Register in home screen side menu About User option.');
      return;
    } else {
      t_propertyname = (prefs.getString('propertyname') ?? '');
      t_unitnumber = (prefs.getString('unitnumber') ?? '');
      t_userreferencenumber = (prefs.getString('userreferencenumber') ?? '');
      t_username = (prefs.getString('username') ?? '');
      t_deviceid = (prefs.getString('deviceid') ?? await DeviceId.getID);
      print('local storage read complete');
      int len = 0;
      len = ScopedModel.of<CartModel>(context).cart.length;
      print(len);
      if (len > 0) {
        //database update
        String docid = '';
        docid = firestoreInstance
            .collection("OnBehalfListOrder")
            .document()
            .documentID;
        firestoreInstance
            .collection("OnBehalfListOrder")
            .document(docid)
            .setData({
          "orderref": docid,
          "ordertotal":
              ScopedModel.of<CartModel>(context, rebuildOnChange: true)
                  .totalCartValue
                  .toString(),
          "property": t_propertyname,
          "unit": t_unitnumber,
          "userreferencenumber": t_userreferencenumber,
          "username": t_username,
          "deviceid": t_deviceid,
          "created": FieldValue.serverTimestamp(),
          "status": "Open",
          "notes": "Order submitted",
          "active": true
        }).then((_) {
          print("success! " + "$docid");
        });

        ScopedModel.of<CartModel>(context).cart.every((element) {
          firestoreInstance
              .collection("OnBehalfListOrder")
              .document(docid)
              .collection("items")
              .add({
            "item": element.item,
            "price": element.price,
            "qty": element.qty
          }).then((value) {
            print('item added to ' + docid);
          });
          print(element.id);
          print(element.item);
          print(element.price);
          print(element.qty);
          return true;
        });
        print('Order request successfully submitted. Ref: ' + docid);
        ScopedModel.of<CartModel>(context).clearCart();
        _ackAlert(context,
            'This order request is submitted successfully. Ref: ' + docid);
      } else {
        print('Cart is empty.');
        _ackAlert(context, 'Cart is empty.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Text("Order Request Cart"),
          actions: <Widget>[
            FlatButton(
                child: Text(
                  "Clear",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () => ScopedModel.of<CartModel>(context).clearCart())
          ],
        ),
        body: ScopedModel.of<CartModel>(context, rebuildOnChange: true)
                    .cart
                    .length ==
                0
            ? Center(
                child: Text("No items in Cart"),
              )
            : Container(
                padding: EdgeInsets.all(8.0),
                child: Column(children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                      itemCount: ScopedModel.of<CartModel>(context,
                              rebuildOnChange: true)
                          .total,
                      itemBuilder: (context, index) {
                        return ScopedModelDescendant<CartModel>(
                          builder: (context, child, model) {
                            return ListTile(
                              title: Text(model.cart[index].item),
                              subtitle: Text(model.cart[index].qty.toString() +
                                  " x " +
                                  model.cart[index].price.toString() +
                                  " = " +
                                  (model.cart[index].qty *
                                          model.cart[index].price)
                                      .toString()),
                              trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.add),
                                      onPressed: () {
                                        model.updateProduct(model.cart[index],
                                            model.cart[index].qty + 1);
                                        // model.removeProduct(model.cart[index]);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.remove),
                                      onPressed: () {
                                        model.updateProduct(model.cart[index],
                                            model.cart[index].qty - 1);
                                        // model.removeProduct(model.cart[index]);
                                      },
                                    ),
                                  ]),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Container(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Order Total: \$ " +
                            ScopedModel.of<CartModel>(context,
                                    rebuildOnChange: true)
                                .totalCartValue
                                .toString() +
                            "",
                        style: TextStyle(
                            fontSize: 20.0, fontWeight: FontWeight.bold),
                      )),
                  SizedBox(
                      width: double.infinity,
                      child: RaisedButton(
                        color: Colors.blue,
                        textColor: Colors.white,
                        elevation: 0,
                        child: Text(
                          "Submit Order Request",
                          textScaleFactor: 1.5,
                        ),
                        onPressed: () {
                          _submitorderrequest();
                        },
                      ))
                ])));
  }
}
