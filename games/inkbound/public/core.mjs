export const TOOLS = [
  {name:'速写笔',en:'QUICK LINER',tag:'连续点绘',cap:28,reserve:168,rate:.13,power:26,range:48,pellets:1,spread:.011,reload:1.45},
  {name:'橡皮泵',en:'WIDE ERASER',tag:'近距扩散',cap:8,reserve:48,rate:.7,power:22,range:16,pellets:8,spread:.11,reload:1.85},
  {name:'针管笔',en:'PRECISION PEN',tag:'远距校准',cap:5,reserve:30,rate:1.05,power:130,range:70,pellets:1,spread:.001,reload:2.1},
  {name:'折纸尺',en:'PAPER RULER',tag:'近身划线',cap:Infinity,reserve:Infinity,rate:.48,power:100,range:3.4,pellets:1,spread:0,reload:0}
];
export const BLOCKS=[
 {x:-7,z:5,w:3.4,d:2.6,h:2.8,type:'book'}, {x:6,z:2,w:3,d:4,h:2.2,type:'eraser'},
 {x:-3,z:-6,w:5,d:2.2,h:2.3,type:'book'}, {x:10,z:-9,w:2.4,d:3,h:4.2,type:'pencil'},
 {x:-12,z:-10,w:3,d:3,h:4,type:'pencil'}, {x:12,z:11,w:3.2,d:2,h:2,type:'eraser'},
 {x:-13,z:13,w:2.5,d:3,h:2.1,type:'book'}, {x:1,z:-15,w:5,d:2,h:2,type:'book'}
];
export const clamp=(x,a,b)=>Math.max(a,Math.min(b,x));
export function moveBody(b,dx,dz,r=.4){
 const steps=Math.max(1,Math.ceil(Math.hypot(dx,dz)/.2));
 for(let n=0;n<steps;n++){
  b.x=clamp(b.x+dx/steps,-19+r,19-r);
  for(const q of BLOCKS) if(Math.abs(b.z-q.z)<q.d/2+r&&Math.abs(b.x-q.x)<q.w/2+r) b.x=b.x<q.x?q.x-q.w/2-r:q.x+q.w/2+r;
  b.z=clamp(b.z+dz/steps,-19+r,19-r);
  for(const q of BLOCKS) if(Math.abs(b.x-q.x)<q.w/2+r&&Math.abs(b.z-q.z)<q.d/2+r) b.z=b.z<q.z?q.z-q.d/2-r:q.z+q.d/2+r;
 }
}
export function rayBox(o,d,b){
 let lo=0,hi=Infinity;
 for(const [k,min,max] of [['x',b.x-b.w/2,b.x+b.w/2],['y',0,b.h],['z',b.z-b.d/2,b.z+b.d/2]]){
  if(Math.abs(d[k])<1e-8){if(o[k]<min||o[k]>max)return Infinity;continue;}
  let a=(min-o[k])/d[k],c=(max-o[k])/d[k]; if(a>c)[a,c]=[c,a]; lo=Math.max(lo,a);hi=Math.min(hi,c);if(lo>hi)return Infinity;
 }return lo;
}
export function raySphere(o,d,c,r){
 const x=o.x-c.x,y=o.y-c.y,z=o.z-c.z,b=x*d.x+y*d.y+z*d.z,q=x*x+y*y+z*z-r*r,disc=b*b-q;
 if(disc<0)return Infinity; const t=-b-Math.sqrt(disc);return t>=0?t:Infinity;
}
export class Simulation{
 constructor(seed=123){this.seed=seed;this.players={};this.enemies=[];this.drops=[];this.events=[];this.wave=0;this.time=0;this.breakTime=1;this.queue=0;this.spawnClock=0;this.nextId=1;this.total=0;this.cleared=0;this.ended=false;}
 random(){this.seed=(Math.imul(this.seed,1664525)+1013904223)>>>0;return this.seed/4294967296;}
 addPlayer(id){const n=Object.keys(this.players).length;const p={id,x:n*1.2,z:13,yaw:0,pitch:-.07,hp:100,score:0,cleared:0,tool:0,ammo:[28,8,5,0],reserve:[168,48,30,0],cooldown:0,reloading:0,invulnerable:1,combo:0,comboTime:0};this.players[id]=p;return p;}
 removePlayer(id){delete this.players[id];}
 emit(e){e.n=this.nextId++;this.events.push(e);if(this.events.length>70)this.events.shift();}
 changeTool(p,n){if(n>=0&&n<4&&n!==p.tool){p.tool=n;p.reloading=0;this.emit({type:'switch',player:p.id});}}
 reload(p){const w=TOOLS[p.tool];if(p.tool===3||p.reloading||p.ammo[p.tool]>=w.cap||p.reserve[p.tool]<=0)return false;p.reloading=w.reload;this.emit({type:'reload',player:p.id});return true;}
 startWave(){
 this.wave++;this.total=Math.min(30,4+this.wave*2+Math.max(0,Object.keys(this.players).length-1)*3);this.queue=this.total;this.cleared=0;this.spawnClock=0;
 for(const p of Object.values(this.players)){p.hp=Math.min(100,p.hp+18);p.invulnerable=1.5;p.ammo=[28,8,5,0];p.reserve=[168,48,30,0];p.reloading=0;}
 this.emit({type:'wave',wave:this.wave});
 }
 spawn(){
 const living=Object.values(this.players).filter(p=>p.hp>0);if(!living.length)return;
 const p=living[Math.floor(this.random()*living.length)];let x=0,z=-15;
 for(let i=0;i<25;i++){const a=this.random()*Math.PI*2;x=Math.sin(a)*17.2;z=Math.cos(a)*17.2;if(Math.hypot(x-p.x,z-p.z)>11&&!BLOCKS.some(b=>Math.abs(x-b.x)<b.w/2+1&&Math.abs(z-b.z)<b.d/2+1))break;}
 const type=this.wave>=3&&this.random()<.23?'heavy':this.wave>=2&&this.random()<.3?'runner':'drifter';
 const hp=type==='heavy'?175:type==='runner'?42:68;const r=type==='heavy'?1.05:type==='runner'?.5:.72;
 this.enemies.push({id:'e'+this.nextId++,x,z,type,hp,maxHp:hp,r,speed:(type==='runner'?2.3:type==='heavy'?.8:1.22)*(1+Math.min(.7,(this.wave-1)*.045)),phase:this.random()*6.28,stun:0});
 }
 useTool(p){
 if(p.hp<=0||p.cooldown>0||p.reloading||this.ended)return false;
 const w=TOOLS[p.tool];if(p.tool!==3&&p.ammo[p.tool]<=0){this.reload(p);return false;}
 if(p.tool!==3)p.ammo[p.tool]--;p.cooldown=w.rate;const origin={x:p.x,y:1.62,z:p.z};let hit=false;const endpoints=[];
 for(let i=0;i<w.pellets;i++){
  const yaw=p.yaw+(this.random()-.5)*w.spread*2,pitch=p.pitch+(this.random()-.5)*w.spread*2;
  const dir={x:-Math.sin(yaw)*Math.cos(pitch),y:Math.sin(pitch),z:-Math.cos(yaw)*Math.cos(pitch)};
  let limit=w.range;for(const b of BLOCKS)limit=Math.min(limit,rayBox(origin,dir,b));
  let target=null,distance=limit;
  for(const e of this.enemies){
   if(e.hp<=0)continue;let d=raySphere(origin,dir,{x:e.x,y:e.r+.15,z:e.z},e.r+.15);
   if(p.tool===3){const dx=e.x-p.x,dz=e.z-p.z,len=Math.hypot(dx,dz);const dot=(dx*dir.x+dz*dir.z)/Math.max(.01,len);if(len<w.range+e.r&&dot>.65)d=len;}
   if(d<distance){distance=d;target=e;}
  }
  if(target){target.hp-=w.power;target.stun=.13;hit=true;
   if(target.hp<=0){p.combo=p.comboTime>0?p.combo+1:1;p.comboTime=3.5;const pts=(target.type==='heavy'?200:100)+Math.min(p.combo-1,5)*20;p.score+=pts;p.cleared++;this.cleared++;
    this.emit({type:'clear',id:target.id,x:target.x,y:target.r,z:target.z,player:p.id,points:pts});
    if(this.random()<.19)this.drops.push({id:'d'+this.nextId++,x:target.x,z:target.z,life:20});
   }
  }
  endpoints.push({x:origin.x+dir.x*distance,y:origin.y+dir.y*distance,z:origin.z+dir.z*distance});
 }
 this.enemies=this.enemies.filter(e=>e.hp>0);this.emit({type:'use',player:p.id,tool:p.tool,x:p.x,z:p.z,endpoints,hit});return true;
 }
 step(dt,inputs={}){
 dt=clamp(dt,0,.05);if(this.ended)return;this.time+=dt;
 for(const p of Object.values(this.players)){
  if(p.hp<=0)continue;const i=inputs[p.id]||{};
  p.cooldown=Math.max(0,p.cooldown-dt);p.invulnerable=Math.max(0,p.invulnerable-dt);p.comboTime=Math.max(0,p.comboTime-dt);
  if(Number.isFinite(i.yaw))p.yaw=i.yaw;if(Number.isFinite(i.pitch))p.pitch=clamp(i.pitch,-1.3,1.3);
  if(Number.isInteger(i.tool))this.changeTool(p,i.tool);
  if(p.reloading>0){p.reloading-=dt;if(p.reloading<=0){const n=p.tool,add=Math.min(TOOLS[n].cap-p.ammo[n],p.reserve[n]);p.ammo[n]+=add;p.reserve[n]-=add;p.reloading=0;this.emit({type:'loaded',player:p.id});}}
  let f=clamp(i.forward||0,-1,1),s=clamp(i.strafe||0,-1,1),len=Math.hypot(f,s);if(len>1){f/=len;s/=len;}
  const speed=(i.sprint?7.4:4.6)*(i.aim?.55:1),dx=(-Math.sin(p.yaw)*f+Math.cos(p.yaw)*s)*speed*dt,dz=(-Math.cos(p.yaw)*f-Math.sin(p.yaw)*s)*speed*dt;
  moveBody(p,dx,dz);
  if(i.reload)this.reload(p);if(i.fire)this.useTool(p);
 }
 const living=Object.values(this.players).filter(p=>p.hp>0);if(Object.keys(this.players).length&&!living.length){this.ended=true;this.emit({type:'end'});return;}
 if(!living.length)return;
 if(this.queue===0&&this.enemies.length===0){this.breakTime-=dt;if(this.breakTime<=0){this.startWave();this.breakTime=6;}}
 if(this.queue>0){this.spawnClock-=dt;if(this.spawnClock<=0){this.spawn();this.queue--;this.spawnClock=Math.max(.42,1.45-this.wave*.07);}}
 for(const e of this.enemies){
  e.stun=Math.max(0,e.stun-dt);if(e.stun>0)continue;let target=living[0];for(const p of living)if(Math.hypot(p.x-e.x,p.z-e.z)<Math.hypot(target.x-e.x,target.z-e.z))target=p;
  let dx=target.x-e.x,dz=target.z-e.z,len=Math.hypot(dx,dz);if(len>.001){dx/=len;dz/=len;}
  for(const q of this.enemies){if(q===e)continue;const x=e.x-q.x,z=e.z-q.z,l=Math.hypot(x,z);if(l>0&&l<e.r+q.r+.25){dx+=x/l*.7;dz+=z/l*.7;}}
  const oldX=e.x,oldZ=e.z;moveBody(e,dx*e.speed*dt,dz*e.speed*dt,e.r*.8);
  if(Math.hypot(e.x-oldX,e.z-oldZ)<e.speed*dt*.2)moveBody(e,-dz*e.speed*dt,dx*e.speed*dt,e.r*.8);
  if(len<e.r+.65&&target.invulnerable<=0){target.hp=Math.max(0,target.hp-(e.type==='heavy'?20:10));target.invulnerable=.9;this.emit({type:'smudge',player:target.id,x:e.x,z:e.z});moveBody(e,-dx*.7,-dz*.7,e.r*.8);}
 }
 this.drops=this.drops.filter(d=>{d.life-=dt;for(const p of living)if(Math.hypot(p.x-d.x,p.z-d.z)<1.5){p.hp=Math.min(100,p.hp+12);for(let n=0;n<3;n++)p.reserve[n]+=TOOLS[n].cap;this.emit({type:'pickup',player:p.id});return false;}return d.life>0;});
 }
 snapshot(){return {players:this.players,enemies:this.enemies,drops:this.drops,wave:this.wave,total:this.total,cleared:this.cleared,queue:this.queue,breakTime:this.breakTime,time:this.time,ended:this.ended,events:this.events};}
}
