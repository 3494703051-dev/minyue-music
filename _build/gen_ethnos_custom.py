#!/usr/bin/env python3
# 生成"民族音乐-畲塔怒鄂版"的定制合并数据文件 ethnos_custom.json
# 仅合并四民族：畲族(e20)、塔吉克族(e39)、怒族(e40)、鄂温克族(e43)
import json
import time
from pathlib import Path

BUILD = Path('/Users/qiaoyou/WorkBuddy/民族音乐/_build')
OUT = Path('/Users/qiaoyou/WorkBuddy/民族音乐/ethnos_custom.json')

GROUPS = [
    ('e20', '畲族'),
    ('e39', '塔吉克族'),
    ('e40', '怒族'),
    ('e43', '鄂温克族'),
]

merged = {
    'schema': 'ethnos_custom/v1',
    'app_name': '民族音乐-畲塔怒鄂版',
    'generated_at': time.strftime('%Y-%m-%d %H:%M:%S'),
    'note': '由 mountainriverechoes 官方曲库过滤生成，仅含畲族/塔吉克族/怒族/鄂温克族四个民族。',
    'groups': [],
    'total_songs': 0,
}

for key, name in GROUPS:
    src = BUILD / 'webui' / 'ethnos_cache' / f'{key}_{name}.json'
    data = json.loads(src.read_text(encoding='utf-8'))
    tracks = data.get('tracks') or []
    entry = {
        'key': key,
        'group': name,
        'declared_count': data.get('count'),
        'count': len(tracks),
        'built_at': data.get('built_at'),
        'kws': data.get('kws') or [],
        'source_file': src.name,
        'tracks': [
            {
                'song_name': t.get('song_name'),
                'singers': t.get('singers'),
                'album': t.get('album'),
                'source': t.get('source_cn') or t.get('source'),
                'ext': t.get('ext'),
                'duration': t.get('duration'),
            }
            for t in tracks
        ],
    }
    merged['groups'].append(entry)
    merged['total_songs'] += len(tracks)
    print(f'{name:<6} {key}  {len(tracks):>4} 首')

OUT.write_text(json.dumps(merged, ensure_ascii=False, indent=1), encoding='utf-8')
print(f'\ntotal = {merged["total_songs"]} 首')
print(f'written -> {OUT}  ({OUT.stat().st_size} bytes)')
