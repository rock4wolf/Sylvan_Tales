# Registro inicial de riesgos

Revisión de alcance del prototipo. Los riesgos se mantienen abiertos hasta que la evidencia indicada exista; pasar pruebas automatizadas no los cierra por sí solo.

| Tipo | Riesgo | Evidencia actual | Siguiente verificación |
|---|---|---|---|
| Técnico | `scripts/game.gd` sigue reuniendo interfaz, viaje, campaña y combate en un archivo grande. | 1,700+ líneas; navegación, registro de eventos y presentación del d20 ya están separados. | Extraer un sistema completo por vez y ejecutar pruebas de flujo tras cada extracción. |
| Técnico | El guardado puede romperse con cambios de esquema o datos dañados. | Versionado, normalización y pruebas de migración actuales. | Añadir casos para archivos truncados y formatos futuros antes de beta. |
| Diseño | El combate y las reglas solo cubren una selección de acciones, personajes y efectos. | Límites enumerados en `docs/reglas_prototipo.md` y `docs/verificacion_fases_0_2.md`. | Definir contenido de beta y revisar las reglas adoptadas con pruebas de casos límite. |
| Técnico/UX | Las vistas animadas fijan el resultado mediante tween; no modelan rebotes ni física del dado. | `scripts/d20_roll_view.gd` y `scripts/damage_die_view.gd`. | Decidir si la física real mejora la experiencia y medir legibilidad/consistencia antes de sustituir la animación actual. |
| Producción | La campaña no ha pasado pruebas de uso observadas ni de accesibilidad con jugadores. | Pruebas automatizadas headless; sin sesiones de usuario registradas. | Ejecutar sesiones con perfiles distintos, observar bloqueos y priorizar cambios. |
| Producción | Equilibrio medido solo con duelos simplificados. | `tests/test_combat_balance.gd` simula 500 semillas por emparejamiento 1v1. | Simular y jugar encuentros con distancia, terreno, grupo y tácticas representativas. |
| Arte y UX | El tablero y varios recursos son provisionales; la lectura visual no está validada en ventana real. | Sprites SVG sencillos y tablero dibujado por código. | Producir guía visual, integrar assets de la campaña y revisar en pantalla a escala objetivo. |
| Plataforma | El prototipo está configurado para escritorio; móvil y otros tamaños no se han comprobado. | Arranque headless de Godot 4.6.2. | Probar resoluciones, entrada y legibilidad en las plataformas elegidas. |
| Contenido y derechos | La presencia de archivos de libros de reglas no demuestra permiso de redistribución. | Referencias documentadas en `docs/reglas_prototipo.md`; no hay revisión de licencia registrada. | Verificar procedencia, permiso y condiciones antes de distribuir el repositorio o una compilación. |
