#import "../config/thesis-config.typ": gl, glpl, glossary-style, linkfn
#pagebreak(to: "odd")

= Strumenti e tecnologie utilizzate <cap:tecnologie>
#text(style: "italic", [
    In questo capitolo presento le tecnologie utilizzate durante lo stage, motivandone per ciascuna il ruolo all'interno del progetto.
])
#v(1em)

== Go

Go è il linguaggio di programmazione utilizzato da Datasoil per lo sviluppo dei servizi backend, ed è il linguaggio in cui è stato scritto l'intero servizio oggetto dello stage. Nato in Google, Go privilegia la semplicità e la leggibilità del codice: offre una sintassi essenziale, una tipizzazione statica con tempi di compilazione rapidi, una libreria standard ricca e la compilazione in un singolo eseguibile, caratteristica che ne semplifica la distribuzione. Il linguaggio si distingue inoltre per il supporto nativo alla concorrenza, tramite le _goroutine_ (thread leggeri gestiti dal runtime) e i canali di comunicazione tra esse.

Non avendo esperienza pregressa con il linguaggio, una parte dello stage è stata dedicata al suo apprendimento.

== MongoDB

MongoDB è un database NoSQL orientato ai documenti: i dati sono memorizzati come documenti in formato BSON (una rappresentazione binaria di JSON) raggruppati in _collection_, senza uno schema rigido imposto a priori. È il database utilizzato da Datasoil per la persistenza dei dati, organizzati secondo il modello multi-tenant: un database logico per ciascun cliente.

Nel servizio sviluppato MongoDB svolge un duplice ruolo: contiene la configurazione delle interrogazioni per il recupero dei KPI — così che ogni tenant possa definire le proprie senza modifiche al codice — e ospita la cache dei riepiloghi generati, evitando di invocare inutilmente il modello linguistico per richieste già elaborate.

== Cube

Cube è un _semantic layer_ open source: uno strato intermedio che si frappone tra le sorgenti dati e le applicazioni, centralizzando la definizione delle metriche di business. Invece di distribuire la logica di calcolo dei KPI tra le varie applicazioni — con il rischio di definizioni divergenti — le metriche vengono definite una sola volta nei _data model_ di Cube, e le applicazioni le interrogano tramite API ottenendo valori consistenti e, in questo senso, "certificati".

Come approfondito nel @cap:analisi-requisiti[Capitolo], l'adozione di un semantic layer è la soluzione scelta per garantire che i dati forniti al modello linguistico siano recuperati in modo deterministico. Cube è stato preferito allo sviluppo di un backend dedicato perché offre già pronte funzionalità essenziali quali il caching delle interrogazioni, le API di accesso e un sistema di sicurezza multi-tenant basato su token JWT, sfruttato nel progetto per garantire la segregazione dei dati tra i clienti.

== Modelli linguistici e API OpenAI

I modelli linguistici di grandi dimensioni (Large Language Model, LLM) sono modelli di apprendimento automatico addestrati su grandi quantità di testo, capaci di comprendere e produrre linguaggio naturale. Nel progetto l'LLM è impiegato con un ruolo deliberatamente circoscritto: non gli è richiesto di calcolare o dedurre alcun dato, ma soltanto di esporre in un testo scorrevole i KPI che gli vengono forniti, seguendo istruzioni che ne vincolano il comportamento ai soli dati presenti.

L'interazione avviene tramite le API di OpenAI, utilizzando l'SDK ufficiale per Go. Ogni generazione è una chiamata indipendente, composta da un messaggio di sistema — che definisce regole e vincoli espositivi — e da un messaggio utente contenente i dati, serializzati in JSON, corredati dalle istruzioni di lettura specifiche di ciascun blocco.

== Amazon SQS ed ElasticMQ

Amazon Simple Queue Service (SQS) è il servizio di code gestite di AWS, utilizzato in Datasoil per la comunicazione asincrona tra le componenti della piattaforma. Una coda disaccoppia chi produce messaggi da chi li consuma: il produttore pubblica e prosegue, il consumatore elabora al proprio ritmo, e un messaggio la cui elaborazione fallisce torna disponibile per un nuovo tentativo.

Il servizio sviluppato è un consumatore SQS, e per il consumo della coda si appoggia a un package sviluppato internamente dall'azienda, che si fa carico dell'intero dialogo con SQS: la ricezione dei messaggi tramite _long polling_, la loro elaborazione in parallelo da parte di un numero configurabile di _worker_, la cancellazione dalla coda dei soli messaggi elaborati con successo — così che quelli falliti vengano automaticamente riproposti — e l'arresto controllato del consumatore. Al package viene fornita unicamente la funzione di elaborazione del singolo messaggio, nella quale risiede la logica specifica del servizio.

Per lo sviluppo e i test in locale è stato utilizzato ElasticMQ, un server che espone un'API compatibile con SQS: il codice del servizio rimane identico a quello di produzione, cambia soltanto l'indirizzo della coda nella configurazione.

== Docker

Docker è la piattaforma di containerizzazione utilizzata per riprodurre in locale l'infrastruttura necessaria allo sviluppo: l'istanza di Cube, il database MongoDB e la coda ElasticMQ vengono eseguiti come container, garantendo un ambiente di lavoro replicabile e vicino a quello di produzione.

== Librerie di supporto

Oltre alle tecnologie principali, il servizio si appoggia ad alcune librerie consolidate dell'ecosistema Go: *Viper* per la gestione della configurazione da file e variabili d'ambiente, *Resty* per le chiamate HTTP verso le API di Cube e la libreria ufficiale *mongo-driver* per l'accesso a MongoDB.
