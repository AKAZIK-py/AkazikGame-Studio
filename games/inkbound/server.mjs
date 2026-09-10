import {WebSocketServer} from 'ws';
import http from 'node:http';
import {randomUUID} from 'node:crypto';
import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {Simulation,clamp} from './core.mjs';
const PORT=Number(process.env.PORT||8787),HOST=process.env.HOST||'127.0.0.1';
const allowed=(process.env.ALLOWED_ORIGINS||`http://localhost:${PORT},http://127.0.0.1:${PORT}`).split(',');
const staticRoot=path.resolve(process.env.STATIC_DIR||fileURLToPath(new URL('./public',import.meta.url)));
const server=http.createServer(async(req,res)=>{
 if(req.url==='/health'){res.writeHead(200,{'Content-Type':'application/json'});res.end(JSON.stringify({ok:true,rooms:rooms.size}));return;}
 try{const pathname=decodeURIComponent(new URL(req.url,'http://localhost').pathname),file=path.resolve(staticRoot,'.'+(pathname==='/'?'/index.html':pathname));if(!file.startsWith(staticRoot+path.sep))throw Error('path');const data=await readFile(file);const types={'.html':'text/html; charset=utf-8','.js':'text/javascript','.mjs':'text/javascript','.css':'text/css','.zip':'application/zip','.md':'text/plain; charset=utf-8'};res.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream','X-Content-Type-Options':'nosniff'});res.end(data);}catch{res.writeHead(404);res.end('Not found');}
});
const wss=new WebSocketServer({noServer:true,maxPayload:2048,perMessageDeflate:false}),rooms=new Map();
server.on('upgrade',(req,socket,head)=>{if(!allowed.includes(req.headers.origin)){socket.write('HTTP/1.1 403 Forbidden\r\nConnection: close\r\n\r\n');socket.destroy();return;}wss.handleUpgrade(req,socket,head,ws=>wss.emit('connection',ws,req));});
function send(ws,m){if(ws.readyState===1&&ws.bufferedAmount<250000)ws.send(JSON.stringify(m));}
function error(ws,message){send(ws,{type:'error',message});}
wss.on('connection',ws=>{
 ws.id=randomUUID().slice(0,8);ws.isAlive=true;ws.rate=0;ws.lastInput=Date.now();const joinTimer=setTimeout(()=>{if(!ws.room)ws.close(1008,'join timeout');},7000);
 ws.on('pong',()=>ws.isAlive=true);
 ws.on('message',raw=>{
  if(++ws.rate>100){ws.close(1008,'rate limit');return;}let m;try{m=JSON.parse(raw);}catch{return error(ws,'消息格式不正确');}
  if(m.type==='join'){
   if(ws.room)return;const code=String(m.room||'').toUpperCase();if(!/^[A-Z0-9]{6,12}$/.test(code))return error(ws,'房间码不符合要求');
   let r=rooms.get(code);if(!r){if(rooms.size>=80)return error(ws,'服务房间已满');r={sim:new Simulation(Math.floor(Math.random()*1e8)),clients:new Map(),inputs:{},host:ws.id,code};r.sim.breakTime=3;rooms.set(code,r);}
   if(r.clients.size>=4)return error(ws,'这一页已经有 4 位朋友了');
   r.clients.set(ws.id,ws);r.sim.addPlayer(ws.id);ws.room=r;clearTimeout(joinTimer);send(ws,{type:'welcome',id:ws.id,room:code,host:r.host===ws.id});return;
  }
  if(m.type==='ping')return send(ws,{type:'pong',at:m.at});
  const r=ws.room;if(!r)return;
  if(m.type==='input'){
   const i=m.input||{},f=n=>Number.isFinite(n)?n:0;
   r.inputs[ws.id]={forward:clamp(f(i.forward),-1,1),strafe:clamp(f(i.strafe),-1,1),yaw:f(i.yaw)%(Math.PI*2),pitch:clamp(f(i.pitch),-1.3,1.3),tool:clamp(Math.round(f(i.tool)),0,3),sprint:!!i.sprint,aim:!!i.aim,fire:!!i.fire,reload:!!i.reload};ws.lastInput=Date.now();
  }
  if(m.type==='restart'&&r.host===ws.id&&r.sim.ended){r.sim=new Simulation(Date.now()>>>0);for(const id of r.clients.keys())r.sim.addPlayer(id);r.inputs={};}
 });
 ws.on('close',()=>{clearTimeout(joinTimer);const r=ws.room;if(r){r.clients.delete(ws.id);r.sim.removePlayer(ws.id);delete r.inputs[ws.id];if(!r.clients.size)rooms.delete(r.code);else if(r.host===ws.id)r.host=r.clients.keys().next().value;}});
 ws.on('error',()=>{});
});
let frame=0,last=performance.now();const tick=setInterval(()=>{const now=performance.now(),dt=Math.min(.05,(now-last)/1000);last=now;
 for(const r of rooms.values()){
  for(const [id,ws]of r.clients)if(Date.now()-ws.lastInput>600){const old=r.inputs[id]||{};r.inputs[id]={yaw:old.yaw,pitch:old.pitch,tool:old.tool};}
  r.sim.step(dt,r.inputs);if(frame%3===0){const message={type:'state',state:r.sim.snapshot(),host:r.host};for(const ws of r.clients.values())send(ws,message);}
 }frame++;
},1000/60);
const rate=setInterval(()=>{for(const ws of wss.clients)ws.rate=0;},1000);
const heartbeat=setInterval(()=>{for(const ws of wss.clients){if(!ws.isAlive){ws.terminate();continue;}ws.isAlive=false;ws.ping();}},15000);
server.listen(PORT,HOST,()=>console.log(`INKBOUND server http://${HOST}:${PORT} — allowed origins: ${allowed.join(', ')}`));
process.on('SIGTERM',()=>{clearInterval(tick);clearInterval(rate);clearInterval(heartbeat);wss.close();server.close();});
