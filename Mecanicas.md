# Mecanicas

## 1. Creacion de mundos
el jugador podrá crear su propio mundo con la tematica que le agrade, y agregar a este mundo el contenido ya creado previamente que le agrade

### 1.2 Interfaz
se muestra una pantalla del espacio con los mundos creados:
- Abeir-Toril (forgotten Realms)

### 1.3 Creacion de un nuevo mundo

> Omitir esta mecanica en el MVP


## 2. Creacion de Personaje
para cada de las siguientes secciones sera posible agregar un nuevo elemento, mostrar todas las posibles elecciones para cada categoria y las elecciones por nivel dentro de cada categoria
- Eleccion de Especie 
> Especies para MVP: Human, Elf, Orc, Goliath, Halfling, Tiefling y Dragonborn
- Eleccion de Background
> Backgrounds para MVP: Soldier, Noble, Sage, Acolyte, Farmer
- Eleccion de Clase
> Clases para MVP: Fighter, Ranger, Wizard, Cleric
- Eleccion de Subclase (si es posible)
> no implementada para MVP

Despues:
- Eleccion de stats (Point buy, Dice Roll, Manual)
- Eleccion de equipamento (Clase y Background, Ir a tienda basica con elementos iniciales para vender o comprar lo deseado)
- Nombre, Personality Traits, Ideals, Bonds, Flaws, History
- Apariencia (menu de customizacion de character)

## 3. Exploracion de mundo
la interfaz principal donde casi todo el juego se desarrolla, la vista predeterminada es vista de region. Es un mapa en 2d mostrando la region de la zona, con una malla Hexagonal, y coloreado de zonas y ofreciendo una descripcion de cada una

> para este MVP la region se genera proceduralmente y usar esta opcion en el futuro para construir mas mundos
### 3.1 Zonas de Movimiento
la vista de mapa hexagonal con distintos tiles, cada tile se traduce a una zona/bioma diferente
#### 3.1.1 Grassland
##### Descripcion
##### Efectos
##### Eventos
##### Encuentros
#### 3.1.2 Forest
##### Descripcion
##### Efectos
##### Eventos
##### Encuentros
#### 3.1.3 Dense Forest
##### Descripcion
##### Efectos
##### Eventos
##### Encuentros
#### 3.1.4 Paved Road
##### Descripcion
##### Efectos
##### Eventos
##### Encuentros
#### 3.1.5 Dirt Road
##### Descripcion
##### Efectos
##### Eventos
##### Encuentros
#### 3.1.6 Hill
##### Descripcion
##### Efectos
##### Eventos
##### Encuentros
#### 3.1.7 Mountain
##### Descripcion
##### Efectos
##### Eventos
##### Encuentros
#### 3.1.8 Vulcano
##### Descripcion
##### Efectos
##### Eventos
##### Encuentros
#### 3.1.9 Swamp
##### Descripcion
##### Efectos
##### Eventos
##### Encuentros
#### 3.1.10 Coast
##### Descripcion
##### Efectos
##### Eventos
##### Encuentros
#### 3.1.11 River
##### Descripcion
##### Efectos
##### Eventos
##### Encuentros
#### 3.1.12 Ocean
##### Descripcion
##### Efectos
##### Eventos
##### Encuentros
#### 3.1.13 Lake
##### Descripcion
##### Efectos
##### Eventos
##### Encuentros

### 3.2 Zonas de interes
Estas zonas al entrar te da la opcion de accesar directamente (sin la necesidad de un evento generado) e interactuar con lo que haya ahi (Edificios/NPC/exploracion)

#### 3.2.1 Farm
##### Descripcion
##### Edificios
##### NPC
##### Misiones
#### 3.2.2 Village
##### Descripcion
##### Edificios
##### NPC
##### Misiones
#### 3.2.3 Town
##### Descripcion
##### Edificios
##### NPC
##### Misiones
#### 3.2.4 City
##### Descripcion
##### Edificios
##### NPC
##### Misiones
#### 3.2.5 Mine
##### Descripcion
##### Edificios
##### NPC
##### Misiones
#### 3.2.8 Cemetery
##### Descripcion
##### Edificios
##### NPC
##### Misiones
#### 3.2.9 Burrow
##### Descripcion
##### Edificios
##### NPC
##### Misiones
#### 3.2.10 road Inn/Tavern
##### Descripcion
##### Edificios
##### NPC
##### Misiones
#### 3.2.11 Dungeon
##### Descripcion
##### Edificios
##### NPC
##### Misiones
#### 3.2.12 Castle
##### Descripcion
##### Edificios
##### NPC
##### Misiones

### 3.2 Distancia
el diametro de un hex equivale a una distancia de 3 millas

### 3.3 Movimiento
para el viaje se puede considerar 3 tipos de movimiento:
- paso cauteloso
- paso normal
- paso forzado

cada una representa una forma que modifica algunos parametros

#### 3.3.1 Paso Normal
avanzar a paso normal se tiene una velocidad de 3mph, lo que se traduce a que cada hora se puede trasladar un hex

#### 3.3.2 Paso Cauteloso
avanzar con paso cauteloso reduce la velocidad a 2mph, pero se puede viajar superando una prueba de stealth para pasar indetectado a cualquier encuentro generado

#### 3.3.3 Paso Forzado
avanzar con paso forzado aumenta la velocidad a 4mph pero se reduce -5 a Passive Perception, lo que le da desventaja para percibir cualquier encuentro

### 3.3.4 Agotamiento
se puede avanzar una cantidad de 8 horas por el mapa sin recibir agotamiento
pasando esa hora, se hara una tirada de DC 10, +1 por hora pasada las 8 horas o ganara un nivel de agotamiento 

### 3.3.5 Terreno Dificil
cuando se cruza una zona como Dense Forest, Snow, Hills o Mountain la velocidad se reduce a la mitad

### 3.3.6 Uso de monturas
Si se usa una montura la velocidad aumenta dependiendo de la montura, la montura tambien es afectada por cansancio pasando las 8 horas continuas

para usar una montura es necesario visitar un establo para comprar una

### 3.3.7 Monturas
la velocidad dependera de la calidad y un modificador interno al azar siguiendo los limites establecidos
- Burro 0.3 a 1.2 mph más
- Caballo 0.8 a 3 mph más
- Camello 1 a 2 mph más

### 3.4 Tiempo
el tiempo marca algunos efectos, iluminacion y probabilidad ciertos eventos sucedan, ademas de contar los quest con limite de tiempo para reflejar urgenciay tactica real pueden fallarse si se rebasa el tiempo definido

#### 3.4.2 Avance del tiempo
cada que se ejecute una accion de mover el mapa, el personaje semovera en el espacio y el tiempo se movera al mismo tiempo, se implementan botones de Pause, Play, Forward x2, x4, x8

Estado del prototipo: la escena reutilizable de interior muestra edificios, NPC, afiliación/reputación y estado de misiones declarados para el POI; la granja es el ejemplo configurado. Sus conversaciones comprueban requisitos, muestran texto y aplican cambios de relación/reputación una sola vez. Cada tipo de POI también puede declarar interacciones con pruebas de habilidad, texto de éxito y fallo, y registro en el diario. Cada interacción solo se resuelve una vez por partida; se guardan sus resultados y pueden aplicar cambios de reputación de facción declarados en datos. Posada y establo ofrecen además sus servicios básicos.

## 4. Encuentros (Mapa Isometrico generado proceduralmente)
El encuentro es generado proceduralmente basados en el paso del jugador, la zona del hex tile y su nivel
cada que se entra a una ventana de encuentro (mapa isometrico) se debe seguir la siguiente estructura:
1. Resolver Sigilo y percepcion para ver que bando se ha detectado, ajustar ventajas y ataques de oportunidad (emboscadas)
2. Resolver iniciativas, solicitar al usuario tirada de dados
3. Movimiento en el mapa
 - Tanto el jugador como los NPC tienen una velocidad (normalmente 30 ft)
 - cada cuadro es de 5 ft
 - marcar la zona disponible para moverse
 - limitar movimiento solo en la zona disponible para moverse
 - confirmar movimiento
4. Resolver acciones
 - Hablar
 - Atacar
 - Ayudar
 - Influenciar
 - Buscar
 - Esquivar
 - Disengage
 - Magic
 - Study
 - Esconderse
 - preparar
 - utilizar
 - Defenderse
 - sujetar
5. Actualizar y mostrar barras de vida en tiempo real y el indicador de daño/curacion recibida
6. Validar en tiempo real cuando una entidad muere
7. mostrar entidades aliadas, enemigas y neutrales con algun identificador
8. cada ronda suma 6 segundos al tiempo global

Estado del prototipo: los marcadores del mapa táctico muestran jugador, rival y a Mira cuando se une al grupo; la orden de ataque de Mira aún se resuelve durante el turno del jugador, sin iniciativa ni turno táctico independiente. El sigilo puede intentarse detrás de cobertura total o dentro de casillas fijas de vegetación densa, que impiden la línea de visión sin bloquear el movimiento.

Cobertura táctica del prototipo: algunas casillas marcadas en el tablero proporcionan cobertura parcial (+2 CA contra ataques). La cobertura no bloquea la línea de visión ni modifica salvaciones; las casillas con cobertura total siguen bloqueando movimiento y línea de visión según el mapa.

## 5. Tiradas de dados
1. mostrar un boton que diga "tirar los dados", mostrando un label de que dados se tirarán
2. mostrar la simulacion de dados y resultado 
3. Situacion especial para attack rolls con 1 y 20 
 - en tiradas con 1 resolver situacion
  - Fumble situation: menos probable, efecto negativo adicional
  - Fumble: Fallo Automatico
 - En tiradas con 20 resolver situation
  - Critical Situation: menos probable, efecto positivo adicional
  - Critical: Critico automatico
4. para tiradas d20 que no sean attack rolls solo añadir un texto generico y divertido describiendo la pifia o el exito critico

Estado del prototipo: las tiradas manuales muestran d20 3D; los dados de daño y curación d4, d6, d8, d10 y d12 se animan con el valor obtenido, uno tras otro. Si el contenido define d20 como dado de daño, reutiliza su escena. La caída se sincroniza con el resultado de reglas mediante tween; todavía no usa simulación física.

## 6. Facciones
en el mundo siempre existen facciones distintas con distintos propositos, cada faccion tiene un alineamiento y objetivo, pueden mostrar aceptacion o rechazo para otras facciones y jugadores, esto se muestra con un nivel de 100 a  -100 donde 0 es neutral
