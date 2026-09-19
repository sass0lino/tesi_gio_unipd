// numerazione a due cifre (01, 02, ...)
#let pad(n) = if n < 10 { "0" + str(n) } else { str(n) }

// Requisiti funzionali
#let getFR(getLen: bool) = {
  let FR = ()
  let m = "RF-OB_"
  let d = "RF-DE_"
  let o = "RF-OP_"
  let mandatory = 0
  let desirable = 0
  let optional = 0

  mandatory += 1
  FR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [Il sistema deve produrre un riepilogo testuale in linguaggio naturale dello stato di un'entità a partire dai suoi dati.],
    [Piano di lavoro (O02)],
  ))

  mandatory += 1
  FR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [Il sistema deve comporre il riepilogo con i KPI aggregati dell'entità e con informazioni qualitative puntuali che la riguardano.],
    [Riunione con il tutor aziendale],
  ))

  mandatory += 1
  FR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [Il sistema deve differenziare il contenuto del riepilogo in base al tipo di entità e all'evento che lo richiede.],
    [Piano di lavoro (O02)],
  ))

  mandatory += 1
  FR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [Il sistema deve fornire il riepilogo di un'entità quando richiesto, oppure indicare che non è disponibile.],
    [Riunione con il tutor aziendale],
  ))

  mandatory += 1
  FR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [Il sistema deve consentire di richiedere la produzione di un riepilogo non ancora disponibile.],
    [Riunione con il tutor aziendale],
  ))

  mandatory += 1
  FR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [Il sistema deve mantenere disponibile il riepilogo prodotto per le richieste successive, senza riprodurlo a ogni consultazione.],
    [Riunione con il tutor aziendale],
  ))

  mandatory += 1
  FR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [Il sistema deve impedire che venga fornito un riepilogo non più corrispondente allo stato dell'entità.],
    [Riunione con il tutor aziendale],
  ))

  mandatory += 1
  FR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [Il sistema deve poter essere attivato dalle altre componenti della piattaforma, e non soltanto da un'azione dell'operatore.],
    [Piano di lavoro (O01)],
  ))

  desirable += 1
  FR.push((
    [#(d + pad(desirable))#label("req:" + d + pad(desirable))],
    [Il sistema deve indicizzare le entità per consentire il recupero di informazioni da documenti non strutturati.],
    [Piano di lavoro (O03)],
  ))

  optional += 1
  FR.push((
    [#(o + pad(optional))#label("req:" + o + pad(optional))],
    [Il sistema deve rispondere a richieste dell'utente in modalità agente.],
    [Piano di lavoro (O04)],
  ))

  if getLen == true {
    return (mandatory, desirable, optional)
  }
  return FR
}

// Requisiti qualitativi
#let getQR(getLen: bool) = {
  let QR = ()
  let m = "RQA-OB_"
  let d = "RQA-DE_"
  let o = "RQA-OP_"
  let mandatory = 0
  let desirable = 0
  let optional = 0

  mandatory += 1
  QR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [I valori esposti nel riepilogo devono provenire esclusivamente dai dati recuperati, senza deduzioni né informazioni non presenti nei dati.],
    [Piano di lavoro (O02)],
  ))

  mandatory += 1
  QR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [Il riepilogo deve essere prodotto nella lingua predefinita del tenant.],
    [Riunione con il tutor aziendale],
  ))

  mandatory += 1
  QR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [Le date riportate nel riepilogo devono corrispondere a quelle che l'operatore vede sulla piattaforma.],
    [Analisi interna],
  ))

  mandatory += 1
  QR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [Ogni tenant deve poter accedere esclusivamente ai propri dati.],
    [Piano di lavoro (O01)],
  ))

  mandatory += 1
  QR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [Nessuna richiesta accettata deve andare perduta, neppure in caso di arresto del servizio, che deve portare a termine le elaborazioni già avviate.],
    [Analisi interna],
  ))

  mandatory += 1
  QR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [Richieste non valide o errori temporanei delle sorgenti dati non devono compromettere il funzionamento del servizio.],
    [Analisi interna],
  ))

  mandatory += 1
  QR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [L'elaborazione ripetuta della stessa richiesta non deve produrre effetti indesiderati.],
    [Analisi interna],
  ))

  desirable += 1
  QR.push((
    [#(d + pad(desirable))#label("req:" + d + pad(desirable))],
    [I dati da comporre nel riepilogo e le relative istruzioni di esposizione devono essere configurabili per singolo tenant senza modifiche al codice.],
    [Analisi interna],
  ))

  desirable += 1
  QR.push((
    [#(d + pad(desirable))#label("req:" + d + pad(desirable))],
    [Il riepilogo deve potersi mantenere entro una lunghezza massima stabilita, scegliendo quali contenuti riportare in ordine di importanza quando i dati eccedono lo spazio disponibile.],
    [Riunione con il tutor aziendale],
  ))

  if getLen == true {
    return (mandatory, desirable, optional)
  }
  return QR
}

// Requisiti di vincolo
#let getCR(getLen: bool) = {
  let CR = ()
  let m = "RV-OB_"
  let d = "RV-DE_"
  let o = "RV-OP_"
  let mandatory = 0
  let desirable = 0
  let optional = 0

  mandatory += 1
  CR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [Il servizio deve essere sviluppato nel linguaggio Go.],
    [Vincolo aziendale],
  ))

  mandatory += 1
  CR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [Il servizio deve attingere alla sorgente dati esistente su MongoDB, organizzata con un database per ciascun tenant.],
    [Vincolo aziendale],
  ))

  mandatory += 1
  CR.push((
    [#(m + pad(mandatory))#label("req:" + m + pad(mandatory))],
    [La comunicazione asincrona con la piattaforma deve avvenire tramite la coda Amazon SQS, impiegando la libreria di consumo sviluppata internamente dall'azienda.],
    [Vincolo aziendale],
  ))

  desirable += 1
  CR.push((
    [#(d + pad(desirable))#label("req:" + d + pad(desirable))],
    [Il servizio deve integrarsi nell'architettura e nel ciclo di rilascio della piattaforma.],
    [Piano di lavoro (D01)],
  ))

  if getLen == true {
    return (mandatory, desirable, optional)
  }
  return CR
}
