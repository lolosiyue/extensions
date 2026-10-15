import re,json
L=open('/workspace/finaldebug-md-ascii/diyba.md',encoding='utf-8').read().split('\n')
ent=re.compile(r'^\d+\. \*\*(.+?)\*\*')
starts=[i for i,l in enumerate(L) if ent.match(l) and 196<=i+1<=534]
done={'赵昂','陈寿','严舆','赵娥','梁习'}
items=[]
for k,s in enumerate(starts):
    e=starts[k+1] if k+1<len(starts) else min(s+12,534)
    j=s+1
    while j<e and (L[j].startswith('   ') or L[j].strip()=='' and j+1<e and L[j+1].startswith('   ')): j+=1
    items.append(dict(name=ent.match(L[s]).group(1),lo=s+1,hi=j))
skipped=[i for i in items if i['name'] in done]
todo=[i for i in items if i['name'] not in done]
out=[]
for n in range(0,len(todo),4):
    g=todo[n:n+4]
    out.append(dict(id=f"b{n//4+1:02d}",names=[x['name'] for x in g],ranges=[[x['lo'],x['hi']] for x in g]))
json.dump(dict(total=len(items),preskipped=[i['name'] for i in skipped],batches=out),open('evidence/GU-diyba-20261015/batches.json','w'),ensure_ascii=False,indent=1)
for b in out:
    open(f".staging/{b['id']}.excerpt.md",'w').write('\n\n'.join('\n'.join(L[lo-1:hi]) for lo,hi in b['ranges'])+'\n')
print(len(items),len(skipped),len(out))
