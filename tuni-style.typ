// Sources:
//
// * https://markkinointipankki.tuni.fi/ohjeistukset/graafinen-ohjeistus/
// * https://markkinointipankki.tuni.fi/wp-content/uploads/2024/05/TUNI_Graafinenohjeistus_052024_2.pdf

/*
# Värit

<https://markkinointipankki.tuni.fi/ohjeistukset/varit/>

Digitaalisissa käyttöympäristöissä käytetään aina RGB-määrityksiä. Painotuotteissa pyritään käyttämään Pantone-määrityksiä aina kun se on mahdollista.

Violetti on hallitseva väri, jota kevennetään valkoisella. Violetista voidaan
käyttää myös eri vaaleusasteita. Toissijaista väripalettia käytetään niukasti.

Digitaalisissa käyttöympäristöissä käytetään aina RGB-määrityksiä. Painetussa
mediassa käytetään CMYK tai Pantone -värimäärityksiä.
*/

/* Ensisijaiset värit */
#let tuni-purple = rgb(78, 0, 142) // #4e008e
#let tuni-white = rgb(255, 255, 255)
#let tuni-black = rgb(0, 0, 0)

/* Toissijaiset värit */
#let tuni-blue = rgb(130, 200, 240) // #82c8f0
#let tuni-pink = rgb(245, 165, 200) // #f5a5c8
#let tuni-yellow = rgb(255, 220, 165) // #ffdca5
#let tuni-lpurple = rgb(195, 185, 215)
#let tuni-fuchsia = rgb(240, 115, 135) // #f07387
#let tuni-green = rgb(125, 205, 190)
#let tuni-grey = rgb(200, 200, 200)

/*
# Saavutettavat värit

- Valkoinen tausta: violetti, musta ja fuchsia
- Violetti tausta: tuniBlue, tuniPink, tuniYellow, tuniGreen, tuniGrey, tuniWhite
- Toissijainen väripaletti taustana: violetti ja musta
- Valkoinen teksti on saavutettava ainoastaan tuniFuchsian päällä
*/

/*
# Typografia

## Digitaaliset ympäristöt

Open Sans -fonttia käytetään kaikissa digitaalisissa järjestelmissä silloin kun
se on mahdollista. Open Sans on Googlen ilmainen kirjaisinperhe ja sen voi
ladata osoitteesta: fonts.google.com.

Kirjaisinperheen kaikki leikkaukset ovat käytettävissä.

Office-ympäristö

Office-ohjelmissa (Word, PowerPoint, Excell) Neue Haas Unica -fontin tilalla on
Arial ja sen kaikki leikkaukset. Arial voi soveltua myös digitaalisten
järjestelmien käyttöön.
*/

#let tuni-font = "Open Sans"
#let tuni-font-ms = "Arial"

/*
Kirjasinkoko

- Minimi 11 on saavutettava.
  - Poikkeus: kaavioiden arvopisteiden otsikot voivat olla 9.
*/

#let tuni-font-size = 12pt // 16 px
#let tuni-font-size-graph-min = 9pt
#let tuni-font-size-code = 10pt // 13px
#let tuni-codeblock-inset = 0.5em
