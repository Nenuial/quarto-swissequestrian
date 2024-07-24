
// This is an example typst template (based on the default template that ships
// with Quarto). It defines a typst function named 'article' which provides
// various customization options. This function is called from the 
// 'typst-show.typ' file (which maps Pandoc metadata function arguments)
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-show.typ' entirely. You can find 
// documentation on creating typst templates and some examples here: 
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates


#let article(
  logo: none,
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "a4",
  lang: "en",
  region: "US",
  flipped: false,
  font: (),
  fontsize: 11pt,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)

  set page(
    paper: paper,
    margin: margin,
    flipped: flipped,
    numbering: "1/1",
    number-align: bottom + right,
    header: context {
      if counter(page).get().first() == 1 {
        box(width: 50%,
          [#set text(fill: rgb("#00283c"), size: 8pt)
          *SWISS EQUESTRIAN*\
          #set text(fill: black)
          Postfach 726, Papiermühlestrasse 40H, CH-3000 Bern 22\
          #link("tel:0041313354343", "+41 (0)31 335 43 43"), #link("mailto:info@swiss-equestrian.ch", "info@swiss-equestrian.ch"), #link("https://www.swiss-equestrian.ch", "swiss-equestrian.ch")]
        )
      } else {
      box(width: 33%, baseline: -1cm,
        [#set text(fill: rgb("#00283c"), size: 8pt)
          *SWISS EQUESTRIAN*\
          #link("https://www.swiss-equestrian.ch", "swiss-equestrian.ch")
          ])
      box(width: 33%, baseline: -1cm,
        [#set text(weight: "bold")
         #align(center, 
            [#title
             #if subtitle != none [: #subtitle]
            ]
         )])
      box(width: 33%, baseline: -.5cm,
        [#align(right, image(width: 1.5cm, logo))])
    }}
  )

  place(
  top + right,
  dx: 0cm,
  dy: -2.5cm,
  image(width: 2.5cm, logo)
  )

  set heading(numbering: sectionnumbering)

  if title != none {
    align(center)[#block(width: 80%, inset: 1.5em)[
      #text(weight: "bold", size: 2.3em,)[#upper(title)]
    ]]
  }

  if subtitle != none {
    align(center)[#block(width: 80%)[
      #text(weight: "bold", size: 1.8em,)[#subtitle]
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  v(1cm)

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)
