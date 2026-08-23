#import "../config/thesis-config.typ": gl, glpl, glossary-style, linkfn
#pagebreak(to: "odd")

// le tabelle comparative sono lunghe: senza questo si spezzerebbero male tra le pagine
#show figure: set block(breakable: true)

= Progettazione e sviluppo <cap:progettazione>
#text(style: "italic", [
    In questo capitolo espongo lo studio degli approcci possibili, l'architettura del servizio, le scelte di progettazione che ne hanno determinato la forma, il modello dati del semantic layer e lo sviluppo dei singoli componenti, documentato sul codice effettivo.
])
#v(1em)

Il @cap:analisi-requisiti[Capitolo] ha stabilito che cosa il sistema deve fare. Questo capitolo espone il come, procedendo dall'alto verso il basso: prima lo studio che ha portato a scegliere il modo in cui i dati arrivano al modello linguistico, poi l'architettura complessiva e le decisioni di progetto, quindi il modello dati con cui i KPI vengono definiti, infine i componenti del servizio, presentati uno a uno insieme al codice che li realizza.

== Studio degli approcci

=== Il vincolo del determinismo

Il servizio deve produrre un testo che descrive lo stato di un'entità, e quel testo viene letto da un operatore che sulla sua base prende decisioni di manutenzione. Tra i clienti della piattaforma figurano organizzazioni che gestiscono infrastrutture critiche, dove un valore riportato in modo errato non è un difetto estetico ma un rischio operativo.

Il vincolo che ne deriva è il punto di partenza di tutta la progettazione: nessun valore esposto nel riepilogo può essere inventato, dedotto o ricalcolato. È il requisito RQA-OB\_01, e da solo determina il ruolo che il modello linguistico può assumere.

I modelli linguistici sono strumenti probabilistici: producono il testo più plausibile date le istruzioni ricevute, non il testo verificato rispetto a una fonte. Quando la plausibilità coincide con la verità il risultato è corretto; quando non coincide il modello produce comunque un testo scorrevole e sicuro di sé, fenomeno noto come _allucinazione_. La conseguenza pratica è che a un modello linguistico si può affidare l'esposizione di un dato, ma non il suo recupero né il suo calcolo.

Ho quindi separato nettamente le due responsabilità. Il recupero e il calcolo dei valori avvengono per via deterministica, fuori dal modello; al modello arriva un insieme di valori già stabiliti, con il compito di comporli in un testo leggibile e con il divieto esplicito di aggiungere interpretazioni soggettive. Tutto lo studio che segue riguarda il modo di realizzare la prima metà di questa separazione.

=== Approcci valutati per i dati strutturati

I KPI di un'entità risiedono nel database della piattaforma, in forma strutturata. Ho valutato tre modi di portarli davanti al modello.

*Text-to-SQL:* Il modello linguistico riceve lo schema del database e la domanda dell'utente, e produce l'interrogazione da eseguire. È l'approccio più flessibile, perché non richiede di prevedere in anticipo quali domande verranno poste. Ha però un difetto insanabile rispetto al vincolo posto sopra: l'interrogazione stessa è generata in modo probabilistico. Un'interrogazione sintatticamente valida ma semanticamente sbagliata, per esempio una che aggrega sul campo sbagliato o dimentica un filtro, restituisce un risultato numericamente plausibile e formalmente ineccepibile, e nulla nel testo finale segnala che sia sbagliato. Lo spostamento della generazione dal testo all'interrogazione non elimina il problema, lo rende soltanto più difficile da individuare.

*Calcolo dei KPI affidato al modello:* Il modello riceve i dati grezzi e ne calcola direttamente gli aggregati. È l'approccio più diretto da realizzare, ed è anche quello che viola nel modo più evidente il vincolo: il calcolo è esattamente l'operazione che un modello linguistico non garantisce. Su volumi di dati non banali si aggiunge il problema della finestra di contesto, che impone di ridurre i dati prima di passarli, introducendo una seconda fonte di imprecisione (oltre che costi altissimi).

*Semantic layer:* Le metriche sono definite una sola volta in un modello dati dichiarativo, esterno sia al database sia alle applicazioni, e vengono interrogate attraverso un'API. La definizione di "numero di ispezioni non conformi negli ultimi dodici mesi" esiste in un punto solo, è scritta da chi conosce il dominio ed è la stessa per tutte le applicazioni che la richiedono @lyft-semantic-layer. Il modello linguistico non partecipa in alcun modo al calcolo: riceve il risultato di un'interrogazione predeterminata.

La @tab:confronto-approcci riassume il confronto.

#figure(
  caption: [Confronto tra gli approcci valutati per il recupero dei dati strutturati.],
  table(
    columns: (1.2fr, 1fr, 1fr, 1fr),
    align: (left, left, left, left),
    fill: (x, y) => if y == 0 { luma(230) },
    table.header([*Criterio*], [*Text-to-SQL*], [*Calcolo dal modello*], [*Semantic layer*]),
    [Determinismo del valore],
      [Assente: la query è generata dal modello],
      [Assente: il calcolo è svolto dal modello],
      [Garantito: query predefinite],
    [Verificabilità di un errore],
      [Bassa: il risultato è plausibile anche se sbagliato],
      [Bassa: nessun riscontro sul valore prodotto],
      [Alta: la metrica è ispezionabile e riproducibile],
    [Latenza],
      [Due chiamate al modello per ogni richiesta],
      [Una chiamata su un volume di dati elevato],
      [Interrogazioni dirette, con caching nativo],
    [Manutenibilità],
      [La correttezza dipende dallo schema esposto al modello],
      [Nessuna definizione condivisa delle metriche],
      [Definizione unica e centralizzata],
    [Multi-tenancy],
      [Da realizzare a parte],
      [Da realizzare a parte],
      [Nativa, con estensione dei modelli e token JWT],
  )
)<tab:confronto-approcci>

La scelta è caduta sul semantic layer, e il prodotto adottato è Cube. Oltre a soddisfare il vincolo di determinismo, offre già realizzate alcune funzionalità che altrimenti sarebbero state da sviluppare: il caching delle interrogazioni, le API di accesso e un sistema di sicurezza multi-tenant basato su token JWT. Lo sviluppo di un backend dedicato avrebbe richiesto di riprodurle tutte, senza alcun vantaggio compensativo.

L'accostamento fra semantic layer e modello linguistico non è isolato. Lyft, che ha costruito uno strato analogo per le stesse ragioni, ne espone oggi le definizioni agli agenti di intelligenza artificiale proprio perché la loro struttura deterministica riduce le allucinazioni nelle analisi generate @lyft-semantic-layer.

Va osservato che la scelta ha un costo, ed è opportuno dichiararlo: il semantic layer non risponde a domande impreviste. Ogni metrica che non è stata definita non esiste, e il servizio non può recuperarla. Questo è accettabile perché il riepilogo non è una conversazione ma un testo a struttura nota, il cui contenuto è deciso in anticipo dal tipo di entità e dall'evento che lo richiede. Sarebbe inaccettabile in uno scenario di interrogazione libera, che è infatti l'obiettivo O04 rimasto fuori dal perimetro (sebbene probabilmente adottare questo sistema anche nel caso di Text-to-SQL dovrebbe aiutare grazie al sistema di measures e dimensions).

=== Interfacciamento tra la sorgente dati e il semantic layer <sez:interfacciamento>

La scelta del semantic layer ha aperto una questione che il piano di lavoro non prevedeva. La piattaforma conserva i dati su MongoDB, un database orientato ai documenti, mentre Cube è progettato per operare su sorgenti relazionali. Serviva quindi un modo per rendere i dati di MongoDB interrogabili da Cube, e questa è la parte dello stage che ha assorbito più tempo rispetto alle attese.

Ho valutato tre strade.

*Vista materializzata su PostgreSQL.* I documenti vengono travasati in un campo `jsonb` su PostgreSQL e da lì "srotolati" in una vista materializzata con le colonne che servono. È la soluzione che l'azienda aveva già predisposto per un singolo cliente. Ha il pregio di presentare a Cube una tabella relazionale ordinaria, e il difetto di richiedere una vista scritta a mano per ciascun cliente.

*Interrogazione diretta del campo `jsonb`.* Saltare la vista e lasciare che sia Cube a estrarre i campi dal documento grezzo, così da eliminare il passaggio da mantenere per ogni cliente. L'ho sperimentata perché avrebbe reso l'architettura generale, ma i tempi di risposta si sono rivelati proibitivi e le configurazioni SQL necessarie difficili da leggere e da mantenere.

*Esportazione in Parquet interrogata da DuckDB.* Concettualmente la soluzione migliore tra quelle esaminate: DuckDB è già incluso in Cube, quindi non aggiunge componenti all'infrastruttura, e legge i file Parquet in modo efficiente senza richiedere una vista per cliente. L'ho sperimentata e ha funzionato. A fermarla non è stato un limite tecnico, ma il passaggio successivo: per diventare la soluzione stabile avrebbe richiesto di automatizzare l'esportazione periodica dei dati da MongoDB, un lavoro infrastrutturale che l'azienda non era nelle condizioni di affrontare in quel momento.

La questione è infatti di natura infrastrutturale e riguarda il modo in cui l'azienda espone i propri dati, non il servizio oggetto dello stage: qualunque delle tre soluzioni si adotti, il servizio interroga Cube nello stesso identico modo. Constatato che il tempo speso stava sottraendosi allo sviluppo, in accordo con il tutor aziendale ho proseguito sull'ambiente PostgreSQL già configurato, lasciando la generalizzazione come intervento successivo.

A posteriori osservo che la rinuncia è stata più netta del necessario. L'automazione serviva all'esercizio continuativo in produzione, dove i dati cambiano di continuo; il lavoro dello stage si è invece svolto interamente in ambiente di sviluppo, su dati che non avevano bisogno di essere aggiornati a ogni istante, e per quello sarebbe bastata un'esportazione manuale eseguita una volta. Avrei potuto proseguire su Parquet e DuckDB senza dipendere da alcuna decisione infrastrutturale, lasciando all'azienda il solo passo dell'automazione. Averlo capito dopo è il tipo di errore che si commette quando si confonde ciò che serve al prodotto con ciò che serve al proprio lavoro.

=== Il recupero da documenti non strutturati

L'obiettivo O03 del piano di lavoro prevedeva di estendere il riepilogo alle informazioni contenute in documenti non strutturati, come procedure e manuali, attraverso un approccio RAG (_Retrieval-Augmented Generation_): i documenti vengono suddivisi in frammenti e indicizzati, e al momento della richiesta i frammenti più pertinenti vengono recuperati e forniti al modello insieme alla domanda.

Lo studio ha portato a individuare come soluzione appropriata un recupero ibrido, che combina la ricerca vettoriale per somiglianza semantica con la ricerca lessicale BM25, seguito da una fase di _re-ranking_ dei risultati @hybrid-search-rag. La ricerca vettoriale da sola tende a mancare le corrispondenze esatte su codici e sigle, che in un contesto di manutenzione sono frequenti; la ricerca lessicale da sola non coglie le riformulazioni.

L'approccio è stato analizzato ma non realizzato. La ragione non è tecnica ma di perimetro: richiede un'infrastruttura di indicizzazione e di recupero autonoma, il cui sviluppo avrebbe occupato la parte restante dello stage lasciando incompiuto il flusso sui dati strutturati. La decisione, concordata con il tutor aziendale, è discussa nel @cap:introduzione[Capitolo] e ripresa tra gli sviluppi futuri.

Vale però osservare che la separazione di responsabilità stabilita all'inizio di questo capitolo rimane valida anche in quello scenario. Un frammento di documento recuperato è un dato reale, non una deduzione del modello, e viene fornito al modello nello stesso modo in cui gli vengono forniti i KPI. La struttura del servizio, come si vedrà nella @sez:summary[Sezione], è predisposta ad accogliere questa seconda sorgente senza modifiche al flusso.

== Architettura del servizio <sez:architettura>

=== Le tre operazioni

Il servizio espone tre operazioni, che corrispondono a tre momenti distinti nella vita di un riepilogo.

La *produzione* costruisce un riepilogo. Ricevuti il tenant, l'entità e l'evento che l'ha richiesta, recupera le interrogazioni configurate per quel caso, ne ottiene i valori dal semantic layer, li affida al modello linguistico e conserva il testo ottenuto.

La *consultazione* restituisce un riepilogo già prodotto, oppure segnala che non ne esiste alcuno. Non produce nulla e non ha effetti: è una sola lettura.

L'*invalidazione* elimina i riepiloghi di un'entità che è stata modificata, così che smettano di essere restituiti dalla consultazione.

La divisione in tre operazioni distinte, e in particolare il fatto che la consultazione non produca mai nulla, è la scelta di progettazione più importante dell'intero servizio, e la motivo nella @sez:scelte[Sezione]. La @fig:architettura mostra il flusso completo.

// sorgente del diagramma: tesi/puml/architettura.puml
#figure(
  caption: [Architettura del servizio e flusso delle tre operazioni.],
  image("../images/architettura.png", width: 84%)
)<fig:architettura>

=== Stile architetturale

Il servizio non viene invocato: resta in ascolto e reagisce a ciò che gli altri componenti della piattaforma producono. L'integrazione avviene per *scambio di messaggi asincroni*, e i due canali di ingresso portano messaggi di natura diversa. Sulla coda di produzione arrivano comandi, cioè richieste rivolte al servizio perché compia un'operazione. Sul canale di invalidazione arrivano notifiche di eventi: la piattaforma dichiara che un'entità è stata modificata, senza stabilire che cosa se ne debba fare, e la distribuzione avviene in _publish-subscribe_ attraverso un topic al quale più consumatori possono iscriversi @integration-patterns. È questa seconda forma a rendere il servizio autonomo nel mantenere validi i propri riepiloghi. Alle due code si affianca il canale sincrono della consultazione, riservato alle letture.

All'interno, il servizio segue lo stile *ports and adapters*, noto anche come architettura esagonale @hexagonal-architecture. Il nucleo applicativo è il package `summary`, che non conosce alcun sistema esterno: dichiara le interfacce di ciò che gli occorre, e quelle interfacce sono le porte. Le realizzazioni concrete stanno fuori e ne sono gli adattatori: l'archivio su MongoDB, il servizio che recupera i KPI, il client del modello linguistico, il lettore delle impostazioni del cliente. Lo stesso criterio si ripete un livello più sotto, perché anche il servizio dei KPI dichiara a sua volta l'interfaccia del semantic layer di cui ha bisogno. Dal lato opposto stanno gli adattatori in ingresso, cioè i due consumatori di coda e il gestore dell'endpoint HTTP, la funzione che riceve la richiesta di consultazione e vi risponde. A collegare le due sponde è il _composition root_, l'unico luogo del programma che conosce insieme le porte e gli adattatori.

Ciò che tiene insieme questa struttura è la direzione delle dipendenze, che puntano tutte verso il nucleo: è la persistenza a dipendere dall'interfaccia dichiarata dal dominio, non il dominio a dipendere da MongoDB. Da qui discendono due proprietà concrete. Sostituire l'archivio o il fornitore del modello linguistico non tocca la logica di produzione, perché il nucleo continua a vedere la stessa porta. E nei test quelle stesse porte accolgono realizzazioni finte, così il flusso si esercita per intero senza rete e senza costi.

Da questo schema il servizio si discosta in un punto, deliberatamente: la consultazione non attraversa il nucleo, perché quel gestore legge l'archivio direttamente. È la scelta che le impedisce di produrre riepiloghi, per le ragioni esposte nella @sez:scelte[Sezione].

=== Organizzazione del codice

Il servizio è scritto in Go e segue l'organizzazione convenzionale del linguaggio, che distingue il codice eseguibile dai package di libreria. Sotto `cmd` risiede il punto di ingresso, che legge la configurazione, apre le connessioni verso i sistemi esterni, costruisce i componenti e avvia i tre ascoltatori. Sotto `internal` risiedono i package applicativi, ciascuno con una responsabilità circoscritta.

#figure(
  caption: [I package del servizio e le dipendenze tra essi.],
  image("../images/pacchetti.png", width: 88%)
)<fig:pacchetti>

/ `summary`: coordina la produzione di un riepilogo, dalla raccolta dei dati alla chiamata al modello;
/ `kpi`: recupera le interrogazioni configurate per il tenant e l'evento, le esegue sul semantic layer e ne restituisce i risultati;
/ `store`: conserva, restituisce e cancella i riepiloghi prodotti;
/ `tenant`: legge le impostazioni del cliente che influenzano il contenuto del riepilogo;
/ `clients`: contiene gli adattatori verso i sistemi esterni, ovvero MongoDB, Cube, OpenAI e AWS;
/ `config`: raccoglie e valida la configurazione da file e variabili d'ambiente.

Come mostra la @fig:pacchetti, le frecce delle dipendenze puntano tutte dall'alto verso il basso: il punto di ingresso conosce ogni package, mentre i package applicativi non si conoscono tra loro e nessuno di essi importa gli altri. Il criterio che rende possibile questa struttura è che le dipendenze sono dichiarate da chi le usa e non da chi le fornisce, ed è approfondito nella @sez:summary[Sezione].

== Scelte di progettazione <sez:scelte>

Le decisioni raccolte in questa sezione non riguardano un singolo componente ma la forma complessiva del servizio. Sono le scelte su cui mi sono confrontato più a lungo con il tutor aziendale, e per ciascuna riporto le alternative valutate e la ragione della preferenza.

=== Comandi asincroni e letture sincrone

La prima versione del servizio riceveva ogni cosa dalla coda. Era una scelta comoda in prototipazione, ma inadeguata alla consultazione: l'operatore apre una scheda e attende una risposta, mentre una coda non risponde a chi le scrive.

Ho quindi separato i due canali secondo la natura delle operazioni. La produzione e l'invalidazione sono comandi: modificano lo stato, richiedono tempo, possono fallire e in tal caso vanno ritentati. Una coda offre esattamente questo, perché conserva il messaggio finché non viene elaborato con successo e assorbe i picchi di richieste senza sovraccaricare il servizio. La consultazione è invece una lettura: è veloce, non ha effetti, e chi la esegue ha bisogno della risposta immediatamente. Un endpoint HTTP sincrono le si adatta senza sforzo.

La distinzione tra comandi, che modificano lo stato, e interrogazioni, che si limitano a leggerlo, è un principio consolidato di progettazione; qui viene applicata ai canali, assegnando a ciascuna delle due famiglie il mezzo di trasporto che le è congeniale.

Resta da spiegare come la piattaforma venga a sapere che una produzione richiesta è terminata. Il servizio non la avvisa: SQS non offre al mittente alcun riscontro sull'esito dell'elaborazione, e costruire un canale di notifica dedicato avrebbe aggiunto una componente al solo scopo di comunicare un fatto già osservabile. L'interfaccia interroga periodicamente la consultazione finché il riepilogo non compare, con un limite di tempo oltre il quale segnala all'operatore che la richiesta non è andata a buon fine. Il meccanismo riusa un'operazione che esiste già ed è la più economica del servizio.

=== Una coda per ciascun comando

I due comandi potevano viaggiare su una sola coda, distinti da un campo del messaggio. Ho preferito due code separate.

I due messaggi hanno origini e forme diverse. La richiesta di produzione è definita insieme al servizio e ne segue il formato; la segnalazione di modifica appartiene alla piattaforma, esisteva già per altri scopi e arriva incapsulata nella struttura del sistema di distribuzione. Con una coda sola il consumatore dovrebbe riconoscere il formato prima di poterlo leggere, ramificare sul tipo di comando e cercare l'identificativo del tenant in posizioni diverse a seconda dei casi: una logica di smistamento che non appartiene a nessuno dei due flussi e che va mantenuta insieme a entrambi.

Anche i volumi e i costi sono asimmetrici. Un'invalidazione è una cancellazione, arriva a ogni modifica di un'entità e può presentarsi a ondate quando la piattaforma esegue aggiornamenti massivi. Una produzione comporta diverse interrogazioni e una chiamata al modello linguistico, e dietro di essa c'è un operatore che aspetta. Su una coda condivisa un'ondata di invalidazioni si metterebbe in fila davanti alla richiesta di quell'operatore; con due code i due flussi hanno consumatori distinti e non si ostacolano.

Il costo infrastrutturale non entra nel confronto perché SQS si tariffa sul numero di richieste e non sul numero di code: due code che smaltiscono lo stesso traffico di una costano quanto quella.

=== Un archivio, non una cache

Il riepilogo prodotto viene conservato su MongoDB. La differenza rispetto a una cache non è terminologica ma di comportamento, e sta in cosa accade quando il riepilogo non c'è.

Una cache, non trovando il valore, lo ricalcola e lo restituisce a chi lo aveva chiesto. Applicato a questo servizio significherebbe che aprire la scheda di un'entità priva di riepilogo ne avvia la produzione: l'operatore attende alcuni secondi senza averlo chiesto, e ogni apertura di scheda genera una chiamata al modello, che è l'operazione più costosa del servizio. Peggio ancora, la richiesta esplicita di produzione perderebbe di senso, perché la semplice consultazione avrebbe già fatto tutto.

Il servizio si comporta invece come un archivio: se il riepilogo non c'è, lo dichiara e si ferma. Sta alla piattaforma decidere cosa farne, e la scelta naturale è proporre all'operatore di richiederne la produzione. Il costo viene sostenuto solo quando qualcuno lo ha voluto.

Questa scelta è il motivo per cui la lettura dell'archivio non appartiene al package che produce i riepiloghi ma è raggiunta direttamente dall'endpoint di consultazione, come si vedrà nella @sez:http[Sezione]. Se la consultazione passasse per il codice di produzione, la tentazione di far produrre in caso di assenza sarebbe a una riga di distanza. Tenendo separati i due percorsi la garanzia è strutturale e non affidata alla disciplina di chi scriverà il codice in seguito.

=== Granularità dell'invalidazione

Un'entità può avere più riepiloghi, uno per ciascun evento che li ha richiesti. Quando arriva la segnalazione che l'entità è cambiata, il servizio li cancella tutti.

La segnalazione dice che l'entità è stata modificata e nulla più: non conosce l'esistenza dei riepiloghi né quali dati ciascuno di essi utilizzi. L'alternativa era dichiarare, per ogni riepilogo, da quali fonti dipende, e cancellare solo quelli effettivamente toccati. L'ho scartata perché la sua correttezza si reggerebbe su una dichiarazione mantenuta a mano: chi aggiungesse una fonte a un'interrogazione dimenticando di aggiornare la dichiarazione non provocherebbe alcun guasto visibile, e semplicemente un giorno un operatore leggerebbe un dato vecchio senza avere modo di accorgersene.

Il confronto è quindi tra due errori. Cancellare troppo produce una rigenerazione superflua: rumorosa, immediatamente osservabile, innocua. Cancellare troppo poco produce un dato non aggiornato mostrato come se fosse attuale: silenzioso, invisibile e dannoso. La preferenza per il primo è netta.

Il disegno su richiesta rende inoltre il costo di cancellare troppo quasi nullo. La cancellazione non rigenera nulla di per sé: il costo si materializza soltanto se qualcuno apre davvero quella scheda e chiede il riepilogo, e in quel caso lo ottiene aggiornato.

Va segnalato un vincolo infrastrutturale che questa scelta comporta. SQS è punto a punto: un messaggio consegnato a un consumatore non è più disponibile per gli altri. Il servizio non può quindi mettersi in ascolto sulla coda con cui la piattaforma già distribuisce gli eventi di modifica, perché sottrarrebbe i messaggi al loro destinatario originario. Serve invece iscrivere una coda dedicata al topic SNS da cui quegli eventi provengono, così che il sistema di distribuzione ne recapiti una copia a ciascun consumatore.

=== Idempotenza

Elaborare due volte lo stesso messaggio non deve produrre effetti diversi dall'elaborarlo una volta sola. Non è una precauzione teorica ma la conseguenza diretta di come funziona l'infrastruttura scelta: SQS garantisce la consegna almeno una volta, il che significa che lo stesso messaggio può essere recapitato due volte anche in assenza di errori. Vi si aggiunge il fatto che la libreria di consumo interna non verifica l'esito della cancellazione del messaggio dalla coda: se quella cancellazione fallisce, il messaggio ricompare e viene rielaborato.

Entrambi i comandi sono quindi costruiti perché la ripetizione sia innocua, come richiede RQA-OB\_07. La produzione controlla per prima cosa se il riepilogo esiste già e in tal caso lo restituisce senza rifarlo, evitando una seconda chiamata al modello. L'invalidazione cancella ciò che trova e considera un esito valido il non aver trovato nulla, perché l'entità poteva legittimamente non avere riepiloghi. Il codice corrispondente è mostrato nelle sezioni @sez:summary[] e @sez:store[].

Si noti che il controllo iniziale della produzione ha un effetto collaterale voluto: una richiesta di produzione su un riepilogo esistente non lo rigenera. Per ottenere un riepilogo aggiornato occorre prima invalidare, che è esattamente ciò che accade quando i dati cambiano davvero.

=== Robustezza degli ingressi

Il servizio riceve richieste da tre canali e da sistemi che non controlla. Un messaggio malformato, un identificativo assente o un'indisponibilità temporanea del semantic layer non devono comprometterne il funzionamento, come prescrive RQA-OB\_06.

Ogni richiesta viene quindi validata prima di essere elaborata: quelle prive del tenant, dell'identificativo dell'entità o dell'evento sono rifiutate subito, senza attivare il flusso e senza spendere una chiamata al modello. Il servizio prosegue nel frattempo con i messaggi successivi, e un ingresso scorretto resta un fatto locale a quel messaggio.

Su questo punto il servizio presenta però una lacuna che è corretto dichiarare. Un messaggio rifiutato non viene cancellato dalla coda, perché la cancellazione avviene solo in caso di successo, e torna quindi disponibile per un nuovo tentativo. Trattandosi di un messaggio malformato il tentativo fallirà di nuovo, e il messaggio verrà ripresentato indefinitamente. Il rimedio previsto da SQS è la coda di scarto (_dead letter queue_), sulla quale i messaggi vengono spostati dopo un numero configurato di tentativi falliti, in modo da toglierli dal ciclo e conservarli per l'ispezione. Non è stata configurata nel corso dello stage, e la riprendo tra gli sviluppi futuri nel @cap:conclusioni[Capitolo].

Un criterio diverso vale all'interno della produzione, sui singoli blocchi di dati. Un'interrogazione che restituisce un risultato vuoto non fa fallire nulla: il blocco arriva al modello privo di valori, e le istruzioni gli impongono di omettere ciò che manca invece di supplirvi. Se invece è il semantic layer a non rispondere, il fallimento riguarda la richiesta nel suo complesso e non un suo frammento: la produzione si interrompe, nessun riepilogo parziale viene conservato e il messaggio torna sulla coda per essere ritentato quando il sistema sarà di nuovo raggiungibile.

=== Design pattern adottati

Le decisioni descritte in questa sezione diventano codice attraverso tre pattern di progettazione @design-patterns, che vale la pena nominare perché sono il vocabolario con cui lo stile illustrato nella @sez:architettura[Sezione] si realizza concretamente. Discendono tutti e tre dalla stessa idea, programmare verso un'interfaccia anziché verso una realizzazione, ma rispondono a domande diverse, e tenerle distinte è ciò che evita di scambiare un pattern per l'altro.

*Dependency injection.* La domanda è chi decida quale realizzazione un componente userà. Il coordinatore della produzione ha bisogno di un archivio, di un modello linguistico, di una sorgente di dati e delle impostazioni del cliente: se se li costruisse da sé dovrebbe conoscere MongoDB, OpenAI e Cube, e non sarebbe verificabile senza di essi. Li riceve invece dall'esterno al momento della costruzione, sotto forma di quattro valori che soddisfano le interfacce dichiarate.

```go
// internal/summary/summary.go
func New(store Store, llm LLM, kpi Source,
	tenants Tenants) *Service {
	return &Service{store: store, llm: llm,
		kpi: kpi, tenants: tenants}
}
```

La scelta delle realizzazioni concrete avviene in un punto solo dell'intero programma, il composition root.

```go
// cmd/context-service/main.go
summaries := store.New(db)
tenants := tenant.New(db)
kpiService := kpi.New(db, cubeClient)
summaryService := summary.New(
	summaries, llm, kpiService, tenants)
```

Il guadagno immediato è la verificabilità: nei test quelle stesse quattro posizioni ricevono realizzazioni finte, e il flusso di produzione si esercita per intero senza rete e senza costi. Il pattern realizza inoltre il principio di inversione delle dipendenze, perché il nucleo dipende da astrazioni che possiede e non da tipi concreti che gli sono esterni.

*Repository.* La domanda è quale parte del sistema debba sapere in che modo i dati sono conservati. Il coordinatore deve poter salvare un riepilogo e rileggerlo, ma non ha ragione di sapere che quel riepilogo vive in una collection di MongoDB individuata da una coppia di campi. L'interfaccia è quindi espressa nei termini del dominio, l'entità e l'evento, e non in quelli del database.

```go
// internal/summary/summary.go
type Store interface {
	Get(ctx context.Context, tenantID, geocID,
		trigger string) (string, bool, error)
	Save(ctx context.Context, tenantID, geocID,
		trigger, summary string) error
}
```

Tutto ciò che è specifico di MongoDB, ovvero i filtri, l'_upsert_, l'indice unico e i limiti di tempo, resta confinato nel package `store` descritto nella @sez:store[Sezione]. Se l'archivio cambiasse tecnologia, il coordinatore non se ne accorgerebbe.

*Adapter.* La domanda è come far dialogare due interfacce concepite per scopi diversi. Al servizio serve una sola operazione, produrre un testo date delle istruzioni e dei dati.

```go
// internal/summary/summary.go
type LLM interface {
	Complete(ctx context.Context, systemPrompt,
		userMessage string) (string, error)
}
```

L'SDK di OpenAI parla però un'altra lingua: chiede di comporre una struttura di parametri con il modello, la temperatura e un elenco tipizzato di messaggi distinti per ruolo, e restituisce un insieme di risposte alternative da cui estrarre la prima. Il package `openaiclient`, riportato nella @sez:clients[Sezione], è il solo punto dell'intero servizio in cui le due forme si incontrano. Cambiare fornitore significa scrivere un secondo adattatore, non modificare la logica di produzione, e lo stesso vale per gli altri tre client, verso MongoDB, Cube e AWS.

Un quarto pattern compare in forma minore nei consumatori delle code: le funzioni che elaborano i messaggi non sono scritte direttamente ma prodotte da una _factory_, che riceve il componente da usare e restituisce la funzione già legata a esso, come si vedrà nella @sez:consumatori[Sezione].

== Il semantic layer <sez:semantic>

Il lavoro dello stage non si esaurisce nel servizio in Go. I KPI che il servizio recupera non esistono finché qualcuno non li definisce, e definirli ha occupato una parte consistente del tempo: vivono in un modello dati dichiarativo che Cube compila e traduce in SQL al momento dell'interrogazione.

=== La sorgente relazionale

Cube interroga PostgreSQL, dove i documenti di MongoDB arrivano in due forme. Una tabella di appoggio conserva ciascun documento intero in un campo `jsonb`; una vista materializzata ne espone in colonne i campi di uso più frequente. Ogni cubo del modello parte da una `SELECT` che unisce le due.

```yaml
# cube/model/shared/tickets_base.yml
cubes:
  - name: tickets_base
    sql: >
      SELECT
        v.id,
        v.priority,
        v.status,
        (v.date)::timestamptz AS opened_at,
        v.ts_response         AS responded_at,
        v."desc"              AS description,
        s.raw
      FROM mongo_mv_tickets v
      JOIN mongo_staging_tickets s ON v.id = s.id
```

La vista fornisce le colonne già pronte, mentre il campo `raw` resta a disposizione per tutto ciò che la vista non espone. Il secondo caso non è raro, perché alcune informazioni vivono in profondità dentro il documento e vanno estratte una per una.

```yaml
- name: closed_at
  sql: >
    (SELECT (t.value ->> 'ts')::timestamptz
       FROM jsonb_array_elements(
              ({CUBE}.raw -> 'status') -> 'transitions'
            ) t(value)
      WHERE t.value ->> 'metatype' = 'closed'
      ORDER BY (t.value ->> 'ts')::timestamptz
      LIMIT 1)
  type: time
```

Un ticket non ha un campo con la data di chiusura: ha un elenco di transizioni di stato, e la chiusura è la prima transizione il cui tipo è `closed`. Ricavarla significa scorrere quell'elenco dentro il documento. È il genere di espressione che, moltiplicata per ogni campo, rendeva difficile da mantenere l'interrogazione diretta del `jsonb` discussa nella @sez:interfacciamento[Sezione]. Scritta qui, però, viene scritta una volta sola.

=== Dimensioni e metriche

Un cubo dichiara dimensioni e metriche. Le dimensioni sono gli attributi su cui si può filtrare e raggruppare; le metriche sono i valori aggregati che si possono chiedere.

```yaml
measures:
  - name: total_tickets
    type: count

  - name: open_tickets
    type: count
    filters:
      - sql: "{closed_at} IS NULL"

  - name: avg_resolution_days
    sql: >
      EXTRACT(EPOCH FROM
        ({closed_at} - {opened_at})) / 86400
    type: avg
    filters:
      - sql: "{closed_at} IS NOT NULL"
```

Il valore di questa forma sta nella riga `filters` di `open_tickets`. Che cosa significhi "ticket aperto" è stabilito in un punto solo, ed è un ticket privo di transizione di chiusura. Chiunque chieda `open_tickets`, il servizio di contesto oggi o una dashboard domani, riceve lo stesso numero calcolato nello stesso modo. È la ragione per cui il semantic layer è stato scelto, e qui si vede messa in pratica.

Si noti anche che le definizioni si appoggiano l'una all'altra: `closed_at` è estratta dal documento, `open_tickets` la usa come filtro e `avg_resolution_days` la usa come estremo di un intervallo. La complessità dell'estrazione resta confinata in un punto e tutto il resto ne discende.

=== La specializzazione per cliente

Le definizioni comuni stanno in `model/shared`, quelle di un singolo cliente in `model/tenants/<identificativo>`. Un cubo del cliente estende quello condiviso, tramite la direttiva `extends` @cube-extending, e vi aggiunge ciò che serve soltanto a lui.

```yaml
# cube/model/tenants/6902.../inspections_ferrovie.yml
cubes:
  - name: inspection_ferrovie
    extends: inspections_base

    dimensions:
      - name: physical_risk
        sql: >
          CASE upper({CUBE}.risk_physical)
            WHEN 'BASSO' THEN 0
            WHEN 'MEDIO' THEN 1
            WHEN 'ALTO'  THEN 2 END
        type: number

    measures:
      - name: physical_risk_max
        sql: "{physical_risk}"
        type: max
```

Questo cliente registra i livelli di rischio come testo, e per poterne calcolare il peggiore occorre prima tradurli in numeri. È una necessità sua: un altro cliente potrebbe non avere affatto i livelli di rischio, oppure misurarli su una scala diversa. È la variabilità per cliente descritta nel @cap:analisi-requisiti[Capitolo], vista dal lato della realizzazione.

L'estensione spiega anche perché le interrogazioni configurate per questo cliente nominano `inspection_ferrovie` e non `inspections_base`, pur usando membri che appartengono al cubo condiviso.

```json
{
  "measures": [
    "inspection_ferrovie.physical_risk_max",
    "inspection_ferrovie.total_completed_inspections"
  ],
  "timeDimensions": [{
    "dimension": "inspection_ferrovie.inspection_date",
    "granularity": "year"
  }]
}
```

`physical_risk_max` è definita nel file del cliente, mentre `total_completed_inspections` e `inspection_date` vengono dal file condiviso: dopo l'estensione appartengono tutte allo stesso cubo.

=== La segregazione dei dati fra clienti

Il servizio firma un token JWT con l'identificativo del tenant e lo allega a ogni interrogazione. Cube lo legge dal contesto di sicurezza e, se manca, rifiuta la richiesta.

```javascript
// cube/cube.js
function getTenantId(context) {
  const fromToken = context && context.securityContext
    && context.securityContext.tenant_id;
  if (fromToken) {
    return fromToken;
  }
  throw new Error('Missing tenant_id in JWT token');
}
```

Da quell'identificativo discendono tre decisioni. La prima riguarda quali definizioni caricare: ai file condivisi si aggiungono quelli della cartella del cliente, e il modello compilato risulta diverso da cliente a cliente.

```javascript
repositoryFactory: function (context) {
  const tenantId = getTenantId(context);
  return {
    dataSchemaFiles: async function () {
      const shared = loadDir(
        path.join(__dirname, 'model', 'shared'));
      const tenantFiles = loadDir(
        path.join(__dirname, 'model', 'tenants', tenantId));
      return shared.concat(tenantFiles);
    },
  };
},
```

La seconda riguarda il database a cui connettersi, che è quello intestato al cliente.

```javascript
driverFactory: function (context) {
  const tenantId = getTenantId(context);
  return {
    type: 'postgres',
    host: process.env.CUBEJS_DB_HOST,
    user: process.env.CUBEJS_DB_USER,
    password: process.env.CUBEJS_DB_PASSWORD,
    database: tenantId,
  };
}
```

La terza riguarda le cache: `contextToAppId` distingue gli schemi compilati e `contextToOrchestratorId` separa i pool di connessioni e le pre-aggregazioni, entrambi etichettati con l'identificativo del cliente.

Ne segue che la segregazione richiesta da RQA-OB\_04 non è un filtro applicato alle interrogazioni, ma la conseguenza del fatto che due clienti non condividono nulla: né le definizioni, né la connessione, né la cache. Un'interrogazione scritta male non può raggiungere i dati di un altro cliente, perché il database in cui quei dati vivono non è nemmeno aperto. È una garanzia più solida di quella offerta da un filtro, che dipenderebbe invece dalla correttezza di chi lo scrive.

Lo stesso identificativo ricorre infine in tre punti: è il nome del database MongoDB del cliente, il nome del suo database PostgreSQL e il nome della cartella dei suoi modelli. Il servizio lo riceve nel messaggio e lo propaga senza mai doverlo tradurre.

== Sviluppo dei componenti

La @fig:sequenza segue una richiesta di produzione dal messaggio in coda fino al riepilogo conservato, e mostra in quale ordine i componenti entrano in gioco.

// sorgente del diagramma: tesi/puml/sequenza-produzione.puml
#figure(
  caption: [Il flusso di produzione di un riepilogo.],
  image("../images/sequenza-produzione.png", width: 100%)
)<fig:sequenza>

Il consumatore valida il messaggio e chiama il coordinatore, che per prima cosa interroga l'archivio: se il riepilogo esiste già lo restituisce e il flusso finisce lì, senza spendere nulla. Altrimenti legge lingua e fuso del cliente, chiede i dati al servizio dei KPI, che esegue in parallelo le interrogazioni configurate per quell'evento, riunisce i risultati in un unico payload, lo affida al modello linguistico e conserva il testo ottenuto.

Le sezioni che seguono percorrono lo stesso tragitto: prima il coordinatore, poi le parti che utilizza, infine il punto di ingresso che collega tutto e gli ascoltatori sui tre canali. Gli estratti di codice provengono dai file effettivi del servizio, con i commenti presenti nel codice; alcune righe sono spezzate per adattarle alla pagina.

=== Il coordinatore della produzione <sez:summary>

Il package `summary` contiene la logica centrale del servizio: dato un tenant, un'entità e un evento, produrre il riepilogo. Per farlo ha bisogno di quattro collaborazioni esterne: una sorgente di dati, un modello linguistico, un archivio in cui salvare e le impostazioni del cliente. La decisione strutturale più importante del package è che nessuna di queste collaborazioni è un riferimento concreto: sono quattro interfacce, dichiarate dal package stesso.

```go
// internal/summary/summary.go

type Source interface {
	Blocks(ctx context.Context, tenantID, geocID,
		trigger, timezone string) (map[string]any, error)
}

// quello che ci serve dall'llm; interfaccia definita
// qui così nei test si può passare una versione finta
type LLM interface {
	Complete(ctx context.Context, systemPrompt,
		userMessage string) (string, error)
}

// quello che ci serve dall'archivio; la generazione
// non sa che dietro c'è mongo
type Store interface {
	Get(ctx context.Context, tenantID, geocID,
		trigger string) (string, bool, error)
	Save(ctx context.Context, tenantID, geocID,
		trigger, summary string) error
}

// lingua e fuso del tenant, che cambiano il riepilogo
type Tenants interface {
	Get(ctx context.Context,
		tenantID string) (language, timezone string, err error)
}

type Service struct {
	store   Store
	llm     LLM
	kpi     Source
	tenants Tenants
}
```

In Go le interfacce sono soddisfatte implicitamente: un tipo le realizza per il solo fatto di possedere i metodi richiesti, senza dichiararlo. La convenzione del linguaggio è che l'interfaccia appartenga a chi la consuma e non a chi la fornisce, ed è l'inverso di quanto avviene nei linguaggi a oggetti tradizionali. La conseguenza è visibile nella @fig:interfacce: i package che realizzano le quattro interfacce non importano `summary`, e `summary` non importa loro. Le frecce di realizzazione attraversano i confini dei package senza che alcun file di codice le dichiari.

// sorgente del diagramma: tesi/puml/summary-interfacce.puml
#figure(
  caption: [Le interfacce del package summary e i tipi che le realizzano.],
  image("../images/summary-interfacce.png", width: 100%)
)<fig:interfacce>

Questa impostazione ha due effetti pratici. Il primo è che `summary` non sa che i riepiloghi finiscono su MongoDB né che il modello è quello di OpenAI: sostituire l'uno o l'altro non tocca la logica di produzione. Il secondo riguarda i test, ed è quello che ha inciso di più: fornendo realizzazioni finte delle quattro interfacce, il flusso di produzione si verifica per intero senza chiamare il modello linguistico, quindi senza costi e in modo ripetibile, come descritto nel @cap:verifica[Capitolo].

Il metodo `Produce` percorre l'intero flusso, e lo riporto integralmente perché è il cuore del servizio.

```go
// internal/summary/summary.go

func (s *Service) Produce(ctx context.Context,
	tenantID, geocID, trigger string) (string, error) {

	// se la sintesi c'è già non la rifacciamo: sqs può
	// consegnare due volte lo stesso messaggio e l'llm
	// è la cosa più cara che facciamo
	summary, found, err := s.store.Get(ctx, tenantID,
		geocID, trigger)
	if err != nil {
		return "", fmt.Errorf(
			"reading stored summary: %w", err)
	}
	if found {
		return summary, nil
	}

	language, timezone, err := s.tenants.Get(ctx, tenantID)
	if err != nil {
		return "", fmt.Errorf("tenant settings: %w", err)
	}

	// ogni servizio produce i suoi blocchi; li fondiamo
	// in un'unica mappa così l'llm viene chiamato una
	// volta sola con tutto il contesto
	data := map[string]any{}
	for _, src := range s.sourcesFor(trigger) {
		blocks, err := src.Blocks(ctx, tenantID, geocID,
			trigger, timezone)
		if err != nil {
			return "", err
		}
		for name, block := range blocks {
			data[name] = block
		}
	}

	payload, err := json.MarshalIndent(
		map[string]any{"geoc_id": geocID, "data": data},
		"", "  ")
	if err != nil {
		return "", fmt.Errorf("building payload: %w", err)
	}

	summary, err = s.llm.Complete(ctx,
		systemPrompt(language), string(payload))
	if err != nil {
		return "", fmt.Errorf(
			"generating summary: %w", err)
	}

	// se il salvataggio fallisce restituiamo comunque
	// il riepilogo
	if err := s.store.Save(ctx, tenantID, geocID,
		trigger, summary); err != nil {
		fmt.Fprintln(os.Stderr, "saving summary:", err)
	}
	return summary, nil
}
```

Quattro punti del metodo meritano un commento.

Il controllo iniziale sull'archivio realizza l'idempotenza della produzione discussa nella @sez:scelte[Sezione]: una consegna ripetuta dello stesso messaggio trova il riepilogo già salvato e non paga una seconda chiamata al modello.

Le sorgenti vengono richieste a `sourcesFor`, che oggi restituisce la sola sorgente dei KPI ma esiste come elenco proprio in previsione della sorgente documentale discussa nello studio degli approcci: aggiungerla significherà aggiungere un elemento a questa lista, senza toccare il flusso.

```go
// smistamento deterministico: dato il trigger,
// la lista di servizi da attivare
func (s *Service) sourcesFor(trigger string) []Source {
	return []Source{s.kpi}
}
```

I blocchi di tutte le sorgenti confluiscono in un'unica struttura JSON e la chiamata al modello è una sola, con tutto il contesto: chiamarlo una volta per blocco avrebbe prodotto testi indipendenti da ricucire, mentre il riepilogo deve leggersi come un discorso unico.

Infine, un fallimento del salvataggio non fa fallire la produzione: il lavoro costoso è già stato fatto, e perdere il testo per un problema di scrittura sarebbe uno spreco senza contropartita. L'errore viene segnalato e il riepilogo restituito comunque.

Le istruzioni per il modello risiedono nello stesso package. Il messaggio di sistema è fisso e ne varia soltanto la lingua, letta dalle impostazioni del tenant come richiede RQA-OB\_02:

```go
// internal/summary/prompt.go

// stesso meccanismo di {{GEOC_ID}} nelle query:
// sostituzione letterale, nessun carattere speciale
const promptTemplate = `
You are a technical analyst. You receive (as JSON)
an asset with one or more data blocks: each block
has an "instructions" field explaining how to read
that data and a "result" field with the values.
Write a single summary, professional and in
{{LANGUAGE}}, following each block's "instructions"
and relying EXCLUSIVELY on the data provided.
[...]
`

// istruzioni fisse per l'llm; la lingua è quella
// impostata dal tenant
func systemPrompt(language string) string {
	return strings.ReplaceAll(promptTemplate,
		"{{LANGUAGE}}", language)
}
```

La sostituzione della lingua è volutamente letterale, con `strings.ReplaceAll` anziché con la formattazione di stringhe del linguaggio: il testo delle istruzioni contiene caratteri, come il segno di percentuale, che una funzione di formattazione interpreterebbe come segnaposto, corrompendo silenziosamente il prompt. Le regole omesse nell'estratto impongono al modello di attenersi ai soli dati presenti, omettere quanto manca invece di supplirvi, non riportare codici identificativi, esplicitare sempre le date e rispettare il limite di lunghezza richiesto da RQA-DE\_02.

=== L'estrazione dei KPI

Il package `kpi` realizza l'interfaccia `Source` ed è responsabile di trasformare un evento in un insieme di blocchi di dati. Quali dati compongano il riepilogo non è scritto nel codice: ogni tenant possiede nel proprio database una collection `kpi_query`, in cui ciascun documento descrive un blocco. Questo è un esempio reale, abbreviato nei campi testuali:

```json
{
  "name": "ticket_stats",
  "triggers": ["ticket_opened"],
  "instructions": "Report the total number of
    tickets of the asset and how many are still
    open. Report the average first-response
    time and [...]",
  "query": {
    "measures": [
      "tickets_base.total_tickets",
      "tickets_base.open_tickets",
      "tickets_base.avg_response_days",
      "tickets_base.avg_resolution_days"
    ],
    "dimensions": ["tickets_base.geoc_id"],
    "filters": [{
      "member": "tickets_base.geoc_id",
      "operator": "equals",
      "values": ["{{GEOC_ID}}"]
    }]
  }
}
```

Il campo `triggers` elenca gli eventi per i quali il blocco è pertinente, ed è ciò che realizza la differenziazione richiesta da RF-OB\_03; il campo `instructions` accompagna i valori fino al modello e gli dice come leggerli; il campo `query` è l'interrogazione per il semantic layer, con il segnaposto `{{GEOC_ID}}` al posto dell'entità. La selezione dei blocchi è un'unica interrogazione su MongoDB:

```go
// internal/kpi/kpi.go

type QueryDoc struct {
	Name         string `bson:"name"`
	Instructions string `bson:"instructions"`
	Query        bson.M `bson:"query"`
}

func (s *Service) getQueries(ctx context.Context,
	tenantID, trigger string) ([]QueryDoc, error) {

	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	// matcha i documenti il cui array triggers
	// contiene il trigger della richiesta
	filter := bson.M{"triggers": trigger}

	coll := s.db.Database(tenantID).
		Collection("kpi_query")
	cur, err := coll.Find(ctx, filter)
	...
}
```

Ne discende la proprietà espressa da RQA-DE\_01: aggiungere un blocco a un riepilogo, modificarne il taglio espositivo o abilitare un nuovo tipo di entità sono operazioni di configurazione, senza interventi sul codice. Non è una proprietà rimasta sulla carta: il secondo scenario realizzato, il riepilogo per i ticket, è stato aggiunto a servizio già funzionante e non ha richiesto alcuna modifica al codice, soltanto nuovi documenti in questa collection e nuove metriche nel semantic layer.

La configurazione allestita durante lo stage riguarda un solo cliente e due dei tre tipi di entità della piattaforma. Il riepilogo di un'ispezione compone l'andamento dei livelli di rischio negli anni, le non conformità rilevate e le statistiche sulle ispezioni svolte; quello di un ticket compone le statistiche sui ticket dell'asset, l'elenco dei ticket aperti e di quelli chiusi di recente, con la descrizione dell'intervento eseguito. Gli asset, terzo tipo di entità, non sono stati configurati: per quanto appena detto non richiederebbe sviluppo, ma soltanto nuove metriche nel semantic layer e nuovi documenti in questa collection. Va sottolineato che i blocchi qui elencati valgono per quel cliente e non per il sistema: un altro tenant, disponendo di dati diversi, avrebbe una configurazione diversa a parità di codice.

Le interrogazioni selezionate sono indipendenti tra loro e vengono eseguite in parallelo, una goroutine ciascuna:

```go
// internal/kpi/kpi.go

func (s *Service) runQueries(ctx context.Context,
	tenantID, geocID, timezone string,
	queries []QueryDoc) (map[string]any, error) {

	blocks := map[string]any{}
	var mu sync.Mutex
	var wg sync.WaitGroup
	var firstError error

	for _, q := range queries {
		// senza questo campo cube calcola periodi e
		// granularità in utc, spostando le date viste
		// dall'operatore
		if timezone != "" {
			q.Query["timezone"] = timezone
		}

		wg.Add(1)
		go func(q QueryDoc) {
			defer wg.Done()

			raw, err := json.Marshal(q.Query)
			...
			queryJSON := strings.ReplaceAll(
				string(raw), "{{GEOC_ID}}", geocID)

			result, err := s.cube.Query(
				ctx, tenantID, queryJSON)

			mu.Lock()
			defer mu.Unlock()
			if err != nil {
				if firstError == nil {
					firstError = fmt.Errorf(
						"query %s: %w", q.Name, err)
				}
				return
			}
			blocks[q.Name] = map[string]any{
				"instructions": q.Instructions,
				"result":       result,
			}
		}(q)
	}
	wg.Wait()
	if firstError != nil {
		return nil, fmt.Errorf(
			"querying cube: %w", firstError)
	}
	return blocks, nil
}
```

La latenza complessiva del recupero è quella dell'interrogazione più lenta e non la somma di tutte, cosa che conta perché ogni riepilogo ne comprende più d'una: nella configurazione allestita durante lo stage sono tre sia per le ispezioni sia per i ticket. La mappa dei risultati è protetta da un mutex perché le goroutine vi scrivono in concorrenza, e viene trattenuto il primo errore: se una qualunque interrogazione fallisce, l'intera raccolta fallisce, coerentemente con il criterio esposto nella @sez:scelte[Sezione].

Il frammento mostra anche il trattamento del fuso orario richiesto da RQA-OB\_03. Cube calcola i periodi e le granularità temporali in UTC quando non gli viene indicato diversamente: un'ispezione registrata alle prime ore del mattino in Italia ricadrebbe nel giorno precedente, e il riepilogo riporterebbe una data diversa da quella che l'operatore legge sulla scheda. Il fuso configurato dal tenant viene quindi aggiunto a ogni interrogazione; se il tenant non lo imposta, il campo non compare e resta il comportamento predefinito di Cube.

=== L'archivio dei riepiloghi <sez:store>

Il package `store` gestisce la collection `ai_summaries` presente nel database di ciascun tenant, dove ogni riepilogo è identificato dalla coppia entità-evento. Espone tre operazioni, una per ciascun momento della vita del riepilogo. La lettura distingue l'assenza dall'errore, perché per questo servizio l'assenza è una risposta e non un guasto:

```go
// internal/store/store.go

// legge la sintesi salvata per (geoc_id, trigger);
// trovato=false se non c'è
func (s *Store) Get(ctx context.Context, tenantID,
	geocID, trigger string) (string, bool, error) {
	...
	err := s.summaries(tenantID).
		FindOne(ctx, bson.M{
			"geoc_id": geocID, "trigger": trigger,
		}).
		Decode(&d)
	// nessuna sintesi per questa entità
	if errors.Is(err, mongo.ErrNoDocuments) {
		return "", false, nil
	}
	if err != nil {
		return "", false, err
	}
	return d.AiSummary, true, nil
}
```

Il salvataggio è un _upsert_: se un documento per la coppia esiste viene aggiornato, altrimenti viene creato. L'operazione si appoggia a un indice unico su entità ed evento, che garantisce l'assenza di duplicati anche se due produzioni della stessa sintesi si concludessero insieme:

```go
// internal/store/store.go

// upsert della sintesi per (geoc_id, trigger)
func (s *Store) Save(ctx context.Context, tenantID,
	geocID, trigger, summary string) error {
	...
	_, err := s.summaries(tenantID).UpdateOne(ctx,
		bson.M{"geoc_id": geocID, "trigger": trigger},
		bson.M{"$set": bson.M{
			"ai_summary": summary,
			"updated_at": time.Now(),
		}},
		options.Update().SetUpsert(true),
	)
	...
}
```

La cancellazione realizza la granularità scelta nella @sez:scelte[Sezione]: elimina tutti i riepiloghi dell'entità, qualunque sia l'evento che li ha generati, e non considera un errore il non trovarne alcuno:

```go
// internal/store/store.go

// cancella tutte le sintesi dell'entità, non solo
// quelle di un trigger. chi segnala l'aggiornamento
// sa che l'entità è cambiata, non quali sintesi
// ne dipendono
func (s *Store) Delete(ctx context.Context,
	tenantID, geocID string) (int64, error) {
	...
	res, err := s.summaries(tenantID).
		DeleteMany(ctx, bson.M{"geoc_id": geocID})
	if err != nil {
		return 0, fmt.Errorf("delete: %w", err)
	}
	// zero non è un errore, l'entità poteva
	// non avere sintesi
	return res.DeletedCount, nil
}
```

=== Le impostazioni del cliente

Il package `tenant` legge dalla collection `mytenant` del database del cliente le due impostazioni che condizionano il riepilogo: la lingua e il fuso orario. Due dettagli del codice derivano dall'osservazione dei dati reali. Il primo è che la collection contiene anche un documento di soli contatori, per cui la ricerca filtra sul campo della lingua anziché prendere il primo documento disponibile. Il secondo è che la piattaforma registra la lingua come sigla, mentre al prompt serve il nome esteso: la conversione passa da una mappa delle lingue gestite, e qualunque valore non riconosciuto ricade sull'inglese, così che un dato mancante o imprevisto non blocchi mai la produzione.

```go
// internal/tenant/tenant.go

// le lingue gestite dalla piattaforma; una sigla
// che non è qui ricade sul default
var languages = map[string]string{
	"it": "Italian",
	"en": "English",
	"es": "Spanish",
	"de": "German",
	"pt": "Portuguese",
	"sk": "Slovak",
	"zh": "Chinese",
}

const defaultLanguage = "English"

// legge dalla collection mytenant la lingua, già estesa
// e pronta per il prompt, e il fuso in formato iana,
// vuoto se il tenant non lo imposta
func (r *Reader) Get(ctx context.Context,
	tenantID string) (language, timezone string, err error) {
	...
	var d settingsDoc
	// nella collection c'è anche un documento di soli
	// contatori: cerchiamo quello che ha la lingua
	err = r.db.Database(tenantID).
		Collection("mytenant").
		FindOne(ctx, bson.M{
			"sync_locale": bson.M{"$exists": true},
		}).
		Decode(&d)
	// tenant senza impostazioni:
	// meglio il default che un errore
	if errors.Is(err, mongo.ErrNoDocuments) {
		return defaultLanguage, "", nil
	}
	...
	language, ok := languages[d.Locale]
	if !ok {
		language = defaultLanguage
	}
	return language, d.Timezone, nil
}
```

=== I client verso i sistemi esterni <sez:clients>

Il package `clients` raccoglie gli adattatori verso i quattro sistemi con cui il servizio dialoga. Sono deliberatamente sottili: traducono le chiamate del servizio nelle API dei rispettivi sistemi, senza logica propria. Due di essi contengono però dettagli che vale la pena mostrare.

Il client di Cube è il punto in cui il servizio firma il token JWT che accompagna ogni interrogazione. Il token porta l'identificativo del tenant fra le proprie dichiarazioni e una scadenza breve; che cosa Cube ne faccia una volta ricevuto, e come da quel valore discenda la segregazione richiesta da RQA-OB\_04, è descritto nella @sez:semantic[Sezione].

```go
// internal/clients/cube/cube.go

// firma un jwt hs256 con il tenant_id nei claim
func (c *Client) token(tenantID string) (string, error) {
	if tenantID == "" {
		return "", fmt.Errorf("tenant_id is required")
	}
	now := time.Now()
	claims := jwt.MapClaims{
		"tenant_id": tenantID,
		"iat":       now.Unix(),
		// scadenza, per evitare che il token duri per sempre
		"exp": now.Add(5 * time.Minute).Unix(),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256,
		claims).SignedString([]byte(c.secret))
}
```

Lo stesso client gestisce una particolarità del protocollo di Cube: quando un'interrogazione richiede un calcolo non ancora in cache, la risposta non è il risultato ma l'indicazione `Continue wait`, con cui Cube invita a ripresentare la richiesta. Il client la ripresenta a intervalli di un secondo, dentro un tempo massimo complessivo oltre il quale l'operazione fallisce invece di restare appesa.

Il client del modello linguistico costruisce la conversazione minima: un messaggio di sistema con le istruzioni e un messaggio utente con i dati. Non c'è uno storico da mantenere, perché ogni riepilogo è una chiamata indipendente. La temperatura, il parametro che governa la variabilità del testo generato, è impostata bassa: a parità di dati il testo deve restare il più possibile stabile e aderente ai valori forniti.

```go
// internal/clients/openaiclient/openaiclient.go

func (c *Client) Complete(ctx context.Context,
	systemPrompt, userMessage string) (string, error) {

	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	resp, err := c.api.Chat.Completions.New(ctx,
		openai.ChatCompletionNewParams{
			Model: openai.ChatModel(c.model),
			// bassa = output più stabile e fedele ai dati
			Temperature: openai.Float(0.2),
			Messages: []openai.ChatCompletionMessageParamUnion{
				openai.SystemMessage(systemPrompt),
				openai.UserMessage(userMessage),
			},
		})
	...
}
```

Gli altri due client sono minimi. Quello di MongoDB apre la connessione e la verifica subito con un ping, così un database irraggiungibile viene scoperto all'avvio del servizio e non alla prima richiesta. Quello di AWS costruisce la sessione per SQS, con una particolarità utile allo sviluppo: se la configurazione indica un endpoint esplicito, la sessione punta a quell'indirizzo con credenziali fittizie, ed è ciò che permette di usare ElasticMQ in locale; altrimenti vale la catena di credenziali standard di AWS, quella che verrebbe usata in produzione. Il codice del servizio è identico nei due casi, cambia una riga di configurazione.

=== Il punto di ingresso

Il file `main.go` è l'unico punto del programma che conosce tutte le parti. Il suo compito è costruirle nell'ordine giusto e collegarle: è qui che i tipi concreti vengono assegnati alle interfacce viste nella @sez:summary[Sezione].

```go
// cmd/context-service/main.go

func main() {
	cfg, err := config.Load()
	...
	// il context si chiude quando arriva ctrl+c o un
	// sigterm, così il consumer smette di leggere dalla
	// coda e il servizio si spegne in modo pulito
	ctx, stop := signal.NotifyContext(
		context.Background(),
		os.Interrupt, syscall.SIGTERM)
	defer stop()

	db, err := mongoclient.Connect(ctx, cfg.MongoURI)
	...
	cubeClient := cube.New(cfg.CubeAPIURL, cfg.CubeSecret)
	llm := openaiclient.New(cfg.OpenAIKey,
		cfg.OpenAIURL, cfg.OpenAIModel)

	summaries := store.New(db)
	tenants := tenant.New(db)
	kpiService := kpi.New(db, cubeClient)
	summaryService := summary.New(
		summaries, llm, kpiService, tenants)

	var wg sync.WaitGroup

	sess := awsclient.NewSession(
		cfg.AWSRegion, cfg.SQSEndpoint)

	producer := &sqsconsumer.SQSconsumer{}
	producer.SetSession(sess)
	producer.EnsureExec(cfg.SQSQueueURL, 10, 3,
		newProduceProcessor(summaryService), ctx, &wg)

	// coda separata per l'invalidazione: formato,
	// volumi e costi diversi dalla produzione
	invalidator := &sqsconsumer.SQSconsumer{}
	invalidator.SetSession(sess)
	invalidator.EnsureExec(cfg.SQSInvalidateQueueURL,
		10, 3, newInvalidateProcessor(summaries),
		ctx, &wg)

	// il servizio ha due ingressi: le code per i
	// comandi, l'http per le consultazioni
	startHTTP(ctx, cfg.HTTPAddr, summaries, &wg, stop)

	wg.Wait() // aspetta la fine di tutte le goroutine
}
```

Tre aspetti di questo file governano il comportamento dell'intero servizio.

Il primo è il contesto derivato dai segnali del sistema operativo. `signal.NotifyContext` produce un contesto che viene cancellato all'arrivo di una richiesta di arresto, e quel contesto viene passato a ogni ascoltatore: la cancellazione è il segnale unico con cui tutte le parti del servizio apprendono che è ora di fermarsi. È il meccanismo su cui si regge l'arresto controllato richiesto da RQA-OB\_05: i consumatori smettono di prelevare messaggi nuovi e completano quelli in corso, i messaggi non ancora presi in carico restano sulla coda e verranno elaborati alla ripartenza.

Il secondo è il `WaitGroup`, il contatore con cui il programma principale attende la terminazione di tutte le goroutine prima di uscire. Senza questa attesa, all'uscita del `main` le elaborazioni in corso verrebbero interrotte a metà, vanificando l'arresto controllato appena descritto.

Il terzo è il consumo delle code, affidato alla libreria interna dell'azienda, uno dei vincoli del progetto (RV-OB\_03). La libreria si fa carico dell'intero dialogo con SQS: la ricezione tramite _long polling_ a blocchi di dieci messaggi, l'elaborazione in parallelo da parte di tre _worker_, la cancellazione dalla coda dei soli messaggi elaborati con successo e l'arresto alla cancellazione del contesto. Al servizio resta da fornire una sola cosa: la funzione che elabora il singolo messaggio.

=== I consumatori delle code <sez:consumatori>

Le funzioni di elaborazione dei due comandi seguono lo stesso schema: sono costruite da una _factory_ che riceve il componente da usare e restituisce la funzione da consegnare alla libreria di consumo. La chiusura cattura il componente, e la funzione risultante ha la firma che la libreria si aspetta.

```go
// cmd/context-service/sqs_produce.go

// il tenant_id arriva negli attributi
type produceBody struct {
	GeocID  string `json:"geoc_id"`
	Trigger string `json:"trigger"`
}

func newProduceProcessor(
	svc *summary.Service) sqsconsumer.SQSmessageProcessor {

	return func(m *sqs.Message) error {
		attr, ok := m.MessageAttributes["tenant_id"]
		if !ok || attr.StringValue == nil {
			return fmt.Errorf("missing tenant_id attribute")
		}
		tenantID := *attr.StringValue

		if m.Body == nil {
			return fmt.Errorf("empty message body")
		}
		var body produceBody
		err := json.Unmarshal([]byte(*m.Body), &body)
		if err != nil {
			return fmt.Errorf("invalid body: %w", err)
		}
		if tenantID == "" || body.GeocID == "" ||
			body.Trigger == "" {
			return fmt.Errorf(
				"tenant_id, geoc_id and trigger are required")
		}

		aiSummary, err := svc.Produce(
			context.Background(),
			tenantID, body.GeocID, body.Trigger)
		if err != nil {
			// la libreria logga l'errore e il
			// messaggio verrà ritentato
			return err
		}
		...
		return nil
	}
}
```

La validazione precede ogni elaborazione, come previsto dalla @sez:scelte[Sezione]: un messaggio privo dei dati necessari viene rifiutato prima che il flusso parta, senza spendere interrogazioni né chiamate al modello. L'errore restituito dalla funzione è anche il canale con cui si governa il destino del messaggio: se la funzione ritorna un errore la libreria non cancella il messaggio dalla coda, che torna disponibile per un nuovo tentativo.

Il consumatore dell'invalidazione è ancora più breve, perché delega tutto alla cancellazione dell'archivio vista nella @sez:store[Sezione]. Va dichiarata un'approssimazione: il formato del messaggio qui letto è una versione essenziale definita per lo sviluppo, poiché l'iscrizione della coda al topic reale della piattaforma, con la struttura di incapsulamento che ne deriva, appartiene all'integrazione in produzione non realizzata (obiettivo D01).

```go
// cmd/context-service/sqs_invalidate.go

func newInvalidateProcessor(
	summaries *store.Store) sqsconsumer.SQSmessageProcessor {

	return func(m *sqs.Message) error {
		...
		deleted, err := summaries.Delete(
			context.Background(),
			*attr.StringValue, body.GeocID)
		if err != nil {
			// il messaggio tornerà in coda e ci riproveremo
			return err
		}

		fmt.Fprintf(os.Stderr,
			"invalidated %s: %d summaries deleted\n",
			body.GeocID, deleted)
		return nil
	}
}
```

=== La consultazione <sez:http>

L'ultimo ingresso del servizio è l'endpoint HTTP con cui la piattaforma consulta i riepiloghi. La sua caratteristica strutturale è ciò che non può fare: il gestore della richiesta riceve un'interfaccia che espone la sola lettura, quindi la consultazione non ha materialmente accesso né alla produzione né alla cancellazione. La garanzia discussa nella @sez:scelte[Sezione], per cui consultare non produce mai, non è una convenzione ma una proprietà del tipo.

```go
// cmd/context-service/http.go

// quello che serve alla consultazione:
// leggere l'archivio, niente altro
type summaryReader interface {
	Get(ctx context.Context, tenantID, geocID,
		trigger string) (string, bool, error)
}

// GET /summary?tenant_id=...&geoc_id=...&trigger=...
// la consultazione legge solo l'archivio
func handleSummary(
	summaries summaryReader) http.HandlerFunc {

	return func(w http.ResponseWriter, r *http.Request) {
		q := r.URL.Query()
		tenantID := q.Get("tenant_id")
		geocID := q.Get("geoc_id")
		trigger := q.Get("trigger")
		if tenantID == "" || geocID == "" || trigger == "" {
			writeJSON(w, http.StatusBadRequest, summaryOut{
				Status: "error",
				ErrorDetails: "tenant_id, geoc_id and " +
					"trigger are required",
			})
			return
		}

		aiSummary, found, err := summaries.Get(
			r.Context(), tenantID, geocID, trigger)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError,
				summaryOut{
					Status:       "error",
					ErrorDetails: err.Error(),
				})
			return
		}
		if !found {
			// non è un errore: è la risposta che permette
			// all'interfaccia di proporre la produzione
			writeJSON(w, http.StatusOK,
				summaryOut{Status: "not_found"})
			return
		}
		writeJSON(w, http.StatusOK,
			summaryOut{Status: "ok", AiSummary: aiSummary})
	}
}
```

La risposta per il riepilogo assente ha stato HTTP 200 e non 404, con l'esito espresso dal campo `status` del corpo: l'assenza è una risposta valida prevista dal caso d'uso UC1, non un errore di chi ha chiesto, ed è la risposta su cui la piattaforma costruisce la proposta di produzione all'operatore.

L'arresto del server segue lo stesso segnale del resto del servizio, con un dettaglio che merita attenzione: il contesto del servizio, una volta cancellato, non può essere usato per governare la chiusura, perché è già scaduto. Lo spegnimento usa quindi un contesto nuovo con un proprio limite di tempo, entro il quale le richieste in corso vengono completate.

```go
// cmd/context-service/http.go

wg.Add(1)
go func() {
	defer wg.Done()
	<-ctx.Done() // aspetta ctrl+c o sigterm

	// context nuovo: quello del servizio è già
	// cancellato, e a Shutdown serve tempo per
	// finire le richieste in corso
	shutdownCtx, cancel := context.WithTimeout(
		context.Background(), 10*time.Second)
	defer cancel()
	server.Shutdown(shutdownCtx)
}()
```

Con questo l'esposizione dei componenti è completa: la produzione, l'archivio, le impostazioni, i client, i tre ingressi e il punto che li collega. Il modo in cui questo insieme è stato verificato, sia nelle parti sia nel flusso completo, è l'oggetto del @cap:verifica[Capitolo].
