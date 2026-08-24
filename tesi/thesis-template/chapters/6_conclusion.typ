#import "../config/variables.typ": *
#pagebreak(to:"odd")

= Conclusioni<cap:conclusioni>
#text(style: "italic", [
    In questo capitolo valuto il raggiungimento degli obiettivi, indico le direzioni in cui il lavoro può proseguire, riassumo ciò che ho imparato e traggo un bilancio personale dell'esperienza.
])
#v(1em)

== Raggiungimento degli obiettivi

Il piano di lavoro fissava quattro obiettivi obbligatori e uno desiderabile. La @tab:obiettivi ne riporta l'esito.

#figure(
  caption: [Raggiungimento degli obiettivi del piano di lavoro.],
  table(
    columns: (auto, 2.5fr, auto),
    align: (left + horizon, left, center + horizon),
    fill: (x, y) => if y == 0 { luma(230) },
    table.header([*Codice*], [*Obiettivo*], [*Esito*]),
    [O01], [Ricezione di eventi asincroni dalle altre componenti della piattaforma, con caricamento delle configurazioni del cliente e delle entità interessate], [Raggiunto],
    [O02], [Valutazione di KPI specifici per entità e cliente, e interfacciamento con l'IA generativa per la produzione della sintesi testuale], [Raggiunto],
    [O03], [Indicizzazione delle entità per il recupero di documenti non strutturati], [Non raggiunto],
    [O04], [Ricezione di richieste utente in modalità agente, con recupero documentale e risposta], [Non raggiunto],
    [D01], [Integrazione nell'architettura e nel ciclo di rilascio della piattaforma], [Non raggiunto],
  )
)<tab:obiettivi>

Gli obiettivi raggiunti sono quelli che riguardano i dati strutturati, e su di essi il lavoro è arrivato più lontano di quanto il piano richiedesse: non solo il servizio produce le sintesi, ma le conserva, le mantiene allineate ai dati e le rende consultabili. Al servizio si affianca il modello dati del semantic layer, dove le metriche sono state definite e da cui i valori provengono, più una suite di test automatici e un ambiente di sviluppo che riproduce l'infrastruttura con un comando.

Gli obiettivi O03 e O04 riguardano invece i dati non strutturati e non sono stati realizzati. La decisione, presa con il tutor aziendale a metà stage, è discussa nel @cap:introduzione[Capitolo] e le sue ragioni tecniche nel @cap:progettazione[Capitolo]: l'estensione ai documenti richiedeva un'infrastruttura autonoma di indicizzazione e recupero, il cui sviluppo avrebbe occupato tutto il tempo restante lasciando incompiuto anche il flusso sui dati strutturati. Fra due fronti aperti a metà e uno chiuso, si è preferito il secondo.

L'obiettivo desiderabile D01 non è stato raggiunto per ragioni di tempo e di coordinamento con il ciclo di rilascio interno, e nella settimana conclusiva l'azienda ha preferito destinare il tempo residuo a un affiancamento formativo con uno sviluppatore del team.

Il risultato complessivo è quindi un servizio completo e verificato sul perimetro dei dati strutturati, configurato per un cliente e per due dei tre tipi di entità della piattaforma, e uno studio documentato ma non realizzato sul perimetro restante. Ciò che manca perché entri in esercizio è elencato nella sezione seguente.

== Sviluppi futuri

Il lavoro può proseguire in più direzioni, che elenco dalla più immediata alla più impegnativa.

*Configurazione del terzo tipo di entità.* Gli asset sono rimasti fuori dalla configurazione allestita durante lo stage. Come osservato nel @cap:progettazione[Capitolo], colmare la lacuna non richiede sviluppo: il servizio non distingue i tipi di entità, e il terzo percorre le stesse istruzioni dei primi due. Occorrono la definizione delle metriche nel semantic layer e la configurazione delle interrogazioni corrispondenti.

*Coda di scarto.* Un messaggio malformato torna oggi sulla coda indefinitamente. Configurare una _dead letter queue_ dopo un numero prestabilito di tentativi lo toglie dal ciclo e lo conserva per l'ispezione. È una modifica di configurazione dell'infrastruttura, non del servizio.

*Contenimento della lunghezza.* È il requisito RQA-DE\_02, rimasto insoddisfatto. La sua importanza cresce con la mole di dati: l'entità usata per le prove ha sei ticket, ma un'ispezione con dieci anni di storia produrrebbe un testo in cui persino gli indicatori di base rischiano di non trovare posto. Serve che il servizio, davanti a più dati di quanti ne possa esporre, scelga.

L'esperimento del @cap:verifica[Capitolo] indica dove non intervenire: il numero dichiarato nell'istruzione non ha effetto, perché a determinare la lunghezza è quanto c'è da dire. La leva sta quindi a monte. Ridurre gli elementi passati al modello, per esempio abbassando il numero di ticket recuperati da ciascuna interrogazione, accorcia il testo in modo deterministico ed è pura configurazione. Spostare il vincolo dal testo complessivo al singolo blocco, chiedendo una frase per ticket anziché un totale di caratteri, parla al modello nella stessa forma delle istruzioni che già esegue con fedeltà. A valle, un controllo che misuri il testo e ne chieda una riscrittura più breve quando eccede fornirebbe la garanzia, al prezzo di una seconda chiamata.

Solo a quel punto avrebbe senso indicare nelle istruzioni un ordine di importanza fra i blocchi: quando esiste un budget effettivo, quell'ordine diventa il criterio con cui decidere che cosa sacrificare, mentre oggi il modello non arriva mai a doversi porre il problema.

*Integrazione in produzione.* Corrisponde all'obiettivo D01 e comprende la definizione del topic da cui provengono le segnalazioni di modifica, la creazione delle code dedicate, l'inserimento del servizio nel ciclo di rilascio e la strumentazione per l'osservabilità, oggi limitata alla registrazione degli eventi sullo standard error.

*Generalizzazione dell'accesso ai dati.* L'interfacciamento tra MongoDB e il semantic layer si appoggia oggi a una vista materializzata su PostgreSQL, che va scritta per ciascun cliente. Fra le alternative esaminate nel @cap:progettazione[Capitolo], l'esportazione in formato Parquet interrogata da DuckDB è quella che le eliminerebbe senza aggiungere componenti all'infrastruttura, dal momento che DuckDB è già incluso in Cube. Non è un'ipotesi sulla carta: l'ho sperimentata e funziona, e quel che manca è l'automazione dell'esportazione periodica dei dati. È la direzione che indicherei a chi riprenderà la questione.

*Estensione ai dati non strutturati.* È l'obiettivo O03, e con esso l'O04 che lo presuppone. Lo studio svolto indica come soluzione appropriata un recupero ibrido, che combina ricerca vettoriale e ricerca lessicale con una fase di re-ranking. La struttura del servizio è predisposta ad accoglierlo: la produzione raccoglie i blocchi di contesto da un insieme di sorgenti, e una sorgente documentale si aggiunge alle esistenti senza modificare il flusso. Anche la modalità agente di O04 può essere affrontata restando in Go, dove sono ormai disponibili framework dedicati alla costruzione di sistemi multi-agente @adk-go.

== Conoscenze acquisite

Sono entrato in azienda senza conoscere il linguaggio Go, che ho imparato durante lo stage e nel quale ho scritto l'intero servizio. Al di là della sintassi, che si assimila in fretta, quello che ho dovuto acquisire è il modo in cui in Go si organizza un programma: le interfacce dichiarate da chi le usa e non da chi le fornisce, la gestione esplicita degli errori a ogni chiamata, la concorrenza come strumento ordinario e non come tecnica avanzata. Sono convenzioni che all'inizio sembrano arbitrarie e di cui si capisce il senso solo quando il programma cresce.

Ho imparato a lavorare con i modelli linguistici, e soprattutto a diffidarne nel modo giusto. La lezione che porto con me non è che siano inaffidabili, ma che l'affidabilità dipende da quale compito si affida loro: lo stesso modello che inventa un numero se gli si chiede di calcolarlo espone quel numero in modo impeccabile se glielo si fornisce. Buona parte della progettazione descritta in questa relazione consiste nel disegnare il sistema attorno a questa distinzione.

Ho conosciuto il semantic layer, che non avevo mai incontrato negli studi, e ne ho scritto i modelli. Definire una metrica si è rivelato meno meccanico di quanto pensassi: stabilire che cosa conti come "ticket aperto" obbliga a guardare come i dati sono fatti davvero, e quella decisione, una volta scritta, vale per chiunque la interroghi. Ho lavorato con la comunicazione asincrona a code, e ho capito sul campo perché l'idempotenza non sia una raffinatezza teorica ma la conseguenza diretta di una garanzia di consegna almeno una volta.

Sul piano non tecnico, l'acquisizione più utile riguarda i requisiti. All'università i requisiti si ricevono già scritti; in azienda esistono nella testa delle persone, emergono nei confronti, cambiano quando qualcuno vede un risultato intermedio, e vanno separati dalle soluzioni che chi li esprime ha già in mente. Averli formalizzati tardi, come racconto nel @cap:introduzione[Capitolo], mi ha mostrato il costo di quel ritardo meglio di quanto avrebbe fatto un corso.

== Valutazione personale

Considero lo stage un'esperienza positiva, e la ragione principale è l'autonomia che mi è stata lasciata. Il piano di lavoro fissava i risultati attesi ma non il modo di ottenerli, e su ogni questione rilevante ho potuto valutare le alternative, provarle e proporre una scelta.

L'episodio più istruttivo è l'interfacciamento fra il database e il semantic layer, e lo è perché contiene due errori diversi. Il primo è stato insistere troppo a lungo sull'interrogazione diretta del `jsonb`, che si è rivelata impraticabile: fermarsi era la decisione giusta, ma è arrivata dal tutor aziendale prima che da me. Il secondo l'ho riconosciuto solo scrivendo questa relazione, ed è aver rinunciato all'esportazione in Parquet quando invece funzionava, perché le mancava un'automazione che serviva all'azienda e non a me. In un caso ho continuato a lavorare su un problema che non era il mio; nell'altro ho smesso di lavorare su uno che lo era.

La difficoltà maggiore l'ho incontrata all'inizio, ed era di ordine diverso da quelle tecniche: capire il dominio. Il codice si legge, ma sapere che cosa sia una non conformità, perché un livello di rischio si misuri per aree e che cosa un manutentore voglia sapere aprendo la scheda di un impianto richiede di ascoltare chi quel lavoro lo conosce. Le riunioni con il tutor aziendale, che all'inizio consideravo un intervallo nel lavoro vero, si sono rivelate la parte da cui è dipeso il risultato: le tre correzioni descritte nel @cap:verifica[Capitolo] vengono tutte da lì e nessuna sarebbe emersa da un test.

Il rammarico è di non aver visto il servizio in produzione. È il passaggio in cui un lavoro smette di essere un esercizio e comincia a essere usato, e mi resta la curiosità di sapere come si comporterà. Ho cercato di lasciarlo nelle condizioni migliori perché quel passaggio sia semplice per chi lo farà: il codice è documentato, i test si eseguono con un comando, l'ambiente di sviluppo si avvia con un altro, e questa relazione contiene le ragioni di ogni scelta, che sono la parte che di solito va perduta.
