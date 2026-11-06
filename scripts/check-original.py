import json
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
selected = {
    'lexical rather than caller scope', 'uninitialized variable',
    'global mutation in expression call', 'too many arguments',
    'expression call exception reaches caller catch',
    'return executes finally with current state', 'catch return executes finally',
    'no whitespace before unary minus', 'escaping closure',
    'factorial recursion', 'multiple function arguments', 'block shadowing',
}
cases = [c for c in json.loads((root / 'tests/cases.json').read_text()) if c['name'] in selected]
cases.insert(0, {'name': 'original lexical scope example', 'source': (root / 'test.java').read_text(), 'expected': 115})
results = []
with tempfile.TemporaryDirectory() as temporary:
    directory = Path(temporary)
    for filename in ('interpreter.rkt', 'functionParser.rkt', 'lex.rkt'):
        data = subprocess.check_output(['git', 'show', f'5faf614:{filename}'], cwd=root)
        (directory / filename).write_bytes(data)
    for case in cases:
        (directory / 'test.java').write_text(case['source'])
        try:
            run = subprocess.run(['racket', 'interpreter.rkt'], cwd=directory,
                                 capture_output=True, text=True, timeout=4)
            observed = dict(exit_code=run.returncode, stdout=run.stdout.strip(), stderr=run.stderr.strip())
        except subprocess.TimeoutExpired:
            observed = dict(timeout=True)
        results.append(dict(name=case['name'], expected=case.get('expected'), expected_error=case.get('error'), **observed))
report = {'source_commit': '5faf61446c7fe3203e0c89a653739eb7ce9ff76f', 'racket': subprocess.check_output(['racket', '--version'], text=True).strip(), 'results': results}
target = root / 'docs/original-baseline.json'
target.parent.mkdir(exist_ok=True)
target.write_text(json.dumps(report, indent=2) + '\n')
for item in results:
    print(item['name'], '=>', item.get('stdout', 'TIMEOUT'), 'exit', item.get('exit_code'))
