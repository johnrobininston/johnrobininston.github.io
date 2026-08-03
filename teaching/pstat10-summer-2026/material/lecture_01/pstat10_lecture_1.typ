// Simple numbering for non-book documents
#let equation-numbering = "(1)"
#let callout-numbering = "1"
#let subfloat-numbering(n-super, subfloat-idx) = {
  numbering("1a", n-super, subfloat-idx)
}

// Theorem configuration for theorion
// Simple numbering for non-book documents (no heading inheritance)
#let theorem-inherited-levels = 0

// Theorem numbering format (can be overridden by extensions for appendix support)
// This function returns the numbering pattern to use
#let theorem-numbering(loc) = "1.1"

// Default theorem render function
#let theorem-render(prefix: none, title: "", full-title: auto, body) = {
  if full-title != "" and full-title != auto and full-title != none {
    strong[#full-title.]
    h(0.5em)
  }
  body
}
// Some definitions presupposed by pandoc's typst output.
#let content-to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(content-to-string).join("")
  } else if content.has("body") {
    content-to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms.item: it => block(breakable: false)[
  #text(weight: "bold")[#it.term]
  #block(inset: (left: 1.5em, top: -0.4em))[#it.description]
]

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let fields = old_block.fields()
  let _ = fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => {
          let subfloat-idx = quartosubfloatcounter.get().first() + 1
          subfloat-numbering(n-super, subfloat-idx)
        })
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => block({
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          })

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let children = old_title_block.body.body.children
  let old_title = if children.len() == 1 {
    children.at(0)  // no icon: title at index 0
  } else {
    children.at(1)  // with icon: title at index 1
  }

  // TODO use custom separator if available
  // Use the figure's counter display which handles chapter-based numbering
  // (when numbering is a function that includes the heading counter)
  let callout_num = it.counter.display(it.numbering)
  let new_title = if empty(old_title) {
    [#kind #callout_num]
  } else {
    [#kind #callout_num: #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block,
    block_with_new_content(
      old_title_block.body,
      if children.len() == 1 {
        new_title  // no icon: just the title
      } else {
        children.at(0) + new_title  // with icon: preserve icon block + new title
      }))

  align(left, block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1)))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color,
        width: 100%,
        inset: 8pt)[#if icon != none [#text(icon_color, weight: 900)[#icon] ]#title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}


// syntax highlighting functions from skylighting:
/* Function definitions for syntax highlighting generated by skylighting: */
#let EndLine() = raw("\n")
#let Skylighting(fill: none, number: false, start: 1, sourcelines) = {
   let blocks = []
   let lnum = start - 1
   let bgcolor = rgb("#f1f3f5")
   for ln in sourcelines {
     if number {
       lnum = lnum + 1
       blocks = blocks + box(width: if start + sourcelines.len() > 999 { 30pt } else { 24pt }, text(fill: rgb("#aaaaaa"), [ #lnum ]))
     }
     blocks = blocks + ln + EndLine()
   }
   block(fill: bgcolor, width: 100%, inset: 8pt, radius: 2pt, blocks)
}
#let AlertTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let AnnotationTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let AttributeTok(s) = text(fill: rgb("#657422"),raw(s))
#let BaseNTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let BuiltInTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let CharTok(s) = text(fill: rgb("#20794d"),raw(s))
#let CommentTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let CommentVarTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))
#let ConstantTok(s) = text(fill: rgb("#8f5902"),raw(s))
#let ControlFlowTok(s) = text(weight: "bold",fill: rgb("#003b4f"),raw(s))
#let DataTypeTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let DecValTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let DocumentationTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))
#let ErrorTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let ExtensionTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let FloatTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let FunctionTok(s) = text(fill: rgb("#4758ab"),raw(s))
#let ImportTok(s) = text(fill: rgb("#00769e"),raw(s))
#let InformationTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let KeywordTok(s) = text(weight: "bold",fill: rgb("#003b4f"),raw(s))
#let NormalTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let OperatorTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let OtherTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let PreprocessorTok(s) = text(fill: rgb("#ad0000"),raw(s))
#let RegionMarkerTok(s) = text(fill: rgb("#003b4f"),raw(s))
#let SpecialCharTok(s) = text(fill: rgb("#5e5e5e"),raw(s))
#let SpecialStringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let StringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let VariableTok(s) = text(fill: rgb("#111111"),raw(s))
#let VerbatimStringTok(s) = text(fill: rgb("#20794d"),raw(s))
#let WarningTok(s) = text(style: "italic",fill: rgb("#5e5e5e"),raw(s))


#import "@preview/touying-quarto-clean:0.1.1": *

#import "@preview/fontawesome:0.5.0": *
#let brand-color = (:)
#let brand-color-background = (:)
#let brand-logo = (:)

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
  columns: 1,
)

#show: clean-theme.with(
  aspect-ratio: "16-9",
    // Typography ---------------------------------------------------------------
            // Colors --------------------------------------------------------------------
        // Title slide ---------------------------------------------------------------
      )

#title-slide(
  title: [PSTAT 10 Data Science Principles],
  subtitle: [Lecture 1: Introduction],
  authors: (
                    ( name: [John Robin Inston],
            affiliation: [University of California, Santa Barbara],
            email: [johninston\@ucsb.edu],
            orcid: [0009-0001-7285-6823]),
            ),
  date: [July 31, 2026],
)

= Introduction
<introduction>
== 👋 Welcome
<welcome>
#block[
]
#block[
Welcome to PSTAT 10 Data Science Principles! 🎉

]
#block[
#block[
]
=== Teaching Team
<teaching-team>
- #strong[John Inston] #emph[\(Instructor)] --- Pronouns: he/him
  - 🏢 OH: Tuesday 1:30pm--3:00pm, South Hall Cubicle 5431T
  - ✉️ Email: #link("mailto:johninston@ucsb.edu")[johninston\@ucsb.edu]
  - 🌐 Website: #link("https://johnrobininston.com")[johnrobininston.com]

]
== 👩‍🏫 Teaching Assistants
<teaching-assistants>
#block[
#block[
]
I am being assisted this term by the following wonderful teaching assistants:

]
#block[
#block[
- === Yifan Chen
  <yifan-chen>
  - ✉️ Email: #link("mailto:ychen300@ucsb.edu")[ychen300\@ucsb.edu]
  - 🏢 OH: TBD

]
#block[
- === Yaxuan Wang
  <yaxuan-wang>
  - ✉️ Email: #link("mailto:yaxuanwang@ucsb.edu")[yaxuanwang\@ucsb.edu]
  - 🏢 OH: TBD

]
]
#block[
#block[
😊 Please treat all members of the course --- both teaching staff and students --- with respect and kindness at all times!

]
]
== ℹ️ Course Structure
<ℹ-course-structure>
#block[
#block[
]
#block[
#callout(
body: 
[
+ Section attendance --- 10%
+ Section worksheets --- 20% #emph[\(graded on completion)]
+ Homework assignments --- 35% #emph[\(graded on correctness)]
+ Final exam --- 35%

]
, 
title: 
[
Grading Structure
]
, 
background_color: 
rgb("#f7dddc")
, 
icon_color: 
rgb("#CC1914")
, 
icon: 
fa-exclamation()
, 
body_background_color: 
white
)
]
]
#block[
#block[
]
#block[
#callout(
body: 
[
- Section worksheets are due via PDF on Gradescope at 11:59pm on the following Wednesday / Friday after section (2 days).
- Homework assignments are uploaded to Canvas Tuesday evening and due via PDF on Gradescope at #strong[11:59pm the following Wednesday (8 days)].

]
, 
title: 
[
Worksheet & Assignment Submissions
]
, 
background_color: 
rgb("#f7dddc")
, 
icon_color: 
rgb("#CC1914")
, 
icon: 
fa-exclamation()
, 
body_background_color: 
white
)
]
]
#block[
#block[
📝 Final is written in-person for 11AM Thursday September 11th in ILP room 2101.

]
]
== ✅ Course Outline
<course-outline>
The following is our tentative course outline:

#block[
#block[
- === Week 1
  <week-1>
  - Vectors, matrices and arrays
  - Functions and control flow

- === Week 2
  <week-2>
  - Dataframes and tibbles
  - Data manipulation

- === Week 3
  <week-3>
  - Statistics
  - Probability

]
#block[
- === Week 4
  <week-4>
  - Database structure and design
  - Basic SQL

- === Week 5
  <week-5>
  - More complex SQL
  - Data visualization

- === Week 6
  <week-6>
  - Review
  - Additional topics as time allows

]
]
== ⚖️ Academic Integrity
<academic-integrity>
#block[
#block[
]
=== Common Points
<common-points>
+ Your priority should be to learn how to code and produce scientific documents!
+ The use of online resources such as Google, Stack Exchange, or ChatGPT is permitted as a study aid.

]
#block[
#block[
✍️ Write your own code! You will not learn by copy and pasting.

]
]
#block[
#block[
🚫 You may collaborate on assignments and worksheets, but always write and submit your own documents. You will not receive marks if you submit a group work document.

]
]
= R & RStudio
<r-rstudio>
== 🅁 What is R?
<what-is-r>
#block[
#block[
]
This course will use the programming language R.

- Open-source programming language designed for statistical computing.
- Large collection of community built libraries and resources.
- Tools for computation, data exploration, and visualization.

]
#block[
#block[
]
You can download R to your system using the following link:

#figure([
#link("https://www.r-project.org/")[#box(image("static/images/R-logo.png", width: 3.125in))]
], caption: figure.caption(
position: bottom, 
[
Download R!
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


]
== 💻 What is RStudio?
<what-is-rstudio>
#block[
#block[
]
We write code in an interactive development environment (IDE) --- applications designed to facilitate writing and running code.

]
#block[
#block[
]
In this course we will be using the IDE RStudio, which can be downloaded using the following link:

#figure([
#link("https://posit.co/downloads/")[#box(image("static/images/Rstudio_logo.png", width: 3.125in))]
], caption: figure.caption(
position: bottom, 
[
Download RStudio!
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


]
== 🖥️ RStudio Interface
<rstudio-interface>
#figure([
#box(image("static/images/rstudio_interface.png", width: 80.0%))
], caption: figure.caption(
position: bottom, 
[
RStudio Interface
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


== 📜 Scripts & Console
<scripts-console>
#block[
#block[
]
=== Scripts
<scripts>
- We write code in scripts, which appear in the top left pane.
- In your worksheets and assignments we will use Quarto documents --- #emph[which can generate PDFs] --- which will also appear in the top left pane.

]
#block[
#block[
]
=== Console
<console>
- The console in the bottom left pane is where we run code.
- This is also where any error messages for bug-fixing will appear.

]
== 🗂️ Environment & Files
<environment-files>
#block[
#block[
]
=== Data Environment
<data-environment>
- We often need to use data that we wish to save and recall.
- These will appear in the data environment in the top right pane.

]
#block[
#block[
]
=== Files
<files>
- When using an IDE we are required to define a file environment --- #emph[i.e.~telling the computer where to look for files we wish to load and save.]
- This is shown and changed in the Files tab in the bottom right pane.

]
== 📦 Packages
<packages>
#block[
#block[
]
=== What are packages?
<what-are-packages>
- Often we make our lives easier by using code written by the community for certain tasks --- #emph[e.g.~plot formatting, data manipulation, statistical analysis, etc.]
- This code can be found online as packages which we can load and use in our IDE.
- A list of the pre-installed packages can be found in the Packages tab in the bottom right pane.

]
== 🔧 Package Management
<package-management>
#block[
#block[
]
=== Package Management Functions
<package-management-functions>
To install a package (e.g.~#NormalTok("cowsay");) use the #NormalTok("install.packages()"); function:

#block[
#Skylighting(([#FunctionTok("install.packages");#NormalTok("(");#StringTok("\"cowsay\"");#NormalTok(")");],));
]
]
#block[
The package should now appear in the Packages tab. To use functions from the package we load them using the #NormalTok("library()"); function:

#block[
#Skylighting(([#FunctionTok("library");#NormalTok("(cowsay)");],));
]
]
#block[
Similarly, to remove the package we use the #NormalTok("remove.packages()"); function:

#block[
#Skylighting(([#FunctionTok("remove.packages");#NormalTok("(cowsay)");],));
]
]
== 🔧 Package Management (Alternative)
<package-management-alternative>
#block[
#block[
]
=== Manual Alternative
<manual-alternative>
Helpfully, R also has a manual library management tool which allows us to:

- Manually install packages using the button highlighted below.
- Select which libraries to load or unload with a check box.

]
#block[
#figure([
#box(image("static/images/package_management.png"))
], caption: figure.caption(
position: bottom, 
[
Package Management
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


]
= Quarto Documents
<quarto-documents>
== 📝 Quarto Basics
<quarto-basics>
#block[
#block[
]
In this course you will be required to use Quarto documents to generate PDFs for submission.

=== What is a Quarto document?
<what-is-a-quarto-document>
- Quarto documents generate a variety of document types --- such as PDFs, Word documents, PowerPoints, Beamer slides, HTML documents, etc. --- in RStudio.
- They use a language called Markdown for formatting.
- Allow you to add and run code chunks inside the document.
- Allow you to use mathematical expressions written using LaTeX.

]
== 📝 Quarto in RStudio
<quarto-in-rstudio>
To create a Quarto document in RStudio we use the new document button in the top left corner and select Quarto document.

#figure([
#box(image("static/images/new_quarto.png"))
], caption: figure.caption(
position: bottom, 
[
New Quarto Document
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


== 📝 Quarto Documents
<quarto-documents-1>
#block[
#block[
]
Then you will be met with the following pop-up menu asking you to specify the document type.

#figure([
#box(image("static/images/quarto_details.png", width: 2.60417in))
], caption: figure.caption(
position: bottom, 
[
Quarto Document Specification
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


]
#block[
From here you can specify you want a PDF document and give your document a title and author.

]
== 📚 Quarto Syntax
<quarto-syntax>
#block[
#block[
]
- Your TAs will help you with the details of Quarto's syntax. Additionally, you can find a template assignment Quarto document with the generated PDF on Canvas.
- The online documentation for Quarto --- providing a comprehensive summary of all of the syntax, including code annotation and LaTeX --- can be found here:

#figure([
#link("https://quarto.org/docs/output-formats/pdf-basics.html")[#box(image("static/images/quarto_logo.png"))]
], caption: figure.caption(
position: bottom, 
[
Read Quarto Documentation!
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


]
= Programming Concepts
<programming-concepts>
== 🧮 Calculations
<calculations>
#block[
#block[
]
=== Simple Calculations
<simple-calculations>
Fundamentally, R is a calculator allowing you to perform a wide variety of mathematical computations.

]
#block[
#block[
#Skylighting(([#DecValTok("6");#SpecialCharTok("+");#DecValTok("5");#NormalTok(" ");#CommentTok("# addition");],
[#DecValTok("6-5");#NormalTok(" ");#CommentTok("# subtraction");],
[#DecValTok("2");#SpecialCharTok("*");#DecValTok("4");#NormalTok(" ");#CommentTok("# multiplication");],
[#DecValTok("4");#SpecialCharTok("/");#DecValTok("2");#NormalTok(" ");#CommentTok("# division");],
[#DecValTok("2");#SpecialCharTok("^");#DecValTok("10");#NormalTok(" ");#CommentTok("# raising to power 10");],
[#FunctionTok("exp");#NormalTok("(");#DecValTok("2");#NormalTok(") ");#CommentTok("# applying the exponential function");],
[#FunctionTok("log");#NormalTok("(");#DecValTok("9");#NormalTok(") ");#CommentTok("# applying the natural log (ln)");],
[#FunctionTok("log10");#NormalTok("(");#DecValTok("1000");#NormalTok(") ");#CommentTok("# applying log base 10");],
[#FunctionTok("sqrt");#NormalTok("(");#DecValTok("64");#NormalTok(") ");#CommentTok("# computing the square root");],));
]
]
#block[
#block[
📌 The use of #NormalTok("#"); has made the text following the computations into a comment, which is not read as code.

]
]
== ❓ Help Function
<help-function>
#block[
#block[
]
One of my personal favorite functions in R is the #NormalTok("help()"); function or the #NormalTok("?"); function. With this function you can ask R's built-in code documentation reader to provide information on how a specific function works.

]
#block[
For example, suppose the function #NormalTok("sqrt()"); confused me. To read about how the code works we can write in the console:

#Skylighting(([#NormalTok("help(sqrt())");],
[#NormalTok("?sqrt()");],));
#block[
📌 Make sure to not include these functions in your writings for documents.

]
]
== 💪 Exercise --- R Calculations
<exercise-r-calculations>
Spend the next 3 minutes evaluating the following expressions in R:

+ $\( log_2 \( 256 \) + 2^3 \) \/ \( 4^2 - sqrt(64) \)$\; and
+ $exp \( 4 \) times 56 \( ln \( 7 \) - 3^3 \)$.

#block[
#block[
#Skylighting(([#NormalTok("(");#FunctionTok("log2");#NormalTok("(");#DecValTok("256");#NormalTok(") ");#SpecialCharTok("+");#NormalTok(" ");#DecValTok("2");#SpecialCharTok("^");#DecValTok("3");#NormalTok(") ");#SpecialCharTok("/");#NormalTok(" (");#DecValTok("4");#SpecialCharTok("^");#DecValTok("2");#NormalTok(" ");#SpecialCharTok("-");#NormalTok(" ");#FunctionTok("sqrt");#NormalTok("(");#DecValTok("64");#NormalTok("))");],));
]
#grid(
columns: (1fr), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
#Skylighting(([#NormalTok("[1] 2");],));
],
)
#block[
#Skylighting(([#FunctionTok("exp");#NormalTok("(");#DecValTok("4");#NormalTok(")");#SpecialCharTok("*");#DecValTok("56");#SpecialCharTok("*");#NormalTok("(");#FunctionTok("log");#NormalTok("(");#DecValTok("7");#NormalTok(")");#SpecialCharTok("-");#DecValTok("3");#SpecialCharTok("^");#DecValTok("3");#NormalTok(")");],));
#block[
#Skylighting(([#NormalTok("[1] -76602.79");],));
]
]
]
== 🔢 Data Types
<data-types>
Below is a list of some important R datatypes:

#block[
+ Numeric --- #emph[see examples above] --- including numbers, vectors, and matrices.

]
#block[
#block[
#set enum(numbering: "1.", start: 2)
+ Character --- any letter or number enclosed in either single quotes (#NormalTok("' '");) or double quotes (#NormalTok("\" \"");) becomes a character.
  - A sequential collection of characters forms a string --- this is not a specific datatype in R --- e.g.~#NormalTok("\"2+3*4\"");, #NormalTok("\"alphabet\"");.
]

]
#block[
#block[
#set enum(numbering: "1.", start: 3)
+ Logical --- a TRUE / FALSE output of some logical query.
]

]
== 🔣 Logic
<logic>
The following are the key logic symbols we use in R:

#block[
#block[
#block[
- #NormalTok("<"); --- less than
- #NormalTok(">"); --- greater than
- #NormalTok("<="); --- less than or equal to
- #NormalTok(">="); --- greater than or equal to

]
#block[
- #NormalTok("=="); --- equal to
- #NormalTok("!="); --- not equal to
- #NormalTok("|"); --- OR (or $union$ mathematically)
- #NormalTok("&"); --- AND (or $sect$ mathematically)

]
]
]
== 💪 Exercise --- Logic
<exercise-logic>
What will the following logical queries return?

#block[
+ #NormalTok("5 > 10");
+ #NormalTok("10 <= 10");
+ #NormalTok("13 != 12");
+ #NormalTok("\"Hello\" == \"Hello\"");
+ #NormalTok("\"Hello\" <= \"Hell\"");
+ #NormalTok("\"Goodbye\" != \"Hello\"");
+ #NormalTok("\"Hello\" != \"Hello\" | 5 < 10");
+ #NormalTok("4 <= 2 & 5 <= 12");
+ #NormalTok("3 < 5 < 7");

]
Spend 2 minutes evaluating the examples above in R and check your answers.

#block[
#block[
📌 Part 9 gives an error because we cannot combine logical expressions without using either #NormalTok("&"); or #NormalTok("|");.

]
]
== ✅ Solution --- Logic
<solution-logic>
#block[
#Skylighting(([#DecValTok("5");#NormalTok(" ");#SpecialCharTok(">");#NormalTok(" ");#DecValTok("10");],
[#DecValTok("10");#NormalTok(" ");#SpecialCharTok("<=");#NormalTok(" ");#DecValTok("10");],
[#DecValTok("13");#NormalTok(" ");#SpecialCharTok("!=");#NormalTok(" ");#DecValTok("12");],
[#StringTok("\"Hello\"");#NormalTok(" ");#SpecialCharTok("==");#NormalTok(" ");#StringTok("\"Hello\"");],));
]
#grid(
columns: (1fr, 1fr, 1fr, 1fr), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
#Skylighting(([#NormalTok("[1] FALSE");],));
],
  rect(stroke: none, width: 100%)[
#Skylighting(([#NormalTok("[1] TRUE");],));
],
  rect(stroke: none, width: 100%)[
#Skylighting(([#NormalTok("[1] TRUE");],));
],
  rect(stroke: none, width: 100%)[
#Skylighting(([#NormalTok("[1] TRUE");],));
],
)
#block[
#block[
#Skylighting(([#StringTok("\"Hello\"");#NormalTok(" ");#SpecialCharTok("<=");#NormalTok(" ");#StringTok("\"Hell\"");],
[#StringTok("\"Goodbye\"");#NormalTok(" ");#SpecialCharTok("!=");#NormalTok(" ");#StringTok("\"Hello\"");],
[#StringTok("\"Hello\"");#NormalTok(" ");#SpecialCharTok("!=");#NormalTok(" ");#StringTok("\"Hello\"");#NormalTok(" ");#SpecialCharTok("|");#NormalTok(" ");#DecValTok("5");#NormalTok(" ");#SpecialCharTok("<");#NormalTok(" ");#DecValTok("10");],
[#DecValTok("4");#NormalTok(" ");#SpecialCharTok("<=");#NormalTok(" ");#DecValTok("2");#NormalTok(" ");#SpecialCharTok("&");#NormalTok(" ");#DecValTok("5");#NormalTok(" ");#SpecialCharTok("<=");#NormalTok(" ");#DecValTok("12");],));
]
#grid(
columns: (1fr, 1fr, 1fr, 1fr), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
#Skylighting(([#NormalTok("[1] FALSE");],));
],
  rect(stroke: none, width: 100%)[
#Skylighting(([#NormalTok("[1] TRUE");],));
],
  rect(stroke: none, width: 100%)[
#Skylighting(([#NormalTok("[1] TRUE");],));
],
  rect(stroke: none, width: 100%)[
#Skylighting(([#NormalTok("[1] FALSE");],));
],
)
]
== ➡️ Assignment Operator
<assignment-operator>
#block[
#block[
]
Throughout this course the most frequently used operator will be the assignment operator #NormalTok("<-");, which assigns some value (of any datatype) to an object.

#block[
#Skylighting(([#NormalTok("x ");#OtherTok("<-");#NormalTok(" ");#StringTok("\"Hello World\"");],
[#NormalTok("y ");#OtherTok("<-");#NormalTok(" ");#DecValTok("6");#NormalTok(" ");#SpecialCharTok("<=");#NormalTok(" ");#DecValTok("7");],));
]
]
#block[
#block[
]
Notice that when you run the code above you receive no output, but the objects will have appeared in your data environment (top right tab).

#figure([
#box(image("static/images/environment.png"))
], caption: figure.caption(
position: bottom, 
[
Data Environment
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


]
== 🖨️ Print Function
<print-function>
#block[
#block[
]
If we wish to display an output we can print the object using the #NormalTok("print()"); function:

#block[
#Skylighting(([#FunctionTok("print");#NormalTok("(x)");],));
#block[
#Skylighting(([#NormalTok("[1] \"Hello World\"");],));
]
]
]
#block[
Although the same effect can be achieved by simply calling the object:

#block[
#Skylighting(([#NormalTok("x");],));
#block[
#Skylighting(([#NormalTok("[1] \"Hello World\"");],));
]
]
To see the additional functionality of #NormalTok("print()"); you can check the documentation using #NormalTok("?print");.

]
== ✅ Good Practices
<good-practices>
#block[
#block[
]
- Make sure your code is easy to read --- #emph[both for graders and for your own error checking] --- by documenting with comments and using good structure (such as indentation).

]
#block[
#block[
]
- When naming objects in R keep in mind the following conventions:
  - Letters, digits, underscores, and dots can all be used.
  - Object names cannot start with a digit or underscore.
  - Avoid starting object names with dots (doing so has special meaning).
  - Object names are case sensitive.
  - Use descriptive, logical, and efficient object names.

]
= Summary
<summary>
== ✅ Topics Covered
<topics-covered>
#block[
#block[
😵‍💫 Today was information overload.

]
]
#block[
We introduced ourselves to:

- R and RStudio #pause
- Quarto document generation #pause
- Packages #pause
- Calculations in R #pause
- Datatypes #pause
- Assignment operators

]
== 📅 Next Class
<next-class>
#block[
#block[
🤩 Next class we continue our introduction!

]
]
#block[
- Data structures #pause
- Filtering, recycling & sorting #pause
- Vectorizations

]



#bibliography(("static/references.bib"))

