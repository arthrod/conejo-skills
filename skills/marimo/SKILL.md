---
name: marimo
description: Everything marimo — writing notebooks (cells, script-mode detection, reactivity), preparing them for scheduled batch runs (Pydantic params, CLI args, WandB), generating anywidget components, and checking WASM/Pyodide compatibility. Use for any marimo notebook task.
---

# Marimo — Notebooks, Batch Runs, Anywidget, WASM

| Concern | Section |
|---|---|
| Writing notebooks correctly | [Writing marimo notebooks](#writing-marimo-notebooks) |
| Making a notebook batch-runnable from CLI | [Batch-runnable notebooks](#batch-runnable-notebooks) |
| Generating anywidget components | [Anywidget generator](#anywidget-generator) |
| Checking WASM/Pyodide compatibility | [WASM compatibility](#wasm-compatibility-checker) |

---

# Writing marimo notebooks

## Running Marimo Notebooks

```bash
# Run as script (non-interactive, for testing)
uv run <notebook.py>

# Run interactively in browser
uv run marimo run <notebook.py>

# Edit interactively
uv run marimo edit <notebook.py>
```

## Script Mode Detection

Use `mo.app_meta().mode == "script"` to detect CLI vs interactive:

```python
@app.cell
def _(mo):
    is_script_mode = mo.app_meta().mode == "script"
    return (is_script_mode,)
```

## Key Principle: Keep It Simple

**Show all UI elements always.** Only change the data source in script mode.

- Sliders, buttons, widgets should always be created and displayed
- In script mode, just use synthetic/default data instead of waiting for user input
- Don't wrap everything in `if not is_script_mode` conditionals
- Don't use try/except for normal control flow

### Good Pattern

```python
# Always show the widget
@app.cell
def _(ScatterWidget, mo):
    scatter_widget = mo.ui.anywidget(ScatterWidget())
    scatter_widget
    return (scatter_widget,)

# Only change data source based on mode
@app.cell
def _(is_script_mode, make_moons, scatter_widget, np, torch):
    if is_script_mode:
        # Use synthetic data for testing
        X, y = make_moons(n_samples=200, noise=0.2)
        X_data = torch.tensor(X, dtype=torch.float32)
        y_data = torch.tensor(y)
        data_error = None
    else:
        # Use widget data in interactive mode
        X, y = scatter_widget.widget.data_as_X_y
        # ... process data ...
    return X_data, y_data, data_error

# Always show sliders - use their .value in both modes
@app.cell
def _(mo):
    lr_slider = mo.ui.slider(start=0.001, stop=0.1, value=0.01)
    lr_slider
    return (lr_slider,)

# Auto-run in script mode, wait for button in interactive
@app.cell
def _(is_script_mode, train_button, lr_slider, run_training, X_data, y_data):
    if is_script_mode:
        # Auto-run with slider defaults
        results = run_training(X_data, y_data, lr=lr_slider.value)
    else:
        # Wait for button click
        if train_button.value:
            results = run_training(X_data, y_data, lr=lr_slider.value)
    return (results,)
```

## Don't Guard Cells with `if` Statements

Marimo's reactivity means cells only run when their dependencies are ready. Don't add unnecessary guards:

```python
# BAD - the if statement prevents the chart from showing
@app.cell
def _(plt, training_results):
    if training_results:  # WRONG - don't do this
        fig, ax = plt.subplots()
        ax.plot(training_results['losses'])
        fig
    return

# GOOD - let marimo handle the dependency
@app.cell
def _(plt, training_results):
    fig, ax = plt.subplots()
    ax.plot(training_results['losses'])
    fig
    return
```

The cell won't run until `training_results` has a value anyway.

## Don't Use try/except for Control Flow

Don't wrap code in try/except blocks unless you're handling a specific, expected exception. Let errors surface naturally.

```python
# BAD - hiding errors behind try/except
@app.cell
def _(scatter_widget, np, torch):
    try:
        X, y = scatter_widget.widget.data_as_X_y
        X = np.array(X, dtype=np.float32)
        # ...
    except Exception as e:
        return None, None, f"Error: {e}"

# GOOD - let it fail if something is wrong
@app.cell
def _(scatter_widget, np, torch):
    X, y = scatter_widget.widget.data_as_X_y
    X = np.array(X, dtype=np.float32)
    # ...
```

Only use try/except when:
- You're handling a specific, known exception type
- The exception is expected in normal operation (e.g., file not found)
- You have a meaningful recovery action

## Cell Output Rendering

Marimo only renders the **final expression** of a cell. Indented or conditional expressions won't render:

```python
# BAD - indented expression won't render
@app.cell
def _(mo, condition):
    if condition:
        mo.md("This won't show!")  # WRONG - indented
    return

# GOOD - final expression renders
@app.cell
def _(mo, condition):
    result = mo.md("Shown!") if condition else mo.md("Also shown!")
    result  # This renders because it's the final expression
    return
```

## Marimo Variable Naming

Variables in `for` loops that would conflict across cells need underscore prefix:

```python
# Use _name, _model to make them cell-private
for _name, _model in items:
    ...
```

## PEP 723 Dependencies

```python
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "marimo",
#     "torch>=2.0.0",
# ]
# ///
```

## Prefer pathlib over os.path

Use `pathlib.Path` for file path operations instead of `os.path`:

```python
# GOOD - use pathlib
from pathlib import Path
data_dir = Path(tempfile.mkdtemp())
parquet_file = data_dir / "data.parquet"

# BAD - avoid os.path
import os
parquet_file = os.path.join(temp_dir, "data.parquet")
```


## marimo check 

When working on a notebook it is important to check if the notebook can run. That's why marimo provides a `check` command that acts as a linter to find common mistakes. 

```bash
uvx marimo check <notebook.py>
```

Make sure these are checked before handing a notebook back to the user.

## api docs

If the user specifically wants you to use a marimo function, you can locally check the docs via: 

```
uv --with marimo run python -c "import marimo as mo; help(mo.ui.form)"
```

## Additional resources

- For SQL use in marimo see [SQL.md](references/SQL.md)
- For UI elements in marimo [UI.md](references/UI.md)
- For exposing functions/classes as top level imports [TOP-LEVEL-IMPORTS.md](references/TOP-LEVEL-IMPORTS.md)

---

# Batch-runnable notebooks

Make a marimo notebook runnable as a scheduled batch job from the CLI while keeping the interactive UI.

## Pydantic source-of-truth

Declare the job's parameters as a Pydantic model:

```python
from pydantic import BaseModel, Field

class ModelParams(BaseModel):
    sample_size: int = Field(default=1024 * 4, description="Number of training samples per epoch.")
    learning_rate: float = Field(default=0.01, description="Learning rate for the optimizer.")
```

## UI form for interactive mode

```python
el = mo.md("""
{sample_size}
{learning_rate}
""").batch(
    sample_size=mo.ui.slider(1024, 1024 * 10, value=1024 * 4, step=1024, label="Sample size"),
    learning_rate=mo.ui.slider(0.001, 0.1, value=0.01, step=0.001, label="Learning rate"),
).form()
el
```

## CLI mode → same Pydantic model

```python
if mo.app_meta().mode == "script":
    model_params = ModelParams(
        **{k.replace("-", "_"): v for k, v in mo.cli_args().items()}
    )
else:
    model_params = ModelParams(**el.value)
```

Run from CLI:

```bash
uv run notebook.py --sample-size 4096 --learning-rate 0.005
```

**Verify with the user which params should be CLI-configurable** before editing the notebook.

## Weights & Biases (opt-in)

If WandB is requested, add `wandb_project` and `wandb_run_name` to `ModelParams`, and log the params at run start.

For ML training jobs, start from `references/starting-point.py` (when present). **Keep `column=N` annotations intact.**

## Environment variables

Use `python-dotenv` to read `.env`, plus `EnvConfig` for user-supplied keys in the UI:

```python
from wigglystuff import EnvConfig

config = EnvConfig({
    "OPENAI_API_KEY": lambda k: openai.Client(api_key=k).models.list(),
    "WANDB_API_KEY":  lambda k: wandb.login(key=k, verify=True),
})
config.require_valid()
config["OPENAI_API_KEY"]
config.get("OPENAI_API_KEY", "some default")
```

Place `EnvConfig` at the top of the notebook.

## Columns

If the notebook uses the columns feature for navigation, **keep them intact**:

```python
@app.cell(column=0, hide_code=True)
def _(mo):
    mo.md(r"""demo""")
```

---

# Anywidget generator

Vanilla JavaScript in `_esm`, paired `_css`, wrapped with `mo.ui.anywidget(...)`.

## Minimal example

```python
import anywidget
import traitlets

class CounterWidget(anywidget.AnyWidget):
    _esm = """
    function render({ model, el }) {
      let count = () => model.get("number");
      let btn = document.createElement("button");
      btn.innerHTML = `count is ${count()}`;
      btn.addEventListener("click", () => {
        model.set("number", count() + 1);
        model.save_changes();
      });
      model.on("change:number", () => {
        btn.innerHTML = `count is ${count()}`;
      });
      el.appendChild(btn);
    }
    export default { render };
    """
    _css = "button { font-size: 14px; }"
    number = traitlets.Int(0).tag(sync=True)

widget = mo.ui.anywidget(CounterWidget())
widget

# In another cell — widget.value is a dict
print(widget.value["number"])
```

## Best practices

1. **Vanilla JS in `_esm`** — `render({ model, el })`, `model.get/set/save_changes`, `model.on("change:trait", ...)`. End with `export default { render };`.
2. **Always include `_css`** — keep it minimal; support light + dark via `@media (prefers-color-scheme: dark) { ... }`.
3. **Wrap for display** — `widget = mo.ui.anywidget(OriginalAnywidget())`. Access values via `widget.value` (dict).
4. **External files for large widgets** — point `_esm`/`_css` at paths via `pathlib` when JS or CSS gets elaborate.
5. **Dumber is better** — obvious code beats clever abstractions. Reader should grok it top-to-bottom.

---

# WASM compatibility checker

Check whether a marimo notebook can run in WebAssembly (marimo playground, community cloud, exported WASM HTML).

## Step 1 — Read the notebook

Ask the user which notebook if not specified.

## Step 2 — Extract dependencies

From **both** sources:

- **PEP 723 metadata** (`# /// script` block at top)
- **Import statements** — map import names → PyPI distribution names:

  | Import | Distribution |
  |---|---|
  | `sklearn` | `scikit-learn` |
  | `skimage` | `scikit-image` |
  | `cv2` | `opencv-python` |
  | `PIL` | `Pillow` |
  | `bs4` | `beautifulsoup4` |
  | `yaml` | `pyyaml` |
  | `dateutil` | `python-dateutil` |
  | `attr` / `attrs` | `attrs` |
  | `gi` | `PyGObject` |
  | `serial` | `pyserial` |
  | `usb` | `pyusb` |
  | `wx` | `wxPython` |

## Step 3 — Check each package against Pyodide

1. **Stdlib?** Most works. Does NOT work: `multiprocessing`, `subprocess`, `sqlite3` (use `apsw`), `pdb`, `tkinter`, `readline`. `threading` is emulated → WARN.
2. **Pyodide built-in?** See `references/pyodide-packages.md` if available.
3. **Pure-Python wheel on PyPI** (`py3-none-any.whl`)? Installable via `micropip`. Examples: `plotly`, `seaborn`, `humanize`, `pendulum`, `arrow`, `tabulate`, `tenacity`, `backoff`.
4. **Native extensions?** FAIL. Common culprits: `torch`, `tensorflow`, `jax`, `psycopg2`, `mysqlclient`, `uvloop`, `grpcio`, `psutil`. Suggest replacements (`psycopg` pure mode, `pymysql`, `duckdb`).

## Step 4 — Incompatible code patterns

| Pattern | Fail reason | Fix |
|---|---|---|
| `subprocess.run`, `os.system`, `os.popen` | No process spawning | Remove or gate behind non-WASM check |
| `multiprocessing.Pool`, `ProcessPoolExecutor` | No forking | Single-threaded |
| `threading.Thread`, `ThreadPoolExecutor` | Emulated, no speedup | WARN — use `asyncio` for I/O |
| Hard-coded local file paths | Virtual fs only | Fetch via URL or embed |
| `sqlite3.connect` | stdlib sqlite3 unavailable | `apsw` or `duckdb` |
| `pdb.set_trace`, `breakpoint()` | No debugger | Remove |
| `os.environ`, `os.getenv` | Env vars unavailable | `mo.ui.text` or defaults |
| `Path.home`, `Path.cwd` with real-fs expectations | Virtual fs only | URLs or embedded data |
| Dataset loads > 100 MB | 2 GB total memory cap | Smaller samples / remote APIs |

## Step 5 — Check PEP 723 metadata

- **Missing `# /// script` block** → WARN, recommend adding it (auto-install on WASM startup).
- **Imported but not listed in dependencies** → WARN, suggest adding.
- Version pins are fine — marimo strips them in WASM.

## Step 6 — Report

**Compatibility: PASS / WARN / FAIL**
- **PASS** — all packages and patterns compatible
- **WARN** — likely OK, some packages unverified
- **FAIL** — one or more definitely incompatible

Output:
- **Package Report** table (Package | Status | Notes)
- **Code Issues** list (cell/line + fix)
- **Recommendations** — concrete swaps or rewrites

## Context
- WASM notebooks run via [Pyodide](https://pyodide.org)
- 2 GB memory cap
- CORS-compatible network requests work
- Chrome has best WASM perf; Firefox/Edge/Safari also supported
- `micropip` installs any pure-Python wheel from PyPI at runtime
