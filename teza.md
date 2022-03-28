(actualitatea și importanța temei;
scopul și obiectivele;
suportul metodologic;
baza experimentală;
noutatea științifică;
semnificația teoretică;
valoarea aplicativă;
sumarul)


**Actualitatea și importanța temei.**

Dezvoltarea jocurilor video este un domeniu important în ziua de azi.
Dezvoltarea lor practică și eficientă necesită mai multe instrumente, ca o modalitate de rendering a mesh-elor sau a imaginilor pe ecran, o modalitate de user input, scripting etc.

Motorul de joc Unity a făcut limbajul C# popular pentru scripting în jocuri video.
Așadar, ușurarea programării în C# poate aduce la un proces de dezvoltare mai plăcut și mai productiv pentru programatori de jocuri în Unity, sau în alte medii unde se folosește acest limbaj de programare.

C# nu este un limbaj perfect.
Este dificil să se scrie codul declarativ fără să se utilizeze reflexie runtime care este lentă și alocă multă memorie excesivă.
Uneori necesită mai mult cod boilerplate sau cod mai puțin eficient sau care să consume mai multă memorie chiar pentru a atinge lucruri simple.

În mai multe cazuri, însă, acest cod poate fi generat pe baza fișierilor de sursă inițiale.
Codul care să genereze acest boilerplate dorit poate fi mai ușor de înțeles decât codul băzat pe reflexie runtime, și trebuie să fie scris doar o singură dată, eliminând codul boilerplate dat pentru întotdeauna.
Codul generat va fi echivalent cu acel cod boilerplate, însă nu trebuie fi scris de mână de fiecare dată, și nu trebuie să fie sincronizat cu codul inițial — acestea se vor face automat de către generatorul de cod.


**Scopul și obiectivele.**

În această lucrare autorul proiectează, explică și elaborează un astfel generator de cod.
Generatorul final poate fi utilizat ușor în mai multe proiecte, poate fi extins dinamic utilizând plugin-uri care să conțină logica specifică de analiză a codului sursă și de generare a codului nou.
Se demonstrează niște exemple de utilizare a generatorului de cod.
Se arată încă cum generatorul de cod poate fi integrat într-o aplicație de linie de comandă centralizată care să se utilizeze într-un pipeline CI/CD.


**Suportul metodologic.**

Generatorul de cod este un instrument realizat în limbajul C#, pe baza platformei .NET 6 și a lui Roslyn care este un set de librării și instrumente pentru analiza codului sursă C#.
Generatorul de cod a fost testat și utilizat în practică în Unity.
Instrumentul a fost elaborat după necesitate în dezvoltare și reiese întreg din experimentare și experiența autorului.


**Noutatea științifică/originalitatea.**

În general, generatorul de cod a fost proiectat și elaborat după necesitățile autorului.
Autorul utilizează acest instrument în proiectele proprii și planifică să-l perfecționeze și să-l facă mai modular și mai ușor de utilizat.


**Valoarea aplicativă.**

Produsul obținut poate fi utilizat pentru generarea codului în orice proiect ce urmează,
cu posibilitatea de a crea plugin-uri personalizate, destinate unui proiect concret,
pentru a ușura realizarea scopurilor specifice acestuia.


**Sumarul tezei.**

În această lucrare se argumentează și se elaborează un generator de cod C# flexibil și extensibil care poate fi utilizat pentru a ușura și a face mai plăcută programarea în C#, și pentru a spori eficiența programatorului în implementarea unelor soluții.



## I. Sumarul Generării Codului în C#

 <!-- (analiza literaturii la tema tezei) -->

<!-- 
• Esența problemei ce ține de tema tezei, istoriografia problemei.
• Abordarea și studiul problemei în literatura de specialitate (review-ul surselor
bibliografice și al materialelor folosite în lucrare, oferta pieței).
• Inventarierea și/sau examinarea direcțiilor principale de soluționare a problemei
stabilite, justificarea alegerii.
• Selectarea metodelor și procedeelor de soluționare a problemei (proiectare,
programare individuală, efectuarea experimentelor, utilizarea metodelor statistice,
comparative etc.).
• Concluzii, propuneri, viziuni justificate, eventual originale. -->

<!--
- Mention the previous project where the idea was born
- Mention that these things are really a limitation of the language, D allows doing most of this at compile time.
- Make the obvious statement that the use of Roslyn is preferred, because it's by far the most capable API.
- Benefits of code generation (eliminate boilerplate, replace reflection, IL code generation, generate nice wrappers, initialization code, use declarative code without runtime penalties)
- Some examples: flags, bitfields, data objects. -->


### Capacitățile și deficiențele lui C#

<!-- https://docs.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/ -->
C# este un limbaj de programare modern, posedă caracteristici utile și practice, printre care:
- Tipizarea statică;
- Un runtime inteligent;
- Un colector de gunoi integrat, util pentru programarea de uz general;
- O librărie de clase extinsă și testată în timp;
- etc.

Cu toate că C# este "mediul" acestei lucrări, nu se va descrie în întregime,
deoarece importanta este esența problemei care constă în faptul că, cu toate că limbajul acesta este destul de capabil, este și destul de limitat.

Cel mai important moment pentru autor este posibilitatea executării sau generării codului,
posibilitatea performării reflexiei asupra tipurilor în timpul compilării.
Să se menționeze, că C# deja permite reflexia asupra tipurilor și generarea codului, însă abordarea lui este că deleghează totul la timpul rulării, deci reflexia runtime și emisia codurilor IL, respectiv.
Aceste tehnici, însă, sunt dificile de utilizat și codul care le folosește este predispus la erori.
Însă, dacă s-ar putea să se genereze fișieri în timpul compilării, sau înainte de compilare, și ca aceste fișieri să conțină codul regular, sigur de tip, aceste erori ar fi prinși în timpul compilării.
Adică, codul pur și simplu nu s-ar compila, cu indicarea concretă a erorii, în loc de a da crash în timpul rulării.

Analiza tipurilor în timpul compilării (sau înainte de compilare, într-un pas aparte), în loc de aceasta în timpul rulării, permite și analiza mai profundă a tipurilor, folosirea structurilor de date mai avansate, ca grafuri, lucrul cu informații mai bogate despre simboluri în codul sursă, etc.
Dacă această analiză nu este delegată la timpul rulării ci este executată în prealabil, salvează timpul de execuție și memoria RAM valoroasă în timpul rulării, care sunt în special importante în jocuri video.

Generarea codului poate fi folosită și pentru a elimina codul boilerplate, sau pentru a genera wrapper-uri sau funcții ajutătoare.

### Exemplu: implementarea interfețelor prin compoziție

Urmează o instanță posibilă de apăriția codului boilerplate, unde dorim să implementăm o interfață prin compoziție.
Deci fie o astfel de interfață:

```csharp
public interface IExample
{
    void A();
    void B();
    void C();
    void D();
    // ...
}
```

Acum fie că dorim să creăm o structură, unde să avem o implementare a acestei interfețe.
Deoarece trebuie să fie o structură, dorim numaidecât să folosim compoziția, și nu putem folosi moștenirea.
Încă dorim ca această structură să implementeze și ea interfața aceasta, ca să poată fi folosită în generics.

În alte cuvinte:

```csharp
public struct Composition : IExample
{
    private IExample _impl;
}
```
<!-- https://softwareengineering.stackexchange.com/questions/288066/reducing-boilerplate-in-class-that-implements-interfaces-through-composition -->

Este clar că acum trebuie să implementăm această interfață.
Deci, unica soluție care C# ne propune este următoarea:

```csharp
public struct Composition : IExample
{
    private IExample _impl;

    void A() { _impl.A(); }
    void B() { _impl.B(); }
    void C() { _impl.C(); }
    void D() { _impl.D(); }
    // ...
}
```

Este clar, că așa abordare în primul rând este o repetare proastă a codului, aducerea zgomotului fără sens în cod.
Însă cel mai rău aspect este că, acum, dacă s-ar schimba interfața `IExample`, s-ar trebui să fie schimbat și acest tip. 
Da, nu e nimic dacă este doar un singur astfel de tip, dar aceste lucruri se acumulează și pot face codul mai anevoios de modificat, sporesc fricția între limbajul de programare și programatorul.

> O altă soluție aici ar putea fi supraîncărcarea castului implicit în acest tip integrat,
> însă supraîncarcarea casturilor implicite în interfețe nu este permisă în C#.

Cu generarea codului, ar putea fi posibilă o astfel de soluție, simplă, clară, ușoară de utilizat, și rezistentă la schimbări ale interfeței:

```csharp
public partial struct Composition : IExample
{
    [ForwardMethodCalls]
    private IExample _impl;
}
```

Iar codul generat deja să conțină aceste implementări, într-un fișier aparte:

```csharp
public partial struct Composition
{
    void A() { _impl.A(); }
    void B() { _impl.B(); }
    void C() { _impl.C(); }
    void D() { _impl.D(); }
    // ...
}
```

### Exemplu: metodele ajutătoare pentru enumuri flag 

Fie un astfel de enum cu flaguri:

```csharp
public enum Flags
{
    Shy = 1 << 0,
    Brave = 1 << 1,
    Strong = 1 << 2,
    Beautiful = 1 << 3,
}
```

Și folosirea lui în cod tipică:

```csharp
Flags flags = Flags.Shy | Flags.Brave;

// Check if it has the Shy flag
assert((flags & Flags.Shy) != 0);

// Check if it has both the Shy and the Brave flags
assert((flags & (Flags.Shy | Flags.Brave)) == (Flags.Shy | Flags.Brave));

// Check it's neither Strong nor Beautiful
assert((flags & (Flags.Strong | Flags.Beautiful)) == 0);

// Clear the Shy flag
flags &= ~Flags.Shy;

// Conditionally set/unset the Beautiful flag
if (true)
    flags |= Flags.Beautiful;
else
    flags &= ~Flags.Beautiful;
```

Acestea pot fi puse în metode de extensiune și atunci uzul lor devine mai descriptiv:

```csharp
Flags flags = Flags.Shy | Flags.Brave;

// Check if it has the Shy flag
assert(flags.Has(Flags.Shy));

// Check if it has both the Shy and the Brave flags
assert(flags.Has(Flags.Shy | Flags.Brave));

// Check it's neither Strong nor Beautiful
assert(flags.DoesNotHaveEither(Flags.Strong | Flags.Beautiful));

// Clear the Shy flag
flags.Unset(Flags.Shy);

// Conditionally set/unset the Beautiful flag
flags.Set(Flags.Beautiful, true);

// ...

public static class FlagsExtensions
{
    public static Flags Has(this Flags source, Flags flags)
    {
        return (source & flags) == flags;
    }
    public static Flags DoesNotHaveEither(this Flags source, Flags flags)
    {
        return (source & flags) == 0;
    }
    public static void Unset(this ref Flags source, Flags target)
    {
        source &= ~target;
    }
    public static void Set(this ref Flags source, Flags target, bool isOn)
    {
        if (isOn)
            source |= target;
        else
            source &= ~target;
    }
}
```

Problema este că trebuie să se scrie aceste metode pentru toate tipurile flag care sunt în cod.
Când apare un nou astfel de tip, trebuie să se copieze acest cod, și să se plaseze undeva, cu denimirea tipului de intrare schimbată.
C# nu propune o soluție pentru această problemă: este pur și simplu imposibil să scrieți astfel de metode care să lucreze cu orice tip enum flag.
Aceasta este posibil de realizat cu IL emission, dar nu cred că merită.

Autorul propune următoarea soluție declarativă, explicată mai bine în capitolul 3:

```csharp
[NiceFlags]
public enum Flags
{
    // ...
}
```

Aceasta generează toate acele metode automat.

### Mai multe exemple

Cele două exemple clar arată capacitățile generării codului în eliminarea boilerplate-ului.
Însă acesta nu este singurul lor caz de utilizare.
Să se menționeze această prezentare https://youtu.be/j6ow-UemzBc unde autorul demonstrează cum compania lui generează codul pentru endpoint-uri API din fișiere agnostice de configurare.
Protobuf https://developers.google.com/protocol-buffers care generează codul pentru mai multe limbaje, realizând protocolul personalizat dintr-o descriere într-un DSL.
Message Pack https://github.com/neuecc/MessagePack-CSharp care permite emiterea codului IL pentru serializarea eficientă a datelor, dar permite și generarea codului AOT. Vedeți în special https://github.com/neuecc/MessagePack-CSharp#aot 
Încă un exemplu: consola și comenzile integrate în joc, menționat și în capitolul 3. https://github.com/AntonC9018/command_terminal


### Istoriografia problemei

După ce autorul a început să studieze și să practice programarea independentă în C#, și anume în proiectul Hopper descris în teza de an, au devenit evidente deficiențele acestui limbaj.
Folosind o abordare directă, a fost conceput și creat un prototip al generatorului de cod, cuplat cu proiectul în care a fost utilizat.
Acest generator de cod s-a descris pe scurt în teza de an al autorului.

După teza de an, autorul a continuat să experiementeze cu aceste concepte, implementând baza unui alt joc, conceput cu două ani înainte de perfectarea tezei de an.
În timp de aproape o lună și jumătate, a fost creat un proiect-șablon în Unity cu toate instrumentele necesare: generatorul de cod, divizarea modulară a asamblelor C# în Unity, integrarea unui terminal virtual în joc, o interfață de consolă centrală.
https://github.com/PunkyIANG/a-particular-project
Deci, generatorul de cod a fost inițial adaptat la nevoile acestui proiect, însă autorul a văzut oportunitatea să-l modularizeze printr-o arhitectură pe baza plugin-urilor, ceea ce și se explică în această lucrare.


### Roslyn

Roslyn este un ansamblu de librării și instrumente pentru analiza și compilarea codului C#, pentru C#.
De fapt, însuși compilatorul C# este implementat pe baza acestor librării Roslyn.
Roslyn combină întregul pipeline de compilare: tokenizarea, analiza sintactică, analiza semantică, generarea codului executabil, expuzând toate aceste operații.

Cel mai des, Roslyn este utilizat pentru analizatori, adică programe care analizează codul sursă și detectează erori logice, posibil propunând o remediere (code fix), sau adaugând operații utile în IDE-urile (de exemplu, "implement methods", "extract into a local function").
De fapt, repertoriul Roslyn conține o mulțime de analizatori gata pentru folosire.

Însă Roslyn a fost demult utilizat și pentru generatori de cod ad hoc, adică unele programe care produc codul sursă adaugător, des generat pe baza codului sursă inițial, create pentru un lucru specific.
Așa programe manual citesc fișierile sursă, manual le parsează conținuturile, manual le analizează și le produc output-ul.
Deci așa programe de fapt fac următoarele lucruri:
- Configurarea - din ce mapă sau proiect să fie citite fișierile;
- Parsarea - citirea fișierilor sursă și generarea obiectului de compilare;
- Analiza la nivel sintactic sau semantic al codului sursă;
- Generarea codului.

Un exemplu este generatorul de cod Message-Pack https://github.com/neuecc/MessagePack-CSharp.
Kari, generatorul de cod descris în această lucrare, a fost scris inițial după aceeași arhitectură ca și codul acestui proiect, însă autorul a prins oportunitatea să-l generalizeze.

Decizia să facă generatorul de cod în C# a fost o decizie evidentă, deoarece nu există nici o altă librărie care este asemănător de capabilă.


### Source Generators în .NET

.NET 5 a introdus un concept nou - Source Generators (generatori de sursă). https://docs.microsoft.com/en-us/dotnet/csharp/roslyn-sdk/source-generators-overview
Acestea sunt de fapt analizatorii care primesc la intrare arborele sintactic, și returnează codul sursă generat.
Acestea integrează cu compilatorul, deci funcționează pe baza arborelui sintactic al compilatorului.

Generatorii de sursă permit accelerarea generatorilor de cod personalizate, prin reutilizarea configurației și a datelor despre cod deja existente în timpul compilării în memoria compilatorului.
Aceasta permite generatorilor de cod personalizate să facă mai puțin lucru irelevant, și să lucreze cu abstracțiunile corespunzătoare.

Însă ei au și mai multe limitații:

- După experiența autorului, ele pot fi folosite doar cu MSBuild, sistemul de build al lui Microsoft.
  MSBuild este renumit pentru scalabilitatea proastă - un proces de build chiar puțin netrivial devine aproape imposibil de suportat.

- Generatorii de sursă trebuie să folosească și ele fișiere MSBuild pentru a-și specifica configurația (n-am sursă) și pentru a fi distribuite ca pachete NuGet, 
  însă în experiența autorului crearea de așa fișiere MSBuild pentru integrarea ușoară în alte proiecte devine foarte complicată și este predispusă la erori.

- Nu se poate folosi toate capacitățile framework-ului - sunt dintr-o cauză limitate la .NET Standard 2.0.

- Sunt considerate o capacitate avansată și experimentală, și nu sunt documentate bine.

- Sunt destul de dificile de setat și de utilizat.
   
- Clar că sunt suportate doar pe versiunile cele mai noi ale compilatorului, și clar că nu pot fi utilizate în Unity.


Așadar, după opinia autorului, acestea nu sunt practice la moment.


Crearea unei soluții personale ar fi mai ușor și mai practic:

- S-ar avea mai mult control asupra întregului proces, deoarece codul ar fi simplu și ușor de modificat.

- Realizarea unei soluții destul de bune din punct de vedere al uzului practic nu este atât de complicată.

- Soluția ar putea fi utilizată în Unity, precum și în orice alt proiect C#, indiferent de dacă folosește sau nu MSBuild și indifirent de versiunea compilatorului utilizată în acel proiect.

- Reutilizarea configurației tot poate fi asigurată (cel puțin parțial, descris și în continuare). 


### Rezumat

În acest capitol s-a discutat și s-a exemplificat valoarea practică a generatorilor de cod, și s-a argumentat de ce soluțiile existente nu sunt practice.
A fost introdusă și ideea de fluidizare a procesului utilizând un sistem care să reutilizeze o singură sursă de informație despre structura codului, făcând mai puțin lucru în total, așadar întregul proces să devină mai rapid în general.


## II. Sumarul Arhitecturii

<!-- 
 (fundamentarea teoretică)
• Structurarea (divizarea pe părți) trebuie să fie suficient de bine echilibrată, părțile
fiind puse într-o legătură logică și coerentă, astfel, încât să poată fi depistate cu
ușurință elementele-cheie ale acestora și legătura dintre ele.
• Expunerea se efectuează gradual, de la general la particular, de la simplu la compus,
însoțită de studii de caz și soluții concrete ce vizează probleme/obiecte reale.
• În lucrare se recomandă a se omite descrieri masive a obiectelor, a proceselor, a
sistemelor hardware-software, a instrumentelor și metodelor utilizate etc.
• Se recomandă ca scrierea și expunerea materialului tezei să se efectueze de la
persoana a treia, cu mici excepții în timpul susținerii orale a tezei, când e vorba de
aportul personal la obținerea rezultatelor din teză.
• Fiecare capitol se va termina cu un mini-rezumat din câteva aliniate, unde se va
expune esența compartimentului, concluziile, opiniile și contribuția personală a
autorului precum și se va asigura o trecere logică la următorul compartiment. -->


### Concretizarea cerințelor pentru generator de cod

Este clar că pentru a putea realiza un produs software trebuie să se știe ce exact se cere de el.
În cazul unui generator de cod, se poate formaliza cerințele funcționale de bază la nivel înalt în următorul mod:

1. Se cere ca generatorul de cod să citească fișierele sursă cu codul de intrare.
2. Se cere ca să se genereze codul de ieșire, pe baza unei logici specifice. Ca un exemplu concret, enumuri flag.
3. Se cere ca generatorul de cod să nu fie prea lent.
   Cu toate că aici nu sunt date concrete, această cerință se consideră funcțională, deoarece este foarte importantă.

Prima cerință poate fi concretizată mai tare:

- Trebuie să se poată controla ce fișiere sursă vor fi procesate. De exemplu, toate fișierele dintr-o mapă.
- Dacă codul logicii de generare necesită parametrizarea suplimentară, trebuie să fie posibil de a o furniza.
- Configurarea să se facă prin linia de comandă sau prin fișiere de configurare.
- Se cere să se integreze cu sistemul de structurare a subproiectelor folosit de Unity, anume asmdef-uri.
- Se cere ca fișierele sursă să fie interpretate corect, și ca codul generat să fie parametrizat de către codul de intrare.
  În alte cuvinte, se dorește o modalitate de a putea procesa codul de intrare într-un mod standardizat.


Se concretizează a doua cerință în modul următor:

- Codul de analiză și de generare a codului să fie scris în limbajul C# pe baza platformei .NET 6, să poată accesa toate API-urile specifice acestuia.
- Această logică trebuie să poată analiza o reprezentare abstractă a codului sursă de intrare și să poată genera output-ul, ca text.
- Se cere ca să fie ușor de creat fișiere cu codul care să conforme formatării corecte și care să nu lupte cu simboluri din codul inițial.
  În alte cuvinte, se cere ca librăria generatorului de cod să ofere API-uri utile pentru generarea codului și lucrul cu simboluri din cod.
- Deoarece se dorește ca codul de intrare să fie declarativ, să folosească extensiv atribute aplicate la tipuri și la membrii lor, ar fi foarte
  comod dacă codul generat să poată automat conțină definiții pentru aceste atribute, partajate între codul de intrare care să le folosească drept atribute,
  și logica de analiză și generare care să le caute în reprezentarea abstractă a codului sursă și să le inspecteze.
- Logica acestui analizator se va schimba des, și analizatorii noi vor fi adăugați, de aceea se cere ca acest nivel să fie cât mai flexibil, să fie posibil să se modifice și să se augmenteze ușor.


Ultima cerință se obține prin paralelizare.


### Schița arhitecturii

În primul rând se dorește să se precizeze încă o dată etapele concrete de funcționare a sistemei propuse care reies în mod natural din analiza superficială a cerințelor:

- Configurarea - parsarea argumentelor liniei de comandă, sau a fișierilor de configurare; validarea lor.
- Descoperirea fișierelor sursă și clasificarea lor între subproiecte (de exemplu, după asmdef-uri în Unity, sau după mape).
- Citirea conținutului fișierelor sursă, convertarea textului în reprezentarea abstractă a codului.
- Analiza codului.
- Generarea codului.

Se poate ușor observa că primele 3 puncte vor fi aceeași pentru orice logică de analiză și de generare a codului, și corespundă la prima cerință din lista adusă anterior.
Analog, ultimele două sunt legate la a doua cerință.
Să se țină minte că se cere ca acest nivel să fie cât mai flexibil.

Aceasta natural aduce la următoarea arhitectură:

- Să existe un orchestrator, care să accepte configurația din linia de comandă, să citească fișierele sursă și să le converteze în reprezentarea codului abstractă.
- Să existe mai multe plugin-uri, care să analizeze și să genereze output-ul pentru această reprezentare abstractă.
- Orchestratorul va încărca plugin-urile în timpul rulării, conform configurației, le va inițializa, iarăși, conform configurației, și le va da codul ca datele de intrare. El va primi output-ul generat de către ele și îl va scrie în fișiere corespunzătoare.

Arhitectura propusă poate fi eventual subdivizată și la mai multe etape, prin divizarea orchestratorului la mai multe părți.
Însă, nu este numaidecât necesar de făcut acest lucru, deoarece așa arhitectură deja corespunde cerințelor.

O divizare utilă însă ar fi cel puțin să se extragă etapa de citire a configurării din orchestrator într-un modul ce ține de interpretarea comenzilor din linie de comandă și/sau fișierelor de configurare.
Acest modul ar putea fi reutilizat în alte locuri în cod, sau poate fi substituit cu o librărie.


### Plugin-uri

Ideea principală a sistemelor băzate pe plugin-uri este ca să fie posibil să se augmenteze logica sistemului în timpul rulării, adică fără să se schimbe codul acestei sisteme.
Acesta presupune că trebuie să existe o modalitate de a descoperi în timpul rulării codul logicii care trebuie să fie executat.
Acest cod atunci ar putea să se schimbe fără a afecta logica sistemei originale.

În alte cuvinte, totul ce sistemul va trebui să facă va fi administrarea și integrarea acestor plugin-uri.
Însăși logică va fi conținută în aceste plugin-uri și nu va fi partea integrală a sistemei.

Utilizarea plugin-urilor reprezintă o soluție care foarte bine corespunde cerințelor: în primul rând, restul sistemului este decuplat din nivelul plugin-urilor, iar acesta este foarte flexibil, adică ușor de modificat și de augmentat.

În C#, există DLL-uri - librării care permit să încarce codul în timpul rulării, să linkeze toate funcțiile necesare, să descopere tipurile prezente în această librărie și să facă ceva cu ele.
În cazul generatorului de cod dat, dorim ca aceste plugin-uri să poată fi inițializate, să analizeze codul sursă și să genereze codul nou.
Cea mai ușoară modalitate de a asigura acest lucru este de a defini o interfață cu toate aceste acțiuni ca metode, iar în timpul rulării de a căuta toate tipurile care implementează această interfață, după ce poate fi instanțiate și utilizate, executând metodele acestei interfețe. 

În plus, deoarece se presupune că plugin-urile sunt independente, putem paraleliza în mod trivial executarea lor.
(Pot fi și dependente, însă această problemă tot poate fi soluționată fără a anula utilizarea plugin-urilor și argumentul dat.)


### Fluxul de lucru cu generatorul de cod

Generatorul de cod trebuie să fie ușor de utilizat.
Configurarea nu trebuie să ia mult timp și trebuie să fie simplă.
De aceea s-a decis că generatorul de cod trebuie să funcționeze ca o aplicație de consolă tipică: să fie invocată la consolă, unde utilizatorul ar da toate argumentele și opțiunile.
Este clar că aceste opțiuni de obicei vor fi ascunse într-un script executabil, de exemplu, ca un fișier bat pe Windows.

Încă, configurația generală pentru un anumit proiect poate fi pusă într-un fișier json.
Așa fișier poate conține configurația parametrilor concrete pentru plugin-uri, sau configurația de felul care proiect din acestea este principal, cum să fie numită mapă de ieșire, etc. Exemplu (https://github.com/AntonC9018/race/blob/c5b282236ce3381a983bad4e48f213472dff7267/game/kari.json):
```jsonc
{
    "inputFolder": "Assets/Source",
    // The plugin paths are passed via the cli tool
    "generatedNamespaceSuffix": "Generated",
    "rootNamespace": "Race",
    "outputMode": "NestedDirectory",
    "inputMode": "UnityAsmdefs",
    "commonProjectName": "Common",

    // UnityHelpers
    "engineCommon": "EngineCommon",

    // CommandTerminal
    "terminalProject": "CommandTerminal"
}
```

S-a decis ca toate plugin-urile să fie importate ori dintr-o singură directorie, ori individual după cale către DLL-uri.
Încă se admite instalarea prin NuGet, pentru a putea să le împărtășească ușor cu lumea, însă procesul de lucru cu NuGet gol este mult mai complicat decât folosirea submodulelor git și setarea individuală a calelor la DLL-uri într-un script, de aceea această funcționalitate nu se folosește la moment.

Configurarea plugin-urilor tot se face prin consola.
Ei primesc argumente în același fel ca și orchestratorul.

Din punct de vedere a integrării cu instrumente, invocarea directă ar fi mai bună, ca de exemplu linkarea la librării C, însă invocarea unui proces la consolă tot este destul de ușor.

Deci, comanda exemplu de invocare ar putea fi următoarea:

```
kari -configurationFile kari.json -pluginPaths plugin1.dll,plugin2.dll,plugin3.dll
```

Aceasta ar invoca generatorul de cod cu plugin-uri plugin1, plugin2 și plugin3, unde restul configurației se ia din fișierul kari.json.
După aceasta, programul generează codul, ori arată erori, posibil cu mesajul de ajutor care arată toate opțiunile.


### Rezumat

În acest capitol s-au stabilit cerințele principale pentru generatorul de cod și s-a discutat arhitectura generală a sistemului.
S-a decis că o arhitectură băzată pe plugin-uri, unde orchestratorul dirijează o mulțime de plugin-uri soluționează problema conform cerințelor.
S-a discutat și fluxul de lucru dorit, mai precis, faptul că va fi o aplicație din linia de comandă.


## III. Implementarea generatorului de cod

<!-- (practică, aplicații, rezultate) -->


### Configurarea

După cum s-a menționat, configurarea se va face din linia de comandă și/sau prin fișiere json de configurare.
Autorul a decis să creeze codul propriu pentru lucrul acesta, cu toate că deja există mai multe librării care fac același lucru.
Autorul ori nu a fost satisfăcut cu API-ul lor, ori cu lipsa opțiunilor dorite.

Deci a fost realizat un API declarativ pentru specificarea opțiunilor particulare care o clasă specifică va lua:
Exemplu (a se vede codul sursă pentru un exemplu complet https://github.com/AntonC9018/Kari/blob/fd60ad86f353444ae51f53f72393850dad7bf587/source/Kari.Generator/KariCompiler.cs):

Următorul cod transmite argumentele primite la consolă la parser, care își completează structura de date internă cu toate opțiunile prinse, pentru o mapare mai eficientă în continuare:


https://github.com/AntonC9018/Kari/blob/fd60ad86f353444ae51f53f72393850dad7bf587/source/Kari.Generator/KariCompiler.cs#L126-L132

```csharp
ArgumentParser parser = new ArgumentParser();
var result = parser.ParseArguments(args);
if (result.IsError)
{
    argumentLogger.LogError(result.Error);
    return (int) ExitCode.OptionSyntaxError;
}
```

Aici se arată codul parțial al clasei ce va primi argumentele din consolă, mapate la tipurile câmpurilor.
Cum se poate observa, este utilizat atributul `Option` pentru a atinge un API declarativ.
Acestea sunt scanate în timpul rulării de către parser, utilizând reflexie runtime, pentru a obține informații despre obiect la care să fie bindate valorile argumentelor. 

https://github.com/AntonC9018/Kari/blob/fd60ad86f353444ae51f53f72393850dad7bf587/source/Kari.Generator/KariCompiler.cs#L21-L87

```csharp
public class KariOptions
{
    public string HelpMessage => "Use Kari to generate code for a C# project.";

    [Option("Input path to the directory containing source files or projects.", 
        IsPath = true)] 
    public string inputFolder = ".";

    [Option("Plugins folder or paths to individual plugin dlls.",
        // Can be sometimes inferred from input, aka NuGet's packages.config
        IsRequired = false,
        IsPath = true)]
    public string[] pluginPaths = null;

    [Option("The suffix added to the project namespace to generate the output namespace.")]
    public string generatedNamespaceSuffix = "Generated";
    // ...
}
```

Urmează un exemplu de utilizare în codul generatorului de cod.
Metoda `FillObjectWithOptionValues` umple obiectul dat cu valorile din structura de date internă, și returnează o listă cu toate erorile care s-au îmtâmplat în timpul bindării parametrilor. 

https://github.com/AntonC9018/Kari/blob/fd60ad86f353444ae51f53f72393850dad7bf587/source/Kari.Generator/KariCompiler.cs#L147-L155

```csharp
var ops = new KariOptions();
var result1 = parser.FillObjectWithOptionValues(ops);

if (result1.IsError)
{
    foreach (var e in result1.Errors)
        argumentLogger.LogError(e);
    return (int) ExitCode.BadOptionValue;
}
```


Aceeași metodă este utilizată și pentru bindarea valorilor la câmpurile "administratorilor" plugin-urilor.
Administratorii sunt obiecte care dirijează procesul de execuție a plugin-urilor.


https://github.com/AntonC9018/Kari/blob/fd60ad86f353444ae51f53f72393850dad7bf587/source/Kari.GeneratorCore/Workflow/MasterEnvironment.cs#L208-L221

```csharp
foreach (var admin in Administrators)
{
    var result = parser.FillObjectWithOptionValues(admin.GetArgumentObject());
    if (result.IsError)
    {
        foreach (var err in result.Errors)
        {
            Logger.LogError(err);
        }
    }
}
```

Interesant este momentul că, când vreo opțiune este menționată în parser, ea este marcată cu un flag.
După ce toate opțiunile au fost colectate, se poate obține toate opțiunile care nu au fost marcate cu un astfel de flag - argumentele superfluoase.
Opinia autorului este că prezența argumentelor superfluoase mereu trebuie să fie considerată ca o eroare critică.
În plus, toate așa erori trebuie să fie explicit afișate.

https://github.com/AntonC9018/Kari/blob/fd60ad86f353444ae51f53f72393850dad7bf587/source/Kari.Generator/KariCompiler.cs#L446-L460

```csharp
var unrecognizedOptions = parser.GetUnrecognizedOptions();
var unrecognizedConfigOptions = parser.GetUnrecognizedOptionsFromConfigurations();
if (unrecognizedOptions.Any() || unrecognizedConfigOptions.Any())
{
    foreach (var arg in unrecognizedOptions)
    {
        _logger.LogError($"Unrecognized option: `{arg}`");
    }
    foreach (var arg in unrecognizedConfigOptions)
    {
        // TODO: This can contain more info, like the line number.
        _logger.LogError($"Unrecognized option: `{parser.GetPropertyPathOfOption(arg)}`");
    }
    return ExitCode.UnknownOptions;
}
```

Un exemplu de output:

```
kari -helloworld -mynameisanton
[Master]: Unrecognized option: `helloworld`
[Master]: Unrecognized option: `mynameisanton`
```

Mesajele de ajutor au fost implementate utilizând librăria https://github.com/spectreconsole/spectre.console, în particular, funcționalitatea de creare a tabelelor.
Deci, o parte a mesajul de ajutor arată cam în modul următor:

```
                                      Use Kari to generate code for a C# project.
┌──────────────────────────┬────────┬───────────────────────┬──────────────────────────────────────────────────────────┐
│          Option          │  Type  │    Default/Config     │ Description                                              │
├──────────────────────────┼────────┼───────────────────────┼──────────────────────────────────────────────────────────┤
│        inputFolder       │  Path  │ E:\Coding\CSharp\race │ Input path to the directory containing source files or   │
│                          │        │                       │ projects.                                                │
│                          │        │                       │                                                          │
│        pluginPaths       │ Path[] │          ---          │ Plugins folder or paths to individual plugin dlls.       │
│                          │        │                       │                                                          │
│   pluginConfigFilePath   │  Path  │          ---          │ Path to `packages.*.config` that you're using to manage  │
│                          │        │                       │ packages. The plugins mentioned in that file will be     │
│                          │        │                       │ imported.                                                │
│                          │        │                       │                                                          │
│ generatedNamespaceSuffix │ String │       Generated       │ The suffix added to the project namespace to generate    │
│                          │        │                       │ the output namespace.                                    │
│                          │        │                       │                                                          │
```

Codul parser-ului este foarte simplu. 
https://github.com/AntonC9018/Kari/blob/fd60ad86f353444ae51f53f72393850dad7bf587/source/Kari.Arguments/ArgumentParsing.cs
Pe scurt:

- Toate opțiunile sunt colectate și păstrate într-un tablou asociativ, numele -> valoarea.
- Toate fișierele menționate prin opțiunea `configurationFile` sunt încărcate și sălvate într-o listă.
- Metoda `FillObjectWithOptionValues` primește la intrare un obiect de orice tip, îi inspectează câmpurile, utilizând reflexia runtime, și performă conversiunile din tip șir în tipul câmpului corespunzător.
- Metoda `GetHelpFor` consruiește un tabel, utilizând aceeași reflexie runtime.
- Metodele `GetUnrecognizedOptions` și `GetUnrecognizedOptionsFromConfigurations` iterează prin toate opțiunele nemarcate și le returnează numele.

Să se noteze că API-ul nu este final.
A fost realizat în durata de aproape o zi și în continuare ceva modificat după necesitățile aplicației.



### Încărcarea plugin-urilor

După cum s-a menționat anterior, codul plugin-urilor este distribuit și încărcat prin DLL-uri.
Pentru aceasta, se folosesc funcțiile `Assembly.LoadFile` și `GetExportedTypes`, după ce se realizează filtrarea tuturor tipurilor, anume căutarea tipurilor care implementează interfața `IAdministrator`.
Aceste tipuri deja pot fi instanțiate prin reflexie.

https://github.com/AntonC9018/Kari/blob/9d12bfd2ec2520e6192fe3ffa3f119421d6016cd/source/Kari.GeneratorCore/Workflow/AdministratorFinder.cs

După ce s-au încărcat plugin-urile, nu sunt inițializate imediat.
La început, ele iau argumentele de linie de comanda, iar după aceasta sunt încărcate toate proiectele cu codul sursă de intrare.
Plugin-urile realizează inițializarea suplimentară după ce devin accesibile toate proiectele cu codul sursă și după ce au primit toate argumentele, deoarece validarea argumentelor deseori se face pe baza proiectelor sau tipurilor existente în compilație.
De exemplu, unele plguin-uri generează un fel de output agnostic, de aceea doresc să știu care este proiectul comun, pentru a scrie fișierele acolo, însă denumirea proiectului comun nu se cunoaște înainte ca proiectele utilizatorului au fost descoperite.


### Descoperirea fișierelor sursă

Kari permite mai multe moduri de intrare (de descoperire a fișierelor sursă):

- `UnityAsmdef`.
  Unity are formatul său pentru definirea subproiectelor, numit asmdef.
  Este un fișier JSON care conține metadatele despre subproiectul dat, precum și dependențele lui.
  Divizarea fișierelor de sursă între mai multe așa proiecte este benefică pentru proiecte mari, deoarece reduce timpul de compilare incrementală.
  Acest mod de intrare descoperă toate fișierele cu extensiunea `asmdef` imbricate într-o directorie dată, și prescrie toate fișierele în același folder acestui subproiect.

- `ByDirectory`. Acest mod de intrare presupune gruparea fișierelor de intrare după subdirectorii imediate ale directorii de intrare.

- `Monolithic`. Toate directoriile sunt considerate ca un singur proiect.

- `Autodetect`. Ghicește modul de intrare din structura sistemului de fișiere.


Această logică se conține într-o singură funcție, cu mai multe funcții locale imbricate.
Codul este foarte simplu, operând cu API-urile sistemei de fișiere și în cea mai mare parte conține validări.
În dependența de cerințele următoare pentru proiect, acest cod poate fi extras în încă o etapă opțională de descoperire.

https://github.com/AntonC9018/Kari/blob/9d12bfd2ec2520e6192fe3ffa3f119421d6016cd/source/Kari.GeneratorCore/Workflow/MasterEnvironment.cs#L285-L598

Acest cod încă gestionează căutarea acelor două proiecte, anume proiectului `Common` care reprezintă un proiect cu cod agnostic care conceptual nu poate să se refere la nici un alt proiect, și a proiectului `Root`, adică proiectului care să conține funcții de inițializare și care conceptual poate referi la orice alt proiect.
Fiecare mod de intrare are logica sa de căutare a proiectelor acestea, selectată în așa fel ca să aibă cât mai mult sens în scopul modului de intrare selectat.


### Pornirea plugin-urilor cu codul sursă ca parametri de intrare

Obiectul care permite reprezentarea abstractă a codului sursă în Roslyn se numește o compilație.
Acest obiect poate fi creat din arbori sintactici care la rândul său sunt creați din codul sursă, citit din fișiere sursă.
Crearea compilației nu poate fi paralelizată pe mai multe fire, însă generarea arborilor din textul sursă poate fi paralelizată.
Acestă paralelizare nu aduce un beneficiu mare, însă din testele autorului a accelerat timpul execuției cu aproape 10%.

https://github.com/AntonC9018/Kari/blob/9d12bfd2ec2520e6192fe3ffa3f119421d6016cd/source/Kari.GeneratorCore/Workflow/MasterEnvironment.cs#L604-L664

După ce toții arbori s-au încărcat, se creează obiectul de compilație.
Acest obiect este după înțelegerea autorului în mare parte leneș, adică nu cachează atâtea multe simboluri.

https://github.com/AntonC9018/Kari/blob/9d12bfd2ec2520e6192fe3ffa3f119421d6016cd/source/Kari.GeneratorCore/Workflow/MasterEnvironment.cs#L666-L697

Plugin-urile de obicei lucrează la nivelul tipurilor sau al membrii lor.
De obicei se cere ca aceste simboluri (tipuri sau membrii) să fie anotate cu atributele folosite pentru configurarea codului generat pentru acest simbol, fiind descoperite și interpretate de către plugin-uri.
Cel mai importat simbol sunt tipurile definite de utilizator, de aceea ele sunt mereu cachate din arborii sintactici, ca să nu le facă pe plugin-uri să realizeze acest lucru.
Cacharea de face în mod paralel.
Această operație este destul de constisitoare.
După înțelegerea autorului, cere destul de multe resurse din acea cauză că crearea compilației este leneșă, deci analiza tuturor arborilor sintactice necesită cacharea leneșă a mai multor simboluri.

https://github.com/AntonC9018/Kari/blob/9d12bfd2ec2520e6192fe3ffa3f119421d6016cd/source/Kari.GeneratorCore/Workflow/MasterEnvironment.cs#L699-L727

Fiecare plugin, în rândul său, face filtrarea proprie a tipurilor, colectând datele necesare.
Aceasta se face în metoda `IAdministrator.Collect` scopul căreia este să inițializeze toate datele necesare pentru generarea consecutivă a codului.
Deoarece procesarea mai multor simboluri ia destul de mult timp, acest proces este paralelizat între plugin-uri, care pot paraleliza procesul mai departe cum ele consider rezonabil.

După ce toate plugin-urile au terminat cacharea simbolurilor, are loc generarea codului prin invocarea metodei `IAdministrator.Generate` la toate plugin-urile.
Șirurile cu codul sursă de ieșire la început sunt generate aparte în memorie, adică nu sunt scrise imediat în fișiere.
Paralelizarea se face în același mod ca și la colectarea simbolurilor.


### Sălvarea output-ului

Plugin-urile scriu codul de output al lor direct într-un UTF-8 bufer ca să fie posibil să scrie textul de ieșire direct în fișiere.
Se utilizează librăria https://github.com/Cysharp/ZString, cu toate că se planifică să se folosească capacitățile noi de interpolare a șirurilor fără alocările memoriei adăugate în .NET 6 https://devblogs.microsoft.com/dotnet/string-interpolation-in-c-10-and-net-6/

Plugin-urile selectează explicit denumirile fișierelor în care doresc să scrie output-ul lor, însă aceste denumiri sunt doar hint-uri, și proiectul în care se dorește să fie generat fișierul.
Sistemul este liber să folosească alte denumiri pentru aceste fișiere, în funcție de *modul de output* selectat.

Sunt 4 moduri de output:

- `CentralFile`. Output-ul este concatenat între toate proiectele, și scris într-un singur fișier.
  https://github.com/AntonC9018/Kari/blob/9d12bfd2ec2520e6192fe3ffa3f119421d6016cd/source/Kari.GeneratorCore/Workflow/MasterEnvironment.cs#L1114-L1129

- `CentralDirectory`. Output-ul este divizat între proiecte și put într-un folder de ieșire comun.
  Fiecare subfolder al acestui folder are denumirea proiectului pentru care a fost generat fișierul, și conține toate fișierele, ca solicitat de plugin-uri.
  https://github.com/AntonC9018/Kari/blob/9d12bfd2ec2520e6192fe3ffa3f119421d6016cd/source/Kari.GeneratorCore/Workflow/MasterEnvironment.cs#L1064-L1080

- `NestedFile`. Output-ul fiecărui proiect în parte este concatenat și scris în câte un fișier pentru fiecare proiect.
  https://github.com/AntonC9018/Kari/blob/9d12bfd2ec2520e6192fe3ffa3f119421d6016cd/source/Kari.GeneratorCore/Workflow/MasterEnvironment.cs#L1131-L1145

- `NestedDirectory`. Output-ul este divizat între proiecte și generat în căte un subfolder, cu denumirile fișierelor ca solicitat de plugin-uri.
  https://github.com/AntonC9018/Kari/blob/9d12bfd2ec2520e6192fe3ffa3f119421d6016cd/source/Kari.GeneratorCore/Workflow/MasterEnvironment.cs#L1040-L1057


Înainte de a fi scris în fișier, codul generat este comparat cu conținutul fișierului existent, dacă un fișier cu aceeași denumire deja există.
Dacă conținuturile se diferă, conținutul fișierului existent se înlocuiește cu cel generat.
Aceasta se face, deoarece instrumentele ca MSBuild și Unity, cel puțin în unele versiuni, determină dacă trebuie să recompileze proiectul pe baza timestamp-urilor de modificare salvate în metadatele fișierelor.
Chiar dacă se înlocuiește conținutul unui fișier cu conținutul nou egal, timestamp-ul se schimbă, ce invocă o recompilare.
Din această cauză, dacă se admite ca generatorul de cod să nu aibă această verificare, rularea generatorului de cod de a două dată va invoca o recompilare.
Deoarece recompilarea în Unity este foarte lentă, luând pănă la 10 secunde, se câștigă destul de multe resurse dacă se folosește această verificare.

https://github.com/AntonC9018/Kari/blob/9d12bfd2ec2520e6192fe3ffa3f119421d6016cd/source/Kari.GeneratorCore/Workflow/MasterEnvironment.cs#L950-L972

Se poate observa că se folosește cod asincron de scriere a datelor în fișiere, și codul este la un nivel destul de scăzut.
Acestea sunt în cea mai mare parte experimentările autorului și de fapt nu accelerează executarea.
Deci acest cod probabil va fi schimbat când autorul va găsi timpul pentru refactoring.


### Rezumat

În acest capitol s-au discutat detaliile referitor la implementarea sistemei: cum se configurează sistemul, cum el interacționează cu plugin-urile, cum codul sursă este citit și cum sunt scrise fișierele de ieșire.
În acest capitol nu s-a discutat logica generării codului, deoarece aceasta deja vine din plugin-uri concrete.

Este clar că nu sunt considerate dependențele între proiecte și orice schimbare forțează codul pentru fiecare proiect să fie regenerat.
Încă, dependențele de fiecare plugin din punct de vedere a tipurilor cu atribute specifice, sau a tipului de output (dependent de totul input, sau pentru un proiect aparte) nu au fost explorate.
Acestea pot fi folosite pentru a accelera generatorul de cod și mai departe, dar necesită și mai mult cod și timp pentru a le implementa.


## IV. Programarea Plugin-urilor și Exemple de Utilizare

### CodeBuilder

Când se realizează generarea codului, se dorește ca codul generat să fie formatat conform standardelor.
Formatarea corectă face codul mai ușor de citit și de înțeles pentru persoana care îl citește.
Pentru acest lucru a fost creat tipul `CodeBuilder` care simplifică procesul de indentare.
El are un contor pentru indentarea curentă, și o adaugă de atâtea ori, când codul se scrie pe o linie nouă.

Esența acestei utilități poate fi ilustrată în următorul cod:

```csharp
// UTF-8
public byte[] IndentationBytes { get; }

public int CurrentIndentationCount;
public void IncreaseIndent() => CurrentIndentationCount++;
public void DecreaseIndent() => CurrentIndentationCount--;

public void Indent()
{
    for (int i = 0; i < CurrentIndentationCount; i++)
        StringBuilder.AppendLiteral(IndentationBytes);
}

public void AppendLine() 
{ 
    Indent();
    NewLine();
}
```

https://github.com/AntonC9018/Kari/blob/fd60ad86f353444ae51f53f72393850dad7bf587/source/Kari.Utils/CodeBuilder.cs#L19-L184

Mai jos se vede niște exemple de utilizare.

### Anotațiile 

Următorul caz de utilizare comun pentru majoritatea plugin-urilor sunt anotațiile (sau atributele).
Atributele sunt acel lucru care permite design-ul unor API-uri declarative.
Este comod pentru ele să fie partajate între codul sursă al plugin-ului și cel al consumatorului.
Plugin-ul le-ar utiliza ca containeri pentru datele extrase din codul consumatorului, iar acela le-ar folosi pentru a stabili aceste date.
Astfel, același container este utilizat și pentru definirea datelor, și pentru manipularea lor.

Deci s-ar dori să se partajeze codul legat cu anotațiile între plugin-ul și consumatorul, însă cum să se realizeze acest lucru?
O soluție poate fi să se copieze fișierul sursă din sursa plugin-ului în codul consumatorului, dar nu ar fi comod să se facă aceasta manual, deoarece ar fi nevoie ca el să schimbe și în codul sursă al consumatorului când se schimbă interfața plugin-ului, și este încă un pas de setup, și trebuie să fie urmărit de source control, etc.
O soluție mult mai comodă ar fi ca plugin-ul să genereze acest fișier drept un fișier de ieșire al său.
Atunci, dacă plugin-ul a fost utilizat cu totul, acest fișier cu anotațiile va fi prezent numaidecât în proiectul consumatorului.
În plus, plugin-ul acum are posbilitatea să schimbe conținutul fișierului său cu anotațiile.

Problema este că C# nu poate citi fișiere ca șiruri în timpul compilării, de aceea a trebuit să se realizeze un program aparte care să citească acest fișier cu anotațiile și să genereze un nou fișier cu o singură clasă statică, cu o singură constantă statică cu conținutul acestui fișier.
Deoarece acum este un program aparte și este posibil de făcut mai multe lucruri decât doar generarea acestei constante, a fost implementată și generarea boilerplate-ului asociat cu căutarea simbolurilor acestor anotații în codul de intrare analizat de plugin-uri.
I s-a dat denumirea *Annotator*, deoarece lucrează cu anotațiile.

https://github.com/AntonC9018/Kari/blob/fd60ad86f353444ae51f53f72393850dad7bf587/source/Kari.Annotator/Annotator.cs

Acest instrument ori se integrează în procesul de build al plugin-urilor, ori fișierele generate sunt incluse în source control.
Fișierele targets și props din MSBuild distribuite cu Kari realizează integrarea acestui instrument în procesul de build al plugin-ului,
însă sistemul de build urmează să fie schimbat la ceva mai ușor de menținut. 

https://github.com/AntonC9018/Kari/blob/fd60ad86f353444ae51f53f72393850dad7bf587/source/Kari.Plugins/InternalPlugin.props



Referitor la căutarea tuturor simboluri cu un anumit atribut aplicat la ele, a se vede discuția mai detaliată a soluțiilor.
Codul generat de către anotator creează instanțe de wrapper-uri asupra atributelor interesante și le păstrează în câmpuri.
https://stackoverflow.com/questions/67539903/converting-attributedata-into-a-known-attribute-type-roslyn


Urmează un exemplu al unui fișier generat.
Clasa `DummyDataObjectAnnotations` conține membrul Text cu codul sursă al fișierului, din care acest fișier a fost generat,
iar clasa `DataObjectSymbols` reprezintă acel boilerplate ce ține de wrapper-uri pentru atributele.

```csharp
namespace Kari.Plugins.DataObject
{
    using Kari.GeneratorCore.Workflow;
    using Kari.Utils;
    internal static class DummyDataObjectAnnotations
    {
        internal const string Text = @"namespace Kari.Plugins.DataObject
{
    using System;
    using System.Diagnostics;

    [AttributeUsage(AttributeTargets.Class | AttributeTargets.Struct)]
    [Conditional(""CodeGeneration"")]
    public class DataObjectAttribute : Attribute
    {
    }
}
";
    }
    internal static partial class DataObjectSymbols
    {
        internal static AttributeSymbolWrapper<DataObjectAttribute> DataObjectAttribute { get; private set; }

        internal static void Initialize(NamedLogger logger)
        {
            var compilation = MasterEnvironment.Instance.Compilation;
            DataObjectAttribute = new AttributeSymbolWrapper<DataObjectAttribute>(compilation, logger);
        }
    }
}
```


### Cum lucrează plugin-urile, mai detaliat

Fiecare plugin, după cum s-a menționat anterior, trebuie să definească cel puțin o clasă publică de *administrator* care să implementeze interfața `IAdministrator`.
De obicei, administratorii definesc un tablou de *analizori* care conține câte un analizor pentru fiecare proiect.
Administratorii deleghează deciziile concrete referitor la analiza tipurilor și generarea codului pentru ele la analizorii aceștia.

https://github.com/AntonC9018/Kari/blob/1e103379417c3a268e1891ab94acb0cc81eb9489/source/Kari.Plugins/Flags/FlagsAdministrator.cs

Aceasta este codul administratorului plugin-ului pentru generarea codului pentru enumuri flag.
După cum se poate vedea, se utilizează funcțiile statice ale clasei `AdministratorHelpers`.
Aceste funcții acomodează exact cazul acesta de utilizare: lucrul printr-un tablou de analizori, câte o instanță pentru fiecare proiect.

https://github.com/AntonC9018/Kari/blob/1e103379417c3a268e1891ab94acb0cc81eb9489/source/Kari.GeneratorCore/Workflow/Administrator.cs#L67-L163 

- În metoda `Initialize()` tabloul cu analizorii se umple, câte un analizor pentru fiecare proiect;
- În metoda `Collect()`, lucrul de colectare a simbolurilor pur și simplu se deleghează la analizori;
- În metoda `Generate()`, se realizează generarea codului, aparte pentru fiecare proiect.
- Metoda `GetAnnotations()` returnează textul acelui fișier cu anotațiile.

https://github.com/AntonC9018/Kari/blob/dcfd36eac6de767a922df97a37f009ae12d8cf1f/source/Kari.Plugins/Flags/FlagsAnalyzer.cs

În acest exemplu, se poate vedea ce de obicei se face în metoda `CollectSymbols()` al fiecărui analizor.
În acest caz, sunt colectate unele informații despre toate simbolurile cu atributul `NiceFlags`.


https://github.com/AntonC9018/Kari/blob/dcfd36eac6de767a922df97a37f009ae12d8cf1f/source/Kari.Plugins/Flags/FlagsAnalyzer.cs#L159-L170

Metoda `GenerateCode()` folosește aceste date pentru a formata un șir cu codul boilerplate și scrie rezultatul într-un `CodeBuilder`.
Early exit-ul `if (_infos.Count == 0) return;` garantează că dacă nici un tip nu a fost anotat cu atributul `NiceFlags`, nimic nu va fi generat.



### Plugin-ul Flags

Cu toate că plugin-ul pentru generarea codului pentru enumuri flag deja a fost menționat în lucrare de mai multe ori, merită a vedea întreaga imagine.
Deci, plugin-ul Flags este un plugin pentru generatorul de cod Kari care permite generarea metodelor utile pentru lucrul cu enumuri flag.
Acestea includ următoarele:

- `Has` și `DoesNotHave` care verifică prezența unui flag sau a unei combinații de flaguri în valoarea dată;
- `HasEither` și `DoesNotHaveEither` care verifică intersecția a două seturi de flaguri;
- `WithSet` și `WithUnset` care setează sau șterge un flag sau o combinație de flaguri, returnând valoarea modificată;
- `Set` și `Unset` care funcționează ca `WithSet` și `WithUnset`, doar că modifică argumentul;
- `Set` cu un argument boolean, care setează sau șterge un flag sau o combinație de flaguri, indicat de valoarea acestui argument.

Pentru demonstrare, se va crea un proiect nou în care se va folosi generatorul de cod Kari cu acest plugin.
Acest proiect este un proiect console fără dependențe pe .NET 6.
Fișierul principal conține următorul cod sursă, foarte asemănător cu exemplul din capitolul 1:

https://github.com/AntonC9018/uni_thesis/blob/ee1ae3f38d2d4ce81a8ada5956ede10b18deb6f7/examples/flags/Program.cs


Înainte de compilare trebuie să se ruleze generatorul de cod.
Pentru aceasta se invocă Kari cu drumul la fișierul de configurare `kari.json` care conține drumul la DLL-ul plugin-ului Flags.
Acesta poate fi dat lui Kari și direct, însă utilizarea unui fișier de configurare este mai comod.

https://github.com/AntonC9018/uni_thesis/blob/ee1ae3f38d2d4ce81a8ada5956ede10b18deb6f7/examples/flags/kari.bat

https://github.com/AntonC9018/uni_thesis/blob/ee1ae3f38d2d4ce81a8ada5956ede10b18deb6f7/examples/flags/kari.json

Și codul generat:

https://github.com/AntonC9018/uni_thesis/blob/ee1ae3f38d2d4ce81a8ada5956ede10b18deb6f7/examples/flags/Generated/FlagsAnnotations.cs

https://github.com/AntonC9018/uni_thesis/blob/ee1ae3f38d2d4ce81a8ada5956ede10b18deb6f7/examples/flags/Generated/Flags.cs



### DataObject plugin

DataObject este un plugin pentru Kari care permite generarea codului pentru tipuri care conceptual doar conțin datele.
Codului generat va conține supraîncărcări triviale pentru operatorii de egalitate, supraîncărcarea metodei `Equals`, `GetHashCode`.

De fapt, aceasta a fost implementat în versiunele noi de C#, anume C# 9 și C# 10 din .NET 5 și .NET 6 respectiv, în forma de *records* și *record structs*, însă acestea nu sunt accesibile în Unity.

https://docs.microsoft.com/en-us/dotnet/csharp/whats-new/tutorials/records

Administratorul acestui plugin are aceeași structură ca și administratorul plugin-ului Flags:

https://github.com/AntonC9018/Kari/blob/dcfd36eac6de767a922df97a37f009ae12d8cf1f/source/Kari.Plugins/DataObject/DataObjectAdministrator.cs

Informațiile colectate au mai multe chestii, ca simbolul tipului, simbolurile pentru câmpurile instance, etc.

https://github.com/AntonC9018/Kari/blob/dcfd36eac6de767a922df97a37f009ae12d8cf1f/source/Kari.Plugins/DataObject/DataObjectAnalyzer.cs#L160-L180

Metoda `CollectSymbols` tot așa colectează simbolurile necesare și le pune în aceste obiecte cu informații suplimentare extrase.
Se mai fac niște verificări pentru a avertiza utilizatorul despre problemele cu tipul: trebuie să nu fie static, trebuie să fie parțial, trebuie să aibă un modificator de acces.

https://github.com/AntonC9018/Kari/blob/dcfd36eac6de767a922df97a37f009ae12d8cf1f/source/Kari.Plugins/DataObject/DataObjectAnalyzer.cs#L14-L46

Metoda pentru generarea codului este puțin mai complicată decât cea a plugin-ului Flags, deoarece codul generat depinde de detaliile tipului mai mult.
De exemplu, dacă tipul este o clasă, atunci operatorul `==` trebuie să verifice cazul când unul sau ambele argumente sunt nule. 

https://github.com/AntonC9018/Kari/blob/dcfd36eac6de767a922df97a37f009ae12d8cf1f/source/Kari.Plugins/DataObject/DataObjectAnalyzer.cs#L48-L157

Proiectul cu exemplul de utilizare are aceeași structură ca și proiectul pentru flaguri, doar că menționează plugin-ul `DataObject` în loc de `Flags`.

### As part of a CLI usable in a CI/CD pipeline



<!-- Concluziile finale caracterizează succint rezultatele obținute, valoarea lor, modalitățile de
realizare a obiectivelor formulate în introducere, opiniile proprii și contribuția personală în studierea
și elucidarea problemei abordate. În teza de licență vor fi evidențiate minimum 2-3 concluzii de
bază, iar în teza de – master 3-5, cu un accent deosebit pe aprecierea elementelor noi și originale. -->