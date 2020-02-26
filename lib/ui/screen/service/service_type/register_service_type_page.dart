import 'package:anad_magicar/model/viewmodel/reg_service_type_vm.dart';
import 'package:anad_magicar/ui/screen/base/main_page.dart';
import 'package:anad_magicar/ui/screen/service/service_type/register_service_type_form.dart';
import 'package:flutter/material.dart';

class RegisterServiceTypePage extends StatefulWidget {
  RegServiceTypeVM regServiceTypeVM;
  RegisterServiceTypePage({Key key,this.regServiceTypeVM}) : super(key: key);

  @override
  RegisterServicePageTypeState createState() {
    return RegisterServicePageTypeState();
  }
}

class RegisterServicePageTypeState extends MainPage<RegisterServiceTypePage> {

  static final String route='/registerservicetypepage';

  @override
  void dispose() {
    super.dispose();
  }


  @override
  List<Widget> actionIcons() {
    // TODO: implement actionIcons
    return null;
  }

  @override
  String getCurrentRoute() {
    // TODO: implement getCurrentRoute
    return route;
  }

  @override
  FloatingActionButton getFab() {
    // TODO: implement getFab
    return null;
  }

  @override
  initialize() {
    // TODO: implement initialize
    return null;
  }

  @override
  Widget pageContent() {
    // TODO: implement pageContent
    return new RegisterServiceTypeForm(serviceTypeVM:new RegServiceTypeVM(carId: widget.regServiceTypeVM.carId, route: widget.regServiceTypeVM.route),);
  }

  @override
  int setCurrentTab() {
    // TODO: implement setCurrentTab
    return 0;
  }

}
