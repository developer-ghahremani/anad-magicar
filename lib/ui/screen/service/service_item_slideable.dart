import 'package:anad_magicar/common/constants.dart';
import 'package:anad_magicar/data/rest_ds.dart';
import 'package:anad_magicar/model/apis/api_service.dart';
import 'package:anad_magicar/model/message.dart';
import 'package:anad_magicar/model/viewmodel/service_vm.dart';
import 'package:anad_magicar/repository/center_repository.dart';
import 'package:anad_magicar/translation_strings.dart';
import 'package:anad_magicar/ui/screen/service/register_service_page.dart';
import 'package:anad_magicar/ui/screen/service/service_form.dart';
import 'package:anad_magicar/utils/date_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:anad_magicar/widgets/slidable_list/flutter_slidable.dart';
import 'package:anad_magicar/utils/dart_helper.dart';
import 'package:anad_magicar/widgets/animated_dialog_box.dart';

class ServiceItemSlideable extends StatefulWidget {
  ApiService serviceItem;
  ServiceItemSlideable({Key key,this.serviceItem}) : super(key: key);

  @override
  _ServiceItemSlideableState createState() {
    return _ServiceItemSlideableState();
  }
}

class _ServiceItemSlideableState extends State<ServiceItemSlideable> {

  SlidableController slidableController;
  Animation<double> _rotationAnimation;
  Color _fabColor = Colors.blue;


  _onConfirmToDelete(ApiService sItem,BuildContext context,bool mode,int type) async {

    sItem.RowStateType=mode ? Constants.ROWSTATE_TYPE_UPDATE :
    Constants.ROWSTATE_TYPE_DELETE;
    if(!mode) {
      var result = await restDatasource.saveCarService(sItem);
      if (result != null) {
        if (result.IsSuccessful) {
          centerRepository.showFancyToast(result.Message);
          changeServiceNotyBloc.updateValue(new Message(type: 'SERVICE_DELETED',index: sItem.ServiceId));
        }
        else {
          centerRepository.showFancyToast(result.Message);
        }
      }
      Navigator.pop(context);
    }
    else{
      Navigator.pushNamed(context, RegisterServicePageState.route,arguments: new ServiceVM(carId: sItem.CarId,
          editMode: true, service: sItem));
    }
  }

  deleteService(ApiService sItem,BuildContext context,bool mode) async{
    if(mode) {
      Navigator.pushNamed(context, RegisterServicePageState.route,arguments: new ServiceVM(carId:sItem.CarId,
          editMode: true, service: sItem));
    } else {
      await animated_dialog_box.showScaleAlertBox(
          title: Center(child: Text(
              Translations.current.confimDelete())),
          context:context,
          firstButton:Builder(builder: ( BuildContext newcontext) {
            return MaterialButton(
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(40),
    ),
    color: Colors.white,
    child: Text(Translations.current.yes()),
    onPressed: () async {
         _onConfirmToDelete(sItem, newcontext, mode, 0);
    },
    );},),
          secondButton: Builder(builder: ( BuildContext context) {
            return MaterialButton(

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              color: Colors.white,
              child: Text(Translations.current.no()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            );
          },
          ),
          icon: Icon(Icons.info_outline, color: Colors.red,),
          yourWidget: Container(
            child: Text(Translations.current.areYouSureToDelete()),
          ));
    }
  }


  _onUpdateService(ApiService sItem,BuildContext context,bool mode,int type) async {

    sItem.RowStateType= Constants.ROWSTATE_TYPE_UPDATE;
    sItem.ServiceStatusConstId=type;

    if(mode || type==Constants.SERVICE_DONE || type==Constants.SERVICE_NOTDONE) {
      Navigator.pushNamed(context, RegisterServicePageState.route,arguments: new ServiceVM(carId: sItem.CarId,
          editMode: true, service: sItem));
    } else {
      sItem.RowStateType= Constants.ROWSTATE_TYPE_DELETE;
      var result = await restDatasource.saveCarService(sItem);
      if (result != null) {
        if (result.IsSuccessful) {
          centerRepository.showFancyToast(result.Message);
          Navigator.of(context).pop();
          // RxBus.post(new ChangeEvent(type:"SERVICE",message: 'DELETED'));
          changeServiceNotyBloc.updateValue(new Message(type: 'SERVICE_DELETED',index: sItem.ServiceId));
        }
        else {
          centerRepository.showFancyToast(result.Message);
        }
      }

    }
  }


  Widget _getSlidableWithDelegates(
      BuildContext context, int serviceId, Axis direction) {
    final  item=widget.serviceItem;

    return Slidable.builder(
      key: Key(item.ServiceId.toString()),
      controller: slidableController,
      direction: direction,
      dismissal:null, /*SlidableDismissal(
        child: SlidableDrawerDismissal(),
        closeOnCanceled: true,
        onWillDismiss: (item.ServiceId == serviceId)
            ? null
            : (actionType) {
          return showDialog<bool>(
            context: context,
            builder: (context) {
              return null;//deleteService(item, context, false);
            },
          );
        },
        onDismissed: (actionType) {

          setState(() {

          });
        },
      ),*/
      actionPane: _getActionPane(1),
      actionExtentRatio: 0.25,
      child: Builder(
        builder: (BuildContext context) {
          return HorizontalListItem(widget.serviceItem);},),
      actionDelegate: (widget.serviceItem.ServiceStatusConstId==Constants.SERVICE_DONE) ? null  :
      SlideActionBuilderDelegate(
          actionCount: 2,
          builder: (context, index, animation, renderingMode) {
            if(index==0){
              return IconSlideAction(
                caption: Translations.current.actionService(),
                color: renderingMode == SlidableRenderingMode.slide
                    ? Colors.indigo.withOpacity(animation.value)
                    : Colors.indigo,
                icon: Icons.done_all,
                onTap: () {  _onUpdateService(item,context,false,Constants.SERVICE_DONE);},
              );
            }
           else {
              return IconSlideAction(
                  caption: Translations.current.notDoneService(),
                  color: renderingMode == SlidableRenderingMode.slide
                      ? Colors.indigo.withOpacity(animation.value)
                      : Colors.indigo,
                  icon: Icons.snooze,
                  onTap: () { _onUpdateService(item,context,false,Constants.SERVICE_NOTDONE);},
              );
            }
          }),
      secondaryActionDelegate: (widget.serviceItem.ServiceStatusConstId==Constants.SERVICE_DONE) ? null : SlideActionBuilderDelegate(
          actionCount: 2,

          builder: (context, index, animation, renderingMode) {
            if (index == 0) {
              return IconSlideAction(
                caption: Translations.current.delete(),
                color: renderingMode == SlidableRenderingMode.slide
                    ? Colors.red.withOpacity(animation.value)
                    : Colors.red,
                icon: Icons.delete,
                onTap: () { deleteService(item, context, false);},
              );
            }else {
                return IconSlideAction(
                  caption: Translations.current.edit(),
                  color: renderingMode == SlidableRenderingMode.slide
                      ? Colors.blue.withOpacity(animation.value)
                      : (renderingMode == SlidableRenderingMode.dismiss
                      ? Colors.blue
                      : Colors.green),
                  icon: Icons.archive,
                  onTap: ()  {
                         deleteService(item,context,true);
                  },
                );

            }
          }),
    );
  }
  void handleSlideAnimationChanged(Animation<double> slideAnimation) {
    setState(() {
      _rotationAnimation = slideAnimation;
    });
  }

  void handleSlideIsOpenChanged(bool isOpen) {
    setState(() {
      _fabColor = isOpen ? Colors.green : Colors.blue;
    });
  }
  static Widget _getActionPane(int index) {
    switch (index % 4) {
      case 0:
        return SlidableBehindActionPane();
      case 1:
        return SlidableStrechActionPane();
      case 2:
        return SlidableScrollActionPane();
      case 3:
        return SlidableDrawerActionPane();
      default:
        return null;
    }
  }

  static Color _getAvatarColor(int index) {
    switch (index % 4) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.indigoAccent;
      default:
        return null;
    }
  }

  static String _getSubtitle(int index) {
    switch (index % 4) {
      case 0:
        return 'SlidableBehindActionPane';
      case 1:
        return 'SlidableStrechActionPane';
      case 2:
        return 'SlidableScrollActionPane';
      case 3:
        return 'SlidableDrawerActionPane';
      default:
        return null;
    }
  }

  void _showSnackBar(BuildContext context, String text) {
    Scaffold.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void initState() {
    slidableController = SlidableController(
      onSlideAnimationChanged: handleSlideAnimationChanged,
      onSlideIsOpenChanged: handleSlideIsOpenChanged,
    );
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return _getSlidableWithDelegates(context, widget.serviceItem.ServiceId, Axis.horizontal);
  }
}
class HorizontalListItem extends StatelessWidget {

  HorizontalListItem(this.item);
  final ApiService item;
  bool isDurational;
  String serviceTypeTitle='';

  @override
  Widget build(BuildContext context) {
    bool isDone=item.ServiceStatusConstId==Constants.SERVICE_DONE;
    String dateTitle=Translations.current.serviceDate();
    if(isDone){
      dateTitle=Translations.current.serviceDoneDate();
    }

    isDurational=item.serviceType.ServiceTypeConstId==Constants.SERVICE_TYPE_DURATIONALITY;
    if(isDurational) {
      serviceTypeTitle=Translations.current.serviceTypeIsDurational();
    }
    else{
      serviceTypeTitle=Translations.current.serviceTypeIsFunctionality();
    }


    int count=0;
    if(isDurational) {

      if(item.serviceType.DurationTypeConstId==Constants.SERVICE_DURATION_DAY){
        String sDate=item.ServiceDate;
        String todayeDate=DateTimeUtils.getDateJalali();
       count= DateTimeUtils.diffDaysFromDateToDate3(todayeDate, sDate);
      }else if(item.serviceType.DurationTypeConstId==Constants.SERVICE_DURATION_MONTH){
        String sDate=item.ServiceDate;
        String todayeDate=DateTimeUtils.getDateJalali();
        count= DateTimeUtils.diffDaysFromDateToDate3(todayeDate, sDate);
      } else if(item.serviceType.DurationTypeConstId==Constants.SERVICE_DURATION_YEAR){
        String sDate=item.ServiceDate;
        String todayeDate=DateTimeUtils.getDateJalali();
        count= DateTimeUtils.diffDaysFromDateToDate3(todayeDate, sDate);
      }
    }
    else {
      int distance=0;
      int coutnvalue=0;
      if(item.car!=null && item.car.totlaDistance!=null)
        distance=item.car.totlaDistance;
      if(item.serviceType.DurationCountValue!=null)
        coutnvalue=item.serviceType.DurationCountValue;
        count= coutnvalue-distance;
    }
    return Container(
      alignment: Alignment.centerLeft,
      color: Colors.white,
      width: MediaQuery.of(context).size.width-10,
      height: 160.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
       //mainAxisSize: MainAxisSize.max,
        children: <Widget>[

          Expanded(
            child: Padding(
          padding: EdgeInsets.only(left: 10.0,right: 10.0),
      child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
              Text(DartHelper.isNullOrEmptyString(serviceTypeTitle),style: TextStyle(fontSize: 15.0)),
      Container(
        width: 90.0,
      height: 50.0,
      decoration: BoxDecoration(
        color: item.ServiceStatusConstId==Constants.SERVICE_DONE ? Colors.greenAccent :
        item.ServiceStatusConstId==Constants.SERVICE_NOTDONE ? Colors.pinkAccent :
        item.ServiceStatusConstId==Constants.SERVICE_CANCEL ? Colors.blueAccent :
        item.ServiceStatusConstId==Constants.SERVICE_NEAR ? Colors.amberAccent :
        Colors.white,
      ),

        child: Text(DartHelper.isNullOrEmptyString( item.serviceType.ServiceTypeTitle),
            overflow: TextOverflow.fade,softWrap: true,textAlign: TextAlign.center,
             style: TextStyle(fontSize: 10.0,color: item.ServiceStatusConstId==Constants.SERVICE_NOTDONE ? Colors.white : Colors.white)),
        //foregroundColor: Colors.white,
      ),
      ],
    ),
          ),
          ),
         isDone ? Container() :
         Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10.0,right: 10.0),
              child:
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(Translations.current.remaindToNextService(),style: TextStyle(fontSize: 15.0)),
                  Text(DartHelper.isNullOrEmptyString(count.toString()),style: TextStyle(fontSize: 15.0),),
                ],
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10.0,right: 10.0),
          child:
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(dateTitle,style: TextStyle(fontSize: 15.0)),
                  Text(DartHelper.isNullOrEmptyString(isDone ? item.ActionDate :  item.ServiceDate),style: TextStyle(fontSize: 15.0),),
                  ],
            ),
            ),
          ),
       isDone ?   Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10.0,right: 10.0),
              child:
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(Translations.current.description(),style: TextStyle(fontSize: 15.0)),
                  Text(DartHelper.isNullOrEmptyString(  item.Description),style: TextStyle(fontSize: 15.0),),
                ],
              ),
            ),
          ) :
           Container(),
          isDone ?   Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10.0,right: 10.0),
              child:
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(Translations.current.serviceCost(),style: TextStyle(fontSize: 15.0)),
                  Text(DartHelper.isNullOrEmptyString(  item.ServiceCost.toString()),style: TextStyle(fontSize: 15.0),),
                ],
              ),
            ),
          ) :
          Container(),

        ],
      ),
    );
  }
}

