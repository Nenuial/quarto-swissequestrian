$if(lang)$
#set text(lang: "$lang$")
$endif$

#show: letter-simple.with(
  sender: (
    name: "$sender.name$",
    address: "$sender.address$",
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
    #place(top + right, image("$logo$", width: 3.2cm), dx: -1.5cm, dy: 1.5cm)
  ],

  $if(annexes)$
  footer: [$for(annexes)$$annexes$$sep$\ $endfor$],
  $endif$
  
  $if(annotations)$
  annotations: [$annotations$],
  $endif$
  recipient: [
    $for(recipient)$
    $recipient$
    $sep$\
    $endfor$
  ],
  
  $if(reference-signs)$
  reference-signs: (
    $for(reference-signs/pairs)$
    ([$it.key$], [$it.value$]),
    $endfor$
  ),
  $endif$

  $if(signature)$
  signature-name: "$signature.name$",
  signature-title: "$signature.title$",
  $endif$
  
  date: "$date$",
  subject: "$subject$",
)
