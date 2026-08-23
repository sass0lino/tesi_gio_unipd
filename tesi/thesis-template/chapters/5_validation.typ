#import "../config/thesis-config.typ": gl, glpl, glossary-style, linkfn
#pagebreak(to: "odd")

// le tabelle di questo capitolo sono lunghe: senza questo si spezzerebbero male tra le pagine
#show figure: set block(breakable: true)

= Verifica e validazione <cap:verifica>
#text(style: "italic", [
    In questo capitolo descrivo come ho verificato che il servizio funzioni come previsto e come ne ho validato il risultato con l'azienda, riportando il grado di soddisfacimento dei requisiti e i limiti delle prove svolte.
])
#v(1em)

== Approccio adottato

Le attività descritte in questo capitolo rispondono a due domande distinte. La verifica chiede se il servizio faccia ciò che è stato specificato, e si risponde con prove ripetibili condotte sul codice. La validazione chiede se ciò che è stato specificato sia effettivamente utile a chi lo userà, e a questa risponde soltanto il giudizio di chi conosce il dominio.

Il servizio è stato verificato su due livelli. Il primo è costituito dai test automatici, che esercitano le singole parti in isolamento e i punti in cui il comportamento è meno evidente. Il secondo è la prova del flusso completo nell'ambiente di sviluppo locale, che riproduce l'infrastruttura di produzione e attinge ai dati reali dell'ambiente di _staging_ aziendale.

Va detto subito, per non attribuire al lavoro un rigore che non ha avuto, che i test automatici non sono stati scritti insieme al codice ma nella parte conclusiva dello stage, quando la struttura del servizio si era stabilizzata. Durante lo sviluppo la verifica è stata manuale, condotta eseguendo il flusso e osservandone il risultato. La scelta ha una ragione, ovvero che la forma del servizio è cambiata a fondo più di una volta e i test scritti presto sarebbero stati riscritti altrettante, ma ha anche un costo che è giusto riconoscere: alcuni difetti sono stati individuati più tardi di quanto sarebbe accaduto altrimenti.

== Test automatici

I test sono scritti con il package `testing` della libreria standard di Go, senza librerie di asserzione esterne, coerentemente con l'uso prevalente nell'ecosistema del linguaggio. Si dividono in due famiglie a seconda di come trattano le dipendenze esterne.

*Test di unità.* Riguardano i package in cui la logica è propria del servizio e le dipendenze sono dichiarate come interfacce, secondo quanto descritto nel @cap:progettazione[Capitolo]. Al posto del modello linguistico, del semantic layer e dell'archivio vengono fornite realizzazioni finte, che restituiscono valori prestabiliti e registrano le chiamate ricevute. La parte in esame resta così isolata dal resto, e il flusso di produzione si verifica per intero senza chiamare il modello: senza costi, senza rete e con esito sempre uguale a parità di ingressi.

*Test di integrazione.* Riguardano i package che parlano con MongoDB, dove ciò che va verificato è proprio l'interrogazione e non la logica che la circonda. Sostituire il database con una finzione verificherebbe soltanto che il codice chiama i metodi che il codice chiama, senza dire nulla sul fatto che il filtro sia corretto. Questi test avviano quindi un'istanza reale di MongoDB in un container, vi inseriscono i documenti necessari, eseguono le operazioni e distruggono il container al termine.

```go
// internal/mongotest/mongotest.go

// avvia un mongo in un container usa e getta e ne restituisce
// il client; container e connessione vengono chiusi a fine test
func Start(t *testing.T) *mongo.Client {
	t.Helper()
	ctx := context.Background()

	container, err := mongodb.Run(ctx, "mongo:7")
	if err != nil {
		t.Fatalf("avvio del container: %v", err)
	}
	t.Cleanup(func() {
		testcontainers.TerminateContainer(container)
	})

	uri, err := container.ConnectionString(ctx)
	...
	client, err := mongo.Connect(ctx,
		options.Client().ApplyURI(uri))
	...
	t.Cleanup(func() { client.Disconnect(ctx) })

	return client
}
```

Le due chiamate a `t.Cleanup` sono ciò che rende sostenibile questo approccio: la chiusura del container e della connessione viene registrata subito dopo l'apertura ed eseguita comunque, anche se il test fallisce a metà. Senza di esse un test interrotto lascerebbe container attivi sulla macchina.

La @tab:test riassume che cosa verifica ciascun gruppo di test e a quali requisiti si riferisce.

#figure(
  caption: [Test automatici e requisiti verificati.],
  table(
    columns: (auto, 2.2fr, auto),
    align: (left + horizon, left, left + horizon),
    fill: (x, y) => if y == 0 { luma(230) },
    table.header([*Package*], [*Comportamento verificato*], [*Requisiti*]),
    [`store`],
      [Un riepilogo salvato viene riletto correttamente; la ricerca distingue entità ed evento; l'invalidazione cancella tutti i riepiloghi dell'entità e non solo quelli di un evento; invalidare un'entità priva di riepiloghi non produce errore.],
      [RF-OB\_06, RF-OB\_07, RQA-OB\_07],
    [`tenant`],
      [Le impostazioni del cliente vengono lette dal documento corretto anche in presenza di altri documenti nella stessa collection; in assenza di impostazioni la lingua ricade sull'inglese e il fuso orario resta non specificato.],
      [RQA-OB\_02, RQA-OB\_03],
    [`kpi`],
      [Le interrogazioni configurate vengono eseguite e i risultati raccolti con le rispettive istruzioni; il fuso orario del cliente viene aggiunto a ciascuna interrogazione, e non compare quando il cliente non lo ha impostato.],
      [RF-OB\_03, RQA-OB\_03],
    [`summary`],
      [Se il riepilogo esiste già viene restituito senza chiamare il modello; se non esiste viene percorso l'intero flusso, dalla raccolta dei dati alla chiamata al modello al salvataggio.],
      [RF-OB\_01, RF-OB\_05, RQA-OB\_07],
    [`cmd`],
      [La consultazione restituisce il riepilogo quando esiste; quando non esiste segnala l'assenza senza trattarla come un errore.],
      [RF-OB\_04, RF-OB\_06],
  )
)<tab:test>

L'intera suite viene eseguita con un solo comando e termina con esito positivo. La copertura raggiunta è riportata nella @tab:copertura.

#figure(
  caption: [Copertura delle istruzioni per package.],
  table(
    columns: (auto, auto, 2fr),
    align: (left + horizon, center + horizon, left),
    fill: (x, y) => if y == 0 { luma(230) },
    table.header([*Package*], [*Copertura*], [*Nota*]),
    [`tenant`], [92,3%], [],
    [`store`], [87,0%], [],
    [`summary`], [77,8%], [Non coperti i rami di errore delle dipendenze],
    [`kpi`], [45,7%], [Non coperta la lettura delle interrogazioni da MongoDB],
    [`cmd`], [19,8%], [Coperta la sola consultazione; avvio e configurazione non sono sotto test],
    [`clients`], [0%], [Adattatori verso i sistemi esterni, privi di logica propria],
  )
)<tab:copertura>

I valori vanno letti per quello che sono. La copertura misura quante istruzioni vengono eseguite durante i test, non quanti comportamenti significativi siano stati verificati, ed è quindi un indicatore utile a individuare le zone d'ombra più che a certificare la qualità. Le zone d'ombra qui sono due e le dichiaro esplicitamente: i rami di gestione degli errori, verificati solo in parte, e il codice di avvio del servizio, che non è sotto test perché la sua verifica coincide di fatto con l'avvio del servizio stesso, oggetto delle prove manuali descritte nella sezione seguente. La copertura nulla degli adattatori verso i sistemi esterni è invece una conseguenza voluta della struttura: contengono la sola traduzione tra le chiamate del servizio e le API dei sistemi, e verificarli richiederebbe quei sistemi.

== Verifica del flusso completo

I test automatici verificano le parti; resta da verificare che il servizio funzioni quando le parti sono collegate ai sistemi veri. Per questo è stato allestito un ambiente di sviluppo locale che riproduce l'infrastruttura di produzione: MongoDB, Cube e la coda vengono eseguiti come container, con ElasticMQ al posto di SQS. Il codice del servizio è identico a quello che andrebbe in produzione, e cambia soltanto l'indirizzo della coda nella configurazione. I dati sono quelli reali dell'ambiente di staging aziendale.

Su questo ambiente ho verificato gli scenari seguenti.

/ Produzione di un riepilogo: inviato il comando sulla coda, il servizio recupera le interrogazioni del cliente, ottiene i valori dal semantic layer, produce il testo e lo conserva. Il testo è stato confrontato con i dati di partenza per accertare che ogni valore riportato vi trovasse riscontro.
/ Consultazione di un riepilogo esistente: l'endpoint restituisce il testo conservato senza attivare alcuna produzione.
/ Consultazione di un riepilogo assente: l'endpoint segnala l'assenza. È la risposta su cui si regge l'intero disegno su richiesta, perché è quella che permette alla piattaforma di proporre la produzione all'operatore.
/ Invalidazione: inviata la segnalazione di modifica, i riepiloghi dell'entità vengono cancellati e la consultazione successiva li dà per assenti.
/ Ripetizione dell'invalidazione: la stessa segnalazione inviata due volte cancella due riepiloghi al primo passaggio e nessuno al secondo, senza errore. È la verifica diretta di RQA-OB\_07.
/ Indisponibilità di una sorgente: spegnendo il semantic layer, la produzione fallisce senza conservare alcun riepilogo parziale e il messaggio resta sulla coda. La consultazione continua a rispondere per i riepiloghi già presenti.
/ Arresto durante l'elaborazione: fermando il servizio mentre una produzione è in corso, questa viene portata a termine prima della chiusura, e i messaggi non ancora presi in carico restano sulla coda.

L'ultimo scenario merita una precisazione: la mia prova ne accerta il comportamento nominale, ma non copre il caso in cui l'elaborazione ecceda il limite di tempo previsto per l'arresto. Quel caso è affidato all'idempotenza, verificata separatamente.


== Grado di soddisfacimento dei requisiti

La @tab:soddisfacimento riporta l'esito per ciascun requisito individuato nel @cap:analisi-requisiti[Capitolo].

#figure(
  caption: [Grado di soddisfacimento dei requisiti.],
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left + horizon, center + horizon, center + horizon, center + horizon, center + horizon),
    fill: (x, y) => if y == 0 { luma(230) },
    table.header([*Tipologia*], [*Priorità*], [*Individuati*], [*Soddisfatti*], [*Percentuale*]),
    [Funzionali], [Obbligatori], [8], [8], [100%],
    [Funzionali], [Desiderabili], [1], [0], [0%],
    [Funzionali], [Opzionali], [1], [0], [0%],
    [Qualitativi], [Obbligatori], [7], [7], [100%],
    [Qualitativi], [Desiderabili], [2], [1], [50%],
    [Di vincolo], [Obbligatori], [3], [3], [100%],
    [Di vincolo], [Desiderabili], [1], [0], [0%],
    [*Totale*], [], [*23*], [*19*], [*83%*],
  )
)<tab:soddisfacimento>

Tutti i requisiti obbligatori sono soddisfatti. I quattro non soddisfatti sono desiderabili o opzionali:

/ RF-DE\_01: l'indicizzazione delle entità per il recupero da documenti non strutturati, corrispondente all'obiettivo O03, analizzata sul piano degli approcci ma non realizzata;
/ RF-OP\_01: la risposta a richieste dell'utente in modalità agente, corrispondente all'obiettivo O04, che presuppone il precedente;
/ RV-DE\_01: l'integrazione nell'architettura e nel ciclo di rilascio della piattaforma, corrispondente all'obiettivo desiderabile D01;
/ RQA-DE\_02: il contenimento della sintesi entro una lunghezza massima, che ho tentato di ottenere e che la sezione seguente documenta.

=== Tracciamento delle verifiche

La @tab:tracciamento-verifiche indica per ciascun requisito il modo in cui è stato verificato. I vincoli si verificano per ispezione, perché riguardano come il servizio è fatto e non come si comporta; i requisiti lasciati fuori dal perimetro non hanno verifica perché non hanno realizzazione.

#figure(
  caption: [Modo di verifica di ciascun requisito.],
  table(
    columns: (auto, 1fr),
    align: (left + horizon, left),
    fill: (x, y) => if y == 0 { luma(230) },
    table.header([*Requisito*], [*Verifica*]),
    [RF-OB\_01], [Test di unità e prova sul flusso completo],
    [RF-OB\_02], [Validazione con il tutor aziendale],
    [RF-OB\_03], [Test di unità e prova sul flusso completo],
    [RF-OB\_04], [Test di unità e prova sul flusso completo],
    [RF-OB\_05], [Test di unità e prova sul flusso completo],
    [RF-OB\_06], [Test di integrazione e prova sul flusso completo],
    [RF-OB\_07], [Test di integrazione e prova sul flusso completo],
    [RF-OB\_08], [Prova sul flusso completo: ogni comando arriva dalla coda],
    [RF-DE\_01], [Non realizzato],
    [RF-OP\_01], [Non realizzato],
    [RQA-OB\_01], [Prova sul flusso completo: confronto fra i valori nel testo e i dati di partenza],
    [RQA-OB\_02], [Test di integrazione e prova sul flusso completo],
    [RQA-OB\_03], [Test di unità, test di integrazione e validazione con il tutor],
    [RQA-OB\_04], [Non verificato: la configurazione comprende un solo cliente],
    [RQA-OB\_05], [Prova sul flusso completo: arresto durante l'elaborazione],
    [RQA-OB\_06], [Prova sul flusso completo: indisponibilità del semantic layer],
    [RQA-OB\_07], [Test di unità, test di integrazione e ripetizione dell'invalidazione],
    [RQA-DE\_01], [Verifica sul campo: il riepilogo dei ticket è stato aggiunto senza modifiche al codice],
    [RQA-DE\_02], [Misura sperimentale su ventuno generazioni: requisito non soddisfatto],
    [RV-OB\_01], [Ispezione del codice],
    [RV-OB\_02], [Ispezione della configurazione],
    [RV-OB\_03], [Ispezione del codice],
    [RV-DE\_01], [Non realizzato],
  )
)<tab:tracciamento-verifiche>

Due righe meritano una nota. RQA-DE\_01, la configurabilità per cliente, non ha un test dedicato ma una verifica più convincente di un test: il secondo tipo di entità è stato messo in esercizio a servizio già funzionante, e per farlo sono bastati nuovi documenti di configurazione. RQA-OB\_04, la segregazione fra clienti, è l'unico requisito obbligatorio privo di verifica, per la ragione discussa più avanti fra i limiti.

=== La lunghezza del riepilogo

RQA-DE\_02 chiede che la sintesi si mantenga entro una lunghezza massima, scegliendo i contenuti in ordine di importanza quando i dati eccedono. Il tentativo fatto durante lo stage è stato il più semplice possibile: dichiarare il limite fra le istruzioni al modello. Una prima misura ha dato 930 caratteri contro i 650 dichiarati.

Per capire se il limite fosse almeno seguito come indicazione ho generato sette volte lo stesso riepilogo, cancellandolo fra una prova e l'altra così che venisse prodotto da capo, e ho ripetuto la serie con il limite dichiarato portato a 750 caratteri e poi abbassato a 500, lasciando invariato tutto il resto.

#figure(
  caption: [Lunghezza in caratteri di sette generazioni per ciascun limite dichiarato nell'istruzione.],
  table(
    columns: (auto, 3fr, auto, auto),
    align: (center + horizon, left, center + horizon, center + horizon),
    fill: (x, y) => if y == 0 { luma(230) },
    table.header([*Limite*], [*Le sette misure*], [*Media*], [*Entro*]),
    [500], [804, 844, 820, 920, 813, 727, 860], [827], [0/7],
    [650], [695, 794, 789, 822, 822, 689, 704], [759], [0/7],
    [750], [825, 793, 867, 808, 771, 777, 785], [804], [0/7],
  )
)<tab:lunghezza>

Il numero scritto nell'istruzione non governa la lunghezza del testo. Abbassare il limite a 500 ha prodotto i testi più lunghi dei tre gruppi; alzarlo a 750 non li ha allungati in proporzione. Le tre medie stanno fra 759 e 827 caratteri, e lo scarto che le separa, 68 caratteri, è dello stesso ordine della variabilità interna a ciascun gruppo, che va da 33 a 61. Nessuna delle ventuno generazioni è rientrata nel proprio limite.

A governare la lunghezza è il contenuto. L'entità usata per le prove ha un ticket aperto e cinque chiusi di recente, e le istruzioni dei singoli blocchi chiedono per ciascuno la data, la priorità, lo stato e una descrizione: il limite complessivo e le istruzioni di dettaglio sono richieste in conflitto, e il modello risolve il conflitto a favore del dettaglio.

Il requisito non è quindi soddisfatto, e l'esperimento mostra che la strada tentata è chiusa: nessuna riformulazione dell'istruzione lo renderebbe tale. Il @cap:conclusioni[Capitolo] riprende la questione indicando dove intervenire.

== Validazione con il tutor aziendale

La verifica accerta la conformità alla specifica, ma non dice se un riepilogo sia utile a un operatore che deve decidere se intervenire su un impianto. Su questo l'unico giudizio che conta è quello di chi conosce il dominio, e il servizio è stato quindi sottoposto con regolarità al tutor aziendale, leggendo insieme i testi prodotti sui dati reali.

Questi confronti hanno inciso sul risultato più di quanto suggerisca la loro informalità, e in particolare hanno prodotto tre correzioni.

La prima riguarda ciò che il riepilogo deve contenere. Le prime versioni si limitavano ai KPI aggregati, ed erano formalmente corrette ma poco utili: un operatore che vede quanti ticket sono aperti vuole sapere di che cosa trattano. Da qui l'inclusione delle informazioni puntuali sulle singole occorrenze, con le relative istruzioni di lettura.

La seconda riguarda la lingua. Il servizio produceva testi in inglese, cosa che nelle prove tecniche non aveva dato nell'occhio ma che rende il riepilogo inservibile per un operatore italiano sul campo. Ne è derivato il requisito RQA-OB\_02 e la lettura della lingua dalle impostazioni del cliente.

La terza riguarda le date, ed è la correzione che sarebbe stata più difficile da individuare per altra via. Le date calcolate in UTC dal semantic layer non coincidevano con quelle mostrate dalla piattaforma, e uno scarto di un giorno su una data di chiusura non è un difetto che il codice segnali in alcun modo: si nota solo confrontando il riepilogo con la scheda, cioè facendo quello che farà l'operatore. Ne è derivato il requisito RQA-OB\_03.

Vale la pena osservare che tutte e tre le correzioni riguardano il contenuto del riepilogo e nessuna il suo funzionamento. È la conferma pratica di una distinzione che sulla carta sembra scolastica: un servizio può superare ogni test e produrre un risultato inutile, e l'unico modo per accorgersene è mostrarlo a chi lo userà.

== Limiti della verifica svolta

Per completezza dichiaro ciò che le prove descritte non coprono.

Il servizio non è stato provato sotto carico. Non esistono misure su quante richieste di produzione possa smaltire nell'unità di tempo, né sul comportamento della coda quando le richieste si accumulano. Il dato mancherebbe comunque di un riferimento realistico, dal momento che il servizio non è mai stato esposto a un traffico vero.

Il comportamento in caso di messaggi ripetutamente malformati non è stato provato, coerentemente con il fatto che la coda di scarto non è stata configurata: è la lacuna già dichiarata nel @cap:progettazione[Capitolo].

Anche la segregazione dei dati fra clienti è rimasta senza prova. Il requisito RQA-OB\_04 è soddisfatto per costruzione, perché come descritto nel @cap:progettazione[Capitolo] ogni cliente ha un proprio database e un proprio modello compilato, ma la configurazione allestita durante lo stage comprende un solo cliente. Manca quindi l'unica prova che varrebbe davvero: un secondo cliente a cui i dati del primo risultino inaccessibili.

Infine, l'assenza dell'integrazione in produzione fa sì che tutte le prove siano state condotte in un ambiente che riproduce quello reale ma non lo è. La riproduzione è fedele nei componenti e nei dati, ma non nella scala, nella concorrenza tra più consumatori e nelle condizioni di rete.
