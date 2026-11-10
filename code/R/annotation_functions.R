# Shared helpers for ";"-separated annotation strings.

# Unique, sorted, nonempty entries of the ";"-separated values, joined by
# `collapse`.
filter_collapse <- function(annotation_data, collapse = ";") {
  annotation_data <- annotation_data %>%
    paste0(collapse = ";") %>%
    stringr::str_split_1(";") %>%
    unique() %>%
    sort()

  annotation_data <- annotation_data[annotation_data != ""]

  if (length(annotation_data) == 0) {
    return("")
  }

  paste0(annotation_data, collapse = collapse)
}

# Apply filter_collapse() to each element of an annotation column.
filter_column <- function(annotation_data, collapse = ";") {
  sapply(annotation_data, filter_collapse, collapse = collapse) %>%
    unname()
}
