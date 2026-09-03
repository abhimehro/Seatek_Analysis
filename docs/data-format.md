# Seatek sensor data format

`Updated_Seatek_Analysis.R` reads **headerless** whitespace-separated text
files and writes Excel/CSV summaries under `Data/` (outputs are gitignored).

## Primary inputs (tracked)

| Path | Series | Filename pattern |
|------|--------|------------------|
| `Data/SS_Yxx.txt` | 28 | `SS_Y01.txt` … `SS_Y14.txt` |
| `Data/S26_Yxx.txt` | 26 | `S26_Y*.txt` |

`Data/` is the only tracked source for Series 28 `SS_Y*.txt` inputs. Keep raw
Series 28 inputs there so the production pipeline and repository documentation
share one canonical location.

## Columns

`fread(..., header = FALSE)` expects **at least 33 columns**:

1. `Sensor01` … `Sensor32` (up to 32 sensor columns; extra columns dropped)
2. `Timestamp` — numeric epoch seconds, or already `POSIXct`

Files with fewer than 33 columns warn but still load.

## Outputs (regenerate; do not commit)

- `Data/SS_Yxx.xlsx`, `Data/S26_Yxx.xlsx`
- `Data/Seatek_Summary.xlsx` / `Seatek_Summary*.csv`

See `README.md` repository structure and `AGENTS.md` for the R/test commands.
