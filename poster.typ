#import "@preview/peace-of-posters:0.6.0" as pop
#import "@preview/zebraw:0.5.5": *
// Tiaoma provides the QR code generator for the Bottom Box
#import "@preview/tiaoma:0.3.0"
#import "tuni-style.typ"
#import "lib.typ" as lib: *

#show: doc => preamble(doc)

// Hyphenate or not?
#set text(hyphenate: false)

#let DEBUG = false

#let orgs = (
  tau: (
    idx: 1,
    name: [Tampere University],
    location: [/*Tampere, */Finland],
  ),
  ltu: (
    idx: 2,
    name: [Luleå University of Technology],
    location: [/*Luleå, */Sweden],
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

// The bottom box is ordinarily dynamically sized, based on its contents
#let bottom-box-height = 5cm

#let vfix = 20pt
#let tuni-logo-height = bottom-box-height
// Editor's stylistic choice: TUNI logo's visual weight is a bit downwards
// distributed. Consider moving it upwards just a bit to counter-balance.
#let tuni-logo-y-offset = 0.0 * bottom-box-height
#let logo-box(sizes, y-offsets) = box(
  stroke: if DEBUG { red },
  height: 140pt + vfix,
  grid(
    columns: 2,
    align: horizon,
    column-gutter: 0.5em,
    move(
      dy: y-offsets.at(0) + 5pt,
      image(
        "assets/logo_TAU_fieng_white_crop.svg",
        fit: "contain",
        width: sizes.at(0).at(0),
        height: sizes.at(0).at(1),
      ),
    ),
    move(
      image(
        "assets/export/LTU_eng_ CMYK converted white.svg",
        height: sizes.at(1).at(0),
        width: sizes.at(1).at(1),
      ),
      dy: y-offsets.at(1) + 5pt,
    ),
  ),
)

#pop.title-box(
  [
    #set text(fill: white)

    #logo-box(
      ((400pt, auto), (auto, auto)),
      (tuni-logo-y-offset, -8pt),
    )
    #v(-vfix)

    #box(stroke: if DEBUG { red })[
      Work in Progress:\ Efficient Readers-Writer Locks for
      the RTIC Framework
    ]
  ],
  authors: [
    #v(1cm)
    #set text(fill: white)
    #(
      authors
        .map(a => [#a.name#super[#a.org.idx]])
        .join(", ", last: " and ")
    )
  ],
  institutes: [
    #set text(fill: white, weight: "regular")
    #(
      orgs
        .values()
        .map(o => (
          super[#o.idx] + o.name + ", " + o.location
        ))
        .join(", ")
    )

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
    - *_Readers-Writer Locks_ (_RW Locks_) for the
      RTIC~framework,*\ offer improved schedulability for
      Rust-based embedded systems with high-priority readers
      of shared resources.
    - Suggested /*_runtime_*/ implementation introduces *no
      runtime overhead* compared to RTIC's pre-existing
      /*single-unit*/
      mutex locks.
    - The declarative mapping between
      Stack~Resource~Policy~(SRP) and RW~locks can be
      implemented by ahead-of-time code analysis and
      preprocessing.
    - _Rust alias guarantees_ can be used to enforce
      access-mode guarantees in the application-side lock
      API.
  ]
  #pop.column-box(heading: [*Prior work*])[
    - SRP models Readers-Writer locks using multi-unit
      resources.~@baker1991srp-journal
    - A special case of
      SRP---Priority~Ceiling~Protocol---has been extended to
      apply to RW resources by
      #box[Sha et al.~@sha1989rwpcp]
    //- Conventional OSes tend not to provide bounded blocking.~@buttazzo2011-hard

    #pop.column-box(heading: [*The RTIC framework*])[
      #grid(
        columns: (1fr, auto),
        align: (left + horizon, center + top),
        column-gutter: 1em,
        stroke: if DEBUG { red },
        [
          *Near-zero overhead Rust-based RTOS~@rtic*\ with a
          hardware orchestrated execution model.

          Used in industry & popular with hobbyists:\ *a
          million all-time downloads on crates.io*.

        ],
        move(dy: -2em, align(center + horizon, rect(
          radius: 100%,
          height: 6em,
          width: 6em,
          stroke: none,
          fill: white,
          move(
            // Account for the tail
            dy: -8pt,
            image("assets/logo_RTIC.png", height: 95%),
          ),
        ))),
      )

      #v(-0.5em)
      /*
      #let hrule = align(center, box(width: 100%, repeat[\- #h(0.4em)]))
      //#let hrule = line(length: 100%, stroke: stroke(dash: "dashed", thickness: 5pt))
      #hrule
      */

      *Model: tasks & shared resources for single-processor
      systems*
      - SRP-based resource sharing for concurrent tasks.
      - *Intuition:* interrupts as tasks.
      - *Limitations/*Constraints*/:* single processor,
        fixed priorities.
      - *Benefits:*
        single-stack execution, race- and
        deadlock-free/* execution*/, bounded blocking,
        // one context switch per task execution,
        prevention of multiple priority inversion, and
        amenable to WCET, response time and schedulability
        analysis.

    #pop.column-box(heading: [*Efficient resource sharing /
    locking*])[
      #grid(
        columns: (1fr, 1fr),
        column-gutter: 0.5em,
        zebraw(
          //highlight-lines: (2, 8, 9, 10, 18, 19, 20),
          //footer: "Highlight footer",
          highlight-color: tuni-style.tuni-blue,
          lang: false,
        )[
          ```rust
          #[shared = [res]]
          fn task() {
            res.lock(|r| {

              /* ... */
            });
          }
          ```
        ],
        zebraw(
          //highlight-lines: (2, 8, 9, 10, 18, 19, 20),
          //footer: "Highlight footer",
          highlight-color: tuni-style.tuni-blue,
          lang: false,
          numbering: false,
        )[
          ```asm
          mrs     r0, BASEPRI
          push    {r0}
          # 0x40: comp.-time constant
          mov     r0, #0x40
          msr     BASEPRI_MAX, r0
          /* ... */
          pop     {r0}
          msr     BASEPRI, r0
          ```
          /*
          ```
          cur = read basepri
          if ceil(r) > cur:
            basepri = ceil(r)

          /* ... */
          basepri = cur
          ```
          */
        ],
      )
    ]
  ]

  #pop.column-box(heading: [*SRP-compliant Readers-Writer
  Lock*])[
    *Theorem* Given the current system ceiling
    $macron(Pi)_"old"$ and assuming $R$ is a RW resource
    modeled as a multi-unit resource,
    /*when a lock is taken on a readers/writer resource $R$, the system ceiling can be raised to a compile-time known constant, $ceil(R)_"r"$ for read and $ceil(R)_0$ for write, and the system is still compliant to SRP.

    Formally,*/ SRP compliance is maintained when:

    #grid(
      columns: 2,
      column-gutter: 1em,
      [
        1. upon taking a read-lock of resource $R$, the
          system ceiling $macron(Pi)$ is updated to
          #math.equation(block: true, [$
            macron(Pi) = max(macron(Pi)_"old", ceil(R)_1),
          $<eq:rw-lock-ceil-r>])
          where $ceil(R)_1$ is the highest preemption level
          of jobs with write-access to $R$, and
      ],
      [
        2. upon taking a write-lock of resource $R$, the
          system ceiling $macron(Pi)$ changes to
          $
            macron(Pi) = max(macron(Pi)_"old", ceil(R)_0),
          $<eq:rw-lock-ceil-w>
          where $ceil(R)_0$ is the highest preemption level
          of jobs with any access~to~$R$.
      ],
    )
  ]

  #pop.column-box(heading: [*RW
  resources/*Multi-unit resources*/*])[
    SRP supports multi-unit resources. RTIC implements
    near-zero overhead locks for single-unit resources.

    RW resources are modeled in SRP as a special case of
    multi-unit resources, where the number of units is the
    number of jobs accessing the resource and readers
    acquire one unit and writers acquire all units.
  ]

  #pop.column-box(
    heading: [*Improved response time with RW locks for
    high-priority readers*],
    box(
      stroke: if DEBUG { red },
      [
        - Five jobs (tasks) contending over a shared
          resource
        - Static priority = preemption level
        /*
        Example system has five tasks and a shared RW
        resource. Priorities equal preemption levels. First
        diagrams shows behavior when mutex locks are used to
        access the resource, and the second when RW locks
        are used instead.
        */

        #box(
          stroke: if DEBUG { red },
          image("assets/export/legend.pdf", width: 100%),
        )
        //*Mutex*
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
        #box(
          stroke: if DEBUG { red },
          image(
            "assets/export/system-mutex.pdf",
            width: 100%,
          )
            + place(top + right, dy: 0.75em, dx: -1em, rect(
              fill: tuni-style.tuni-pink,
              outset: 0.4em,
              [*Using Mutex Locks*],
            )),
        )
        /* HACK: see above */
        //*RW*
        #v(-1.25em)
        #box(
          stroke: if DEBUG { red },
          image("assets/export/system-rw.pdf", width: 100%)
            + place(
              top + right,
              dy: 0.45em,
              dx: -1em,
              rect(
                fill: tuni-style.tuni-pink,
                outset: 0.4em,
                [*Using Readers-Writer Locks*],
              ),
            ),
        )
        #v(-1.25em)
      ],
    ),
  )

  #pop.column-box(heading: [*Future Work*])[
    - Generalized multi-unit resources.
  ]

  #pop.column-box(heading: [*References*])[
    #set text(size: 20pt)
    #set par(spacing: 0.75em)
    #bibliography("refs.bib", title: none)
  ]
])

#{
  pop.bottom-box(
    logo: {
      logo-box(
        ((auto, tuni-logo-height), (auto, auto)),
        (tuni-logo-y-offset, -5pt),
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
