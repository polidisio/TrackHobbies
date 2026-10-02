import json, re, sys, uuid, urllib.parse, urllib.request
from datetime import datetime, timedelta, timezone
SP=sys.argv[1]
cfg={}
for l in open('/Users/clot/Projects/TrackHobbies/Config/Secrets.xcconfig'):
    m=re.match(r'^(GAME_API_HOST|GAME_API_TOKEN)\s*=\s*(.*)$',l.strip())
    if m: cfg[m.group(1)]=m.group(2).strip()
def worker(path,q):
    u=f"https://{cfg['GAME_API_HOST']}{path}?q={urllib.parse.quote(q)}"
    for _ in range(4):
        try:
            r=urllib.request.Request(u,headers={'X-App-Token':cfg['GAME_API_TOKEN'],'User-Agent':'curl/8.7.1'})
            return json.load(urllib.request.urlopen(r,timeout=20))['results']
        except Exception: pass
    return []
raw=json.load(open(f'{SP}/store/raw.json'))
def exact(path,q,title,pages=None):
    for r in worker(path,q):
        if r['title']==title and (r.get('coverURL') or r.get('imageURL')) and (pages is None or r.get('numberOfPages')==pages): return r
    return None
raw['books']['Dune']=exact('/books/search','Dune Frank Herbert','Dune',450) or raw['books']['Dune']
raw['books']['Klara and the Sun']=exact('/books/search','Klara and the Sun Ishiguro','Klara and the Sun',320) or raw['books']['Klara and the Sun']
raw['games']['Disco Elysium']=exact('/games/search','Disco Elysium','Disco Elysium') or raw['games']['Disco Elysium']
raw['games']['The Legend of Zelda: Breath of the Wild']=exact('/games/search','Breath of the Wild','The Legend of Zelda: Breath of the Wild') or raw['games']['The Legend of Zelda: Breath of the Wild']
raw['books']['Hyperion']=exact('/books/search','Hyperion Dan Simmons','Hyperion') or raw['books']['Hyperion']
raw['books']['El nombre del viento']=exact('/books/search','The Name of the Wind Patrick Rothfuss','The Name of the Wind') or raw['books']['El nombre del viento']
print('hyperion:',raw['books']['Hyperion']['title'],raw['books']['Hyperion']['numberOfPages'],'| wind:',raw['books']['El nombre del viento']['title'],raw['books']['El nombre del viento']['numberOfPages'])
raw['books']['The Martian']=exact('/books/search','The Martian Andy Weir','The Martian')
print('martian:',raw['books']['The Martian'] and raw['books']['The Martian']['numberOfPages'])
now=datetime.now(timezone.utc).replace(microsecond=0)
def d(days): return (now-timedelta(days=days)).strftime('%Y-%m-%dT%H:%M:%SZ')
items=[]
def add(type_,title,status,src,**kw):
    it=dict(id=str(uuid.uuid4()).upper(),type=type_,title=title,status=status)
    if src:
        it['imageURL']=src.get('coverURL') or src.get('imageURL')
        if src.get('externalId'): it['externalId']=str(src['externalId'])
        if src.get('id') and type_!='book': it['externalId']=str(src['id'])
        if src.get('summary'): it['summary']=src['summary'][:600]
        if src.get('author'): it['authorOrCreator']=src['author']
    it.update(kw); items.append(it)
B=raw['books']
# --- Libros
add('book','Dune','completed',B['Dune'],authorOrCreator='Frank Herbert',userRating=5.0,totalPages=450,currentPage=450,startDate=d(26),endDate=d(11),lastUpdated=d(11),reviewComment='A sci-fi masterpiece: politics, religion and ecology in a single universe.')
add('book','Hyperion','inProgress',B['Hyperion'],authorOrCreator='Dan Simmons',totalPages=B['Hyperion']['numberOfPages'] or 482,currentPage=204,startDate=d(9),lastUpdated=d(0))
add('book','The Name of the Wind','inProgress',B['El nombre del viento'],authorOrCreator='Patrick Rothfuss',totalPages=B['El nombre del viento']['numberOfPages'] or 662,currentPage=288,startDate=d(21),lastUpdated=d(1))
add('book','Piranesi','completed',B['Piranesi'],authorOrCreator='Susanna Clarke',userRating=4.75,totalPages=231,currentPage=231,startDate=d(14),endDate=d(6),lastUpdated=d(6))
add('book','Foundation','completed',B['Foundation'],authorOrCreator='Isaac Asimov',userRating=4.5,totalPages=255,currentPage=255,startDate=d(40),endDate=d(33),lastUpdated=d(33))
add('book','Neuromancer','completed',B['Neuromancer'],authorOrCreator='William Gibson',userRating=4.25,totalPages=337,currentPage=337,startDate=d(70),endDate=d(60),lastUpdated=d(60))
add('book','Project Hail Mary','wishlist',B['Project Hail Mary'],authorOrCreator='Andy Weir',totalPages=497,lastUpdated=d(3))
add('book','Klara and the Sun','wishlist',B['Klara and the Sun'],authorOrCreator='Kazuo Ishiguro',totalPages=320,lastUpdated=d(4))
add('book','The Martian','notStarted',B['The Martian'],authorOrCreator='Andy Weir',totalPages=369,lastUpdated=d(8))
# --- Series
S=raw['series']
add('series','Severance','inProgress',S['Severance'],currentSeason=2,currentEpisode=4,totalSeasons=2,totalEpisodes=19,startDate=d(12),lastUpdated=d(0))
add('series','The Bear','inProgress',S['The Bear'],currentSeason=3,currentEpisode=2,totalSeasons=4,totalEpisodes=38,startDate=d(7),lastUpdated=d(2))
add('series','Dark','completed',S['Dark'],userRating=5.0,totalSeasons=3,totalEpisodes=26,startDate=d(50),endDate=d(18),lastUpdated=d(18),reviewComment='A time-travel puzzle that gets better every season.')
add('series','Chernobyl','completed',S['Chernobyl'],userRating=4.75,totalSeasons=1,totalEpisodes=5,startDate=d(20),endDate=d(16),lastUpdated=d(16))
add('series','Arcane','completed',S['Arcane'],userRating=4.5,totalSeasons=2,totalEpisodes=18,startDate=d(35),endDate=d(24),lastUpdated=d(24))
add('series','Breaking Bad','wishlist',S['Breaking Bad'],totalSeasons=5,totalEpisodes=62,lastUpdated=d(5))
# --- Juegos
G=raw['games']
add('game','Hades','inProgress',G['Hades'],timeSpentHours=18.5,startDate=d(10),lastUpdated=d(0))
add('game','Hollow Knight','inProgress',G['Hollow Knight'],timeSpentHours=31,startDate=d(25),lastUpdated=d(2))
add('game','Celeste','completed',G['Celeste'],userRating=4.5,timeSpentHours=9,startDate=d(30),endDate=d(22),lastUpdated=d(22))
add('game','Stardew Valley','completed',G['Stardew Valley'],userRating=4.75,timeSpentHours=62,startDate=d(80),endDate=d(45),lastUpdated=d(45))
add('game','The Legend of Zelda: Breath of the Wild','completed',G['The Legend of Zelda: Breath of the Wild'],userRating=5.0,timeSpentHours=120,startDate=d(120),endDate=d(70),lastUpdated=d(70),title_override=None)
add('game','Disco Elysium','wishlist',G['Disco Elysium'],lastUpdated=d(6))
for it in items:
    it.pop('title_override',None)
    it['status']={'inProgress':'in_progress','notStarted':'not_started'}.get(it['status'],it['status'])
json.dump({'version':1,'exportedAt':d(0),'items':items},open(f'{SP}/store/demo.json','w'),ensure_ascii=False,indent=1)
miss=[i['title'] for i in items if not i.get('imageURL')]
print(len(items),'items; sin portada:',miss)
