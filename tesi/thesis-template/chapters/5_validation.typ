#import "../config/thesis-config.typ": gl, glpl, glossary-style, linkfn, req, obj
#pagebreak(to: "odd")

// le tabelle di questo capitolo sono lunghe: senza questo si spezzerebbero male tra le pagine
#show figure: set block(breakable: true)

= Verifica e validazione <cap:verifica>
#text(style: "italic", [
    In questo capitolo descrivo come ho verificato che il servizio funzioni correttamente e come ne ho validato il risultato con l'azienda, riportando il grado di soddisfacimento dei requisiti e i limiti delle prove svolte.
])
#v(1em)

== Approccio adottato

Le attività descritte in questo capitolo rispondono a due domande distinte:
- la *verifica* chiede se il servizio faccia ciò che è stato specificato;
- la *validazione* chiede se ciò che è stato specificato sia effettivamente utile a chi lo userà.

Il servizio è stato verificato in due modi, ai quali sono dedicate le due sezioni seguenti. I test automatici provano le singole parti in isolamento, si eseguono con un solo comando e possono quindi essere ripetuti a ogni modifica. I test di sistema riguardano il servizio intero collegato ai sistemi reali, nell'ambiente di sviluppo locale che riproduce l'infrastruttura di produzione e attinge ai dati reali dell'ambiente di _staging_ aziendale. Sono stati eseguiti a mano perché mettono in gioco situazioni che un test automatico non riproduce, come spegnere una sorgente dati o fermare il servizio mentre sta elaborando.

Va detto subito che i test automatici non sono stati scritti insieme al codice ma nella parte conclusiva dello stage. Durante lo sviluppo la verifica è stata manuale, condotta eseguendo il flusso e osservandone il risultato. La scelta ha una ragione, cioè che la forma del servizio è cambiata a fondo più di una volta e i test scritti presto sarebbero stati riscritti altrettante, ma ha anche un costo che è giusto riconoscere: alcuni difetti sono stati individuati più tardi di quanto sarebbe accaduto altrimenti.

== Test automatici

I test sono scritti con il package `testing` della libreria standard di Go, senza librerie esterne (coerentemente con la filosofia del linguaggio), e sono di due tipi:

- *Test di unità.* Riguardano i package in cui la logica è propria del servizio e le dipendenze sono dichiarate come interfacce, secondo quanto descritto nel @cap:progettazione[Capitolo]. Al posto del modello linguistico, del semantic layer e dell'archivio vengono fornite realizzazioni simulate, che restituiscono valori prestabiliti e registrano le chiamate ricevute. La parte in esame resta così isolata dal resto, e il flusso di produzione si verifica per intero senza chiamare il modello (senza costi, senza rete e con esito sempre uguale a parità di ingressi).

- *Test di integrazione.* Riguardano i package che parlano con MongoDB, dove ciò che va verificato è proprio l'interrogazione e non la logica che la circonda. Questi test avviano quindi un'istanza reale di MongoDB in un container, vi inseriscono i documenti necessari, eseguono le operazioni e distruggono il container al termine. L'avvio e la distruzione del container sono raccolti in una funzione di supporto, che ciascuno di questi test richiama con una riga.

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

Le due chiamate a `t.Cleanup` sono ciò che rende sostenibile questo approccio: la chiusura del container e della connessione viene registrata subito dopo l'apertura ed eseguita comunque, anche se il test fallisce a metà (senza di esse un test interrotto lascerebbe container attivi sulla macchina).

In tutto la suite comprende sedici casi, otto di unità e otto di integrazione. La @tab:test riassume che cosa verifica ciascun gruppo e a quali requisiti si riferisce.

#figure(
  caption: [Test automatici e requisiti verificati.],
  table(
    columns: (auto, 1fr, 8.1em),
    align: (left + horizon, left, left + horizon),
    fill: (x, y) => if y == 0 { luma(230) },
    table.header([*Package*], [*Comportamento verificato*], [*Requisiti*]),
    [`store`],
      [Un riepilogo salvato viene riletto correttamente; un secondo salvataggio sulla stessa chiave lo aggiorna invece di duplicarlo; la ricerca su un'entità priva di riepiloghi non trova nulla; l'invalidazione cancella tutti i riepiloghi dell'entità e non solo quelli di un evento, e invalidare un'entità che non ne ha non produce errore.],
      [#req("RF-OB_06", display: [RF‑OB\_06]), #req("RF-OB_07", display: [RF‑OB\_07]), #req("RQA-OB_07", display: [RQA‑OB\_07])],
    [`tenant`],
      [Le impostazioni del cliente vengono lette dal documento corretto anche in presenza di altri documenti nella stessa collection; una lingua configurata ma non supportata ricade sull'inglese; in assenza di impostazioni la lingua ricade sull'inglese e il fuso orario resta non specificato.],
      [#req("RQA-OB_02", display: [RQA‑OB\_02]), #req("RQA-OB_03", display: [RQA‑OB\_03])],
    [`kpi`],
      [Nell'interrogazione inviata al semantic layer il segnaposto è sostituito con l'identificativo dell'entità; i risultati sono raccolti con le rispettive istruzioni di lettura; il fuso orario del cliente viene aggiunto all'interrogazione, e non compare quando non è impostato.],
      [#req("RF-OB_03", display: [RF‑OB\_03]), #req("RQA-OB_03", display: [RQA‑OB\_03])],
    [`summary`],
      [Se il riepilogo esiste già viene restituito senza chiamare il modello; se non esiste viene percorso l'intero flusso, dalla raccolta dei dati alla chiamata al modello al salvataggio.],
      [#req("RF-OB_01", display: [RF‑OB\_01]), #req("RF-OB_05", display: [RF‑OB\_05]), #req("RQA-OB_07", display: [RQA‑OB\_07])],
    [`cmd`],
      [La consultazione restituisce il riepilogo quando esiste e ne segnala l'assenza quando non esiste, senza trattarla come un errore; una richiesta priva di un parametro obbligatorio viene respinta; un errore dell'archivio produce una risposta di errore e non l'interruzione del servizio.],
      [#req("RF-OB_04", display: [RF‑OB\_04]), #req("RF-OB_06", display: [RF‑OB\_06]), #req("RQA-OB_06", display: [RQA‑OB\_06])],
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
    [`cmd`], [19,8%], [Coperta la sola consultazione; avvio, configurazione e funzioni di consumo delle code non sono sotto test],
    [`clients`], [0%], [Adattatori verso i sistemi esterni, privi di logica propria],
  )
)<tab:copertura>

I valori vanno letti per quello che sono. La copertura misura quante istruzioni vengono eseguite durante i test, non quanti comportamenti significativi siano stati verificati, ed è quindi un indicatore utile a individuare le zone d'ombra più che a certificare la qualità.

== Test di sistema manuali

I test automatici verificano le parti; resta da verificare che il servizio funzioni quando le parti sono collegate ai sistemi reali. Per questo è stato allestito un ambiente di sviluppo locale che riproduce l'infrastruttura di produzione: MongoDB, Cube e la coda vengono eseguiti come container, con ElasticMQ al posto di SQS. Il codice del servizio è identico a quello che andrebbe in produzione, e cambia soltanto l'indirizzo della coda nella configurazione. I dati sono quelli reali dell'ambiente di staging aziendale.

Su questo ambiente ho eseguito a mano i seguenti scenari.

/ Produzione di un riepilogo: inviato il comando sulla coda, il servizio recupera le interrogazioni del cliente, ottiene i valori dal semantic layer, produce il testo e lo conserva. Il testo è stato confrontato con i dati di partenza per accertare che ogni valore riportato vi trovasse riscontro.
/ Consultazione di un riepilogo esistente: l'endpoint restituisce il testo conservato senza attivare alcuna produzione.
/ Consultazione di un riepilogo assente: l'endpoint segnala l'assenza. È la risposta su cui si regge l'intero disegno su richiesta, perché è quella che permette alla piattaforma di proporre la produzione all'operatore.
/ Invalidazione: inviata la segnalazione di modifica, i riepiloghi dell'entità vengono cancellati e la consultazione successiva li dà per assenti.
/ Ripetizione dell'invalidazione: la stessa segnalazione inviata due volte cancella due riepiloghi al primo passaggio e nessuno al secondo, senza errore. È la verifica diretta di #req("RQA-OB_07").
/ Indisponibilità di una sorgente: spegnendo il semantic layer, la produzione fallisce senza conservare alcun riepilogo parziale e il messaggio resta sulla coda. La consultazione continua a rispondere per i riepiloghi già presenti.
/ Arresto durante l'elaborazione: fermando il servizio mentre una produzione è in corso, questa viene portata a termine prima della chiusura, e i messaggi non ancora presi in carico restano sulla coda.

Attenzione: la prova dell'ultimo scenario ne accerta il comportamento nominale, ma non copre il caso in cui l'elaborazione ecceda il limite di tempo previsto per l'arresto. Quel caso è affidato all'idempotenza, verificata separatamente.

Il primo scenario è quello che produce il risultato del servizio. La @fig:esempio-riepilogo ne riporta un esempio completo, generato su un oggetto locativo, per l'evento di apertura di un ticket.

#figure(
  caption: [Un riepilogo prodotto dal servizio su un oggetto locativo, per l'evento di apertura di un ticket.],
  block(
    width: 100%,
    inset: 10pt,
    stroke: 0.5pt + luma(120),
    radius: 2pt,
    align(left, text(style: "italic", [
      Attualmente è aperto un ticket, aperto il 9 dicembre 2025, con priorità alta e stato "in corso". Riguarda un pozzo/cisterna di profondità sconosciuta nell'area del casello, con richiesta di messa in sicurezza e recinzione.

      Sono stati chiusi cinque ticket. Il 26 maggio 2026 è stato chiuso un ticket relativo a rifiuti nella baracca. Il 4 marzo 2026 è stata eseguita la demolizione di un capanno con rifiuti. Il 3 marzo 2026 è stata richiesta la messa in sicurezza di un pozzo/tombino. Il 3 marzo 2026 è stato effettuato lo smaltimento di rifiuti all'interno di un'abitazione. Il 3 marzo 2026 è stata demolita una baracca con copertura in presunto MCA.

      Ci sono 6 ticket totali, di cui 1 aperto. Il tempo medio di risposta è di 21,57 giorni e il tempo medio di risoluzione è di 271,47 giorni.
    ]))
  )
)<fig:esempio-riepilogo>

Il testo permette di riscontrare direttamente alcune proprietà discusse altrove in questa relazione. I quattro valori dell'ultimo capoverso sono le quattro metriche configurate nel blocco delle statistiche, riportate senza elaborazione; non compare alcun codice identificativo, come impongono le istruzioni al modello; le date sono esplicite e calcolate nel fuso del cliente, secondo #req("RQA-OB_03"). Si vede però anche che il riepilogo è lungo 792 caratteri contro i 650 dichiarati nelle istruzioni.


== Validazione del risultato

Il confronto con il tutor aziendale ha riguardato soprattutto le scelte di approccio e di realizzazione, quelle discusse nel @cap:progettazione[Capitolo], ma ha toccato fin dall'inizio anche il contenuto del riepilogo. L'indicazione di partenza era di restare sui KPI aggregati, accompagnati da qualche analisi elementare, come l'andamento del rischio negli anni. I primi riepiloghi prodotti sui dati reali sono stati giudicati adeguati già in quella forma.

Di mia iniziativa avevo aggiunto al riepilogo delle ispezioni una quantità di informazioni puntuali sulle singole occorrenze. Il tutor ha chiesto di toglierle, per mantenere il riepilogo sul piano generale degli aggregati. Le informazioni puntuali sono rientrate più tardi con lo scenario dei ticket, e in quella forma sono state accolte: dei ticket aperti il riepilogo riporta quando sono stati aperti, la priorità, lo stato e di che cosa trattano.

Anche le due modifiche successive sono nate da una mia proposta, poi approvata dal tutor, e vengono dal confronto fra il riepilogo e la scheda che ha davanti l'operatore. Il testo veniva prodotto in inglese, inservibile per un operatore italiano sul campo, e le date calcolate in UTC dal semantic layer non coincidevano con quelle mostrate dalla piattaforma: uno scarto di un giorno su una data di chiusura non è un difetto che il codice segnali in alcun modo. Ne sono derivati i requisiti #req("RQA-OB_02") e #req("RQA-OB_03").

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

/ #req("RF-DE_01"): l'indicizzazione delle entità per il recupero da documenti non strutturati, corrispondente all'obiettivo #obj("O03"), analizzata sul piano degli approcci ma non realizzata;
/ #req("RF-OP_01"): la risposta a richieste dell'utente in modalità agente, corrispondente all'obiettivo #obj("O04"), che presuppone il precedente;
/ #req("RV-DE_01"): l'integrazione nell'architettura e nel ciclo di rilascio della piattaforma, corrispondente all'obiettivo desiderabile #obj("D01");
/ #req("RQA-DE_02"): il contenimento del riepilogo entro una lunghezza massima, che ho tentato di ottenere e che la sezione seguente documenta.

=== Tracciamento delle verifiche

La @tab:tracciamento-verifiche indica per ciascun requisito il modo in cui è stato verificato. I vincoli si verificano per ispezione, perché riguardano come il servizio è fatto e non come si comporta; i requisiti lasciati fuori dal perimetro non hanno verifica perché non hanno realizzazione.

#figure(
  caption: [Modo di verifica di ciascun requisito.],
  table(
    columns: (auto, 1fr),
    align: (left + horizon, left),
    fill: (x, y) => if y == 0 { luma(230) },
    table.header([*Requisito*], [*Verifica*]),
    [#req("RF-OB_01")], [Test di unità e prova sul flusso completo],
    [#req("RF-OB_02")], [Validazione del risultato con il tutor aziendale],
    [#req("RF-OB_03")], [Test di unità e prova sul flusso completo],
    [#req("RF-OB_04")], [Test di unità e prova sul flusso completo],
    [#req("RF-OB_05")], [Test di unità e prova sul flusso completo],
    [#req("RF-OB_06")], [Test di integrazione e prova sul flusso completo],
    [#req("RF-OB_07")], [Test di integrazione e prova sul flusso completo],
    [#req("RF-OB_08")], [Prova sul flusso completo: ogni comando arriva dalla coda],
    [#req("RF-DE_01")], [Non realizzato],
    [#req("RF-OP_01")], [Non realizzato],
    [#req("RQA-OB_01")], [Prova sul flusso completo: confronto fra i valori nel testo e i dati di partenza],
    [#req("RQA-OB_02")], [Test di integrazione e prova sul flusso completo],
    [#req("RQA-OB_03")], [Test di unità, test di integrazione e validazione del risultato],
    [#req("RQA-OB_04")], [Non verificato: la configurazione comprende un solo cliente],
    [#req("RQA-OB_05")], [Prova sul flusso completo: arresto durante l'elaborazione],
    [#req("RQA-OB_06")], [Test di unità e prova sul flusso completo: indisponibilità del semantic layer],
    [#req("RQA-OB_07")], [Test di unità, test di integrazione e ripetizione dell'invalidazione],
    [#req("RQA-DE_01")], [Verifica sul campo: il riepilogo dei ticket è stato aggiunto senza modifiche al codice],
    [#req("RQA-DE_02")], [Misura sperimentale su ventuno generazioni: requisito non soddisfatto],
    [#req("RV-OB_01")], [Ispezione del codice],
    [#req("RV-OB_02")], [Ispezione della configurazione],
    [#req("RV-OB_03")], [Ispezione del codice],
    [#req("RV-DE_01")], [Non realizzato],
  )
)<tab:tracciamento-verifiche>

- Attenzione 1: #req("RQA-DE_01") (configurabilità per cliente) non ha un test dedicato ma una verifica fatta "sul campo", infatti il secondo tipo di entità è stato messo in esercizio a servizio già funzionante, e per farlo sono bastati nuovi documenti di configurazione (oltre al setup del semantic layer).
- Attenzione 2: #req("RQA-OB_04") (segregazione fra clienti) è l'unico requisito obbligatorio privo di verifica, per la ragione discussa più avanti fra i limiti.

=== Approfondimento: la lunghezza del riepilogo

#req("RQA-DE_02") chiede che il riepilogo si mantenga entro una lunghezza massima, scegliendo i contenuti in ordine di importanza quando i dati eccedono. Durante lo stage questo requisito è stato affrontato nel modo più semplice possibile: dichiarare il limite fra le istruzioni al modello. Facendo qualche test ho subito notato che il limite non veniva rispettato: la prima misura ha dato 930 caratteri contro i 650 dichiarati.

Per capire se il limite fosse seguito almeno come indicazione, ho testato empiricamente il servizio.
Ho generato sette volte lo stesso riepilogo per tre limiti di lunghezza differenti - 500, 650 e 750 caratteri - lasciando invariati tutti gli altri parametri.

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

Il numero scritto nell'istruzione non governa la lunghezza del testo. Abbassare il limite a 500 ha prodotto i testi più lunghi dei tre gruppi; alzarlo a 750 non li ha allungati in proporzione. Nessuna delle ventuno generazioni è rientrata nel proprio limite.

A governare la lunghezza è il contenuto. L'entità usata per le prove ha un ticket aperto e cinque chiusi di recente, e le istruzioni dei singoli blocchi chiedono per ciascuno la data, la priorità, lo stato e una descrizione: il limite complessivo e le istruzioni di dettaglio sono richieste in conflitto, e il modello lo risolve a favore del dettaglio.

Il requisito non è quindi soddisfatto. Il @cap:conclusioni[Capitolo] riprende la questione suggerendo approcci differenti.

== Limiti della verifica svolta

Per completezza dichiaro ciò che le prove descritte non coprono.

Il servizio non è stato provato sotto carico. Non esistono misure su quante richieste di produzione possa smaltire nell'unità di tempo, né sul comportamento della coda quando le richieste si accumulano. Il dato mancherebbe comunque di un riferimento realistico, dal momento che il servizio non è mai stato esposto a un traffico vero.

Il comportamento in caso di messaggi ripetutamente malformati non è stato provato, coerentemente con il fatto che la coda di scarto non è stata configurata: è la lacuna già dichiarata nel @cap:progettazione[Capitolo].

Anche la segregazione dei dati fra clienti è rimasta senza prova. Il requisito #req("RQA-OB_04") è soddisfatto per costruzione, perché come descritto nel @cap:progettazione[Capitolo] ogni cliente ha un proprio database e un proprio modello compilato, ma la configurazione allestita durante lo stage comprende un solo cliente. Manca quindi l'unica prova che varrebbe davvero: un secondo cliente a cui i dati del primo risultino inaccessibili.

La validazione si è fermata al giudizio del tutor aziendale. Nessun operatore ha usato i riepiloghi nel proprio lavoro, quindi manca il riscontro che conterebbe di più, cioè se servano davvero a chi deve decidere se intervenire su un impianto.

Infine, l'assenza dell'integrazione in produzione fa sì che tutte le prove siano state condotte in un ambiente che riproduce quello reale ma non lo è. La riproduzione è fedele nei componenti e nei dati, ma non nella scala, nella concorrenza tra più consumatori e nelle condizioni di rete.
