import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'test_expansion_list_item.dart';
import 'test_define.dart';

class TestExpansionPanelList extends StatefulWidget {
  _TestExpansionPanelListState createState() => _TestExpansionPanelListState();
}

class _TestExpansionPanelListState extends State<TestExpansionPanelList> {
  List<int> mList;   //组成一个int类型数组，用来控制索引
  List<ExpandStateBean> expandStateList;  //开展开的状态列表,ExpandStateBean是自定义的类

  //构造方法，调用这个类的时候自动执行
  _TestExpansionPanelListState(){
    mList=new List();
    expandStateList=new List();
    //遍历两个List进行赋值
    for(int i=0;i<1;i++){
      mList.add(i);
      expandStateList.add(ExpandStateBean(i,false));//item初始状态为闭着的
    }
  }

  //修改展开与闭合的内部方法
  _setCurrentIndex(int index,isExpand){
    setState(() {
      //遍历可展开状态列表
      expandStateList.forEach((item){
        if(item.index==index){
          //取反，经典取反方法
          item.isOpen=!isExpand;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TestDefine.mainViewBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: ExpansionPanelList(
          //交互回调属性，里面是个匿名函数
          expansionCallback: (index,bol){
            //调用内部方法
            _setCurrentIndex(index, bol);
          },
          //进行map操作，然后用toList再次组成List
          children: mList.map((index){
            //返回一个组成的ExpansionPanel
            return ExpansionPanel(
                backgroundColor: expandStateList[index].isOpen?TestDefine.expaBackgroundColorSelected:TestDefine.expaBackgroundColorNormal,
                headerBuilder: (context,isExpanded){
                  return Container(
                    color: isExpanded?TestDefine.expaBackgroundColorSelected:TestDefine.expaBackgroundColorNormal,
                    padding: EdgeInsets.fromLTRB(10, 15, 0, 0),
                    child: Text("播放器", style: TextStyle(color: Colors.white),),
                  );
                  // return TestExpansionPanelListItem();
                  // return ListTile(
                  //   title: Text('This is No.$index'),
                  // );
                },
                // body: ListTile(
                //   hoverColor: Colors.red,
                //   title: Text('expansion no.$index'),
                //   trailing: new Icon(Icons.arrow_forward_ios),
                // ),

              body:Container(
                height: 300,
                child: ListView.separated(
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    if (index == 1) {
                      return Container(
                        height: 100,
                        color: Colors.red,
                      );
                    }else if (index == 2) {
                      return Container(
                        height: 100,
                        color: Colors.red,
                      );
                    }else {
                      return Container(
                        height: 100,
                        color: Colors.red,
                      );
                    }
                  },
                  separatorBuilder: (context, index) {
                    return Divider(
                      height: .5,
                      indent: 75,
                      color: Color(0xFFDDDDDD),
                    );
                  },
                ),
              ),
              isExpanded: expandStateList[index].isOpen,
            );
          }).toList(),
        ),
      ),
    );
  }
}

//list中item状态自定义类
class ExpandStateBean{
  var isOpen;   //item是否打开
  var index;    //item中的索引
  ExpandStateBean(this.index,this.isOpen);
}