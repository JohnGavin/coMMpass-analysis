# Classify cytogenetic risk group

Assigns risk group based on IMWG 2014 revised criteria: - High risk:
t(4;14), t(14;16), t(14;20), del(17p), gain(1q21) - Standard risk:
t(11;14), or none of the above

## Usage

``` r
classify_cytogenetic_risk(cyto)
```

## Arguments

- cyto:

  Data frame with cytogenetic marker columns

## Value

Character vector of risk classifications
