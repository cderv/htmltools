
makeTags <- function(text1, text2) {
  inputTags <- div(
    class = "outer",
    tagList(
      div(
        class = "inner",
        a(href="example.com", "`a` ", list(strong(text1), em(p(text2))), " text."),
      ),
      span(
        class = "sibling",
        "sibling text"
      )
    )
  )

  inputTags <- span(list(inputTags, inputTags))
  inputTags
}

test_that("error checks", {
  expect_error(asSelector("div, span"), "contain `,`")
  expect_error(asSelector("div[foo]"), "contain `[`", fixed = TRUE)
  expect_error(asSelector("div:text"), "Pseudo CSS selectors")
})


test_that("selector parses string", {
  selector <- asSelector("h1#myId-value.class-name .child-class#child-id_value")

  expect_equal(
    format(selector),
    "h1#myId-value.class-name #child-id_value.child-class"
  )
})

test_that("* checks", {
  expect_equal(format(asSelector(" * ")), "*")
  expect_equal(format(asSelector(" *.class-name")), ".class-name")
  expect_s3_class(asSelector(" * "), selectorClass)
})


test_that("> checks", {
  expect_error(asSelector("> div"), "first element")
  expect_error(asSelector("div >"), "last element")
  expect_error(asSelectorList("> div"), "first element")
  expect_error(asSelectorList("div >"), "last element")

  expect_equal(format(asSelector("div>span")), "div > span")
  expect_equal(format(asSelector("div>>span")), "div > * > span")
})





# x <- div(class = "foo", "text 1",
#   div(class = "bar", "text 2"),
#   div(class = "bar", "text 3",
#     span("more text")
#   )
# )
# y <- x
# x <- x[1:length(x)]
# mutate_in_place(x)
# x %>% find(".bar", function(item) { toupper(x$children); item })
# y <- x %>% el_find(".bar") %>% el_find(".x") %>% el_mutate(function(x) toupper(x$children))
# x %>% find(".bar") %>% addClass("abc")
# x %>% find(".bar") %>% removeClass("abc")
# x %>% find(".bar") %>% attr(`data-x` = 123)
# x %>% find(".bar") %>% css(color = "red")
# actionButton("x", "X") %>% removeClass("btn-default") %>% addClass("btn-primary")
# x <- actionButton("x", "X")
# x$attribs$class <- sub("btn-default", "btn-primary", x$attribs$class)
# removeClass.shiny.tag <- function(x, class) {
#   ...
# }
# x <- div(
#   actionButton("x", "X")
# )
# # Selection types:
# #  - tags
# #  - classes
# #  - ID
# #  - descendent   ".btn .x"
# # Future:
# #  - direct child ".btn > .x"
# #
# # Tag functions:
# #  - delay execution, wrap them somehow
# #  - need to know we have a way forward
# x %>% el_select(".btn") %>% el_remove_class("btn-default") %>% el_add_class("btn-primary")
# x %>% find(".btn") %>% { . %>% removeClass("btn") %>% addClass("btn-primary") }
# x$select(".btn")$removeClass("btn-default")$addClass("btn-primary")
# `$.shiny.tag` <- function(x, name, ...) {
#   el_fns[[name]](x, ...)
# }
