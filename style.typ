#import "@preview/hydra:0.6.1": hydra

#let font-name = "New Computer Modern" // TUD: "Noto Sans"
#let body-size = 11pt
#let info-size = 10pt

#let tud-doc(
  // optional, external parameters
  title: none,
  subtitle: none,
  authors: (), // e.g., ((first_name: "Max", surname: "Mustermann", matriculationno: "123", email: "x@y"), ...); matriculationno and email are optional
  faculty: none,
  institute: none,
  chair: none,
  supervisors: (), // e.g., ((name: "Dr. X", email: "x@y"), ...)
  language: "en",
  date: none, // pass a datetime; if none, the date block is omitted
  // optional branding overrides
  logo_de: "logo/TUD_Logo_RGB_horizontal_schwarz_de.svg",
  logo_en: "logo/TUD_Logo_RGB_horizontal_schwarz_en.svg",
  logo_height: 2cm,
  font-name: font-name,
  body-size: body-size,
  info-size: info-size, 
  doc
) = {
  /*
   * Text Flow
   */
  set text(
    font: font-name,
    lang: language,
    size: body-size,
    costs: (widow: 1000%, orphan: 1000%),
  )

  let bs = body-size

  // line spacing: https://github.com/typst/typst/issues/106#issuecomment-2041051807

  // Text is from left to .right. edge of the content space
  set par(justify: true, leading: 0.8em)
  set page(numbering: "I")

  // Heading size and spacing settings
  show heading.where(level: 1): it => pagebreak(weak: true) + text(size:  1.6em)[#it] + v(1em)
  show heading.where(level: 2): it => text(size:  1.4em)[#it] +v(0.7em)
  show heading.where(level: 3): it => text(size:  1.2em)[#it] +v(0.6em)

  show ref: it => {
    let el = it.element
    if el != none and el.func() == heading and el.level == 1 and el.supplement != [Appendix] {
      link(el.location(), "Chapter " + numbering(
        el.numbering,
        ..counter(heading).at(el.location())
      ))
    } else { it }
  }

  //
  // Numbering
  //

  // set heading scheme
  set heading(numbering: "1.1")

  // set figure numbering, depends on state "backmatter"
  set figure(numbering: n => {
    let appx = state("backmatter", false).get()
    let hdr = counter(heading).get()
    let format = if appx { "A.1" } else { "1.1" }
    numbering(format, hdr.first(), n)
  })

  // set equation numbering, depends on state "backmatter"
  set math.equation(numbering: n => {
    let appx = state("backmatter", false).get()
    let hdr = counter(heading).get()
    let format = if appx { "(A.1)" } else { "(1.1)" }
    numbering(format, hdr.first(), n)
  }, block: true)

  // reset the counters wich each major heading
  show heading.where(level: 1): hdr => {
    counter(figure.where(kind:image)).update(0)
    counter(figure.where(kind:table)).update(0)
    counter(math.equation).update(0)
    hdr
  }
  
  
  //
  // Front Page
  //

  // Format Page, No Numbering on Title Page
  set page(margin: (left: 1.1cm + 1.75cm, top: 1.35cm + 2.1cm), numbering: none)
  
  // Place TU Logo in the top left corner
  place(
      top + left,
      dx: -1.82cm,  
      dy: -2.1cm,
      image(if language == "de" {logo_de} else if language == "en" {logo_en} , height: logo_height),
  )
  
 

    // Place structure unit below (only if something provided)
  if faculty != none or institute != none or chair != none [
    #box(
      width: 100%,
      outset: (y: 4pt),
      stroke: (top: black, bottom: black)
    )[
      #if faculty != none [ *#faculty* \ ]
      #if institute != none and faculty != none [
        #institute, #chair
      ] else if institute != none [
        #institute
      ] else if chair != none [
        #chair
      ]
    ]
  ]

  // Place Title
  if title != none or subtitle != none [
    #place(
      dy: 15%,
      [
        #if title != none and subtitle != none [
          #text(30pt, weight: "bold", title) 

          #text(20pt, subtitle)
        ] else if title != none [
          #text(30pt, weight: "bold", title)
        ] else if subtitle != none [
          #text(20pt, subtitle)
        ]
      ]
    )
  ]

  // Author placement
  if authors.len() > 0 {
    place(
      dy: 45%,
      grid(
        row-gutter: 4%,
        ..authors.map((author) => [
          *#author.first_name #author.surname*\
          #if author.keys().contains("matriculationno") and language == "de" [_Matrikelnummer:_ #author.matriculationno \ ]
          #if author.keys().contains("matriculationno") and language == "en" [_Matriculation No.:_ #author.matriculationno \ ]
          #if author.keys().contains("email") [_E-Mail:_ #link("mailto:" + author.email)]
        ]),
      )
    )
  }

  // Submission date and Supervisor placement
  if (date != none) or (supervisors.len() > 0) {
    place(
      bottom,
      {
        if language == "de" {
          if date != none [
            *Abgabedatum*\
            #date.display("[day].[month].[year]")
            #v(5%)
          ]
          if supervisors.len() > 0 [
            *Betreuer:*\
            #list(
              tight: true,
              ..supervisors.map((sup) => [
                - #sup.name#if sup.keys().contains("email") and sup.email != "" [ #link("mailto:" + sup.email) ]
              ])
            )
          ]
        }
        if language == "en" {
          if date != none [
            *Date of Submission*\
            #date.display("[day].[month].[year]")
            #v(5%)
          ]
          if supervisors.len() > 0 [
            *Supervisor#if supervisors.len() > 1 [s]:*\
            #list(
              tight: true,
              ..supervisors.map((sup) => [
                #sup.name#if sup.keys().contains("email") and sup.email != "" [ (#link("mailto:" + sup.email)) ]
              ])
            )
          ]
        }
      }
    )
  }

  pagebreak() // end of title page  
  
  //
  // Content
  //
  doc
}


#let create-tud-outline(
  font-name: font-name,
  body-size: body-size,
  info-size: info-size,
  title: auto, // The title of the outline can be customized; if nothing is selected, the default heading for the selected language will be used.
  depth: 3, // The default depth of the outline is 3
) = {
  // top-level TOC entries in bold without filling
  show outline.entry.where(level: 1): it => {
    set block(above: 2 * body-size)
    set text(font: font-name, weight: "bold", size: info-size)
    link(
      it.element.location(),    // make entry linkable
      it.indented(it.prefix(), it.body() + box(width: 1fr,) +  strong(it.page()))
    )
  }

  // other TOC entries in regular with adapted filling
  show outline.entry.where(level: 2).or(outline.entry.where(level: 3)): it => {
    set block(above: 0.8 * body-size)
    set text(font: font-name, size: info-size)
    link(
      it.element.location(),  // make entry linkable
      it.indented(
          it.prefix(),
          it.body() + "  " +
            box(width: 1fr, repeat([.], gap: 2pt)) +
            "  " + it.page()
      )
    )
  }
  
  outline(title: title, depth: depth, indent: auto)

  pagebreak() // end of outline
}

#let tud-preamble(doc) = {
  //
  // Set Page Style
  // Chapter in Page Header, Page Number in Footer
  //
  set page(
    margin: auto,
    numbering: "i", // roman page numbers for preamble
    header: [#context hydra(1) \ #line(start: (0%, 0% -.2cm), length: 100%)],
    footer: context[#line(start: (0%, 0% -.2cm) ,length: 100%) #align(center, counter(page).display("i"))],
  )

  // Unnumbered headings in preamble
  set heading(numbering: none)

  counter(page).update(1)

  //
  // Content
  //
  doc
}

#let tud-body(doc) = {
  //
  // Set Page Style
  // Chapter in Page Header, Page Number in Footer
  //
  set page(
    margin: auto,
    numbering: "1", // needed for outline
    header: [#context hydra(1) \ #line(start: (0%, 0% -.2cm), length: 100%)],
    footer: context[#line(start: (0%, 0% -.2cm) ,length: 100%) #align(center, counter(page).display("1"))],
  )
  counter(page).update(1)

  set heading(numbering: "1.1")
  counter(heading).update(0)

  show heading: it => {
    if (it.level > 3){ // Heading only numbered up to level 3
        block(it.body)
    } else {
        it
    }
  }
  
  //
  // Content
  //
  doc
}


#let tud-appendix(doc) =  {
  set heading(numbering: "A.1", supplement: "Appendix")
  counter(heading).update(0)
  state("backmatter").update(true)
  //
  // Content
  //
  doc
}

#outline(target: heading.where(supplement: [Appendix]), title: [Appendix])
