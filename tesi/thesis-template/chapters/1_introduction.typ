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

Il servizio è il solo oggetto dello stage. L'interfaccia con cui l'operatore visualizza il riepilogo e ne richiede la produzione appartiene alla piattaforma ed è competenza del team aziendale: nel documento viene descritta soltanto per dare senso al comportamento del servizio, che è stato progettato e realizzato per sostenerla.

Lo stage si è svolto in modalità full-time per un totale di 320 ore, sotto la supervisione del tutor aziendale Pietro De Caro. Gli obiettivi erano fissati dal piano di lavoro concordato con l'azienda, che mi ha lasciato però ampia autonomia sul _come_ raggiungerli: per ciascun obiettivo ho valutato approcci alternativi, sviluppato prototipi per verificarne la fattibilità e consolidato le scelte attraverso frequenti momenti di confronto con il tutor.

La forma che il servizio ha infine assunto non era stabilita in partenza: è il risultato di scelte maturate lungo tutto il periodo, che la sezione seguente ripercorre insieme ai problemi da cui sono nate.

=== Principali problematiche e relative soluzioni

Le principali problematiche riscontrate durante la realizzazione del progetto riguardano l'affidabilità dei contenuti generati dall'LLM e l'interfacciamento con i dati aziendali. Di seguito vengono analizzati i problemi specifici e le relative soluzioni adottate.

*1. Recupero deterministico dei dati per l'LLM*

_Descrizione:_ gli LLM eccellono nella produzione di testo fluente, ma se incaricati anche del recupero o del calcolo dei dati tendono a produrre _allucinazioni_, ovvero affermazioni plausibili ma non supportate dai dati reali. Gli approcci più diffusi per interrogare dati aziendali tramite LLM, ovvero il RAG e le tecniche Text-to-SQL, si sono rivelati dallo studio preliminare inadatti ai dati strutturati: in un contesto in cui il riepilogo supporta decisioni operative, un valore inventato non è accettabile.

_Soluzione:_ è stato introdotto un _semantic layer_ (Cube), uno strato intermedio che centralizza la definizione delle metriche e fornisce KPI "certificati", recuperati in modo completamente deterministico. All'LLM viene affidata soltanto l'esposizione in linguaggio naturale di valori già calcolati, con istruzioni che ne vincolano il comportamento ai soli dati forniti.

*2. Interfacciamento tra il semantic layer e il database aziendale*

_Descrizione:_ la piattaforma conserva i dati su MongoDB, un database NoSQL, mentre Cube opera su sorgenti relazionali. L'azienda disponeva di una soluzione temporanea, applicata a un solo cliente: il travaso dei dati in un campo `jsonb` su PostgreSQL, poi "srotolato" in una vista materializzata. Nel tentativo di rendere l'architettura più generale ho sperimentato l'interrogazione diretta del campo `jsonb` grezzo da parte di Cube, ottenendo però tempi di risposta proibitivi e configurazioni SQL molto difficili da mantenere; ho poi sperimentato con esito positivo l'esportazione dei dati in formato Parquet, che però per reggersi nel tempo avrebbe richiesto un lavoro di automazione a carico dell'azienda. Questa problematica ha assorbito una parte significativa del tempo di stage.

_Soluzione:_ in accordo con il tutor aziendale, l'ottimizzazione dell'interfacciamento è stata messa in pausa per non bloccare l'avanzamento del progetto, trattandosi di una questione prettamente infrastrutturale. Lo sviluppo è proseguito sull'ambiente PostgreSQL già pronto e configurato, mantenendo l'architettura aperta a una futura generalizzazione.

*3. Gestione della multitenancy*

_Descrizione:_ i database dei vari clienti hanno schemi per lo più simili, ma presentano campi personalizzati; occorre inoltre garantire che ogni cliente possa accedere esclusivamente ai propri dati.

_Soluzione:_ per i data model è stata utilizzata la direttiva `extends` di Cube, che permette di condividere le definizioni comuni estendendole in modo granulare per ciascun cliente; la segregazione dei dati si fonda invece sul fatto che a ciascun cliente corrispondono un database, un modello compilato e una cache propri, selezionati a partire dall'identificativo che il servizio presenta in un token JWT firmato. Anche le interrogazioni per il recupero dei KPI sono configurate per singolo tenant su MongoDB, senza interventi sul codice del servizio.

*4. Definizione del perimetro dei KPI*

_Descrizione:_ una volta risolta la questione del recupero, restava da definire quali KPI fossero utili al riepilogo e in quale forma esporli: se sviluppare vere e proprie funzioni di analisi del dato (ad esempio il calcolo di trend), o se arricchire i KPI con dati qualitativi recuperati direttamente dal database.

_Soluzione:_ confrontandomi con il tutor aziendale ho scelto di mantenere il sistema semplice: KPI aggregati "grezzi", affidando all'LLM la loro descrizione in linguaggio naturale guidata da istruzioni specifiche per ciascun blocco di dati. Il riepilogo accosta così due tipi di contenuto: i KPI aggregati e alcune informazioni puntuali sulle singole occorrenze, come la descrizione dei ticket aperti e dell'intervento svolto su quelli chiusi di recente. Anche queste ultime passano però dal semantic layer: l'ipotesi di recuperarle direttamente dal database, scavalcandolo, è stata scartata per non aprire una seconda via di accesso ai dati con garanzie diverse dalla prima.

*5. Conservazione e aggiornamento del riepilogo*

_Descrizione:_ produrre un riepilogo richiede una chiamata al modello linguistico, quindi comporta un costo e alcuni secondi di attesa. Da qui la domanda su cosa farne una volta prodotto. Rigenerarlo a ogni apertura di scheda garantisce che sia sempre aggiornato, ma fa pagare quel costo anche all'operatore che apre la scheda per altri motivi. Conservarlo rende invece immediate le consultazioni successive, esponendo però al rischio opposto: quando i dati dell'entità cambiano, per esempio all'apertura di un nuovo ticket o al completamento di un'ispezione, il testo conservato smette di corrispondere alla realtà.

_Soluzione:_ il riepilogo viene conservato, e utilizzo due meccanismi per evitare ri-generazioni inutili o versioni non valide del riepilogo.

Il primo separa la consultazione dalla produzione. La consultazione si limita a leggere: restituisce il riepilogo se esiste, altrimenti risponde che non è disponibile. Ricevendo questa seconda risposta la piattaforma può proporre all'operatore di richiedere la produzione, che resta l'unico modo per avviarla.

Il secondo tiene il riepilogo allineato ai dati. Ho valutato due strategie prima di scegliere: confrontare la data del riepilogo con quella dell'ultima modifica dell'entità, oppure assegnare al riepilogo una scadenza a tempo. Entrambe richiedevano un controllo periodico e lasciavano una finestra di tempo in cui il testo mostrato poteva essere già superato. La soluzione adottata parte invece da un meccanismo che la piattaforma aziendale possiede già, ovvero l'evento che segnala la modifica (update) di un'entità aziendale (ticket, ecc...). Quando il servizio intercetta una modifica, elimina subito dal database il riepilogo dell'entità di riferimento, così alla richiesta successiva sarà necessario generare un nuovo riepilogo basato su dati aggiornati.

=== Pianificazione

Il piano di lavoro concordato con l'azienda prevedeva otto settimane da quaranta ore ciascuna, per un totale di 320, così articolate:

1. introduzione al prodotto, alle tecnologie e ai processi aziendali; definizione degli obiettivi e avvio dell'analisi dei requisiti;
2. completamento dell'analisi dei requisiti; studio e confronto delle tecnologie e degli approcci RAG disponibili;
3. progettazione dell'applicativo e avvio della documentazione tecnica;
4. e 5. sviluppo dell'applicativo, a partire dai moduli principali;
6. completamento dello sviluppo funzionale ed esecuzione dei test unitari e di integrazione;
7. verifica dell'applicativo su dati reali e revisione della documentazione;
8. collaudo finale e rifinitura della documentazione.

La ripartizione delle ore prevista era la seguente:

#figure(
  caption: [Ripartizione delle ore prevista dal piano di lavoro.],
  table(
    columns: (auto, 1fr),
    align: (center + horizon, left + horizon),
    fill: (x, y) => if y == 0 { luma(230) },
    table.header([*Ore*], [*Attività*]),
    [8], [Introduzione alla piattaforma proprietaria],
    [8], [Introduzione agli strumenti utilizzati in azienda],
    [32], [Analisi dei requisiti e stesura della relativa documentazione],
    [32], [Studio e confronto delle tecnologie disponibili],
    [40], [Progettazione dell'applicativo],
    [120], [Sviluppo dell'applicativo],
    [40], [Collaudo e test su dati reali],
    [40], [Scrittura della documentazione],
    [*320*], [*Totale*],
  )
)<tab:ripartizione-ore>

=== Svolgimento effettivo

Il lavoro ha seguito lo sviluppo previsto dal piano. Le differenze, concordate di volta in volta con il tutor aziendale, hanno riguardato soprattutto la distribuzione temporale di alcune fasi e l'esito dello studio preliminare.

La fase di studio e confronto delle tecnologie, alla quale il piano destinava trentadue ore, ha prodotto il risultato più rilevante per l'intero progetto. Lo scopo dello stage era formulato attorno all'approccio RAG, ma l'analisi ne ha evidenziato l'inadeguatezza rispetto ai dati strutturati, ai quali insieme al tutor aziendale è stata data la priorità. La distinzione tra dati strutturati e non strutturati era già presente negli obiettivi, i primi in O01 e O02, i secondi in O03 e O04. È divenuta così anche una distinzione di approccio: il RAG è rimasto la strada prevista per i soli documenti non strutturati.

A questa fase si è affiancata una questione che la pianificazione non contemplava: l'interfacciamento tra il semantic layer e il database aziendale. Trattandosi di un database non relazionale, il problema è di natura infrastrutturale e ha assorbito una porzione consistente del tempo.

L'analisi dei requisiti, che il piano collocava nelle prime due settimane, si è distribuita lungo l'intero periodo. L'autonomia lasciatami sul modo di realizzare gli obiettivi ha fatto sì che diversi requisiti si precisassero mentre il lavoro procedeva, restando a lungo impliciti nei confronti con il tutor; la loro formalizzazione, avvenuta nella parte conclusiva dello stage, ha reso evidenti alcuni punti su cui il servizio non era ancora allineato a quanto concordato, in particolare la lingua del testo e il fuso orario con cui vengono calcolate le date, il cui adeguamento è rientrato nell'ultima fase dello sviluppo.

Il collaudo previsto dalle settimane conclusive si è svolto nell'ambiente di sviluppo locale, sui dati reali dell'ambiente di _staging_ aziendale, e si è accompagnato alla scrittura dei test automatici; l'integrazione nell'infrastruttura di produzione, corrispondente all'obiettivo desiderabile D01, non è stata invece realizzata.

=== Obiettivi

Il piano di lavoro concordato con l'azienda definisce i seguenti obiettivi obbligatori:

- *O01* — Ricezione di eventi asincroni dalle altre componenti della piattaforma, con caricamento delle configurazioni del cliente e delle entità interessate;
- *O02* — Valutazione di KPI specifici per entità e cliente, e interfacciamento con l'IA generativa per la produzione della sintesi testuale;
- *O03* — Indicizzazione delle entità per il recupero di documenti non strutturati (approccio RAG);
- *O04* — Ricezione di richieste utente in modalità agente, con recupero documentale e risposta.

A questi si aggiunge l'obiettivo desiderabile *D01*, l'integrazione nell'architettura e nel ciclo di rilascio della piattaforma.

Il lavoro si è concentrato sul flusso relativo ai dati strutturati (O01 e O02), portandolo a un livello di completezza e solidità vicino all'integrazione in produzione. Nella seconda metà dello stage, in accordo con il tutor aziendale, si è scelto di consolidare tale flusso anziché avviare gli obiettivi O03 e O04: l'estensione ai documenti non strutturati avrebbe comportato lo studio e la realizzazione di un'infrastruttura di indicizzazione e recupero autonoma, con il rischio concreto di lasciare incompiuti entrambi i fronti. Gli obiettivi O03 e O04 sono stati pertanto analizzati sul piano teorico ma non realizzati, e sono ripresi tra gli sviluppi futuri nel @cap:conclusioni[Capitolo].

Anche l'obiettivo desiderabile D01 non è stato raggiunto: nella settimana conclusiva l'azienda ha preferito destinare il tempo residuo a un affiancamento formativo con uno sviluppatore del team, ritenendolo più utile rispetto a un'attività il cui coordinamento con il ciclo di rilascio interno avrebbe ecceduto la durata dello stage.

== Il prodotto finale

Il servizio realizzato copre l'intero flusso previsto per i dati strutturati e offre tre operazioni distinte. La *produzione* di un riepilogo, richiesta tramite coda, recupera le interrogazioni configurate per il tenant, ne estrae i KPI tramite il semantic layer, genera il testo con l'LLM e lo rende persistente. La *consultazione*, servita in modo sincrono, restituisce il riepilogo di un'entità oppure segnala che non è disponibile, senza produrne di nuovi. È questa seconda risposta a permettere alla piattaforma di proporre all'operatore la produzione. L'*invalidazione*, attivata dall'evento con cui la piattaforma segnala la modifica di un'entità: elimina i riepiloghi che non ne rispecchiano più lo stato, così che la richiesta successiva ne produca di aggiornati.

Il servizio è configurabile per singolo cliente senza interventi sul codice, sia nelle interrogazioni che compongono il riepilogo, sia nella lingua e nel fuso orario con cui viene prodotto. È inoltre corredato di una suite di test automatici e di un ambiente di sviluppo locale che ne riproduce l'infrastruttura.

Per un'analisi approfondita del risultato ottenuto si rimanda al @cap:conclusioni[Capitolo].

== Organizzazione del testo

La tesi è divisa in sei capitoli, che ripercorrono il lavoro nell'ordine in cui è stato svolto. Il primo, che si chiude con questa sezione, presenta l'azienda ospitante e il progetto di stage. Il @cap:tecnologie[Capitolo] descrive gli strumenti e le tecnologie utilizzate. Il @cap:analisi-requisiti[Capitolo] delimita il sistema e ne analizza i requisiti. Il @cap:progettazione[Capitolo] illustra lo studio degli approcci possibili, la progettazione e lo sviluppo del servizio. Il @cap:verifica[Capitolo] riporta le attività di verifica e validazione. Il @cap:conclusioni[Capitolo] trae un bilancio del lavoro svolto e delle prospettive future.

Riguardo la stesura del testo sono state adottate le seguenti convenzioni tipografiche:

- gli acronimi, le abbreviazioni e i termini di uso non comune vengono definiti nel #link(<glossary>)[glossario], situato alla fine del documento, e alla loro prima occorrenza sono indicati con la nomenclatura #glossary-style[termine]\;
- i termini in lingua straniera o facenti parte del gergo tecnico sono evidenziati con il carattere _corsivo_;
- i nomi di funzioni, variabili e altri elementi di codice sono scritti con carattere `monospaziato`;
- le citazioni a risorse presenti nella #link(<bibliography>)[bibliografia] sono affiancate dal rispettivo numero identificativo, es. $[1]$.
