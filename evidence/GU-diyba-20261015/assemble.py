import json,os,sys
S='.staging'
ids=[b['id'] for b in json.load(open('evidence/GU-diyba-20261015/batches.json'))['batches']]
off=open('extensions/offline.lua',encoding='utf-8').read()
tail='return { extension, extension_card, extension_wz, extension_hl }'
assert off.rstrip().endswith(tail)
body=off.rstrip()[:-len(tail)]
ai=open('ai/offline-ai.lua',encoding='utf-8').read().rstrip()+'\n'
n=0
for i in ids:
    f=f'{S}/{i}/skills.lua'
    if os.path.exists(f):
        t=open(f,encoding='utf-8').read().strip()
        if t and not all(l.strip().startswith('--') or not l.strip() for l in t.split('\n')):
            body+=f'\n-- ===== diyba {i} =====\ndo\n{t}\nend\n'
    f=f'{S}/{i}/ai.lua'
    if os.path.exists(f):
        t=open(f,encoding='utf-8').read().strip()
        if t and not all(l.strip().startswith('--') or not l.strip() for l in t.split('\n')):
            ai+=f'\n-- ===== diyba {i} =====\ndo\n{t}\nend\n'
open('extensions/offline.lua','w',encoding='utf-8').write(body+'\n'+tail+'\n')
open('ai/offline-ai.lua','w',encoding='utf-8').write(ai)
