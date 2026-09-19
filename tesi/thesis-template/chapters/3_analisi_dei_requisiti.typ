#import "data/requirements_list.typ": getFR, getQR, getCR
#import "../config/thesis-config.typ": req, obj

#pagebreak(to:"odd")

// le tabelle dei requisiti sono lunghe: senza questo si spezzerebbero male tra le pagine
#show figure: set block(breakable: true)

= Analisi dei requisiti<cap:analisi-requisiti>

#text(style: "italic", [
    In questo capitolo delimito il confine del sistema, individuo gli attori e i casi d'uso, e da questi derivo i requisiti, classificati per tipologia e priorità e collegati alle rispettive fonti.
])
#v(1em)

Il sistema oggetto dell'analisi è il servizio di contesto sviluppato durante lo stage. L'interfaccia con cui l'operatore visualizza il riepilogo e ne richiede la produzione appartiene invece alla piattaforma, e resta perciò fuori dal confine considerato.

I requisiti raccolti in questo capitolo esprimono che cosa il sistema deve fare, cioè le capacità che un osservatore esterno può riscontrare, e non il modo in cui tali capacità vengono realizzate. Le soluzioni adottate sono decisioni di progettazione e trovano spazio nel @cap:progettazione[Capitolo].

== Casi d'uso

L'analisi parte da ciò che accade sulla piattaforma, perché è da lì che nascono le richieste rivolte al servizio. Dal punto di vista dell'operatore la funzionalità ha due soli esiti, illustrati in @fig:flusso-operatore: aprendo la scheda di un'entità, il riepilogo è già disponibile, oppure è assente e se ne può richiedere la produzione. Da queste due possibilità nascono le interazioni descritte nel seguito.

// sorgente del diagramma: tesi/puml/flusso-operatore.puml
#figure(
  caption: [La funzionalità dal punto di vista dell'operatore.],
  image("../images/flusso-operatore.png", width: 100%, alt: "Diagramma di flusso. L'operatore apre la scheda dell'entità. Se esiste un riepilogo corrispondente allo stato attuale, viene mostrato. Altrimenti viene proposto il comando per richiederne la produzione: l'operatore lo attiva e il riepilogo viene prodotto e mostrato.")
)<fig:flusso-operatore>

=== Attori

L'operatore non contatta mai il servizio in modo diretto. Agisce sull'interfaccia della piattaforma, ed è la piattaforma a rivolgersi al servizio. L'unico attore individuato è quindi la piattaforma SaaS, che invia le richieste e ne riceve gli esiti.

L'operatore sul campo beneficia della funzionalità, ma non è un attore del sistema in esame perché non interagisce mai con il suo confine. È un portatore di interesse, e la sua esigenza è ciò che motiva l'intera analisi.

Non sono stati individuati attori secondari. I sistemi da cui il servizio ottiene i dati e con cui produce il testo del riepilogo non sono un presupposto dell'analisi: derivano dalle scelte architetturali illustrate nel @cap:progettazione[Capitolo].

=== Interazioni previste

Tra la piattaforma e il servizio sono previste due interazioni, rappresentate in @fig:casi-uso e descritte ciascuna da un caso d'uso. La prima è la *consultazione* di un riepilogo, la seconda è la *richiesta di produzione* di un riepilogo non ancora disponibile.

// sorgente del diagramma: tesi/puml/casi-uso.puml
#figure(
  caption: [Diagramma dei casi d'uso del servizio.],
  image("../images/casi-uso.png", width: 90%, alt: "Diagramma dei casi d'uso. L'unico attore è la piattaforma SaaS, collegata a due casi d'uso del servizio di contesto: UC1, consultazione del riepilogo, e UC2, richiesta di produzione del riepilogo.")
)<fig:casi-uso>

==== UC1: Consultazione del riepilogo <uc:consultazione>

/ Attore principale: Piattaforma SaaS
/ Scenario principale: la piattaforma chiede al servizio il riepilogo di una determinata entità, e il servizio la restituisce.
/ Precondizioni: il servizio è operativo e la richiesta riguarda un'entità del tenant per cui la piattaforma è autorizzata.
/ Postcondizioni: la piattaforma dispone di un riepilogo che corrisponde allo stato attuale dell'entità.
/ Estensioni: se per l'entità non è disponibile alcun riepilogo, il servizio lo segnala. La piattaforma può allora proporre all'operatore di richiederne la produzione (@uc:produzione).
/ Trigger: un operatore apre la scheda dell'entità sulla piattaforma.

==== UC2: Richiesta di produzione del riepilogo <uc:produzione>

/ Attore principale: Piattaforma SaaS
/ Scenario principale: la piattaforma chiede la produzione del riepilogo per una determinata entità e un determinato evento. Il servizio individua i dati previsti per quel caso, li recupera, ne produce un riepilogo in linguaggio naturale e lo rende disponibile alle consultazioni successive.
/ Precondizioni: il servizio è operativo, e per quel tenant e quel tipo di evento è definito l'insieme dei dati da comporre.
/ Postcondizioni: il riepilogo dell'entità è disponibile alla consultazione.
/ Estensioni: se una parte dei dati previsti non è disponibile, viene omessa dal riepilogo anziché comprometterne la produzione. Se la produzione non va a buon fine non viene reso disponibile alcun riepilogo, e la richiesta viene ripresentata.
/ Trigger: un operatore richiede la produzione dalla scheda dell'entità, oppure un evento della piattaforma la richiede automaticamente.

=== Variabilità del contenuto

I due casi d'uso non si moltiplicano per il tipo di entità: ispezioni, ticket e asset condividono lo stesso schema di interazione, e ciò che cambia da un caso all'altro sono soltanto i dati che compongono il riepilogo.

Questi variano lungo due dimensioni. La prima è il tipo di entità, perché di un'ispezione e di un ticket interessano cose diverse. La seconda è il cliente: ogni tenant misura la propria operatività a modo proprio, dispone di dati differenti e attribuisce importanza a indicatori differenti, per cui il riepilogo di un'ispezione non ha lo stesso contenuto presso clienti diversi.

Quali dati comporre non è quindi un requisito del sistema, ma una sua configurazione. Il requisito è che il sistema sappia differenziare il contenuto in base al tipo di entità e all'evento (#req("RF-OB_03")) e che tale differenziazione sia definibile per ciascun cliente senza modifiche al codice (#req("RQA-DE_01")); quali indicatori compaiano poi nel riepilogo di un determinato cliente non appartiene a questo capitolo. Il meccanismo che rende possibile la configurazione è descritto nel @cap:progettazione[Capitolo].

== Classificazione dei requisiti

I requisiti individuati sono identificati da un codice così strutturato:

#align(center)[*[TIPO]-[PRIORITÀ]\_[NUMERO]*]

dove il *tipo* assume uno dei seguenti valori:

/ RF: requisito funzionale, ovvero una capacità che il sistema deve offrire;
/ RQA: requisito qualitativo, ovvero una proprietà che il comportamento del sistema deve rispettare;
/ RV: requisito di vincolo, ovvero una condizione imposta dall'ambiente in cui il sistema si inserisce.

e la *priorità* uno tra:

/ OB: obbligatorio, necessario al funzionamento della soluzione;
/ DE: desiderabile, di valore riconoscibile ma non indispensabile;
/ OP: opzionale, possibile sviluppo successivo.

Due requisiti funzionali compaiono tra i desiderabili e gli opzionali pur derivando da obiettivi che il piano di lavoro classificava come obbligatori, e conviene chiarirlo prima di leggere le tabelle. Si tratta di #req("RF-DE_01") e #req("RF-OP_01"), corrispondenti agli obiettivi #obj("O03") e #obj("O04"), relativi al recupero di informazioni da documenti non strutturati e all'interazione in modalità agente. In accordo con il tutor aziendale il perimetro del lavoro è stato concentrato sui dati strutturati, per le ragioni esposte nel @cap:introduzione[Capitolo], e i due requisiti sono stati ricollocati di conseguenza. Il @cap:conclusioni[Capitolo] li riprende tra gli sviluppi futuri.

Tra i requisiti di vincolo rientrano soltanto le condizioni che l'azienda ha effettivamente imposto, ovvero il linguaggio di sviluppo, la sorgente dati esistente e l'infrastruttura di comunicazione già adottata dalla piattaforma. Le altre tecnologie impiegate non compaiono qui perché sono state scelte nel corso del progetto: sono quindi decisioni di progettazione, e vengono discusse nel @cap:progettazione[Capitolo].

=== Requisiti funzionali

#figure(
  caption: [Requisiti funzionali.],
  table(
    columns: (auto, 3fr, 2fr),
    align: (left + horizon, left, left + horizon),
    fill: (x, y) => if y == 0 { luma(230) },
    table.header([*Codice*], [*Descrizione*], [*Fonte*]),
    ..getFR(getLen: false).flatten()
  )
)<tab:requisiti-funzionali>

=== Requisiti qualitativi

#figure(
  caption: [Requisiti qualitativi.],
  table(
    columns: (auto, 3fr, 2fr),
    align: (left + horizon, left, left + horizon),
    fill: (x, y) => if y == 0 { luma(230) },
    table.header([*Codice*], [*Descrizione*], [*Fonte*]),
    ..getQR(getLen: false).flatten()
  )
)<tab:requisiti-qualitativi>

Il requisito #req("RQA-DE_02"), sulla lunghezza del riepilogo, compare tra i desiderabili e non tra gli obbligatori. La ragione è che nulla nel sistema dipende dal suo rispetto: il servizio funziona e il riepilogo resta utilizzabile anche quando il testo eccede, e l'interfaccia che imporrebbe un vincolo di spazio non è ancora stata realizzata. Il suo valore è rivolto a uno scenario futuro, quello di entità con una storia molto lunga, dove i dati da riportare eccederebbero qualunque spazio disponibile e occorrerebbe scegliere quali riportare. Il @cap:verifica[Capitolo] ne riporta la misura e l'esito.

=== Requisiti di vincolo

#figure(
  caption: [Requisiti di vincolo.],
  table(
    columns: (auto, 3fr, 2fr),
    align: (left + horizon, left, left + horizon),
    fill: (x, y) => if y == 0 { luma(230) },
    table.header([*Codice*], [*Descrizione*], [*Fonte*]),
    ..getCR(getLen: false).flatten()
  )
)<tab:requisiti-vincolo>

== Tracciamento dei requisiti

Le matrici seguenti collegano ciascun requisito alla propria origine e ai casi d'uso che lo hanno generato. Servono a due verifiche: che ogni requisito abbia una giustificazione, e che ogni caso d'uso trovi nei requisiti tutto ciò che serve a realizzarlo.

=== Riepilogo quantitativo

#figure(
  caption: [Riepilogo dei requisiti per tipologia e priorità.],
  table(
    columns: 5,
    align: (left + horizon, center + horizon, center + horizon, center + horizon, center + horizon),
    table.header([*Tipologia*], [*Obbligatori*], [*Desiderabili*], [*Opzionali*], [*Totale*]),
    [Funzionali (RF)],
      [#getFR(getLen: true).at(0)], [#getFR(getLen: true).at(1)], [#getFR(getLen: true).at(2)], [*#getFR(getLen: true).sum()*],
    [Qualitativi (RQA)],
      [#getQR(getLen: true).at(0)], [#getQR(getLen: true).at(1)], [#getQR(getLen: true).at(2)], [*#getQR(getLen: true).sum()*],
    [Di vincolo (RV)],
      [#getCR(getLen: true).at(0)], [#getCR(getLen: true).at(1)], [#getCR(getLen: true).at(2)], [*#getCR(getLen: true).sum()*],
    [*Totale*],
      [*#{getFR(getLen: true).at(0) + getQR(getLen: true).at(0) + getCR(getLen: true).at(0)}*],
      [*#{getFR(getLen: true).at(1) + getQR(getLen: true).at(1) + getCR(getLen: true).at(1)}*],
      [*#{getFR(getLen: true).at(2) + getQR(getLen: true).at(2) + getCR(getLen: true).at(2)}*],
      [*#{getFR(getLen: true).sum() + getQR(getLen: true).sum() + getCR(getLen: true).sum()}*],
  )
)<tab:riepilogo-requisiti>

=== Tracciamento fonte-requisito

#figure(
  caption: [Tracciamento tra fonti e requisiti.],
  table(
    columns: (auto, 1fr),
    align: (left + horizon, left),
    fill: (x, y) => if y == 0 { luma(230) },
    table.header([*Fonte*], [*Requisiti generati*]),
    [Piano di lavoro (#obj("O01"))], [#req("RF-OB_08"), #req("RQA-OB_04")],
    [Piano di lavoro (#obj("O02"))], [#req("RF-OB_01"), #req("RF-OB_03"), #req("RQA-OB_01")],
    [Piano di lavoro (#obj("O03"))], [#req("RF-DE_01")],
    [Piano di lavoro (#obj("O04"))], [#req("RF-OP_01")],
    [Piano di lavoro (#obj("D01"))], [#req("RV-DE_01")],
    [Riunioni con il tutor aziendale], [#req("RF-OB_02"), #req("RF-OB_04"), #req("RF-OB_05"), #req("RF-OB_06"), #req("RF-OB_07"), #req("RQA-OB_02"), #req("RQA-DE_02")],
    [Analisi interna], [#req("RQA-OB_03"), #req("RQA-OB_05"), #req("RQA-OB_06"), #req("RQA-OB_07"), #req("RQA-DE_01")],
    [Vincoli aziendali], [#req("RV-OB_01"), #req("RV-OB_02"), #req("RV-OB_03")],
  )
)<tab:tracciamento-fonti>

=== Tracciamento caso d'uso-requisito

#figure(
  caption: [Tracciamento tra casi d'uso e requisiti.],
  table(
    columns: (auto, 1fr),
    align: (left + horizon, left),
    fill: (x, y) => if y == 0 { luma(230) },
    table.header([*Caso d'uso*], [*Requisiti coinvolti*]),
    [#link(<uc:consultazione>)[UC1: Consultazione]], [#req("RF-OB_04"), #req("RF-OB_06"), #req("RF-OB_07"), #req("RQA-OB_04"), #req("RQA-OB_06")],
    [#link(<uc:produzione>)[UC2: Richiesta di produzione]], [#req("RF-OB_01"), #req("RF-OB_02"), #req("RF-OB_03"), #req("RF-OB_05"), #req("RF-OB_06"), #req("RF-OB_08"), #req("RQA-OB_01"), #req("RQA-OB_02"), #req("RQA-OB_03"), #req("RQA-OB_04"), #req("RQA-OB_05"), #req("RQA-OB_06"), #req("RQA-OB_07"), #req("RQA-DE_01"), #req("RQA-DE_02")],
  )
)<tab:tracciamento-casi-uso>

I requisiti #req("RF-DE_01") e #req("RF-OP_01") non compaiono nella matrice dei casi d'uso. Derivano direttamente dal piano di lavoro e riguardano capacità che il perimetro dello stage non comprende: i relativi casi d'uso andranno definiti nel momento in cui verranno affrontate.