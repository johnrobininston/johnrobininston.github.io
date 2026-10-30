# Payoff diagrams for the topic notes, drawn as inline SVG inside a Bootstrap
# carousel. Colors come from CSS variables keyed on body.quarto-light /
# body.quarto-dark, so the plots follow the site's light/dark toggle (a
# static knitr image cannot).
#
# Usage in a note (chunk options: echo: false, results: asis):
#
#   source("../assets/payoff-plots.R")
#   payoff_carousel("my-id", list(
#     payoff_slide("Long call", "Buy a call at \\(K\\).",
#                  function(s) pmax(s - 100, 0), 100, "K")
#   ))

pp_css <- "
.pp-carousel { max-width: 540px; margin: 1.5rem auto; position: relative; }
body.quarto-light .pp-carousel {
  --pp-line: #1e66f5; --pp-fill: rgba(30, 102, 245, 0.14);
}
body.quarto-dark .pp-carousel {
  --pp-line: #8caaee; --pp-fill: rgba(140, 170, 238, 0.18);
}
.pp-carousel svg { display: block; width: 100%; height: auto; }
.pp-carousel svg text { fill: currentColor; font-family: inherit; }
.pp-carousel .pp-line {
  fill: none; stroke: var(--pp-line); stroke-width: 4;
  stroke-linejoin: round; stroke-linecap: round;
}
.pp-carousel .pp-area { fill: var(--pp-fill); stroke: none; }
.pp-carousel .pp-thin { stroke-width: 2.5; }
.pp-carousel .pp-dot { fill: var(--pp-line); stroke: none; }
.pp-carousel .pp-axis { stroke: currentColor; stroke-width: 1.5; opacity: 0.7; }
.pp-carousel .pp-grid {
  stroke: currentColor; stroke-width: 1; stroke-dasharray: 4 4; opacity: 0.3;
}
.pp-carousel .pp-caption { text-align: center; padding: 0 2.5rem; min-height: 5.5rem; }
.pp-carousel .pp-title { font-weight: 600; font-size: 1.1rem; margin-bottom: 0.25rem; }
.pp-carousel .carousel-indicators {
  position: static; margin: 0.25rem 0 0; justify-content: center;
}
.pp-carousel .carousel-indicators [data-bs-target] {
  background-color: currentColor; width: 9px; height: 9px;
  border: 0; border-radius: 50%; margin: 0 5px; opacity: 0.3;
}
.pp-carousel .carousel-indicators .active { opacity: 0.9; }
.pp-carousel .carousel-control-prev,
.pp-carousel .carousel-control-next {
  width: 2.5rem; height: 60%; top: 0; color: inherit; opacity: 0.5;
}
.pp-carousel .carousel-control-prev:hover,
.pp-carousel .carousel-control-next:hover { opacity: 1; }
.pp-carousel .pp-arrow { font-size: 2.5rem; line-height: 1; }
"

# Escape text for use inside SVG.
pp_label <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  gsub("<", "&lt;", x, fixed = TRUE)
}

# A tick label such as "K" or "K1" with the index as a subscript.
pp_tick <- function(label) {
  m <- regmatches(label, regexec("^([A-Za-z]+)([0-9]*)$", label))[[1]]
  if (length(m) == 3 && nzchar(m[3])) {
    sprintf("%s<tspan dy=\"5\" font-size=\"11\">%s</tspan>", m[2], m[3])
  } else {
    pp_label(label)
  }
}

# One SVG payoff diagram. `f` is a vectorized payoff function of the terminal
# price, piecewise linear with kinks only at `strikes`.
payoff_svg <- function(f, strikes, labels, s_range = c(50, 150)) {
  x0 <- 60; x1 <- 370; y0 <- 25; y1 <- 215
  s <- sort(unique(c(s_range, strikes)))
  y <- f(s)
  pad <- 0.2 * diff(range(c(0, y)))
  lo <- min(c(0, y)) - pad
  hi <- max(c(0, y)) + pad
  px <- function(v) x0 + (v - s_range[1]) / diff(s_range) * (x1 - x0)
  py <- function(v) y1 - (v - lo) / (hi - lo) * (y1 - y0)
  pts <- function(xs, ys) paste(sprintf("%.1f,%.1f", xs, ys), collapse = " ")

  curve <- pts(px(s), py(y))
  area <- paste(curve, sprintf("%.1f,%.1f %.1f,%.1f", x1, py(0), x0, py(0)))

  grid <- sprintf(
    "<line class=\"pp-grid\" x1=\"%.1f\" y1=\"%d\" x2=\"%.1f\" y2=\"%d\"/>",
    px(strikes), y0, px(strikes), y1
  )
  ticks <- sprintf(
    "<text x=\"%.1f\" y=\"236\" text-anchor=\"middle\" font-size=\"14\">%s</text>",
    px(strikes), vapply(labels, pp_tick, "")
  )

  paste0(
    "<svg viewBox=\"0 0 400 270\" role=\"img\" ",
    "aria-label=\"Payoff diagram\" xmlns=\"http://www.w3.org/2000/svg\">",
    paste(grid, collapse = ""),
    sprintf("<polygon class=\"pp-area\" points=\"%s\"/>", area),
    sprintf("<line class=\"pp-axis\" x1=\"%d\" y1=\"%d\" x2=\"%d\" y2=\"%d\"/>",
            x0, y0, x0, y1),
    sprintf("<line class=\"pp-axis\" x1=\"%d\" y1=\"%.1f\" x2=\"%d\" y2=\"%.1f\"/>",
            x0, py(0), x1, py(0)),
    sprintf("<polyline class=\"pp-line\" points=\"%s\"/>", curve),
    paste(ticks, collapse = ""),
    sprintf("<text x=\"%d\" y=\"%.1f\" text-anchor=\"end\" font-size=\"13\">0</text>",
            x0 - 8, py(0) + 4),
    sprintf("<text x=\"%d\" y=\"258\" text-anchor=\"end\" font-size=\"15\">",
            x1),
    "S<tspan dy=\"5\" font-size=\"11\">T</tspan></text>",
    sprintf("<text transform=\"translate(22 %.1f) rotate(-90)\" ", (y0 + y1) / 2),
    "text-anchor=\"middle\" font-size=\"15\">Payoff</text>",
    "</svg>"
  )
}

# One SVG line plot of a series (x, y). `points = TRUE` marks each
# observation, for discrete-time series. `xlab`/`ylab` may contain markup
# such as "x<tspan dy=\"5\" font-size=\"11\">t</tspan>".
series_svg <- function(x, y, points = FALSE, xlab = "t", ylab = "x") {
  x0 <- 44; x1 <- 390; y0 <- 10; y1 <- 208
  xt <- pretty(range(x), 5); xt <- xt[xt >= min(x) & xt <= max(x)]
  yt <- pretty(range(y), 4)
  xr <- range(x); yr <- range(c(y, yt))
  px <- function(v) x0 + (v - xr[1]) / diff(xr) * (x1 - x0)
  py <- function(v) y1 - (v - yr[1]) / diff(yr) * (y1 - y0)
  pts <- paste(sprintf("%.1f,%.1f", px(x), py(y)), collapse = " ")
  grid <- sprintf(
    "<line class=\"pp-grid\" x1=\"%d\" y1=\"%.1f\" x2=\"%d\" y2=\"%.1f\"/>",
    x0, py(yt), x1, py(yt))
  xl <- sprintf(
    "<text x=\"%.1f\" y=\"223\" text-anchor=\"middle\" font-size=\"11\">%s</text>",
    px(xt), format(xt))
  yl <- sprintf(
    "<text x=\"%d\" y=\"%.1f\" text-anchor=\"end\" font-size=\"11\">%s</text>",
    x0 - 6, py(yt) + 4, format(yt))
  dots <- if (points) {
    paste(sprintf("<circle class=\"pp-dot\" cx=\"%.1f\" cy=\"%.1f\" r=\"2.5\"/>",
                  px(x), py(y)), collapse = "")
  } else ""
  paste0(
    "<svg viewBox=\"0 0 400 250\" role=\"img\" ",
    "aria-label=\"Time series plot\" xmlns=\"http://www.w3.org/2000/svg\">",
    paste(grid, collapse = ""),
    sprintf("<line class=\"pp-axis\" x1=\"%d\" y1=\"%d\" x2=\"%d\" y2=\"%d\"/>",
            x0, y0, x0, y1),
    sprintf("<line class=\"pp-axis\" x1=\"%d\" y1=\"%d\" x2=\"%d\" y2=\"%d\"/>",
            x0, y1, x1, y1),
    sprintf("<polyline class=\"pp-line pp-thin\" points=\"%s\"/>", pts),
    dots,
    paste(xl, collapse = ""), paste(yl, collapse = ""),
    sprintf("<text x=\"%d\" y=\"243\" text-anchor=\"end\" font-size=\"13\">%s</text>",
            x1, xlab),
    sprintf("<text transform=\"translate(12 %.1f) rotate(-90)\" ", (y0 + y1) / 2),
    sprintf("text-anchor=\"middle\" font-size=\"13\">%s</text>", ylab),
    "</svg>"
  )
}

# A carousel slide for a series plot, for use with payoff_carousel().
series_slide <- function(title, caption, x, y, points = FALSE,
                         xlab = "t", ylab = "x") {
  list(title = title, caption = caption,
       svg = series_svg(x, y, points, xlab, ylab))
}

# A carousel slide: title, caption (may contain \\( \\) math) and the payoff.
payoff_slide <- function(title, caption, f, strikes, labels = "K") {
  list(title = title, caption = caption,
       svg = payoff_svg(f, strikes, labels))
}

# Print a carousel of slides as a raw HTML block (use with results: asis).
payoff_carousel <- function(id, slides) {
  n <- length(slides)
  active <- function(i) if (i == 1) " active" else ""
  indicators <- vapply(seq_len(n), function(i) {
    sprintf(paste0(
      "<button type=\"button\" data-bs-target=\"#%s\" data-bs-slide-to=\"%d\"",
      "%s aria-label=\"Slide %d\"></button>"),
      id, i - 1, if (i == 1) " class=\"active\" aria-current=\"true\"" else "", i)
  }, "")
  items <- vapply(seq_len(n), function(i) {
    sl <- slides[[i]]
    sprintf(paste0(
      "<div class=\"carousel-item%s\">%s<div class=\"pp-caption\">",
      "<div class=\"pp-title\">%s</div><div>%s</div></div></div>"),
      active(i), sl$svg, sl$title, sl$caption)
  }, "")
  control <- function(dir, arrow, label) {
    sprintf(paste0(
      "<button class=\"carousel-control-%s\" type=\"button\" ",
      "data-bs-target=\"#%s\" data-bs-slide=\"%s\">",
      "<span class=\"pp-arrow\" aria-hidden=\"true\">%s</span>",
      "<span class=\"visually-hidden\">%s</span></button>"),
      dir, id, dir, arrow, label)
  }
  html <- paste0(
    "<style>", pp_css, "</style>",
    "<div class=\"pp-carousel\">",
    sprintf("<div id=\"%s\" class=\"carousel slide\" data-bs-interval=\"false\">", id),
    sprintf("<div class=\"carousel-inner\">%s</div>", paste(items, collapse = "")),
    control("prev", "&#8249;", "Previous"),
    control("next", "&#8250;", "Next"),
    sprintf("<div class=\"carousel-indicators\">%s</div>",
            paste(indicators, collapse = "")),
    "</div></div>"
  )
  cat("\n```{=html}\n", html, "\n```\n", sep = "")
}
