#import "../config/constants.typ": figuresList, tablesList, sourceCodeList
#set page(numbering: "i")
#pagebreak(to: "odd")

#[
  #show outline.entry.where(level: 1): it => {
    linebreak()
    link(it.element.location(), strong(it))
    h(1fr)
  }
  #outline(
    depth: 5
  )
]

#pagebreak()

#outline(
  title: figuresList,
  target: figure.where(kind: image)
)

#pagebreak()

#outline(
    title: tablesList,
    target: figure.where(kind: table),
)

// elenco dei codici sorgente tolto: i listati non sono figure con didascalia, quindi risultava vuoto
// #v(8em)
//
// #outline(
//     title: sourceCodeList,
//     target: figure.where(kind: raw),
// )
