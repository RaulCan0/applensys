import 'package:flutter/material.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../models/empresa.dart';

class DashboardScreen extends StatelessWidget {
  final Empresa? empresa;
  final int? dimensionId;
  final String evaluacionId;

  const DashboardScreen({
    super.key,
    this.empresa,
    this.dimensionId,
    required this.evaluacionId,
  });

  @override
  Widget build(BuildContext context) {
    final title = dimensionId != null
        ? 'Dashboard Dimensión $dimensionId'
        : 'Dashboard General';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.indigo,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Actualizando dashboard...')),
              );
              // Aquí puedes llamar a tu lógica de recarga si la vuelves a necesitar
            },
          ),
        ],
      ),
      endDrawer: const DrawerLensys(),
      body: const DashboardCarousel(),
    );
  }
}

class DashboardCarousel extends StatefulWidget {
  const DashboardCarousel({super.key});

  @override
  State<DashboardCarousel> createState() => _DashboardCarouselState();
}

class _DashboardCarouselState extends State<DashboardCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> slides = List.generate(7, (index) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.9,
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.indigo[100 * ((index % 8) + 1)],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'Gráfico ${index + 1}',
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
      );
    });

    return Column(
      children: [
        Expanded(
          child: CarouselSlider(
            options: CarouselOptions(
              height: double.infinity,
              viewportFraction: 0.95,
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {
                setState(() => _currentIndex = index);
              },
            ),
            items: slides,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == index
                      ? Colors.indigo
                      // ignore: deprecated_member_use
                      : Colors.indigo.withOpacity(0.4),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
