import 'package:flutter/material.dart';
import '../theme/colors.dart';

class SearchCard extends StatelessWidget{
    const SearchCard({super.key});

    @override
    Widget build(BuildContext context){
        return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius:BorderRadius.circular(16),
            ),

            child:Padding(
                padding:const EdgeInsets.all(16.0),

                child:Column(
                    crossAxisAlignment:CrossAxisAlignment.start,
                    children:[

                        const Text(
                            "Find your perfect ride",
                            style:TextStyle(
                                fontSize:18,
                                fontWeight:FontWeight.bold,
                                color:AppColors.textPrimary,
                            ),
                        ),

                        const SizedBox(height:5),

                        const Text(
                            "Enter your rout details",
                            style:TextStyle(
                                fontSize:14,
                                color:AppColors.textSecondary,
                            ),
                        ),

                        const SizedBox(height:15),

                        TextField(
                            decoration:InputDecoration(
                                hintText:"From",

                                prefixIcon:const Icon(
                                    Icons.circle,
                                    size:12,
                                    color:Colors.green,
                                ),

                                filled: true,
                                fillColor:AppColors.surface,

                                border:OutlineInputBorder(
                                    borderRadius:BorderRadius.circular(10),
                                    borderSide:BorderSide.none,
                                ),
                            ),
                        ),

                        const SizedBox(height:10),

                        TextField(
                            decoration:InputDecoration(
                                hintText:"To",

                                prefixIcon:const Icon(
                                    Icons.circle,
                                    size:12,
                                    color:Colors.red,   
                                ),
                                filled:true,
                                fillColor:AppColors.surface,

                                border:OutlineInputBorder(
                                    borderRadius:BorderRadius.circular(10),
                                    borderSide:BorderSide.none,
                                ),
                            ),
                        ),

                        const SizedBox(height:20),

                        SizedBox(
                            width: double.infinity,

                            child:ElevatedButton(
                                onPressed:(){

                                },
                                child:const Text("Search Rides"),
                            ),
                        )
                    ],
                ),

            ),
        );
    }
}