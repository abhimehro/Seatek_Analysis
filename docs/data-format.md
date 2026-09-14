# Seatek sensor data format

`Updated_Seatek_Analysis.R` reads **headerless** whitespace-separated text files
and writes Excel/CSV summaries under `Data/` (outputs are gitignored).

## Pipeline inputs (tracked)

| Path | Series | Filename pattern |
| --- | --- | --- |
| `Data/SS_Yxx.txt` | 28 | `SS_Y01.txt` … `SS_Y14.txt` |

`Updated_Seatek_Analysis.R` matches only `^SS_Y[0-9]{2}\\.txt$` under `Data/`.
It does **not** load Series 26 files.

`Data/` is the only tracked source for Series 28 `SS_Y*.txt` inputs. Keep raw
Series 28 inputs there so the production pipeline and repository documentation
share one canonical location.

## Related tracked data (not read by this R pipeline)

| Path | Series | Filename pattern |
| --- | --- | --- |
| `Series_26/Raw_Data/Text_Files/S26_Yxx.txt` | 26 | `S26_Y*.txt` |

## Columns

`fread(..., header = FALSE)` expects **at least 33 columns**:

1. `Sensor01` … `Sensor32` (up to 32 sensor columns; extra columns dropped)
2. `Timestamp` — numeric epoch seconds, or already `POSIXct`

Files with fewer than 33 columns warn but still load.

## Outputs (regenerate; do not commit)

- `Data/SS_Yxx.xlsx` (Series 28 year workbooks)
- `Data/Seatek_Summary.xlsx` / `Seatek_Summary*.csv`

Series 26 Excel under `Series_26/` is from older/manual processing, not this R
pipeline.

See `README.md` repository structure and `AGENTS.md` for the R/test commands.
