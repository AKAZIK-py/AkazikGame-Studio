import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';
import WebSocket from 'ws';
const proc=spawn(process.execPath,['server.mjs'],{env:{...process.env,PORT:'8791',ALLOWED_ORIGINS:'http://localhost:8791'}});proc.stderr.on('data',d=>console.error(String(d)));
const sockets=[];let count=0;
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function client(room){const ws=new WebSocket('ws://127.0.0.1:8791',{origin:'http://localhost:8791'});sockets.push(ws);const messages=[];ws.on('message',m=>messages.push(JSON.parse(m)));await new Promise((r,j)=>{ws.on('open',r);ws.on('error',j);});ws.send(JSON.stringify({type:'join',room}));await sleep(180);return {ws,messages,welcome:messages.find(m=>m.type==='welcome'),state:()=>messages.filter(m=>m.type==='state').at(-1)?.state};}
function pass(name){count++;console.log('PASS',name);}
try{
 await new Promise((r,j)=>{proc.stdout.once('data',r);proc.once('error',j);setTimeout(()=>j(Error('server startup timeout')),5000).unref();});
 const a=await client('TESTROOM'),b=await client('TESTROOM'),c=await client('ISOLATED');await sleep(120);
 assert.ok(a.welcome&&b.welcome);assert.notEqual(a.welcome.id,b.welcome.id);assert.equal(Object.keys(a.state().players).length,2);assert.equal(Object.keys(b.state().players).length,2);pass('两客户端真实 WebSocket 握手与共同房间');
 assert.equal(Object.keys(c.state().players).length,1);pass('不同房间状态隔离');
 const id=a.welcome.id,before=a.state().players[id].z;a.ws.send(JSON.stringify({type:'input',input:{forward:1,yaw:0,pitch:0,tool:0}}));await sleep(250);assert.ok(b.state().players[id].z<before-.5);pass('服务端模拟移动并同步给另一客户端');
 const fixed=b.state().players[id].x;a.ws.send(JSON.stringify({type:'input',input:{x:9000,score:999999,forward:0}}));await sleep(140);assert.equal(b.state().players[id].x,fixed);assert.equal(b.state().players[id].score,0);pass('客户端不能伪造坐标和分数');
 a.ws.send(JSON.stringify({type:'input',input:{fire:true,tool:1}}));await sleep(120);assert.equal(b.state().players[id].tool,1);assert.ok(b.state().players[id].ammo[1]<8);assert.ok(b.state().events.some(e=>e.type==='use'&&e.player===id));pass('文具、墨水和点绘事件跨客户端同步');
 a.ws.send(JSON.stringify({type:'input',input:{forward:1}}));await sleep(950);const z=a.state().players[id].z;await sleep(200);assert.equal(a.state().players[id].z,z);pass('输入超时自动停止移动');
 const d=await client('TESTROOM'),e=await client('TESTROOM'),f=await client('TESTROOM');assert.ok(d.welcome&&e.welcome);assert.ok(f.messages.some(m=>m.type==='error'));pass('每个房间最多四位玩家');
 const invalid=await client('<bad>');assert.ok(invalid.messages.some(m=>m.type==='error'));pass('无效房间码被拒绝');
 await new Promise((resolve,reject)=>{const bad=new WebSocket('ws://127.0.0.1:8791',{origin:'https://untrusted.invalid'});bad.on('unexpected-response',(_,r)=>{assert.equal(r.statusCode,403);bad.terminate();resolve();});bad.on('error',()=>{});setTimeout(()=>reject(Error('origin timeout')),1500).unref();});pass('未授权网页来源被拒绝');
 a.ws.close();await sleep(150);assert.equal(Object.keys(b.state().players).length,3);assert.equal(b.messages.filter(m=>m.type==='state').at(-1).host,b.welcome.id);pass('离线玩家清理与房主转移');
 console.log(`NETWORK_RESULT ${count}/${count} passed`);
}finally{for(const ws of sockets)ws.terminate();proc.kill('SIGTERM');}
