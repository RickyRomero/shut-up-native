## Shut Up

[Shut Up][homepage] is an open source project for blocking comment sections in all mainstream web browsers.

This is a brand-new modern version of Shut Up for Safari on macOS, which replaces the legacy Safari extension from 2010. A [WebExtension version of Shut Up][shut-up-webextension] is available which supports Chrome, Firefox, Edge, and Opera. A deprecated version for Safari on [iOS and iPadOS][shut-up-ios] is also available.

This app leverages [shutup.css][shutup-css] by [Steven Frank][site-steven] and contributors, which is used with permission.

## Installation

If you're simply looking to _install_ Shut Up, these are the links you're looking for:

- [Shut Up for Chrome][ext-chrome]
- [Shut Up for Edge][ext-edge]
- [Shut Up for Firefox][ext-firefox]
- [Shut Up for Opera][ext-opera]
- [Shut Up for Safari][ext-safari] (Shared link for macOS, iOS, and iPadOS)

## Minimum Requirements

Shut Up requires macOS Monterey or newer.

## Development

If you want to help develop or translate Shut Up into your language, you need at least Xcode 16.

## Setting Up Git Hooks

This project uses Git hooks to automatically format Swift code before commits. To configure Git to use the shared hooks provided in this repository, run the following command in the root of your project after cloning:

```sh
git config core.hooksPath githooks
```

## Translations

Translations for the main app must be added in two places:

- For the main app: `Shut Up -> Shut Up -> Views -> Main (Strings)`
- For all other strings: `Shut Up -> Shared -> Localizable`

Translations for the Info.plist strings must be added here:

- For Shut Up: `Shut Up -> Shut Up -> InfoPlist`
- For Shut Up Core: `Shut Up -> Shut Up Core -> InfoPlist`
- For Shut Up Helper `Shut Up -> Shut Up Helper -> InfoPlist`

## License

Shut Up is available under the terms of the [MIT License][license].

[homepage]: https://rickyromero.com/shutup/ "Shut Up Homepage"
[shut-up-ios]: https://github.com/RickyRomero/shut-up-ios "iOS version of Shut Up"
[shut-up-webextension]: https://github.com/RickyRomero/shut-up-webextension "WebExtension version of Shut Up"
[license]: LICENSE.md "MIT License"
[shutup-css]: https://github.com/panicsteve/shutup-css "shutup-css on GitHub"
[site-steven]: https://stevenf.com "Steven Frank's personal website"
[ext-chrome]: https://chrome.google.com/webstore/detail/oklfoejikkmejobodofaimigojomlfim?hl=en-US&gl=US "Shut Up on the Chrome Web Store"
[ext-safari]: https://apps.apple.com/app/id1015043880 "Shut Up on the App Store"
[ext-firefox]: https://addons.mozilla.org/en-US/firefox/addon/shut-up-comment-blocker/ "Shut Up at Firefox Add-ons"
[ext-edge]: https://microsoftedge.microsoft.com/addons/detail/giifliakcgfijgkejmenachfdncbpalp "Shut Up at Edge Add-ons"
[ext-opera]: https://github.com/panicsteve/shutup-css#installation-on-opera "Installation on Opera"
