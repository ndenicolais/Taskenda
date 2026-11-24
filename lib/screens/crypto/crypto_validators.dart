// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import '../../l10n/app_localizations.dart';

/// Minimum length of a new encryption code.
const minPassphraseLength = 8;

/// A new encryption code (setup, recovery): at least [minPassphraseLength]
/// characters. Not trimmed: spaces are part of the code.
String? validateNewPassphrase(AppLocalizations l, String? v) {
  if (v == null || v.isEmpty) return l.cryptoPassphraseEmpty;
  if (v.length < minPassphraseLength) {
    return l.cryptoPassphraseTooShort(minPassphraseLength);
  }
  return null;
}

String? validatePassphraseConfirmation(
  AppLocalizations l,
  String? v,
  String passphrase,
) => v != passphrase ? l.cryptoPassphraseMismatch : null;

/// The code typed to unlock: only required (its length is the account's).
String? validatePassphrase(AppLocalizations l, String? v) =>
    v == null || v.isEmpty ? l.cryptoPassphraseEmpty : null;
