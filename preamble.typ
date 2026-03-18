// === Heksa's playground ===

#let show-todo = false

// TODO-notes that can easily be made to vanish with the above boolean
#import "@preview/dashy-todo:0.1.3" as dashy
#let todo(..it) = {
  if not show-todo {
    return
  }

  set text(size: 8pt, hyphenate: true, lang: "en")
  // `par(justify: false)` cannot be used---breaks paragraphs
  //set par(justify: false)
  dashy.todo(..it)
}

#let heksa = todo.with(stroke: color.rgb("#17B890"))
#let valhe = todo.with(stroke: color.rgb("#fffb17"))
#let per = todo.with(stroke: purple)
// === Heksa's playground ends ===

#let preamble(doc) = {
  doc
}

// Environment for theorems
//
// From the style guide:
// "The preferred style is to set the head giving the theorem number as a tertiary heading (no Arabic numeral preceding)..."
#let theorem(content) = {
  set par(first-line-indent: 0pt)
  (
    heading(
      level: 3,
      [Theorem],
    )
      + [_#(content)_]
  )
}

// Environment for proofs
//
// From the style guide:
// "... and the proof head as a quaternary head"
#let proof(content, title: [Proof]) = {
  set par(first-line-indent: 0pt)
  (
    heading(
      level: 4,
      title,
      numbering: none,
    )
      + content
  )
}
