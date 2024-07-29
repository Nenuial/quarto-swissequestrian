// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}

// ####################
// # typst-letter-pro #
// ####################
// 
// This template is based on Typst Letter Prof
// by Sematre
//
// Project page:
// https://github.com/Sematre/typst-letter-pro
// 

// ##################
// # Letter formats #
// ##################
#let letter-formats = (
  "DIN-5008-A": (
    folding-mark-1-pos: 87mm,
    folding-mark-2-pos: 87mm + 105mm,
    header-size: 27mm,
  ),
  
  "DIN-5008-B": (
    folding-mark-1-pos: 105mm,
    folding-mark-2-pos: 105mm + 105mm,
    header-size: 45mm,
  ),
)

// ##################
// # Generic letter #
// ##################

/// This function takes your whole document as its `body` and formats it as a simple letter.
/// 
/// - format (string): The format of the letter, which decides the position of the folding marks and the size of the header.
///   #table(
///     columns: (1fr, 1fr, 1fr),
///     stroke: 0.5pt + gray,
///     
///     text(weight: "semibold")[Format],
///     text(weight: "semibold")[Folding marks],
///     text(weight: "semibold")[Header size],
///     
///     [DIN-5008-A], [87mm, 192mm],  [27mm],
///     [DIN-5008-B], [105mm, 210mm], [45mm],
///   )
/// 
/// - header (content, none): The header that will be displayed at the top of the first page.
/// - footer (content, none): The footer that will be displayed at the bottom of the first page. It automatically grows upwords depending on its body. Make sure to leave enough space in the page margins.
/// 
/// - folding-marks (boolean): The folding marks that will be displayed at the left margin.
/// - hole-mark (boolean): The hole mark that will be displayed at the left margin.
/// 
/// - address-box (content, none): The address box that will be displayed below the header on the left.
/// 
/// - information-box (content, none): The information box that will be displayed below below the header on the right.
/// - reference-signs (array, none): The reference signs that will be displayed below below the the address box. The array has to be a collection of tuples with 2 content elements.
///   
///   Example:
///   ```typ
///   (
///     ([Foo],   [bar]),
///     ([Hello], [World]),
///   )
///   ```
/// 
/// - page-numbering (string, function, none): Defines the format of the page numbers.
///   #table(
///     columns: (auto, 1fr),
///     stroke: 0.5pt + gray,
///     
///     text(weight: "semibold")[Type], text(weight: "semibold")[Description],
///     [string],   [A numbering pattern as specified by the official documentation of the #link("https://typst.app/docs/reference/model/numbering/", text(blue)[_numbering_]) function.],
///     [function], [
///       A function that returns the page number for each page.\
///       Parameters:
///       - current-page (integer)
///       - page-count (integer)
///       Return type: _content_
///     ],
///     [none],     [Disable page numbering.],
///   )
/// 
/// - margin (dictionary): The margin of the letter.
///   
///   The dictionary can contain the following fields: _left_, _right_, _top_, _bottom_.\
///   Missing fields will be set to the default. 
///   Note: There is no _rest_ field.
/// 
/// - body (content, none): The content of the letter
/// -> content
#let letter-generic(
  format: "DIN-5008-B",
  
  header: none,
  footer: none,
  
  folding-marks: true,
  hole-mark: true,
  
  address-box: none,
  information-box: none,
  
  reference-signs: none,
  
  page-numbering: (current-page, page-count) => {
    str(current-page) + "/" + str(page-count)
  },

  margin: (
    left:   25mm,
    right:  20mm,
    top:    20mm,
    bottom: 20mm,
  ),
  
  body,
) = {
  if not letter-formats.keys().contains(format) {
    panic("Invalid letter format! Options: " + letter-formats.keys().join(", "))
  }
  
  margin = (
    left:   margin.at("left",   default: 25mm),
    right:  margin.at("right",  default: 20mm),
    top:    margin.at("top",    default: 20mm),
    bottom: margin.at("bottom", default: 20mm),
  )
  
  set page(
    paper: "a4",
    flipped: false,
    
    margin: margin,
    
    background: {
      if folding-marks {
        // folding mark 1
        place(top + left, dx: 5mm, dy: letter-formats.at(format).folding-mark-1-pos, line(
            length: 2.5mm,
            stroke: 0.25pt + black
        ))
        
        // folding mark 2
        place(top + left, dx: 5mm, dy: letter-formats.at(format).folding-mark-2-pos, line(
            length: 2.5mm,
            stroke: 0.25pt + black
        ))
      }
      
      if hole-mark {
        // hole mark
        place(left + top, dx: 5mm, dy: 148.5mm, line(
          length: 4mm,
          stroke: 0.25pt + black
        ))
      }
    },
    
    footer-descent: margin.bottom - 2cm,
    footer: locate(loc => {
      show: pad.with(top: 12pt, bottom: 1.5cm)
      
      let current-page = loc.page()
      let page-count = counter(page).final(loc).at(0)
      
      grid(
        columns: (.8fr, .2fr),
        align: ((bottom + left), (top + right)),
        rows: (0.65em, 1fr),
        row-gutter: 0pt,

        if current-page == 1 {
          footer
        } else {
          []
        },
        
        if page-count > 1 {
          if type(page-numbering) == str {
            numbering(page-numbering, current-page, page-count)
          } else if type(page-numbering) == function {
            page-numbering(current-page, page-count)
          } else if page-numbering != none {
            panic("Unsupported option type!")
          }
        },
        
      )
    }),
  )
  
  // Reverse the margin for the header, the address box and the information box
  pad(top: -margin.top, left: -margin.left, right: -margin.right, {
    grid(
      columns: 100%,
      rows: (letter-formats.at(format).header-size, 45mm),
      
      // Header box
      header,
      
      // Address / Information box
      pad(left: 20mm, right: 10mm, {
        grid(
          columns: (85mm, 75mm),
          rows: 45mm,
          column-gutter: 20mm,
          
          // Address box
          address-box,
          
          // Information box
          pad(top: 5mm, information-box)
        )
      }),
    )
  })

  v(12pt)

  // Reference signs
  if (reference-signs != none) and (reference-signs.len() > 0) {
    grid(
      // Total width: 175mm
      // Delimiter: 4.23mm
      // Cell width: 50mm - 4.23mm = 45.77mm
      
      columns: (45.77mm, 45.77mm, 45.77mm, 25mm),
      rows: 12pt * 2,
      gutter: 12pt,
      
      ..reference-signs.map(sign => {
        let (key, value) = sign
        
        text(size: 8pt, key)
        linebreak()
        text(size: 10pt, value)
      })
    )
  }
  
  // Add body.
  body
}

// ####################
// # Helper functions #
// ####################

/// Creates a simple header with a name, an address and extra information.
/// 
/// - name (content, none): Name of the sender
/// - address (content, none): Address of the sender
/// - extra (content, none): Extra information about the sender
#let header-simple(name, address, extra: none) = {
  set text(size: 10pt)

  if name != none {
    strong(name)
    linebreak()
  }
  
  if address != none {
    address
    linebreak()
  }

  if extra != none {
    extra
  }
}

/// Creates a simple sender box with a name and an address.
/// 
/// - name (content, none): Name of the sender
/// - address (content, none): Address of the sender
#let sender-box(name: none, address) = rect(width: 85mm, height: 5mm, stroke: none, inset: 0pt, {
  set text(size: 7pt)
  set align(horizon)
  
  pad(left: 5mm, underline(offset: 2pt, {
    if name != none {
      name
    }

    if (name != none) and (address != none) {
      ", "
    }

    if address != none {
      address
    }
  }))
})

/// Creates a simple annotations box.
/// 
/// - content (content, none): The content
#let annotations-box(content) = {
  set text(size: 7pt)
  set align(bottom)
  
  pad(left: 5mm, bottom: 2mm, content)
}

/// Creates a simple recipient box.
/// 
/// - content (content, none): The content
#let recipient-box(content) = {
  set text(size: 10pt)
  set align(top)
  
  pad(left: 5mm, content)
}

/// Creates a simple address box with 2 fields.
/// 
/// The width is is determined automatically. Row heights:
/// #table(
///   columns: 3cm,
///   rows: (17.7mm, 27.3mm),
///   stroke: 0.5pt + gray,
///   align: center + horizon,
///   
///   [sender\ 17.7mm],
///   [recipient\ 27.3mm],
/// )
/// 
/// See also: _address-tribox_
/// 
/// - sender (content, none): The sender box
/// - recipient (content, none): The recipient box
#let address-duobox(sender, recipient) = {
  grid(
    columns: 1,
    rows: (17.7mm, 27.3mm),
      
    sender,
    recipient,
  )
}

/// Creates a simple address box with 3 fields and optional repartitioning for a stamp.
/// 
/// The width is is determined automatically. Row heights:
/// #table(
///   columns: 2,
///   stroke: none,
///   align: center + horizon,
///   
///   text(weight: "semibold")[Without _stamp_],
///   text(weight: "semibold")[With _stamp_],
///   
///   table(
///     columns: 3cm,
///     rows: (5mm, 12.7mm, 27.3mm),
///     stroke: 0.5pt + gray,
///     align: center + horizon,
///     
///     [_sender_ 5mm],
///     [_annotations_\ 12.7mm],
///     [_recipient_\ 27.3mm],
///   ),
///   
///   table(
///     columns: 3cm,
///     rows: (5mm, 21.16mm, 18.84mm),
///     stroke: 0.5pt + gray,
///     align: center + horizon,
///     
///     [_sender_ 5mm],
///     [_stamp_ +\ _annotations_\ 21.16mm],
///     [_recipient_\ 18.84mm],
///   )
/// )
/// 
/// See also: _address-duobox_
/// 
/// - sender (content, none): The sender box
/// - annotations (content, none): The annotations box
/// - recipient (content, none): The recipient box
/// - stamp (boolean): Enable stamp repartitioning. If enabled, the annotations box and the recipient box divider is moved 8.46mm (about 2 lines) down.
#let address-tribox(sender, annotations, recipient, stamp: false) = {
  if stamp {
    grid(
      columns: 1,
      rows: (5mm, 12.7mm + (4.23mm * 2), 27.3mm - (4.23mm * 2)),
      
      sender,
      annotations,
      recipient,
    )
  } else {
    grid(
      columns: 1,
      rows: (5mm, 12.7mm, 27.3mm),
      
      sender,
      annotations,
      recipient,
    )
  }
}

// #################
// # Simple letter #
// #################

/// This function takes your whole document as its `body` and formats it as a simple letter.
/// 
/// The default font is set to _Source Sans Pro_ without hyphenation. The body text will be justified.
/// 
/// - format (string): The format of the letter, which decides the position of the folding marks and the size of the header.
///   #table(
///     columns: (1fr, 1fr, 1fr),
///     stroke: 0.5pt + gray,
///     
///     text(weight: "semibold")[Format],
///     text(weight: "semibold")[Folding marks],
///     text(weight: "semibold")[Header size],
///     
///     [DIN-5008-A], [87mm, 192mm],  [27mm],
///     [DIN-5008-B], [105mm, 210mm], [45mm],
///   )
/// 
/// - header (content, none): The header that will be displayed at the top of the first page. If header is set to _none_, a default header will be generaded instead.
/// - footer (content, none): The footer that will be displayed at the bottom of the first page. It automatically grows upwords depending on its body. Make sure to leave enough space in the page margins.
/// 
/// - folding-marks (boolean): The folding marks that will be displayed at the left margin.
/// - hole-mark (boolean): The hole mark that will be displayed at the left margin.
/// 
/// - sender (dictionary): The sender that will be displayed below the header on the left.
///   
///   The name and address fields must be strings (or none).
/// 
/// - recipient (content, none): The recipient that will be displayed below the annotations.
/// 
/// - stamp (boolean): This will increase the annotations box size is by two lines in order to provide more room for the postage stamp that will be displayed below the sender.
/// - annotations (content, none): The annotations box that will be displayed below the sender (or the stamp if enabled).
/// 
/// - information-box (content, none): The information box that will be displayed below below the header on the right.
/// - reference-signs (array, none): The reference signs that will be displayed below below the the address box. The array has to be a collection of tuples with 2 content elements.
///   
///   Example:
///   ```typ
///   (
///     ([Foo],   [bar]),
///     ([Hello], [World]),
///   )
///   ```
/// 
/// - date (content, none): The date that will be displayed on the right below the subject.
/// - subject (string, none): The subject line and the document title.
/// 
/// - page-numbering (string, function, none): Defines the format of the page numbers.
///   #table(
///     columns: (auto, 1fr),
///     stroke: 0.5pt + gray,
///     
///     text(weight: "semibold")[Type], text(weight: "semibold")[Description],
///     [string],   [A numbering pattern as specified by the official documentation of the #link("https://typst.app/docs/reference/meta/numbering/", text(blue)[_numbering_]) function.],
///     [function], [
///       A function that returns the page number for each page.\
///       Parameters:
///       - current-page (integer)
///       - page-count (integer)
///       Return type: _content_
///     ],
///     [none],     [Disable page numbering.],
///   )
/// 
/// - margin (dictionary): The margin of the letter.
///   
///   The dictionary can contain the following fields: _left_, _right_, _top_, _bottom_.\
///   Missing fields will be set to the default. 
///   Note: There is no _rest_ field.
/// 
/// - font (string, array): Font used throughout the letter.
/// 
///   Keep in mind that some fonts may not be ideal for automated letter processing software
///   and #link("https://en.wikipedia.org/wiki/Optical_character_recognition", text(blue)[OCR]) may fail.
/// 
/// - body (content, none): The content of the letter
/// -> content
#let letter-simple(
  format: "DIN-5008-B",
  
  header: none,
  footer: none,

  folding-marks: true,
  hole-mark: true,
  
  sender: (
    name: none,
    address: none,
    extra: none,
  ),
  
  recipient: none,

  stamp: false,
  annotations: none,
  
  information-box: none,
  reference-signs: none,

  signature-name: none,
  signature-title: none,
  
  date: none,
  subject: none,

  page-numbering: (current-page, page-count) => {
    str(current-page) + "/" + str(page-count)
  },

      margin: (bottom: 2cm,left: 2cm,right: 2cm,top: 4cm,),
  
  font: "Source Sans Pro",

  body,
) = {
  margin = (
    left:   margin.at("left",   default: 25mm),
    right:  margin.at("right",  default: 20mm),
    top:    margin.at("top",    default: 20mm),
    bottom: margin.at("bottom", default: 30mm),
  )
  
  // Configure page and text properties.
  set document(
    title: subject,
    author: sender.name,
  )

  set text(font: font, hyphenate: false)

  // Create a simple header if there is none
  if header == none {
    header = pad(
      left: margin.left,
      right: margin.right,
      top: margin.top,
      bottom: 5mm,
      
      align(bottom + right, header-simple(
        sender.name,
        if sender.address != none {
          sender.address.split(", ").join(linebreak())
        } else {
          "lul?"
        },
        extra: sender.at("extra", default: none),
      ))
    )
  }

  let sender-box      = sender-box(name: sender.name, sender.address)
  let annotations-box = annotations-box(annotations)
  let recipient-box   = recipient-box(recipient)

  let address-box     = address-tribox(sender-box, annotations-box, recipient-box, stamp: stamp)
  if annotations == none and stamp == false {
    address-box = address-duobox(align(bottom, pad(bottom: 0.65em, sender-box)), recipient-box)
  }
  
  letter-generic(
    format: format,
    
    header: header,
    footer: footer,

    folding-marks: folding-marks,
    hole-mark: hole-mark,
    
    address-box:     address-box,
    information-box: information-box,

    reference-signs: reference-signs,

    page-numbering: page-numbering,
    
    {
      // Add the date line, if any.
      if date != none {
        align(right, date)
        v(0.65em)
      }
      
      // Add the subject line, if any.
      if subject != none {
        pad(right: 10%, text(fill: rgb("#00283c"), size: 12pt, strong(upper(subject))))
        v(0.65em)
      }
      
      set par(justify: true)
      body
      if signature-name != none {
        pad(left: 7cm, [
          #v(1cm)
          #text(fill: rgb("#00283c"), strong(upper(signature-title)))
          #v(1.5cm)
          #signature-name
        ])
      }
    },

    margin: margin,
  )
}
#set text(lang: "fr")

#show: letter-simple.with(
  sender: (
    name: "Pascal Burkhard",
    address: "Chemin du Marais 10, 1031 Mex",
  ),

  font: "Gilroy",

  header: [
    #place(top + left, dx: 2.5cm, dy: 1.5cm, [
      #set text(fill: rgb("#00283c"), size: 8pt)
          *SWISS EQUESTRIAN*\
          #set text(fill: black)
          Postfach 726, Papiermühlestrasse 40H, CH-3000 Bern 22\
          #link("tel:0041313354343", "+41 (0)31 335 43 43"), #link("mailto:info@swiss-equestrian.ch", "info@swiss-equestrian.ch"), #link("https://www.swiss-equestrian.ch", "swiss-equestrian.ch")
    ])
    #place(top + right, image("_extensions/se-resources/images/logo-se.svg", width: 3.2cm), dx: -1.5cm, dy: 1.5cm)
  ],

    footer: [#strong[Kopie an:];\ - Monika Elmer, TK Springen\ - Markus Niklaus, GS Swiss Equestrian],
    
    recipient: [
        Jean Dupond
    \
        Rue Dufour 4
    \
        1111 La Prairie
      ],
  
    reference-signs: (
        ([Votre référence], [2024-07-29-01]),
      ),
  
    signature-name: "Pascal Burkhard",
  signature-title: "Responsable formation des juges de saut et tous les autres abrutis d’officiels aussi",
    
  date: "29 juillet 2024",
  subject: "Lettre type",
)


Cupidatat laborum incididunt sint. Adipisicing consectetur sit eu magna. Elit elit velit ad in cillum anim aliqua nostrud quis commodo ut. Et eiusmod ut eu duis deserunt magna voluptate est mollit amet. Commodo ullamco et minim proident labore officia nisi est non. Consequat occaecat laboris tempor cillum eu ut nulla amet. Mollit enim aliqua sunt proident ullamco aute sunt velit anim et esse proident eiusmod culpa.

Labore aute minim enim. Nulla esse excepteur in irure cupidatat culpa labore do sit tempor proident adipisicing. Eu culpa velit nisi nisi ullamco cillum. Cillum irure aliquip voluptate quis qui qui eiusmod consequat nostrud cillum aliqua tempor minim eiusmod aute. Esse exercitation eiusmod laboris do dolore sit dolore irure ipsum excepteur. Amet laboris nostrud aliqua. Magna qui ea labore reprehenderit do commodo tempor fugiat cillum ullamco cillum.

Cupidatat laborum incididunt sint. Adipisicing consectetur sit eu magna. Elit elit velit ad in cillum anim aliqua nostrud quis commodo ut. Et eiusmod ut eu duis deserunt magna voluptate est mollit amet. Commodo ullamco et minim proident labore officia nisi est non. Consequat occaecat laboris tempor cillum eu ut nulla amet. Mollit enim aliqua sunt proident ullamco aute sunt velit anim et esse proident eiusmod culpa.

Labore aute minim enim. Nulla esse excepteur in irure cupidatat culpa labore do sit tempor proident adipisicing. Eu culpa velit nisi nisi ullamco cillum. Cillum irure aliquip voluptate quis qui qui eiusmod consequat nostrud cillum aliqua tempor minim eiusmod aute. Esse exercitation eiusmod laboris do dolore sit dolore irure ipsum excepteur. Amet laboris nostrud aliqua. Magna qui ea labore reprehenderit do commodo tempor fugiat cillum ullamco cillum.

Adipisicing do nulla ullamco. Cillum mollit anim officia ad velit et enim aliquip esse non proident ut laboris ipsum laborum. Ullamco aliquip ullamco cupidatat esse dolor eiusmod esse non minim ad nulla commodo velit. Officia excepteur fugiat anim ex irure est ut est sit. In ullamco pariatur esse cillum laboris voluptate adipisicing deserunt excepteur cillum ipsum nulla.

#pagebreak()
Cupidatat laborum incididunt sint. Adipisicing consectetur sit eu magna. Elit elit velit ad in cillum anim aliqua nostrud quis commodo ut. Et eiusmod ut eu duis deserunt magna voluptate est mollit amet. Commodo ullamco et minim proident labore officia nisi est non. Consequat occaecat laboris tempor cillum eu ut nulla amet. Mollit enim aliqua sunt proident ullamco aute sunt velit anim et esse proident eiusmod culpa.

Labore aute minim enim. Nulla esse excepteur in irure cupidatat culpa labore do sit tempor proident adipisicing. Eu culpa velit nisi nisi ullamco cillum. Cillum irure aliquip voluptate quis qui qui eiusmod consequat nostrud cillum aliqua tempor minim eiusmod aute. Esse exercitation eiusmod laboris do dolore sit dolore irure ipsum excepteur. Amet laboris nostrud aliqua. Magna qui ea labore reprehenderit do commodo tempor fugiat cillum ullamco cillum.

Adipisicing do nulla ullamco. Cillum mollit anim officia ad velit et enim aliquip esse non proident ut laboris ipsum laborum. Ullamco aliquip ullamco cupidatat esse dolor eiusmod esse non minim ad nulla commodo velit. Officia excepteur fugiat anim ex irure est ut est sit. In ullamco pariatur esse cillum laboris voluptate adipisicing deserunt excepteur cillum ipsum nulla.

Labore laborum reprehenderit aliquip aliqua voluptate. Ex amet nisi est nulla pariatur excepteur culpa ullamco velit cupidatat cupidatat velit cupidatat pariatur voluptate. Aliqua aliquip elit Lorem culpa consequat sint exercitation sunt ut. Enim laboris tempor voluptate laboris laboris cupidatat duis sunt cupidatat sit ipsum sit amet nisi.

Culpa quis proident aliquip sunt. Ipsum laboris sunt dolor ullamco aliquip non exercitation sit nostrud ex consectetur irure nulla magna. Aute aliqua qui eu irure. Exercitation sit dolor sint esse est quis do Lorem cupidatat ipsum cillum nisi cillum. Cillum qui tempor in cupidatat laboris pariatur voluptate adipisicing pariatur nulla nostrud sint laborum anim. Consequat duis ipsum velit duis sunt aliquip ea do. Nisi sit quis do in deserunt amet commodo. Non ea aute officia esse minim do et dolor proident.

Eiusmod non incididunt consectetur aliquip reprehenderit fugiat incididunt culpa sint mollit culpa laboris nisi. Voluptate aute dolore sunt non sint exercitation fugiat ea nostrud enim. Culpa id mollit ullamco consequat laborum aliqua eiusmod sit irure irure sint nisi. Dolor dolor eu deserunt elit. Laboris officia non occaecat laborum nostrud.

Lorem consectetur occaecat labore laboris amet nulla Lorem minim laborum pariatur duis cupidatat. Culpa commodo pariatur laborum veniam nisi est. Est id proident non dolor dolore. Proident dolore pariatur sunt ullamco quis Lorem minim incididunt ipsum dolore elit sunt. Eu tempor irure proident exercitation laboris proident occaecat nulla consectetur qui proident labore. Id irure veniam duis dolore sit id ea in deserunt. Aute cillum reprehenderit ipsum.

Dolor duis esse enim velit aliquip elit nostrud consequat pariatur. Adipisicing est do nisi et. Amet sint tempor nostrud mollit. Velit quis occaecat ullamco reprehenderit commodo dolor quis et consectetur. Anim eiusmod dolor occaecat nulla exercitation esse aliqua labore incididunt pariatur exercitation laborum occaecat dolor. Nisi eiusmod id irure ut nisi esse ad ut quis do. Nulla enim exercitation dolore amet enim exercitation dolore nulla consequat adipisicing aute officia ut. Sit adipisicing enim esse velit non.

Amet consequat consectetur in Lorem qui deserunt deserunt deserunt eiusmod eiusmod veniam id cupidatat. Ex aliquip labore consequat ipsum velit anim. Consectetur duis ipsum mollit dolor laboris commodo nostrud qui laborum occaecat labore velit est. Cillum proident dolore incididunt nostrud ipsum et qui ea occaecat fugiat nulla.

Est dolor dolor reprehenderit ea. Irure ut deserunt tempor nostrud aliquip esse non laboris mollit nulla mollit adipisicing nulla. Lorem magna eu nostrud nulla laboris eiusmod culpa elit culpa ad enim qui. Ad nulla deserunt tempor ea velit aliquip culpa. Ad tempor voluptate laborum tempor culpa magna ex velit dolore dolore ullamco proident.
