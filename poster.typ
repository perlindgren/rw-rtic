#import "@preview/peace-of-posters:0.6.0" as pop
#import "@preview/zebraw:0.5.5": *
// Tiaoma provides the QR code generator for the Bottom Box
#import "@preview/tiaoma:0.3.0"
#import "tuni-style.typ"
#import "lib.typ" as lib: *

#show: doc => preamble(doc)

#let DEBUG = false

#let orgs = (
  tau: (
    idx: 1,
    name: [Tampere University],
    location: [Tampere, Finland],
  ),
  ltu: (
    idx: 2,
    name: [Luleå University of Technology],
    location: [Luleå, Sweden],
  ),
)
#let authors = (
  (
    name: "Valhe Kouneli",
    department: [Faculty of Information Technology and
      Communication Sciences],
    org: orgs.tau,
    email: "valhe.kouneli@gmail.com",
  ),
  (
    name: "Henri Lunnikivi",
    department: [Computing Sciences],
    org: orgs.tau,
    email: "henri.lunnikivi@tuni.fi",
  ),
  (
    name: "Per Lindgren",
    /* Original ortography from Luleå's site:
     * "Computer science, Electrical and Space engineering" */
    department: [Computer Science, Electrical and Space
      Engineering],
    org: orgs.ltu,
    email: "per.lindgren@ltu.se",
  ),
)

#pop.title-box(
  [
    #set text(fill: white)
    #box(
      height: 140pt,
      image("assets/logo_TAU_fieng_white_crop.svg", width: 400pt),
    )

    Work in Progress: Efficient Readers-Writer Locks for the RTIC Framework
  ],
  authors: [
    #v(1cm)
    #set text(fill: white)
    #authors.map(a => [#a.name#super[#a.org.idx]]).join(", ", last: " and ")
  ],
  institutes: [
    #set text(fill: white, weight: "regular")
    #orgs.values().map(o => super[#o.idx] + o.name + ", " + o.location).join(", ", last: " and ")

    /*#super("1")Tampere University, Finland
    #super("2")Luleå University of Technology, Sweden
    */
  ],
  title-size: 85pt,
  authors-size: 38pt,
  institutes-size: 26pt,
)

#columns(2, [
  #pop.column-box(heading: "Summary")[
    #set text(size: 33pt)
    - #lorem(10)
    - #lorem(20)
    - #lorem(30)
  ]

  #pop.column-box(heading: "Example: ???")[
    #set text(size: 28pt)
    #zebraw(
      highlight-lines: (7, 8, 9, 10, 18, 19, 20),
      footer: "Highlight footer",
      highlight-color: rgb("#c3b9d7"),
    )[
      ```C
      line 1
      line 2
      line 3
      ```
    ]
  ]

  #pop.column-box(heading: "Architecture")[
    #set text(size: 30pt)
    #lorem(10)

    #text(weight: "bold")[Results]:
    - #lorem(5)
    - #lorem(10)
    - #lorem(15)
  ]

  #colbreak()

  #pop.column-box(heading: "Virtualization")[
    #set text(size: 32pt)
    - #lorem(30)

    #text(weight: "bold")[Requirements]:
    - #lorem(10)
    - #lorem(20)

    #text(weight: "bold")[Effect]:
    - #lorem(10)
    - #lorem(20)

    #text(weight: "bold")[Limitations]:
    - #lorem(10)
    - #lorem(20)
  ]

  #pop.column-box(heading: "Experimental Results")[
    #set text(size: 32pt)
    - #lorem(10)
    - #lorem(20)
    - #lorem(30)
  ]

  #pop.column-box(heading: "Future Work")[
    #set text(size: 28pt)
    - #text(weight: "bold")[Virtualization] -- #lorem(10)
    - #text(weight: "bold")[Integration] -- #lorem(20)
    - #text(weight: "bold")[Evaluation] -- #lorem(10)
  ]

  #pop.column-box(heading: "References")[
    #set text(size: 25pt)
    #bibliography("refs.bib", title: none)
  ]
])

#{
  // The bottom box is dynamically sized, based on its contents
  let bottom-box-height = 5cm

  pop.bottom-box(
    logo: {
      let logo-height = bottom-box-height
      // Editor's stylistic choice: TUNI logo's visual weight is a bit downwards
      // distributed. Consider moving it upwards just a bit to counter-balance.
      let logo-y-offset = 0.0 * bottom-box-height
      move(
        dy: logo-y-offset,
        image(
          "assets/logo_TAU_fieng_white_crop.svg",
          fit: "contain",
          height: logo-height,
        ),
      )
    },
    // Stack the text and the QR code in a box
    //
    // Text size is based on the font. TODO: The QR code is dynamically scaled
    // to remaining space.
    box(
      height: bottom-box-height,
      /*
      grid(
        rows: (auto, 1fr),
        stroke: if DEBUG { red.lighten(50%) },
        row-gutter: 0.5em,
        align: horizon + center,
        text[*SoC Hub:*],
        {
          let qr-size = 3.6em
          rect(
            fill: white,
            width: qr-size,
            height: qr-size,
            tiaoma.qrcode("https://sochub.fi/", width: 100%, height: 100%),
          )
        },
      ),
      */
      stroke: if DEBUG { red },
    ),
  )
}
