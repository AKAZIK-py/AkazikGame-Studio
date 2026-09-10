import * as T from './vendor/three.module.js';
import {BLOCKS} from './core.mjs';
import {PaperCanvasRenderer} from './canvas-renderer.js';
const INK=0x244c9a,PAPER=0xf7f4e9;
const vshader=`varying vec3 vN; varying vec3 vW;void main(){vN=normalize(mat3(modelMatrix)*normal);vec4 w=modelMatrix*vec4(position,1.);vW=w.xyz;gl_Position=projectionMatrix*viewMatrix*w;}`;
const fshader=`varying vec3 vN;varying vec3 vW;uniform vec3 ink;uniform vec3 paper;uniform float density;void main(){float shade=dot(normalize(vN),normalize(vec3(-.5,1.,.8)));vec2 p=gl_FragCoord.xy;float wobble=sin(p.y*.13)*.9;float line=1.-smoothstep(.65,1.6,abs(mod(p.x+p.y*.73+wobble,7.)-3.5));float cross=1.-smoothstep(.4,1.3,abs(mod(p.x-p.y*.83,9.)-4.5));float h=line*smoothstep(.7,-.4,shade)*density+cross*smoothstep(-.2,-.8,shade)*.22;vec3 col=mix(paper,ink,clamp(h,0.,.65));gl_FragColor=vec4(col,1.);}`;
function material(density=.4){return new T.ShaderMaterial({vertexShader:vshader,fragmentShader:fshader,uniforms:{ink:{value:new T.Color(INK)},paper:{value:new T.Color(PAPER)},density:{value:density}}});}
const skin=material(.48),dark=material(.88),blueLine=new T.LineBasicMaterial({color:INK}),faintLine=new T.LineBasicMaterial({color:INK,transparent:true,opacity:.22});
function line(points,color=INK,opacity=1){return new T.Line(new T.BufferGeometry().setFromPoints(points.map(p=>new T.Vector3(...p))),new T.LineBasicMaterial({color,transparent:opacity<1,opacity}));}
function solid(geo,mat=skin){const g=new T.Group(),m=new T.Mesh(geo,mat);g.add(m);const edge=new T.EdgesGeometry(geo,24);g.add(new T.LineSegments(edge,blueLine));const echo=new T.LineSegments(edge,faintLine);echo.position.set(.017,.015,.012);g.add(echo);return g;}
function box(w,h,d,x,y,z,mat=skin){const g=solid(new T.BoxGeometry(w,h,d),mat);g.position.set(x,y,z);return g;}
function cylinder(r,h,x,y,z,n=8){const g=solid(new T.CylinderGeometry(r,r,h,n));g.position.set(x,y,z);return g;}
function textSprite(text,size=160){const c=document.createElement('canvas');c.width=1024;c.height=192;const ctx=c.getContext('2d');ctx.fillStyle='#244c9a';ctx.font=`italic ${size}px Georgia, serif`;ctx.textAlign='center';ctx.fillText(text,512,150);const tex=new T.CanvasTexture(c);tex.colorSpace=T.SRGBColorSpace;const s=new T.Sprite(new T.SpriteMaterial({map:tex,transparent:true,depthWrite:false}));s.scale.set(7.5,1.4,1);return s;}
export class SketchRenderer{
 constructor(container){
  this.container=container;const probe=document.createElement('canvas');const context=probe.getContext('webgl2',{antialias:true,alpha:true});this.renderer=context?new T.WebGLRenderer({canvas:probe,context,antialias:true,alpha:true}):new PaperCanvasRenderer();this.renderer.setPixelRatio(Math.min(devicePixelRatio,1.6));this.renderer.setClearColor(PAPER,1);this.renderer.outputColorSpace=T.SRGBColorSpace;container.prepend(this.renderer.domElement);this.renderer.domElement.id='world';
  this.scene=new T.Scene();this.camera=new T.PerspectiveCamera(72,1,.08,100);this.camera.rotation.order='YXZ';this.scene.add(this.camera);this.entities=new Map();this.remotes=new Map();this.drops=new Map();this.fx=[];this.recoil=0;this.toolIndex=-1;this.bob=0;this.aim=0;this.menu=true;this.menuTime=0;
  this.makeWorld();this.setTool(0);this.resize();this.observer=new ResizeObserver(()=>this.resize());this.observer.observe(container);
 }
 resize(){const w=this.container.clientWidth,h=this.container.clientHeight;this.renderer.setSize(w,h);this.camera.aspect=w/h;this.camera.updateProjectionMatrix();}
 quality(low){this.renderer.setPixelRatio(low?1:Math.min(devicePixelRatio,1.6));this.resize();}
 makeWorld(){
  const floorMat=new T.ShaderMaterial({vertexShader:vshader,fragmentShader:`varying vec3 vW;varying vec3 vN;void main(){float wave=sin(vW.x*1.3)*.012;float dist=abs(mod(vW.z+wave,1.5)-.75);float aa=max(fwidth(vW.z)*1.2,.013);float ruled=1.-smoothstep(.020,.020+aa,dist);float margin=1.-smoothstep(.026,.026+aa,abs(vW.x+16.5));vec3 paper=vec3(.955,.945,.90);vec3 ink=vec3(.10,.25,.54);vec3 col=mix(paper,ink,ruled*.34+margin*.42);gl_FragColor=vec4(col,1.);}`});
  const floor=new T.Mesh(new T.PlaneGeometry(44,44),floorMat);floor.rotation.x=-Math.PI/2;floor.position.y=-.02;floor.userData.skipCanvas=true;this.scene.add(floor);
  const base=box(42,.18,42,0,-.15,0);base.traverse(o=>o.userData.skipCanvas=true);this.scene.add(base);
  if(this.renderer.isPaperFallback){for(let z=-21;z<=21;z+=1.5){const ruled=line([[-21,0,z],[21,0,z]],INK,.30);ruled.userData.background=true;this.scene.add(ruled);}const margin=line([[-16.5,0,-21],[-16.5,0,21]],INK,.42);margin.userData.background=true;this.scene.add(margin);}
  for(let z=-18;z<20;z+=3){const pts=[];for(let a=0;a<=24;a++){const t=a/24*Math.PI*2;pts.push([-20.1+Math.cos(t)*.7,.04+Math.sin(t)*.45,z]);}this.scene.add(line(pts));}
  for(const b of BLOCKS){
   const g=new T.Group();g.position.set(b.x,0,b.z);
   if(b.type==='book'){
    g.add(box(b.w,b.h,b.d,0,b.h/2,0));g.add(box(b.w+.14,.12,b.d+.16,0,b.h+.04,0));
    for(let y=.22;y<b.h;y+=.25)g.add(line([[-b.w/2-.004,y,b.d/2+.016],[b.w/2,y+.025,b.d/2+.016]],INK,.4));
    g.add(line([[-b.w/2+.25,b.h+.105,-b.d/2],[ -b.w/2+.25,b.h+.105,b.d/2]]));
   }else if(b.type==='eraser'){
    g.add(box(b.w,b.h,b.d,0,b.h/2,0));g.add(box(b.w+.035,b.h+.02,b.d*.45,0,b.h/2,-.1,dark));
    for(let x=-b.w/2+.2;x<b.w/2;x+=.24)g.add(line([[x,b.h+.015,b.d*.24],[x+.3,b.h+.015,b.d*.42]],INK,.3));
   }else{
    g.add(box(b.w,b.h*.56,b.d,0,b.h*.28,0));
    for(let n=0;n<3;n++){const pen=cylinder(.23,b.h,(-1+n)*.65,b.h*.55,0,6);pen.rotation.z=(n-1)*.12;g.add(pen);const cap=solid(new T.ConeGeometry(.23,.7,6));cap.position.set((n-1)*.87,b.h*1.05+.3,0);g.add(cap);}
   }this.scene.add(g);
  }
  for(const [x,z,s] of [[-8,-19,1],[13,18,.8],[18,-2,1.1]]){
   const pts=[];for(let n=0;n<=40;n++){let a=n/40*Math.PI*2;pts.push([x+Math.cos(a)*1.1*s,.08,z+Math.sin(a)*2.5*s]);}this.scene.add(line(pts));
   const pts2=[];for(let n=0;n<=35;n++){let a=n/35*Math.PI*1.8;pts2.push([x+Math.cos(a)*.65*s,.1,z+Math.sin(a)*2*s]);}this.scene.add(line(pts2));
  }
  for(const side of [-1,1])for(let n=-18;n<=18;n+=3){const g=box(.12,.6,1.35,side*19.6,.3,n);this.scene.add(g);}
  for(let n=-18;n<=18;n+=3)this.scene.add(box(1.35,.6,.12,n,.3,-19.6));
  const label=textSprite('THE MARGIN',120);label.position.set(0,4.6,-19.5);this.scene.add(label);
  const small=textSprite('stay curious.',100);small.position.set(-14,5.8,-12);this.scene.add(small);this.worldLabels=[label,small];
  for(let i=0;i<5;i++){
   const x=(i-2)*9,z=-24-(i%2)*2,pts=[];
   for(let n=0;n<48;n++){const a=n/47*Math.PI*2;pts.push([x+Math.cos(a)*2.1*(1+.08*Math.sin(a*7)),8+i%2+Math.sin(a)*.65,z]);}
   this.scene.add(line(pts,INK,.25));
  }
 }
 blob(e){
  const g=new T.Group(),body=solid(new T.SphereGeometry(e.r,12,8),e.type==='heavy'?dark:skin);body.scale.set(1,1.08,.87);body.position.y=e.r+.1;g.add(body);
  const face=new T.Group();face.position.set(0,e.r+.16,e.r*.8);
  for(const x of [-.24,.24]){const pts=[];for(let n=0;n<18;n++){const t=n/17*Math.PI*2;pts.push([x*e.r*1.6+Math.cos(t)*e.r*.08,Math.sin(t)*e.r*.14,0]);}face.add(line(pts));}
  face.add(line([[-e.r*.18,-e.r*.23,0],[0,-e.r*.28,.01],[e.r*.18,-e.r*.23,0]]));g.add(face);
  for(let n=0;n<5;n++){let a=n/5*Math.PI*2;g.add(line([[Math.cos(a)*e.r*.8,.09,Math.sin(a)*e.r*.75],[Math.cos(a)*e.r*1.22,.08,Math.sin(a)*e.r*1.22],[Math.cos(a+.18)*e.r*1.35,.09,Math.sin(a+.18)*e.r*1.35]]));}
  if(e.type==='heavy'){const ring=solid(new T.TorusGeometry(e.r*.85,.075,4,12));ring.rotation.x=Math.PI/2;ring.position.y=e.r*1.78;g.add(ring);}
  if(e.type==='runner'){g.add(line([[-.25,e.r*2.1,0],[0,e.r*2.7,0],[.22,e.r*2.1,0]]));}
  const bar=new T.Mesh(new T.PlaneGeometry(e.r*1.7,.065),new T.MeshBasicMaterial({color:INK,side:T.DoubleSide}));bar.position.y=e.r*2.6+.1;bar.visible=false;g.add(bar);g.userData.bar=bar;return g;
 }
 setTool(index){
  if(index===this.toolIndex)return;this.toolIndex=index;if(this.tool){this.camera.remove(this.tool);this.disposeGeometry(this.tool);}const g=new T.Group();
  if(index===3){g.add(box(.15,1.2,.07,0,0,0));for(let y=-.5;y<.6;y+=.1)g.add(line([[-.072,y,.04],[.015,y,.04]]));g.rotation.z=-.4;}
  else{const r=index===1?.105:.045,len=index===2?.95:.72;const pen=cylinder(r,len,0,0,0,8);g.add(pen);const nib=solid(new T.ConeGeometry(r,.16,6));nib.position.y=len/2+.08;g.add(nib);g.add(cylinder(r*1.18,.06,0,len*.24,0));g.add(box(.026,len*.35,.035,r+.012,-len*.2,0));g.rotation.x=-1.15;g.rotation.z=-.18;}
  g.position.set(index===3?.42:.36,-.35,-.72);g.scale.setScalar(index===3?.62:.82);this.camera.add(g);this.tool=g;
 }
 disposeGeometry(g){g.traverse(o=>{if(o.geometry)o.geometry.dispose();if(o.material&&!['ShaderMaterial'].includes(o.material.type)&&o.material!==blueLine&&o.material!==faintLine){if(o.material.map)o.material.map.dispose();o.material.dispose();}});}
 flash(event,own){
  if(event.type==='use'){
   if(own)this.recoil=event.tool===1?.14:event.tool===3?.25:.08;
   for(const p of event.endpoints){const ray=line([[event.x,1.5,event.z],[p.x,p.y,p.z]],INK,.7);this.scene.add(ray);this.fx.push({obj:ray,life:.12,total:.12});}
  }
  if(event.type==='clear')for(let i=0;i<10;i++){
   const a=Math.random()*Math.PI*2;const o=line([[-.08,0,0],[.08,0,0],[0,0,0],[0,.13,0]],INK,.85);o.position.set(event.x,event.y,event.z);this.scene.add(o);this.fx.push({obj:o,life:.65,total:.65,v:new T.Vector3(Math.cos(a)*2,Math.random()*2+1,Math.sin(a)*2)});
  }
 }
 frame(state,player,dt,options={}){
  this.menuTime+=dt;this.setTool(player?.tool||0);const time=state.time||this.menuTime;for(const label of this.worldLabels)label.visible=!options.menu;
  const alive=new Set();for(const e of state.enemies){alive.add(e.id);let g=this.entities.get(e.id);if(!g){g=this.blob(e);this.scene.add(g);this.entities.set(e.id,g);}g.position.set(e.x,Math.sin(time*3.5+e.phase)*.055,e.z);g.rotation.y=Math.atan2((player?.x||0)-e.x,(player?.z||10)-e.z);g.rotation.z=Math.sin(time*4+e.phase)*.05;g.userData.bar.scale.x=Math.max(.01,e.hp/e.maxHp);g.userData.bar.visible=e.hp<e.maxHp;}
  for(const [id,g] of this.entities)if(!alive.has(id)){this.scene.remove(g);this.disposeGeometry(g);this.entities.delete(id);}
  const remoteIds=new Set();for(const p of Object.values(state.players)){if(p.id===player?.id||p.hp<=0)continue;remoteIds.add(p.id);let g=this.remotes.get(p.id);if(!g){g=cylinder(.28,1.6,0,.8,0,6);const badge=textSprite('FRIEND',80);badge.position.y=1.3;badge.scale.set(1.6,.3,1);g.add(badge);this.scene.add(g);this.remotes.set(p.id,g);}g.position.x=p.x;g.position.z=p.z;}
  for(const [id,g]of this.remotes)if(!remoteIds.has(id)){this.scene.remove(g);this.disposeGeometry(g);this.remotes.delete(id);}
  const ds=new Set();for(const d of state.drops){ds.add(d.id);let g=this.drops.get(d.id);if(!g){g=box(.45,.3,.3,0,.3,0);this.scene.add(g);this.drops.set(d.id,g);}g.position.set(d.x,.35+Math.sin(time*4)*.09,d.z);g.rotation.y=time;}
  for(const [id,g]of this.drops)if(!ds.has(id)){this.scene.remove(g);this.disposeGeometry(g);this.drops.delete(id);}
  for(let i=this.fx.length-1;i>=0;i--){const f=this.fx[i];f.life-=dt;if(f.v){f.obj.position.addScaledVector(f.v,dt);f.v.y-=dt*3;}f.obj.material.opacity=Math.max(0,f.life/f.total);if(f.life<=0){this.scene.remove(f.obj);this.disposeGeometry(f.obj);this.fx.splice(i,1);}}
  this.recoil=Math.max(0,this.recoil-dt*.5);
  if(options.menu){this.camera.position.set(9.2+Math.sin(this.menuTime*.05)*.8,10.2,21.2);this.camera.lookAt(.6,0,-3.2);this.camera.fov=47;this.tool.visible=false;}
  else if(player){
   this.tool.visible=true;this.camera.position.set(player.x,1.62+(options.moving?Math.sin(time*11)*.035:0),player.z);this.camera.rotation.set(player.pitch,player.yaw,0,'YXZ');const fov=options.aim?(player.tool===2?28:52):72;this.camera.fov+=(fov-this.camera.fov)*Math.min(1,dt*12);
   this.tool.position.set((options.aim?.1:.38)+Math.sin(time*5)*.003,-.32-this.recoil*.55-(player.reloading?Math.sin(player.reloading*3)*.12:0),-.65+this.recoil);
   if(player.tool===3)this.tool.rotation.z=-.4-this.recoil*5;
  }
  this.camera.updateProjectionMatrix();this.renderer.render(this.scene,this.camera);
 }
}
