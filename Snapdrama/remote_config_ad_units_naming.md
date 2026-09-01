# Firebase Remote Config — ad units

## test_id switch (root of `appVersionCode2` JSON)

| Value | Effect |
|---|---|
| `"test_id": true` | Use `publisher_ad_units_manage_test` (Google sample / test units) |
| `"test_id": false` | Use `publisher_ad_units_manage` (live AdMob units) |

**Play Store live:** set `"test_id": false` and publish.

**Manifest App ID (live):** `ca-app-pub-2256714742649688~6945348183`

## After-login ads master switch

| RC key | Effect |
|---|---|
| `after_login_ads_show` | `false` = hide **all** Home + post-login ads (banner, native, interstitial, rewarded, Exo IMA). Splash/onboarding ads still work. `true` = show them. |

Also recommended in same JSON:
- `interstitial_ad_show`: false
- `exo_player_ima_show`: false

## Google test IDs

| Format | ID |
|---|---|
| App ID (Manifest legacy test) | `ca-app-pub-3940256099942544~3347511713` |
| Native | `ca-app-pub-3940256099942544/2247696110` |
| Interstitial | `ca-app-pub-3940256099942544/1033173712` |
| App Open | `ca-app-pub-3940256099942544/9257395921` |
| Banner | `ca-app-pub-3940256099942544/9214589741` |
| Rewarded | `ca-app-pub-3940256099942544/5224354917` |

## Onboarding key map

| Sheet name | RC key |
|---|---|
| splash native new | `splash_native` |
| splash native old | `splash_native_old` |
| splash inter new | `splash_inter` |
| splash inter old | `splash_inter_old` |
| native-lfo1-1 | `lfo1_native` |
| native-lfo1-2 | `lfo1_native_2` |
| native-lfo2-1 | `lfo2_native` |
| native-lfo2-2 | `lfo2_native_2` |
| native-lfo2-3 | `lfo2_native_3` |
| native-ob1-1 | `onboard_1_native` |
| native-ob1-2 | `onboard_1_native_2` |
| native-ob2-1 | `onboard_2_native` |
| native-ob2-2 | `onboard_2_native_2` |
| native-ob3-1 | `onboard_3_native` |
| native-ob3-2 | `onboard_3_native_2` |
| native-ob3-3 | `onboard_3_native_3` |
| native-ob4-1 | `onboard_4_native` |
| native-ob4-2 | `onboard_4_native_2` |
| inter-ob5 | `inter_onboard` |

Parameter key = `appVersionCode` + `versionCode` (e.g. `appVersionCode2` / `appVersionCode3`).
