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

Nel servizio sviluppato MongoDB svolge tre ruoli: contiene la configurazione delle interrogazioni per il recupero dei KPI, che ogni tenant può così definire senza modifiche al codice; custodisce i riepiloghi prodotti; ed è la sorgente da cui vengono lette le impostazioni del tenant che ne condizionano il contenuto, ovvero la lingua e il fuso orario.

== Cube

Cube è un _semantic layer_ open source: uno strato intermedio che si frappone tra le sorgenti dati e le applicazioni, centralizzando la definizione delle metriche di business. Invece di distribuire la logica di calcolo dei KPI tra le varie applicazioni, con il rischio di definizioni divergenti, le metriche vengono definite una sola volta nei _data model_ di Cube, e le applicazioni le interrogano tramite API ottenendo valori consistenti e, in questo senso, "certificati".

Nel servizio sviluppato Cube è la sorgente di tutti i valori che compaiono nel riepilogo: le metriche sono definite nei suoi modelli dati e il servizio le interroga tramite API. Le ragioni per cui è stato scelto, e il modello dati costruito durante lo stage, sono discussi nel @cap:progettazione[Capitolo].

== PostgreSQL

PostgreSQL è il database relazionale su cui Cube esegue le proprie interrogazioni. Non è la sorgente originaria dei dati, che resta MongoDB, ma il punto in cui questi vengono resi disponibili in forma relazionale: i documenti sono travasati in una tabella e da lì esposti in una vista materializzata, le cui colonne sono ciò su cui i _data model_ di Cube risultano definiti.

Il passaggio esiste perché Cube è progettato per operare su sorgenti relazionali, mentre la piattaforma conserva i propri dati in documenti. La soluzione era già predisposta dall'azienda per un cliente, e l'ho adottata per non fermare lo sviluppo su una questione infrastrutturale: le alternative valutate e le ragioni della scelta sono discusse nel @cap:progettazione[Capitolo].

== Modelli linguistici e API OpenAI

I modelli linguistici di grandi dimensioni (Large Language Model, LLM) sono modelli di apprendimento automatico addestrati su grandi quantità di testo, capaci di comprendere e produrre linguaggio naturale. Nel progetto l'LLM è impiegato con un ruolo deliberatamente circoscritto: non gli è richiesto di calcolare o dedurre alcun dato, ma soltanto di esporre in un testo scorrevole i KPI che gli vengono forniti, seguendo istruzioni che ne vincolano il comportamento ai soli dati presenti.

L'interazione avviene tramite le API di OpenAI, utilizzando l'SDK ufficiale per Go. Ogni generazione è una chiamata indipendente, composta da un messaggio di sistema, che definisce regole e vincoli espositivi, e da un messaggio utente contenente i dati, serializzati in JSON, corredati dalle istruzioni di lettura specifiche di ciascun blocco.

== Amazon SQS, SNS ed ElasticMQ

Amazon Simple Queue Service (SQS) è il servizio di code gestite di AWS, utilizzato in Datasoil per la comunicazione asincrona tra le componenti della piattaforma. Una coda disaccoppia chi produce messaggi da chi li consuma: il produttore pubblica e prosegue, il consumatore elabora al proprio ritmo, e un messaggio la cui elaborazione fallisce torna disponibile per un nuovo tentativo.

Amazon Simple Notification Service (SNS) è il servizio di distribuzione di messaggi per argomenti dello stesso fornitore, e supplisce a un limite delle code: SQS consegna ciascun messaggio a un solo consumatore, quindi due servizi non possono ricevere lo stesso evento. Un messaggio pubblicato su un _topic_ SNS viene invece recapitato in copia a tutti i sottoscrittori, tra i quali possono figurare altrettante code SQS. È il meccanismo che consente al servizio di ricevere gli eventi con cui la piattaforma segnala la modifica di un'entità, che hanno già altri destinatari, senza sottrarli a questi ultimi.

Il servizio sviluppato consuma due code distinte, una per ciascun comando che può ricevere: la richiesta di produzione di un riepilogo e la segnalazione che un'entità è stata modificata. Per il consumo si appoggia a un package sviluppato internamente dall'azienda, che si fa carico dell'intero dialogo con SQS: la ricezione dei messaggi tramite _long polling_, la loro elaborazione in parallelo da parte di un numero configurabile di _worker_, la cancellazione dalla coda dei soli messaggi elaborati con successo, così che quelli falliti vengano automaticamente riproposti, e l'arresto controllato del consumatore. Al package viene fornita unicamente la funzione di elaborazione del singolo messaggio, nella quale risiede la logica specifica del servizio.

Per lo sviluppo e i test in locale è stato utilizzato ElasticMQ, un server che espone un'API compatibile con SQS: il codice del servizio rimane identico a quello di produzione, cambia soltanto l'indirizzo della coda nella configurazione.

== Docker

Docker è la piattaforma di containerizzazione utilizzata per riprodurre in locale l'infrastruttura necessaria allo sviluppo: l'istanza di Cube, il database MongoDB e la coda ElasticMQ vengono eseguiti come container, garantendo un ambiente di lavoro replicabile e vicino a quello di produzione.

Docker è impiegato anche dai test automatici, che se ne servono per avviare istanze temporanee di MongoDB secondo il meccanismo descritto nella sezione seguente.

== Strumenti per i test

I test automatici del servizio sono scritti con il package `testing` della libreria standard di Go, senza librerie di asserzione esterne. È l'uso prevalente nell'ecosistema del linguaggio: la libreria standard si occupa dell'esecuzione, del confronto dei risultati e della misura della copertura, e un framework aggiuntivo introdurrebbe una dipendenza senza coprire un'esigenza rimasta scoperta.

A essa si affiancano due strumenti per i casi in cui il codice da verificare dialoga con l'esterno. Il package `net/http/httptest`, anch'esso nella libreria standard, esegue una richiesta HTTP direttamente sul gestore e ne raccoglie la risposta, senza bisogno di avviare un server né di occupare una porta di rete. La libreria `testcontainers` permette invece a un test di avviare un servizio reale dentro un container, utilizzarlo e distruggerlo al termine: nel progetto se ne serve per eseguire le interrogazioni su un'istanza vera di MongoDB, anziché su una sua imitazione che verificherebbe soltanto le chiamate e non il loro esito.

== Librerie di supporto

Oltre alle tecnologie principali, il servizio si appoggia ad alcune librerie consolidate dell'ecosistema Go: `Viper` per la gestione della configurazione da file e variabili d'ambiente, `Resty` per le chiamate HTTP verso le API di Cube e la libreria ufficiale `mongo-driver` per l'accesso a MongoDB.

Il canale sincrono con cui la piattaforma consulta i riepiloghi è invece realizzato con il solo package `net/http` della libreria standard di Go, senza ricorrere a framework esterni: le esigenze del servizio si limitano a un singolo _endpoint_ di lettura, e la libreria standard le copre integralmente.
