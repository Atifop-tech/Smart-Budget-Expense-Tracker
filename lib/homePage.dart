import 'package:flutter/material.dart';
import 'package:saad_project_2/dashboard.dart';
import 'package:saad_project_2/history.dart';
import 'package:google_fonts/google_fonts.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(
      appBar: AppBar(
        
            title: Text(
              "HELLO CUSTOMER !!",
              style: GoogleFonts.robotoMono(fontSize: 20),
            ),
            centerTitle: true,
            backgroundColor: Colors.blue,
            actions: [
              
            ],
          
        bottom: TabBar(tabs: [
          Tab(icon: Icon(Icons.history_rounded, color: Colors.black,)),
          Tab(icon: Icon(Icons.dashboard_rounded, color: Colors.black,),)
        ]),
      ),

      body: TabBarView(children: [
        History(),
        DashboardPage()
      ]),
    ));
  }
}
