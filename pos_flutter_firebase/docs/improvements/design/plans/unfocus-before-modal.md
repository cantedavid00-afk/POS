# Fix: the keyboard pops back up after closing a dialog

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/unfocus-before-modal
- **Needs new dependency**: none

## Why

The admin types a product name, taps "add category", and when that dialog closes the keyboard jumps back up even though they were done typing. Unfocusing before opening any modal keeps the keyboard away for good.

## Where

No `FocusManager` unfocus exists anywhere in `lib/` (grep returns nothing; `FocusScope.of(context).unfocus()` doesn't count per the article). These openers run while a field on the same page can be focused:
- `lib/features/products/ui/add_product_screen.dart:359-367` — `_addCategory` opens the category dialog from the product form (fields at `:409`+):
```dart
  Future<void> _addCategory() async {
    final category = await showDialog<app_models.Category>(
```
→ first line of the method becomes `FocusManager.instance.primaryFocus?.unfocus();`
- `lib/features/pos/ui/pos_screen.dart` — the toolbar search field can be focused while these open (all lack unfocus today):
  - `_showTicketDiscountDialog` (`final result = await showDialog<TicketDiscountSelection>(`)
  - `_suspendCurrentTicket` (`final name = await showDialog<String>(`)
  - `_showOpenTicketsDialog` (`final ticket = await showDialog<OpenTicket>(`)
  - `_editCartItem` (`final result = await showDialog<({List<SelectedModifier> modifiers, double discount, String discountName})>(`)
  - `_showCartDetails` (`await showDialog<void>(`)
→ first line of each method becomes `FocusManager.instance.primaryFocus?.unfocus();`

## The fix

The article's one-liner before each modal open. Never `FocusScope.of(context).unfocus()` — per the article it finds the nearest scope, not the focused field.

## Steps

1. Add the `FocusManager.instance.primaryFocus?.unfocus();` line to the six openers above (`FocusManager` needs no import beyond `material.dart`/`widgets.dart`, already present).
2. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "FocusManager.instance.primaryFocus?.unfocus()" lib/features/products/ui/add_product_screen.dart` → 1
- `grep -c "FocusManager.instance.primaryFocus?.unfocus()" lib/features/pos/ui/pos_screen.dart` → 5
- `grep -c "FocusScope.of(context).unfocus()" lib/features/pos/ui/pos_screen.dart lib/features/products/ui/add_product_screen.dart` → 0

## Don't touch

- Dialog contents, form validation, or focus behavior inside the dialogs (weight/payment dialogs intentionally autofocus their first field).
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
