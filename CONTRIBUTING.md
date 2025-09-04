# CV

This repository contains the source files for my CV in **Polish** and
**English**. The CV is written in Markdown and converted to PDF using
[Pandoc](https://pandoc.org/) with the [Eisvogel LaTeX template](https://github.com/Wandmalfarbe/pandoc-latex-template).

## Structure

```bash
fmmaciej-cv/          
├─ assets/    # photos
├─ build/     # ourput 
├─ build.sh
├─ src/
│  ├─ cv-pl.md      # source
│  ├─ cv-en.md
│  └─ partials/
│     ├─ preamble.tex  # package, configuration
│     ├─ identity.tex  # data
│     ├─ lang-pl.tex   # language mapping
│     ├─ lang-en.tex
│     └─ header.tex    # tcolorbox z \cvname, \cvrole
└─ .vscode/
   ├─ tasks.json
   ├─ settings.json
   └─ extensions.json
```

## Requirements

To build the CV you need:

- [Pandoc](https://pandoc.org/)
- A LaTeX distribution with the **XeLaTeX** engine:
  - **Linux**: TeX Live (with `texlive-latex-extra`,
                              `texlive-fonts-recommended`,
                              `texlive-lang-european`)
  - **macOS**: [MacTeX](https://tug.org/mactex/) (via `brew install --cask mactex-no-gui`)
  - **Windows**: [MiKTeX](https://miktex.org/) (will auto-install missing packages)
- Common LaTeX packages required by Eisvogel (usually included in the above):
  `xcolor, geometry, fontawesome5, longtable, booktabs, array, graphicx,
   fancyhdr, lastpage, hyperref, ulem, KOMA-Script`

## Usage

The `build.sh` script builds the CV. Make sure it is executable:

```bash
chmod +x build.sh
```

**Run:**

```bash
./build.sh --en    # Build English CV (build/cv-en.pdf)
./build.sh --pl    # Build Polish CV (build/cv-pl.pdf)
./build.sh --all   # Build both versions
```

**Show help:**

```bash
./build.sh --help
```

**Output:**
The generated PDFs are placed in the `build/` directory:

- cv-en.pdf – English version
- cv-pl.pdf – Polish version

## License

This repository is personal.
Please do not reuse or redistribute the contents of my CV.
