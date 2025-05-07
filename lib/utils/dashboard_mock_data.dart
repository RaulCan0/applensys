// mock_dashboard_data.dart

import 'package:applensys/models/level_averages.dart';

final List<LevelAverages> estructuraBaseMockDimension = [
  LevelAverages(id: 1, nombre: 'IMPULSORES CULTURALES', ejecutivo: 4.5, gerente: 4.2, miembro: 4.0, nivel: ''),
  LevelAverages(id: 2, nombre: 'MEJORA CONTINUA', ejecutivo: 4.3, gerente: 4.1, miembro: 3.9, nivel: ''),
  LevelAverages(id: 3, nombre: 'ALINEAMIENTO EMPRESARIAL', ejecutivo: 4.0, gerente: 4.2, miembro: 4.1, nivel: ''),
];

final List<LevelAverages> estructuraBaseMockPrincipios = [
  LevelAverages(id: 1, nombre: 'Respetar a Cada Individuo', ejecutivo: 4.6, gerente: 4.3, miembro: 4.1, nivel: ''),
  LevelAverages(id: 2, nombre: 'Liderar con Humildad', ejecutivo: 4.2, gerente: 4.0, miembro: 3.8, nivel: ''),
  LevelAverages(id: 3, nombre: 'Buscar la Perfección', ejecutivo: 4.4, gerente: 4.2, miembro: 4.0, nivel: ''),
  LevelAverages(id: 4, nombre: 'Abrazar el pensamiento Cientifico', ejecutivo: 4.0, gerente: 3.9, miembro: 3.7, nivel: ''),
  LevelAverages(id: 5, nombre: 'Enfocarse en el proceso', ejecutivo: 4.1, gerente: 4.0, miembro: 3.9, nivel: ''),
  LevelAverages(id: 6, nombre: 'Asegurar la Calidad en la Fuente', ejecutivo: 4.3, gerente: 4.2, miembro: 4.0, nivel: ''),
  LevelAverages(id: 7, nombre: 'Mejorar el Flujo y Jalón de Valor', ejecutivo: 4.1, gerente: 3.9, miembro: 3.8, nivel: ''),
  LevelAverages(id: 8, nombre: 'Pensar Sistémicamente', ejecutivo: 4.2, gerente: 4.1, miembro: 4.0, nivel: ''),
  LevelAverages(id: 9, nombre: 'Crear constancia de Propósito', ejecutivo: 4.3, gerente: 4.0, miembro: 3.9, nivel: ''),
  LevelAverages(id: 10, nombre: 'Crear valor para el cliente', ejecutivo: 4.5, gerente: 4.3, miembro: 4.2, nivel: ''),
];

final List<LevelAverages> estructuraBaseMockComportamientos = List.generate(28, (i) {
  return LevelAverages(
    id: i + 1,
    nombre: 'Comportamiento ${i + 1}',
    ejecutivo: 3.5 + (i % 3) * 0.2,
    gerente: 3.4 + (i % 3) * 0.2,
    miembro: 3.3 + (i % 3) * 0.2,
    nivel: '',
  );
});

final List<LevelAverages> estructuraBaseMockNiveles = [
  LevelAverages(id: 1, nombre: 'Ejecutivo', ejecutivo: 4.2, gerente: 0.0, miembro: 0.0, nivel: ''),
  LevelAverages(id: 2, nombre: 'Gerente', ejecutivo: 0.0, gerente: 4.1, miembro: 0.0, nivel: ''),
  LevelAverages(id: 3, nombre: 'Miembro de Equipo', ejecutivo: 0.0, gerente: 0.0, miembro: 4.0, nivel: ''),
];

final List<LevelAverages> estructuraBaseMockSistemas = [
  LevelAverages(id: 1, nombre: 'Sistema de Producción', ejecutivo: 4.1, gerente: 4.0, miembro: 3.9, nivel: ''),
  LevelAverages(id: 2, nombre: 'Sistema de Calidad', ejecutivo: 4.3, gerente: 4.1, miembro: 4.0, nivel: ''),
  LevelAverages(id: 3, nombre: 'Sistema de Logística', ejecutivo: 4.2, gerente: 4.0, miembro: 3.8, nivel: ''),
];
