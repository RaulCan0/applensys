import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:applensys/widgets/chat_scren.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:applensys/models/empresa.dart';

class DashboardScreen extends StatefulWidget {
  final String evaluacionId;
  final Empresa empresa;

  const DashboardScreen({
    super.key,
    required this.evaluacionId,
    required this.empresa,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _autoPlay = true;

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
        title: Center(
          child: Text(
            widget.empresa.nombre,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold, // Opcional: para mayor visibilidad
              fontSize: 20, // Opcional: para mayor tamaño
            ),
            textAlign: TextAlign.center,
          ),
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
      body: Stack(
        children: [
          Center(
            child: CarouselSlider(
              options: CarouselOptions(
                height: 550.0,
                enlargeCenterPage: true,
                autoPlay: _autoPlay,
                aspectRatio: 20 / 9,
                enableInfiniteScroll: true,
                autoPlayInterval: const Duration(seconds: 5),
              ),
              items: [
                {'color': Colors.grey, 'title': 'General'},
                {'color': Colors.blueGrey, 'title': 'Principios'},
                {'color': Colors.teal, 'title': 'Comportamientos'},
                {'color': Colors.indigo, 'title': 'Sistemas Asociados'},
              ].asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final color = data['color'] as Color;
                final title = data['title'] as String;
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.92,
                      height: 480,
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.black87, // Sin opacity
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Center(
                            child: Text(
                              'Slide ${index + 1}',
                              style: const TextStyle(fontSize: 40.0, color: Colors.white),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          Positioned(
            bottom: 32,
            right: 32,
            child: IconButton(
              icon: Icon(_autoPlay ? Icons.pause : Icons.play_arrow, color: Colors.white),
              style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF003056),
              padding: const EdgeInsets.all(16), // Adjust padding as needed
              ),
              onPressed: () {
              setState(() {
                _autoPlay = !_autoPlay;
              });
            },
            ),
          ),
        ],
      ),
    );
  }
}

