# CV

This repository contains the source files for my CV in **Polish** and
**English**. The CV is written in Markdown and converted to PDF using
[Pandoc](https://pandoc.org/) with the [Eisvogel LaTeX template](https://github.com/Wandmalfarbe/pandoc-latex-template).

## Structure

```bash
fmmaciej-cv/          
├─ assets/    # photos
├─ build/     # PDFs and diagnostic logs
├─ build.sh
├─ pandoc.yaml # shared Pandoc settings
├─ tools/update_eisvogel.py # template downloader
├─ src/
│  ├─ cv-pl.md      # source
│  ├─ cv-en.md
│  ├─ templates/    # upstream Eisvogel and version manifest
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

- [Pandoc](https://pandoc.org/) and Bash (3.2 or newer)
- A LaTeX distribution with the **XeLaTeX** engine:
  - **Linux**: TeX Live (with `texlive-latex-extra`,
                              `texlive-fonts-recommended`,
                              `texlive-lang-european`)
  - **macOS**: [MacTeX](https://tug.org/mactex/) (via `brew install --cask mactex-no-gui`)
  - **Windows**: [MiKTeX](https://miktex.org/) and Git Bash, or TeX Live in WSL
- Eisvogel's [required packages](https://github.com/Wandmalfarbe/pandoc-latex-template/tree/v3.5.1#required-latex-packages).
  Our partials additionally use `lmodern`, `fontawesome5`, `graphicx` and `tcolorbox` (including its skins library).

`--check` also requires [ShellCheck](https://www.shellcheck.net/).
`--update-eisvogel` requires Python 3.9 or newer and `curl`; normal builds work offline without Python.

Tested with Pandoc **3.12.1**, XeLaTeX from **TeX Live 2026**, Eisvogel **3.5.1** and Bash **3.2**.

## Usage

The `build.sh` script builds the CV. Make sure it is executable:

```bash
chmod +x build.sh
```

**Run:**

```bash
./build.sh --en    # Build English CV
./build.sh --pl    # Build Polish CV
./build.sh --all   # Build both versions
```

**Show help:**

```bash
./build.sh --help
```

**Output:**
The generated PDFs are placed in the `build/` directory:

- `cv-organisciak-maciej-en.pdf` – English version
- `cv-organisciak-maciej-pl.pdf` – Polish version

The script resolves paths relative to its own location. CVs build sequentially (EN, then PL); published PDFs are replaced only after all requested builds succeed. Full Pandoc and LaTeX output is saved in `build/en.log` and `build/pl.log`. Each language build overwrites its previous log.

## Checks and updates

```bash
./build.sh --check                  # Bash syntax, ShellCheck and both trial builds
./build.sh --update-eisvogel         # Latest stable release
./build.sh --update-eisvogel 3.5.1   # Specific release
```

Checks and template updates preserve the published PDFs. The updater verifies the archive SHA-256, extracts the standalone template and tries both CVs before installing it. Its version and checksums are recorded in `src/templates/eisvogel.version.json`.

Builds use a temporary directory inside `build/`, removed when the script exits, including on handled `INT` or `TERM`. Publishing rejects symbolic links as destinations, including dangling links.

Files are published sequentially with `mv`. A publication error or interruption can leave a partially updated pair. Rebuild the PDFs with `./build.sh --all`. To recover the template and manifest after an incomplete update, restore both from Git before retrying:

```bash
git restore -- src/templates/eisvogel.latex src/templates/eisvogel.version.json
```

Keep CV styling in `pandoc.yaml` and `src/partials/`; local edits to the upstream template block subsequent updates. After updating, run `--all` and review the page layout. Markdown linting remains available in VS Code.

Builds and updates share a lock at `build/.build-lock`. If an operation was killed without cleanup, remove that empty directory only after confirming no build or update is running.

## License

This repository is personal.
Please do not reuse or redistribute the contents of my CV.
