"""Reproducible local authority, real-client, latency, gateway and load checks."""
from pathlib import Path
import argparse,os,subprocess,tempfile,time,signal
parser=argparse.ArgumentParser();parser.add_argument('--only',default='');parser.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'));args=parser.parse_args()
root=Path(__file__).resolve().parents[1];logs=root/'network_tests'/'runs';logs.mkdir(exist_ok=True)
def run(command,env,name,timeout=60):
 with open(logs/(name+'.log'),'w') as log:
  result=subprocess.run(command,cwd=root,env=env,stdout=log,stderr=log,timeout=timeout)
 text=(logs/(name+'.log')).read_text()
 if result.returncode or 'ERROR:' in text:raise RuntimeError(name+' failed:\n'+text[-4000:])
 print(name+' passed',flush=True);return text
with tempfile.TemporaryDirectory(prefix='fx-net-tests-') as data:
 env={**os.environ,'GODOT_BIN':args.godot,'FX_PROJECT_ROOT':str(root),'XDG_DATA_HOME':data,'PORT':'9080'}
 if not args.only:run([args.godot,'--headless','--path',str(root),'--script',str(root/'network_tests/combat.gd')],env,'combat')
 for check in ([] if args.only else ['local_prediction','buffered_world','t4_collision']):
  run([args.godot,'--headless','--path',str(root),'--script',str(root/'network_tests'/(check+'.gd'))],env,check)
 for name in ['connection.test','actual_client.test','latency.test','gateway.test','two_views.test','benchmark','reliability.test']:
  if args.only and name not in args.only.split(','):continue
  log=open(logs/(name+'-server.log'),'w')
  server=subprocess.Popen(['node',str(root/'network_service/gateway.mjs')],cwd=root/'network_service',env=env,stdout=log,stderr=log,start_new_session=True)
  try:
   for n in range(100):
    if 'authority listening' in (logs/(name+'-server.log')).read_text():break
    if server.poll() is not None:raise RuntimeError('Server exited before ready')
    time.sleep(.1)
   text=run(['node',str(root/'network_tests'/(name+'.mjs'))],env,name)
   print(text[-1000:],flush=True)
  finally:
   os.killpg(server.pid,signal.SIGTERM) if server.poll() is None else None
   server.wait(timeout=5);log.close()
  if 'ERROR:' in (logs/(name+'-server.log')).read_text():raise RuntimeError('Authority errors: '+name)
print('NETWORK ALPHA SUITE PASSED',flush=True)
