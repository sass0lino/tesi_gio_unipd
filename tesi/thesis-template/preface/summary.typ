#import "../config/constants.typ": abstract
#import "../config/variables.typ": *
#import "../config/thesis-config.typ": glossary-style
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.8": *
#pagebreak(to: "odd")
#v(4em)

#text(24pt, weight: "semibold", abstract)

#v(1em)
Il presente documento descrive il lavoro svolto durante il periodo di stage curricolare, della durata di trecentoventi ore, dal laureando #text(myName) presso l'azienda #text(myCompany). Lo stage è stato condotto sotto la supervisione del tutor aziendale #myTutor, mentre il #text(myProf) ha ricoperto il ruolo di tutor accademico.
\ \
Questa tesi tratta la progettazione e lo sviluppo di un servizio per la generazione automatica di riepiloghi testuali all'interno della piattaforma SaaS di facility management di Datasoil. Il servizio reagisce agli eventi della piattaforma, recupera in modo deterministico i KPI dell'entità interessata tramite un semantic layer e ne affida l'esposizione in linguaggio naturale a un modello linguistico (LLM), con l'obiettivo di supportare l'operatore sul campo con un quadro sintetico e attendibile dello stato di asset, ispezioni e ticket.

