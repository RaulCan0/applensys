import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Gráfico de dona (PieChart) con leyenda a la derecha.
/// Recibe:
///  • data: `Map<nombre_dimension, promedio>` (p. ej. { "Impulsores culturales": 4.2, "Mejora continua": 3.8, ... })
///  • title: título que se muestra arriba del gráfico.
class DonutChart extends StatelessWidget {
  final Map<String, double> data;
  final String title;

  const DonutChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    // Asigno un color fijo (por índice) a cada dimensión, rotando sobre colorsPrimaries.
    final List<Color> sectionColors = List.generate(
      entries.length,
      (i) => Colors.primaries[i % Colors.primaries.length],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1) Columna izq: título + dona
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Título del gráfico
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Espacio para el PieChart
              Expanded(
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    sections: List.generate(entries.length, (index) {
                      final value = entries[index].value;
                      return PieChartSectionData(
                        color: sectionColors[index],
                        value: value,
                        title: '',           // No mostramos texto dentro de la sección
                        radius: 60,
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // 2) Columna der: leyenda con color y texto
        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // Cuadro de color
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: sectionColors[i],
                        shape: BoxShape.rectangle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Nombre de la dimensión
                    Expanded(
                      child: Text(
                        entries[i].key,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


// Puedes colocar este widget en tu clase V o donde lo necesites
class DonutChartV extends StatelessWidget {
  final Map<String, double> data;
  final String title;

  const DonutChartV({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final List<Color> sectionColors = List.generate(
      entries.length,
      (i) => Colors.primaries[i % Colors.primaries.length],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna izquierda: título + dona
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    sections: List.generate(entries.length, (index) {
                      final value = entries[index].value;
                      return PieChartSectionData(
                        color: sectionColors[index],
                        value: value,
                        title: '',
                        radius: 60,
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Columna derecha: leyenda
        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: sectionColors[i],
                        shape: BoxShape.rectangle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entries[i].key,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
