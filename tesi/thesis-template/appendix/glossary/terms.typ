#let glossary-terms = (
  (
    key: "bm25",
    short: [BM25],
    long: [Best Matching 25],
    description: [Funzione di ordinamento usata nella ricerca testuale, che valuta la pertinenza di un documento rispetto a una interrogazione sulla base della frequenza dei termini. A differenza della ricerca vettoriale opera sulle parole effettive, ed è quindi efficace sulle corrispondenze esatte come codici e sigle.]
  ),
  (
    key: "ci",
    short: [CI],
    long: [Continuous integration],
    description: [Pratica di programmazione che prevede la frequente integrazione del codice prodotto verso il ramo principale del repository Git. Generalmente prima di poter fare questa integrazione il sistema esegue dei test automatici (compilazione, unità, ecc...).]
  ),
  (
    key: "dlq",
    short: [DLQ],
    long: [Dead letter queue],
    description: [Coda di scarto sulla quale un sistema di messaggistica sposta i messaggi la cui elaborazione è fallita per un numero prestabilito di volte, così da toglierli dal ciclo dei tentativi e conservarli per l'ispezione.]
  ),
  (
    key: "goroutine",
    short: [goroutine],
    description: [Unità di esecuzione concorrente del linguaggio Go, gestita dal runtime del linguaggio anziché dal sistema operativo, e per questo molto più leggera di un thread.]
  ),
  (
    key: "jwt",
    short: [JWT],
    long: [JSON Web Token],
    description: [Formato standard di token che racchiude un insieme di dichiarazioni firmate digitalmente. Chi lo riceve può verificarne l'autenticità senza consultare l'emittente, e usarne il contenuto per stabilire identità e permessi di chi presenta il token.]
  ),
  (
    key: "kpi",
    short: [KPI],
    long: [Key Performance Indicator],
    description: [Indicatore quantitativo che misura una grandezza rilevante per il funzionamento di un'organizzazione o di un processo. In questa relazione i KPI sono i valori aggregati calcolati sulle entità della piattaforma, come il numero di ticket aperti o il tempo medio di risoluzione.]
  ),
  (
    key: "llm",
    short: [LLM],
    long: [Large Language Model],
    description: [Modello di apprendimento automatico addestrato su grandi quantità di testo, capace di comprendere e produrre linguaggio naturale. Genera il testo più probabile date le istruzioni ricevute, senza alcuna verifica rispetto a una fonte.]
  ),
  (
    key: "allucinazione",
    short: [allucinazione],
    description: [Affermazione prodotta da un modello linguistico che risulta plausibile e ben formulata ma non corrisponde ad alcun dato reale. È la conseguenza del fatto che il modello ottimizza la plausibilità del testo e non la sua verità.]
  ),
  (
    key: "multi-tenancy",
    short: [multi-tenancy],
    description: [Modello architetturale in cui una sola installazione di un'applicazione serve più organizzazioni clienti, dette tenant, mantenendone i dati separati e non accessibili le une alle altre.]
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
    description: [Approccio in cui, prima di interrogare un modello linguistico, si recuperano da una base documentale i frammenti pertinenti alla domanda e li si forniscono al modello insieme ad essa, così che la risposta si fondi su documenti reali.]
  ),
  (
    key: "re-ranking",
    short: [re-ranking],
    description: [Fase successiva a un recupero documentale, in cui i risultati ottenuti vengono riordinati da un secondo modello, più accurato e più costoso del primo, applicato al solo insieme ristretto dei candidati.]
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
    description: [Strato intermedio fra le sorgenti dati e le applicazioni, nel quale le metriche di business sono definite una sola volta e in modo dichiarativo. Le applicazioni le interrogano attraverso un'API, ottenendo valori coerenti fra loro.]
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
    description: [Ambiente che replica quello di produzione e ne utilizza dati realistici, impiegato per le prove che precedono il rilascio senza incidere sul servizio effettivamente in uso.]
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
    key: "idempotenza",
    short: [idempotenza],
    description: [Proprietà di un'operazione che, ripetuta più volte con gli stessi argomenti, produce lo stesso effetto di una singola esecuzione. È necessaria quando l'infrastruttura può consegnare due volte lo stesso messaggio.]
  ),
)
