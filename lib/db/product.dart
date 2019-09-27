import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class ProductService{
  Firestore _firestore = Firestore.instance;
  String ref = 'products';

  void createProduct(Map<String, dynamic> data){
    var id = Uuid();
    String productId = id.v1();
    data['id'] = productId;
    _firestore.collection(ref).document(productId).setData(data);
  }
}