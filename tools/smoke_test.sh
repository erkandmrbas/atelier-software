#!/usr/bin/env bash
# End-to-end smoke test: one task goes from card to gate, the way a lead and two agents would run it.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export ATELIER_HOME="$WORK/home"
cd "$WORK"
python3 "$ROOT/plugins/atelier-software/scripts/atelier.py" init >/dev/null
A="python3 .atelier/bin/atelier.py"
$A new-task T-01 "Add health endpoint" >/dev/null
python3 - <<'PY'
import pathlib, re
p = pathlib.Path(".atelier/tasks/T-01.md")
t = p.read_text()
fill = {
    "Goal": "GET /health returns 200 with {\"ok\": true}.",
    "Constraints": "- Never change existing routes.",
    "Quality bar": "- Responds in under 50 ms on a local run.\n- 1 new test, 0 failing tests.",
    "Examples and references": "See the existing /version route.",
    "Approval checkpoint": "none",
    "Fixed decisions": "Use the existing router.",
    "Left open on purpose": "none",
}
for head, body in fill.items():
    t = re.sub(rf"(## {re.escape(head)}\n)(<!--.*?-->\n)?", rf"\g<1>{body}\n", t, count=1, flags=re.S)
t = t.replace("owner:\n", "owner: worker-1\n")
p.write_text(t)
PY
$A check-card T-01 >/dev/null
$A set-status T-01 in-progress >/dev/null
if $A set-status T-01 done >/dev/null 2>&1; then echo "FAIL: done allowed without gate"; exit 1; fi
$A new-handoff T-01 --author worker-1 >/dev/null
python3 - <<'PY'
import pathlib
p = pathlib.Path(".atelier/handoffs/T-01.md")
t = p.read_text()
for head in ["What was done", "Files changed", "Against the quality bar", "Not done or open issues", "How to verify"]:
    t = t.replace(f"## {head}\n", f"## {head}\nfilled for {head}\n", 1)
p.write_text(t)
PY
$A check-handoff T-01 >/dev/null
$A new-gate T-01 --reviewer worker-1 >/dev/null
sed -i.bak -e 's/^result: fail/result: pass/' -e 's/^## Measurements$/## Measurements\n- 12 ms, pass/' .atelier/gates/T-01.md
if $A gate T-01 >/dev/null 2>&1; then echo "FAIL: author reviewed own work"; exit 1; fi
sed -i.bak -e 's/^reviewer: worker-1/reviewer: reviewer-1/' .atelier/gates/T-01.md
$A gate T-01 >/dev/null
out="$($A status --strict)"; grep -q "done" <<<"$out"
$A lesson flaky-port "Test used a fixed port" >/dev/null
set +e; $A lesson flaky-port "Same again" >/dev/null; code=$?; set -e
[ "$code" = "3" ] || { echo "FAIL: second lesson did not demand a check (exit $code)"; exit 1; }
echo "smoke test passed"
