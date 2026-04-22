#import "@preview/peace-of-posters:0.6.0" as pop
#import "@preview/zebraw:0.5.5": *
// Tiaoma provides the QR code generator for the Bottom Box
#import "@preview/tiaoma:0.3.0"
#import "tuni-style.typ"
#import "lib.typ" as lib: *

#show: doc => preamble(doc)

// All headings in purple, all headings in standard point size
#show heading: it => text(fill: tuni-style.tuni-purple, size: pop.layout-a0.at("body-size"), it)
#show heading: it => { [#it #v(-.3em)] }

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

    Work in Progress:\ Efficient Readers-Writer Locks for the RTIC Framework
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
  #pop.column-box(heading: [*Summary*])[
    - We present Readers-Writers locks (RW locks) for the RTIC framework, offering improved schedulability for systems with high-priority readers.
    - Suggested runtime implementation introduces no overhead compared to RTIC's pre-existing mutex locks.
    - The declarative mapping from RW locks to SRP can be implemented by analysis and a preprocessor pass.
  ]
  #pop.column-box(heading: [Prior work])[
    PCP has been extended to apply to RW resources by Sha et al.~@sha1989rwpcp
  ]

  #pop.column-box(heading: [*RTIC framework*])[
    = Meta
    - *Near-zero overhead Rust-based RTOS* based on a hardware orchestrated execution model.
    - Million downloads on crates.io

    = Model: tasks & shared resources
    - Stack Resource Policy (SRP) @baker1991srp-journal
    - Interrupts as tasks
  ]

  #pop.column-box(heading: [*RW resources/*Multi-unit resources*/*])[
    RW resources are modeled as a special case of multi-unit resources, where the number of units is the number of jobs accessing the resource and readers acquire one unit and writers acquire all units.
  ]

  #pop.column-box(heading: [*Efficient resource sharing / locking*])[
    #zebraw(
      highlight-lines: (2, 8, 9, 10, 18, 19, 20),
      footer: "Highlight footer",
      highlight-color: tuni-style.tuni-blue,
      lang: false,
    )[
      ```C
      line 1
      line 2
      line 3
      ```
    ]
  ]

  #pop.column-box(heading: [*Code*])[
  ]

  #pop.column-box(heading: [*Mutex*], rect(
    stroke: if DEBUG { red },
    /* HACK: render diagrams as SVG to work around an unknown PDF rendering bug.
     *
     * Using PDf causes hatch-colorings to be partially invisible. Rendering as
     * SVG  gives a warning but we'll be okay with that.
     *
     * SVG rendering settings for draw.io:
     *
     * * Zoom: 100%, Border Width: 0
     * * Size: Diagram
     * * [x] Transparent background
     * * Appearance: Light
     * * [ ] Shadow
     * * [ ] Include a copy of my diagram
     * * [x] Embed Images
     * * [x] Embed Fonts
     */
    image("assets/export/system-mutex.svg", width: 100%),
  ))

  #pop.column-box(
    heading: [*RW*],
    rect(
      stroke: if DEBUG { red },
      /* HACK: see above */
      image("assets/export/system-rw.svg", width: 100%),
    ),
  )

  #pop.column-box(heading: [*SRP-compliant Readers-Writer Lock*])[
    #set math.equation(numbering: "(1)")

    *Theorem* Given the current system ceiling $macron(Pi)_"old"$ and assuming $R$ is a RW resource modeled as a multi-unit resource,
    /*when a lock is taken on a readers/writer resource $R$, the system ceiling can be raised to a compile-time known constant, $ceil(R)_"r"$ for read and $ceil(R)_0$ for write, and the system is still compliant to SRP.

    Formally,*/ SRP compliance is maintained when:

    + upon taking a read-lock of resource $R$, the system
      ceiling $macron(Pi)$ is updated to

      #box[$
        macron(Pi) = max(macron(Pi)_"old", ceil(R)_1)
      $<eq:rw-lock-ceil-r>]
      where $ceil(R)_1$ is the highest preemption level of
      jobs with write-access to $R$, and
    + upon taking a write-lock of resource $R$, the system
      ceiling $macron(Pi)$ changes to

      #box[$
        macron(Pi) = max(macron(Pi)_"old", ceil(R)_0),
      $<eq:rw-lock-ceil-w>]

      where $ceil(R)_0$ is the highest preemption level of jobs with any access~to~$R$.
  ]
  //#colbreak()

  #pop.column-box(heading: [*Future Work*])[
    - General multi-unit resources
  ]

  #pop.column-box(heading: [*References*])[
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
