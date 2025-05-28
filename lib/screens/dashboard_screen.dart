import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:applensys/widgets/chat_scren.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:applensys/models/empresa.dart';

class DashboardScreen extends StatelessWidget {
  final String evaluacionId;
  final Empresa empresa;

  const DashboardScreen({
    super.key,
    required this.evaluacionId,
    required this.empresa,
  });

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      drawer: SizedBox(width: 300, child: const ChatWidgetDrawer()),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          empresa.nombre,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF003056),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {}, // Acción deshabilitada por ahora
            tooltip: 'Recargar datos',
          ),
          IconButton(
            icon: const Icon(Icons.note_add_outlined),
            onPressed: () {}, // Acción deshabilitada por ahora
            tooltip: 'Exportar Reporte',
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: const DrawerLensys(),
      body: Center(
        child: CarouselSlider(
          options: CarouselOptions(
            height: 550.0,
            enlargeCenterPage: true,
            autoPlay: true,
            aspectRatio: 20 / 11,
            enableInfiniteScroll: true,
            autoPlayInterval: const Duration(seconds: 5),
          ),
            items: List.filled(5, Colors.grey)
              .asMap()
              .entries
              .map((entry) {
            final index = entry.key;
            final color = entry.value;
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(color: color),
                  child: Center(
                    child: Text(
                      'Slide ${index + 1}',
                      style: const TextStyle(fontSize: 36.0, color: Colors.white),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
