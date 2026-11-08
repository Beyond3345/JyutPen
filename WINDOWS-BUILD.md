# Building the Windows installer

This guide builds the Windows installer of 粵筆 · JyutPen on a Windows
computer and adds it to a GitHub release that was made for macOS only. That
release comes from the build workflow started by hand with "release" ticked
and "windows" unticked (see "Building from source" in the README). The
examples use version 1.4.0; for another version, replace it everywhere.

Do not push a tag for the version from Windows. A pushed tag `v…` starts the
full workflow, which builds both installers again and makes a second draft
release. The tag of a release made by hand already exists once it is
published.

## What you need, once

- Windows 10 or 11, 64-bit
- [Git for Windows](https://git-scm.com/download/win), which brings Git Bash
- [Node.js](https://nodejs.org) LTS
- [Python](https://www.python.org/downloads/windows/) 3.13, with "Add
  python.exe to PATH" ticked
- [Rust](https://rustup.rs) with the stable `x86_64-pc-windows-msvc`
  toolchain, and the Microsoft C++ Build Tools with the "Desktop development
  with C++" workload, as in
  [Tauri's prerequisites](https://v2.tauri.app/start/prerequisites/)
- Microsoft Edge WebView2, which Windows 11 and updated Windows 10 include
- [GitHub CLI](https://cli.github.com), signed in with `gh auth login`, to
  upload the installer (or the GitHub website)

The first build downloads NSIS, Tectonic, the fonts and Pyodide, so the
computer needs internet access.

## 1. Get the sources

The three repositories sit side by side. The tool is checked out at the
release's tag, and xjyutping-py and xjyutping-tex at the commits that
`XJYUTPING_PY_COMMIT` and `XJYUTPING_TEX_COMMIT` give at the top of
`.github/workflows/build.yml` for that tag.

Keep Unix line endings first. Git for Windows converts them by default, and
the shell script of step 3 then fails:

```powershell
git config --global core.autocrlf false
```

Then, in PowerShell, in the folder that is to hold the three repositories:

```powershell
git clone https://github.com/Beyond3345/xjyutping-Tool
git clone https://github.com/Beyond3345/xjyutping-py
git clone https://github.com/Beyond3345/xjyutping-tex
git -C xjyutping-Tool checkout v1.4.0
Select-String -Path xjyutping-Tool\.github\workflows\build.yml -Pattern 'XJYUTPING_(PY|TEX)_COMMIT'
```

The last command prints the two commits. For 1.4.0 they are:

```powershell
git -C xjyutping-py checkout b24cf669fa9a980e838dd249bbfe37ef9e845bcf
git -C xjyutping-tex checkout 3c945828abca6ae573a7515f57a8f98f1f88a32f
```

If the repositories were cloned before, run `git fetch` in each of them
first.

## 2. Fetch the bundled files

In PowerShell, in `xjyutping-Tool`:

```powershell
npm ci
node scripts/vendor.mjs
```

`vendor.mjs` copies the Python package and the LaTeX package from the two
sibling repositories, and downloads Tectonic for Windows, the fonts and
Pyodide, each checked against a pinned sha256. It ends with a line such as
`vendor: ready for x86_64-pc-windows-msvc (… xjyutping-tex 1.5.4 …)`.

## 3. Check the PDF engine

In Git Bash, in `xjyutping-Tool`:

```bash
PYTHON=python scripts/compile-check.sh --engine-only
```

Every line must start with `ok`. The check compiles a sample lesson with the
bundled Tectonic for each audience and each font, as the workflow does
before it builds.

## 4. Build

In PowerShell, in `xjyutping-Tool`:

```powershell
npx tauri build --bundles nsis
```

The installer is
`src-tauri\target\release\bundle\nsis\JyutPen_1.4.0_x64-setup.exe`. The
build ignores `src-tauri/icons/AppIcon.icon`, which only macOS uses; Windows
gets `icon.ico`.

## 5. Test it

The built app tests itself. It loads every font, checks that the window fits
the screen, reads a sample lesson and compiles it to a PDF, then writes a
report and quits:

```powershell
cd src-tauri\target\release
$report = "$env:TEMP\jyutpen-self-test.txt"
$app = Start-Process -FilePath .\JyutPen.exe -ArgumentList '--self-test', $report -PassThru -Wait
Get-Content $report
$app.ExitCode
```

The report starts with `app 1.4.0, xjyutping-py 1.3.3, xjyutping-tex 1.5.4`
and ends with `self-test ok`, and the exit code is 0.

Then install `JyutPen_1.4.0_x64-setup.exe`, open JyutPen, type a line and
generate a PDF. If xjyutping-Tool is installed, uninstall it in Settings,
Apps, leaving "Delete the application data" unticked: JyutPen keeps using
that data (the lessons, settings and corrections).

## 6. Add it to the release

Upload the installer, from `xjyutping-Tool`:

```powershell
gh release upload v1.4.0 src-tauri\target\release\bundle\nsis\JyutPen_1.4.0_x64-setup.exe --repo Beyond3345/xjyutping-Tool
```

Then add Windows to the release notes, which were written for macOS only:

```powershell
gh release view v1.4.0 --repo Beyond3345/xjyutping-Tool --json body -q .body > notes.md
notepad notes.md
gh release edit v1.4.0 --repo Beyond3345/xjyutping-Tool --notes-file notes.md
```

In `notes.md`, under "Installing", add this line after the one for macOS:

```
- Windows 10 or 11: run `JyutPen_1.4.0_x64-setup.exe`; if SmartScreen warns about an unknown publisher, choose "More info", then "Run anyway".
```

Change "It does not need Python or TeX" in the last line to "Neither needs
Python or TeX".

Both can also be done on the website: on the release's page, choose Edit,
drop the installer onto the assets area, edit the notes, then choose Update
release.

## Without a Windows computer

GitHub can build the installer instead. Under Actions, build, choose "Run
workflow" on the release's tag, with "release" unticked and "windows"
ticked. When the run has passed, its artifacts hold the installer, which is
uploaded as in step 6.
