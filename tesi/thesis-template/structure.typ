/* Questo file serve per:
- Gestire i capitoli
- Gestire lo stile e la numerazione del conteggio delle pagine
*/

// Frontmatter
#include "preface/firstpage.typ"
#include "preface/copyright.typ"

#set page(numbering: "i")
#include "preface/dedication.typ"
#include "preface/acknowledgements.typ"
#include "preface/summary.typ"
#include "preface/table-of-contents.typ"

// Mainmatter
#counter(page).update(1)
#set page(numbering: "1.")
#include "chapters/1_introduction.typ"
#include "chapters/2_technologies.typ"
#include "chapters/3_requirements.typ"
#include "chapters/4_design.typ"
#include "chapters/5_validation.typ"
#include "chapters/6_conclusion.typ"

// Backmatter
#include "appendix/glossary/glossary.typ"
#include "appendix/bibliography/bibliography.typ"
