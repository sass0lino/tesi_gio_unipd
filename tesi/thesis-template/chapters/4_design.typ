#import "../config/thesis-config.typ": gl, glpl, glossary-style, linkfn
#pagebreak(to: "odd")

= Progettazione e sviluppo <cap:progettazione>
#text(style: "italic", [
    In questo capitolo descrivo l'architettura del servizio sviluppato e le principali scelte di progettazione e implementazione.
])
#v(1em)

== Architettura del servizio

// architettura event-driven, il layer di contesto, flusso completo:
// evento in coda -> query del tenant -> KPI da Cube -> LLM -> salvataggio

== Estrazione dei KPI

// multitenancy, JWT, query dinamiche su MongoDB, esecuzione parallela

== Generazione del riepilogo tramite LLM

// prompt di sistema, istruzioni per blocco, vincoli espositivi

== Caching e persistenza

// cache dei riepiloghi, force refresh, indice unico per tenant

== Integrazione con la coda

// consumer SQS, elaborazione parallela, spegnimento controllato,
// ElasticMQ per lo sviluppo locale
