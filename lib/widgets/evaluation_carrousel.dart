// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class EvaluationCarousel extends StatefulWidget {
  final String evaluacionId;
  final String empresaNombre;
  final Function(int) onPageChanged;
  final int initialPage;

  const EvaluationCarousel({
    super.key,
    required this.evaluacionId,
    required this.empresaNombre,
    required this.onPageChanged,
    this.initialPage = 0,
  });

  @override
  State<EvaluationCarousel> createState() => _EvaluationCarouselState();
}

class _EvaluationCarouselState extends State<EvaluationCarousel> {
  late CarouselSliderController _carouselController;
  late int _currentIndex;

  // Lista de títulos para cada contenedor del carrusel
  final List<String> _titulos = [
    'Dimensiones',
    'Nivel por Dimensión',
    'Principios',
    'Comportamientos',
    'Niveles de Comportamiento',
    'Sistemas Asociados',
  ];
  
  // Lista de colores para los contenedores
  final List<Color> _colors = [
    Colors.blue.shade200,
    Colors.green.shade200,
    Colors.amber.shade200,
    Colors.grey.shade200,
    Colors.teal.shade200,
    Colors.indigo.shade200,
  
  ];

  // Lista de íconos para cada contenedor
  final List<IconData> _icons = [
    Icons.info_outline,
    Icons.data_usage,
    Icons.visibility,
    Icons.settings,
    Icons.straighten,
    Icons.assessment,
  ];

  // Lista de descripciones para cada contenedor
  final List<String> _descriptions = [
    'Datos de dimensiones y generales de la evaluación',
    'Datos de los niveles por dimensión',
    'Datos generales de los principios',
    'Datos de los comportamientos generales',
    'Niveles por comportamiento',
    'Sistemas Asociados',
  ];

  @override
  void initState() {
    super.initState();
    _carouselController = CarouselSliderController();
    _currentIndex = widget.initialPage;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Carrusel principal
        Expanded(
          child: CarouselSlider.builder(
            carouselController: _carouselController,
            itemCount: 8,
            options: CarouselOptions(
              height: double.infinity,
              initialPage: widget.initialPage,
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
                widget.onPageChanged(index);
              },
            ),
            itemBuilder: (context, index, realIndex) {
              return _buildCarouselItem(index);
            },
          ),
        ),
        
        // Indicadores de navegación (bolitas)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              8, 
              (index) => _buildDotIndicator(index)
            ),
          ),
        ),
        
        // Barra inferior con título y controles
        Container(
          height: 60,
          color: Colors.indigo,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: _currentIndex > 0 
                    ? () => _carouselController.previousPage() 
                    : null,
                disabledColor: Colors.white38,
              ),
              Text(
                _titulos[_currentIndex],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                onPressed: _currentIndex < 7 
                    ? () => _carouselController.nextPage() 
                    : null,
                disabledColor: Colors.white38,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Contenedor individual del carrusel
  Widget _buildCarouselItem(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: _colors[index],
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            spreadRadius: 1.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Encabezado del contenedor
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: _colors[index].darker(10),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _icons[index],
                  size: 28.0,
                  color: Colors.indigo,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    _titulos[index],
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.indigo,
                  radius: 12,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descripción del contenedor
                  Text(
                    _descriptions[index],
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 24.0),
                  
                  // Ejemplo de contenido específico para cada sección
                  _buildSectionSpecificContent(index),
                                    
                  const Spacer(),
                  
                  // Información adicional
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID de Evaluación: ${widget.evaluacionId}',
                          style: const TextStyle(fontSize: 14.0, color: Colors.black87),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Empresa: ${widget.empresaNombre}',
                          style: const TextStyle(fontSize: 14.0, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Contenido específico para cada sección
  Widget _buildSectionSpecificContent(int index) {
    switch (index) {
      case 0: // Información General
        return _buildInfoSection();
      case 1: // Datos Técnicos
        return _buildTechnicalDataSection();
      case 2: // Inspección Visual
        return _buildVisualInspectionSection();
      case 3: // Pruebas Operativas
        return _buildOperationalTestsSection();
      case 4: // Mediciones
        return _buildMeasurementsSection();
      case 5: // Resultados
        return _buildResultsSection();
      case 6: // Recomendaciones
        return _buildRecommendationsSection();
      case 7: // Fotos y Evidencias
        return _buildPhotosSection();
      default:
        return const SizedBox.shrink();
    }
  }

  // Secciones específicas para cada tipo de contenido
  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Fecha de evaluación:', '13/05/2025'),
        _buildInfoRow('Técnico responsable:', 'Juan Pérez'),
        _buildInfoRow('Tipo de evaluación:', 'Completa'),
        _buildInfoRow('Estado:', 'En proceso'),
      ],
    );
  }

  Widget _buildTechnicalDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Modelo:', 'ABC-123'),
        _buildInfoRow('Fabricante:', 'TechSolutions'),
        _buildInfoRow('Año:', '2023'),
        _buildInfoRow('Serie:', 'TS789456'),
      ],
    );
  }

  Widget _buildVisualInspectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusItem('Estado físico', true),
        _buildStatusItem('Conexiones', true),
        _buildStatusItem('Etiquetas de identificación', false),
        _buildStatusItem('Limpieza general', true),
      ],
    );
  }

  Widget _buildOperationalTestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusItem('Encendido/Apagado', true),
        _buildStatusItem('Funciones principales', true),
        _buildStatusItem('Alarmas', false),
        _buildStatusItem('Calibración', true),
      ],
    );
  }

  Widget _buildMeasurementsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMeasurement('Voltaje', '220V', Icons.electrical_services),
            _buildMeasurement('Corriente', '5A', Icons.bolt),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMeasurement('Temperatura', '35°C', Icons.thermostat),
            _buildMeasurement('Presión', '1.2 Bar', Icons.speed),
          ],
        ),
      ],
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Condición general: ACEPTABLE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 12),
        _buildStatusItem('Seguridad', true),
        _buildStatusItem('Funcionalidad', true),
        _buildStatusItem('Documentación', false),
        _buildStatusItem('Mantenimiento', true),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('1. Actualizar etiquetas de identificación'),
        SizedBox(height: 8),
        Text('2. Revisar sistema de alarmas'),
        SizedBox(height: 8),
        Text('3. Programar mantenimiento preventivo en 3 meses'),
        SizedBox(height: 8),
        Text('4. Completar documentación técnica'),
      ],
    );
  }

  Widget _buildPhotosSection() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(
        4,
        (index) => Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.photo, size: 40, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  // Widgets de utilidad para construir secciones
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.error,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildMeasurement(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Construye un indicador de punto para la navegación
  Widget _buildDotIndicator(int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _carouselController.animateToPage(index),
      child: Container(
        width: isActive ? 12.0 : 10.0,
        height: isActive ? 12.0 : 10.0,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.indigo : Colors.grey.shade300,
          border: isActive 
              ? Border.all(color: Colors.indigo.shade300, width: 2) 
              : null,
        ),
      ),
    );
  }
}

// Extensión de utilidad para oscurecer colores
extension ColorExtension on Color {
  Color darker(int percent) {
    assert(1 <= percent && percent <= 100);
    final value = 1 - percent / 100;
    return Color.fromARGB(
      alpha,
      (red * value).round(),
      (green * value).round(),
      (blue * value).round(),
    );
  }
}