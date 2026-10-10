# D&D Game — Documento de desarrollo

**Versión:** 0.1  
**Estado:** Borrador de planificación derivado del GDD inicial  
**Motor:** Godot (versión mayor por confirmar al iniciar el proyecto)  
**Género:** RPG táctico por turnos con exploración, narrativa y componentes sandbox  
**Dirección de arte:** pixel art inspirado en juegos de 8 y 16 bits  
**Documento base:** `gdd.md`

> **Cómo leer este documento**
>
> - **Definido en el GDD:** requisito o intención expresamente descrita en el documento original.
> - **Propuesta de desarrollo:** decisión recomendada para convertir esa intención en un proyecto construible. Debe validarse antes de convertirse en requisito definitivo.
> - **Pendiente de decisión:** aspecto que el GDD no resuelve y que no debe darse por confirmado.

---

## 1. Resumen del proyecto

El proyecto busca crear un RPG por turnos inspirado en Dungeons & Dragons y en su sistema de reglas de 2024. La experiencia combinará una campaña narrativa con libertad sandbox, exploración a distintas escalas, decisiones con consecuencias, combate táctico, tiradas de dados, gestión de inventario, misiones y reclutamiento de personajes.

La visión a largo plazo va más allá de un RPG cerrado: el juego aspira a convertirse en una plataforma donde se puedan jugar distintos mundos y crear o instalar contenido de la comunidad. Ese contenido podría abarcar mundos, lore, facciones, regiones, ciudades, edificios, especies, clases, subclases y otros componentes. También se contempla viajar entre regiones, mundos y dimensiones, incluso mediante portales o viajes espaciales relacionados con Spelljammer.

El arte tendrá una presentación pixel art de estética retro. El desarrollo se realizará en Godot.

### 1.1 Riesgo principal

El alcance completo equivale a varios productos conectados: un RPG táctico, un sistema de campañas, un simulador de mundo, un editor de contenido y una plataforma de mods. Intentar desarrollar todo simultáneamente elevaría mucho el riesgo de que el proyecto quede incompleto.

**Estrategia recomendada:** construir primero un juego pequeño pero jugable, usando una arquitectura preparada para crecer. El primer objetivo no será crear un universo gigantesco ni un editor universal, sino demostrar que un jugador puede crear un personaje, explorar un lugar, resolver un problema de varias maneras, combatir, obtener botín, completar una misión y guardar la partida.

## 2. Visión, pilares y límites

### 2.1 Visión del producto

Ofrecer una experiencia de RPG de fantasía donde las reglas y tiradas den estructura a las acciones, pero el jugador mantenga libertad para decidir cómo explorar, conversar, infiltrarse, negociar o combatir. Con el tiempo, el mismo núcleo deberá permitir distintas campañas y contenido creado por la comunidad.

### 2.2 Pilares de diseño

1. **Reglas visibles y consistentes.** Las acciones que requieren una tirada usan un servicio común de reglas y dados, en vez de implementar resultados aislados en cada escena.
2. **Más de una solución válida.** Los obstáculos importantes deben permitir, cuando tenga sentido, enfoques como diálogo, sigilo, magia o fuerza directa.
3. **Mundo reactivo.** Los NPC, facciones, misiones, enemigos y objetos deben responder al estado del mundo y a decisiones previas.
4. **Exploración a distintas escalas.** La estructura debe poder representar mapas amplios, regiones, zonas hexagonales, dungeons, poblados, ciudades y edificios.
5. **Contenido separado del código.** Mundos, personajes, objetos y misiones deben definirse mediante datos siempre que sea razonable, para facilitar expansiones y mods.
6. **Lectura rápida del combate.** Las distancias, coberturas, amenazas, estados y resultados de las tiradas deben entenderse con claridad, incluso con pixel art.
7. **Producción incremental.** Cada hito debe dejar una versión ejecutable y verificable; no acumular meses de sistemas sin una experiencia jugable.

### 2.3 Inspiraciones declaradas en el GDD

- Baldur's Gate 3
- The Temple of Elemental Evil
- Pokémon
- Spore
- No Man's Sky
- Final Fantasy
- Warframe

**Uso recomendado de las referencias:** extraer principios concretos (claridad táctica, exploración, variedad de criaturas, progresión, personalización o contenido modular) en vez de intentar reproducir la escala o todos los sistemas de cada título. La referencia a una obra no debe interpretarse como requisito de copiar sus funciones.

### 2.4 Fuera del alcance inicial

Estas funciones pertenecen a la visión de largo plazo, no al primer entregable:

- Explorar un mundo completo de escala planetaria o un universo entero.
- Viajes interplanetarios o entre dimensiones totalmente desarrollados.
- Compatibilidad con todos los escenarios oficiales y de la comunidad desde el lanzamiento.
- Editor visual universal de mundos, campañas, clases, especies y reglas.
- Taller integrado, distribución en línea, calificaciones o actualización automática de mods.
- Multijugador, juego cooperativo, servidores dedicados o sincronización de partidas.
- Generación procedural de mundos con suficiente calidad para sustituir el diseño manual.

No se descarta lo anterior; se aplaza hasta que exista un núcleo jugable estable y se haya comprobado que los sistemas base lo soportan.

## 3. Supuestos que deben validarse

El GDD no define todas las decisiones necesarias para empezar. Para no bloquear la producción, se proponen estos supuestos provisionales:

| Tema | Supuesto para el primer prototipo | Por qué | Estado |
|---|---|---|---|
| Plataforma | PC de escritorio; móvil como posibilidad futura | Simplifica entrada, interfaz y pruebas iniciales | Parcial: arranque de escritorio verificado; móvil sin probar |
| Modalidad | Un jugador; multijugador local como posibilidad futura | Reduce mucho la complejidad de arquitectura | Parcial: la campaña actual es individual |
| Cámara | Varía según el entorno | Compatible con pixel art y mapas tácticos | Parcial: mapa regional y tablero isométrico distintos; navegación de cámara no probada |
| Combate | Turnos sobre una cuadrícula | Facilita movimiento, alcance, línea de visión y lectura táctica | Parcial: prototipo probado; cobertura y acciones tácticas pendientes |
| Exploración inicial | Mapa regional pequeño con zonas definidas y, si aporta valor, una zona hexagonal | Demuestra la jerarquía del mundo | validado |
| Contenido inicial | Un escenario original de fantasía | Permite probar el sistema sin depender de contenido de terceros para expandirlo en futuras iteraciones | validado |
| Idioma de producción | Español en esta documentación; arquitectura preparada para localización | Evita incrustar textos en el código | Por validar |
| Persistencia | Partidas guardadas locales | Necesario para una experiencia de campaña | Validado |
| Modelo de distribución | Sin definir | No afecta al prototipo, pero sí a derechos y soporte de mods | Pendiente |

Antes de ampliar el proyecto, conviene tomar explícitamente las decisiones de plataforma, modalidad, perspectiva, modelo comercial, accesibilidad y soporte de contenido externo.

## 4. Alcance por etapas

### 4.1 Etapa 0 — Definición y prueba de riesgo

**Objetivo:** transformar las ideas principales en especificaciones pequeñas, verificables y sin contradicciones.

Entregables:

- Este documento de desarrollo revisado. 
- Una lista del subconjunto de reglas de 2024 usado en el prototipo y sus fuentes de referencia: `docs/reglas_prototipo.md` (archivos Markdown bajo `Rule books/`). La autorización de uso/distribución todavía requiere revisión antes de publicar.
- Un glosario del juego (atributos, tiradas, estados, acciones, tipos de mapa, misiones y entidades).
- Un prototipo de movimiento y selección sobre una cuadrícula.
- Una prueba de importación de datos de objetos, criaturas y misiones sin modificar código.
- Un inventario inicial de riesgos técnicos, de producción y de propiedad intelectual: `docs/registro_riesgos.md`.

**Criterio de salida:** se puede iniciar una partida de prueba y resolver una acción con una tirada usando datos, no una lógica escrita específicamente para esa única escena.

### 4.2 Etapa 1 — MVP jugable / vertical slice

El MVP debe ser un fragmento pequeño que atraviese todo el bucle principal de juego. Alcance recomendado:

- Menú inicial y nueva partida.
- Un personaje jugable con atributos, habilidades, equipo y ficha visible.
- Un mapa pequeño de exploración y al menos un espacio táctico.
- Movimiento, interacción y comprobaciones de habilidad mediante dados.
- Un NPC neutral y un NPC hostil.
- Mostrar opcion para persuadir o iniciar combate con NPC hostil
- Un combate por turnos con iniciativa, movimiento, acción, ataque, daño, estados y finalización.
- Un encuentro o emboscada donde influyan sigilo, percepción y percepción pasiva.
- Un contenedor u objeto de botín donde Investigation/Investigación intervenga en el descubrimiento o la calidad del hallazgo.
- Inventario con recoger, usar, equipar y descartar objetos.
- Una misión con etapas, objetivos y registro de cambios.
- Una opción de reclutar un aliado/NPC en condiciones concretas.
- Una salida de la zona que permita entrar a un dungeon o lugar interior pequeño.
- Guardado y carga de partida.
- Dirección visual coherente de pixel art, aunque los recursos sean provisionales.

No hace falta incluir en el MVP todas las clases, especies, monstruos, escenarios, reglas, portales o sistemas avanzados. Sí es importante que los sistemas implementados sean reutilizables.

### 4.3 Etapa 2 — Alpha de sistemas

Ampliar el contenido y probar que el núcleo puede sostener una campaña pequeña:

- Más opciones de personaje y equipo.
- Varios arquetipos de enemigos y comportamientos de IA.
- Conversaciones con condiciones y consecuencias.
- Reacciones de facciones y relaciones con NPC.
- Varias misiones conectadas y una misión principal breve.
- Exploración regional con zonas bloqueadas/desbloqueadas.
- Encuentros aleatorios configurables.
- Botín con tablas y reglas de generación controladas.
- Reclutamiento, grupo y manejo básico de aliados.
- Guardado robusto, compatibilidad de versiones y recuperación ante errores.
- Herramientas internas para validar contenido.
- Solicitar tiradas de dados al usuario en lugar de realizarlas en automatico, para dar una sensación de mayor participacion, mostrar un dado realista rodando y cayendo en el resultado
- Implementar y validar que se cumplan las mecanicas de Mecanicas.md correspondientes a la fase

### 4.4 Etapa 3 — Beta de contenido y estabilidad

- Contenido completo para una pequeña campaña demostrativa.
- Balance de combate y economía.
- Corrección de errores, rendimiento y accesibilidad básica.
- Telemetría local de depuración o registros de eventos, sin recopilar datos personales sin una decisión de producto explícita.
- Pruebas con usuarios y cambios priorizados por evidencia.
- Documentación para crear contenido.
- Implementar y validar que se cumplan las mecanicas de Mecanicas.md correspondientes a la fase
- Cada elemento del juego debe tener su Scene y su nodo propiamente organizadas en la estuctura de datos para mayor personalizacion y escalabilidad del desarrollo
- implementacion de assets
- Modular el codigo en partes mas pequeñas para mejor organizacion, escalabilidad y retutilización


### 4.5 Etapa 4 — Herramientas de creación y mods

Solo después de estabilizar el modelo de datos:

- Especificación y versión del formato de contenido.
- Validador de paquetes y referencias.
- Cargador de contenidos externos.
- Plantillas y ejemplos documentados.
- Herramientas para editar misiones, mapas y entidades.
- Gestión de conflictos entre mods.
- Identificadores únicos y dependencias de paquetes.
- Informes de errores que identifiquen el paquete responsable.
- Implementar y validar que se cumplan las mecanicas de Mecanicas.md correspondientes a la fase

El editor visual se debe construir alrededor de las estructuras que el juego realmente utiliza. Crear primero un editor muy general sin un esquema de datos estable probablemente causará retrabajo.

### 4.6 Etapa 5 — Expansión de mundos

Después de validar el producto base, se podrá estudiar la incorporación de otros escenarios, regiones, mundos, dimensiones y viajes espaciales. Cada expansión debe especificar qué sistemas reutiliza, qué datos aporta y qué mecánicas nuevas introduce. El viaje entre mundos no debe forzar a simular cada lugar del universo a la vez.

## 5. Experiencia y bucles de juego

### 5.1 Bucle principal

1. inicio de un personaje (locación definida o locacion procedural)
2. Explorar el entorno y reunir información.
1. Hablar con NPC o seguir explorando
3. Identificar posibilidades de interacción.
4. Elegir un enfoque: diálogo, sigilo, magia, fuerza u otro sistema que el escenario permita.
5. Resolver acciones mediante reglas, tiradas, decisiones o combate.
6. Actualizar el estado del mundo y las misiones.
7. Obtener recompensas, recursos, equipo, información o aliados.
8. Prepararse y continuar hacia la siguiente zona o etapa.
9. Guardar el progreso.

### 5.2 Bucle de combate

1. Detectar el encuentro y determinar si existe sorpresa/emboscada según las reglas definidas.
2. Crear el orden de turnos.
3. Mostrar el estado táctico: unidades, posiciones, vida, condiciones y objetivos conocidos.
4. En cada turno, validar movimiento, alcance, línea de visión, acciones, recursos y objetivos.
5. Resolver las acciones usando un único servicio de reglas.
6. Aplicar daño, curación, condiciones, derrotas y efectos del entorno.
7. Comprobar si el combate continúa o si una condición de victoria/retirada se ha cumplido.
8. Resolver consecuencias, experiencia/recompensas si el diseño las utiliza, botín y cambios de misión.

### 5.3 Bucle de creación de contenido

1. Crear un paquete o escenario a partir de una plantilla.
2. Definir entidades, mapas, encuentros, misiones y conexiones mediante datos.
3. Ejecutar el validador.
4. Probar el contenido en el juego.
5. Corregir referencias, reglas o recursos inválidos.
6. Empaquetar y compartir el contenido.

Este bucle es posterior al MVP, pero debe influir en la separación entre datos y lógica desde el principio.

## 6. Sistemas del juego y requisitos funcionales

### 6.1 Creación de mundo y lore

**Definido en el GDD:** creación de mundo y lore, y soporte para diferentes settings.

**Diseño propuesto:** representar el mundo mediante datos conectados. Un mundo contiene regiones; las regiones contienen localizaciones; las localizaciones pueden enlazarse con mapas, interiores, NPC, encuentros, facciones y misiones. La jerarquía exacta debe poder extenderse sin cambiar el sistema de navegación.

Requisitos:

- Cada entidad tendrá un identificador estable único dentro de su paquete de contenido.
- El nombre visible y los textos narrativos estarán separados del identificador interno.
- Las conexiones entre lugares serán explícitas y validadas.
- El estado de campaña (por ejemplo, lugar visitado, puerta abierta o jefe derrotado) se guardará aparte de la definición estática del lugar.
- Los textos no deben estar incrustados en scripts cuando puedan provenir de datos localizables.
- Los lugares pueden estar disponibles, bloqueados, descubiertos u ocultos según reglas de campaña.

**No implementar todavía:** simulación continua de todo el mundo, economías detalladas para cada asentamiento o generación ilimitada de lore.

### 6.2 Jerarquía de exploración

El GDD menciona espacio, continente, país, región, zona hexagonal, dungeon, pueblo/ciudad y edificio.

Propuesta de navegación:

- **Nivel estratégico:** mundo, dimensión o sector espacial.
- **Nivel regional:** continente, país, región o zona de viaje.
- **Nivel de ruta:** conexión entre localizaciones o mapa de hexágonos.
- **Nivel local:** exterior de asentamiento, dungeon o área táctica.
- **Nivel interior:** edificio, habitación o área interior.

No todos los niveles tienen que ser mapas jugables independientes. Algunos pueden ser pantallas de navegación o nodos en un mapa. Esta decisión debe tomarse con un prototipo de interfaz y no por anticipado para todo el universo.

Requisitos:

- Viajar entre nodos debe revisar condiciones y actualizar la campaña.
- El sistema debe conocer el coste o duración de viaje si esa mecánica se adopta.
- Los encuentros aleatorios deben depender de tablas configurables por zona, contexto y condiciones.
- Un lugar puede contener entradas, salidas, puntos de interés y zonas de interacción.
- El jugador debe distinguir entre lugares descubiertos y lugares todavía ocultos.

### 6.3 Creación de personaje

**Definido en el GDD:** creación de personaje.

MVP recomendado:

- Nombre y apariencia básica.
- Especie/linaje, clase o arquetipo limitado a las opciones incluidas en el prototipo.
- Atributos, modificadores, competencias y habilidades necesarias para la vertical slice.
- Puntos de vida y valores derivados relevantes.
- Equipo inicial e inventario.
- Rasgos y opciones que tengan efecto comprobable en el juego.
- Resumen legible de las reglas aplicadas a la ficha.

Requisitos técnicos:

- La ficha visible no será la fuente de verdad del estado: mostrará un modelo de personaje.
- Los valores derivados se calcularán desde atributos, nivel, equipo, condiciones y reglas aplicables.
- Las elecciones deben validarse al crear el personaje y al cargar una partida.
- Las opciones no disponibles o incompatibles no deben ofrecerse como seleccionables.
- Los datos de creación estarán separados del contenido concreto de una campaña.

**Pendiente:** métodos de generación de atributos, cantidad de clases/especies disponibles, progresión, multiclase, alineamiento, trasfondo, muerte y resurrección, y si se permitirá cambiar decisiones tras crear el personaje.

### 6.4 Motor de reglas y tiradas

**Definido en el GDD:** el juego usa como inspiración las reglas de D&D 5.5 de 2024 y realiza tiradas para las acciones que lo requieran.

**Propuesta crítica:** no distribuir fórmulas de reglas entre scripts de combate, diálogos, inventario y exploración. Crear un módulo de reglas central que pueda ser llamado desde cualquiera de esos sistemas.

Responsabilidades recomendadas:

- Tiradas de dado y expresiones de dados permitidas.
- Pruebas de característica/habilidad.
- Tiradas enfrentadas, salvaciones, ataques y daño.
- Ventaja/desventaja u otros modificadores que correspondan a la especificación adoptada.
- Cálculos de dificultad, competencia, alcance y recursos.
- Condiciones, duración y orden de aplicación de efectos.
- Registro explicable de cada tirada: fórmula aplicada, modificadores y resultado.
- Validación de acciones ilegales antes de gastar recursos.

Reglas de implementación:

1. La interfaz solicita una acción al sistema, pero no calcula el resultado por sí misma.
2. Los sistemas de combate y exploración llaman al mismo servicio de reglas.
3. Cada resolución devuelve un resultado estructurado que puede mostrarse en el registro de combate o en el diario.
4. Las pruebas unitarias deben cubrir tanto resultados típicos como límites.
5. Las tiradas deben ser reproducibles durante depuración usando una semilla configurable; la semilla y el estado necesario se guardarán si el diseño requiere reproducción exacta.
6. El motor debe mantener separadas la regla de juego, la presentación visual del dado y el mensaje narrativo que acompaña el resultado.

**Pendiente importante:** elaborar una especificación de las reglas de 2024 que realmente se implementarán. “Usar D&D 5.5” no determina por sí solo el alcance; hace falta decidir qué clases, competencias, acciones, condiciones, hechizos, objetos, descansos y reglas opcionales entrarán en la primera versión.

### 6.5 Interacción y resolución de problemas

**Definido en el GDD:** se busca que el mundo pueda ser hostil, neutral o aliado, y que los obstáculos admitan diferentes acercamientos, incluidos sigilo, ataque directo, encantamientos y diálogo.

Requisitos:

- Las opciones de interacción deben depender de ubicación, estado, atributos, inventario, misiones y relaciones pertinentes.
- Un diálogo puede ofrecer opciones condicionadas por una tirada o por una decisión previa.
- Una opción fallida no siempre debe significar bloqueo total; cuando sea apropiado, puede generar coste, alerta, pérdida de confianza o una nueva ruta.
- El sistema no debe mostrar opciones que sean imposibles, salvo que el juego quiera mostrar explícitamente por qué están bloqueadas.
- Los cambios importantes deben actualizar variables de campaña y el diario.
- Los NPC deben disponer, al menos, de estado de disposición y de reglas para pasar a hostil, neutral o aliado.

Para cada obstáculo relevante de la vertical slice, diseñar al menos dos soluciones reales y probar que ambas llevan a un resultado válido. No es necesario que todas las puertas o situaciones tengan cuatro soluciones artificiales.

### 6.6 Combate por turnos

**Definido en el GDD:** combate por turnos y sistema de enemigos.

**Supuesto de prototipo:** combate táctico sobre cuadrícula 2D. Si se elige un modelo sin cuadrícula, habrá que revisar movimiento, distancia, cobertura y pathfinding.

Requisitos funcionales mínimos:

- Entrar y salir de un encuentro.
- Registrar unidades combatientes y su estado.
- Calcular y ordenar iniciativa según la regla adoptada.
- Seleccionar una unidad y mostrar sus opciones disponibles.
- Calcular desplazamiento válido y rutas.
- Validar alcance, línea de visión y objetivos de los ataques.
- Resolver ataques, daño, curación, efectos y gasto de recursos.
- Gestionar muerte, inconsciencia, retirada o rendición según el alcance de reglas definido.
- Resolver condiciones de victoria y derrota.
- Mostrar un registro de combate comprensible.
- Aplicar cambios del combate al mundo, inventario y misiones.

Componentes recomendados:

- **CombatEncounter:** estado completo de un encuentro.
- **CombatantState:** datos dinámicos de cada participante.
- **TurnController:** fase y orden de turnos.
- **ActionValidator:** determina si una acción está permitida.
- **MovementSolver:** movimiento y rutas.
- **TargetingService:** alcance, línea de visión y selección de objetivos.
- **RulesService:** resolución de reglas.
- **CombatLog:** eventos explicables del combate.

No conectar directamente los botones de la interfaz con efectos sobre enemigos. La UI envía una intención (por ejemplo, atacar a un objetivo); el combate valida y resuelve la acción.

### 6.7 Enemigos e inteligencia artificial

Requisitos mínimos:

- Datos de criatura separados del comportamiento de IA.
- Atributos, vida, defensas, velocidad, ataques, habilidades, sentidos y recompensas definibles por datos.
- Estados de comportamiento comprensibles: inactivo, patrullando, investigando, alertado, persiguiendo, combatiendo, huyendo o derrotado, según lo que necesite cada tipo.
- Elección de objetivos y acciones legales.
- Uso de rutas accesibles y prevención de movimientos imposibles.
- Respuesta a ruido, detección, distancia y estado de alerta si el encuentro lo utiliza.
- Límite de cálculo por turno para evitar que la IA bloquee la experiencia.

Para el MVP, bastan dos o tres perfiles de comportamiento sencillos (por ejemplo, atacante cuerpo a cuerpo, atacante a distancia y guardia que investiga alertas). No se necesita una IA universal capaz de resolver todas las situaciones.

### 6.8 Sigilo, percepción y emboscadas

**Definido en el GDD:** las emboscadas deben utilizar Perception, Passive Perception y Stealth.

Especificación propuesta:

- Determinar qué unidades pueden detectar a cuáles y bajo qué condiciones.
- Considerar línea de visión, distancia, obstáculos y modificadores incluidos en la especificación de reglas.
- Separar la percepción activa de los valores pasivos si la regla adoptada los distingue.
- Registrar resultados y efectos de detección, sin mostrar al jugador información que su personaje no debería conocer cuando exista información oculta.
- Definir una transición clara entre exploración, alerta y combate.
- Evitar que enemigos sin línea de visión obtengan información precisa injustificada.
- Hacer que el sigilo tenga una utilidad verificable: permitir evitar enemigos, colocarse mejor, robar o acceder a rutas, cuando el contenido lo permita.

Pruebas necesarias: pasar cerca sin ser detectado, generar ruido, perder línea de visión, tener valores pasivos distintos, alertar a un grupo y cargar una partida durante un estado de alerta.

### 6.9 Inventario, equipo y objetos

**Definido en el GDD:** inventario robusto.

Primera versión:

- Objetos apilables y no apilables.
- Cantidad, peso o espacio ocupado si se adopta esa limitación.
- Categorías, rareza opcional, valor, descripción y etiquetas.
- Recoger, soltar, usar, consumir, equipar, desequipar y transferir entre personajes si existe grupo.
- Ranuras de equipo definidas por reglas.
- Validación de requisitos y restricciones.
- Actualización de atributos derivados al equipar o quitar equipo.
- Botín de enemigos y contenedores.
- Persistencia correcta de cantidad, cargas, durabilidad o estado cuando correspondan.

Diseño de datos:

- `ItemDefinition`: definición estática del objeto.
- `ItemInstance`: estado de una instancia concreta, si difiere de la definición (por ejemplo, cargas o estado único).
- `InventoryState`: colección y operaciones válidas de inventario.
- `EquipmentState`: ranuras y objetos equipados.

No codificar a mano un comportamiento distinto dentro de cada objeto si puede describirse con efectos reutilizables. Aun así, no crear un sistema de efectos excesivamente abstracto antes de que haya ejemplos reales que lo necesiten.

### 6.10 Botín y loot generado mediante Investigación

**Definido en el GDD:** sistema de looteo generado de forma inteligente, con Investigation/Investigación como parte del sistema.

La palabra “inteligente” debe convertirse en reglas comprobables. Propuesta:

- Cada contenedor, enemigo o área tiene una tabla o perfil de botín definido por el contenido.
- La investigación puede revelar compartimentos, pistas, objetos ocultos, cantidades adicionales o mejor información, según lo permitido por el tipo de lugar.
- El nivel de investigación no debe producir automáticamente equipo poderoso sin límites.
- Los resultados deben respetar economía, contexto, nivel de amenaza, tipo de ubicación y estado de misión.
- La generación debe ser reproducible con una semilla durante pruebas y evitar rerolls involuntarios al cargar la partida.
- No se debe regenerar botín ya reclamado cada vez que se abandona y reingresa a una zona.
- Los resultados deben guardarse en el estado de la campaña.

Para el MVP, utilizar tablas pequeñas y diseñadas manualmente; más adelante se pueden añadir reglas combinatorias. No utilizar generación procedural para reemplazar el diseño de recompensas principales de historia.

### 6.11 Misiones y seguimiento de quests

**Definido en el GDD:** creación y seguimiento de misiones; posibilidad de jugar una línea principal, misiones prehechas o crear una.

Arquitectura propuesta:

- Una misión contiene identificador, título, descripción, condiciones de inicio, objetivos, requisitos, recompensas, resultados posibles y referencias a otras misiones.
- Los objetivos deben ser tipos de datos reutilizables: hablar con una entidad, encontrar un objeto, visitar un sitio, derrotar una amenaza, entregar algo, descubrir una pista o alcanzar un resultado narrativo.
- El estado de misión puede ser no disponible, disponible, activa, completada, fallida o abandonada si el diseño necesita esos estados.
- El progreso depende de eventos del juego, no de comprobaciones dispersas en cada escena.
- Las misiones pueden ramificarse, admitir objetivos opcionales y reaccionar a distintas formas de resolver un problema.
- El diario debe distinguir objetivos conocidos de condiciones secretas o información no descubierta.
- La misma misión debe poder probarse con rutas alternativas y cargas de guardado.

Recomendación técnica: crear un `EventBus` de eventos de juego tipados o un mecanismo equivalente, sin convertirlo en un sistema global opaco. Por ejemplo, al producirse `item_acquired`, `npc_spoken_to` o `enemy_defeated`, el servicio de misiones comprueba los objetivos que escuchan ese evento.

### 6.12 Encuentros aleatorios

**Definido en el GDD:** sistema de encuentros aleatorios.

Requisitos:

- Cada zona puede referenciar perfiles de encuentros.
- Las tablas tendrán condiciones, peso/probabilidad, límites y requisitos.
- El sistema debe respetar el estado actual: encuentros ya resueltos, hora o periodo si existe, alerta, nivel de amenaza y progresión de misión.
- Debe existir la opción de no generar encuentro.
- Los encuentros de historia no se deben duplicar por error como encuentros aleatorios.
- Debe ser posible desactivar encuentros aleatorios durante pruebas.
- Una semilla permite reproducir el resultado de generación durante depuración.

Evitar usar azar puro en cada paso. Una probabilidad excesiva puede convertir viajes cortos en combates repetitivos; definir frecuencia, variedad y opciones de evitar o preparar encuentros.

### 6.13 NPC, relaciones y reclutamiento

**Definido en el GDD:** interacción con NPC de distintas disposiciones y reclutamiento de héroes/NPC.

Datos y estados recomendados:

- Identidad y función narrativa.
- Estado de disposición o relación relevante.
- Ubicación actual y condiciones de aparición.
- Conversaciones y condiciones.
- Facción o afiliación, si aplica.
- Posibles estados de misión.
- Posibilidad y requisitos de reclutamiento.
- Estadísticas y equipo si puede combatir.

Para el MVP, limitar el grupo a un personaje principal y, como máximo, un aliado reclutable. Primero resolver quién controla al aliado, cómo sigue al jugador, cómo se incorpora al combate y cómo se guardan sus datos. El reclutamiento no debe ser sólo una animación: debe actualizar estado, inventario/grupo, disponibilidad futura y misiones afectadas.

### 6.14 Guardado y carga

Sistema imprescindible para el tipo de juego previsto.

Requisitos:

- Guardar versión del formato de partida.
- Guardar identificadores de contenido y versión de paquetes necesarios.
- Guardar la ubicación, estado del personaje, inventario, equipo, grupo, misiones, mundo descubierto, NPC afectados, encuentros resueltos y variables de campaña.
- No serializar nodos de escena de Godot de forma indiscriminada; guardar un modelo de datos estable y reconstruir la escena al cargar.
- Validar el archivo antes de aplicarlo al estado activo.
- Mostrar error comprensible si falta contenido requerido o el archivo está dañado.
- Mantener, como mínimo, guardado manual y autosave en puntos seguros si el diseño los adopta.
- Escribir el archivo de forma segura para reducir el riesgo de corrupción si el juego se cierra durante el guardado.

Criterios: una partida cargada debe restaurar el mismo estado de misión, objetos recogidos, enemigos derrotados y aliados reclutados que existía al guardar.

## 7. Arquitectura técnica recomendada en Godot

### 7.1 Principios

- Adoptar una versión estable de Godot y fijarla para el equipo durante cada hito.
- Separar datos, lógica de reglas, estado de campaña, presentación y herramientas de contenido.
- Evitar una escena gigantesca que contenga la lógica de todos los sistemas.
- Evitar singletons globales para todo. Usar autoloads sólo para servicios realmente globales y de ciclo de vida claro.
- Diseñar interfaces pequeñas entre sistemas y documentar quién es propietario de cada estado.
- Mantener el núcleo jugable ejecutable desde temprano.
- Usar control de versiones desde el primer día.

### 7.2 Capas del proyecto

1. **Presentación:** escenas, animaciones, interfaces, audio y señales de entrada.
2. **Aplicación:** flujo de partida, transición entre lugares, menús, selección de acciones y coordinación de sistemas.
3. **Dominio:** reglas, personajes, combate, inventario, misiones, encuentros y validación de acciones.
4. **Datos y contenido:** definiciones de entidades, mapas, diálogos, tablas de botín y paquetes de contenido.
5. **Persistencia:** serialización, lectura, migración y validación de partidas.
6. **Herramientas y pruebas:** validadores, depuración, generadores de datos de prueba y pruebas automatizadas.

La capa de dominio no debe depender de nodos visuales concretos. Esto permite probar resultados sin ejecutar toda la interfaz y reduce la fragilidad de futuras herramientas de creación.

### 7.3 Servicios sugeridos

Nombres indicativos; no es obligatorio implementarlos todos como autoload:

- `GameSession`: coordina la partida activa y su estado.
- `ContentRegistry`: registra y resuelve entidades por ID.
- `RulesService`: resuelve reglas y tiradas.
- `DiceService`: gestiona las tiradas y semillas reproducibles.
- `WorldState`: mantiene el estado cambiante de la campaña.
- `TravelService`: administra transiciones y viajes.
- `EncounterService`: crea encuentros aleatorios o predefinidos.
- `CombatService`: administra un combate activo.
- `InventoryService`: aplica operaciones válidas sobre objetos y equipo.
- `QuestService`: actualiza misiones ante eventos de juego.
- `DialogueService`: evalúa diálogos, condiciones y consecuencias.
- `SaveService`: guarda, carga y migra partidas.
- `LocalizationService`: devuelve textos según el idioma seleccionado.
- `AudioService`: música y efectos de sonido, si hace falta un punto común de control.

No es necesario crear un servicio independiente cuando una clase pequeña y local sea suficiente. La arquitectura debe reducir acoplamiento, no maximizar el número de clases.

### 7.4 Estructura inicial de carpetas

```text
res://
  project.godot
  scenes/
    boot/
    menus/
    character_creation/
    exploration/
    tactical_map/
    interiors/
    ui/
  scripts/
    app/
    domain/
      rules/
      characters/
      combat/
      inventory/
      quests/
      dialogue/
      world/
      encounters/
    services/
    data_access/
  content/
    core/
      rules/
      items/
      creatures/
      characters/
      quests/
      encounters/
    campaigns/
      prototype_campaign/
        world/
        maps/
        dialogue/
        quests/
        encounters/
  assets/
    sprites/
    tilesets/
    portraits/
    ui/
    audio/
    fonts/
  localization/
  tools/
  tests/
    unit/
    integration/
    test_content/
  docs/
```

Esta estructura es un punto de partida. Se debe ajustar según el tamaño real; evitar crear carpetas vacías para sistemas que todavía no existen.

### 7.5 Formatos de datos

En Godot se pueden usar recursos nativos, JSON u otros formatos. Recomendación inicial:

- Recursos tipados de Godot para datos estáticos internos cuando faciliten edición e inspección.
- JSON con esquema documentado para importar/exportar contenido y posibilitar herramientas externas, si el formato queda bien definido.
- Estado de partida serializado por separado de los recursos que definen el contenido.
- IDs estables en vez de depender del nombre visible o de rutas frágiles de archivos.

No mezclar sin criterio recursos nativos, JSON y diccionarios improvisados. Cada tipo de dato debe tener un formato canónico y validaciones.

### 7.6 Convención de identificadores

Usar IDs estables, legibles y con espacio de nombres. Ejemplos conceptuales:

```text
core:item.health_potion
core:creature.goblin_scout
prototype:quest.missing_scout
prototype:location.riverside_camp
```

Estos IDs son ejemplos, no contenido definitivo. Evitar reutilizar un ID para otra entidad después de que existan partidas guardadas o mods que lo referencien.

### 7.7 Compatibilidad del contenido creado por usuarios

El soporte de mods debe desarrollarse con seguridad y versionado desde el comienzo, aunque la instalación de mods se habilite después.

Requisitos de diseño:

- Identificación de autor, versión, versión mínima del juego y dependencias.
- Declaración de IDs proporcionados por cada paquete.
- Validación de referencias faltantes, datos incorrectos y conflictos.
- Manejo explícito de recursos ausentes.
- Compatibilidad versionada del esquema de datos.
- Reglas claras para sobrescribir o extender contenido existente.
- No ejecutar código arbitrario de paquetes externos en la primera versión de mods.
- Mostrar qué contenido requiere una partida guardada.

Para la primera implementación de mods, favorecer contenido declarativo (datos, mapas, diálogos, recetas y configuraciones) antes que scripts arbitrarios. Permite construir un ecosistema inicial más fácil de validar y depurar.

## 8. Interfaz y experiencia de usuario

### 8.1 Vistas mínimas del MVP

- Menú principal.
- Nueva partida y creación de personaje.
- Exploración del mundo.
- Interacción/diálogo.
- Pantalla de combate táctico.
- Ficha del personaje.
- Inventario y equipo.
- Diario de misiones.
- Mapa y registro de tiradas/eventos.
- Menú de pausa, opciones, guardar y cargar.

### 8.2 Principios de UX

- El jugador debe saber qué unidad está seleccionada, qué puede hacer y qué coste tiene cada acción.
- Los resultados de dados y reglas relevantes deben poder inspeccionarse.
- La información crítica no debe depender sólo del color.
- Los mensajes de error explican qué acción no se pudo ejecutar y por qué, sin revelar información narrativa oculta.
- Los menús principales deben ser navegables con ratón y teclado. El soporte de mando puede añadirse según la plataforma objetivo.
- El texto de la interfaz debe ser localizable.
- Las animaciones no deben impedir acciones reiteradas innecesariamente; permitir acelerar o reducir animaciones cuando sea viable.

### 8.3 Revisión de interfaz

En cada iteración, observar al menos a una persona que no haya construido esa pantalla. Comprobar si puede realizar una tarea sin instrucciones orales. Registrar la confusión exacta y priorizar los cambios según impacto, no sólo preferencia estética.

## 9. Dirección de arte y contenido audiovisual

### 9.1 Dirección de arte

**Definido en el GDD:** pixel art con estética de los años 80 y 90, de 8 o 16 bits.

Antes de producir gran cantidad de sprites se debe crear una breve guía artística con:

- Resolución lógica del juego y escalado de pantalla.
- Tamaño de tiles y personajes.
- Paleta principal y límites de contraste.
- Perspectiva y orientación de personajes.
- Reglas de iluminación, sombras, contornos y animaciones.
- Diferencias visuales entre terreno, coberturas, objetos interactivos y unidades.
- Guía de retratos, iconos y efectos de hechizos.

No combinar indiscriminadamente pixel art de escalas muy distintas. Los recursos deben compartir resolución de píxel, tratamiento de contorno, saturación y proporciones.

### 9.2 Orden de producción de arte

1. Sprites provisionales y tiles de prueba.
2. Personaje jugable con animaciones mínimas: reposo, caminar, recibir impacto y atacar.
3. Tiles de terreno y objetos que bloqueen movimiento o línea de visión.
4. Enemigos del MVP.
5. Efectos de ataques, impactos y estados.
6. Iconografía de inventario, habilidades y misiones.
7. Retratos y elementos narrativos.
8. Pulido visual después de validar escalas y cámara.

No producir decenas de criaturas antes de probar la escala de los personajes, la lectura del combate y la animación del movimiento.

### 9.3 Audio

El GDD no define un sistema de audio. Propuesta inicial:

- Ambientes por zona.
- Música de exploración y combate.
- Efectos claros para ataques, interfaz, obtención de objetos, interacción y resultados importantes.
- Controles separados de música, ambiente y efectos.

El audio no debe bloquear el MVP si el núcleo aún no es jugable. Se pueden usar recursos temporales con licencia adecuada mientras se valida la experiencia.

## 10. Datos, eventos y flujo de información

### 10.1 Definiciones frente a estado

Separar dos conceptos:

- **Definición:** qué es una espada, un goblin, una misión o una ciudad. Cambia con las actualizaciones del contenido.
- **Estado:** qué espada lleva el personaje, si ese goblin murió, si la misión se completó o si la ciudad está alertada. Cambia durante una partida y debe guardarse.

Si ambos conceptos se mezclan, resultará difícil modificar contenido sin romper partidas guardadas.

### 10.2 Eventos de juego

Una acción resuelta puede emitir eventos como:

- `check_resolved`
- `combat_started`
- `combatant_defeated`
- `item_acquired`
- `item_used`
- `location_entered`
- `npc_interaction_completed`
- `dialogue_choice_selected`
- `quest_state_changed`
- `party_member_recruited`

Los nombres son propuestas. Conviene tiparlos y documentar el formato de sus datos. No utilizar cadenas arbitrarias sin validación para todas las comunicaciones del juego.

### 10.3 Transacciones de acción

Las acciones con varias consecuencias deben ser atómicas desde la perspectiva de la lógica. Por ejemplo, consumir una poción debe validar inventario, gastar la cantidad, aplicar el efecto y emitir el evento correspondiente sin duplicar ni perder unidades si ocurre un error en mitad de la operación.

## 11. Guardado, rendimiento y calidad técnica

### 11.1 Rendimiento

No optimizar a ciegas. Añadir herramientas de medición y comprobar:

- Tiempo de cálculo de rutas.
- Actualización de unidades visibles.
- Coste de evaluación de IA por turno.
- Carga de mapas y recursos.
- Tiempo de guardado/carga.
- Memoria en mapas representativos.

La visión a largo plazo incluye mundos enormes, pero el MVP debería cargar sólo la zona y los datos necesarios. El diseño de contenido no debe exigir mantener un universo completo activo en memoria.

### 11.2 Robustez

- Los archivos de contenido inválidos deben producir errores legibles, no cierres inesperados.
- Una acción ilegal no debe consumir turno, recurso u objeto salvo que la regla lo indique expresamente.
- El combate debe terminar correctamente aunque una unidad sea eliminada durante una cadena de efectos.
- La carga de partida debe validar IDs desconocidos y versiones.
- El sistema debe manejar rutas imposibles, objetivos que desaparecen y misiones que pierden un requisito.
- La lógica del juego no debe depender de una animación completada para actualizar el estado correcto.

## 12. Pruebas y criterios de aceptación

### 12.1 Pruebas unitarias

Cubrir funciones pequeñas y deterministas:

- Modificadores y estadísticas derivadas.
- Tiradas y expresiones de dados permitidas.
- Cálculos de ataque, defensa, daño y curación incluidos en el alcance.
- Validación de movimiento y distancias.
- Operaciones de inventario y equipo.
- Evaluación de condiciones de misión.
- Tablas y probabilidades de encuentro.
- Reglas de percepción y detección.
- Serialización/deserialización y migraciones de datos.

### 12.2 Pruebas de integración

- Una acción de diálogo actualiza el estado de una misión.
- Obtener un objeto actualiza inventario, diario y objetivos pertinentes.
- Derrotar un enemigo resuelve el combate y actualiza el mundo.
- Reclutar un NPC actualiza el grupo y persiste tras cargar partida.
- Una emboscada deriva correctamente de percepción, sigilo y estado del encuentro.
- Dos rutas de resolución diferentes completan un mismo objetivo narrativo.
- Un encuentro aleatorio no duplica un encuentro único de historia.

### 12.3 Pruebas de guardado/carga

Para cada sistema, guardar en distintos estados y comprobar que se restaura correctamente. Casos críticos: inventario con objetos apilados, consumibles parcialmente gastados, misión ramificada, aliado reclutado, contenedor saqueado, enemigo derrotado, mapa descubierto y partida guardada justo después de un combate.

### 12.4 Pruebas manuales de aceptación del MVP

El MVP se considera aceptado sólo si se cumplen todos estos puntos:

- [ ] Se inicia una partida nueva y se crea un personaje válido.
- [ ] Se puede recorrer la zona y entrar a un espacio interior.
- [ ] Una acción de exploración o interacción se resuelve con la regla/tirada correcta.
- [ ] Al menos un obstáculo puede resolverse de dos maneras funcionales.
- [ ] Puede iniciarse, jugarse y finalizarse un combate por turnos.
- [ ] Sigilo y percepción influyen en una situación de detección/emboscada.
- [ ] Investigación puede revelar información o botín según reglas definidas.
- [ ] Se pueden recoger, usar y equipar objetos del alcance inicial.
- [ ] Se inicia y completa una misión con objetivos rastreados.
- [ ] Se puede reclutar un NPC y ese estado persiste.
- [ ] Guardar, cerrar, cargar y continuar restaura el estado correcto.
- [ ] Los errores de contenido o de acción producen mensajes controlados.
- [ ] La experiencia se puede completar con arte temporal sin depender de herramientas de desarrollo.

## 13. Plan de hitos y prioridades

Los tiempos deben estimarse tras completar la Etapa 0 y confirmar disponibilidad del equipo. Dar fechas ahora sería especulativo; utilizar hitos con criterios de salida evita ocultar incertidumbre.

| Hito | Trabajo principal | Resultado verificable |
|---|---|---|
| H0 — Fundamentos | Decisiones, prototipo de dados/reglas, esquema de datos y control de versiones | Especificaciones base aceptadas y prototipo técnico ejecutable |
| H1 — Exploración | Movimiento, mapas, interacción, transición entre zonas | El personaje explora y entra a un interior |
| H2 — Resolución | Reglas, tiradas, diálogos, condiciones y registro | Un problema se puede resolver de más de una manera |
| H3 — Combate | Turnos, acciones, objetivos, movimiento, IA básica y estados | Un encuentro completo jugable |
| H4 — Progresión | Inventario, botín, quests, NPC reclutable y persistencia | Un ciclo de misión de principio a fin |
| H5 — Vertical slice | Arte integrado, sonido básico, UX y corrección de errores | Una demostración corta y coherente |
| H6 — Alpha | Más contenido, balance y estabilidad | Campaña de prueba repetible |
| H7 — Beta | Pruebas externas, accesibilidad, guardados y documentación | Build candidata a lanzamiento de prueba |
| H8 — Contenido comunitario | Esquema versionado, validador, paquetes de datos y ejemplos | Un creador puede añadir contenido no ejecutable sin cambiar el código del juego |

### 13.1 Priorización de tareas

Clasificar el backlog en:

- **P0 — Bloqueante:** impide iniciar o completar el bucle principal.
- **P1 — Necesario para MVP:** parte de los criterios de aceptación.
- **P2 — Después del MVP:** mejora la experiencia o añade variedad.
- **P3 — Visión de largo plazo:** mundos múltiples, herramientas avanzadas, mods extensos y sistemas de escala universal.

No iniciar varias tareas P0 en paralelo si compiten por el mismo esquema de datos o arquitectura. Terminar e integrar pequeñas piezas reduce el riesgo de incompatibilidades.

## 14. Backlog inicial sugerido

### Fundación del repositorio

- [ ] Crear repositorio Git y definir flujo de ramas sencillo.
- [ ] Añadir `.gitignore` adecuado para Godot y documentación.
- [ ] Crear proyecto Godot y configurar resolución lógica, escalado e input.
- [ ] Crear escenas de arranque y menú principal provisional.
- [ ] Añadir guía de estilo de código y convenciones de nombres.
- [ ] Configurar una escena de pruebas y datos de prueba.
- [ ] Crear un registro técnico de decisiones (ADR) para decisiones de arquitectura importantes.

### Núcleo de reglas

- [ ] Definir el subconjunto inicial de reglas de 2024.
- [ ] Definir modelo de personaje y estadísticas derivadas.
- [ ] Implementar servicio de dados con pruebas.
- [ ] Implementar pruebas de habilidad/salvación necesarias para el MVP.
- [ ] Implementar un resultado estructurado y un registro visible de tiradas.
- [ ] Documentar las reglas que aún no se implementan.

### Mundo e interacción

- [ ] Definir el modelo de ubicación y sus conexiones.
- [ ] Implementar movimiento exploratorio.
- [ ] Implementar puntos de interacción.
- [ ] Implementar el estado de campaña y variables de mundo.
- [ ] Implementar diálogos con condiciones y efectos.
- [ ] Implementar una zona de exterior y una zona interior.

### Combate

- [ ] Definir si la cuadrícula es ortogonal, isométrica u otra.
- [ ] Implementar movimiento de unidades con validación.
- [ ] Implementar iniciativa y orden de turnos según la especificación adoptada.
- [ ] Implementar selección de objetivo, alcance y línea de visión.
- [ ] Implementar ataques, daño y derrota.
- [ ] Implementar IA básica.
- [ ] Implementar log de combate.
- [ ] Crear pruebas de combate repetibles.

### Misiones, objetos y persistencia

- [ ] Definir modelo de objeto y estado de inventario.
- [ ] Implementar recoger/usar/equipar.
- [ ] Definir formato de misiones y objetivos.
- [ ] Implementar seguimiento de misiones por eventos.
- [ ] Implementar perfil básico de botín.
- [ ] Implementar NPC reclutable y estado de grupo.
- [ ] Implementar guardado/carga y pruebas de integridad.

### Vertical slice

- [ ] Escribir una misión corta con varias aproximaciones.
- [ ] Crear NPC neutral, enemigo y aliado potencial.
- [ ] Crear un encuentro normal y una situación de emboscada.
- [ ] Crear objetos, botín e inventario suficientes para probar el ciclo.
- [ ] Crear sprites y efectos mínimos con una guía artística común.
- [ ] Realizar una prueba completa desde nueva partida hasta guardar y cargar.
- [ ] Registrar problemas y priorizar correcciones.

## 15. Flujo de trabajo del equipo

Aunque el proyecto sea desarrollado por una sola persona, conviene mantener un flujo claro:

1. Elegir una tarea pequeña del backlog y definir sus criterios de aceptación.
2. Crear una rama o cambio aislado si el tamaño lo justifica.
3. Implementar una parte funcional mínima.
4. Añadir o actualizar pruebas.
5. Probar desde el juego, no sólo desde el editor.
6. Revisar rendimiento, legibilidad y acoplamiento.
7. Integrar el cambio y actualizar la documentación.

Cada sistema debe tener un responsable funcional, incluso si esa persona es el propio desarrollador. Evitar que múltiples sistemas escriban directamente los mismos datos de campaña; un servicio o modelo debe ser el propietario de cada cambio.

### 15.1 Control de versiones

- Versionar proyecto, scripts, archivos de configuración y fuentes editables de contenido.
- No versionar cachés generadas, builds grandes ni archivos temporales sin necesidad.
- Definir cómo se almacenan los archivos grandes y los recursos artísticos fuente.
- Crear etiquetas para builds que cumplan hitos.
- Mantener un changelog y anotar cambios incompatibles con partidas guardadas.

## 16. Riesgos principales y mitigaciones

| Riesgo | Impacto | Mitigación recomendada |
|---|---|---|
| Alcance demasiado grande | El proyecto puede no llegar a una versión jugable | Limitar la vertical slice, aplazar multiverso/editor y exigir criterios de salida por hito |
| Reglas incompletas o ambiguas | Sistemas inconsistentes y retrabajo | Definir el subconjunto de reglas con ejemplos y pruebas antes de extenderlo |
| Acoplamiento de sistemas | Cambiar combate rompe quests, interfaz o guardado | Separar dominio, presentación y estado; integrar mediante servicios/eventos tipados |
| Generación de contenido sin límites | Mundo y botín incoherentes o costosos de equilibrar | Usar tablas controladas y contenido diseñado a mano en la primera versión |
| Sistema de mods prematuro | Tiempo perdido en herramientas antes de validar el juego | Estabilizar modelos de datos y comenzar con contenido declarativo versionado |
| Guardados incompatibles | Pérdida de progreso con actualizaciones | Versionar guardados, validar dependencias y probar migraciones |
| Pixel art inconsistente | La experiencia pierde coherencia visual | Crear guía de resolución, escala, paleta y animación antes de producir contenido en masa |
| IA excesiva para la etapa | Retrasos y turnos lentos | Empezar con perfiles sencillos, medición y límites de cálculo |
| Dependencia de contenido con derechos de terceros | Riesgo de publicación, distribución o monetización | Definir una política de licencias y crear contenido original mientras se verifican permisos |
| Diseño de reglas basado sólo en documentación informal | Errores de reglas y dificultad de mantener compatibilidad | Mantener especificación de reglas, fuentes permitidas y pruebas de conformidad |
| Muchas mecánicas sin pruebas de extremo a extremo | Sistemas que funcionan por separado pero no juntos | Completar temprano un bucle de juego de principio a fin |


## 18. Decisiones pendientes que bloquean la especificación definitiva

Resolverlas gradualmente, pero no dejarlas implícitas:

1. ¿Será exclusivamente para un jugador o tendrá multijugador?
2. ¿La vista será superior, isométrica o con otra perspectiva?
3. ¿El combate será en cuadrícula y qué forma tendrá esa cuadrícula?
4. ¿Cuál es el subconjunto de las reglas de 2024 para el MVP?
5. ¿Qué plataformas son objetivo para la primera publicación?
6. ¿La primera campaña será completamente original o buscará compatibilidad con contenido concreto?
7. ¿Cómo se entiende la creación de mundo: edición dentro del juego, archivos externos o ambas?
8. ¿Los mods podrán cambiar reglas o sólo contenido?
9. ¿Habrá generación procedural? Si sí, ¿qué partes y con qué límites?
10. ¿Qué progresión se usará: niveles, experiencia, hitos u otro sistema?
11. ¿Cómo funciona un grupo: tamaño, turnos de aliados, control directo y reclutamiento?
12. ¿Qué condiciones llevan a victoria, derrota, muerte o retirada?
13. ¿Cuál será el modelo de distribución y qué política de contenido de usuarios se aplicará?
14. ¿Qué funciones deben existir sin conexión y cuáles, si alguna, requerirían servicios en línea?

## 19. Glosario inicial

- **Campaña:** conjunto de misiones, lugares, personajes y estados que forman una partida narrativa.
- **Contenido:** definiciones de mundos, mapas, entidades, misiones, objetos, diálogos y encuentros.
- **Estado del mundo:** cambios hechos durante una partida y persistidos en el guardado.
- **Entidad:** objeto de datos identificable, como personaje, criatura, objeto, región o misión.
- **MVP:** versión mínima que demuestra el bucle principal de juego de extremo a extremo.
- **Vertical slice:** muestra pequeña pero representativa que integra sistemas, arte, interfaz y audio con un nivel de calidad aproximado al producto objetivo.
- **Mod:** paquete externo que añade o modifica contenido del juego.
- **ID estable:** identificador que no cambia sólo porque cambie el nombre visible de una entidad.
- **Servicio de reglas:** módulo central que calcula las resoluciones conforme al conjunto de reglas adoptado.
- **Evento de juego:** notificación estructurada de algo que ocurrió y que otros sistemas pueden necesitar procesar.

## 20. Definición de éxito de la primera versión

La primera versión no se mide por el tamaño del mapa ni por la cantidad de contenido. Se considera exitosa si demuestra de forma estable que:

- Las reglas y las tiradas funcionan de forma consistente.
- El jugador puede explorar, interactuar, resolver conflictos y combatir.
- Más de un enfoque conduce a resultados válidos.
- Las misiones responden a lo que ocurre en el mundo.
- El inventario, el botín y los aliados se integran con la progresión.
- Guardar y cargar no rompe el estado de la campaña.
- Los elementos de contenido se pueden crear o modificar sin escribir una escena nueva por cada entidad.
- La base técnica puede ampliarse sin exigir una reescritura del núcleo.

**Orden recomendado de ejecución:** decidir el alcance del MVP → prototipar movimiento y reglas → completar un combate → enlazar interacción, misiones e inventario → guardar/cargar → integrar arte y UX → probar la vertical slice → ampliar contenido → construir herramientas de mods.

---

## Apéndice A — Plantilla mínima para especificar un sistema

Antes de implementar un sistema nuevo, completar esta ficha:

- **Nombre del sistema:**
- **Problema que resuelve:**
- **Incluido en el MVP:** Sí / No
- **Entradas:**
- **Estado que modifica:**
- **Salidas/eventos:**
- **Reglas aplicables:**
- **Interacción con otros sistemas:**
- **Casos límite:**
- **Pruebas unitarias:**
- **Pruebas de integración:**
- **Criterio de aceptación observable:**
- **Riesgos y decisiones pendientes:**

## Apéndice B — Plantilla mínima de contenido

Toda entidad de contenido debería tener, como mínimo, los campos que correspondan a su tipo:

- `id`: identificador único y estable.
- `display_name` o clave de localización.
- `description` o clave de localización, cuando aplique.
- `content_version`: versión del esquema o del paquete cuando sea necesario.
- Referencias a otras entidades mediante IDs, no por nombres visibles.
- Parámetros validados con límites y tipos definidos.
- Recursos audiovisuales opcionales y rutas comprobadas.
- Condiciones de aparición, uso o disponibilidad si corresponden.

No todas las entidades tendrán exactamente los mismos campos. Se deben definir esquemas específicos para personajes, criaturas, objetos, localizaciones, diálogos, encuentros y misiones.
