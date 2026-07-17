> [!NOTE]
> 🇦🇺 English localization is currently only supported via [constants.typ](https://github.com/tlazzarin/thesis-template/blob/main/config/constants.typ) as the documentation is written in Italian. Please use machine translation or read the code 🙂.
# 🇮🇹 Introduzione
Questa repository contiene un template Typst per la tesi di laurea all'Università di Padova. Pur avendo un forte bias per il corso di Scienze Informatiche (report di un progetto di stage) rimane adattabile per gli altri CdL.\
Il template è basato su [questo template](https://github.com/eliapasquali/typst-thesis-template) e ampiamente modificato per scrivere la
[mia tesi](https://hdl.handle.net/20.500.12608/89992).

> [!TIP]
> Se preferisci usare un servizio simile a Overleaf scarica lo zip di questa repository e caricarlo su [Typst Web](https://typst.app/signin/).

Per compilare la tesi secondo gli standard universitari:
```sh
typst c thesis.typ --pdf-standard a-3b
```
Altrimenti puoi abilitare la watch mode che ricompila il PDF ad ogni modifica:
```sh
typst w thesis.typ
```
Se cerchi un lettore PDF che supporti l'hot reloading ti consiglio [Zathura](https://pwmt.org/projects/zathura/). 
## Features
- ✅ Bibliografia
- ✅ Continuous integration e pubblicazione su GitHub Pages (vedi [esempi.typ](https://github.com/tlazzarin/thesis-template/blob/main/docs/esempi.typ))
- ✅ Glossario
- ✅ Gestione avanzata dei requisiti
- ✅ Supporto PDF/A
- ⏳ Appendici (implementabile)

# Guida
La primissima cosa che ti consiglio di fare è modificare il file [variables.typ](https://github.com/tlazzarin/thesis-template/blob/main/config/variables.typ) inserendo le tue informazioni.\
Nel file [esempi.typ](https://github.com/tlazzarin/thesis-template/blob/main/docs/esempi.typ), incluso di default nel template, ci sono degli esempi di come fare alcune cose.


# Riferimenti
- Template su cui mi sono basato: https://github.com/eliapasquali/typst-thesis-template
- Typst docs: https://typst.app/docs/
- Glossarium: https://typst.app/universe/package/glossarium
- Codly: https://typst.app/universe/package/codly
- Bibliography: https://typst.app/docs/reference/model/bibliography
