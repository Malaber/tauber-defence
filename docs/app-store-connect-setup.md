# App Store Connect and TestFlight setup

The delivery workflow is implemented but deliberately disabled until Apple and GitHub are
provisioned. Pull requests never upload. A successful `main` build uploads only after
`TESTFLIGHT_UPLOAD_ENABLED` is set to `true`; a manual upload reruns the complete CI gate first.

## App identity

- Product name: `Tauber Defence`
- Platform: iOS
- Minimum OS: iOS 18
- Bundle identifier: `de.malaber.tauberdefence`
- Initial marketing version: `0.1.0`
- Primary category: Games
- Product URL: `https://tauber-defence.malaber.de/`
- Support URL: `https://tauber-defence.malaber.de/support/`
- Privacy policy URL: `https://tauber-defence.malaber.de/privacy/`
- SKU suggestion: `tauber-defence-ios` (internal and not customer-visible)

The numeric Apple ID is assigned by App Store Connect and must not be guessed or confused with the
bundle identifier. Store it in the GitHub variable `APP_STORE_CONNECT_APP_ID` after the app record
exists.

## One-time Apple setup

1. In the Apple Developer account, accept current agreements. App Store Connect may block app
   creation until the Account Holder accepts them.
2. Under **Certificates, Identifiers & Profiles → Identifiers**, register an explicit App ID:
   - description: `Tauber Defence`
   - bundle ID: `de.malaber.tauberdefence`
   - capabilities: no optional capabilities for the vertical slice
3. Under **App Store Connect → Apps**, choose **+ → New App**:
   - platform: iOS
   - name: `Tauber Defence`
   - primary language: German or English (choose the language used for initial store metadata)
   - bundle ID: `de.malaber.tauberdefence`
   - SKU: `tauber-defence-ios`
   - user access: Full Access
4. Copy the numeric Apple ID from **App Information** into `APP_STORE_CONNECT_APP_ID`.
5. Create an **App Store Connect** distribution provisioning profile for this explicit App ID and
   download it. A valid team Apple Distribution certificate already used by another Malaber app can
   be reused; the provisioning profile cannot, because it is bound to this App ID.
6. Reuse the active Malaber App Store Connect team API key if it has Developer or App Manager access,
   or create a least-privilege team key under **Users and Access → Integrations → Team Keys**. Save
   the `.p8` immediately because Apple permits only one download.

No Game Center, in-app purchase, push notification, iCloud, or associated-domain entitlement is
needed for the first release.

## GitHub TestFlight environment

Create an Actions environment named `testflight`. Add deployment reviewers if a human approval is
desired before signing and upload.

Repository variables:

- `APP_STORE_CONNECT_APP_ID`: numeric Apple ID from App Store Connect.
- `IOS_MARKETING_VERSION`: optional; defaults to `0.1.0`.
- `APPLE_TEAM_ID`: optional; defaults to `VWKG94374J`.
- `IOS_BUNDLE_IDENTIFIER`: optional; defaults to `de.malaber.tauberdefence`.
- `TESTFLIGHT_UPLOAD_ENABLED`: leave unset during initial setup.

Environment secrets:

- `KEYCHAIN_PASSWORD`: random password used only for the runner's temporary keychain.
- `BUILD_CERTIFICATE_BASE64`: base64 Apple Distribution `.p12`.
- `P12_PASSWORD`: password used when the `.p12` was exported.
- `BUILD_PROVISION_PROFILE_BASE64`: base64 App Store Connect provisioning profile for
  `de.malaber.tauberdefence`.
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`: complete `.p8` contents, including header and footer.

On macOS, encode the two binary credentials as single-line base64:

```bash
base64 -i TauberDefence_AppStore.mobileprovision | pbcopy
base64 -i AppleDistribution.p12 | pbcopy
```

## GitHub Pages and DNS

The intended canonical hostname is `tauber-defence.malaber.de`. Before advertising the URLs:

1. In repository **Settings → Pages**, select **GitHub Actions** as the publishing source.
2. Set `tauber-defence.malaber.de` as the custom domain and enable HTTPS after the certificate is
   available.
3. At the DNS provider, create a CNAME record for `tauber-defence` pointing to
   `malaber.github.io`.
4. Keep `website/CNAME`, canonical metadata, `robots.txt`, and `sitemap.xml` on the same hostname.
5. Run the Pages workflow and verify the product, capabilities, support, and privacy URLs without
   redirects or certificate warnings.

The checked-in CNAME documents intent, but GitHub still requires the domain in repository settings.

## Store compliance

Before the first external build or App Review submission:

- Use the deployed product URL as the marketing URL, the support page as the Support URL, and the
  privacy page as the Privacy Policy URL.
- Answer App Privacy from shipped behavior. The initial app declares no tracking and no collected
  data, contains no account or backend, and keeps game simulation on device.
- Confirm `PrivacyInfo.xcprivacy` still matches every Apple required-reason API and third-party SDK.
- The generated Info.plist declares `ITSAppUsesNonExemptEncryption = NO`; revisit this before release
  if networking, encryption, or a third-party SDK is added.
- Supply iPhone and iPad landscape screenshots from the final release build.
- Describe the nonviolent framing accurately: defences apply pressure to a tolerance value and
  pigeons flee; they are not killed.
- Complete App Store age-rating and content-description questionnaires from actual content. Do not
  infer the final age rating in source documentation.
- Provide review notes explaining that all gameplay is available immediately, no sign-in or special
  account is needed, and the next wave begins with the on-screen wave control.

## First delivery

1. Merge green code and website changes into `main` after Apple, DNS, Pages, and GitHub environment
   setup is complete.
2. Optionally perform the local command-line upload documented in [delivery.md](delivery.md), or run
   **Actions → TestFlight → Run workflow** on `main` with `upload_to_testflight = true`.
3. After processing, complete export compliance and any missing beta metadata in App Store Connect.
4. Add the build to an internal testing group and install it on a physical iPhone and iPad.
5. Run the release smoke test, then set `TESTFLIGHT_UPLOAD_ENABLED=true`.

From then on, each successful, current `main` CI run archives and uploads automatically. A commit
superseded before upload is refused.
