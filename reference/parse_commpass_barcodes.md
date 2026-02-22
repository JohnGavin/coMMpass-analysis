# Parse CoMMpass sample barcodes

Extracts patient ID, visit number, and tissue type from CoMMpass-style
sample barcodes (e.g., "MMRF_1234_1_BM" or longer GDC barcodes).

## Usage

``` r
parse_commpass_barcodes(barcodes)
```

## Arguments

- barcodes:

  Character vector of sample barcodes

## Value

Data frame with sample_id, patient_id, visit_number columns
