# Dashboard Windows (.exe Administrador) — Diseño completo del sistema actual

> **Proyecto:** `pos_flutter_firebase` · **Plataforma objetivo de este documento:** Windows `.exe` (`build/windows/x64/runner/Release/pos_flutter_firebase.exe`)
> **Alcance:** app **exclusiva del administrador**. Android/móvil sigue intacto en `lib/features/home/ui/home_screen.dart` (ruta `_buildMainScaffold`); todo lo descrito aquí vive bajo `lib/features/home/ui/desktop/`.
> **Estado verificado:** `dart analyze` sin errores en los archivos nuevos; `flutter build windows --release` compila; tests de productos/empleado pasan.

---

## 1. Propósito y principios de diseño

1. **Un solo rol:** administrador/dueño. No hay caja POS ni PIN de cajero en el flujo feliz del `.exe` (el PIN solo aparece si la sesión lo exige).
2. **Una sola verdad global:** la sucursal seleccionada y el rango de fecha viven en **un único objeto** (`AdminScope`) por encima de todas las secciones. Cambiar de sección **no resetea** el filtro.
3. **Datos 100% reales:** prohibidos los mocks en producción. El dashboard anterior usaba `DateTime.now().millisecond % 500` y actividad falsa (`Hace 5 min`); todo eso se eliminó.
4. **Lecturas acotadas:** cada `Stream`/`Future` de Firestore lleva `.limit(...)` para no congelar la ventana con miles de documentos.
5. **Sin fallback legacy:** si no existe `stockByStore/{storeId}` el stock es **0**. Nunca se lee el campo global viejo de `products/{id}.stockQuantity` como fuente de verdad.
6. **Pagos split correctos:** `paymentMethod == 'split'` reparte `cashAmount`/`cardAmount`; nunca se cuenta como 100% efectivo.
7. **Devoluciones y cancelados:** `isRefund`/`isCancelled` se excluyen de brutas y se restan para netas.

---

## 2. Mapa de archivos (estructura real)

```
lib/
├── main.dart                                   # Arranque: dotenv, Firebase, Hive, Sync, DI, CartProvider, MaterialApp.router
├── core/
│   ├── router/app_router.dart                  # GoRouter: /, /home, /home/products/add|edit, /home/tickets/:saleId
│   ├── di/service_locator.dart                 # Instancia repositorios + providers
│   └── theme/glass_theme.dart                  # Tema claro/oscuro (fondo sidebar, acento, bordes)
├── shared/
│   ├── models/
│   │   ├── sale.dart                           # Sale.fromDoc, isRefund/isCancelled/isPartiallyCancelled
│   │   ├── product.dart                        # Product.fromDoc (lowStockAlertQuantity NO nulable)
│   │   ├── product_stock.dart                  # ProductStock.fromDoc (storeId = doc.id)
│   │   ├── store.dart                          # Sucursal {id, name, address, phone, active}
│   │   └── employee.dart                       # Empleado {role, storeIds, active, PIN hash}
│   ├── providers/app_session_notifier.dart     # Sesión: business, stores, selectedStore, activeEmployee
│   └── widgets/
│       ├── bottom_padding.dart                 # Padding inferior seguro
│       └── product_presentation.dart           # Thumb con Image.file + errorBuilder (referencia del fix)
└── features/
    └── home/ui/
        ├── home_screen.dart                    # Decide: DesktopLayout (Windows) vs scaffold móvil
        ├── back_office_screen.dart             # Back Office (pestañas Reportes/Inventario/Empleados)
        │                                       # + _AllStoresInventoryView (TODAS, solo lectura)
        └── desktop/
            ├── desktop_layout.dart             # Puerta Windows: login → selección sucursal → PIN → AdminShell + AdminScope
            ├── desktop_navigation.dart         # Nav vieja (iconos 72px). YA NO SE USA en el shell nuevo
            ├── dashboard_screen.dart           # Dashboard viejo con mocks. YA NO SE USA
            ├── reports_screen.dart / inventory_view_screen.dart / shifts_view_screen.dart / ...
            │                                   # Pantallas desktop viejas. YA NO SE USAN en el shell admin
            └── admin/                          # ★ NUEVO — todo el .exe administrador vive aquí
                ├── admin_filters.dart          # AdminScope, AdminDateRange(+resolve/contains), AdminDestination
                ├── admin_topbar.dart           # Barra superior: botón sucursal + filtro fecha + empleado + salir
                ├── admin_navigation.dart       # Nav lateral 5 destinos, labels horizontales, 88px / 240px
                ├── admin_shell.dart            # Shell: nav + topbar + contenido, persiste filtros
                ├── admin_dashboard_screen.dart # Dashboard real: KPIs, gráficas, stock expandible
                ├── admin_receipts_screen.dart  # Recibos filtrados por scope (split bien etiquetado)
                ├── admin_products_screen.dart  # Productos: stock por sucursal + vendidos en periodo
                └── admin_poultry_screen.dart   # Recibir pollo: formulario + historial filtrado
```

**Archivos que ya no alimentan el `.exe` (no borrar todavía, solo están desconectados):**
`desktop_navigation.dart`, `dashboard_screen.dart`, `reports_screen.dart`, `inventory_view_screen.dart`, `employees_view_screen.dart`, `shifts_view_screen.dart`, `business_config_screen.dart`, `backup_export_screen.dart`, `transfers_view_screen.dart`.

---

## 3. Arquitectura y flujo de datos

```
Firebase Auth ──► AuthGate (app_router) ──► HomeScreen ──► DesktopLayout (Windows)
                                                                │
                                        ┌───────────────────────┼───────────────────────┐
                                        │ login / selección     │ PIN empleado          │ sesión lista
                                        │ sucursal / error      │                       ▼
                                        │                       │              ChangeNotifierProvider
                                        │                       │              AdminScope(selectedStoreId: null,
                                        │                       │                       range: today)
                                        │                       │                       │
                                        │                       │                       ▼
                                        │                       │                    AdminShell
                                        │                       │                    ├── AdminNavigation (5 destinos)
                                        │                       │                    ├── AdminTopBar (sucursal + fecha)
                                        │                       │                    └── Contenido según destino
                                        │                       │                        ├── Dashboard ──► Firestore sales (≤500)
                                        │                       │                        │                + products (≤60)
                                        │                       │                        │                + stockByStore por ruta
                                        │                       │                        ├── Recibos ────► Firestore sales (≤300)
                                        │                       │                        ├── Productos ──► products (≤200)
                                        │                       │                        │                + sales (≤300) + stocks
                                        │                       │                        ├── Pollo ──────► poultryReceivings (≤100)
                                        │                       │                        └── BackOffice ─► reutiliza BackOfficeScreen
                                        ▼                       ▼
                                   Firestore ◄────────► Hive local (caché) + SyncQueue (cola offline)
```

**Reglas de flujo (unidireccional):**

- Estado baja: `AdminScope` → pantallas (vía `context.watch<AdminScope>()`).
- Eventos suben: pantallas → `context.read<AdminScope>().selectStore()/setRange()`.
- Vistas nunca escriben Firestore directo salvo acciones explícitas (guardar recepción de pollo, ajustar inventario en sucursal única, CRUD de producto).
- Repositorios/servicios (`SaleRepository`, `ProductRepository`, `StockRepository`, `InventoryRepository`, `PoultryRepository`) son la única puerta a datos; las vistas no inventan totales.

---

## 4. Estado global: `AdminScope`, fechas y destinos

**Archivo:** `lib/features/home/ui/desktop/admin/admin_filters.dart`

### 4.1 `AdminScope` (ChangeNotifier)

| Miembro | Tipo | Significado |
|---|---|---|
| `selectedStoreId` | `String?` | `null` = **TODAS las sucursales**. Con valor = una sucursal. |
| `isAllStores` | `bool` | `selectedStoreId == null`. |
| `range` | `AdminDateRange` | Rango global. Inicial: `today`. |
| `selectStore(String?)` | método | Cambia sucursal, `notifyListeners()` (no-op si es igual). |
| `setRange(AdminDateRange)` | método | Cambia rango, `notifyListeners()` (no-op si es igual). |

Se provee **una sola vez** en `desktop_layout.dart` envolviendo al shell:

```dart
ChangeNotifierProvider(
  create: (_) => AdminScope(initialStoreId: null), // Dashboard arranca en TODAS
  child: _AdminRoot(... AdminShell ...),
)
```

Por eso el botón de sucursal **persiste** al navegar entre Dashboard ↔ Recibos ↔ Productos ↔ Pollo ↔ Back Office.

### 4.2 `AdminDateRange` (filtro de TODAS las secciones)

| Valor | Etiqueta | Rango resuelto (`resolve(now)`) |
|---|---|---|
| `today` | Hoy | `[00:00 hoy, ahora]` |
| `yesterday` | Ayer | `[00:00 ayer, 23:59:59.999 ayer]` |
| `thisWeek` | Esta semana | `[lunes 00:00, ahora]` (lunes = inicio) |
| `thisMonth` | Este mes | `[día 1 00:00, ahora]` |

- `contains(date, now)`: `start <= date <= end`. Fechas `null` se excluyen.
- Fecha de venta usada: `sale.clientCreatedAt ?? sale.createdAt`. Si ambas son `null`, el ticket **no aparece** en dashboard/recibos (decisión consciente contra datos fantasma).
- Todas las secciones filtran **en memoria** tras una query acotada ordenada por `clientCreatedAt desc`. Esto evita crear un índice compuesto por sucursal+fecha por cada pantalla y mantiene el mismo criterio en todo el `.exe`.

### 4.3 `AdminDestination` (los 5 del nav)

| Enum | Etiqueta | Contenido |
|---|---|---|
| `dashboard` | Dashboard | `AdminDashboardScreen` |
| `receipts` | Recibos | `AdminReceiptsScreen` |
| `products` | Productos | `AdminProductsScreen` |
| `poultry` | Recibir pollo | `AdminPoultryScreen` |
| `backoffice` | Back Office | `BackOfficeScreen` (reutilizado, con `ValueKey` por sucursal) |

---

## 5. Shell, barra superior y navegación

### 5.1 `AdminShell` (`admin_shell.dart`)

- `StatefulWidget` con `_destination` (inicial: `dashboard`).
- `LayoutBuilder`: `expanded = maxWidth >= 1300` → nav de 240px con etiquetas + nombre; si no, 88px compacta.
- Estructura: `Row(Navigation, VerticalDivider, Expanded(Column(TopBar, Expanded(contenido))))`.
- Back Office se instancia con `ValueKey(selectedStoreId ?? 'all')` para **reconstruir** al cambiar sucursal global y no mostrar datos stale de otra sucursal.
- Título por destino: Dashboard / Recibos / Productos / Recibir pollo / Back Office.

### 5.2 `AdminTopBar` (`admin_topbar.dart`)

Visible en **las 5 secciones** (requisito: todos los apartados tienen filtro).

| Zona | Widget | Comportamiento |
|---|---|---|
| Izquierda | `PopupMenuButton<String?>` con hijo `FilledButton.tonalIcon` | Muestra **TODAS** (icono `storefront`) o nombre de sucursal (icono `store`). Ítems: "Todas las sucursales" + divisor + cada sucursal con ✓ en la activa. `onSelected` → `AdminScope.selectStore`. |
| Centro | Título de sección + `SegmentedButton<AdminDateRange>` | 4 segmentos compactos: Hoy / Ayer / Esta semana / Este mes. `selected: {scope.range}`. |
| Derecha | `Chip` empleado + `IconButton logout` | Chip: avatar inicial + `nombre · rol`. Logout pide confirmación en `AlertDialog` y llama `onSignOut` (→ `AuthRepository.signOut()`). |
| Responsive | `LayoutBuilder` + `Wrap` | Si `maxWidth < 900`, los bloques bajan de línea en vez de overflow. |

### 5.3 `AdminNavigation` (`admin_navigation.dart`)

- Solo 5 ítems (antes 12+ con permisos por rol; el `.exe` es solo admin).
- Iconos: `dashboard`, `receipt_long`, `inventory_2`, `egg_alt`, `admin_panel_settings`.
- **Fix del bug viejo:** antes labels con `RotatedBox(quarterTurns: 3)` de 9px ilegibles; ahora horizontales (11px compacta / 13px expandida), con `Tooltip`, `InkWell(borderRadius 10)` y `AnimatedContainer` de selección (`primaryContainer`).
- Ancho: `88` compacta / `240` expandida. Fondo `surfaceContainerLow`. Abajo avatar + nombre (truncado a 12 + `…` en compacta; nombre + "Administrador" en expandida).
- `desktop_navigation.dart` (vieja) quedó sin uso a propósito.

---

## 6. Dashboard (`admin_dashboard_screen.dart`) — sección por sección

**Entradas:** `businessId`, `stores`. Lee `AdminScope` con `watch`.
**Query base:** `businesses/{bid}/sales orderBy clientCreatedAt desc limit(500)` por `snapshots()`.
**Filtro en memoria:** sucursal (si no es TODAS) + `range` sobre `clientCreatedAt ?? createdAt`.
**Documentos malformados:** `try { Sale.fromDoc } catch { skip }` — un doc roto no tumba el dashboard.
**Layout:** `ListView` (ya no `GridView` fijo):
- Ancho (<1100): header, KPI, ventas, pagos, artículos, stock — apilados.
- Ancho (≥1100): fila(header+kpi), fila(ventas+pagos, 340px), fila(artículos+ayuda, 340px), stock full-width expandible.

### 6.1 Encabezado

- Compacto `_DashboardHeader`: icono + `Dashboard · {rango}` + `{n} tickets en el periodo`.
- Ancho `_DashboardHeaderFull`: título + `Todas las sucursales` / `Sucursal filtrada`.

### 6.2 KPIs (`_KpiRow` + `_DashboardTotals`)

`_DashboardTotals(sales)` — fórmulas exactas:

| Métrica | Fórmula |
|---|---|
| `originals` | `!isRefund && !isCancelled` (los `partially_cancelled` **sí** cuentan en brutas; es decisión actual a revisar) |
| `refunds` | `isRefund` |
| `gross` (Brutas) | `Σ originals.total` |
| `refundTotal` (Devoluciones) | `Σ refunds.total` |
| `net` (Ventas netas) | `gross − refundTotal` |
| `discounts` | `Σ originals.discountTotal` |
| `cash` | `cash→total` + `split→cashAmount ?? 0` |
| `card` | `card→total` + `split→cardAmount ?? 0` |
| `avgTicket` | `gross / originals.length` (0 si vacío) |

UI: `Wrap` de 6 mini-KPIs (netas, brutas, devoluciones, tickets, ticket prom., descuentos) con `FontFeature.tabularFigures()` para números alineados.

### 6.3 Ventas por sucursal (`_SalesByStoreCard`)

- Agrupa `Σ total` por `storeId` (solo no-refund/no-cancelled), ordena desc, grafica top 8 en `BarChart` (`fl_chart`), barras `primary`, `width 18`, `radius 4`, sin grid/borde, etiquetas X truncadas a 10 chars.
- Subtítulo: `showAll ? 'Todas las sucursales' : 'Sucursal seleccionada'`.
- Leyenda inferior: top 4 como `Nombre: $X · ...` (máx 2 líneas, ellipsis).
- Nombre de sucursal: lookup en `stores`; fallback `id[0..6]` o `(Sin sucursal)`.
- Vacío: `Sin ventas en el periodo`.

### 6.4 Ventas por tipo de pago (`_PaymentTypeCard`)

- `PieChart` 2 secciones: efectivo (verde) / tarjeta (naranja), `centerSpaceRadius 36`, `%` en blanco bold.
- Porcentajes sobre `cash + card` (split ya repartido). `total <= 0` → `Sin cobros en el periodo`.
- Leyenda: `Efectivo $X · Tarjeta $Y` con 2 decimales.

### 6.5 Ventas por artículo Top (`_TopArticlesCard`)

- Agrega por `item['name']`: `qty = item['quantity']`, `subtotal = item['subtotal'] ?? unitPrice*qty`.
- Ordena por cantidad desc, top 8. Fila: nombre (ellipsis) + `N uds · $M` (0 decimales si entero, 2 si decimal) + `LinearProgressIndicator(value = qty/max)`.
- Vacío: `Sin artículos en el periodo`.

### 6.6 Stocks por sucursal — panel expandible (`_StockAllStoresCardExpandable` + `_StockTable`)

**Requisito del usuario:** dinámico, extender/compactar **sin abrir otra ventana**. Implementación:

- `StatefulWidget` con `_expanded: bool`, botón `FilledButton.tonalIcon(unfold_more/unfold_less)` → `Expandir/Compactar`.
- `AnimatedContainer(250ms, easeInOut)`: `300px` compacto / `560px` expandido.
- `_StockTable(key: ValueKey('stock-full|compact'))`: la clave fuerza reconstruir el rango visible sin scroll stale.
- Compacto: `maxItems = 8`. Expandido: `maxItems = 60`.
- Encabezado del conteo: `Mostrando X de Y productos`.
- `_StockTable._load()`:
  1. `products where active == true limit(60) get()` (one-shot, no stream permanente).
  2. Por producto × por sucursal (`stores.take(6)`): `products/{pid}/stockByStore/{sid} get()` por ruta (permitido por reglas, sin `collectionGroup`).
  3. `qty = stockQuantity ?? stock ?? 0`; si no existe doc o hay error → `0`.
  4. Ordena filas por `total` asc (los críticos primero).
- Fila: icono `warning/rojo` si bajo else `inventory_2/verde`; título producto; subtítulo `ABBR: 12.00 · ...` (abreviatura 4 letras por sucursal); trailing `Total X` en rojo si bajo.
- `isLow`: `total <= lowStockAlertQuantity` (si alerta ≤ 0, bajo = `total <= 0`).
- `lowStockAlertQuantity` es `double` **no nulable** en `Product` (los `?? 0` viejos eran dead-code y se quitaron).

**Límites conscientes:** 60 productos, 6 sucursales, 60 visibles. Con más catálogo, ampliar con paginación (ver §11).

### 6.7 Tarjeta de ayuda (`_DashboardHintCard`)

Solo layout ancho, 340px junto a Top artículos:
`¿Cómo leer el dashboard?` — netas = brutas − devoluciones; mixto reparte; sin doc = 0; stock se expande abajo.

---

## 7. Las otras 4 secciones (cómo usan el scope global)

### 7.1 Recibos (`admin_receipts_screen.dart`)

- Query: `sales orderBy clientCreatedAt desc limit(300)`, filtro scope+rango igual que dashboard.
- Fila: `Card` coloreada (`cancelled` rojo 8%, `partial/refund` naranja 8%), icono por estado/pago (`undo`, `cancel_outlined`, `credit_card`, `call_split`, `payments`), título `{folio} · {sucursal}`, subtítulo `{dd/mm hh:mm} · {pago} · {estado}`, trailing `$total`.
- **Fix split:** antes `_paymentLabel` mostraba `split` como "Efectivo". Ahora: `Mixto ef.$X + tj.$Y`.
- Tap → `context.push('/home/tickets/:id', extra: {businessName, store, sale})` (requiere store conocida; si es `null` no navega).
- Vacío: `Sin recibos en {rango} [para esta sucursal]`.

### 7.2 Productos (`admin_products_screen.dart`)

- Streams: `products where active == true limit(200)` + `sales limit(300)` para `soldByProduct[productId]` en el rango/sucursal (excluye refund/cancelled).
- Si `TODAS`: tabla con stock por sucursal (hasta 6) + `Vendidos {rango}: N` por producto, `Stock {total}` en rojo si `total <= lowStockAlertQuantity && trackStock`.
- Si una sucursal: misma tabla filtrada a esa sucursal.
- FAB `Producto` → `/home/products/add` con `storeId` del scope o primera sucursal. Tap en fila → `/home/products/edit`.
- **Imagen segura desktop** (`_SafeThumb`): si `presentationType == image` y `localImagePath` existe en disco (`File.existsSync()` en `try/catch`) → `Image.file + errorBuilder`; si no (ruta Android, OneDrive, borrado) → fallback de color con inicial. Nunca tile rojo.
- Límite: 120 productos listados; stocks por `get()` acotado igual que dashboard.

### 7.3 Recibir pollo (`admin_poultry_screen.dart`)

- Formulario: cantidad (int) + peso kg (coma o punto), validación `> 0`, `avg = peso/cantidad`, `ChickenReceiving(businessId, storeId, employeeId, ...)` → `PoultryRepository.saveReceiving`.
- Sucursal destino: la del scope; si es TODAS, la primera sucursal (y se avisa en el subtítulo).
- **Fix pantalla negra:** antes `Navigator.pop()` destruía el shell embebido; ahora `_countCtrl/_weightCtrl.clear()` + `SnackBar`, sin navegar.
- Historial: `poultryReceivings orderBy createdAt desc limit(100)`, filtro scope+rango en memoria; acepta `chickenCount ?? totalChickens`; error de índice/colección se muestra como texto, no spinner infinito.
- Controladores con `dispose()` propio (patrón anti-`_dependents.isEmpty`).

### 7.4 Back Office (`back_office_screen.dart` reutilizado)

- `AdminShell` lo instancia con `ValueKey(storeId ?? 'all')`.
- Tiene sus propios filtros internos (sucursal + fecha) en Reportes; el TopBar global se mantiene para cambio rápido y consistencia.
- **Fix inventario TODAS (§8).** Empleados/PIN/reportes no se tocaron en este ciclo.

---

## 8. El fix de Inventario Back Office (detalle forense)

**Síntoma:** con `Todas las sucursales`, el inventario mostraba todo en 0 pero los movimientos sí aparecían.

**Causa** (`back_office_screen.dart` `_InventoryTabState.build`, antes del fix):

```dart
stream: widget.selectedStoreId == null
    ? const Stream<Map<String, ProductStock>>.empty()  // ← stocks = {} siempre
    : watchStockByStore(..., storeId: widget.selectedStoreId!),
...
stockQuantity: stock?.stockQuantity ?? 0,  // ← siempre 0 en TODAS
```

Movimientos sí se veían porque `watchMovements` trae todo y filtra en memoria (`selectedStoreId == null || movement.storeId == ...`).

**Solución (sin tocar la ruta de sucursal única):**

```dart
if (widget.selectedStoreId == null) {
  return _AllStoresInventoryView(businessId: ..., stores: ...);
}
return StreamBuilder<List<Product>>( ...ruta única intacta... );
```

`_AllStoresInventoryView` (nuevo, al final de `_InventoryTabState`, antes de `_EmployeesTab`):
`StreamBuilder(products)` → `FutureBuilder(_loadStocks)` (por-ruta, `take(8)` sucursales, `take(120)` productos, sin doc = 0) → `ListView` de `Card/ListTile` con `ABBR stock` por sucursal + `Total` + `Bajo stock` en rojo. Encabezado: `Todas las sucursales — Solo lectura. Selecciona una sucursal arriba para ajustar inventario.` El botón `Ajustar` sigue exigiendo sucursal única (correcto: el diálogo `adjustStock` necesita `storeId` único).

---

## 9. Firestore: colecciones, queries y reglas tocadas por este diseño

**Estructura usada:**

```
businesses/{bid}                     # negocio
  stores/{sid}                       # sucursales
  employees/{eid}                    # roles, storeIds, active, PIN hash
  products/{pid}                     # catálogo (active, price, trackStock, lowStockAlertQuantity…)
    stockByStore/{sid}               # {stockQuantity, lowStockAlertQuantity, price?, chickenCount?}
  sales/{saleId}                     # {storeId, folio, items[], subtotal, discountTotal, total,
                                     #  paymentMethod cash|card|split, cashAmount, cardAmount,
                                     #  status completed|cancelled|partially_cancelled|refund,
                                     #  clientCreatedAt, createdAt, ...}
  poultryReceivings/{id}             # {storeId, chickenCount|totalChickens, totalWeightKg, createdAt}
  productRefs/{ref} · counters/* · inventoryMovements/* · shifts/* · modifiers/* · discounts/*
```

**Queries del dashboard/admin (todas acotadas):**

| Pantalla | Query | Filtro memoria |
|---|---|---|
| Dashboard ventas | `sales orderBy clientCreatedAt desc limit(500)` | sucursal + rango |
| Dashboard stocks | `products where active==true limit(60)` + `stockByStore/{sid} get()` por ruta | — (todo es stock actual) |
| Recibos | `sales orderBy clientCreatedAt desc limit(300)` | sucursal + rango |
| Productos | `products where active==true limit(200)` + `sales limit(300)` + stocks por ruta | vendidos por rango/sucursal |
| Pollo historial | `poultryReceivings orderBy createdAt desc limit(100)` | sucursal + rango |

**Reglas relevantes (`firestore.rules`):** `sales read: canReadBusiness`; `stockByStore read: canReadBusiness`; `products read: canReadBusiness`; `poultryReceivings create: canSell + hasBusinessId`. Las lecturas por-ruta (`doc().get()`) están permitidas; `collectionGroup` se evita a propósito.

**Índices:** `sales orderBy clientCreatedAt` y `poultryReceivings orderBy createdAt` requieren índice simple/compound según consola; si falta, el error se muestra en UI en vez de colgar.

---

## 10. Otros bugs conocidos corregidos en este ciclo Windows

| # | Bug | Archivo:línea aprox | Fix |
|---|---|---|---|
| 1 | Logout imposible (`onSignOut: () {}`) | `desktop_layout.dart` (antes 82,96) | `context.read<AuthRepository>().signOut()` + confirmación en TopBar |
| 2 | Nav duplicada/divergente (3 listas) | `desktop_layout` + `desktop_navigation` + `home_screen` | Una sola fuente: `AdminDestination` (5 ítems) |
| 3 | Labels rotados ilegibles 9px | `desktop_navigation.dart:65` | Labels horizontales en `admin_navigation.dart` |
| 4 | `Image.file` tile rojo en Windows | `product_grid.dart:155` | `existsSync()` en try/catch + `errorBuilder` + fallback color (`_colorCard`) |
| 5 | Mocks en dashboard | `dashboard_screen.dart:164,238,403` | Eliminado; archivo viejo desconectado |
| 6 | Pantalla negra al guardar pollo | `receive_chicken_screen` | Reset de formulario, sin `pop` (`admin_poultry_screen.dart`) |
| 7 | Split mostrado como efectivo | `receipts_screen` viejo | Etiqueta `Mixto ef.$X + tj.$Y` |
| 8 | Stock 0 en TODAS (Back Office) | `back_office_screen.dart:636` | `_AllStoresInventoryView` |
| 9 | Grid fijo impedía expandir stock | `admin_dashboard` viejo | `ListView` + `AnimatedContainer` 300↔560 |
| 10 | Rutas `C:\Users\...` y `.env` frágil | export/backup viejos | Sin hardcodes en pantallas nuevas; `limit()` en queries |

**No tocados a propósito (riesgo conocido, fuera de este ciclo):** totales de venta confiados del cliente, `openShift` sin transacción, `cancelSale` sin revalidación concurrente, `transfer confirm` sin idempotencia, `pinVisible` en texto plano, validación 100% cliente en reglas. Ver auditoría previa.

---

## 11. Responsive, rendimiento y límites

- **Breakpoints:** `<900` TopBar en wrap; `<1100` dashboard apilado; `≥1100` dashboard en filas de 2; `≥1300` nav expandida 240px.
- **Gráficas:** `fl_chart` (`BarChart` + `PieChart`). Barras top 8, pastel 2 secciones, sin animaciones pesadas.
- **Costos Firestore (peor caso dashboard):** 1 query ventas (≤500 docs) + 1 query productos (≤60) + 60×6 gets de stock (≤360). Aceptable para negocio pequeño/mediano; con catálogo mayor, paginar `_load()` o cachear en Hive.
- **Límites duros actuales:** ventas 500, recibos 300, productos 200/120/60 según pantalla, pollo 100, sucursales visibles 6–8, movimientos mostrados 20.
- **Ventana Windows:** título en `windows/runner/main.cpp`, icono en `windows/runner/resources/app_icon.ico`, metadatos en `Runner.rc` (aún dicen `com.example/pos_flutter_firebase` — renombrar antes de distribuir).

---

## 12. Cómo compilar, ejecutar y verificar

```powershell
cd C:\Users\Alonso-Manuel\POS\pos_flutter_firebase
dart analyze lib/features/home/ui/desktop/admin/admin_dashboard_screen.dart
flutter build windows --release
Start-Process build\windows\x64\runner\Release\pos_flutter_firebase.exe
```

- Análisis esperado: `No issues found!` en admin; `back_office_screen.dart` solo 3 `info` preexistentes.
- Tests relacionados que pasan: `test/features/products/product_repository_test.dart`, `test/shared/models/employee_test.dart`.
- Flujo de prueba del dashboard: entra como admin → TopBar en **TODAS** + **Hoy** → verifica KPIs, las 3 gráficas y stock compacto → **Expandir** → cambia a una sucursal → confirma que todo se filtra → cambia a **Ayer/Esta semana/Este mes** → confirma conteos → Back Office → Inventario en TODAS (tabla) y en una sucursal (lista + Ajustar).

---

## 13. Próximos pasos sugeridos (no implementados)

1. Paginar `_loadStocks` y cachear en Hive para catálogos >120 productos.
2. Sincronizar el filtro interno de Back Office con `AdminScope` (hoy son independientes).
3. Renombrar exe/empresa/título/icono (`Runner.rc`, `main.cpp`), fijar tamaño mínimo de ventana, MSIX/firma.
4. Endurecer reglas con validación servidor y quitar `pinVisible` en texto plano.
5. Tests de widget para `AdminScope` + filtros de fecha y dorados del dashboard.

---

*Fin del documento. Fuente de verdad: código en `lib/features/home/ui/desktop/admin/` + `lib/features/home/ui/back_office_screen.dart`.*
