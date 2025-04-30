import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class UiHelper{
  static CustomTextField(TextEditingController controller,String text,IconData icondata,bool tohide){
  return TextField(
    controller:controller,
    obscureText: tohide,
    decoration: InputDecoration(
      hintText: text,
      suffixIcon: Icon(icondata),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25)
      )
    ),
  );
  }


  static CustomButton(VoidCallback voidcallback,String text){
    return SizedBox(height: 50,width: 200,child: ElevatedButton(onPressed: (){
      voidcallback();
    }, child: Text(text,style: TextStyle(color: Colors.black,fontSize: 20),),
      style: ElevatedButton.styleFrom(shape:  RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25)
      )),

    )
    );
  }


  static CustomAlertBox(BuildContext context,String text){
    return showDialog(context: context, builder: (BuildContext context){

      return AlertDialog(
        title: Text(text),
        actions: [
          TextButton(onPressed: (){
            Navigator.pop(context);

          }, child: Text("Okay!!"))
        ],
      );
    });
  }
}
