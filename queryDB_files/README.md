# 🗃️ Multimedia Archive Query Repository Toolchain

This sub-module manages, catalogs, and secures the historical query workspace context. It isolates analytical statements from data-modifying expressions to safeguard your production databases.

---

## 🗄️ Architectural Operations Workflow

### 🚀 1. Set Up the True Baseline Repository
If the tracking matrix gets corrupted or needs to be completely updated, this component clears out legacy indexes, compiles live optimizer metrics using SQLite `EXPLAIN QUERY PLAN`, wraps code inside structured user commentary strings, and loads rows straight into database registries:
```bash
python3 load_baseline.py
```

### 🗂️ 1.b. Formulate Beekeeper Studio Workspace Tab Blocks
To cleanly group your 272 queries into separate copy-pasteable files sorted strictly by execution type (SELECT, UPDATE, CREATE, etc.) to set up tab views inside your Beekeeper instance, run the tab generator:
```bash
python3 generate_workspace_tabs.py
```

### ⚡ 1.c. Audit and Resolve Performance Table Scans
To automatically parse your query logs, extract where-clause column variables, and generate a clean SQL indexing blueprint script targeting your slow unindexed fields, execute the advisor:
```bash
python3 index_optimization_advisor.py
```


### 🔐 2. Execute Queries Safely (Dynamic Router)
Our query execution tool functions as an automated dynamic safety gateway. It reads a given Query ID, detects its data modification parameters, and routes the work seamlessly:
* **`SELECT` / `WITH` Queries:** Execute directly against the Production Master Database file. This provides instant results without creating duplicate file clutter.
* **`UPDATE` / `DELETE` / `INSERT` Queries:** Automatically trigger a pre-run backup loop. If a copy doesn't exist for the day yet, it creates exactly **one** snapshot, points the execution straight to that backup destination, runs the changes there, and leaves your master database completely untouched.
```bash
python3 safe_query_runner.py Q-SEL-817CEFAE-1
```

### 📥 3. Add Incremental Queries Dynamically
To add a new query without rebuilding your base configuration file, use our incremental register loop. This version automatically executes a pre-run database optimizer check to append query performance properties straight into your final code headers:
```bash
python3 update_query_incremental.py "Q-SEL-INC01" "new_query" "SELECT" "Custom data filter" "multi_media_assets" "SELECT * FROM multi_media_assets LIMIT 5;" 0
```

### 📝 4. Append Maintenance Comments and Logs
To append operational logs or update explanations about specific code behaviors over time, inject a timestamped annotation directly:
```bash
python3 update_comments.py Q-UPD-9ADD3718-1 "Tested successfully inside daily sandbox snapshot."
```

---

## 📑 Automated Notebook Export
To compile all tracking rows, classification variables, and raw code definitions into an interactive markdown guide for human or AI reference, generate the dashboard summary report:
```bash
python3 generate_summary_report.py
```

---

## 🤖 AI Assistant Operations Charter
When working alongside an AI assistant in this repository:
1. Provide the assistant with this `README.md` file to load the toolchain architecture parameters.
2. Direct the AI to pull your active code statements directly from the tracking database: `SELECT sql_text FROM sys_query_repo WHERE query_id = 'Q-XXX-XXXX';`. This ensures the assistant always works with your true historical queries.
