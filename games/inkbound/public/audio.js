export class PaperAudio{
 constructor(){this.ctx=null;this.enabled=true;this.volume=.38;this.stepClock=0;}
 async start(){try{if(!this.ctx){this.ctx=new (window.AudioContext||window.webkitAudioContext)();this.master=this.ctx.createGain();this.master.gain.value=this.enabled?this.volume:0;this.master.connect(this.ctx.destination);}if(this.ctx.state==='suspended')await this.ctx.resume();}catch{this.enabled=false;}}
 setEnabled(v){this.enabled=v;if(this.master)this.master.gain.setTargetAtTime(v?this.volume:0,this.ctx.currentTime,.03);}
 setVolume(v){this.volume=v;if(this.master)this.master.gain.setTargetAtTime(this.enabled?v:0,this.ctx.currentTime,.03);}
 tone(freq=440,duration=.1,type='sine',level=.2,slide=0,delay=0){if(!this.ctx||!this.enabled)return;const t=this.ctx.currentTime+delay,o=this.ctx.createOscillator(),g=this.ctx.createGain();o.type=type;o.frequency.setValueAtTime(freq,t);if(slide)o.frequency.exponentialRampToValueAtTime(Math.max(30,slide),t+duration);g.gain.setValueAtTime(.0001,t);g.gain.exponentialRampToValueAtTime(level,t+.006);g.gain.exponentialRampToValueAtTime(.0001,t+duration);o.connect(g);g.connect(this.master);o.start(t);o.stop(t+duration+.01);o.onended=()=>{o.disconnect();g.disconnect();};}
 scratch(duration=.06,level=.1,frequency=1800){if(!this.ctx||!this.enabled)return;const len=Math.floor(this.ctx.sampleRate*duration),buf=this.ctx.createBuffer(1,len,this.ctx.sampleRate),data=buf.getChannelData(0);for(let i=0;i<len;i++)data[i]=(Math.random()*2-1)*(1-i/len);const source=this.ctx.createBufferSource(),filter=this.ctx.createBiquadFilter(),gain=this.ctx.createGain();source.buffer=buf;filter.type='bandpass';filter.frequency.value=frequency;filter.Q.value=.9;gain.gain.value=level;source.connect(filter);filter.connect(gain);gain.connect(this.master);source.start();source.onended=()=>{source.disconnect();filter.disconnect();gain.disconnect();};}
 event(e){if(e.type==='use'){if(e.tool===0){this.scratch(.065,.3,2100);this.tone(430,.045,'triangle',.1,180);}if(e.tool===1){this.scratch(.18,.35,800);this.tone(180,.12,'sine',.14,70);}if(e.tool===2){this.tone(1050,.13,'sine',.18,210);this.scratch(.045,.16,4000);}if(e.tool===3){this.scratch(.17,.3,1300);this.tone(280,.12,'triangle',.1,600);}if(e.hit)this.tone(760,.06,'sine',.1);}
  if(e.type==='clear'){this.tone(650,.1,'sine',.13);this.tone(980,.16,'sine',.12,0,.05);}
  if(e.type==='wave'){[392,494,587].forEach((f,i)=>this.tone(f,.25,'triangle',.13,0,i*.12));}
  if(e.type==='smudge')this.tone(125,.19,'sine',.18,75);
  if(e.type==='reload'){this.scratch(.13,.15,1200);this.tone(350,.08,'triangle',.08);}
  if(e.type==='loaded'||e.type==='pickup'){this.tone(680,.07,'sine',.13);this.tone(910,.12,'sine',.1,0,.07);}
  if(e.type==='switch')this.scratch(.04,.17,2300);
 }
 step(dt,moving){this.stepClock-=dt;if(moving&&this.stepClock<=0){this.stepClock=.34;this.scratch(.055,.055,550);}}
}
