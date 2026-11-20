// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

const developerName = 'Nicola De Nicolais';
const developerEmail = 'ndn21dev@gmail.com';

/// Date shown as "last updated" in the privacy policy (in-app and
/// `PRIVACY.md`): change both together.
final privacyPolicyUpdatedAt = DateTime(2026, 11, 17);

/// Online privacy policy: the portfolio page, which is also the privacy URL
/// of the Google OAuth consent screen.
final uriPrivacyPolicy = Uri.parse(
  'https://ndenicolais.github.io/taskenda/privacy/',
);

/// Links of the Info screen.
/// Project page on the portfolio: also the link sent by "Share Taskenda".
final uriProjectPage = Uri.parse('https://ndenicolais.github.io/taskenda/');
final uriSourceCode = Uri.parse('https://github.com/ndenicolais/Taskenda');
final uriDeveloperGithub = Uri.parse('https://github.com/ndenicolais');
final uriContactMail = Uri(
  scheme: 'mailto',
  path: developerEmail,
  query: 'subject=Taskenda',
);
