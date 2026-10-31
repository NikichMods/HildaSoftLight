# SPDX-License-Identifier: MPL-2.0
"""Deterministic source-only UE4SS candidate, VERSION is the semantic owner."""
from pathlib import Path
import argparse,hashlib,json,re,subprocess,zipfile
ROOT=Path(__file__).resolve().parents[1]
APPROVED='70bd93107584767a3993524bb003d4d7b28cd92867b54364c855bfda109420ea'
def digest(data):return hashlib.sha256(data).hexdigest()
def inputs():
    version=(ROOT/'VERSION').read_text(encoding='utf-8').strip()
    assert re.fullmatch(r'\d+\.\d+\.\d+(?:-[a-zA-Z0-9.]+)?',version),'VERSION format'
    main=(ROOT/'Scripts/main.lua').read_text(encoding='utf-8')
    assert re.search(r'local VERSION="([^"]+)"',main).group(1)==version,'Lua/VERSION mismatch'
    assert digest((ROOT/'DefaultProfile.ini').read_bytes())==APPROVED,'approved profile bytes changed'
    result={}
    for path in sorted((ROOT/'Scripts').glob('*.lua')):result['Scripts/'+path.name]=path.read_bytes()
    for name in ['DefaultProfile.ini','VERSION','LICENSE','LICENSING.md']:result[name]=(ROOT/name).read_bytes()
    result['README.txt']=(ROOT/'packaging/README.txt').read_bytes();result['enabled.txt']=b''
    assert ('Candidate '+version+':')in result['README.txt'].decode('utf-8'),'package instructions/VERSION mismatch'
    return version,result
def build(output,source):
    version,data=inputs()
    actual=subprocess.check_output(['git','rev-parse',source],cwd=ROOT,text=True).strip()
    for name,b in data.items():
        if name=='enabled.txt':continue
        original='packaging/README.txt'if name=='README.txt'else name
        assert b==subprocess.check_output(['git','show',actual+':'+original],cwd=ROOT),('uncommitted package input',original)
    output=Path(output).resolve();output.mkdir(parents=True,exist_ok=True)
    name='HildaSoftLight-'+version+'.zip';archive=output/name
    import io
    memory=io.BytesIO()
    with zipfile.ZipFile(memory,'w',compression=zipfile.ZIP_STORED)as z:
        for relative,b in sorted(data.items()):
            item=zipfile.ZipInfo('HildaSoftLight/'+relative,(2026,1,1,0,0,0));item.create_system=0;item.external_attr=0x20
            z.writestr(item,b)
    wire=memory.getvalue()
    if archive.exists():assert archive.read_bytes()==wire,'Frozen version/archive already exists with different bytes'
    else:archive.write_bytes(wire)
    manifest={'project':'HildaSoftLight','version':version,'stage':'candidate-not-stable','sourceCommit':actual,'archive':name,'archiveSha256':digest(wire),'files':{n:digest(b)for n,b in data.items()},'approvedProfileSha256':APPROVED}
    target=output/'manifest.json'
    if target.exists():assert json.loads(target.read_text())==manifest,'Frozen candidate identity differs'
    else:target.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8',newline='\n')
    (output/'SHA256SUMS.txt').write_text(manifest['archiveSha256']+'  '+name+'\n',encoding='utf-8',newline='\n')
    with zipfile.ZipFile(archive)as z:
        assert z.testzip()is None
        assert {n.removeprefix('HildaSoftLight/'):digest(z.read(n))for n in z.namelist()}==manifest['files']
    print(json.dumps({'archive':str(archive),'sha256':manifest['archiveSha256'],'source':actual,'files':len(data)},indent=2))
    return manifest
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--output',required=True);parser.add_argument('--source',default='HEAD');args=parser.parse_args();build(args.output,args.source)
