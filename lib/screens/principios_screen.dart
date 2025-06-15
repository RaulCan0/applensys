import 'package:applensys/models/asociado.dart';
import 'package:applensys/models/calificacion.dart';
import 'package:applensys/models/principio_json.dart';
import 'package:applensys/screens/tablas_screen.dart' as tablas_screen;
import 'package:applensys/services/domain/json_service.dart';
import 'package:applensys/services/domain/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/empresa.dart';

import 'comportamiento_evaluacion_screen.dart';

class PrincipiosScreen extends StatefulWidget {
  final Empresa empresa;
  final Asociado asociado;
  final String dimensionId;

  const PrincipiosScreen({
    super.key,
    required this.empresa,
    required this.asociado,
    required this.dimensionId,
  });

  @override
  State<PrincipiosScreen> createState() => _PrincipiosScreenState();
}

class _PrincipiosScreenState extends State<PrincipiosScreen> {
  Map<String, List<PrincipioJson>> principiosUnicos = {};
  List<String> comportamientosEvaluados = [];
  Map<String, Calificacion> calificacionesExistentes = {}; 
  bool cargando = true;

  String nombreDimension(String id) {
    switch (id) {
      case '1':
        return 'IMPULSORES CULTURALES';
      case '2':
        return 'MEJORA CONTINUA';
      case '3':
        return 'ALINEAMIENTO EMPRESARIAL';
      default:
        return 'DIMENSIÓN DESCONOCIDA';
    }
  }

  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    cargarDatos(); // Llama a una nueva función que carga todo
  }

  Future<void> cargarDatos() async {
    setState(() => cargando = true);
    try {
      // Cargar principios
      final List<dynamic> datosJson = await JsonService.cargarJson('t${widget.dimensionId}.json');
      if (datosJson.isEmpty) throw Exception('El archivo JSON de principios está vacío.');

      final todosLosPrincipios = datosJson.map((e) => PrincipioJson.fromJson(e)).toList();
      final principiosFiltrados = todosLosPrincipios
          .where((p) => p.cargo.toLowerCase().contains(widget.asociado.cargo.toLowerCase()))
          .toList();

      final agrupados = <String, List<PrincipioJson>>{};
      for (var p in principiosFiltrados) {
        agrupados.putIfAbsent(p.nombre, () => []).add(p);
      }

      // Cargar calificaciones existentes usando el método disponible y filtrando
      final todasLasCalificacionesDelAsociado = await _supabaseService.getCalificacionesPorAsociado(widget.asociado.id);

      final tempComportamientosEvaluados = <String>[];
      final tempCalificacionesExistentes = <String, Calificacion>{};
      final int dimensionIdActual = int.tryParse(widget.dimensionId) ?? 1;

      for (var cal in todasLasCalificacionesDelAsociado) {
        if (cal.idDimension == dimensionIdActual) { // Filtrar por la dimensión actual
          tempComportamientosEvaluados.add(cal.comportamiento);
          tempCalificacionesExistentes[cal.comportamiento] = cal;
        }
      }

      setState(() {
        principiosUnicos = agrupados;
        comportamientosEvaluados = tempComportamientosEvaluados;
        calificacionesExistentes = tempCalificacionesExistentes;
        cargando = false;
      });
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
      if (mounted) {
        setState(() => cargando = false); // Asegúrate de detener la carga en caso de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  void agregarComportamientoEvaluado(String comportamiento, Calificacion calificacion) {
    if (!comportamientosEvaluados.contains(comportamiento)) {
      setState(() {
        comportamientosEvaluados.add(comportamiento);
        calificacionesExistentes[comportamiento] = calificacion; // Guardar la calificación completa
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            ' ${nombreDimension(widget.dimensionId)}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFF003056),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => tablas_screen.TablasDimensionScreen(
                    empresaId: widget.empresa.id,
                    dimension: '',
                    empresa: widget.empresa,
                    evaluacionId: '',
                    asociadoId: '',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : principiosUnicos.isEmpty
              ? const Center(child: Text('No hay principios para este nivel'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                                'EVALUANDO A: ${widget.asociado.nombre}\nNivel Organizacional: ${widget.asociado.cargo.toLowerCase() == 'miembro' ? 'MIEMBRO DE EQUIPO' : widget.asociado.cargo.toUpperCase()}',
                                style: TextStyle(
                                fontSize: 15, 
                                fontFamily: 'Roboto', 
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, // Esto se mantiene dinámico según el tema
                                ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: principiosUnicos.length,
                          itemBuilder: (context, index) {
                            final entry = principiosUnicos.entries.elementAt(index);
                            return StatefulBuilder(
                              builder: (context, setStateTile) {
                                final totalComportamientos = entry.value.length;
                                final evaluados = entry.value.where((p) {
                                  final comportamientoNombre = p.benchmarkComportamiento.split(":").first.trim();
                                  return comportamientosEvaluados.contains(comportamientoNombre);
                                }).length;
                                final progreso = totalComportamientos == 0 ? 0.0 : evaluados / totalComportamientos;

                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Color.lerp(const Color.fromARGB(255, 179, 174, 174), const Color.fromARGB(255, 154, 218, 156), progreso),
                                     border: Border.all(
    color: const Color.fromARGB(255, 0, 0, 0), // color del contorno
    width: 2,),
                                    boxShadow: [
                                      // ignore: deprecated_member_use
                                      BoxShadow(color: const Color.fromARGB(255, 179, 170, 170).withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
                                    ],
                                  ),
                                  child: ExpansionTile(
                                    tilePadding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04, vertical: screenSize.height * 0.02),
                                    childrenPadding: const EdgeInsets.only(bottom: 10),
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center, // Centra el contenido de la columna
                                      children: [
                                        Text(
                                          entry.key,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,  // Siempre negro
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '$evaluados de $totalComportamientos comportamientos evaluados',
                                          style: const TextStyle(fontSize: 14, color: Colors.black87), // Siempre gris oscuro
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                    children: entry.value.map((principio) {
                                      final comportamientoNombre = principio.benchmarkComportamiento.split(":").first.trim();
                                      final calificacionActual = calificacionesExistentes[comportamientoNombre];

                                      return ListTile(
                                        title: Text(
                                          comportamientoNombre,
                                          textAlign: TextAlign.center, // Centrar título
                                          style: TextStyle(
                                            color: comportamientosEvaluados.contains(comportamientoNombre) ? const Color.fromARGB(255, 79, 109, 80) : Colors.black,
                                            fontWeight: comportamientosEvaluados.contains(comportamientoNombre) ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        subtitle: Text(
                                          principio.benchmarkComportamiento.split(":").last.trim(),
                                          style: const TextStyle(color: Colors.black),
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.black,
                                        ),
                                        onTap: () async {
                                         
                                          final String evaluacionIdParaNavegacion = calificacionActual?.id ?? const Uuid().v4();

                                          final resultado = await Navigator.push<String>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ComportamientoEvaluacionScreen(
                                                principio: principio,
                                                cargo: widget.asociado.cargo,
                                                evaluacionId: evaluacionIdParaNavegacion, 
                                                dimensionId: widget.dimensionId,
                                                empresaId: widget.empresa.id,
                                                asociadoId: widget.asociado.id,
                                                dimension: widget.dimensionId, // Asegúrate que esto es lo que esperas
                                                calificacionExistente: calificacionActual, // Pasar la calificación completa
                                              ),
                                            ),
                                          );
                                          // Después de volver, recargar los datos para reflejar cualquier cambio.
                                          if (resultado != null) {
                                            cargarDatos(); // Recargar todos los datos para asegurar consistencia
                                          }
                                        },
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}