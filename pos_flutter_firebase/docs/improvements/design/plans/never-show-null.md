# Fix: data from the database can show up as "null" or blank

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/never-show-null
- **Needs new dependency**: none

## Why

Names, folios, reasons and addresses come from Firestore, where a field can be missing (`null`), stored as the literal string `"null"`, or an empty string. Today they are displayed directly, so an admin can see the word "null" or a blank gap in a list. One shared guard covering all three cases fixes every display at once.

## Where

No shared guard exists (`orPlaceholder|isUsable` grep over `lib/` returns nothing); scattered `?? ''` / `?? 'Sin...'` only cover plain `null`. New file `lib/shared/extensions/string_x.dart` (matches `lib/shared/` folder conventions) with the article's extension, verbatim:

```dart
extension StringX on String? {
  bool get isUsable {
    return this != null && this!.isNotEmpty && this != 'null';
  }

  String orPlaceholder([String placeholder = '-']) {
    if (!isUsable) return placeholder;

    return this!;
  }
}
```

Migrate every display of a Firestore-backed String below (direct `Text(field)` and interpolated uses). Pattern per site: `Text(x.y)` → `Text(x.y.orPlaceholder())`, adding `import '<relative>/shared/extensions/string_x.dart';` to each touched file. Non-String values: call `.toString()` first per the article (none of the sites below need it — all are Strings).

Direct displays:
- `lib/features/transfers/ui/send_transfer_screen.dart:229` — `title: Text(product.name),`
- `lib/features/employees/ui/employee_pin_screen.dart:90` — `.map((employee) => DropdownMenuItem(value: employee, child: Text(employee.name)))`
- `lib/features/losses/ui/losses_screen.dart:104` — `title: Text(product.name),`
- `lib/features/losses/ui/losses_screen.dart:177` — `title: Text(movement.productName),`
- `lib/features/pos/ui/pos_screen.dart:979` — `label: Text(category.name),`
- `lib/features/pos/ui/pos_screen.dart:1079` — `title: Text(ticket.name),`
- `lib/features/home/ui/home_screen.dart:325` — `title: Text(store.name),`
- `lib/features/pos/ui/widgets/ticket_discount_dialog.dart:102` — `title: Text(discount.name),`
- `lib/features/home/ui/back_office_screen.dart:72` — `...widget.stores.map((store) => DropdownMenuItem<String?>(value: store.id, child: Text(store.name))),`
- `lib/features/home/ui/back_office_screen.dart:417` — `title: Text(sale.folio),`
- `lib/features/home/ui/back_office_screen.dart:680` — `title: Text(product.name),`
- `lib/features/home/ui/back_office_screen.dart:727` — `title: Text(movement.productName),`
- `lib/features/home/ui/back_office_screen.dart:755` — `title: Text(movement.productName),`
- `lib/features/home/ui/back_office_screen.dart:887` — `title: Text(employee.name),`
- `lib/features/home/ui/back_office_screen.dart:1300` — `title: Text(store.name),`
- `lib/features/home/ui/desktop/business_config_screen.dart:63` — `title: Text(store.name),`
- `lib/features/products/ui/add_product_screen.dart:431` — `child: Text(category.name),`
- `lib/features/settings/ui/settings_screen.dart:44` — `title: Text(business.name),`
- `lib/features/settings/ui/settings_screen.dart:78` — `title: Text(store.name),`
- `lib/features/products/ui/products_screen.dart:194` — `title: Text(product.name),`
- `lib/features/products/ui/products_screen.dart:319` — `title: Text(category.name),`
- `lib/features/products/ui/products_screen.dart:793` — `title: Text(discount.name),`
- `lib/features/home/ui/desktop/desktop_layout.dart:242` — `title: Text(store.name),`
- `lib/features/home/ui/desktop/employees_view_screen.dart:69` — `title: Text(employee.name),`
- `lib/features/home/ui/desktop/reports_screen.dart:104` — `title: Text(product.key),`
- `lib/features/home/ui/desktop/reports_screen.dart:118` — `title: Text(sale.folio),`
- `lib/features/home/ui/desktop/inventory_view_screen.dart:101` — `title: Text(product.name),`

Interpolated displays of Firestore-backed Strings (same `.orPlaceholder()` wrap on each interpolated value):
- `lib/features/home/ui/home_screen.dart:149` — `Text('${selectedStore.name} · ${activeEmployee.name}', ...)` → `Text('${selectedStore.name.orPlaceholder()} · ${activeEmployee.name.orPlaceholder()}', ...)`
- `lib/features/home/ui/desktop/business_config_screen.dart:64` — `subtitle: Text('${store.address} · ${store.phone}'),` → wrap both values. (Phone gets its mask in the phone-numbers plan; the guard stays as well.)
- `lib/features/home/ui/desktop/employees_view_screen.dart:70` — `subtitle: Text('${employee.role} · ${employee.email}'),` → wrap both values.
- `lib/features/home/ui/desktop/employees_view_screen.dart:110` — `SnackBar(content: Text('${employee.name} desactivado')),` → wrap `employee.name`.
- `lib/features/home/ui/desktop/transfers_view_screen.dart:109` — `title: Text('${item.fromStore} → ${item.toStore}'),` → wrap both values.
- `lib/features/home/ui/desktop/transfers_view_screen.dart:110` — `subtitle: Text('${item.products} productos · ${item.weight} · ${item.date}'),` → wrap `item.products`, `item.weight`, `item.date`.
- `lib/features/home/ui/desktop/inventory_view_screen.dart:102` — `subtitle: Text('${product.categoryName} · Stock: ...'),` → wrap `product.categoryName` (leave the numeric part; numbers plan handles it).
- `lib/features/home/ui/back_office_screen.dart:756` — `subtitle: Text('${movement.typeLabel} · ${movement.reason} · ${_formatDate(...)}'),` → wrap `movement.reason` (typeLabel is a local switch, dates plan handles the date).
- `lib/features/sales/ui/receipts_screen.dart:67` — `title: Text('${_folioLabel(sale)} ${sale.folio}'),` → wrap `sale.folio`.
- `lib/features/sales/ui/receipts_screen.dart:129` — `title: Text('${_folioLabel(sale)} ${_shortFolio(sale.id)}'),` → leave helpers (local, non-null by construction) — skip this one, listed here only to record it was audited.
- `lib/features/home/ui/desktop/reports_screen.dart:119` — `subtitle: Text('${sale.items.length} artículos · ...'),` → nothing nullable (length + local ternary) — skip, audited.

## The fix

Article's `StringX` extension plus the per-site wraps above. Imitate existing `lib/shared/` organization for the new file.

## Steps

1. Create `lib/shared/extensions/string_x.dart` with the extension above, exactly.
2. Apply the direct-display wraps (29 sites) and interpolated wraps (9 sites), adding the import to each touched file.
3. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "orPlaceholder" lib/shared/extensions/string_x.dart` → 3
- `grep -rn "Text(product.name)" lib/features/losses/ui/losses_screen.dart lib/features/home/ui/back_office_screen.dart` → 0 (proves the old pattern is gone where it was quoted)
- `grep -c "orPlaceholder()" lib/features/home/ui/back_office_screen.dart` → 6
- `grep -c "orPlaceholder()" lib/features/losses/ui/losses_screen.dart` → 2

## Don't touch

- Numeric/date displays (numbers and dates plans own them).
- `??` fallbacks that carry real meaning (e.g. `?? 'Sin categoría'` alternatives are replaced by the guard only where listed; where a specific label is wanted, keep it).
- Firestore read code, models, or sync logic.
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
