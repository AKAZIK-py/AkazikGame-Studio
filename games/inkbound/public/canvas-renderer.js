import * as T from './vendor/three.module.js';
// CPU fallback: the same Three.js scene, camera and geometry; no alternate game rules.
export class PaperCanvasRenderer{
 constructor(){this.domElement=document.createElement('canvas');this.ctx=this.domElement.getContext('2d');this.ratio=1;this.info={render:{calls:0,triangles:0}};this.isPaperFallback=true;const tile=document.createElement('canvas');tile.width=tile.height=8;const c=tile.getContext('2d');c.strokeStyle='#244c9a42';c.lineWidth=.65;c.beginPath();c.moveTo(-1,8);c.lineTo(8,-1);c.moveTo(7,9);c.lineTo(9,7);c.stroke();this.hatch=this.ctx.createPattern(tile,'repeat');this.matrix=new T.Matrix4();this.cameraMatrix=new T.Matrix4();}
 setPixelRatio(r){this.ratio=Math.min(r,1.3);}
 setClearColor(){}
 setSize(w,h){this.w=w;this.h=h;this.domElement.width=Math.round(w*this.ratio);this.domElement.height=Math.round(h*this.ratio);this.domElement.style.width=w+'px';this.domElement.style.height=h+'px';}
 project(p,camera){const e=camera.projectionMatrix.elements,z=Math.max(.08,-p[2]);return [this.w/2+p[0]*e[0]/z*this.w/2,this.h/2-p[1]*e[5]/z*this.h/2];}
 clip(poly){const out=[];for(let i=0;i<poly.length;i++){const a=poly[i],b=poly[(i+1)%poly.length],ai=a[2]<-.09,bi=b[2]<-.09;if(ai)out.push(a);if(ai!==bi){const t=(-.09-a[2])/(b[2]-a[2]);out.push([a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t,-.09]);}}return out;}
 render(scene,camera){
  const ctx=this.ctx,w=this.w,h=this.h;ctx.setTransform(this.ratio,0,0,this.ratio,0,0);ctx.globalAlpha=1;ctx.fillStyle='#f7f4e9';ctx.fillRect(0,0,w,h);scene.updateMatrixWorld();camera.updateMatrixWorld();this.cameraMatrix.copy(camera.matrixWorld).invert();const cmds=[],background=[];let tris=0;
  scene.traverseVisible(o=>{
   if(o.userData.skipCanvas)return;
   if(o.isSprite&&o.material.map){const v=new T.Vector3().setFromMatrixPosition(o.matrixWorld).applyMatrix4(this.cameraMatrix);if(v.z<-.1){const p=this.project([v.x,v.y,v.z],camera),scale=new T.Vector3();o.getWorldScale(scale);cmds.push({kind:'sprite',p,z:-v.z,img:o.material.map.image,width:scale.x*camera.projectionMatrix.elements[0]/-v.z*w/2,height:scale.y*camera.projectionMatrix.elements[5]/-v.z*h/2});}return;}
   if(!o.geometry?.attributes.position||(!o.isMesh&&!o.isLine))return;const pos=o.geometry.attributes.position,idx=o.geometry.index,mat=o.material;
   if(o.isMesh&&!mat.uniforms&&mat.color?.getHex()===0x244c9a&&!o.visible)return;
   const mv=new T.Matrix4().multiplyMatrices(this.cameraMatrix,o.matrixWorld),e=mv.elements,vertices=[];
   for(let i=0;i<pos.count;i++){const x=pos.getX(i),y=pos.getY(i),z=pos.getZ(i);vertices.push([e[0]*x+e[4]*y+e[8]*z+e[12],e[1]*x+e[5]*y+e[9]*z+e[13],e[2]*x+e[6]*y+e[10]*z+e[14]]);}
   if(o.isMesh){
    const count=idx?idx.count:pos.count;for(let i=0;i<count;i+=3){const a=vertices[idx?idx.getX(i):i],b=vertices[idx?idx.getX(i+1):i+1],c=vertices[idx?idx.getX(i+2):i+2];const clipped=this.clip([a,b,c]);if(clipped.length<3)continue;const pts=clipped.map(p=>this.project(p,camera));if(pts.every(p=>p[0]<0)||pts.every(p=>p[0]>w)||pts.every(p=>p[1]<0)||pts.every(p=>p[1]>h))continue;const ab=new T.Vector3(b[0]-a[0],b[1]-a[1],b[2]-a[2]),ac=new T.Vector3(c[0]-a[0],c[1]-a[1],c[2]-a[2]),n=ab.cross(ac).normalize();const hatch=mat.uniforms?.density?Math.max(0,(.6-n.y*.5-n.z*.4)*mat.uniforms.density.value):0;cmds.push({kind:'poly',pts,z:-(a[2]+b[2]+c[2])/3,fill:mat.uniforms?'#f7f4e9':mat.color?'#244c9a':'#f7f4e9',hatch});tris++;}
   }else{
    const step=o.isLineSegments?2:1;
    for(let i=0;i<vertices.length-1;i+=step){let a=vertices[i],b=vertices[i+1];if(a[2]>=-.09&&b[2]>=-.09)continue;if((a[2]<-.09)!==(b[2]<-.09)){const t=(-.09-a[2])/(b[2]-a[2]),p=[a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t,-.09];if(a[2]>=-.09)a=p;else b=p;}const pts=[this.project(a,camera),this.project(b,camera)];const cmd={kind:'line',pts,z:-(a[2]+b[2])/2-.012,alpha:mat.opacity??1};(o.userData.background?background:cmds).push(cmd);}
   }
  });
  const draw=c=>{if(c.kind==='sprite'){ctx.globalAlpha=.9;ctx.drawImage(c.img,c.p[0]-c.width/2,c.p[1]-c.height/2,c.width,c.height);return;}ctx.beginPath();ctx.moveTo(c.pts[0][0],c.pts[0][1]);for(let i=1;i<c.pts.length;i++)ctx.lineTo(c.pts[i][0],c.pts[i][1]);if(c.kind==='poly'){ctx.closePath();ctx.globalAlpha=1;ctx.fillStyle=c.fill;ctx.fill();if(c.hatch>.06){ctx.globalAlpha=Math.min(1,c.hatch*1.9);ctx.fillStyle=this.hatch;ctx.fill();}}else{ctx.globalAlpha=c.alpha;ctx.strokeStyle='#244c9a';ctx.lineWidth=.85;ctx.stroke();}};
  for(const c of background)draw(c);cmds.sort((a,b)=>b.z-a.z);for(const c of cmds)draw(c);ctx.globalAlpha=1;this.info.render={calls:cmds.length,triangles:tris};
 }
}
