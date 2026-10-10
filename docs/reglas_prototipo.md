# Reglas del prototipo y fuentes

Este documento delimita qué reglas inspira el prototipo, dónde están documentadas y qué partes son decisiones propias del juego. No declara compatibilidad completa con D&D 2024. Las referencias apuntan a los archivos locales bajo `Rule books/`; las reglas se resumen aquí sin copiar su texto.

## Reglas base del personaje y combate

| Regla | Fuente de referencia | Aplicación actual | Evidencia / límite |
|---|---|---|---|
| Pruebas de característica, salvaciones y ataques: d20, modificadores, ventaja/desventaja y comparación contra CD/CA | Player's Handbook (2024), capítulo 1, “D20 Tests”, “Ability Checks”, “Saving Throws” y “Attack Rolls” | `GameRules` centraliza las tres tiradas y el cálculo del resultado | `scripts/game_rules.gd`; `tests/test_game_rules.gd`. Competencias y bonificadores solo existen en el subconjunto de la campaña. |
| Clase de armadura | Player's Handbook (2024), capítulo 1, “Armor Class”; capítulo 6, armaduras | CA del personaje combina armadura, Destreza y broquel; enemigos declaran CA en datos | `Game._armor_class`, `content/phase_two.json`, `tests/test_character_creation.gd`. Solo hay equipo y fórmulas implementados en el contenido actual. |
| Iniciativa, turnos y ronda de seis segundos | Player's Handbook (2024), capítulo 8, “The Order of Combat” e “Initiative” | Iniciativa al comenzar; la ronda avanza seis segundos al completarse | `Game._start_combat`, `Game._end_player_turn`, `tests/test_phase_three.gd`. El enemigo tira automáticamente; la tirada del jugador es manual. |
| Velocidad y cuadrícula de 5 pies | Player's Handbook (2024), capítulo 8, “Movement and Position” y “Playing on a Grid” | 30 pies se representan con seis casillas; el movimiento se limita por ruta y alcance | `scripts/grid_navigation.gd`, `scripts/game.gd`, `tests/test_phase_three.gd`. Terreno difícil táctico y reglas de esquinas aún no se aplican de forma completa. |
| Acciones de combate | Player's Handbook (2024), capítulo 8, “Actions” y reglas del glosario para Grapple | Ataque, Ayudar, Influenciar, Estudiar, Esquivar, Retirarse, Preparar, Esconderse, Utilizar y Agarrar tienen implementaciones parciales | `scripts/game.gd`, `tests/test_phase_two.gd`, `tests/test_phase_three.gd`. Disponibilidad y efectos están limitados a la campaña demostrativa. |
| Daño de arma, crítico, curación y 0 PV | Player's Handbook (2024), capítulo 1, “Damage Rolls”, “Critical Hits”, “Healing” y “Dropping to 0 Hit Points” | Daño por datos de arma, dado duplicado en crítico, consumible y derrota | `scripts/game_rules.gd`, `scripts/game.gd`, pruebas de flujo y combate. No hay salvaciones de muerte ni reglas generales de resistencia. |
| Cobertura parcial | Player's Handbook (2024), glosario, “Cover” | Regla simplificada local: casillas señaladas dan +2 CA | `GridNavigation.cover_bonus`, `tests/test_phase_three.gd`. Es fija por mapa, no direccional y no modifica salvaciones. |
| Terreno que oculta | Player's Handbook (2024), glosario, “Heavily Obscured Areas” y acción “Hide” | Algunas casillas de vegetación densa bloquean visión y permiten intentar esconderse, pero no bloquean movimiento | `GridNavigation.is_heavily_obscured`, `Game._has_line_of_sight` y `test_phase_three.gd`. Las áreas son fijas y no simulan luz, clima o distintos grados de oscurecimiento. |

## Opciones de personaje y criaturas

- Las cuatro clases y las siete especies disponibles en creación son una selección explícita del MVP dentro de las opciones del *Player's Handbook* (2024), capítulos 2–4. No se ofrecen todas las opciones del libro ni subclases.
- Los cinco trasfondos (Soldier, Noble, Sage, Acolyte y Farmer) se validan como contenido del prototipo; sus rasgos y equipo están simplificados. No se debe inferir que toda su implementación reproduce íntegramente el libro.
- Las estadísticas, comportamiento, botín, encuentros y pistas de las criaturas son datos originales del prototipo en `content/phase_two.json`. El *Monster Manual* (2025) está presente como referencia, pero estas criaturas no se declaran conversiones oficiales.

## Reglas propias de exploración y dados

El mapa hexagonal, 3 millas por hex, velocidades de marcha, paso cauteloso/normal/forzado, monturas, límite diario de ocho horas y pruebas de agotamiento son reglas propias de `Mecanicas.md` y el prototipo. No se presentan como reproducción exacta del ritmo de viaje de D&D.

Las escenas 3D muestran el d20 y los dados de daño/curación d4, d6, d8, d10 y d12 con los valores generados por `GameRules`; un d20 usado para daño reutiliza la escena de veinte caras. En tiradas con varios dados, se animan en secuencia. Son animaciones por tween, no simulación física. Los resultados naturales 1/20 tienen los efectos automáticos de ataque que implementa `GameRules`; los eventos adicionales de d6 descritos por el juego son una regla casera. Las pruebas que no sean ataques reciben narración adicional del prototipo.

## Revisiones aún necesarias

- Confirmar procedencia, permiso de uso y condiciones de distribución de los archivos de referencia antes de publicar o empaquetar el juego.
- Revisar cada fórmula y acción contra la fuente antes de afirmar conformidad con reglas oficiales; las pruebas actuales verifican el comportamiento implementado, no certifican conformidad legal o editorial.
- Resolver las diferencias y pendientes registrados en `docs/verificacion_fases_0_2.md` antes de declarar completa la Fase 2 o una beta de Fase 3.
