# Fix: the keyboard can't drive any form to submit

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/text-input-action
- **Needs new dependency**: none

## Why

Employee, product, payment, loss and poultry forms have two or more fields, but the keyboard's action key does nothing useful — the admin must tap each field by hand. With `next` on every field but the last and submit on the last, the whole form runs from the keyboard alone. (Login and product forms already do this correctly — untouched.)

## Where

No `textInputAction` on any field below (grep confirms; only login/products screens have it). Per form, non-last fields get `textInputAction: TextInputAction.next`, the last gets `.done` (or the matching action) plus `onFieldSubmitted` calling the same method its submit button calls. With `next`, Flutter moves focus on its own — no `FocusNode`s.

- `lib/features/losses/ui/losses_screen.dart:319-336` — quantity field then reason field:
```dart
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.numberWithOptions(decimal: _isWeight),
                decoration: InputDecoration(
                  labelText: _isWeight ? 'Kilos perdidos' : 'Piezas perdidas',
                  hintText: _isWeight ? 'Ej: 2.500' : 'Ej: 10',
                  border: const OutlineInputBorder(),
                ),
              ),
              ...
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motivo',
                  hintText: 'Vencido, dañado, excedente, etc.',
                  border: OutlineInputBorder(),
                ),
              ),
```
→ quantity gets `textInputAction: TextInputAction.next,`; reason gets `textInputAction: TextInputAction.done,` + `onFieldSubmitted: (_) => _registerLoss(),` (its button calls `_registerLoss` at `:343`).
- `lib/features/pos/ui/pos_screen.dart:1361-1383` (split mode: card field then cash field) → card gets `.next`, cash gets `.done` + `onFieldSubmitted: (_) => _submitSplit(),` (button calls `_submitSplit`).
- `lib/features/home/ui/back_office_screen.dart:1252-1282` (name, email, phone, PIN) → name/email/phone get `.next`; PIN gets `.done` + `onFieldSubmitted: (_) => _submit(),` (button calls `_submit` at `:1350`).
- `lib/features/settings/ui/settings_screen.dart:387-391` (business: name, currency, timezone) → name/currency `.next`, timezone `.done` + submit of that dialog (`_submit` at `:405`).
- `lib/features/settings/ui/settings_screen.dart:472-476` (store: name, address, phone) → name/address `.next`, phone `.done` + submit (`_submit` at `:494`).
- `lib/features/home/ui/desktop/business_config_screen.dart:135-139` (name, address, phone; its Crear button just pops) → name/address `.next`, phone `.done` with no `onFieldSubmitted` (nothing to call — see Don't touch).
- `lib/features/shift/ui/shift_screen.dart:425-437` (amount + comment controllers) → amount `.next`, comment `.done` + `onFieldSubmitted: (_) => _submit(),` (button calls `_submit` at `:449`).
- `lib/features/pos/ui/pos_screen.dart` weight dialog: weight field `.next` only when the chicken-count field is shown, chicken field `.done` + submit of that dialog (`_submit` of `_WeightQuantityDialogState`).
- `lib/features/poultry/ui/receive_chicken_screen.dart:94-103` (chickens + weight) → first `.next`, second `.done` + `onFieldSubmitted: (_) => _save(),` (button calls `_save` at `:113`).
- `lib/features/poultry/ui/poultry_config_screen.dart:178-250` (config fields) → all but the last `.next`, last `.done` + `onFieldSubmitted: (_) => _save(),` (button calls `_save` at `:274`).

## The fix

Article's `textInputAction` pattern per form above. Multiline exemption doesn't apply — all these fields are single-line.

## Steps

1. Apply the actions + submit wirings to the 10 forms above.
2. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "textInputAction" lib/features/losses/ui/losses_screen.dart lib/features/pos/ui/pos_screen.dart lib/features/home/ui/back_office_screen.dart lib/features/settings/ui/settings_screen.dart lib/features/home/ui/desktop/business_config_screen.dart lib/features/shift/ui/shift_screen.dart lib/features/poultry/ui/receive_chicken_screen.dart lib/features/poultry/ui/poultry_config_screen.dart` → 28 (losses 2, pos 4, back_office 4, settings 6, business_config 3, shift 2, receive_chicken 2, poultry_config 5)
- `grep -c "onFieldSubmitted" <same files>` → 9 (all but business_config's Crear-less dialog)

## Don't touch

- Login/products forms (already correct), single-field dialogs (search, closing cash, PIN pad), dynamic per-row quantity lists (transfers), and the store-create button that pops without saving (pre-existing behavior, out of scope).
- Never add `onEditingComplete` (it would replace the default next/done behavior per the article).
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- A listed submit method doesn't exist under that name (then wire the method the form's own submit button calls and report).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
