# Lazara comparison image provenance

The eight source screenshots were supplied by the repository owner for public
presentation on 2026-11-01. The matching viewpoints establish three comparison
sets and one FlexAgX showcase pair:

| Set | State | File | SHA-256 |
|---|---|---|---|
| Castle | OFF | `source/set-1-off.png` | `36B6D24A649CDAC44C8611E9F9EF12037B926F8DD9DAEF09367B24E7F44BE8B4` |
| Castle | ON | `source/set-1-on.png` | `FB2C048199EC29CD542F3DA33B13F1F1B63DC2D3B7C2F90EE11791349AFF913D` |
| Eclipse | OFF | `source/set-2-off.png` | `40F0136AEF96DBA9FAC2CD485577D32934F1EFB04435C93C14168790C617F666` |
| Eclipse | ON | `source/set-2-on.png` | `1BB2B1BFD8B1482242F62A8D52BBC3564B50F8829311DF852FF2939BEFE9EAEC` |
| Snow fortress | OFF | `source/set-3-off.png` | `0A76391B6C55E6EC7D6E41596D92F87E5E0810E29EA2AC2B46D907B21453D902` |
| Snow fortress | ON | `source/set-3-on.png` | `5A7751C78E8B531C09312D779429C5040134C499137C633B8BE070970EEA0F46` |
| FlexAgX showcase | View 1 | `source/flexagx-view-1.png` | `B7F706E29F79C9A660DCD13F32FFF15A04A81517204D07A232B6373CBE8DDC06` |
| FlexAgX showcase | View 2 | `source/flexagx-view-2.png` | `001B4A7BCE59ADBE42CABAB6FEE4B81FDA30D9F05B1075BC9A35B4CF8D695425` |

Each source is a 2560x1440 RGB PNG.

The original two-set stitch retains Sets 1 and 2 at native dimensions and
places labels in separate 96-pixel bars; no source pixel is resized, cropped,
or overpainted.

The generated 5120x3072 stitch has SHA-256
`7A33DB7283C66C25297B8AB62A0F336C30E54024FF176E98D8B5872F0FD84FAE`.
An independent decoded-pixel comparison matched all four source regions.

The Set 3 bidirectional split stitch places two 2560x1440 panels side by side:

- panel 1 is the ON image's left half followed by the OFF image's right half;
- panel 2 is the OFF image's left half followed by the ON image's right half.

Every pixel from both source images appears exactly once in the four half-image
regions. Labels occupy a separate 96-pixel bar. The generated 5120x1536 stitch
has SHA-256
`93BFD22DD7C7D67BAABF0F154F37C69BCFC19E1F57505507C88E94B6FAD8DC20`.
Independent decoded-region validation matched all four source halves.

The FlexAgX showcase places View 1 on the left and View 2 on the right at
native resolution. No source pixel is resized, cropped, or overpainted. The
generated 5120x1440 stitch has SHA-256
`DD93837BA11FC542CAA55881E736F1136E11F9F7CFBB346109D2DA9B91432C8F`.
Independent decoded-region validation matched both complete source images.
The [FlexAgX repository](https://github.com/El-Greco1541/FlexAgX) is linked for
showcase credit and is not vendored into this package.

Rebuild from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build_comparison_stitch.ps1
powershell -ExecutionPolicy Bypass -File .\tools\build_bidirectional_split_stitch.ps1
powershell -ExecutionPolicy Bypass -File .\tools\validate_bidirectional_split_stitch.ps1
powershell -ExecutionPolicy Bypass -File .\tools\build_flexagx_showcase.ps1
powershell -ExecutionPolicy Bypass -File .\tools\validate_flexagx_showcase.ps1
```

The screenshots are presentation evidence supplied for this repository. Their
inclusion does not assert ownership of the depicted game's art and does not put
that art under the Camera Obscura MIT software license.
