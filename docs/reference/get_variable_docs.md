# Get Extended Documentation for a Variable

Returns detailed documentation for a specific variable, including
scientific context, calculation methods, and usage notes.

## Usage

``` r
get_variable_docs(variable)
```

## Arguments

- variable:

  Character string naming the variable to document

## Value

A list with elements: variable, description, scientific_context,
calculation, usage_notes, references

## Examples

``` r
docs <- get_variable_docs("age_at_diagnosis")
cat(docs$usage_notes)
#> CRITICAL: GDC stores age in DAYS, not years. Always divide by 365.25 before analysis or display. Values typically range from ~10,000 to ~35,000 days.
```
