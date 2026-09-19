#let glossary-terms = (
  (
    key: "bm25",
    short: [BM25],
    long: [Best Matching 25],
    description: [Funzione di ordinamento usata nella ricerca testuale: valuta la pertinenza di un documento rispetto a una interrogazione in base alla frequenza dei termini. A differenza della ricerca vettoriale lavora sulle parole effettive ed è perciò efficace sulle corrispondenze esatte, come codici e sigle.]
  ),
  (
    key: "dlq",
    short: [DLQ],
    long: [Dead letter queue],
    description: [Coda di scarto sulla quale un sistema di messaggistica sposta i messaggi la cui elaborazione è fallita per un numero prestabilito di volte, togliendoli così dal ciclo dei tentativi e conservandoli per l'ispezione.]
  ),
  (
    key: "goroutine",
    short: [goroutine],
    description: [Unità di esecuzione concorrente del linguaggio Go, gestita dal runtime anziché dal sistema operativo e per questo molto più leggera di un thread.]
  ),
  (
    key: "jwt",
    short: [JWT],
    long: [JSON Web Token],
    description: [Formato standard di token che racchiude un insieme di dichiarazioni firmate digitalmente. Chi lo riceve può verificarne l'autenticità senza consultare l'emittente e servirsi del contenuto per stabilire identità e permessi di chi presenta il token.]
  ),
  (
    key: "kpi",
    short: [KPI],
    long: [Key Performance Indicator],
    description: [Indicatore quantitativo che misura una grandezza rilevante per il funzionamento di un'organizzazione o di un processo. In questa relazione i KPI sono i valori aggregati calcolati sulle entità della piattaforma, ad esempio il numero di ticket aperti o il tempo medio di risoluzione.]
  ),
  (
    key: "llm",
    short: [LLM],
    long: [Large Language Model],
    description: [Modello di apprendimento automatico addestrato su grandi quantità di testo, capace di comprendere e produrre linguaggio naturale. Genera il testo più probabile in funzione delle istruzioni ricevute, senza alcun confronto con una fonte di verità.]
  ),
  (
    key: "allucinazione",
    short: [allucinazione],
    description: [Affermazione prodotta da un modello linguistico che suona plausibile e ben formulata ma non corrisponde ad alcun dato reale. Nasce dal fatto che il modello ottimizza la plausibilità del testo, non la sua verità.]
  ),
  (
    key: "multi-tenancy",
    short: [multi-tenancy],
    description: [Modello architetturale in cui una sola installazione di un'applicazione serve più organizzazioni clienti, dette tenant, mantenendone i dati separati e inaccessibili gli uni agli altri.]
  ),
  (
    key: "parquet",
    short: [Parquet],
    description: [Formato di file per la memorizzazione di dati organizzati per colonne anziché per righe, pensato per le interrogazioni analitiche, che leggono poche colonne su molte righe.]
  ),
  (
    key: "rag",
    short: [RAG],
    long: [Retrieval-Augmented Generation],
    description: [Approccio in cui, prima di interrogare un modello linguistico, si recuperano da una base documentale i frammenti pertinenti alla domanda e li si forniscono al modello insieme ad essa, in modo che la risposta si fondi su documenti reali.]
  ),
  (
    key: "re-ranking",
    short: [re-ranking],
    description: [Fase successiva al recupero documentale, in cui i risultati ottenuti vengono riordinati da un secondo modello, più accurato e più costoso del primo, applicato solo al ristretto insieme dei candidati.]
  ),
  (
    key: "saas",
    short: [SaaS],
    long: [Software as a Service],
    description: [Modello di distribuzione del software in cui l'applicazione è eseguita e mantenuta dal fornitore e resa disponibile ai clienti attraverso la rete, senza che questi debbano installarla o gestirne l'infrastruttura.]
  ),
  (
    key: "semantic-layer",
    short: [semantic layer],
    description: [Strato intermedio fra le sorgenti dati e le applicazioni, in cui le metriche di business sono definite una sola volta e in modo dichiarativo. Le applicazioni le interrogano attraverso un'API e ottengono valori coerenti fra loro.]
  ),
  (
    key: "sns",
    short: [SNS],
    long: [Amazon Simple Notification Service],
    description: [Servizio di distribuzione di messaggi di AWS organizzato per argomenti (topic). Un messaggio pubblicato su un topic viene recapitato in copia a tutti i sottoscrittori, permettendo a più consumatori di ricevere lo stesso evento.]
  ),
  (
    key: "sqs",
    short: [SQS],
    long: [Amazon Simple Queue Service],
    description: [Servizio di code gestite di AWS. Un messaggio inserito in coda viene consegnato a un solo consumatore e rimosso soltanto dopo che questi ne ha dichiarato la corretta elaborazione, con garanzia di consegna almeno una volta.]
  ),
  (
    key: "staging",
    short: [staging],
    description: [Ambiente che riproduce quello di produzione con dati realistici, usato per le prove che precedono il rilascio senza incidere sul servizio in uso.]
  ),
  (
    key: "testcontainers",
    short: [testcontainers],
    description: [Libreria che permette a un test automatico di avviare un servizio reale (per esempio un database) dentro un container, utilizzarlo e distruggerlo al termine, così da verificare il codice contro il sistema vero anziché contro una sua imitazione.]
  ),
  (
    key: "text-to-sql",
    short: [Text-to-SQL],
    description: [Approccio in cui un modello linguistico traduce una domanda espressa in linguaggio naturale nell'interrogazione SQL corrispondente, che viene poi eseguita sul database.]
  ),
  (
    key: "geoc-id",
    short: [geoc_id],
    description: [Nome con cui la piattaforma di Datasoil identifica l'oggetto locativo a cui una sintesi si riferisce. Viaggia nel messaggio che ne richiede la produzione e individua la sintesi conservata nell'archivio insieme al `trigger`.]
  ),
  (
    key: "trigger",
    short: [trigger],
    description: [Nome dell'evento della piattaforma che dà origine a una sintesi, per esempio l'apertura di un ticket o il completamento di un'ispezione. Determina quali interrogazioni vengono eseguite e distingue fra loro le sintesi di una stessa entità.]
  ),
  (
    key: "idempotenza",
    short: [idempotenza],
    description: [Proprietà di un'operazione che, ripetuta più volte con gli stessi argomenti, produce lo stesso effetto di una singola esecuzione. È indispensabile quando l'infrastruttura può consegnare due volte lo stesso messaggio.]
  ),
  (
    key: "composition-root",
    short: [composition root],
    description: [Punto unico di un'applicazione, collocato il più vicino possibile al suo avvio, in cui i moduli vengono composti fra loro e le realizzazioni concrete vengono assegnate alle astrazioni usate dal resto del programma.]
  ),
  (
    key: "dependency-injection",
    short: [dependency injection],
    description: [Tecnica per cui un componente riceve dall'esterno, al momento della costruzione, le realizzazioni delle dipendenze di cui ha bisogno, invece di costruirsele da solo. La scelta delle realizzazioni spetta a un assemblatore esterno al componente.]
  ),
  (
    key: "duckdb",
    short: [DuckDB],
    description: [Sistema di gestione di basi di dati relazionali orientato alle interrogazioni analitiche, che viene eseguito all'interno del processo che lo utilizza anziché come servizio separato da installare e amministrare.]
  ),
  (
    key: "jsonb",
    short: [jsonb],
    description: [Tipo di dato di PostgreSQL che conserva un documento JSON in forma binaria anziché come testo. Rispetto al tipo `json` l'inserimento è più lento, ma il contenuto non va rianalizzato a ogni accesso e può essere indicizzato.]
  ),
  (
    key: "long-polling",
    short: [long polling],
    description: [Modalità di ricezione dei messaggi da una coda in cui la richiesta attende, entro un tempo massimo, che un messaggio diventi disponibile invece di rispondere subito vuota. Riduce le risposte vuote e il numero di chiamate necessarie.]
  ),
  (
    key: "ports-and-adapters",
    short: [ports and adapters],
    description: [Stile architetturale che permette a un'applicazione di essere guidata indifferentemente da utenti, programmi o test automatici, e di essere sviluppata e verificata separatamente dai dispositivi e dai database che userà in esercizio. Le porte sono le interfacce dichiarate dall'applicazione, gli adattatori le loro realizzazioni concrete.]
  ),
  (
    key: "tenant",
    short: [tenant],
    description: [In una soluzione multi-tenant, l'organizzazione cliente a cui appartengono dati e utenti. In questa relazione ogni tenant corrisponde a un'azienda cliente della piattaforma e dispone di un proprio database.]
  ),
  (
    key: "upsert",
    short: [upsert],
    description: [Operazione di scrittura che aggiorna il documento corrispondente al filtro se esiste e altrimenti ne crea uno nuovo. Per non produrre duplicati, i campi del filtro devono avere un indice univoco.]
  ),
  (
    key: "vista-materializzata",
    short: [vista materializzata],
    description: [Vista il cui risultato è conservato in forma di tabella anziché ricalcolato a ogni interrogazione. L'accesso è molto più rapido, ma i dati restano quelli dell'ultimo aggiornamento, che va richiesto esplicitamente.]
  ),
)