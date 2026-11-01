# Lazara comparison image provenance

The four source screenshots were supplied by the repository owner for public
presentation on 2026-11-01. The matching viewpoints establish the two sets:

| Set | State | File | SHA-256 |
|---|---|---|---|
| Castle | OFF | `source/set-1-off.png` | `36B6D24A649CDAC44C8611E9F9EF12037B926F8DD9DAEF09367B24E7F44BE8B4` |
| Castle | ON | `source/set-1-on.png` | `FB2C048199EC29CD542F3DA33B13F1F1B63DC2D3B7C2F90EE11791349AFF913D` |
| Eclipse | OFF | `source/set-2-off.png` | `40F0136AEF96DBA9FAC2CD485577D32934F1EFB04435C93C14168790C617F666` |
| Eclipse | ON | `source/set-2-on.png` | `1BB2B1BFD8B1482242F62A8D52BBC3564B50F8829311DF852FF2939BEFE9EAEC` |

Each source is a 2560x1440 RGB PNG. The stitch retains every screenshot at its
native dimensions and places labels in separate 96-pixel bars; no source pixel
is resized, cropped, or overpainted.

The generated 5120x3072 stitch has SHA-256
`7A33DB7283C66C25297B8AB62A0F336C30E54024FF176E98D8B5872F0FD84FAE`.
An independent decoded-pixel comparison matched all four source regions.

Rebuild from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build_comparison_stitch.ps1
```

The screenshots are presentation evidence supplied for this repository. Their
inclusion does not assert ownership of the depicted game's art and does not put
that art under the Camera Obscura MIT software license.
