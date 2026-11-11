# Install atelier-software

atelier-software is a Claude Code plugin. It lives in one folder, `plugins/atelier-software/`, and the repository root is a Claude Code marketplace with the same name.

## Requirements

- Claude Code.
- Python 3.9 or newer, available as `python3` on your PATH. The CLI (`scripts/atelier.py`) uses the standard library only; there is nothing to `pip install`.
- Git is optional. The method works without it; some checks you write later, such as a test-tampering check, may use it.

Check Python:

```
python3 --version
```

On Windows, if `python3` is not found but `python` is, install Python from python.org with the "Add to PATH" option, or create a `python3` alias. The hooks and skills call `python3`.

## Install from inside Claude Code

```
/plugin marketplace add erkandmrbas/atelier-software
/plugin install atelier-software@atelier-software
```

The first command registers the repository as a marketplace named `atelier-software`. The second installs the plugin `atelier-software` from it. Restart Claude Code if it asks you to.

## Install from a shell

```
claude plugin marketplace add erkandmrbas/atelier-software
claude plugin install atelier-software@atelier-software
```

## Local development

To try a checkout without installing it, start Claude Code with the plugin folder:

```
git clone https://github.com/erkandmrbas/atelier-software.git
cd your-project
claude --plugin-dir /path/to/atelier-software/plugins/atelier-software
```

From the root of the atelier-software repository itself, `claude --plugin-dir ./plugins/atelier-software` works too. Changes to skills take effect in the next session.

## What you get

- 9 skills, called as `/atelier-software:<name>`: `start`, `interrogate`, `board`, `contract`, `dispatch`, `gate`, `draft-first`, `lessons`, `profile-software`. You normally run only `/atelier-software:start`; it loads `profile-software` and calls the others in order.
- 3 subagents: `atelier-software:worker` carries out one task card, `atelier-software:reviewer` measures it and writes the gate report, `atelier-software:researcher` reads the code and reports before the contract is written.
- 3 hooks, active only in projects that have a `.atelier/` folder:
  - **SessionStart** prints the board summary, integrity problems and the 10 most recent rejections at the top of each session.
  - **Stop** blocks the session from ending while a task is marked `done` without a passing gate, or while a lesson has repeated without a check.
  - **SubagentStop** blocks a worker whose final message names a task that is `in-progress` or `review` and has no complete handoff note.

The first time `start` runs in a repository, it creates `.atelier/` with its own copy of the CLI at `.atelier/bin/atelier.py` and the templates beside it. Every skill and subagent calls that project copy.

## Verify the install

1. Make an empty folder and open Claude Code there:

   ```
   mkdir atelier-try && cd atelier-try
   claude
   ```

2. Run `/atelier-software:start` and give it a small job, for example "add a `--version` flag to a small Python CLI".
3. The lead should run `init` and then start asking questions, each with a recommended answer.
4. In a shell in the same folder:

   ```
   ls .atelier
   python3 .atelier/bin/atelier.py status
   ```

   You should see `bin`, `board.md`, `checks`, `contract.md`, `gates`, `handoffs`, `lessons.md`, `rejections.md`, `shelf.md` and `tasks`, and `status` should print `No tasks yet.` followed by `Problems: none` until the lead writes the first card.

`/plugin` lists the installed plugin, and the skills appear as `/atelier-software:` in the command menu.

## Update

```
claude plugin marketplace update atelier-software
```

or `/plugin marketplace update atelier-software` from inside Claude Code. Then update `atelier-software@atelier-software` from `/plugin` if your version does not update installed plugins automatically.

Existing projects keep their own copy of the CLI in `.atelier/bin/`. To give a project the new CLI and templates, run `init` from the updated plugin inside that project: `python3 /path/to/atelier-software/plugins/atelier-software/scripts/atelier.py init`. Without `--force`, `init` refreshes `.atelier/bin/` and keeps your contract, board, lessons, rejections and shelf. `--force` overwrites those five files with blank templates; do not use it on a running job.

## Uninstall

```
claude plugin uninstall atelier-software@atelier-software
claude plugin marketplace remove atelier-software
```

From inside Claude Code: `/plugin uninstall atelier-software@atelier-software` and `/plugin marketplace remove atelier-software`.

Uninstalling never touches your projects. Each project's `.atelier/` folder and your global rejection log at `~/.atelier/rejections.md` stay where they are; delete them yourself if you no longer want them.
