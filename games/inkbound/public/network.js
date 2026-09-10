export class RoomClient{
 constructor(){this.ws=null;this.id=null;this.state=null;this.connected=false;this.latency=0;this.host=false;this.onstate=()=>{};this.onclose=()=>{};}
 connect(address,room){
  return new Promise((resolve,reject)=>{
   let url;try{url=new URL(address);}catch{return reject(new Error('请输入有效的 WebSocket 服务地址'));}
   if(!['ws:','wss:'].includes(url.protocol))return reject(new Error('地址必须以 wss:// 开头（本地调试可用 ws://）'));
   if(location.protocol==='https:'&&url.protocol!=='wss:')return reject(new Error('当前是 HTTPS 页面，请使用启用 TLS 的 wss:// 服务'));
   if(!/^[A-Z0-9]{6,12}$/.test(room))return reject(new Error('房间码需为 6–12 位英文字母或数字'));
   this.disconnect();let settled=false;const ws=new WebSocket(url);this.ws=ws;
   const timer=setTimeout(()=>{if(!settled){settled=true;reject(new Error('连接超时：请确认服务在线、TLS 与来源白名单已配置'));ws.close();}},7000);
   ws.onopen=()=>ws.send(JSON.stringify({type:'join',room}));
   ws.onmessage=ev=>{
    let m;try{m=JSON.parse(ev.data);}catch{return;}
    if(m.type==='error'){if(!settled){settled=true;clearTimeout(timer);reject(new Error(m.message||'无法加入房间'));ws.close();}return;}
    if(m.type==='welcome'){this.id=m.id;this.host=m.host;this.room=m.room;this.connected=true;settled=true;clearTimeout(timer);this.ping=setInterval(()=>{if(ws.readyState===1)ws.send(JSON.stringify({type:'ping',at:Date.now()}));},2500);resolve(m);}
    if(m.type==='state'){this.state=m.state;this.host=m.host===this.id;this.onstate(m.state);}
    if(m.type==='pong')this.latency=Date.now()-m.at;
   };
   ws.onerror=()=>{if(!settled){settled=true;clearTimeout(timer);reject(new Error('服务连接失败，请检查地址、证书和来源白名单'));}};
   ws.onclose=()=>{clearTimeout(timer);clearInterval(this.ping);const was=this.connected;this.connected=false;if(!settled){settled=true;reject(new Error('服务关闭了连接'));}if(was)this.onclose();};
  });
 }
 send(input){if(this.ws?.readyState===1)this.ws.send(JSON.stringify({type:'input',input}));}
 restart(){if(this.ws?.readyState===1)this.ws.send(JSON.stringify({type:'restart'}));}
 disconnect(){this.connected=false;clearInterval(this.ping);if(this.ws){this.ws.onclose=null;this.ws.close();this.ws=null;}}
}
