
# as future expansion becomes a thing, look into `selectr::parse(selector)`
# https://github.com/sjp/selectr/blob/master/R/parser.R
# selectr:::parse("#a.warning > b.mine:not(.theres) d")[[1]]$show()
#> CombinedSelector[CombinedSelector[Class[Hash[Element[*]#a].warning] > Negation[Class[Element[b].mine]:not(Class[Element[*].theres])]] <followed> Element[d]]
## ^^ R6 output

SELECTOR_EVERYTHING <- "everything"
SELECTOR_REGULAR <- "regular"

SELECTOR_SPACE <- "space"
SELECTOR_CHILD <- "child"

selectorClass <- "htmltools.selector"
selectorListClass <- "htmltools.selector.list"
isSelector <- function(x) {
  inherits(x, selectorClass)
}
isSelectorList <- function(x) {
  inherits(x, selectorListClass)
}

# only handles id and classes
asSelector <- function(selector) {
  if (isSelector(selector) || isSelectorList(selector)) {
    return(selector)
  }

  # make sure it's a trimmed string
  selector <- txt_trim(paste0(selector, collapse = " "))

  if (txt_detect(selector, ",", fixed = TRUE)) {
    stop("CSS selectors that contain `,` aren't (yet) implemented.", call. = FALSE)
  }
  if (txt_detect(selector, "[", fixed = TRUE)) {
    stop("CSS selectors that contain `[` aren't (yet) implemented.", call. = FALSE)
  }
  if (txt_detect(selector, "~", fixed = TRUE)) {
    stop("CSS selectors that contain `~` aren't (yet) implemented.", call. = FALSE)
  }
  if (txt_detect(selector, "+", fixed = TRUE)) {
    stop("CSS selectors that contain `+` aren't (yet) implemented.", call. = FALSE)
  }
  if (txt_detect(selector, ":", fixed = TRUE)) {
    stop(
      "Pseudo CSS selectors (e.g., `:first-child`, `:not()`, etc)",
      " aren't (yet) implemented.",
      call. = FALSE
    )
  }

  # Check here to avoid inf recursion
  if (txt_detect(selector, ">", fixed = TRUE)) {
    # If there is a `>`, pad it with spaces
    if (txt_detect(selector, "(^>)|(>$)")) {
      stop(
        "Direct children selector, `>`, must not be the first element or last element",
        " in a css selector. Please add more selector information, such as `*`."
      )
    }
    # While there are any consecutive `> >` items...
    while(txt_detect(selector, ">\\s*>")) {
      # If there are any `>>`, replace them with `> * >`
      selector <- txt_replace_all(selector, ">\\s*>", "> * >")
    }

    # Split by `>` and convert to selectors
    # Alter parts (execpt first) to say they are a direct child
    # Return selector list
    selectorItems <- lapply(strsplit(selector, ">")[[1]], asSelector)
    selectorListItems <- Map(
      selectorItems,
      seq_along(selectorItems),
      f = function(selectorItem, i) {
        if (isSelector(selectorItem)) {
          if (i > 1) selectorItem$traversal <- SELECTOR_CHILD
          asSelectorList(selectorItem)
        } else {
          if (i > 1) selectorItem[[1]]$traversal <- SELECTOR_CHILD
          selectorItem
        }
      }
    )
    selectorList <- asSelectorList(
      unlist(selectorListItems, recursive = FALSE, use.names = FALSE)
    )
    return(selectorList)
  }

  # Split into a selector parts and recurse one more time
  if (txt_detect(selector, "\\s")) {
    selectorItems <- lapply(strsplit(selector, "\\s+")[[1]], asSelector)
    selectorList <- asSelectorList(selectorItems)
    return(selectorList)
  }

  # https://www.w3.org/TR/selectors-3/#selectors

  type <- NULL
  traversal <- SELECTOR_SPACE
  element <- NULL
  id <- NULL
  classes <- NULL

  if (isTRUE(selector == "*")) {
    type <- SELECTOR_EVERYTHING
  } else {
    type <- SELECTOR_REGULAR

    ## Not needed as the regex values below work around this.
    # # if there is more than a `*`, such as `*.warning`, treat as `.warning`
    # if (txt_detect(selector, "^\\*"))
    #   selector <- sub("^\\*", "", selector)
    #   if (grepl("^\\*", selector)) {
    #     stop("malformed css selector. Found at least two `**` that were not separated by a space")
    #   }
    # }

    elementRegex <- "^[a-zA-Z0-9]+"
    element <- txt_match_first(selector, elementRegex)
    if (!is.null(element)) {
      selector <- txt_remove(selector, elementRegex)
    }

    ## https://www.w3.org/TR/CSS21/syndata.html#value-def-identifier
    ##  In CSS, identifiers (including element names, classes, and IDs in selectors) can contain only the characters [a-zA-Z0-9] and ISO 10646 characters U+00A0 and higher, plus the hyphen (-) and the underscore (_); they cannot start with a digit, two hyphens, or a hyphen followed by a digit. Identifiers can also contain escaped characters and any ISO 10646 character as a numeric code (see next item). For instance, the identifier "B&W?" may be written as "B\&W\?" or "B\26 W\3F".
    # # define simpler (maybe not accurate) regex
    # id_regex <- "^#[^#.:[\\s]+" # `#` then everything that isn't a `#`, `.`, `:`, or white space
    # class_regex <- "^\\.[^#.:[\\s]+" # `.` then everything that isn't a `.`, `:`, or white space

    tmpId <- txt_match_first(selector, "#[^.:[]+")
    if (!is.null(tmpId)) {
      id <- txt_remove(tmpId, "^#")
      selector <- txt_remove(selector, tmpId, fixed = TRUE)
    }

    classes <- txt_remove(txt_match_all(selector, "\\.[^.:[]+"), "^\\.")
    if (length(classes) == 0) {
      classes <- NULL
    }
    # if (!is.null(classes)) {
    #   selector <- txt_remove(selector, "\\.[^.:[]+")
    # }
  }

  structure(class = selectorClass, list(
    element = element,
    id = id,
    classes = classes,
    type = type,
    traversal = traversal
  ))
}


asSelectorList <- function(selector) {
  if (isSelectorList(selector)) {
    return(selector)
  }
  if (is.character(selector)) {
    selector <- asSelector(selector)
  }
  if (isSelector(selector)) {
    selector <- list(selector)
  }
  if (!is.list(selector)) {
    stop("Do not know how to convert non list object into a `htmltools.selector.list`")
  }

  isSelectorVals <- vapply(selector, isSelector, logical(1))
  if (!all(isSelectorVals)) {
    stop("Can only convert a list of selectors to a `htmltools.selector.list`")
  }
  structure(class = selectorListClass, selector)
}

#' @export
format.htmltools.selector <- function(x, ...) {
  paste0(
    c(
      if (x$traversal == SELECTOR_CHILD) "> ",
      if (x$type == SELECTOR_EVERYTHING) {
        "*"
      } else {
        paste0(c(
          x$element,
          if (!is.null(x$id)) paste0("#", x$id),
          if (!is.null(x$classes)) paste0(".", x$classes)
        ))
      }
    ),
    collapse = ""
  )
}
#' @export
format.htmltools.selector.list <- function(x, ...) {
  paste0(as.character(lapply(x, format, ...)), collapse = " ")
}

#' @export
print.htmltools.selector <- function(x, ...) {
  cat("// htmltools css selector\n")
  cat(format(x, ...), "\n")
}
#' @export
print.htmltools.selector.list <- function(x, ...) {
  cat("// htmltools css selector list\n")
  cat(format(x, ...), "\n")
}



# When `fixed = TRUE`, `sub()`, `gsub()`, `grepl()` perform ~4x faster
# #> bench::mark(grepl("* ", "A B * C"), grepl("* ", "A B * C", fixed = TRUE))
#   expression                               min median
#   <bch:expr>                           <bch:t> <bch:>
# 1 grepl("* ", "A B * C")                3.91µs 5.23µs
# 2 grepl("* ", "A B * C", fixed = TRUE)   1.1µs 1.34µs
txt_replace <- function(text, pattern, replacement, fixed = FALSE) {
  sub(pattern = pattern, replacement = replacement, x = text, perl = !fixed, fixed = fixed)
}

txt_replace_all <- function(text, pattern, replacement, fixed = FALSE) {
  gsub(pattern = pattern, replacement = replacement, x = text, perl = !fixed, fixed = fixed)
}

txt_remove <- function(x, pattern, ...) {
  txt_replace(x, pattern, "", ...)
}
txt_remove_all <- function(x, pattern, ...) {
  txt_replace_all(x, pattern, "", ...)
}

trim_leading <- function(text) {
  txt_remove_all(text, pattern = "^\\s+")
}

trim_trailing <- function(text) {
  txt_remove_all(text, pattern = "\\s+$")
}

txt_trim <- function(text, side = "both") {
  if (side == "both" || side == "left") {
    text <- trim_leading(text)
  }
  if (side == "both" || side == "right") {
    text <- trim_trailing(text)
  }
  text
}

txt_detect <- function(text, pattern, fixed = FALSE) {
  grepl(pattern = pattern, x = text, perl = !fixed, fixed = fixed)
}

# finds first, NOT all
txt_match_first <- function(x, pattern, ...) {
  regInfo <- regexpr(pattern, x, ...)
  if (length(regInfo) == 1 && regInfo == -1) {
    return(NULL)
  }

  regmatches(x, regInfo)
}

# return a vector of matches or NULL
txt_match_all <- function(x, pattern, ...) {
  if (length(x) != 1) {
    stop("`x` must have a length of 1")
  }
  regInfo <- gregexpr(pattern, x, ...)
  first <- regInfo[[1]]
  if (length(first) == 1 && first == -1) {
    return(NULL)
  }

  regmatches(x, regInfo)[[1]]
}
