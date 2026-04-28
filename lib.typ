#import "@preview/peace-of-posters:0.6.0" as pop
#import "tuni-style.typ"

#let tau-theme = (
  "body-box-args": (
    inset: 0.6em,
    width: 100%,
    fill: tuni-style.tuni-white,
    stroke: tuni-style.tuni-purple,
  ),
  "body-text-args": (
    fill: tuni-style.tuni-black,
  ),
  "heading-box-args": (
    inset: 0.6em,
    width: 100%,
    fill: tuni-style.tuni-purple,
    stroke: tuni-style.tuni-purple,
  ),
  "heading-text-args": (
    fill: tuni-style.tuni-white,
  ),
)

#let preamble(doc) = {
  set page("a0", margin: 1cm)
  pop.set-poster-layout(pop.layout-a0)
  pop.set-theme(tau-theme)
  set text(
    font: tuni-style.tuni-font,
    size: pop.layout-a0.at("body-size"),
  )
  let box-spacing = 1.2em
  set columns(gutter: box-spacing)
  set block(spacing: box-spacing)
  pop.update-poster-layout(
    spacing: box-spacing,
    heading-size: 30pt,
  )

  doc
}
