"""Local evidence gate. Does not call models, authenticate, or change application code."""
import argparse
import hashlib
import json
import math
import struct
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def now():
    return datetime.now(timezone.utc).isoformat()


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix('.tmp')
    temp.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    temp.replace(path)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def png_size(path):
    data = path.read_bytes()
    if len(data) < 33 or data[:8] != b'\x89PNG\r\n\x1a\n' or data[12:16] != b'IHDR':
        raise ValueError('Captura não é PNG válido: ' + path.name)
    return list(struct.unpack('>II', data[16:24]))


def fingerprint(root):
    digest = hashlib.sha256()
    selected = []
    for name in ('lib', 'test', 'integration_test', 'web', 'android', 'ios', 'functions', 'assets'):
        base = root / name
        if base.exists():
            selected.extend(p for p in base.rglob('*') if p.is_file()
                            and not any(x in p.relative_to(base).parts for x in
                                        ('build', '.gradle', '.dart_tool', 'node_modules', 'Pods', '.symlinks', 'ephemeral')))
    for name in ('pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'firebase.json',
                 'firestore.rules', 'firestore.indexes.json', 'storage.rules'):
        if (root / name).is_file():
            selected.append(root / name)
    for path in sorted(set(selected)):
        digest.update(path.relative_to(root).as_posix().encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()


class Harness:
    def __init__(self, root):
        self.root = root.resolve()
        self.manifest = read(root / 'harness/manifest.json')
        self.path = root / 'harness/state.json'
        self.state = read(self.path) if self.path.exists() else {
            'index': 0, 'attempts': {}, 'active': None, 'blocked': None, 'history': []}

    def save(self):
        write(self.path, self.state)

    def current(self):
        index = self.state['index']
        return self.manifest['units'][index] if index < len(self.manifest['units']) else None

    def begin(self):
        unit = self.current()
        if not unit or self.state['blocked']:
            raise ValueError('Sem unidade disponível ou execução bloqueada.')
        if self.state['active']:
            raise ValueError('Já existe tentativa ativa; continue ou submeta antes de iniciar outra.')
        count = self.state['attempts'].get(unit['id'], 0)
        if count >= self.manifest['max_attempts']:
            raise ValueError('Limite de tentativas atingido. Não zerar contador; escalar para revisão humana.')
        count += 1
        attempt = f"{unit['id']}/attempt-{count:02d}"
        folder = self.root / 'harness/evidence' / attempt
        folder.mkdir(parents=True, exist_ok=False)
        self.state['attempts'][unit['id']] = count
        self.state['active'] = {'id': attempt, 'started': now()}
        self.save()
        return folder

    def template(self):
        unit = self.current()
        active = self.state['active']
        if not active:
            raise ValueError('Execute begin primeiro.')
        doc = {'unit': unit['id'], 'attempt': active['id'], 'created_at': now(),
               'implementation_sha256': fingerprint(self.root),
               'reference_sha256': sha(self.root / unit['reference']) if unit['reference'] else None,
               'verdict': 'FAIL', 'implementer': '', 'visual_reviewer': '', 'functional_reviewer': '',
               'criteria': {k: False for k in unit['criteria']}, 'open_findings': ['Preencher após testes reais'],
               'artifacts': {'specification': '', 'functional_review': ''},
               'checks': [{'command': 'flutter analyze', 'exit_code': None, 'log': ''},
                          {'command': 'flutter test', 'exit_code': None, 'log': ''}]}
        if unit['reference']:
            doc['visual_scores'] = {k: 0 for k in self.manifest['visual_dimensions']}
            doc['capture'] = {'viewport': [0, 0], 'dpr': 1, 'text_scale': 1, 'reference_crop': [0, 0, 0, 0]}
            doc['artifacts'].update({'reference_crop': '', 'actual': '', 'comparison': '',
                                     'visual_review': '', 'alternate_viewport': ''})
        if unit['id'] == '99-INTEGRACAO':
            doc['artifacts']['regression'] = ''
            doc['artifacts']['release_report'] = ''
            doc['checks'].extend([{'command': 'flutter build web', 'exit_code': None, 'log': ''},
                                  {'command': 'flutter build apk --debug', 'exit_code': None, 'log': ''}])
        path = self.root / 'harness/evidence' / active['id'] / 'review.template.json'
        if path.exists():
            raise ValueError('Template já existe; preserve-o e crie review.json.')
        write(path, doc)
        return path

    def evidence_file(self, value):
        if not isinstance(value, str) or not value:
            raise ValueError('Caminho de evidência vazio.')
        path = (self.root / value).resolve()
        evidence = (self.root / 'harness/evidence' / self.state['active']['id']).resolve()
        if not path.is_relative_to(evidence) or not path.is_file() or not path.stat().st_size:
            raise ValueError('Evidência ausente, vazia ou fora da tentativa atual: ' + value)
        return path

    def validate(self, report):
        errors = []
        unit = self.current()
        active = self.state['active']
        if not unit or not active:
            return ['Nenhuma tentativa ativa.']
        if report.get('unit') != unit['id'] or report.get('attempt') != active['id']:
            errors.append('Unidade/tentativa incorreta.')
        if report.get('implementation_sha256') != fingerprint(self.root):
            errors.append('Hash do código mudou: recapturar e rever.')
        expected_ref = sha(self.root / unit['reference']) if unit['reference'] else None
        if report.get('reference_sha256') != expected_ref:
            errors.append('Referência incorreta ou alterada.')
        try:
            if datetime.fromisoformat(report['created_at']) < datetime.fromisoformat(active['started']):
                errors.append('Relatório anterior à tentativa.')
        except (KeyError, ValueError, TypeError):
            errors.append('Timestamp inválido.')
        if report.get('verdict') != 'PASS' or report.get('open_findings') != []:
            errors.append('Parecer reprovado ou pendências abertas.')
        for key in unit['criteria']:
            if report.get('criteria', {}).get(key) is not True:
                errors.append('Critério não verificado: ' + key)
        roles = ['implementer', 'functional_reviewer'] + (['visual_reviewer'] if unit['reference'] else [])
        identities = [report.get(k, '').strip() for k in roles]
        if any(not x for x in identities) or len(set(identities)) != len(identities):
            errors.append('Revisores devem ter identidades/sessões independentes informadas.')
        required = ['specification', 'functional_review']
        if unit['reference']:
            required += ['reference_crop', 'actual', 'comparison', 'visual_review', 'alternate_viewport']
            for key in self.manifest['visual_dimensions']:
                score = report.get('visual_scores', {}).get(key)
                if type(score) not in (int, float) or not math.isfinite(score) or not self.manifest['min_visual_score'] <= score <= 100:
                    errors.append('Nota visual insuficiente/inválida: ' + key)
            capture = report.get('capture', {})
            vp, crop = capture.get('viewport', []), capture.get('reference_crop', [])
            if (len(vp) != 2 or len(crop) != 4 or any(type(n) is not int for n in vp + crop)
                    or any(n <= 0 for n in vp) or any(n < 0 for n in crop[:2]) or vp != crop[2:]):
                errors.append('Viewport e recorte precisam ter dimensões idênticas e válidas.')
            if capture.get('dpr') != 1 or capture.get('text_scale') != 1:
                errors.append('Comparação canônica exige DPR/escala 1.')
        if unit['id'] == '99-INTEGRACAO':
            required += ['regression', 'release_report']
        resolved = {}
        for key in required:
            try:
                resolved[key] = self.evidence_file(report.get('artifacts', {}).get(key))
            except ValueError as exc:
                errors.append(str(exc))
        if unit['reference'] and 'actual' in resolved and 'reference_crop' in resolved:
            if sha(resolved['actual']) == sha(resolved['reference_crop']):
                errors.append('Captura é cópia exata da referência; verificar origem independente.')
            for key in ('actual', 'reference_crop'):
                try:
                    if png_size(resolved[key]) != report.get('capture', {}).get('viewport'):
                        errors.append('Dimensões PNG diferentes do viewport: ' + key)
                except ValueError as exc:
                    errors.append(str(exc))
            try:
                width, height = png_size(self.root / unit['reference'])
                x, y, cw, ch = report['capture']['reference_crop']
                if x + cw > width or y + ch > height:
                    errors.append('Recorte fora da prancha.')
            except (ValueError, KeyError, TypeError):
                errors.append('Prancha ou recorte inválido.')
        checks = report.get('checks', [])
        for prefix in ['flutter analyze', 'flutter test'] + (
                ['flutter build web', 'flutter build apk'] if unit['id'] == '99-INTEGRACAO' else []):
            if not any(c.get('command', '').startswith(prefix) for c in checks):
                errors.append('Check obrigatório ausente: ' + prefix)
        for check in checks:
            if type(check.get('exit_code')) is not int or check['exit_code'] != 0:
                errors.append('Check não passou: ' + check.get('command', '?'))
            try:
                self.evidence_file(check.get('log'))
            except ValueError as exc:
                errors.append(str(exc))
        return errors

    def submit(self, path):
        if self.state['blocked']:
            raise ValueError('Execução bloqueada; resolva o motivo antes de submeter.')
        report = read(path)
        if not self.state['active']:
            raise ValueError('Execute begin primeiro.')
        self.evidence_file(str(path))
        errors = self.validate(report)
        record = {'unit': self.current()['id'], 'attempt': self.state['active']['id'],
                  'timestamp': now(), 'accepted': not errors, 'errors': errors,
                  'report': str(path.relative_to(self.root)), 'report_sha256': sha(path)}
        self.state['history'].append(record)
        self.state['active'] = None
        if errors:
            if self.state['attempts'][self.current()['id']] >= self.manifest['max_attempts']:
                self.state['blocked'] = 'Limite de tentativas; exige diagnóstico e decisão humana.'
        else:
            self.state['index'] += 1
        self.save()
        return errors


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('command', choices=['status', 'next', 'begin', 'template', 'fingerprint', 'submit', 'block', 'resume'])
    parser.add_argument('value', nargs='?')
    args = parser.parse_args()
    h = Harness(ROOT)
    try:
        if args.command == 'status':
            print(json.dumps({'unit': h.current(), 'state': h.state}, ensure_ascii=False, indent=2))
        elif args.command == 'fingerprint':
            print(fingerprint(ROOT))
        elif args.command == 'next':
            if h.state['blocked']:
                print('BLOQUEADO: ' + h.state['blocked'])
            elif h.current():
                print((ROOT / h.current()['prompt']).read_text(encoding='utf-8'))
                if h.state['history'] and h.state['history'][-1].get('accepted') is False:
                    print('\nCorrigir a mesma unidade:\n' + '\n'.join(h.state['history'][-1]['errors']))
            else:
                print('Todas as unidades passaram pelos gates registrados. Conferir relatório final e limitações.')
        elif args.command == 'begin':
            print(h.begin())
        elif args.command == 'template':
            print(h.template())
        elif args.command == 'submit':
            if not args.value:
                raise ValueError('Informe o review.json.')
            errors = h.submit((ROOT / args.value).resolve())
            print('\n'.join(errors) if errors else 'APROVADO. Execute next.')
            return 1 if errors else 0
        elif args.command in ('block', 'resume'):
            if not args.value or len(args.value.strip()) < 12:
                raise ValueError('Informe motivo concreto com pelo menos 12 caracteres.')
            if args.command == 'resume' and h.current() and h.state['attempts'].get(h.current()['id'], 0) >= h.manifest['max_attempts']:
                raise ValueError('Limite esgotado: registrar nova decisão humana e novo plano, não reiniciar este ciclo.')
            h.state['blocked'] = args.value if args.command == 'block' else None
            h.state['history'].append({'event': args.command, 'reason': args.value, 'timestamp': now()})
            h.save()
            print('Estado salvo; nenhuma autenticação foi executada pelo harness.')
    except (ValueError, OSError, KeyError, TypeError, json.JSONDecodeError) as exc:
        print('ERRO: ' + str(exc))
        return 2
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
