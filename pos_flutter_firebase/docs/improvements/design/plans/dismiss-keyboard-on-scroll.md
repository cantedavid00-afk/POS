# Fix: the keyboard stays up when the user scrolls the form

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/dismiss-keyboard-on-scroll
- **Needs new dependency**: none

## Why

On long forms (new product, employee, poultry config) the cashier finishes a field and scrolls to see the rest, but the keyboard keeps covering half the screen. Treating that scroll as "done typing" and closing the keyboard is what users expect. No chat screen exists in this app, so the article's exception doesn't apply.

## Where

No scrollable in `lib/` sets `keyboardDismissBehavior` (grep returns nothing). Add `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,` to every scrollable below that contains a text field (all verified to contain one):
- `lib/features/business/ui/business_setup_screen.dart:63` — `child: SingleChildScrollView(` (field at `:77`)
- `lib/features/products/ui/add_product_screen.dart:281` — `content: SingleChildScrollView(` (category dialog name field at `:292`); `:402` — `return ListView(` (product fields at `:409`+)
- `lib/features/products/ui/products_screen.dart:475`, `:708`, `:951` — each `content: SingleChildScrollView(` (fields at `:480`, `:712`+, `:955`+)
- `lib/features/home/ui/back_office_screen.dart:1248` — `content: SingleChildScrollView(` (employee name/email/phone/PIN fields)
- `lib/features/settings/ui/settings_screen.dart:468` — `content: SingleChildScrollView(` (store name/address/phone fields)
- `lib/features/shift/ui/shift_screen.dart:502` — `content: SingleChildScrollView(` (closing-cash field at `:518`)
- `lib/features/sales/ui/receipts_screen.dart:349` — `child: SingleChildScrollView(` (refund reason field at `:408`)
- `lib/features/auth/ui/login_screen.dart:92` — `child: SingleChildScrollView(` (email/password fields)
- `lib/features/pos/ui/pos_screen.dart:1168` — `content: SingleChildScrollView(` (weight field); `:1319` — `content: SingleChildScrollView(` (payment amount fields)
- `lib/features/home/ui/desktop/employees_view_screen.dart:176` — `content: SingleChildScrollView(` (phone field at `:184`)
- `lib/features/home/ui/desktop/business_config_screen.dart:131` — `content: SingleChildScrollView(` (store fields at `:135`+)
- `lib/features/transfers/ui/receive_transfer_screen.dart:82` — `content: SingleChildScrollView(` (confirm-quantity fields at `:100`, `:119`)
- `lib/features/poultry/ui/receive_chicken_screen.dart:91` — `body: ListView(` (chickens/weight fields at `:94`, `:103`)
- `lib/features/poultry/ui/poultry_config_screen.dart:172` — `body: ListView(` (fields at `:178`+)

## The fix

The article's one-line fix per scrollable, e.g.:

```dart
ListView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  children: [
    // your fields
  ],
)
```

## Steps

1. Add `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,` to each scrollable listed above (first parameter position, nothing else changes).
2. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus per-file greps:
- `grep -c "keyboardDismissBehavior" lib/features/products/ui/add_product_screen.dart lib/features/products/ui/products_screen.dart` → 4
- `grep -c "keyboardDismissBehavior" lib/features/pos/ui/pos_screen.dart` → 2
- `grep -c "keyboardDismissBehavior" lib/features/poultry/ui/poultry_config_screen.dart` → 1
- `grep -c "keyboardDismissBehavior" lib/features/business/ui/business_setup_screen.dart lib/features/home/ui/back_office_screen.dart lib/features/settings/ui/settings_screen.dart lib/features/shift/ui/shift_screen.dart lib/features/sales/ui/receipts_screen.dart lib/features/auth/ui/login_screen.dart lib/features/home/ui/desktop/employees_view_screen.dart lib/features/home/ui/desktop/business_config_screen.dart lib/features/transfers/ui/receive_transfer_screen.dart lib/features/poultry/ui/receive_chicken_screen.dart` → 10

## Don't touch

- Pure lists with no fields (product grid, carts, receipts list, movements, pin pad grid, nav rail/drawer lists), dialog pickers with no text input, and the search field in the POS toolbar (typing-then-scrolling-results is the article's search case, but that toolbar field is outside any scrollable — nothing to change).
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- A listed scrollable no longer contains a text field (then skip just that one and report).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
