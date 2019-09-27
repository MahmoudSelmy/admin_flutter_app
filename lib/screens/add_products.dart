import 'package:admin_flutter_app/db/brand.dart';
import 'package:admin_flutter_app/db/category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  List<DocumentSnapshot> brands = <DocumentSnapshot>[];
  List<DocumentSnapshot> categories = <DocumentSnapshot>[];

  List<DropdownMenuItem<String>> categoriesList = <DropdownMenuItem<String>>  [];
  List<DropdownMenuItem<String>> brandsList = <DropdownMenuItem<String>>  [];

  String _currentCategory = "Category";
  String _currentBrand = "Brand";

  CategoryService _categoryService = CategoryService();
  BrandService _brandService = BrandService();

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
        child: ListView(
          children: <Widget>[
            Row(
              children: <Widget>[
                buildExpanded(),
                buildExpanded(),
                buildExpanded(),
              ],
            ),
            buildNameTextField(),
            buildSelector(categoriesList, _currentCategory, changeSelectedCategory),
            buildSelector(brandsList, _currentBrand, changeSelectedBrand),
          ],
        ),
      ),
    );
  }

  Center buildSelector(List<DropdownMenuItem<String>> items, String value, Function onChange) {
    return Center(
            child: DropdownButton(
              items: items,
              value: value,
              onChanged: onChange,
            ),
          );
  }

  Padding buildNameTextField() {
    return Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _name,
              decoration: InputDecoration(hintText: 'Product name'),
              validator: (value){
                if(value.isEmpty)
                  {
                    return "Product name can not be empty";
                  }
                return null;
              },
            ),
          );
  }

  Expanded buildExpanded() {
    return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlineButton(
                  borderSide: BorderSide(color: grey.withOpacity(0.5), width:  2.5),
                  onPressed: (){},
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
                    child: Icon(Icons.add, color: grey,),
                  ),
                ),
              ),
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
}
