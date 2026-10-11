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

The script resolves paths relative to its own location. CVs build sequentially (EN, then PL); published PDFs are replaced only after all requested builds succeed. Full Pandoc and LaTeX output is saved under `build/diagnostics/run-*/`.

## Checks and updates

```bash
./build.sh --check                  # Bash syntax, ShellCheck and both trial builds
./build.sh --update-eisvogel         # Latest stable release
./build.sh --update-eisvogel 3.5.1   # Specific release
```

Checks and template updates preserve the published PDFs. The updater verifies the archive SHA-256, extracts the standalone template and tries both CVs before installing it. Its version and checksums are recorded in `src/templates/eisvogel.version.json`.

Before replacing both PDFs or the template and manifest, the script saves existing files under `build/diagnostics/run-*/backup/`. If a replacement fails, it restores the previous files and removes results that did not previously exist. If restoration fails, the error message points to the backups for manual recovery.

Pair replacement rejects symbolic links as destinations, including dangling links. An `INT` or `TERM` during replacement may trigger restoration. Restoration commands ignore these signals while the script records the interruption and defers exiting until the entire pair has been replaced or restored, then reports the result and diagnostic directory.

Keep CV styling in `pandoc.yaml` and `src/partials/`; local edits to the upstream template block subsequent updates. After updating, run `--all` and review the page layout. Markdown linting remains available in VS Code.

Builds and updates share a lock at `build/.build-lock`. If an operation was killed without cleanup, remove that empty directory only after confirming no build or update is running.

## License

This repository is personal.
Please do not reuse or redistribute the contents of my CV.
