#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.8": *
#import "../config/thesis-config.typ": gl, glpl, glossary-style, linkfn

= Introduzione <cap:introduzione>
#text(style: "italic", [
    In questo capitolo presento l'azienda ospitante e introduco il progetto di stage: le problematiche affrontate, la pianificazione, gli obiettivi e il prodotto realizzato.
])
#v(1em)

== L'azienda

Datasoil S.r.l. è una software house con sede a Padova, parte del gruppo internazionale eFM. Attraverso la propria piattaforma SaaS B2B, l'azienda porta intelligenza artificiale ed _execution_ mobile al centro delle _operations_, collegando mondo fisico e digitale in un unico layer operativo: dalle ispezioni alla manutenzione, fino alla gestione degli asset, le attività frammentate vengono trasformate in processi strutturati, scalabili e governabili. Datasoil opera nei settori _real estate_, industriale e manifatturiero, supportando organizzazioni complesse nell'evoluzione verso modelli operativi più integrati, predittivi e orientati al valore.

Il progetto di stage si colloca nell'ambito del _facility management_, ovvero la gestione integrata di edifici, impianti e asset aziendali, dove la piattaforma ruota attorno a tre entità fondamentali: gli *asset* (i beni gestiti, come impianti e attrezzature), le *ispezioni* (le verifiche periodiche condotte sugli asset) e i *ticket* (le segnalazioni e gli interventi di manutenzione).

Il prodotto è *multi-tenant*: una singola installazione serve più aziende clienti, i cui dati sono mantenuti rigorosamente separati. Come si vedrà nel corso del documento, questa caratteristica ha attraversato l'intero progetto di stage: dall'organizzazione dei dati, alla definizione delle metriche per i singoli clienti, fino alla configurazione delle interrogazioni per ciascun tenant.

== Il progetto e lo stage

=== Descrizione

Il progetto di stage nasce dall'esigenza, individuata nel piano di lavoro, di efficientare l'operatività dell'utente sul campo: restituire in modo automatico una sintesi dello stato di manutenzione e dei relativi interventi per le diverse tipologie di entità gestite dalla piattaforma.

In concreto, si tratta di sviluppare un servizio che, all'apertura della scheda di un asset (o di un'ispezione o di un ticket), generi automaticamente un *riepilogo testuale in linguaggio naturale* dello stato dell'oggetto, sfruttando i dati aziendali per garantire l'attendibilità del contenuto e un modello linguistico (LLM) per la sua esposizione.

Il servizio sviluppato è di tipo _event-driven_: reagisce agli eventi pubblicati dalla piattaforma su una coda (ad esempio il completamento di un'ispezione), recupera i KPI dell'entità interessata, ne affida la sintesi all'LLM e rende disponibile il riepilogo generato.

Lo stage si è svolto in modalità full-time per un totale di 320 ore, sotto la supervisione del tutor aziendale Pietro De Caro. Gli obiettivi erano fissati dal piano di lavoro concordato con l'azienda, che mi ha lasciato però ampia autonomia sul _come_ raggiungerli: per ciascun obiettivo ho valutato approcci alternativi, sviluppato prototipi per verificarne la fattibilità e consolidato le scelte attraverso frequenti momenti di confronto con il tutor.

=== Principali problematiche e relative soluzioni

Le principali problematiche riscontrate durante la realizzazione del progetto riguardano l'affidabilità dei contenuti generati dall'LLM e l'interfacciamento con i dati aziendali. Di seguito vengono analizzati i problemi specifici e le relative soluzioni adottate.

*1. Recupero deterministico dei dati per l'LLM*

_Descrizione:_ gli LLM eccellono nella produzione di testo fluente, ma se incaricati anche del recupero o del calcolo dei dati tendono a produrre _allucinazioni_, ovvero affermazioni plausibili ma non supportate dai dati reali. Gli approcci più diffusi per interrogare dati aziendali tramite LLM — il RAG e le tecniche Text-to-SQL — si sono rivelati, dallo studio preliminare, inadatti ai dati strutturati: in un contesto in cui il riepilogo supporta decisioni operative, un valore inventato non è accettabile.

_Soluzione:_ è stato introdotto un _semantic layer_ (Cube), uno strato intermedio che centralizza la definizione delle metriche e fornisce KPI "certificati", recuperati in modo completamente deterministico. All'LLM viene affidata soltanto l'esposizione in linguaggio naturale di valori già calcolati, con istruzioni che ne vincolano il comportamento ai soli dati forniti.

*2. Interfacciamento tra il semantic layer e il database aziendale*

_Descrizione:_ la piattaforma conserva i dati su MongoDB, un database NoSQL, mentre Cube opera su sorgenti relazionali. L'azienda disponeva di una soluzione temporanea, applicata a un solo cliente: il travaso dei dati in un campo `jsonb` su PostgreSQL, poi "srotolato" in una vista materializzata. Nel tentativo di rendere l'architettura più generale ho sperimentato l'interrogazione diretta del campo `jsonb` grezzo da parte di Cube, ottenendo però tempi di risposta proibitivi e configurazioni SQL molto difficili da mantenere; è stata valutata anche l'esportazione dei dati in formato Parquet, tecnicamente percorribile ma onerosa. Questa problematica ha assorbito una parte significativa del tempo di stage.

_Soluzione:_ in accordo con il tutor aziendale, l'ottimizzazione dell'interfacciamento — questione prettamente infrastrutturale — è stata messa in pausa per non bloccare l'avanzamento del progetto: lo sviluppo è proseguito sull'ambiente PostgreSQL già pronto e configurato, mantenendo l'architettura aperta a una futura generalizzazione.

*3. Gestione della multitenancy*

_Descrizione:_ i database dei vari clienti hanno schemi per lo più simili, ma presentano campi personalizzati; occorre inoltre garantire che ogni cliente possa accedere esclusivamente ai propri dati.

_Soluzione:_ per i data model è stata utilizzata la direttiva `extends` di Cube, che permette di condividere le definizioni comuni estendendole in modo granulare per ciascun cliente; la segregazione dei dati è garantita dall'autenticazione tramite token JWT prevista nativamente da Cube. Anche le interrogazioni per il recupero dei KPI sono configurate per singolo tenant su MongoDB, senza interventi sul codice del servizio.

*4. Definizione del perimetro dei KPI*

_Descrizione:_ una volta risolta la questione del recupero, restava da definire quali KPI fossero utili al riepilogo e in quale forma esporli: se sviluppare vere e proprie funzioni di analisi del dato (ad esempio il calcolo di trend), o se arricchire i KPI con dati qualitativi recuperati direttamente dal database.

_Soluzione:_ confrontandomi con il tutor aziendale ho scelto di mantenere il sistema semplice: KPI aggregati "grezzi", affidando all'LLM la loro descrizione in linguaggio naturale guidata da istruzioni specifiche per ciascun blocco di dati. L'arricchimento con dati qualitativi, pur esplorato con risultati interessanti, è stato accantonato per rimanere strettamente sui dati aggregati.

=== Pianificazione

Il progetto è stato suddiviso in fasi, dedicate dapprima alla comprensione del dominio e alla scelta dell'architettura, e in seguito allo sviluppo vero e proprio:

1. studio preliminare dell'approccio RAG e delle tecniche di interrogazione di dati tramite LLM;
2. analisi degli approcci per i dati strutturati e scelta del semantic layer;
3. sviluppo di prototipi con Cube per validarne la fattibilità: gestione della multitenancy, autenticazione JWT, interfacciamento con i dati;
4. studio del linguaggio Go;
5. sviluppo del servizio: integrazione con Cube e con le API dell'LLM, gestione dinamica delle query, caching dei riepiloghi;
6. integrazione con la coda SQS e predisposizione dell'ambiente di sviluppo locale;
7. #highlight[\[DA COMPLETARE A FINE STAGE: fase conclusiva, requisiti in rinegoziazione\]]

=== Obiettivi

Il piano di lavoro concordato con l'azienda definisce i seguenti obiettivi obbligatori:

- *O01* — Ricezione di eventi asincroni dalle altre componenti della piattaforma, con caricamento delle configurazioni del cliente e delle entità interessate;
- *O02* — Valutazione di KPI specifici per entità e cliente, e interfacciamento con l'IA generativa per la produzione della sintesi testuale;
- *O03* — Indicizzazione delle entità per il recupero di documenti non strutturati (approccio RAG);
- *O04* — Ricezione di richieste utente in modalità agente, con recupero documentale e risposta.

A questi si aggiunge l'obiettivo desiderabile *D01*, l'integrazione nell'architettura e nel ciclo di rilascio della piattaforma.

Il lavoro si è concentrato dapprima sul flusso relativo ai dati strutturati (O01 e O02), portandolo a un livello di completezza e solidità vicino all'integrazione in produzione. #highlight[\[DA COMPLETARE A FINE STAGE: esito di O03 e O04, requisiti in rinegoziazione\]]

== Il prodotto finale

Il servizio realizzato copre l'intero flusso previsto per i dati strutturati: riceve gli eventi dalla coda, recupera le interrogazioni configurate per il tenant, estrae i KPI tramite il semantic layer, genera il riepilogo con l'LLM e lo rende persistente, con la possibilità di servire le richieste successive dalla cache. Il servizio è progettato per essere configurabile per singolo cliente senza interventi sul codice ed è corredato di un ambiente di sviluppo locale che ne riproduce fedelmente l'infrastruttura di produzione.

Per un'analisi approfondita del risultato ottenuto si rimanda al @cap:conclusioni[Capitolo].

== Organizzazione del testo

Questa sezione esplicita l'organizzazione del documento, descrivendo brevemente il contenuto di ogni capitolo.

Il resto del documento è organizzato come segue: il @cap:tecnologie[Capitolo] presenta gli strumenti e le tecnologie utilizzate durante lo stage; il @cap:analisi-requisiti[Capitolo] descrive lo studio preliminare degli approcci possibili e l'analisi dei requisiti; il @cap:progettazione[Capitolo] illustra la progettazione e lo sviluppo del servizio; il @cap:verifica[Capitolo] descrive le attività di verifica e validazione; il @cap:conclusioni[Capitolo] conclude il documento con una valutazione del lavoro svolto e delle prospettive future.

Riguardo la stesura del testo sono state adottate le seguenti convenzioni tipografiche:

- gli acronimi, le abbreviazioni e i termini di uso non comune vengono definiti nel #link(<glossary>)[glossario], situato alla fine del documento, e alla loro prima occorrenza sono indicati con la nomenclatura #glossary-style[termine]\;
- i termini in lingua straniera o facenti parte del gergo tecnico sono evidenziati con il carattere _corsivo_;
- i nomi di funzioni, variabili e altri elementi di codice sono scritti con carattere `monospaziato`;
- le citazioni a risorse presenti nella #link(<bibliography>)[bibliografia] sono affiancate dal rispettivo numero identificativo, es. $[1]$.
