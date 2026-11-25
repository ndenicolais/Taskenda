// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'passkey_client.dart';

/// Neither `dart:io` nor `dart:js_interop`: never the case on Android and
/// web.
PasskeyClient createPasskeyClient() =>
    throw const PasskeyUnavailableException('Unsupported platform');
