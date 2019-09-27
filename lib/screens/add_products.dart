import 'dart:io';

import 'package:admin_flutter_app/db/brand.dart';
import 'package:admin_flutter_app/db/category.dart';
import 'package:admin_flutter_app/db/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class AddProduct extends StatefulWidget {
  @override
  _AddProductState createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct>
{
  Color white = Colors.white;
  Color black = Colors.black;
  Color grey = Colors.grey;
  Color red = Colors.red;

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _name = TextEditingController();
  TextEditingController _quantity = TextEditingController();
  TextEditingController _price = TextEditingController();

  List<DocumentSnapshot> brands = <DocumentSnapshot>[];
  List<DocumentSnapshot> categories = <DocumentSnapshot>[];

  List<DropdownMenuItem<String>> categoriesList = <DropdownMenuItem<String>>  [];
  List<DropdownMenuItem<String>> brandsList = <DropdownMenuItem<String>>  [];

  String _currentCategory;
  String _currentBrand;

  CategoryService _categoryService = CategoryService();
  BrandService _brandService = BrandService();
  ProductService _productService = ProductService();

  List<String> selectedSizes = <String>[];

  List<File> _images = <File>[null, null, null];

  bool isLoading = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getCategories();
    _getBrands();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: isLoading? CircularProgressIndicator(): Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  buildExpanded(0),
                  buildExpanded(1),
                  buildExpanded(2),
                ],
              ),
              buildNameTextField('Product Name.', TextInputType.text, _name),
              Row(
                children: <Widget>[
                  buildSelector('Category : ', categoriesList, _currentCategory, changeSelectedCategory),
                  buildSelector('Brand    : ', brandsList, _currentBrand, changeSelectedBrand),
                ],
              ),
              buildNameTextField('Quantity.', TextInputType.numberWithOptions(), _quantity),
              buildNameTextField('Price.', TextInputType.numberWithOptions(), _price),
              Text('Available Sizes', style: TextStyle(color: red, fontWeight: FontWeight.bold),),
              buildSizes(),
              buildAddButton()
            ],
          ),
        ),
      ),
    );
  }

  Row buildSizes() {
    return Row(
            children: <Widget>[
              buildCheckSize('XS'), Text('XS'),
              buildCheckSize('S'), Text('S'),
              buildCheckSize('M'), Text('M'),
              buildCheckSize('L'), Text('L'),
              buildCheckSize('XL'), Text('XL'),
              buildCheckSize('XXL'), Text('XXL'),
            ],
          );
  }

  Checkbox buildCheckSize(String size) => Checkbox(value: selectedSizes.contains(size), onChanged: (value)=>changeSelectedSize(size), activeColor: red,);

  FlatButton buildAddButton() {
    return FlatButton(
            color: red,
            textColor: white,
            child: Text('Add product'),
            onPressed: _validateAndUpload,
          );
  }

  Future<TypeAheadField> buildTypeAheadField() async {
    return TypeAheadField(
            textFieldConfiguration: TextFieldConfiguration(
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Category'
                )
            ),
            suggestionsCallback: (pattern) async {
              return await _categoryService.getSuggestions(pattern);
            },
            itemBuilder: (context, suggestion) {
              return ListTile(
                leading: Icon(Icons.category),
                title: Text(suggestion['category']),
                subtitle: Text('\$${suggestion['price']}'),
              );
            },
            onSuggestionSelected: (suggestion) {
              setState(() {
                _currentCategory = suggestion['category'];
              });
            },
          );
  }

  Padding buildCategoryVisibility() {
    return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Visibility(
              visible: _currentCategory != null,
              child: InkWell(
                child: Material(
                  borderRadius: BorderRadius.circular(20),
                  color: red,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(_currentCategory??'Category name', style: TextStyle(color: white),),
                      ),
                      IconButton(icon: Icon(Icons.close, color: white,),onPressed: (){
                        setState(() {
                          _currentCategory = null;
                        });
                      },)
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  Expanded buildSelector(String label, List<DropdownMenuItem<String>> items, String value, Function onChange) {
    return Expanded(
      child: Row(
              children: <Widget>[
                Text(label, style: TextStyle(color: red),),
                DropdownButton(
                  items: items,
                  value: value,
                  onChanged: onChange,
                )
              ],
            ),
    );
  }

  Padding buildNameTextField(String hint, TextInputType keyboard, TextEditingController controller) {
    return Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboard,
              decoration: InputDecoration(hintText: hint),
              validator: (value){
                if(value.isEmpty)
                  {
                    return hint + " can not be empty";
                  }
                return null;
              },
            ),
          );
  }

  Expanded buildExpanded(int index) {
    return Expanded(
              child: FittedBox(
                fit: BoxFit.fill,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: OutlineButton(
                    borderSide: BorderSide(color: grey.withOpacity(0.5), width:  2.5),
                    onPressed: (){
                      _askPermission(index);
                    },
                    child: buildSelectorContent(index),
                  ),
                ),
              ),
            );
  }

  Padding buildSelectorContent(int index)
  {
    if(_images[index] == null)
      return buildPickIcon();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
      child: Container(
        height: 300, width: 150,
          child: Image.file(_images[index], fit: BoxFit.fill,),)
    );
  }

  Padding buildPickIcon() {
    return Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
                child: Container(width: 80, height: 150.0
                    ,child: Icon(Icons.add, color: grey,)),
              );
  }

  AppBar buildAppBar() {
    return AppBar(
      backgroundColor: white,
      elevation: 0.1,
      leading: Icon(Icons.close, color: black,),
      title: Text('Add product', style: TextStyle(color: black),),
    );
  }

  List<DropdownMenuItem<String>> getCategoriesDropdown() {
    List<DropdownMenuItem<String>> items = List();
    for(DocumentSnapshot category in categories)
      {
        items.add(DropdownMenuItem(child: Text(category['category']),value: category['category'],));
      }
    return items;
  }

  _getCategories() async
  {
    List<DocumentSnapshot> data = await _categoryService.getCategories();
    setState(() {
      categories = data;
      categoriesList = getCategoriesDropdown();
      _currentCategory = categoriesList[0].value;
    });
  }

  List<DropdownMenuItem<String>> getBrandsDropdown() {
    List<DropdownMenuItem<String>> items = List();
    for(DocumentSnapshot category in brands)
    {
      items.add(DropdownMenuItem(child: Text(category['brand']),value: category['brand'],));
    }
    return items;
  }

  _getBrands() async
  {
    List<DocumentSnapshot> data = await _brandService.getBrands();
    setState(() {
      brands = data;
      brandsList = getBrandsDropdown();
      _currentBrand = brandsList[0].value;
    });
  }

  changeSelectedCategory(String selected)
  {
    setState(() {
      _currentCategory = selected;
    });
  }

  changeSelectedBrand(String selected)
  {
    setState(() {
      _currentBrand = selected;
    });
  }

  void changeSelectedSize(String size)
  {
    if(selectedSizes.contains(size))
      {
        setState(() {
          selectedSizes.remove(size);
        });
      }
    else
      {
        setState(() {
          selectedSizes.add(size);

        });
      }
  }

  void _selectImage(Future<File> pickImage, int index) async
  {
    File image = await pickImage;
    setState(()
    {
      _images[index] = image;
    });
  }

  void _askPermission(int index) async
  {

    Map<PermissionGroup, PermissionStatus> permissions = await PermissionHandler().requestPermissions([PermissionGroup.storage]);
    _selectImage(ImagePicker.pickImage(source: ImageSource.gallery), index);
  }

  void _validateAndUpload() async
  {
    if(_formKey.currentState.validate())
      {
        setState(() {
          isLoading = true;
        });
        bool allselected = true;
        for(int i=0; i < 3; i++) {
          if(_images[i] == null) {
            print('image$i: is null');
            allselected = false;
            break;
          }
        }
        if(allselected)
          {
            if(selectedSizes.isNotEmpty)
              {
                List<String> urls = <String>[];
                final FirebaseStorage storage = FirebaseStorage.instance;
                for(int i=0; i < 3; i++)
                  {
                    var id = Uuid();
                    String picID = '${id.v1()}.jpg';
                    StorageUploadTask task = storage.ref().child(picID).putFile(_images[i]);
                    StorageTaskSnapshot snap = await task.onComplete.then((snapshot)=>snapshot);
                    String url = await snap.ref.getDownloadURL();
                    urls.add(url);
                  }
                _productService.createProduct({
                  "name":_name.text,
                  "price":double.parse(_price.text),
                  "sizes":selectedSizes,
                  "picture":urls,
                  "quantity":int.parse(_quantity.text),
                  "brand":_currentBrand,
                  "category":_currentCategory
                });
                Fluttertoast.showToast(msg: 'Product added');
                // _formKey.currentState.reset();
              }
            else
              {
                Fluttertoast.showToast(msg: 'select at least one size.');
              }
          }
        else
          {
            Fluttertoast.showToast(msg: 'select all image.');
          }
        setState(() {
          isLoading = false;
        });
      }
  }
}
