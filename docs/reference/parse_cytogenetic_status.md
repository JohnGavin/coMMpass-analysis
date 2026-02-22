# Parse cytogenetic status values to standardized categories

Converts various representations of cytogenetic results (Yes/No, 1/0,
Positive/Negative, TRUE/FALSE) to a consistent factor.

## Usage

``` r
parse_cytogenetic_status(x)
```

## Arguments

- x:

  Character or numeric vector of cytogenetic status values

## Value

Character vector with values "positive", "negative", or NA
