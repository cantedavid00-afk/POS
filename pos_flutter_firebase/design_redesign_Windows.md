# Dashboard Windows (.exe) — Rediseño visual y UX para administración multi-sucursal

> **Proyecto:** `pos_flutter_firebase`  
> **Plataforma:** Windows `.exe` (Flutter Desktop)  
> **Rol objetivo:** Administrador / dueño  
> **Objetivo de este documento:** rediseñar completamente la interfaz visual del módulo administrativo para que sea limpia, moderna, ordenada y especialmente clara al trabajar con **múltiples sucursales**, sin modificar la lógica de negocio existente.

---

## 0. Regla principal: rediseñar la interfaz, no romper el sistema

Este documento es una **especificación de UI/UX y arquitectura visual**.

La implementación debe conservar la lógica actualmente documentada en el proyecto:

- `AdminScope` sigue siendo la única fuente global para sucursal y rango de fechas.
- `selectedStoreId == null` significa **Todas las sucursales**.
- Las consultas de Firestore siguen siendo acotadas con `.limit(...)`.
- El stock por sucursal continúa proveniendo exclusivamente de `stockByStore/{storeId}`.
- Los pagos `split` continúan separándose en efectivo/tarjeta.
- Las devoluciones y cancelados conservan exactamente las reglas actuales.
- No se deben introducir mocks, datos ficticios, porcentajes inventados ni métricas simuladas.
- No se debe cambiar el comportamiento del flujo móvil Android.
- No se deben eliminar funcionalidades existentes solamente para simplificar el diseño.

**Prioridad:** primero mantener comportamiento y datos correctos; después mejorar presentación, jerarquía y navegación.

---

# 1. Objetivo visual

La interfaz actual utiliza demasiados bloques oscuros, espacios vacíos y secciones que no tienen una jerarquía clara. El nuevo diseño debe parecer un **panel administrativo profesional de escritorio**, inspirado en dashboards modernos de SaaS/ERP/POS.

### Características visuales requeridas

1. Fondo general claro y muy suave.
2. Tarjetas blancas con bordes redondeados.
3. Sombras muy ligeras, nunca pesadas.
4. Mucho espacio interno y separación consistente.
5. Tipografía limpia y legible.
6. Números monetarios grandes y fáciles de localizar.
7. Colores únicamente cuando comuniquen información.
8. Navegación lateral estable.
9. Filtros globales siempre visibles.
10. La sucursal seleccionada debe ser imposible de confundir.
11. La vista **Todas las sucursales** debe sentirse como una vista de consolidación real, no como una sucursal más.
12. Tablas y gráficas deben ocupar el espacio disponible de manera equilibrada.

---

# 2. Dirección de diseño

## 2.1 Tema principal

Usar como base un tema claro.

### Paleta propuesta

| Elemento | Color sugerido |
|---|---|
| Fondo aplicación | `#F5F6FA` |
| Superficie/card | `#FFFFFF` |
| Texto principal | `#171923` |
| Texto secundario | `#6B7280` |
| Bordes | `#E7E9EF` |
| Acento negocio | `#FF6B00` |
| Acento suave | `#FFF1E8` |
| Éxito | `#22A06B` |
| Fondo éxito | `#E9F8F0` |
| Advertencia | `#D99A00` |
| Fondo advertencia | `#FFF7DD` |
| Error | `#D64545` |
| Fondo error | `#FDECEC` |
| Información | `#3B82F6` |
| Fondo información | `#EDF4FF` |

> Estos valores son la dirección visual. Deben centralizarse en el tema de Flutter y no escribirse directamente en cada widget.

### Bordes y radios

- Card principal: `20–24 px`.
- Card secundaria: `16–20 px`.
- Botones: `10–12 px`.
- Chips: `999 px`.
- Inputs: `12 px`.
- Separación estándar: `8 / 12 / 16 / 24 / 32 px`.

### Sombra

Usar una sola sombra muy tenue para elevar tarjetas sobre el fondo.

Evitar:

- sombras negras fuertes;
- glow;
- gradientes innecesarios;
- tarjetas con múltiples bordes;
- decoración que no aporte información.

---

# 3. Nueva estructura general de la ventana

La ventana debe adoptar esta estructura:

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│ Logo / negocio              Búsqueda       Notificaciones   Usuario         │
├───────────────┬──────────────────────────────────────────────────────────────┤
│               │                                                              │
│ Dashboard     │  Breadcrumb / título                                        │
│               │                                                              │
│ Recibos       │  ┌────────────────────────────────────────────────────────┐  │
│               │  │ Filtros globales                                      │  │
│ Productos     │  │ [Todas las sucursales ▼] [Hoy] [Ayer] [Semana] [Mes]│  │
│               │  └────────────────────────────────────────────────────────┘  │
│ Recibir pollo │                                                              │
│               │  Contenido                                                   │
│ Back Office   │                                                              │
│               │                                                              │
│               │                                                              │
│ Usuario       │                                                              │
└───────────────┴──────────────────────────────────────────────────────────────┘
```

La navegación lateral no debe desaparecer al cambiar de pantalla.

El área de contenido debe desplazarse independientemente de la navegación.

---

# 4. Sidebar / navegación lateral

## 4.1 Diseño

Ancho expandido recomendado: `240–260 px`.

Ancho compacto: `76–84 px`.

Fondo: blanco o ligeramente separado del fondo general.

La navegación debe utilizar íconos + etiquetas horizontales.

```text
┌─────────────────────────┐
│ 🟠  PV Donald           │
│     Administrador       │
├─────────────────────────┤
│                         │
│ ▣  Dashboard            │
│                         │
│ ▤  Recibos              │
│                         │
│ ▣  Productos            │
│                         │
│ 🐔  Recibir pollo       │
│                         │
│ ⚙  Back Office          │
│                         │
├─────────────────────────┤
│                         │
│ M                       │
│ Administrador           │
│ negocio@correo.com      │
└─────────────────────────┘
```

## 4.2 Item seleccionado

El item activo debe usar:

- fondo `#FFF1E8`;
- texto/acento `#FF6B00`;
- icono del mismo color;
- radio aproximado de `12 px`;
- transición corta.

No utilizar barras laterales gruesas para indicar selección.

## 4.3 Hover

Hover muy suave sobre el fondo del item.

No cambiar tamaños, alturas ni desplazar elementos al pasar el mouse.

---

# 5. Topbar global

La barra superior debe resolver visualmente el mayor problema del sistema actual: **saber en qué contexto administrativo estoy**.

Debe contener siempre:

```text
Dashboard

[Todas las sucursales ▼]     [Hoy ▼]     [Administrador ▼]   [↻] [Salir]
```

## 5.1 Selector de sucursal

Debe ser el control más visible de la barra.

### Cuando está seleccionada una sucursal

```text
🏪  Sucursal Centro                 ▼
```

### Cuando están seleccionadas todas

```text
🏪  Todas las sucursales            ▼
```

Al abrir:

```text
┌─────────────────────────────────┐
│ Seleccionar sucursal            │
├─────────────────────────────────┤
│ ✓  Todas las sucursales         │
│                                  │
│    Centro                        │
│    Norte                         │
│    Sur                           │
│    Oriente                       │
└─────────────────────────────────┘
```

La opción seleccionada debe tener check visible.

La etiqueta **Todas las sucursales** debe diferenciarse visualmente de una sucursal individual.

---

# 6. Encabezado de cada pantalla

Cada sección debe empezar con una cabecera consistente.

Ejemplo:

```text
Dashboard
Resumen general del negocio

Todas las sucursales  •  Hoy
```

No repetir en cada tarjeta textos como:

- “Sucursal filtrada”;
- “Periodo seleccionado”;
- “Datos actuales”;

cuando esa información ya está claramente visible arriba.

---

# 7. Dashboard principal — nuevo layout

El dashboard debe ser completamente rediseñado.

La información debe seguir esta jerarquía:

1. Contexto actual.
2. KPIs principales.
3. Comparación de sucursales.
4. Ventas y pagos.
5. Productos más vendidos.
6. Stock.
7. Información secundaria.

## 7.1 Nueva distribución

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│ Dashboard                                                                   │
│ Resumen general del negocio                                                 │
│                                                                              │
│ [ 🏪 Todas las sucursales ▼ ]   [ Hoy ] [ Ayer ] [ Semana ] [ Mes ]        │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌────────────────┐
│ Ventas netas    │ │ Ventas brutas   │ │ Devoluciones    │ │ Tickets        │
│                 │ │                 │ │                 │ │                │
│ $12,345         │ │ $13,200         │ │ $855            │ │ 128            │
│ ↗ periodo       │ │ ↗ periodo       │ │ ↘ periodo       │ │ ↗ periodo      │
└─────────────────┘ └─────────────────┘ └─────────────────┘ └────────────────┘

┌──────────────────────────────────────────────┐ ┌────────────────────────────┐
│ Ventas por sucursal                          │ │ Métodos de pago            │
│                                              │ │                            │
│ Centro    ███████████████ $6,200            │ │          ███████           │
│ Norte     █████████ $3,840                   │ │        efectivo            │
│ Sur       ██████ $2,305                      │ │      tarjeta               │
│                                              │ │                            │
└──────────────────────────────────────────────┘ └────────────────────────────┘

┌──────────────────────────────────────────────┐ ┌────────────────────────────┐
│ Productos más vendidos                       │ │ Resumen del periodo        │
│                                              │ │                            │
│ 1. Pollo entero          120 uds            │ │ Ticket promedio             │
│ 2. Pierna                  86 uds             │ │ $354                        │
│ 3. Pechuga                 72 uds             │ │                            │
│ 4. Alitas                  59 uds             │ │ Descuentos                  │
│                                              │ │ $430                        │
└──────────────────────────────────────────────┘ └────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│ Inventario por sucursal                                        [Expandir]    │
│                                                                              │
│ Producto           Centro     Norte      Sur       Total       Estado       │
│ ─────────────────────────────────────────────────────────────────────────── │
│ Pollo entero       24         12         8         44          Normal       │
│ Pierna             5          4          2         11          Bajo         │
│ Pechuga            0          3          1         4           Crítico      │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

# 8. KPIs

Actualmente hay demasiadas métricas pequeñas agrupadas sin jerarquía.

El nuevo diseño debe utilizar **4 KPIs principales** y dejar métricas secundarias en otra tarjeta.

## KPIs principales

1. **Ventas netas**
2. **Ventas brutas**
3. **Devoluciones**
4. **Tickets**

## Secundarios

- Ticket promedio.
- Descuentos.
- Efectivo.
- Tarjeta.

### Diseño de KPI

Cada KPI debe incluir:

```text
[icono]
Etiqueta

$12,345

↑ 20%   vs periodo anterior
```

### Importante

Los porcentajes de variación **solo deben mostrarse si pueden calcularse con datos reales**.

Si no se cuenta con comparación válida, no mostrar un porcentaje inventado.

---

# 9. Multi-sucursal — componente central del rediseño

Esta es la parte más importante.

Cuando `AdminScope.isAllStores == true`, el usuario no debe interpretar el dashboard como si estuviera viendo una sucursal individual.

## 9.1 Banda de contexto

Debajo del encabezado mostrar:

```text
TODAS LAS SUCURSALES
4 sucursales activas · consolidado del negocio
```

Cuando se selecciona una sola:

```text
SUCURSAL CENTRO
Vista individual de la sucursal
```

Usar un chip o badge claramente identificable.

---

# 10. Tarjeta “Ventas por sucursal”

En modo **Todas** debe ser una de las tarjetas protagonistas del dashboard.

Debe responder rápidamente:

> ¿Qué sucursales están generando ventas durante el periodo?

### Diseño recomendado

Usar barras horizontales o verticales, pero con etiquetas legibles.

Ejemplo:

```text
Ventas por sucursal

Centro       ████████████████████  $6,200
Norte        █████████████         $4,050
Sur          ████████              $2,440
Oriente      ████                  $1,180
```

Mostrar hasta 8 sucursales.

Si existen más:

```text
Mostrando 8 de 12 sucursales
Ver todas
```

Nunca truncar silenciosamente sucursales importantes.

---

# 11. Resumen de sucursales

Agregar una tarjeta complementaria visible únicamente en modo **Todas las sucursales**.

```text
Resumen de sucursales

┌──────────────┬───────────┬───────────┬──────────┐
│ Sucursal     │ Ventas    │ Tickets   │ Stock    │
├──────────────┼───────────┼───────────┼──────────┤
│ Centro       │ $6,200    │ 52        │ Normal   │
│ Norte        │ $4,050    │ 38        │ Bajo     │
│ Sur          │ $2,440    │ 27        │ Normal   │
│ Oriente      │ $1,180    │ 11        │ Crítico  │
└──────────────┴───────────┴───────────┴──────────┘
```

Esta tabla debe utilizar datos reales ya existentes.

No crear nuevas consultas costosas cuando los datos necesarios ya fueron cargados por el dashboard.

---

# 12. Selección de sucursal y efecto visual

Cuando el usuario cambia:

```text
Todas las sucursales → Centro
```

debe ocurrir todo lo siguiente sin navegar a otra pantalla:

- KPIs se actualizan.
- Gráficas se actualizan.
- Productos vendidos se actualizan.
- Stock cambia al contexto de Centro.
- Recibos y demás pantallas mantienen el mismo contexto.

Debe existir una transición corta para evitar sensación de parpadeo.

No resetear la fecha seleccionada.

### Regla

```text
Sucursal + Fecha = contexto administrativo persistente
```

---

# 13. Métodos de pago

La tarjeta de pagos debe ser más compacta que “Ventas por sucursal”.

Mostrar:

```text
Métodos de pago

      ┌────────────┐
      │    62%     │
      │  Efectivo  │
      └────────────┘

Efectivo       $7,842
Tarjeta        $4,503

Mixto:
se reparte entre efectivo y tarjeta
```

No crear un tercer segmento de pastel para `split`.

`split` debe seguir repartido según:

- `cashAmount`;
- `cardAmount`.

---

# 14. Productos más vendidos

La tarjeta debe priorizar lectura rápida.

```text
Productos más vendidos

01   Pollo entero              120 uds    $4,800
     ███████████████████████

02   Pierna                     86 uds    $2,580
     █████████████████

03   Pechuga                    72 uds    $2,160
     ██████████████
```

No utilizar gráficas complejas cuando una lista con barra de progreso sea más legible.

---

# 15. Inventario multi-sucursal

Esta sección debe ser una de las más útiles del sistema.

## Vista compacta

```text
Inventario por sucursal                         [Expandir]

Producto             Centro    Norte    Sur     Total   Estado
Pollo entero            24       12      8       44     Normal
Pierna                   5        4      2       11     Bajo
Pechuga                  0        3      1        4     Crítico
```

## Vista expandida

Al pulsar `Expandir`:

- aumentar altura de la tarjeta;
- mantener al usuario en la misma pantalla;
- mostrar más productos;
- habilitar desplazamiento interno si es necesario;
- conservar la posición del dashboard tanto como sea razonablemente posible.

No abrir una ventana nueva.

---

# 16. Estados de inventario

Usar badges suaves.

```text
Normal       [● Normal]
Bajo         [● Bajo]
Crítico      [● Crítico]
```

No colorear toda una fila.

El color debe concentrarse en el estado.

### Regla existente

Mantener:

```dart
isLow = total <= lowStockAlertQuantity
```

con la regla actual para alerta `<= 0`.

No cambiar esta lógica durante el rediseño.

---

# 17. Recibos — nuevo diseño

La pantalla de recibos debe parecer una tabla administrativa profesional.

```text
Recibos
Historial de ventas

[Todas las sucursales ▼]   [Hoy ▼]           Buscar folio / cliente...

┌──────────┬──────────┬────────────┬────────────┬────────────┬──────────┐
│ Folio    │ Sucursal │ Fecha      │ Pago       │ Estado     │ Total    │
├──────────┼──────────┼────────────┼────────────┼────────────┼──────────┤
│ #INV...  │ Centro   │ 20/11 10:32│ Efectivo   │ Entregado  │ $354     │
│ #INV...  │ Norte    │ 20/11 10:16│ Mixto       │ Entregado  │ $490     │
│ #INV...  │ Sur      │ 20/11 09:43│ Tarjeta    │ Cancelado  │ $210     │
└──────────┴──────────┴────────────┴────────────┴────────────┴──────────┘
```

### En modo Todas

La columna **Sucursal** es obligatoria.

### En modo una sucursal

Puede seguir mostrándose para facilitar contexto, pero puede tener menos prominencia.

---

# 18. Productos — nuevo diseño

Debe dejar de parecer una cuadrícula móvil ampliada.

Usar una vista híbrida:

- buscador;
- filtros;
- tabla/lista administrativa;
- miniatura segura;
- stock;
- vendidos en periodo;
- precio.

Ejemplo:

```text
Productos                           [+ Producto]

[Buscar producto...]   [Activos]   [Con bajo stock]

┌────────────┬──────────┬───────────────┬────────┬───────────┐
│ Producto   │ Precio   │ Stock         │ Vendido│ Estado    │
├────────────┼──────────┼───────────────┼────────┼───────────┤
│ [img] Pollo│ $120.00  │ 44 total      │ 120    │ Normal    │
│ [img] Pierna│ $30.00  │ 11 total      │ 86     │ Bajo      │
└────────────┴──────────┴───────────────┴────────┴───────────┘
```

En modo Todas, al expandir el producto puede mostrarse:

```text
Centro 24 · Norte 12 · Sur 8
```

---

# 19. Recibir pollo — nuevo diseño

La pantalla debe priorizar la tarea de captura.

```text
Recibir pollo
Registrar entrada de pollo

┌───────────────────────────────────────────────┐
│ Sucursal destino                              │
│ [ Centro ▼ ]                                  │
│                                               │
│ Cantidad de pollos                            │
│ [ 120 ]                                       │
│                                               │
│ Peso total (kg)                               │
│ [ 185.50 ]                                    │
│                                               │
│ Peso promedio                                 │
│ 1.55 kg                                      │
│                                               │
│                [ Registrar recepción ]       │
└───────────────────────────────────────────────┘

Recepciones recientes
```

Cuando el scope está en Todas:

```text
Todas las sucursales

Para registrar una recepción debes seleccionar una sucursal.

[Seleccionar sucursal]
```

**No seleccionar silenciosamente la primera sucursal.**

La lógica de negocio existente puede conservarse, pero la UX objetivo debe hacer explícito el destino para evitar errores humanos.

---

# 20. Back Office

No convertir Back Office en otro dashboard independiente.

Debe utilizar el mismo lenguaje visual:

- fondo;
- tarjetas;
- tabla;
- filtros;
- badges;
- títulos;
- botones;
- espaciado.

El filtro de sucursal superior debe mantenerse.

Preferentemente sincronizar filtros internos con `AdminScope` en una fase posterior, sin duplicar fuentes de verdad.

---

# 21. Loading, errores y estados vacíos

## Loading

Usar skeletons, no spinners gigantes.

Ejemplo:

```text
┌──────────────────────┐
│ █████████             │
│                      │
│ ████████████████      │
│ █████████             │
└──────────────────────┘
```

## Vacío

Mensaje claro:

```text
No hay ventas en este periodo

Prueba otro rango de fechas o selecciona otra sucursal.
```

## Error

Nunca mostrar pantalla completamente vacía.

```text
No fue posible cargar esta información

[Reintentar]

Detalle técnico opcional para soporte.
```

---

# 22. Responsive Desktop

Aunque el objetivo es Windows, la ventana debe comportarse bien en distintos tamaños.

### ≥ 1400 px

- Sidebar expandido.
- Dashboard de 2 columnas.
- KPIs en 4 columnas.
- Tabla de stock completa.

### 1100–1399 px

- Sidebar expandido o compacto según espacio.
- Dashboard de 2 columnas.
- KPIs en 2×2 si es necesario.

### 900–1099 px

- Sidebar compacto.
- Tarjetas principalmente apiladas.
- Topbar puede hacer wrap controlado.

### < 900 px

No diseñar una experiencia móvil nueva en este módulo; mantener una versión desktop compacta evitando overflow horizontal.

---

# 23. Componentes Flutter recomendados

Crear componentes reutilizables antes de rediseñar cada pantalla por separado.

```text
lib/features/home/ui/desktop/admin/

├── admin_theme_tokens.dart
├── admin_shell.dart
├── admin_topbar.dart
├── admin_navigation.dart
├── admin_scope_banner.dart
├── widgets/
│   ├── admin_card.dart
│   ├── admin_kpi_card.dart
│   ├── admin_section_header.dart
│   ├── admin_status_badge.dart
│   ├── admin_store_selector.dart
│   ├── admin_date_selector.dart
│   ├── admin_empty_state.dart
│   ├── admin_error_state.dart
│   ├── admin_skeleton.dart
│   ├── admin_stat_row.dart
│   └── admin_table.dart
├── admin_dashboard_screen.dart
├── admin_receipts_screen.dart
├── admin_products_screen.dart
├── admin_poultry_screen.dart
└── ...
```

No duplicar estilos entre pantallas.

---

# 24. Arquitectura visual de cards

Crear una clase/componente base:

```dart
AdminCard(
  title: 'Ventas por sucursal',
  subtitle: 'Periodo actual',
  child: ...,
)
```

Debe controlar:

- padding;
- radius;
- border;
- sombra;
- título;
- acciones superiores;
- comportamiento responsive.

Así se consigue consistencia entre Dashboard, Recibos, Productos y Back Office.

---

# 25. Tipografía

Usar la tipografía disponible de Flutter/Windows o una fuente del proyecto ya existente.

Jerarquía sugerida:

| Uso | Tamaño aproximado | Peso |
|---|---:|---|
| Título página | 26–30 | 700 |
| Título tarjeta | 17–19 | 700 |
| KPI | 26–32 | 700 |
| Texto normal | 14–15 | 400–500 |
| Texto secundario | 12–13 | 400 |
| Badge | 11–12 | 600 |

Los importes deben utilizar cifras tabulares cuando sea posible.

---

# 26. Iconografía

Utilizar `Material Icons` o el sistema de iconos ya existente.

Los iconos deben servir para reconocimiento rápido, no decorar.

Ejemplos:

- Dashboard → `dashboard_outlined`
- Recibos → `receipt_long_outlined`
- Productos → `inventory_2_outlined`
- Pollo → `egg_alt_outlined`
- Back Office → `admin_panel_settings_outlined`
- Sucursal → `storefront_outlined`
- Todas → `domain_outlined`
- Efectivo → `payments_outlined`
- Tarjeta → `credit_card_outlined`

---

# 27. Animaciones

Usar animaciones pequeñas y funcionales:

- cambio de sección: `150–220 ms`;
- selección de sidebar: `150–180 ms`;
- expansión de inventario: `250 ms`;
- aparición de filtros/menús: `150–200 ms`.

No utilizar:

- parallax;
- rebotes excesivos;
- animaciones permanentes;
- gráficas con animación pesada que retrasen la lectura.

---

# 28. Accesibilidad y legibilidad

Debe ser posible interpretar el dashboard sin depender únicamente del color.

Por ejemplo:

```text
[● Bajo]
```

pero acompañar con texto `Bajo`.

Debe existir suficiente contraste entre:

- texto y fondo;
- controles y fondo;
- badges y texto;
- estados de error y contenido.

No utilizar texto menor a `11 px` en contenido relevante.

---

# 29. Reglas específicas para “Todas las sucursales”

Estas reglas son obligatorias.

### Dashboard

Mostrar:

- consolidado general;
- ventas por sucursal;
- resumen por sucursal;
- stock por sucursal.

### Recibos

Mostrar columna `Sucursal`.

### Productos

Mostrar stock separado por sucursal y total.

### Recibir pollo

La UI debe exigir explícitamente una sucursal destino antes de registrar una recepción.

### Back Office

Inventario en Todas = solo lectura consolidada.

Nunca permitir una operación que necesite `storeId` único mientras el contexto sea Todas.

---

# 30. Qué NO debe hacer el agente de implementación

El agente que aplique este diseño **NO DEBE**:

1. Reescribir repositorios de Firestore sin necesidad.
2. Cambiar modelos de datos por razones visuales.
3. Modificar reglas de negocio de ventas.
4. Cambiar el tratamiento de `split`.
5. Reintroducir `products/{id}.stockQuantity` como fuente de verdad.
6. Introducir mocks.
7. Crear consultas ilimitadas.
8. Duplicar `AdminScope`.
9. Crear un segundo selector global de sucursal independiente.
10. Cambiar Android.
11. Reemplazar Flutter por otra tecnología.
12. Romper rutas existentes.
13. Eliminar funciones que ya existen solamente porque no aparecen en el mockup visual.

---

# 31. Estrategia de implementación

La implementación debe realizarse en este orden.

## Fase 1 — Sistema visual

Crear:

- tokens de color;
- espaciado;
- radios;
- tipografía;
- sombras;
- `AdminCard`;
- `AdminKpiCard`;
- badges;
- estados vacío/error/loading.

## Fase 2 — Shell

Rediseñar:

- `AdminShell`;
- `AdminNavigation`;
- `AdminTopBar`;
- selector de sucursal;
- selector de fechas.

Validar que `AdminScope` continúe persistiendo.

## Fase 3 — Dashboard

Rehacer solamente el árbol visual de:

- header;
- KPIs;
- ventas por sucursal;
- métodos de pago;
- top artículos;
- resumen de sucursales;
- inventario.

La capa de obtención de datos debe mantenerse o refactorizarse únicamente si es necesario para alimentar los nuevos widgets sin duplicar consultas.

## Fase 4 — Recibos

Migrar la pantalla al nuevo lenguaje visual.

## Fase 5 — Productos

Migrar tabla/lista y filtros.

## Fase 6 — Recibir pollo

Migrar formulario e historial.

## Fase 7 — Back Office

Aplicar el mismo sistema visual sin reescribir la lógica interna.

---

# 32. Criterios de aceptación visual

La nueva interfaz se considera correcta cuando:

- al abrir Windows aparece Dashboard con `Todas las sucursales` como contexto inicial;
- el usuario identifica la sucursal y rango actual en menos de unos segundos;
- los KPIs tienen una jerarquía clara;
- las ventas por sucursal se pueden comparar sin abrir otra pantalla;
- la tabla de stock permite comparar sucursales horizontalmente;
- no existen tarjetas gigantes con espacios vacíos innecesarios;
- no existen textos rotados o ilegibles;
- no hay overflow horizontal a tamaños razonables;
- todas las pantallas comparten componentes y estilo;
- cambiar sucursal actualiza todas las vistas que dependen del scope;
- cambiar el rango mantiene la sucursal seleccionada;
- cambiar de sección mantiene el contexto global;
- no aparecen datos simulados;
- no aparecen errores rojos provocados por imágenes ausentes;
- no se rompe el flujo de logout;
- `flutter build windows --release` termina correctamente.

---

# 33. Criterios funcionales que NO deben cambiar

Debe continuar funcionando exactamente la lógica documentada del sistema actual:

```text
AdminScope
 ├── selectedStoreId
 ├── isAllStores
 └── range

Dashboard
 ├── ventas reales
 ├── pagos reales
 ├── top artículos
 └── stockByStore real

Recibos
 └── sales reales

Productos
 ├── products reales
 ├── ventas por periodo
 └── stock por sucursal

Recibir pollo
 ├── guardar recepción
 └── historial real

Back Office
 └── inventario multi-sucursal
```

El rediseño debe actuar principalmente en el **presentation layer**.

---

# 34. Prompt maestro para el agente de programación

Copiar este bloque junto con el repositorio:

```text
OBJETIVO

Rediseña la interfaz Windows del proyecto pos_flutter_firebase siguiendo exactamente el documento design_redesign.md.

IMPORTANTE:
El objetivo principal es mejorar UI/UX y organización visual. NO debes rehacer la lógica de negocio ni sustituir la arquitectura actual sin una razón técnica comprobable.

ANTES DE MODIFICAR

1. Lee completamente:
   - design_redesign.md
   - lib/features/home/ui/desktop/admin/admin_filters.dart
   - lib/features/home/ui/desktop/admin/admin_shell.dart
   - lib/features/home/ui/desktop/admin/admin_topbar.dart
   - lib/features/home/ui/desktop/admin/admin_navigation.dart
   - lib/features/home/ui/desktop/admin/admin_dashboard_screen.dart
   - lib/features/home/ui/desktop/admin/admin_receipts_screen.dart
   - lib/features/home/ui/desktop/admin/admin_products_screen.dart
   - lib/features/home/ui/desktop/admin/admin_poultry_screen.dart
   - lib/features/home/ui/back_office_screen.dart
   - modelos y repositorios utilizados por esas pantallas.

2. Identifica qué partes contienen:
   - estado;
   - consultas Firestore;
   - cálculos;
   - navegación;
   - widgets puramente visuales.

3. No cambies una función existente solo porque está visualmente acoplada a un widget.

4. Antes de crear una nueva consulta, verifica si el dato ya existe en memoria.

REDISEÑO

Implementa primero un sistema visual reutilizable:
- tokens de tema;
- AdminCard;
- AdminKpiCard;
- AdminSectionHeader;
- AdminStatusBadge;
- AdminEmptyState;
- AdminErrorState;
- AdminSkeleton;
- selector de sucursal;
- selector de fechas.

Después rediseña AdminShell, navegación y TopBar.

Después rediseña Dashboard, Recibos, Productos, Recibir pollo y Back Office.

MULTI-SUCURSAL

La experiencia de Todas las sucursales es prioritaria.

selectedStoreId == null significa TODAS.
No inventes un nuevo estado global.
No dupliques AdminScope.

En modo Todas:
- Dashboard debe mostrar consolidado + comparación por sucursal.
- Recibos debe mostrar sucursal.
- Productos debe mostrar stock por sucursal + total.
- Inventario debe ser claramente solo lectura cuando no exista storeId único.
- Operaciones que requieran storeId único deben exigir selección explícita.

DATOS

Conserva:
- límites de queries;
- stockByStore como fuente de verdad;
- tratamiento correcto de split;
- exclusión/resta de devoluciones y cancelados;
- filtros de fecha existentes;
- manejo de documentos malformados;
- estados de error.

NO USAR MOCKS.
NO USAR DateTime.now() PARA INVENTAR MÉTRICAS.
NO VOLVER A USAR EL STOCK GLOBAL LEGACY.

CALIDAD

Después de cada fase:
1. ejecuta dart analyze en los archivos modificados;
2. corrige errores;
3. verifica que las rutas siguen funcionando;
4. verifica que AdminScope persiste;
5. ejecuta flutter build windows --release al terminar.

RESULTADO ESPERADO

La aplicación debe verse como un dashboard administrativo moderno:
- fondo claro;
- tarjetas blancas redondeadas;
- jerarquía visual clara;
- KPIs grandes;
- navegación lateral limpia;
- filtros globales visibles;
- comparación multi-sucursal clara;
- inventario legible;
- tablas profesionales;
- sin grandes espacios vacíos;
- sin cambiar la lógica de negocio.

NO TERMINES diciendo solamente que el diseño fue implementado.
Entrega un resumen por archivo modificado y especifica qué cambió visualmente y qué lógica se dejó intacta.
```

---

# 35. Resultado visual esperado

El dashboard final debe transmitir inmediatamente:

```text
¿Dónde estoy?
→ Dashboard

¿Qué estoy viendo?
→ Todas las sucursales

¿De cuándo son los datos?
→ Hoy

¿Cuánto vendimos?
→ KPIs superiores

¿Dónde vendimos más?
→ Ventas por sucursal

¿Cómo cobramos?
→ Métodos de pago

¿Qué se vendió?
→ Top productos

¿Dónde falta producto?
→ Inventario por sucursal
```

La pantalla no debe obligar al administrador a abrir varias ventanas para responder estas preguntas.

---

# 36. Regla final

**El nuevo diseño debe cambiar la experiencia, no la verdad de los datos.**

La fuente de verdad continúa siendo el código actual del proyecto y sus repositorios. Este documento define cómo esa información debe organizarse y visualizarse en Windows.

> **Meta:** convertir el actual POS administrativo en una interfaz de escritorio que se sienta como un producto profesional multi-sucursal, donde la comparación entre sucursales sea una función de primera clase y no un filtro escondido.
