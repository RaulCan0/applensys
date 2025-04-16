import 'package:applensys/screens/asociado_screen.dart.dart';
import 'package:flutter/material.dart';
import '../models/empresa.dart';

class DimensionesScreen extends StatelessWidget {
  final Empresa empresa;

  const DimensionesScreen({super.key, required this.empresa});

  final List<Map<String, dynamic>> dimensiones = const [
    {
      'id': '1',
      'nombre': 'IMPULSORES CULTURALES',
      'icono': Icons.group,
      'color': Colors.blue,
    },
    {
      'id': '2',
      'nombre': 'MEJORA CONTINUA',
      'icono': Icons.update,
      'color': Colors.green,
    },
    {
      'id': '3',
      'nombre': 'ALINEAMIENTO EMPRESARIAL',
      'icono': Icons.business,
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dimensiones - ${empresa.nombre}'),
        backgroundColor: Colors.indigo,
      ),
      body: ListView.builder(
        itemCount: dimensiones.length,
        itemBuilder: (context, index) {
          final dimension = dimensiones[index];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: ListTile(
                  leading: Icon(
                    dimension['icono'],
                    color: dimension['color'],
                    size: 50,
                  ),
                  title: Text(
                    dimension['nombre'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AsociadoScreen(
                              empresa: empresa,
                              dimensionId: dimension['id'],
                            ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
