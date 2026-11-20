# POS Windows (.exe) — Rediseño de Recibos y Productos

> **Proyecto:** `pos_flutter_firebase`  
> **Plataforma:** Windows `.exe` con Flutter Desktop  
> **Rol:** Administrador / dueño  
> **Alcance:** rediseño visual y de UX de las vistas **Recibos** y **Productos**, además de los componentes reutilizables de búsqueda, filtros, tablas, filas, estados y contexto multi-sucursal.

---

## 0. OBJETIVO

Las pantallas actuales ya tienen la información funcional correcta, pero visualmente presentan un problema importante de **densidad y alineación**:

- las columnas se pegan unas a otras;
- los encabezados aparecen concatenados (`FOLIOSUCURSALHORAPAGOESTADOTOTAL` / `PRODUCTOPRECI...`);
- algunas filas parecen texto corrido en vez de registros tabulares;
- hay demasiado espacio vacío alrededor de la información útil;
- el contexto de múltiples sucursales no se entiende suficientemente dentro de cada registro;
- el buscador ocupa mucho alto para una acción simple;
- los datos importantes no tienen una jerarquía visual clara.

El rediseño debe convertir estas pantallas en **vistas administrativas de datos**, no en listas de `Text` colocados horizontalmente.

### Resultado visual esperado

La interfaz debe aproximarse a este patrón:

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│ [Todas las sucursales ▼]    [Hoy] [Ayer] [Semana] [Mes]      usuario   salir │
├──────────────┬───────────────────────────────────────────────────────────────┤
│              │                                                               │
│ Dashboard    │  Recibos                                                     │
│ Recibos      │  Historial de ventas                                        │
│ Productos    │                                                               │
│ Pollo        │  [Buscar folio o cliente...] [Filtros]                      │
│ Back Office  │                                                               │
│              │  ┌─────────────────────────────────────────────────────────┐  │
│              │  │  HOY · 5 recibos · Todas las sucursales                 │  │
│              │  ├───────┬──────────────┬───────┬────────┬────────┬───────┤  │
│              │  │ Folio │ Sucursal     │ Hora  │ Pago   │ Estado │ Total │  │
│              │  ├───────┼──────────────┼───────┼────────┼────────┼───────┤  │
│              │  │T-00031│ Suc. Norte  │15:45  │Efectivo│Pagado │$2,975│  │
│              │  │D-00012│ Suc. Centro │15:43  │Efectivo│Devol. │ $940 │  │
│              │  └───────┴──────────────┴───────┴────────┴────────┴───────┘  │
│              │                                                               │
└──────────────┴───────────────────────────────────────────────────────────────┘
```

---

# 1. REGLA FUNDAMENTAL: NO CAMBIAR LA LÓGICA

Este archivo describe **UI/UX**. No sustituye la lógica existente.

Conservar exactamente:

- `AdminScope` como única fuente global de `selectedStoreId` y `range`.
- `selectedStoreId == null` = **Todas las sucursales**.
- `AdminDateRange` = Hoy / Ayer / Esta semana / Este mes.
- queries acotadas con `.limit(...)`.
- filtros de sucursal y fecha ya existentes.
- `sale.clientCreatedAt ?? sale.createdAt` como fecha usada por las vistas.
- exclusión de documentos malformados sin romper la pantalla.
- `split` como **Mixto**, mostrando efectivo y tarjeta por separado.
- devolución / cancelación / parcial con sus estados existentes.
- stock exclusivamente desde `stockByStore/{storeId}`.
- acciones existentes de navegación y Firestore.
- flujo Android sin modificaciones.

**No crear mocks para mejorar la apariencia.** Si una vista no tiene datos, mostrar un estado vacío real.

---

# 2. CAUSA DEL PROBLEMA ACTUAL

## 2.1 Recibos

La tabla actual visualmente equivale a:

```text
FOLIOSUCURSALHORAPAGOESTADOTOTAL
T-000031$...Sucursal principal15:45 Efectivo Pagado $2,975
```

Esto provoca que:

- no existan límites visuales entre columnas;
- el ojo no pueda escanear filas rápidamente;
- sucursal y folio parezcan una sola cadena;
- estados y formas de pago se confundan;
- la pantalla se vea como un formulario roto aunque los datos sean correctos.

### Corrección

Construir una **tabla real con columnas explícitas** o, en ventanas más estrechas, una fila administrativa con bloques de ancho controlado.

Nunca usar una fila principal con `Row(children: [Text(...), Text(...), ...])` sin anchos/flex bien definidos.

---

## 2.2 Productos

La pantalla actual tiene el mismo problema y además mezcla:

- nombre;
- referencia;
- precio;
- stock total;
- stock por sucursal;
- vendidos;
- estado;

en una sola línea.

### Corrección

Separar claramente:

```text
Producto
REF

Precio
Stock total
Stock por sucursal
Vendidos en periodo
Estado
Acciones
```

En escritorio amplio puede mantenerse como tabla; en ancho menor cada registro debe poder pasar a una tarjeta de dos niveles.

---

# 3. SISTEMA VISUAL COMÚN PARA TABLAS

## 3.1 Contenedor

Cada tabla debe estar dentro de una `Card` blanca:

- radio: `16–20 px`;
- borde fino `#E7E9EF`;
- sombra casi imperceptible;
- padding exterior aproximado `16–20 px`.

No encerrar la tabla dentro de muchas tarjetas anidadas.

## 3.2 Encabezado de tabla

Encabezado gris muy suave:

```text
┌──────────────────────────────────────────────────────────────────────┐
│ FOLIO       SUCURSAL       FECHA      PAGO       ESTADO       TOTAL  │
└──────────────────────────────────────────────────────────────────────┘
```

Características:

- tamaño `11–12 px`;
- peso semibold;
- mayúsculas opcionales;
- color secundario;
- fondo `#F8F9FC`;
- altura `42–46 px`.

No usar texto pegado directamente al borde.

## 3.3 Filas

Altura base recomendada:

- Recibos: `64–72 px`.
- Productos: `72–86 px`.

Separación mediante:

- borde inferior suave, o
- bandas muy sutiles.

Evitar líneas negras fuertes.

## 3.4 Hover

Al pasar el cursor:

- fondo ligeramente diferente;
- cursor de selección si toda la fila es clickeable;
- no mover el contenido.

## 3.5 Alineación

Reglas:

- texto: izquierda;
- fechas/horas: izquierda o centro consistente;
- estados: centro/izquierda;
- cantidades: derecha;
- importes monetarios: derecha;
- acciones: derecha.

Los importes deben tener `tabularFigures` para que los dígitos queden alineados.

---

# 4. COMPONENTE REUTILIZABLE `AdminDataTable`

Crear un componente reutilizable para evitar que Recibos y Productos vuelvan a tener la misma regresión.

Ruta sugerida:

```text
lib/features/home/ui/desktop/admin/widgets/admin_data_table.dart
```

Debe aceptar conceptualmente:

```dart
AdminDataTable<T>(
  columns: [...],
  rows: [...],
  onRowTap: ...,
  emptyState: ...,
  loading: ...,
)
```

Cada columna debería poder definir:

```text
label
flex / width
alignment
builder
minimumWidth
```

No hace falta usar una clase genérica compleja si el proyecto actual no lo necesita; la prioridad es disponer de una forma consistente de controlar las columnas.

---

# 5. ENCABEZADO DE CONTEXTO MULTI-SUCURSAL

En ambas pantallas debe existir una línea compacta debajo del título.

### Todas las sucursales

```text
🏢  TODAS LAS SUCURSALES  ·  4 activas  ·  consolidado  ·  Este mes
```

### Una sucursal

```text
🏪  SUCURSAL CENTRO  ·  Este mes
```

Usar un `Container` o `DecoratedBox` azul muy suave.

El mensaje debe ser informativo, pero no debe competir con el contenido.

---

# 6. PANTALLA RECIBOS — REDISEÑO COMPLETO

Archivo objetivo:

```text
lib/features/home/ui/desktop/admin/admin_receipts_screen.dart
```

## 6.1 Encabezado

```text
Recibos
Historial de ventas
```

Debajo:

```text
[Todas las sucursales ▼]      [Hoy] [Ayer] [Semana] [Mes]
```

El selector de sucursal y periodo principal continúa viviendo en `AdminTopBar`; la pantalla solo debe mostrar el contexto resumido.

---

## 6.2 Barra de búsqueda

La búsqueda actual ocupa demasiado espacio vertical y utiliza un bloque oscuro.

Cambiarla por un input moderno y compacto:

```text
┌──────────────────────────────────────────────────────────────────────────┐
│ 🔍  Buscar por folio, cliente o importe...                         ⌕   │
└──────────────────────────────────────────────────────────────────────────┘
```

Altura: `48–52 px`.

Fondo: blanco.

Borde: `#E2E5EC`.

Focus: borde/acento del tema.

Placeholder: gris secundario.

Añadir botón secundario **Filtros** solo si ya existe lógica para filtros adicionales.

No inventar filtros que no existan.

---

## 6.3 Resumen encima de la tabla

En una franja compacta:

```text
5 recibos                         $8,165.40
Todas las sucursales             Este mes
```

El importe solo debe mostrarse si puede calcularse con los datos existentes y según las reglas actuales.

No convertir este bloque en otra fila de 6 KPIs.

---

## 6.4 Agrupación por fecha

Mantener la organización por día, pero mejorarla:

```text
01 OCT 2026                                      5 recibos
```

Después la tabla.

En periodos grandes:

```text
30 SEP 2026                                      14 recibos
29 SEP 2026                                      17 recibos
28 SEP 2026                                       9 recibos
```

No usar una Card independiente gigante por cada fecha si existen muchos días. Cada grupo debe ser compacto.

---

## 6.5 Tabla de recibos

Columnas recomendadas en escritorio >= 1200 px:

| Columna | Ancho conceptual | Contenido |
|---|---:|---|
| Expandir | 40 px | icono/chevron si existe detalle |
| Folio | 130 px | `T-000031` |
| Sucursal | 1.4 flex | nombre real |
| Fecha / hora | 120 px | `01/10/2026 15:45` |
| Pago | 140 px | Efectivo / Tarjeta / Mixto |
| Estado | 130 px | Pagado / Parcial / Devolución / Cancelado |
| Total | 130 px | `$2,975.00` |
| Acción | 60 px | chevron / menú |

### Regla importante

**Nunca permitir que las columnas colapsen hasta formar texto concatenado.**

Utilizar:

- `Expanded` con `flex`;
- `SizedBox(width: ...)` para columnas críticas;
- `ConstrainedBox(minWidth: ...)`;
- `LayoutBuilder` para cambiar a una variante compacta.

---

# 7. FILA DE RECIBO

Cada fila debe parecer un registro de negocio.

Ejemplo:

```text
┌────────────────────────────────────────────────────────────────────────────┐
│  T-000031   Sucursal Norte   15:45   🟢 Efectivo   🟢 Pagado   $2,975.00  › │
└────────────────────────────────────────────────────────────────────────────┘
```

### Folio

- semibold;
- texto principal;
- fácil de encontrar;
- nunca mezclado con la sucursal.

### Sucursal

Mostrar nombre completo hasta donde permita el ancho.

Para **Todas las sucursales**, la sucursal de cada venta es un dato importante y nunca debe ocultarse.

### Pago

Usar chips:

```text
🟢 Efectivo
🔵 Tarjeta
🟣 Mixto
```

Para mixto:

```text
🟣 Mixto
```

El detalle `ef.$X + tj.$Y` puede mostrarse en tooltip, subtítulo o detalle expandido. No saturar la columna principal.

### Estado

```text
🟢 Pagado
🟡 Parcial
🟠 Devolución
🔴 Cancelado
```

Los colores deben comunicar estado, no decorar.

### Total

Alineación derecha y peso semibold/bold.

---

# 8. DETALLE DEL RECIBO

El clic de una fila debe conservar la navegación existente hacia:

```text
/home/tickets/:id
```

No reemplazar el flujo por un modal nuevo si la aplicación actual ya tiene pantalla de ticket.

---

# 9. ESTADOS DE RECIBOS

## Loading

Usar skeletons simples con 5–8 filas.

Evitar spinner gigante en el centro de la pantalla.

## Vacío

```text
            🧾
     No hay recibos

No existen ventas en el periodo seleccionado.

         [Limpiar búsqueda]
```

El botón solo se muestra si la búsqueda realmente está filtrando.

## Error

```text
No se pudieron cargar los recibos
Verifica la conexión e inténtalo nuevamente.

[Reintentar]
```

No mostrar stack traces en la UI normal.

---

# 10. PANTALLA PRODUCTOS — REDISEÑO COMPLETO

Archivo objetivo:

```text
lib/features/home/ui/desktop/admin/admin_products_screen.dart
```

La pantalla debe funcionar como un **catálogo + inventario administrativo**.

---

## 10.1 Encabezado

```text
Productos                               [+ Producto]
Catálogo e inventario

🏢 TODAS LAS SUCURSALES · 4 activas · consolidado · Este mes
```

El botón `+ Producto` debe mantenerse visible arriba a la derecha en escritorio amplio.

---

## 10.2 Búsqueda y filtros

Usar una única barra compacta:

```text
┌────────────────────────────────────────────────────────────────────────┐
│ 🔍 Buscar producto o referencia...                     [Todos ▼]       │
└────────────────────────────────────────────────────────────────────────┘
```

El filtro `Con bajo stock` puede mantenerse como segmento/pill si la lógica actual ya existe:

```text
[Todos] [Con bajo stock]
```

No utilizar grandes rectángulos negros.

---

# 11. TABLA DE PRODUCTOS — TODAS LAS SUCURSALES

Cuando `selectedStoreId == null`, la tabla debe aprovechar el ancho para comparar sucursales.

### Desktop ancho >= 1350

```text
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│ PRODUCTO             PRECIO     CENTRO    NORTE    SUR    ORIENTE   VENDIDOS   ESTADO   ›     │
├──────────────────────────────────────────────────────────────────────────────────────────────┤
│ 🍗 Pollo Entero      $45.00       12       59      20       14         101      Normal  ›     │
│    REF PO80507621    ─────────  Stock por sucursal ───────────────                      │     │
│                                                                                                │
│ 🪽 Alas              $45.00        2       10       5        3          41      Bajo    ›     │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Orden de lectura

1. producto;
2. precio;
3. stock total / por sucursal;
4. ventas del periodo;
5. estado;
6. acción.

---

# 12. CELDA DE PRODUCTO

El producto debe tener dos líneas:

```text
[ M ]  Mollejas/Hígado
       REF PO20000822
```

La imagen debe conservar el patrón seguro actual (`Image.file`, `existsSync`, `errorBuilder`, fallback de inicial).

No volver a utilizar tiles rojos ante rutas inválidas.

---

# 13. STOCK POR SUCURSAL

Esta es una de las partes más importantes del nuevo diseño.

Para **Todas las sucursales**, cada stock debe verse como una celda compacta:

```text
Centro     54
Norte      26
Sur        18
Oriente    30
```

O en ancho mayor:

```text
CTR 54   NOR 26   SUR 18   ORI 30
```

Usar siempre una etiqueta de sucursal suficientemente clara para evitar confusiones.

### Estado de stock

Normal:

```text
54
```

Bajo:

```text
⚠ 3
```

Crítico:

```text
⚠ 0
```

Los criterios siguen siendo los actuales; el rediseño no redefine `lowStockAlertQuantity`.

---

# 14. UNA SOLA SUCURSAL

Cuando se selecciona una sucursal, simplificar la tabla.

Ejemplo:

```text
┌───────────────────────────────────────────────────────────────────────────────┐
│ PRODUCTO                 PRECIO      STOCK       VENDIDOS      ESTADO          │
├───────────────────────────────────────────────────────────────────────────────┤
│ 🍗 Pollo Entero         $45.00       59             101        ● Normal    ›   │
│ 🪽 Alas                 $45.00        3              41        ⚠ Bajo      ›   │
└───────────────────────────────────────────────────────────────────────────────┘
```

No mostrar cuatro columnas de sucursales cuando el usuario ya eligió una.

---

# 15. PANEL EXPANDIBLE DE PRODUCTO

El clic sobre una fila puede abrir detalle inline si es compatible con la implementación existente.

Ejemplo:

```text
Pollo Entero                                      $45.00
REF PO80507621

Stock por sucursal
────────────────────────────────────────
Centro                 12
Norte                   59
Sur                     20
Oriente                 14

Vendidos este mes     101 unidades

[Editar producto]
```

Esto debe ser opcional. La acción principal actual `'/home/products/edit'` debe conservarse.

---

# 16. ACCIONES

Las acciones principales no deben estar escondidas dentro de filas si se utilizan con frecuencia.

### Principal

```text
+ Producto
```

### Secundarias

- editar;
- abrir detalle;
- cualquier acción ya existente.

No crear acciones nuevas que la lógica actual no soporte.

---

# 17. RESPONSIVE REAL PARA WINDOWS

## >= 1400 px

Tabla completa.

Mostrar todas las columnas de sucursales relevantes.

## 1200–1399 px

Reducir espacios y abreviar algunas etiquetas de sucursal.

## 950–1199 px

Ocultar columnas secundarias y mover información complementaria a segunda línea.

## < 950 px

Cambiar de tabla completa a lista administrativa de tarjetas compactas.

Ejemplo:

```text
┌─────────────────────────────────────────────┐
│ 🍗 Pollo Entero                 $45.00       │
│ REF PO80507621                              │
│                                             │
│ Stock total   105      Vendidos     101     │
│ Centro 12 · Norte 59 · Sur 20 · Ori 14     │
│                                             │
│ 🟢 Normal                            ›       │
└─────────────────────────────────────────────┘
```

No hacer `Wrap` indiscriminado que vuelva a romper la lectura.

---

# 18. ESPACIADO GLOBAL

Usar una escala coherente:

```text
4   micro
8   elementos relacionados
12  controles
16  padding interno
20  separación de bloques
24  separación de secciones
32  separación mayor
```

El problema actual no debe resolverse agregando enormes espacios verticales.

El objetivo es que el contenido respire **sin desperdiciar el área útil**.

---

# 19. REGLAS DE TIPOGRAFÍA

### Título de página

`28–32 px`, peso `700`.

### Subtítulo

`14–16 px`, color secundario.

### Cabecera tabla

`11–12 px`, semibold.

### Datos principales

`14–15 px`.

### Metadatos

`12–13 px`.

### Importes

`14–16 px`, semibold/bold.

No mezclar más de 4 tamaños distintos dentro de una fila.

---

# 20. COLORES DE ESTADO

Mantener semántica consistente:

| Estado | Color visual | Uso |
|---|---|---|
| Normal / Pagado | verde | estado correcto |
| Parcial | ámbar | pendiente/parcial |
| Mixto | azul/violeta | tipo de pago |
| Devolución | naranja | devolución |
| Cancelado | rojo | cancelación |
| Bajo stock | rojo/ámbar | alerta de inventario |
| Información | azul | contexto de sucursal/filtro |

Los colores no deben utilizarse como decoración gratuita.

---

# 21. CORRECCIÓN ESPECÍFICA DE LOS PROBLEMAS VISIBLES EN LAS CAPTURAS

## Problema A — encabezados concatenados

Incorrecto:

```text
FOLIOSUCURSALHORAPAGOESTADOTOTAL
```

Correcto:

```text
FOLIO      SUCURSAL       HORA     PAGO       ESTADO      TOTAL
```

Implementar columnas reales.

---

## Problema B — filas con elementos pegados

Incorrecto:

```text
T-000031Sucursal principal15:45EfectivoPagado$2,975
```

Correcto:

```text
T-000031   Sucursal principal   15:45   Efectivo   Pagado   $2,975.00
```

---

## Problema C — demasiada área vacía

La tabla debe utilizar el ancho útil del contenido.

No centrar toda la tabla dentro de un espacio enorme dejando grandes márgenes laterales.

Usar `crossAxisAlignment: stretch` y columnas flexibles.

---

## Problema D — buscador demasiado oscuro

Eliminar el bloque negro fijo.

Usar input blanco o `surfaceContainer` del tema.

---

## Problema E — contexto multi-sucursal insuficiente

Cuando sea **Todas las sucursales**, la columna `Sucursal` es obligatoria.

No ocultarla.

Cuando una sucursal está seleccionada, se puede reducir visualmente porque el contexto ya vive en el topbar.

---

## Problema F — demasiada información en una sola línea del producto

Separar:

```text
Producto + referencia

Precio | stock | vendidos | estado
```

La referencia siempre debe ser un metadato secundario.

---

# 22. ARQUITECTURA DE WIDGETS SUGERIDA

No es obligatorio copiar exactamente estos nombres si el proyecto ya posee convenciones diferentes.

```text
lib/features/home/ui/desktop/admin/
├── admin_receipts_screen.dart
├── admin_products_screen.dart
└── widgets/
    ├── admin_data_table.dart
    ├── admin_search_bar.dart
    ├── admin_context_banner.dart
    ├── admin_status_chip.dart
    ├── admin_payment_chip.dart
    ├── admin_empty_state.dart
    ├── admin_loading_table.dart
    └── admin_section_header.dart
```

Objetivo: que Recibos y Productos compartan componentes visuales y no evolucionen de manera divergente.

---

# 23. REGLAS DE IMPLEMENTACIÓN EN FLUTTER

## No hacer

```dart
Row(
  children: [
    Text(folio),
    Text(store),
    Text(time),
    Text(payment),
    Text(status),
    Text(total),
  ],
)
```

cuando los elementos no tienen restricciones de ancho.

## Preferir

```dart
Row(
  children: [
    SizedBox(width: 130, child: ...),
    Expanded(flex: 2, child: ...),
    SizedBox(width: 120, child: ...),
    SizedBox(width: 140, child: ...),
    SizedBox(width: 130, child: ...),
    SizedBox(width: 130, child: ...),
  ],
)
```

adaptándolo al contenido real.

También puede utilizarse `DataTable`/`PaginatedDataTable` si encaja con el comportamiento existente, pero **no sacrificar el diseño ni introducir paginación que cambie silenciosamente la semántica actual**.

---

# 24. COMPORTAMIENTO MULTI-SUCURSAL

## Todas

Debe ser evidente:

```text
TODAS LAS SUCURSALES · 4 activas · consolidado
```

Y cada fila debe indicar su sucursal.

## Una sucursal

Debe ser evidente:

```text
SUCURSAL NORTE
```

Y no es necesario repetir el nombre en cada fila si el layout usa el espacio para otras métricas.

## Cambio de sucursal

Al cambiar `AdminScope`:

- mantener la sección actual;
- actualizar inmediatamente el banner/contexto;
- recargar datos respetando la lógica actual;
- no conservar filas de la sucursal anterior;
- no mostrar datos stale;
- no resetear fecha.

---

# 25. RENDIMIENTO

El rediseño no debe aumentar innecesariamente consultas a Firestore.

Mantener los límites actuales documentados.

No hacer una consulta por cada fila de la tabla si los datos ya están disponibles en el estado actual.

Para stocks por sucursal, conservar el patrón existente por-ruta y límites ya documentados.

Evitar `FutureBuilder` anidados por fila si pueden consolidarse los datos previamente.

---

# 26. ACCESIBILIDAD Y ESCRITORIO

- targets de clic >= `40 px`;
- tooltips para iconos sin texto;
- contraste suficiente;
- foco de teclado visible;
- `Enter` abre registro seleccionado;
- `Esc` cierra menús/overlays existentes;
- texto truncado con `ellipsis`, nunca overflow.

---

# 27. CRITERIOS DE ACEPTACIÓN — RECIBOS

La implementación está terminada cuando:

1. Los encabezados están separados visualmente.
2. Ninguna columna se concatena.
3. Folio, sucursal, hora, pago, estado y total son identificables en menos de un segundo de lectura visual.
4. En `Todas las sucursales`, cada ticket muestra claramente su sucursal.
5. `Mixto` nunca aparece como `Efectivo`.
6. Los estados conservan la semántica actual.
7. El clic sigue llevando al ticket existente.
8. La búsqueda conserva el comportamiento funcional existente.
9. Loading/vacío/error tienen estados visuales profesionales.
10. No aparecen datos de otra sucursal después de cambiar el selector.

---

# 28. CRITERIOS DE ACEPTACIÓN — PRODUCTOS

1. Producto y referencia están claramente separados.
2. Precio, stock y vendidos son columnas independientes.
3. En Todas las sucursales se pueden comparar stocks por sucursal.
4. En sucursal única se simplifican las columnas.
5. Bajo stock se identifica claramente.
6. La imagen rota nunca produce un tile rojo de error.
7. `+ Producto` conserva la ruta actual.
8. Editar conserva `/home/products/edit`.
9. La búsqueda y el filtro de bajo stock siguen funcionando.
10. Los datos continúan viniendo de Firestore y de los repositorios actuales.

---

# 29. PROMPT MAESTRO PARA EL AGENTE DE PROGRAMACIÓN

Copia este bloque como instrucción para el agente:

```text
CONTEXTO
Estoy trabajando en un POS administrativo Windows desarrollado en Flutter + Firebase.
Necesito corregir específicamente la presentación visual de las vistas Recibos y Productos.

PROBLEMA OBSERVADO
La funcionalidad existe, pero las tablas están mal compuestas visualmente: los encabezados y datos aparecen concatenados, las columnas pierden alineación, existe demasiado espacio vacío y la información de múltiples sucursales no se escanea con facilidad.

OBJETIVO
Transforma Recibos y Productos en vistas administrativas profesionales de escritorio, con tablas reales, columnas controladas, jerarquía visual clara, búsqueda compacta, estados mediante chips y contexto multi-sucursal siempre visible.

REGLA CERO — NO ROMPAS LA LÓGICA
Antes de editar, lee completamente:
- lib/features/home/ui/desktop/admin/admin_filters.dart
- lib/features/home/ui/desktop/admin/admin_shell.dart
- lib/features/home/ui/desktop/admin/admin_topbar.dart
- lib/features/home/ui/desktop/admin/admin_navigation.dart
- lib/features/home/ui/desktop/admin/admin_receipts_screen.dart
- lib/features/home/ui/desktop/admin/admin_products_screen.dart
- lib/features/home/ui/back_office_screen.dart
- modelos Sale, Product y ProductStock
- repositorios utilizados por Recibos y Productos

No cambies la lógica de AdminScope, Firestore, filtros, split, devoluciones, cancelaciones ni stock por sucursal.

METODOLOGÍA
FASE 1 — AUDITORÍA
1. Lee los archivos reales.
2. Identifica cómo se construyen actualmente las filas y encabezados.
3. Identifica qué widgets provocan el overflow/concatenación.
4. Identifica datos disponibles para cada columna.
5. No asumas nombres de campos que no existan.

FASE 2 — COMPONENTES
Crea componentes reutilizables solamente donde tenga sentido:
- AdminDataTable
- AdminSearchBar
- AdminStatusChip
- AdminPaymentChip
- AdminContextBanner
- AdminEmptyState
- AdminLoadingTable

No dupliques estilos entre Recibos y Productos.

FASE 3 — RECIBOS
Implementa una tabla con columnas independientes:
- Folio
- Sucursal
- Fecha/hora
- Pago
- Estado
- Total
- Acción

En Todas las sucursales, Sucursal es obligatoria.
En una sucursal, puede reducirse visualmente.

FASE 4 — PRODUCTOS
Implementa:
- Producto + referencia
- Precio
- Stock por sucursal cuando Todas
- Stock total cuando sucursal única
- Vendidos en periodo
- Estado
- Acción

No juntes todos los valores en un solo Text.

FASE 5 — RESPONSIVE
Usa LayoutBuilder/breakpoints.
No permitas que las columnas se colapsen hasta formar texto concatenado.
Para anchos pequeños cambia a una tarjeta/lista compacta.

FASE 6 — VALIDACIÓN
Después de implementar:
1. dart analyze
2. flutter build windows --release
3. revisa errores de overflow
4. revisa estados vacíos
5. prueba Todas las sucursales
6. prueba una sucursal
7. cambia Hoy/Ayer/Semana/Mes
8. verifica que no quede información stale
9. verifica split, devolución y cancelado
10. verifica Productos y stock por sucursal

DISEÑO
Usa fondo claro, cards blancas, bordes suaves, radio 16–20, sombras mínimas, acento naranja del negocio, azul suave para contexto multi-sucursal y colores semánticos para estados.

IMPORTANTE
No hagas un rediseño genérico de todo el proyecto.
Prioriza exclusivamente Recibos + Productos + componentes visuales compartidos necesarios.
No cambies Android.
No reemplaces repositorios.
No agregues mocks.
No inventes datos.
No alteres rutas existentes.

ENTREGABLE
Al finalizar proporciona:
- archivos modificados;
- widgets nuevos;
- problemas visuales solucionados;
- comandos de validación ejecutados;
- cualquier limitación real encontrada.
```

---

# 30. RESULTADO VISUAL ESPERADO

## Recibos

```text
Recibos
Historial de ventas

┌──────────────────────────────────────────────────────────────────────────────┐
│ 🏢 TODAS LAS SUCURSALES · 4 activas · consolidado · Este mes               │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│ 🔍 Buscar por folio, cliente o importe...                    [Filtros]       │
└──────────────────────────────────────────────────────────────────────────────┘

01 OCT 2026                                                     5 recibos

┌───────┬─────────────────┬────────────────┬───────────┬──────────┬──────────┐
│ Folio │ Sucursal        │ Fecha/hora     │ Pago      │ Estado   │ Total    │
├───────┼─────────────────┼────────────────┼───────────┼──────────┼──────────┤
│T-00031│ Centro          │01/10 · 15:45   │ Efectivo  │ Pagado   │$2,975.00 │
│D-00012│ Norte           │01/10 · 15:43   │ Efectivo  │ Devol.   │  $940.00 │
│T-00030│ Centro          │01/10 · 15:43   │ Tarjeta   │ Pagado   │  $400.40 │
│T-00029│ Sur             │01/10 · 15:42   │ Tarjeta   │ Pagado   │   $90.00 │
│T-00028│ Oriente         │01/10 · 15:41   │ Mixto     │ Parcial  │$3,760.00 │
└───────┴─────────────────┴────────────────┴───────────┴──────────┴──────────┘
```

## Productos

```text
Productos                                      [+ Producto]
Catálogo e inventario

┌──────────────────────────────────────────────────────────────────────────────┐
│ 🏢 TODAS LAS SUCURSALES · 4 activas · consolidado · Este mes               │
└──────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│ 🔍 Buscar producto o referencia...                     [Todos] [Bajo stock] │
└──────────────────────────────────────────────────────────────────────────────┘

┌───────────────────┬────────┬────────┬────────┬────────┬─────────┬──────────┐
│ Producto          │ Precio │ Centro │ Norte  │ Sur    │ Vendidos│ Estado   │
├───────────────────┼────────┼────────┼────────┼────────┼─────────┼──────────┤
│ 🍗 Pollo Entero   │ $45.00 │   12   │   59   │   20   │   101   │ 🟢 Normal│
│    REF PO80507621 │        │        │        │        │         │          │
├───────────────────┼────────┼────────┼────────┼────────┼─────────┼──────────┤
│ 🪽 Alas           │ $45.00 │    2   │   10   │    5   │    41   │ ⚠ Bajo  │
│    REF PO19998958 │        │        │        │        │         │          │
└───────────────────┴────────┴────────┴────────┴────────┴─────────┴──────────┘
```

---

# 31. DEFINICIÓN DE TERMINADO

El trabajo se considera terminado cuando las capturas de Windows ya no presentan:

- encabezados concatenados;
- columnas que chocan entre sí;
- texto pegado;
- tarjetas gigantes con poca información;
- búsqueda oscura dominante;
- falta de contexto de sucursal;
- stock imposible de comparar.

Y cuando el usuario puede contestar visualmente, sin entrar a otra pantalla:

> **¿Qué venta fue, en qué sucursal ocurrió, cómo se pagó, cuál es su estado y cuánto fue?**

y para productos:

> **¿Qué producto es, cuánto cuesta, cuánto stock tiene en cada sucursal, cuánto se vendió y si necesita atención?**

Ese es el objetivo principal de este rediseño.
