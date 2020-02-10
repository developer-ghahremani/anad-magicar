import 'dart:async';
import 'dart:io';
import 'package:anad_magicar/bloc/theme/change_theme_bloc.dart';
import 'package:anad_magicar/bloc/values/notify_value.dart';
import 'package:anad_magicar/components/button.dart';

import 'package:anad_magicar/components/countdowntimer/progress_card.dart';
import 'package:anad_magicar/components/custom_progress_dialog.dart';
import 'package:anad_magicar/components/image_picker_handler.dart';
import 'package:anad_magicar/components/no_data_widget.dart';
import 'package:anad_magicar/data/ds/plan_ds.dart';
import 'package:anad_magicar/data/rest_ds.dart';
import 'package:anad_magicar/date/helper/shamsi_date.dart';
import 'package:anad_magicar/model/apis/api_user_model.dart';
import 'package:anad_magicar/model/invoice/invoice.dart';
import 'package:anad_magicar/model/invoice/invoice_detail.dart';
import 'package:anad_magicar/model/message.dart';
import 'package:anad_magicar/model/plan_model.dart';
import 'package:anad_magicar/model/user/user.dart';
import 'package:anad_magicar/repository/center_repository.dart';
import 'package:anad_magicar/repository/pref_repository.dart';
import 'package:anad_magicar/translation_strings.dart';
import 'package:anad_magicar/ui/screen/base/main_page.dart';

import 'package:anad_magicar/utils/dart_helper.dart';
import 'package:anad_magicar/utils/date_utils.dart';
import 'package:anad_magicar/widgets/bottom_sheet_custom.dart';
import 'package:anad_magicar/widgets/curved_navigation_bar.dart';

import 'package:anad_magicar/widgets/magicar_appbar.dart';
import 'package:anad_magicar/widgets/magicar_appbar_title.dart';

import 'package:flutter/material.dart';
//import 'package:flutter_datetime_picker/flutter_datetime_picker.dart' as dtpicker;
import 'package:anad_magicar/components/date_picker/flutter_datetime_picker.dart' as dtpicker;
import 'package:url_launcher/url_launcher.dart';




class CurrentPlanForm extends StatefulWidget {
  SaveUserModel user;
  InvoiceModel currentInvoice;
  PlanModel currentPlan;
  CurrentPlanForm({
    @required this.user,
   // @required this.currentPlan,
    @required this.currentInvoice,
  });

  @override
  CurrentPlanFormState createState() {
    return CurrentPlanFormState();
  }


}
class CurrentPlanFormState extends MainPage<CurrentPlanForm>
    with TickerProviderStateMixin{

  NotyBloc<Message> _notygetCurrentPlans;
  bool hasInternet=true;
  ProgressDialog _progressDialog = ProgressDialog();
  Future<List<InvoiceModel>> finvoices;
  static  List<InvoiceModel> invoices=new List();
  List<InvoiceModel> invs;
  Future<PlanModel> currentPlan;
  static RestDatasource restDS;
  PlanDS planDS;
  File _image;
  AnimationController _controller;
  ImagePickerHandler imagePicker;

  List<Map> collections =new List();

  bool isDark=false;
  User user2;
  String fullName="";
  int userId=0;
  static int _invoiceCount=0;

  Future<bool> getAppTheme() async{
    int dark=await changeThemeBloc.getOption();
    setState(() {
      if(dark==1)
        isDark=true;
      else
        isDark=false;
    });

  }

  Future<List<InvoiceModel>> loadCurrentPlan() async {

    _progressDialog.showProgressDialog(context,textToBeDisplayed: Translations.current.loadingdata());
     invoices=new List();
    invoices=await restDS.getInvoiceByUserId(userId);
    if(invoices==null)
      invoices=centerRepository.getInvoices().where((inv)=> inv.UserId==userId).toList();

    if(invoices!=null &&
    invoices.length>0) {
      _invoiceCount = invoices.length;
      if (centerRepository.getPlans() != null &&
          centerRepository
              .getPlans()
              .length > 0) {
        List<PlanModel> plans = centerRepository.getPlans();
        for (var invs in invoices) {

          List<PlanModel> findPlan = plans.where((p) => p.PlanId == invs.PlanId)
              .toList();
          if (findPlan != null && findPlan.length > 0) {

            PlanModel planModel = findPlan.first;
            invs.planModel = planModel;
          }
        }
      }
      /*PlanModel result = await planDS.getById(
          BaseRestDS.GET_PLAN_BY_PLANID_URL, invoices[0].PlanId);*/
      return invoices;
    }
    else
      {
      }
    return null;
  }





  List<Widget> getInvoiceDetailsTiles(BuildContext context, InvoiceModel invoiceModel) {
    List<Widget> list = [];
    if (invoices != null &&
    invoiceModel.invoiceDetailModel!=null &&
    invoiceModel.invoiceDetailModel.length>0) {
      for (InvoiceDetailModel i in invoiceModel.invoiceDetailModel) {
        String startDate = invoiceModel.StartDate!=null ? invoiceModel.StartDate : '';
        String desc =invoiceModel.Description!=null ?  invoiceModel.Description : '';
        String endDate = invoiceModel.EndDate!=null ? invoiceModel.EndDate : '';
        String invoiceDate = invoiceModel.InvoiceDate!=null ? invoiceModel.InvoiceDate : '';
        String remainAmount = '';
        String remainCount = '';
        bool isActive=startDate!='';
        remainAmount = i.RemainAmount!=null ? i.RemainAmount.toString() : '' ;
        remainCount =i.RemainCount!=null ? i.RemainCount.toString() : '';
        double amount = invoiceModel.Amount;
        amount=amount!=null ? amount : 0;

        list.add(ListTile(
          leading: IconButton(icon:Icon( Icons.details,color: Colors.blueAccent,),onPressed: (){},iconSize: 15.0,),
          title: Text(invoiceDate + " - " + startDate + ' - ' + endDate +' '+ Translations.current.planStatus()+' : '+ (!isActive ?
          Translations.current.deactive() :
          Translations.current.active() ) ),
          subtitle: Text(
              amount.toString() + ' # ' + remainAmount + " | " + remainCount +
                  ' # ' + Translations.current.description() + ' : ' + desc),
          trailing: Container(width: 0.0,height: 0.0,)
        ));
      }
    }
    else
      {
        list.add(new Text(Translations.current.noDatatoShow()));
      }
    return list;
  }





  _toggle()
  {
    Navigator.of(context).pushNamed('/home');
  }
  _showBottomSheetPlans(BuildContext cntext, List<PlanModel> plns)
  {
    showModalBottomSheetCustom(context: cntext ,
        builder: (BuildContext context) {
          return CurrentPlansForm(
            notyGetCurrentPlan: _notygetCurrentPlans ,
            userId: userId,);
        });
  }
  _addPayment()
  {
    _showBottomSheetPlans(context, centerRepository.getPlans());

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }



  Widget _mainListBuilder(BuildContext context, int index,List<InvoiceModel> planModel) {
     return ExpansionTile(
         title: Card1(invoices:invoices,invoiceModel: invoices[index],),
         children: getInvoiceDetailsTiles(context, invoices[index]),
    );
  }

  Widget _buildListItem() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3.0),
        child: Image.asset('assets/images/user2.png', fit: BoxFit.fill),
      ),
    );
  }

  Container _buildSectionHeader(BuildContext context,List<InvoiceModel> planModel) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(Translations.of(context).currentPlan(), style: Theme.of(context).textTheme.title,),
          FlatButton(
            onPressed: (){ Navigator.pop(context); },
            child: Text(Translations.of(context).exit(), style: TextStyle(color: Colors.blue),),
          )
        ],
      ),
    );
  }

  Container _buildInvoicesRow(List<InvoiceModel> invoiceModels,InvoiceModel invModel) {
    return  Container(
      height: 100.0,
    child:
       Card1(invoices: invoiceModels, invoiceModel: invModel),
    );
  }



  Container _buildHeader(BuildContext context,List<InvoiceModel> planModel) {
    return  Container(
      margin: EdgeInsets.only(top: 10.0),
      height:300.0,
      child: Stack(
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(top: 10.0, left: 40.0, right: 40.0, bottom: 10.0),
            child: Material(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)),
              elevation: 5.0,
              color: Colors.white,
              child: Column(
                children: <Widget>[
                  SizedBox(height: 1.0,),
                  Container(
                    height: 50.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: ListTile(
                            title: Text(widget.user!=null && !DartHelper.isNullOrEmpty(widget.user.MobileNo) ? widget.user.MobileNo : "موبایل",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold,),),
                            subtitle: Text(Translations.of(context).mobile(),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.0,color: Colors.redAccent) ),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(widget.user!=null ? widget.user.UserName : 'کد کاربری',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),),
                            subtitle: Text(Translations.current.userName().toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.0) ),
                          ),
                        ),

                      ],
                    ),
                  ),
                  SizedBox(height: 5.0,),
                  Container(
                    height: 50.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: ListTile(
                            title: Text(widget.user!=null ? widget.user.FirstName : "نام",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold,),),
                            subtitle: Text(Translations.of(context).firstName(),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.0,color: Colors.redAccent) ),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(widget.user!=null ? widget.user.LastName : 'نام خانوادگی',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),),
                            subtitle: Text(Translations.current.lastName().toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.0) ),
                          ),
                        ),

                      ],
                    ),
                  ),
                  SizedBox(height: 5.0,),
                  Container(
                    height: 50.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: ListTile(
                            title: Text(widget.user!=null ? widget.user.FirstName : "نام",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold,),),
                            subtitle: Text(Translations.of(context).firstName(),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.0,color: Colors.redAccent) ),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(widget.user!=null ? widget.user.LastName : 'نام خانوادگی',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),),
                            subtitle: Text(Translations.current.lastName().toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.0) ),
                          ),
                        ),

                      ],
                    ),
                  ),
                  SizedBox(height: 5.0,),
                  Container(
                    height: 50.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: ListTile(
                            title: Text(widget.user!=null ? widget.user.FirstName : "نام",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold,),),
                            subtitle: Text(Translations.of(context).firstName(),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.0,color: Colors.redAccent) ),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(widget.user!=null ? widget.user.LastName : 'نام خانوادگی',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),),
                            subtitle: Text(Translations.current.lastName().toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.0) ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  @override
  List<Widget> actionIcons() {
    // TODO: implement actionIcons
    return null;
  }

  @override
  String getCurrentRoute() {
    // TODO: implement getCurrentRoute
    return '/plans';
  }

  @override
  FloatingActionButton getFab() {
    // TODO: implement getFab
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: (){
        _addPayment();
      },
      elevation: 0.0,
    );
  }

  @override
  initialize() {
    // TODO: implement initialize
    _notygetCurrentPlans=new NotyBloc<Message>();

    if(widget.user==null || widget.user.UserId==null)
    {
      prefRepository.getLoginedUserId().then((res){
        if(res!=null)
          userId=res;
      });
    }
    else
      userId=widget.user.UserId;

    _progressDialog=new ProgressDialog();
    restDS=new RestDatasource();
    planDS=new PlanDS();
    _controller = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    finvoices=loadCurrentPlan();
    return null;
  }

  @override
  Widget pageContent() {
    // TODO: implement pageContent
    return StreamBuilder<Message>(
      stream: _notygetCurrentPlans.noty,
      initialData: null,
      builder: (BuildContext c, AsyncSnapshot<Message> data)
      {
        if (data != null && data.hasData) {
          Message msg=data.data;
          if(msg!=null &&
              msg.type=='GET_CURRENT_PLAN')
            finvoices=loadCurrentPlan();
        }
        return
          Stack(
            overflow: Overflow.visible,
            children: <Widget>[
              FutureBuilder<List<InvoiceModel>>(
                future: finvoices,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    _progressDialog.dismissProgressDialog(context);
                    invs = snapshot.data;

                    return
                      Stack(
                        children: <Widget>[
                          Container(
                            height: 0.0,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [
                                    Colors.indigo.shade300,
                                    Colors.indigo.shade500
                                  ]
                              ),
                            ),
                          ),
                          /*Container(
                  margin:EdgeInsets.only(top:60.0),
                  height: MediaQuery.of(context).size.height-10,
                  child:*/
                          Padding(padding: EdgeInsets.only(top: 60.0),
                            child:
                            ListView.builder(
                              physics: new PageScrollPhysics(),
                              scrollDirection: Axis.vertical,
                              itemCount: _invoiceCount,
                              itemBuilder: (context, index) =>
                                  _mainListBuilder(context, index, invs),
                            ),
                          ),

                        ],
                      );
                  }
                  return Center(
                      child:
                      new NoDataWidget()
                  );
                },
              ),
              /*Positioned(
                child:
                new MagicarAppbar(
                  backgroundColorAppBar: Colors.transparent,
                  title: new MagicarAppbarTitle(
                    *//*image: Image.asset('assets/images/current_plans.png'),
                  imageFunc: () {
                   // showCurrentPlans();
                  },*//*
                    currentColor: Colors.indigoAccent,
                    actionIcon: null*//*Icon(
                    Icons.add_circle_outline, color: Colors.redAccent,
                    size: 20.0,)*//*,
                    actionFunc: null,//_addPayment,
                  ),
                  actionsAppBar: hasInternet ? null : [
                    new Row(
                      children: <Widget>[
                        Image.asset('assets/images/no_internet.png'),
                      ],
                    )
                  ],
                  elevationAppBar: 0.0,
                  iconMenuAppBar: Icon(
                    Icons.arrow_back, color: Colors.indigoAccent,),
                  toggle: _toggle,
                ),
              ),*/
            ],
          );
      },
    );
  }

  @override
  int setCurrentTab() {
    // TODO: implement setCurrentTab
    return 4;
  }




}


class Card1 extends StatelessWidget {

  List<InvoiceModel> invoices;
  InvoiceModel invoiceModel;

  Card1({
    @required this.invoices,
    @required this.invoiceModel,

  });

  RestDatasource restDS;
  bool isActive=false;

  activateInvoice(BuildContext context, InvoiceModel inv) async {
    restDS=new RestDatasource();
    String startDate=Jalali.now().toString();
    restDS.invoicePlanActivation(inv.InvoiceId, startDate).then((res) {
      if (res.IsSuccessful) {
        centerRepository.showFancyToast(res.Message != null ? res.Message :
        Translations.current.activateSuccessful());
      }
      else {
        centerRepository.showFancyToast(res.Message != null ? res.Message :
        Translations.current.activateunSuccessful());
      }
      /*dtpicker.DatePicker.showDatePicker(context,
        theme: dtpicker.DatePickerTheme(
          cancelStyle:  TextStyle(fontFamily: 'IranSans',fontSize: 28.0,color: Colors.pinkAccent),
          itemStyle: TextStyle(fontFamily: 'IranSans',fontSize: 20.0),
          doneStyle: TextStyle(fontFamily: 'IranSans',fontSize: 28.0,color: Colors.green)
        ),
        showTitleActions: true,
        minTime: DateTime(1397, 1, 1),
        maxTime: DateTime(1410, 1, 1),
        onChanged: (date) {
          //print('change $date');
        }, onConfirm: (date) {
          //print('confirm $date');
          String startDate=date.year.toString()+'/'+date.month.toString()+'/'+date.day.toString();
          restDS.invoicePlanActivation(inv.InvoiceId, startDate).then((res){
            if(res.IsSuccessful)
            {
              centerRepository.showFancyToast( res.Message!=null ? res.Message :
                  Translations.current.activateSuccessful());
            }
            else
            {
              centerRepository.showFancyToast( res.Message!=null ? res.Message :
                  Translations.current.activateunSuccessful());
            }
          });
        }, currentTime: DateTime.now(), locale: dtpicker.LocaleType.fa);*/
    });
  }

  Widget remainDayProgress(double progressValue) {

    var progress = Container(
       width:80.0,
    height:80.0,
    child:
      ProgressCard(
        width: 80.0,
        isOn: false,
        isOff: true,
        progress:progressValue ,
      ),
    );

    return progress;
  }

  Widget remainAmountProgress(double progressValue) {

    var progress = Container(
      width:80.0,
      height:80.0,
      child:
      ProgressCard(
        width: 80.0,
        isOn: false,
        isOff: true,
        progress: progressValue,
      ),
    );

    return progress;
  }


  @override
  Widget build(BuildContext context) {
    isActive=(invoiceModel.StartDate!=null &&
        invoiceModel.StartDate!='');
    return new Padding(
      padding: EdgeInsets.only(top: 10.0,bottom: 10.0),
      child: new Stack(
                                        //overflow: Overflow.visible,
                                        children: <Widget>[
      new Container(
        height:48.0,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(3),
      ),
                                          child: new Padding(
                                          padding: EdgeInsets.only(right: 5.0,left: 5.0),
                                          child:
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              new Text(Translations.current.currentPlan(),
                                                  style: new TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18.0,
                                                  )
                                              ),

                                            ],
                                          ),
    ),
      ),
                                          new Container(

                                            margin: EdgeInsets.only(top: 40.0,right: 5.0),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).cardColor,
                                              borderRadius: BorderRadius.circular(3),
                                              border: Border.all(color: Colors.indigoAccent.withOpacity(0.0),width: .5)
                                            ),
                                            constraints: new BoxConstraints.expand(

                                              height: 420.0,
                                              width: MediaQuery.of(context).size.width*0.95,
                                            ),
                                            child: new Padding(
                                              padding: EdgeInsets.only(right: 5.0,left: 5.0),
                                              child:
                                            new Column(

                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Row(
                                            mainAxisAlignment: MainAxisAlignment.center ,

                                            children: <Widget>[
                                                      new Text(DartHelper.isNullOrEmptyString( invoiceModel.DisplayName),
                                                          style: new TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 18.0,
                                                          )
                                                      ),
                                                    ],
                                                  ),

                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween ,

                                                children: <Widget>[
                                                  new Text(Translations.current.invoiceDate(),style: new TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18.0,
                                                  )),
                                                     new Text( DartHelper.isNullOrEmptyString(invoiceModel
                                                      .InvoiceDate),
                                                      style: new TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 18.0,
                                                      )

                                                  ),
                                                  ],
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween ,

                                                children: <Widget>[
                                                  new Text(Translations.current.description(),style: new TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18.0,
                                            )),
                                                    new Text( DartHelper.isNullOrEmptyString(invoiceModel.Description),
                                                      style: new TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16.0,
                                                      )
                                                  ),
                                                  ],
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween ,

                                                children: <Widget>[
                                                  new Text(Translations.current.invoiceAmount(),style: new TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18.0,
                                            )),
                                                     new Text( DartHelper.isNullOrEmptyString(invoiceModel.Amount.toString()),
                                                      softWrap: true,
                                                      overflow: TextOverflow.fade,
                                                      style: new TextStyle(color: Colors.pink[200],
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 18.0,
                                                      )

                                                  ),
                                                  ],
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween ,

                                                children: <Widget>[
                                                  new Text(Translations.current.planTitle(),
                                                style: new TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18.0,
                                                )),
                                                     new Text( (invoiceModel.planModel!=null ? DartHelper.isNullOrEmptyString( invoiceModel.planModel.PlanTitle) : ''),
                                                      style: new TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 18.0,
                                                      )
                                                  ),
                                                  ],
                                              ),
                                              /*Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween ,

                                                children: <Widget>[
                                                  new Text(Translations.current.fromDate() ,style: new TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18.0,
                                            )),
                                             new Text( invoiceModel.planModel!=null ?   DartHelper.isNullOrEmptyString( invoiceModel.planModel.FromDate) : ''),
                                                ],
                                             ),
                                              Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween ,
                                                  children: <Widget>[
                                                     new Text( Translations.current.toDate(),style: new TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0,
                                          )),
                                                     new Text( (invoiceModel.planModel!=null ? DartHelper.isNullOrEmptyString( invoiceModel.planModel.ToDate): ''),
                                                      style: new TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 18.0,
                                                      )
                                                  ),
                                                  ],
                                              ),*/
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: <Widget>[
                                                      remainDayProgress (DateTimeUtils.diffDaysFromDateToDate(invoiceModel.StartDate,invoiceModel.EndDate),),
                                                      remainAmountProgress((calcSumAmount(invoiceModel.invoiceDetailModel) / (invoiceModel.Amount!=null ? invoiceModel.Amount : calcSumAmount(invoiceModel.invoiceDetailModel)))),
                                                            ],
                                                  ),
                                                 new Padding(
                                                   padding: EdgeInsets.only(top: 1.0,bottom: 10.0),
                                                   child:
                                                  new Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: <Widget>[
                                                    /*!isActive ?  Text(Translations.current.activatePlan(),style: TextStyle(color: Colors.pinkAccent),) :
                                                    Text(Translations.current.planIsActive() ,style: TextStyle(color: Colors.green),),
*/
                                                      FlatButton(
                                                        padding: EdgeInsets.only(left: 0, right: 0),
                                                        child: !isActive ? Button(wid: 100.0, title: Translations.current.activatePlan(),color: Colors.indigoAccent.value) :
                                                        Container(width: 0.0,height: 0.0,),
                                                        onPressed: () {
                                                          activateInvoice(context, invoiceModel);
                                                        },

                                                      ),
                                                    ],
                                                  ),
                                                 ),
                                                ],
                                            ),
                                            ),
                                          ),

                                          new Positioned(
                                            right: 10.0,
                                            bottom: 20.0,
                                            child: new Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: <Widget>[
                                                /*isActive ?  new Icon(Icons.stars, color: Colors.greenAccent,
                                                    size: 28.0,) :*/
                                              Button(
                                                title: Translations.current.showDetails(),
                                                color: Colors.indigoAccent.value,
                                                wid: 100,)
                                                ]
                                            ),
                                          ),
                                        ],








      ),
    );
  }


  _showBottomSheetPlans(BuildContext cntext, List<PlanModel> plns)
    {
    showModalBottomSheetCustom(context: cntext ,
        builder: (BuildContext context) {
            return CurrentPlansForm();
    });
  }
  double calcSumAmount(List<InvoiceDetailModel> details )
  {
    double sum=0;
    for(var invd in details)
      {
        double val=invd.RemainAmount;
        if(val==null)
          val=0;
        sum+=val;
      }
    return sum;
  }

  Path _buildHeartPath() {
    return Path()
      ..moveTo(20, 15)
      ..cubicTo(20, 12, 15, 0, 30, 0)
      ..cubicTo(0, 0, 0, 37.5, 0, 37.5)
      ..cubicTo(0, 20, 20, 77, 20, 95)
      ..cubicTo(90, 77, 110, 55, 110, 37.5)
      ..cubicTo(110, 37.5, 110, 0, 80, 0)
      ..cubicTo(65, 0, 55, 12, 55, 15)
      ..close();
  }

}


class CurrentPlansForm extends StatelessWidget {

  List<PlanModel> plans=new List();
  int userId;
  NotyBloc<Message> notyGetCurrentPlan;
  CurrentPlansForm({
    this.notyGetCurrentPlan,
     this.plans,
    @required this.userId,
  });

  @override
  Widget build(BuildContext context) {

    plans=centerRepository.getPlans();

    return ListView.builder(
      itemCount: plans.length ,
        itemBuilder: (context,index) {
          return createPlansCard(context,userId, plans[index]);
    }
    );
  }
  _launchURL() async {
    const url = 'http://anadgps.com/payline/invoices/pay/f771e16a-d681-42e4-b43d-57c1df500420';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _buyCurrentPlanSelected(int userId,int planId) async{
    RestDatasource restDatasource=new RestDatasource();
    _launchURL();
     /*restDatasource.partialSaveInvoice(userId, planId).then((res) {
       if(res!=null )
         {
           if(res.IsSuccessful)
             {
               centerRepository.showFancyToast(Translations.current.buyPlanSuccessful());
               notyGetCurrentPlan.updateValue(new Message(type: 'GET_CURRENT_PLAN'));
             }
           else
             {
               centerRepository.showFancyToast(Translations.current.buyPlanUnSuccessful());
             }
         }
     });*/
  }

  Widget createPlansCard(BuildContext context,int userId, PlanModel plnModel)
  {

    var item= new Padding(
  padding: EdgeInsets.only(right: 5.0,left: 5.0,top: 4.0,bottom: 4.0),
  child:
    new Column(
      children: <Widget>[


        new Container(
          margin: EdgeInsets.only(top: 10.0,right: 5.0,left: 5.0),
          constraints: new BoxConstraints.expand(
            height: 230.0,
            width: MediaQuery.of(context).size.width*0.95,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            border: Border(),
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
          ),
          child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween ,
                  children: <Widget>[
                    new Text(' '+Translations.current.planTitle()+' : '+ DartHelper.isNullOrEmptyString( plnModel.PlanTitle),
                        style: new TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        )
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween ,

                  children: <Widget>[
                    new Text(' '+Translations.current.planCode()+' : '),
                        new Text(DartHelper.isNullOrEmptyString(plnModel.PlanCode+' '),
                        softWrap: true,
                        overflow: TextOverflow.fade,
                        style: new TextStyle(color: Colors.pink[200],
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                        )

                    ),
                  ],
                ),

          /*Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween ,

              children: <Widget>[
                new Text(' '+Translations.current.fromDate() +' ',style: new TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                )),
                   new Text( DartHelper.isNullOrEmptyString(plnModel.FromDate)+ ' ',
                       style: new TextStyle(
                         fontWeight: FontWeight.bold,
                         fontSize: 18.0,
                       )),
                    ],
          ),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween ,
                children: <Widget>[
                  new Text(Translations.current.toDate()+ ' ',style: new TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  )),
                  new Text(DartHelper.isNullOrEmptyString(plnModel.ToDate)+' ',
                    style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    )

                ),
                ],
            ),*/
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween ,
              children: <Widget>[
                new Text(' '+Translations.current.planCost()+' ',style: new TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                )),
                  new Text( DartHelper.isNullOrEmptyString(plnModel.Cost.toString()+ ' '),
                    style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    )
                ),
                ],
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween ,
              children: <Widget>[
                new Text(' '+Translations.current.description()+' ',style: new TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 18.0,
    )),
              new Text(DartHelper.isNullOrEmptyString(plnModel.Description)+' ',
                    softWrap: true,
                    overflow: TextOverflow.fade,
                    style: new TextStyle(color: Colors.pink[200],
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    )

                ),
                ],
          ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                   /* new Text(' '+Translations.current.buyPlan(),
                        style: new TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        )
                    ),*/
                    SizedBox(width: 10.0,),
                    GestureDetector(
                      onTap: () {
                        _buyCurrentPlanSelected(userId,plnModel.PlanId);
                        },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                          color: Colors.greenAccent,
                          border: Border.all(color: Colors.greenAccent,width: 1.0),
                        ),
                        width: 100.0,
                        height: 36.0,
                        child:
                            Center(
                              child:
                                Text(Translations.current.buyPlan(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white,fontSize: 20.0),)
                        //Icon(Icons.shopping_cart,color: Colors.green,size: 35.0,),),
                            ),
                      ),
                    ),
                  ],
                ),
              ]
          ),

        ),

       /* new Positioned(
          right: 0.0,
          bottom: -25.0,
          child: new Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                new Icon(Icons.star, color: Colors.greenAccent,
                  size: 20.0,),
              ]
          ),
        ),*/
      ],






),

    );
    return item;
  }



}