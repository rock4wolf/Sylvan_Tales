# Reglas implementadas: fase 1 y alpha 2

Este documento fija el subconjunto usado por la vertical slice. El [Player's Handbook (2024)](Rule%20books/5.5e/Player's%20Handbook%20(2024).md) es material de consulta; el juego utiliza reglas resumidas aquí y contenido narrativo original.

## Tiradas

- Prueba de característica y salvación: `1d20 + modificador`; suma competencia cuando el personaje es competente en esa prueba. El total igual o mayor a la CD tiene éxito. Sin competencia aún se puede intentar la prueba.
- Ventaja y desventaja tiran dos d20 y conservan el mayor o el menor, respectivamente. Si ambas afectan la misma tirada, se anulan. Las circunstancias no se acumulan.
- Los resultados muestran dados, modificador, total y CD. El generador acepta una semilla para reproducir pruebas.
- La Percepción pasiva del personaje es `10 + modificador de Sabiduría (Percepción)`. El vigía tiene Percepción pasiva 13; Sigilo se compara contra ese valor.
- La iniciativa es una prueba de Destreza. Un combatiente sorprendido tiene desventaja en iniciativa.

## Combate

- Cada casilla táctica representa 5 pies. La velocidad del personaje y del enemigo de la slice es 30 pies (6 casillas); levantarse desde Derribado consume la mitad del movimiento.
- El ataque usa el atributo, competencia, arma y dado de daño configurados por la clase. Un 1 natural falla; un 20 natural impacta y es crítico. Un crítico duplica los dados de daño, no el modificador.
- El hacha tiene la maestría Topple. Tras impactar, el jugador puede forzar una salvación de Constitución contra `8 + modificador usado en el ataque + competencia`; se aplica el modificador de Constitución definido para el enemigo. Al fallar, queda Derribado. Un ataque cuerpo a cuerpo contra un objetivo Derribado tiene ventaja.
- La CA usa armadura de cuero (`11 + modificador de Destreza`); equipar el broquel añade 2.
- Un ataque de oportunidad se solicita con tirada manual cuando el personaje abandona el alcance cuerpo a cuerpo del enemigo. Retirarse consume la acción y evita esos ataques durante el turno.
- Estudiar consume la acción y solicita Investigación contra la CD del enemigo; al superar la prueba se muestra la pista configurada en contenido.
- Preparar consume la acción y guarda un ataque con arma; si un enemigo fuera de alcance se acerca a cuerpo a cuerpo en su siguiente turno, se solicita el ataque preparado antes de que resuelva su propio ataque. Si no se activa, expira al terminar ese turno.
- Esconderse está disponible tras cobertura que bloquee toda línea de visión; consume la acción y requiere Sigilo CD 15. Mientras el rival no recupere visión, no puede atacar al personaje. Moverse por una casilla visible o ser descubierto termina el estado.
- Agarrar consume una acción, requiere mano libre y alcance; el enemigo intenta escapar con una acción. El objetivo agarrado puede liberarse si el personaje se aleja.
- El único conjuro disponible por clase es su cantrip configurado: Rayo de fuego para Wizard y Llama sagrada para Cleric. No existe aún un sistema general de conjuros.
- El enemigo termina el encuentro al llegar a 0 PV. El personaje que llega a 0 PV queda fuera de la expedición y puede cargar una partida guardada.

## Contenido de la aventura

- Persuadir al custodio (Persuasión CD 13) o forzar la reja (Atletismo CD 13) abre rutas funcionales al archivo. Los valores y consecuencias son contenido original de esta aventura, no reglas universales.
- Investigación (CD 13 en el escondite, CD 12 en el archivo) resuelve hallazgos definidos por el escenario. No hay generación procedural de botín.
- Un fallo de Sigilo activa un combate sorpresa contra el vigía; el éxito permite cruzar sin combatir.
- El registro inicia la misión al hablar con Mira; recuperarlo habilita su reclutamiento y la cadena de misiones de la calzada y el faro.
- El tónico de campo cura `2d4 + 2` PV. El broquel se puede equipar; los objetos comunes se pueden descartar.

## Sistemas alpha de fase 2

- `content/phase_two.json` contiene tres arquetipos, cuatro enemigos, dos facciones, NPC, tres misiones enlazadas, dos regiones, encuentros ponderados, tablas de botín y condiciones de diálogo.
- El selector inicial aplica atributos, habilidades, arma y competencia del arquetipo elegido. Los enemigos obtienen PV, CA, ataque, alcance, comportamiento y tabla de botín desde sus definiciones.
- El perfil `aggressive` persigue al personaje; `skirmisher` mantiene distancia de ataque y retrocede si queda trabado en cuerpo a cuerpo. Mira puede realizar un ataque de apoyo por ronda.
- Persuasión modifica reputación de facción y relación con NPC. La ruta a la calzada requiere completar el registro y cumplir el mínimo de reputación de las Cartógrafas.
- Las misiones `sealed_ledger`, `causeway_markers` y `restore_beacon` se encadenan. Las regiones se desbloquean, visitan y guardan como estado de campaña.
- Cada región puede resolver su tabla de encuentros una vez. Se persiste la tirada ponderada y su resultado para evitar rerolls al cargar. Los enemigos entregan botín de su tabla configurada.
- Los objetos de misión no se pueden descartar para evitar bloquear objetivos posteriores.
- Los guardados usan versión 2; los guardados de versión 1 se migran al cargarlos, con valores por defecto para reputación, relaciones, misiones y regiones.
- Ejecuta el validador del paquete con `godot --headless --path . --script res://tools/validate_content.gd`. Comprueba claves requeridas y referencias entre misiones, regiones, encuentros, enemigos, botín, NPC y facciones.

La prueba integrada de la alpha está en `tests/test_phase_two.gd`; el validador también tiene casos de datos malformados en `tests/test_content_registry.gd`.

## Límites conocidos

La ficha ofrece siete especies, cinco trasfondos y cuatro clases de nivel 1 sobre tres perfiles de atributos; no incluye Point Buy, tirada/manual de atributos, subclases, equipo inicial seleccionable, rasgos completos, lista general de conjuros, descansos ni tiradas de muerte. Esconderse usa solo los obstáculos fijos que bloquean toda línea de visión; faltan cobertura parcial y terreno de ocultación. Los aliados solo reciben una orden de ataque y no tienen IA de movimiento propia. Los encuentros son una vez por región y las tablas no sustituyen el diseño narrativo; el faro cierra una campaña breve, no un sistema genérico de edición de misiones.

## Controles

- Clic o `WASD`/flechas: moverse por la cuadrícula.
- Clic en una figura u objeto: acercarse; al estar adyacente, aparecen sus interacciones.
- En combate: moverse, atacar, activar Topple, Estudiar, Preparar, agarrar, Retirarse, esquivar, ayudar/ordenar el ataque de Mira, lanzar el cantrip de la clase, usar un tónico o terminar el turno.
- Las pestañas laterales muestran escena, ficha, bolsa y diario de misiones/regiones. `Guardar` y `Continuar partida` persisten el estado local.
