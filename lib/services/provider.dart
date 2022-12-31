import 'package:flutter/cupertino.dart';

class Btn with ChangeNotifier {
  changeBtn() {
    notifyListeners();
  }
}

class HomeList with ChangeNotifier {
  updateHomeList() {
    notifyListeners();
  }
}

class updateRowList with ChangeNotifier {
  updateList() {
    notifyListeners();
  }
}
