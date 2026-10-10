# Crear y validar contenido

El juego carga el escenario demostrativo desde `phase_two.json`. Conserva `schema_version: 1` y las secciones existentes: especies, trasfondos, clases, arquetipos, facciones, NPC, enemigos, objetos, misiones, regiones, biomas, monturas, puntos de interés, encuentros, botín y diálogos. Cada punto de interés requiere `name`, `category` y `description`; `services` es opcional y admite `mounts` y `long_rest`. `interior` puede declarar `buildings` (objetos `name`/`description`), referencias a NPC, misiones existentes y conversaciones (referencias a un NPC y un diálogo con `text`); la escena `scenes/ui/poi_interior.tscn` los muestra al acceder y aplica los requisitos/efectos del diálogo una sola vez. `interactions` es opcional y contiene acciones con `id` único, `label`, `skill`, `ability`, `dc`, `success` y `failure`; `success_effect` opcional admite cambios de reputación de una facción existente entre -100 y 100. La escena reutilizable `scenes/ui/poi_view.tscn` muestra el acceso, la descripción y las opciones declaradas; cada interacción se resuelve una vez por partida, pide una prueba manual, aplica su efecto de éxito y guarda el resultado en el diario y en la partida.

## Flujo

1. Duplica `phase_two.json` antes de editarlo y conserva IDs estables; las referencias usan esos IDs, no los nombres visibles.
2. Añade datos a la sección correspondiente. Mantén las tablas de encuentros y botín como listas con `weight`; cada referencia debe apuntar a una entidad existente.
   Las criaturas incluyen `size` (`Tiny`, `Small`, `Medium`, `Large`, `Huge` o `Gargantuan`) y atributos `str`/`dex`/`con`, usados por combate, agarres y Topple. `study_dc` y `study_clue` definen la CD de Investigación y la pista que revela la acción Estudiar.
3. Valida el JSON con Godot 4.6:

   ```sh
   godot --headless --editor --import
   godot --headless --path . --script tools/validate_content.gd
   ```

4. Ejecuta las pruebas `tests/test_*.gd` y prueba el flujo en el juego antes de reemplazar el contenido del escenario.

El validador comprueba tipos, límites y referencias cruzadas. Los dados de daño en clases, arquetipos, trucos y enemigos admiten d4, d6, d8, d10, d12 o d20; los valores no admitidos se rechazan para que las escenas tengan una representación compatible. Los dados de daño manuales se animan; las tiradas automáticas de los enemigos siguen resolviéndose sin animación. El contenido actual tiene esquema versión 1; todavía no hay migrador ni carga de paquetes externos. Mantén copias del JSON original: el prototipo no edita ni recupera automáticamente archivos de contenido.
