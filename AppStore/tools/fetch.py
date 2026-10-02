import json, re, subprocess, urllib.parse, urllib.request, sys
cfg={}
for l in open('/Users/clot/Projects/TrackHobbies/Config/Secrets.xcconfig'):
    m=re.match(r'^(GAME_API_HOST|GAME_API_TOKEN)\s*=\s*(.*)$',l.strip())
    if m: cfg[m.group(1)]=m.group(2).strip()
def worker(path,q):
    u=f"https://{cfg['GAME_API_HOST']}{path}?q={urllib.parse.quote(q)}"
    for _ in range(3):
        try:
            r=urllib.request.Request(u,headers={'X-App-Token':cfg['GAME_API_TOKEN'],'User-Agent':'curl/8.7.1'})
            return json.load(urllib.request.urlopen(r,timeout=20))['results']
        except Exception as e: err=e
    print('ERR',q,err,file=sys.stderr); return []
def tvmaze(q):
    return json.load(urllib.request.urlopen('https://api.tvmaze.com/search/shows?q='+urllib.parse.quote(q),timeout=20))
out={'books':{}, 'series':{}, 'games':{}}
books=[("Dune","Frank Herbert"),("Neuromancer","William Gibson"),("Foundation","Isaac Asimov"),("Hyperion","Dan Simmons"),("El nombre del viento","Patrick Rothfuss"),("Project Hail Mary","Andy Weir"),("The Hobbit","J.R.R. Tolkien"),("Piranesi","Susanna Clarke"),("Klara and the Sun","Kazuo Ishiguro")]
for t,a in books:
    res=worker('/books/search',f"{t} {a}")
    sur=a.split()[-1].lower()
    ok=[r for r in res if r.get('coverURL') and r.get('numberOfPages') and sur in r['author'].lower() and t.lower().split()[0] in r['title'].lower()]
    out['books'][t]=ok[0] if ok else None
    print('book',t,'->',(ok[0]['title'],ok[0]['numberOfPages']) if ok else None)
for t in ["Dark","Severance","Breaking Bad","The Bear","Chernobyl","Arcane"]:
    r=tvmaze(t)
    s=next((x['show'] for x in r if x['show'].get('image') and x['show']['name'].lower()==t.lower()),None) or (r[0]['show'] if r else None)
    out['series'][t]={'title':s['name'],'imageURL':(s.get('image') or {}).get('original'),'id':str(s['id']),'summary':re.sub('<[^>]+>','',s.get('summary') or '')} if s else None
    print('series',t,'->',out['series'][t] and out['series'][t]['imageURL'])
for t in ["Hades","Disco Elysium","Celeste","Hollow Knight","Stardew Valley","The Legend of Zelda: Breath of the Wild"]:
    res=worker('/games/search',t)
    ok=[r for r in res if r.get('imageURL')]
    out['games'][t]=ok[0] if ok else None
    print('game',t,'->',(ok[0]['title'] if ok else None))
json.dump(out,open(sys.argv[1],'w'),ensure_ascii=False,indent=1)
