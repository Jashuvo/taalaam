import { useState, useEffect, useRef } from "react";

/* ════════════════════════════════════════════════════════════════
   Ta'allam (تعلَّم) — full product demo, every learner-facing surface
   Brand tokens mirror lib/core/theme/app_theme.dart
   ════════════════════════════════════════════════════════════════ */

const CSS = `
:root{
  --deep:#0D2218;--forest:#1B4332;--mid:#2D6A4F;--teal:#0D4A4A;--teal-l:#1A7070;
  --leaf:#4CAF82;--gold:#D4A017;--gold-l:#E9C25B;--gold-deep:#A87B0A;
  --cream:#F5F0E8;--paper:#FAF8F3;--card:#FFFFFF;--ink:#1A2E22;--ink-2:#4A6355;
  --line:#E4DCCB;--ok:#2E7D32;--ok-bg:#E4F2E5;--no:#B3261E;--no-bg:#FAE4E2;
  --ar:'Amiri','Noto Naskh Arabic','Scheherazade New','Traditional Arabic',serif;
  --bn:'Hind Siliguri','Noto Sans Bengali','SolaimanLipi',sans-serif;
  --rm:16px;--rl:22px;
  --shc:0 1px 2px rgba(13,34,24,.06),0 6px 18px -8px rgba(13,34,24,.14);
  --shp:0 2px 6px rgba(13,34,24,.12),0 18px 40px -16px rgba(13,34,24,.35);
}
.ta *{margin:0;padding:0;box-sizing:border-box;-webkit-tap-highlight-color:transparent}
.ta{font-family:var(--bn);background:var(--deep);color:var(--cream);min-height:100vh;
  display:flex;flex-direction:column;align-items:center;justify-content:center;
  padding:26px 16px;gap:16px;position:relative;overflow-x:hidden}
.bgpat{position:absolute;inset:0;pointer-events:none;opacity:.05;
  background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120' viewBox='0 0 120 120'%3E%3Cg fill='none' stroke='%23D4A017' stroke-width='1'%3E%3Cpath d='M60 14 L92 46 L60 78 L28 46 Z'/%3E%3Cpath d='M60 14 L92 46 L60 78 L28 46 Z' transform='rotate(45 60 46)'/%3E%3Ccircle cx='60' cy='46' r='7'/%3E%3C/g%3E%3C/svg%3E")}
.bgglow{position:absolute;width:760px;height:760px;border-radius:50%;pointer-events:none;
  background:radial-gradient(circle,rgba(212,160,23,.10),transparent 62%);
  top:50%;left:50%;transform:translate(-50%,-50%)}
.mark{position:relative;z-index:2;text-align:center;line-height:1}
.mark .a{font-family:var(--ar);font-size:40px;color:var(--gold-l);display:block}
.mark .l{font-size:10.5px;letter-spacing:.42em;text-transform:uppercase;
  color:rgba(245,240,232,.55);margin-top:9px;display:block;font-weight:500}
.jumps{position:relative;z-index:2;display:flex;flex-wrap:wrap;gap:7px;justify-content:center;max-width:520px}
.jump{font-family:var(--bn);font-size:11.5px;font-weight:600;color:rgba(245,240,232,.8);
  background:rgba(233,194,91,.08);border:1px solid rgba(233,194,91,.3);border-radius:99px;
  padding:6px 12px;cursor:pointer;transition:all .15s}
.jump:hover{background:rgba(233,194,91,.18);color:var(--gold-l)}
.hint{position:relative;z-index:2;font-size:11.5px;color:rgba(245,240,232,.4);text-align:center}

.phone{position:relative;z-index:2;width:min(392px,100%);height:min(812px,calc(100vh - 168px));
  min-height:620px;background:#08130d;border-radius:52px;padding:11px;
  box-shadow:0 0 0 1px rgba(233,194,91,.18),0 40px 90px -30px rgba(0,0,0,.85),0 12px 30px rgba(0,0,0,.5)}
.ps{width:100%;height:100%;border-radius:42px;overflow:hidden;position:relative;
  background:var(--cream);display:flex;flex-direction:column}
.notch{position:absolute;top:11px;left:50%;transform:translateX(-50%);
  width:108px;height:26px;border-radius:18px;background:#08130d;z-index:60}
.sbar{flex:none;height:44px;display:flex;align-items:flex-end;justify-content:space-between;
  padding:0 26px 4px;font-size:12.5px;font-weight:600;color:var(--ink)}
.body{flex:1;position:relative;overflow:hidden}
.scr{position:absolute;inset:0;display:flex;flex-direction:column;overflow-y:auto;
  opacity:0;transform:translateY(8px);pointer-events:none;
  transition:opacity .26s ease,transform .26s ease;scrollbar-width:none}
.scr::-webkit-scrollbar{display:none}
.scr.on{opacity:1;transform:none;pointer-events:auto}
.toast{position:absolute;top:54px;left:50%;transform:translate(-50%,-16px);background:var(--forest);
  color:var(--gold-l);font-size:12.5px;font-weight:600;border-radius:99px;padding:8px 15px;
  opacity:0;pointer-events:none;z-index:80;transition:all .35s cubic-bezier(.3,1.3,.5,1);
  box-shadow:var(--shp);white-space:nowrap;max-width:88%}
.toast.show{opacity:1;transform:translate(-50%,0)}

/* nav */
.nav{flex:none;display:flex;background:var(--paper);border-top:1px solid var(--line);
  padding:6px 8px 10px;z-index:50}
.nav button{flex:1;border:none;background:transparent;cursor:pointer;font-family:var(--bn);
  display:flex;flex-direction:column;align-items:center;gap:2px;padding:6px 0 3px;
  font-size:10px;color:var(--ink-2);position:relative}
.nav .ni{font-size:17px;line-height:1.2}
.nav .qi{font-family:var(--ar);font-size:18px}
.nav button.on{color:var(--forest);font-weight:700}
.nav button.on .ni{color:var(--gold-deep)}
.nbadge{position:absolute;top:1px;right:calc(50% - 19px);min-width:16px;height:16px;
  border-radius:99px;background:#C0392B;color:#fff;font-size:9.5px;font-weight:700;
  display:grid;place-items:center;padding:0 4px}

/* ── ONBOARDING ── */
.ob{flex:1;display:flex;flex-direction:column;padding:26px 24px;align-items:center}
.ob-logo{font-family:var(--ar);font-size:46px;color:var(--forest);line-height:1}
.ob-eyebrow{font-size:10.5px;letter-spacing:.2em;color:var(--gold-deep);font-weight:700;margin-top:10px;text-transform:uppercase}
.ob-dots{display:flex;gap:7px;margin-top:14px}
.ob-dots i{width:26px;height:5px;border-radius:99px;background:#E4DCCB}
.ob-dots i.f{background:var(--gold)}
.ob-card{width:100%;background:var(--card);border:1px solid var(--line);border-radius:var(--rl);
  padding:22px 18px;margin-top:24px;box-shadow:var(--shc);text-align:center}
.ob-card h2{font-size:17px;font-weight:700;color:var(--ink)}
.ob-ar{font-family:var(--ar);font-size:44px;color:var(--forest);margin-top:10px;direction:rtl}
.ob-opts{display:flex;flex-direction:column;gap:10px;margin-top:18px;width:100%}
.ob-opt{border:1.5px solid var(--line);border-bottom-width:3px;background:var(--card);border-radius:var(--rm);
  padding:13px;font-family:var(--bn);font-size:15px;font-weight:600;color:var(--ink);cursor:pointer;transition:all .14s}
.ob-opt:hover{border-color:#CBC2AC}
.ob-opt.sel{border-color:var(--teal-l);background:#EAF4F2;color:var(--teal)}
.ob-res{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;padding:0 10px}
.ob-star{font-size:54px;color:var(--gold);animation:stmp .55s cubic-bezier(.3,1.4,.5,1)}
.ob-res h2{font-size:21px;color:var(--ink);font-weight:700;margin-top:12px}
.ob-res p{font-size:13.5px;color:var(--ink-2);margin-top:5px;line-height:1.6}
.bigbtn{margin-top:24px;width:100%;border:none;border-radius:var(--rm);padding:15px;font-family:var(--bn);
  font-size:15.5px;font-weight:700;cursor:pointer;color:var(--cream);
  background:linear-gradient(135deg,var(--forest),var(--mid));box-shadow:0 8px 20px -6px rgba(27,67,50,.5)}
.bigbtn:hover{filter:brightness(1.07)}

/* ── HOME ── */
.hh{padding:8px 20px 0;display:flex;align-items:center;justify-content:space-between}
.av{width:40px;height:40px;border-radius:50%;background:linear-gradient(135deg,var(--forest),var(--mid));
  border:2px solid var(--gold);display:grid;place-items:center;color:var(--gold-l);font-weight:700;font-size:15px}
.chips{display:flex;gap:7px}
.chip{display:flex;align-items:center;gap:5px;background:var(--card);border:1px solid var(--line);
  border-radius:999px;padding:6px 11px;font-size:12.5px;font-weight:600;color:var(--ink);box-shadow:var(--shc)}
.chip .i{font-size:13px}
.chip.fl .i{color:var(--gold)}
.chip.xp .i{color:var(--teal-l)}
.greet{padding:13px 22px 9px}
.dl{font-size:10px;color:var(--gold-deep);font-weight:600;letter-spacing:.1em;margin-bottom:2px}
.greet h1{font-size:20px;font-weight:700;color:var(--ink);letter-spacing:-.01em}
.greet p{font-size:12.5px;color:var(--ink-2);margin-top:3px}
.greet p b{color:var(--gold-deep);font-weight:600}

.tcard{margin:0 18px 11px;border-radius:var(--rl);overflow:hidden;background:var(--card);
  border:1px solid var(--line);box-shadow:var(--shc);cursor:pointer;transition:transform .16s,box-shadow .16s}
.tcard:hover{transform:translateY(-2px);box-shadow:var(--shp)}
.tcard:active{transform:scale(.985)}
.tch{height:88px;position:relative;display:flex;align-items:center;padding:0 16px;gap:12px;overflow:hidden}
.tcbig{position:absolute;right:-8px;bottom:-20px;font-family:var(--ar);font-size:60px;
  color:rgba(255,255,255,.07);line-height:1;direction:rtl;pointer-events:none}
.tcic{width:40px;height:40px;border-radius:12px;background:rgba(255,255,255,.16);flex:none;
  display:grid;place-items:center;color:#fff}
.tct h3{color:#fff;font-size:16px;font-weight:700}
.tct small{color:rgba(255,255,255,.82);font-size:11.5px;display:block;margin-top:1px}
.tcb{padding:10px 16px 12px;display:flex;align-items:center;gap:10px}
.tcbar{flex:1;height:6px;border-radius:99px;background:#E9E2D2;overflow:hidden}
.tcbar i{display:block;height:100%;border-radius:99px}
.tcb span{font-size:11px;font-weight:600;color:var(--ink-2)}
.tcb .c{color:#C2B89F;font-size:15px}

.wk{margin:0 18px 11px;background:var(--card);border:1px solid var(--line);border-radius:var(--rm);
  padding:12px 14px;box-shadow:var(--shc)}
.wk .r1{display:flex;align-items:center;justify-content:space-between}
.wk h4{font-size:13px;font-weight:700;color:var(--ink)}
.wk .lb{font-size:11.5px;font-weight:700;color:var(--gold-deep);cursor:pointer}
.wk .lb:hover{text-decoration:underline}
.wkbar{margin-top:9px;height:7px;border-radius:99px;background:#E9E2D2;overflow:hidden}
.wkbar i{display:block;height:100%;width:75%;border-radius:99px;background:linear-gradient(90deg,var(--gold),var(--gold-l))}
.wk .r2{margin-top:6px;font-size:10.5px;color:var(--ink-2)}

.srs{display:flex;gap:10px;padding:1px 18px 16px}
.srsc{flex:1;background:var(--card);border:1px solid var(--line);border-radius:var(--rm);
  padding:11px 12px;display:flex;align-items:center;gap:9px;box-shadow:var(--shc);cursor:pointer;transition:transform .15s}
.srsc:hover{transform:translateY(-1px)}
.srsi{width:33px;height:33px;border-radius:10px;display:grid;place-items:center;font-size:15px;flex:none}
.srsc.m .srsi{background:#FBF3DE;color:var(--gold-deep)}
.srsc.r .srsi{background:#E2EFEA;color:var(--mid)}
.srsc h4{font-size:12.5px;font-weight:600;color:var(--ink)}
.srsc span{font-size:10.5px;color:var(--ink-2)}
.srsb{margin-left:auto;min-width:22px;height:22px;border-radius:99px;background:var(--forest);
  color:var(--gold-l);font-size:11px;font-weight:700;display:grid;place-items:center;padding:0 6px}

/* ── TRACK DETAIL ── */
.td{flex:none;color:var(--cream);padding:11px 18px 15px;border-radius:0 0 26px 26px;
  box-shadow:var(--shp);position:relative;overflow:hidden}
.tdbig{position:absolute;right:-10px;bottom:-26px;font-family:var(--ar);font-size:92px;
  color:rgba(255,255,255,.06);line-height:1;direction:rtl;pointer-events:none}
.tdt{display:flex;align-items:center;gap:10px;position:relative}
.back{width:31px;height:31px;border-radius:50%;border:none;cursor:pointer;flex:none;
  background:rgba(255,255,255,.16);color:#fff;font-size:16px;display:grid;place-items:center}
.back:hover{background:rgba(255,255,255,.26)}
.tde{font-size:10px;letter-spacing:.2em;text-transform:uppercase;color:var(--gold-l);font-weight:600}
.td h2{font-size:18px;font-weight:700;margin-top:7px;position:relative}
.tds{font-family:var(--ar);font-size:14.5px;color:rgba(245,240,232,.85);margin-top:1px;position:relative}
.tdp{margin-top:10px;display:flex;align-items:center;gap:10px;position:relative}
.tdb{flex:1;height:7px;border-radius:99px;background:rgba(245,240,232,.22);overflow:hidden}
.tdb i{display:block;height:100%;border-radius:99px;background:linear-gradient(90deg,var(--gold),var(--gold-l))}
.tdp span{font-size:11px;font-weight:600;color:var(--gold-l)}
.uchips{display:flex;gap:6px;margin-top:11px;position:relative;flex-wrap:wrap}
.uc{font-size:10.5px;font-weight:600;border-radius:99px;padding:4px 10px;
  background:rgba(255,255,255,.13);color:rgba(255,255,255,.75)}
.uc.on{background:var(--gold);color:#fff}
.uc.lk{opacity:.55}
.path svg{display:block;width:100%;height:auto}
.bead{cursor:pointer}
.bead .ring{transition:transform .25s}
.bead:hover .ring{transform:scale(1.07);transform-origin:center;transform-box:fill-box}
.blab{font-family:var(--bn);font-weight:600;fill:var(--ink);font-size:12.5px}
.bsub{font-family:var(--bn);fill:var(--ink-2);font-size:10.5px}
.bstar{font-size:9px;fill:var(--gold)}
@keyframes pls{0%,100%{stroke-opacity:.55}50%{stroke-opacity:.08}}
.pring{animation:pls 2.2s ease-in-out infinite}
.cpill{cursor:pointer}
.cpill:hover rect{filter:brightness(1.12)}

/* ── EXERCISE ── */
.ext{display:flex;align-items:center;gap:12px;padding:11px 20px 5px}
.exx{width:33px;height:33px;border-radius:50%;border:none;background:transparent;
  color:var(--ink-2);font-size:18px;cursor:pointer;display:grid;place-items:center}
.exx:hover{background:rgba(26,46,34,.06)}
.exp{flex:1;height:11px;border-radius:99px;background:#E6DFD0;overflow:hidden}
.exp i{display:block;height:100%;border-radius:99px;background:linear-gradient(90deg,var(--mid),var(--leaf));
  transition:width .55s cubic-bezier(.4,0,.2,1)}
.hearts{display:flex;gap:2px;font-size:13.5px;flex:none}
.hrt{color:#E05252;transition:all .3s}
.hrt.off{color:#D8D0BD;transform:scale(.85)}
.exw{flex:1;display:flex;flex-direction:column;padding:6px 22px 16px}
.exk{font-size:11px;letter-spacing:.13em;text-transform:uppercase;font-weight:700}
.exq{font-size:18px;font-weight:700;color:var(--ink);margin-top:3px}
.exword{margin:16px auto 4px;display:flex;align-items:center;gap:15px}
.abtn{width:50px;height:50px;border-radius:50%;border:none;cursor:pointer;flex:none;
  background:linear-gradient(135deg,var(--gold),var(--gold-deep));color:#fff;
  display:grid;place-items:center;box-shadow:0 6px 16px -4px rgba(168,123,10,.55);transition:transform .15s}
.abtn:active{transform:scale(.93)}
.eq{display:flex;align-items:flex-end;gap:2.5px;height:16px}
.eq i{width:3px;background:#fff;border-radius:2px;height:5px}
.abtn.pl .eq i{animation:eq .7s ease-in-out infinite}
.abtn.pl .eq i:nth-child(2){animation-delay:.12s}
.abtn.pl .eq i:nth-child(3){animation-delay:.24s}
.abtn.pl .eq i:nth-child(4){animation-delay:.36s}
@keyframes eq{0%,100%{height:4px}50%{height:15px}}
.arw{font-family:var(--ar);font-size:42px;line-height:1.5;color:var(--ink);direction:rtl}
.trl{text-align:center;font-size:12.5px;color:var(--ink-2);letter-spacing:.05em;font-style:italic}
.opts{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:20px}
.opt{border:1.5px solid var(--line);border-bottom-width:3.5px;background:var(--card);
  border-radius:var(--rm);padding:14px 8px 12px;cursor:pointer;font-family:var(--bn);
  font-size:15px;font-weight:600;color:var(--ink);transition:all .14s;text-align:center}
.opt.arf{font-family:var(--ar);font-size:21px;direction:rtl;padding:11px 8px 9px}
.opt:hover{border-color:#CBC2AC;transform:translateY(-1px)}
.opt.sel{border-color:var(--teal-l);background:#EAF4F2;color:var(--teal)}
.opt.ok{border-color:var(--ok);background:var(--ok-bg);color:var(--ok)}
.opt.no{border-color:#D98880;background:var(--no-bg);color:var(--no)}
.opt.dim{opacity:.45;pointer-events:none}
.prompt{margin:12px 0 0;background:var(--card);border:1px solid var(--line);border-radius:var(--rm);
  padding:12px 14px;display:flex;align-items:center;gap:10px;box-shadow:var(--shc)}
.prompt .f{width:34px;height:34px;border-radius:50%;flex:none;display:grid;place-items:center;
  background:#E2EFEA;color:var(--teal);font-size:16px}
.prompt p{font-size:15px;font-weight:600;color:var(--ink)}
.tbl{display:flex;flex-direction:row-reverse;flex-wrap:wrap;gap:8px;align-content:flex-start;
  min-height:56px;padding:8px 2px;border-bottom:2px solid var(--line);margin-top:18px}
.tbh{font-size:10.5px;color:#B9AF97;margin-top:5px;text-align:center}
.bank{display:flex;flex-wrap:wrap;gap:9px;justify-content:center;margin-top:20px;direction:rtl}
.tok{font-family:var(--ar);font-size:21px;line-height:1.5;direction:rtl;padding:7px 14px 5px;
  border:1.5px solid var(--line);border-bottom-width:3px;border-radius:13px;background:var(--card);
  cursor:pointer;color:var(--ink);transition:all .14s}
.tok:hover{border-color:#CBC2AC;transform:translateY(-1px)}
.tok.used{opacity:0;pointer-events:none}
.tbl .tok{background:#EAF4F2;border-color:var(--teal-l)}
.fibs{margin:22px auto 0;font-family:var(--ar);font-size:30px;direction:rtl;display:flex;
  flex-direction:row;gap:10px;align-items:baseline;color:var(--ink);flex-wrap:wrap;justify-content:center}
.slot{min-width:84px;border-bottom:2.5px dashed var(--gold);text-align:center;color:var(--gold-deep);
  font-size:28px;padding:0 6px}
.gloss{text-align:center;font-size:12px;color:var(--ink-2);margin-top:12px;font-style:italic}
.dd{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:18px}
.ddi{border:1.5px solid var(--line);border-bottom-width:3px;background:var(--card);border-radius:var(--rm);
  padding:12px 8px;cursor:pointer;text-align:center;font-weight:600;color:var(--ink);transition:all .14s}
.ddi.ar{font-family:var(--ar);font-size:21px;direction:rtl}
.ddi.bn{font-family:var(--bn);font-size:14.5px}
.ddi:hover{border-color:#CBC2AC}
.ddi.sel{border-color:var(--teal-l);background:#EAF4F2}
.ddi.mt{border-color:var(--ok);background:var(--ok-bg);color:var(--ok);pointer-events:none;opacity:.75}
.ddi.bad{border-color:#D98880;background:var(--no-bg)}
.tfst{margin-top:18px;background:var(--card);border:1px solid var(--line);border-radius:var(--rl);
  padding:20px 16px;text-align:center;box-shadow:var(--shc)}
.tfst .a{font-family:var(--ar);font-size:32px;color:var(--ink);direction:rtl}
.tfst p{font-size:14.5px;font-weight:600;color:var(--ink);margin-top:6px}
.tfr{display:grid;grid-template-columns:1fr 1fr;gap:11px;margin-top:18px}
.tfb{border:1.5px solid var(--line);border-bottom-width:3.5px;border-radius:var(--rm);padding:16px;
  font-family:var(--bn);font-size:16px;font-weight:700;cursor:pointer;background:var(--card);color:var(--ink);transition:all .14s}
.tfb.t:hover{border-color:var(--ok)}
.tfb.f:hover{border-color:#D98880}
.tfb.sel{border-color:var(--teal-l);background:#EAF4F2;color:var(--teal)}
.tfb.ok{border-color:var(--ok);background:var(--ok-bg);color:var(--ok)}
.tfb.no{border-color:#D98880;background:var(--no-bg);color:var(--no)}
.tfb.dim{opacity:.45;pointer-events:none}
.refl{margin-top:14px;background:var(--card);border:1px solid var(--line);border-radius:var(--rl);
  padding:20px 18px;text-align:center;box-shadow:var(--shc)}
.refl .a{font-family:var(--ar);font-size:30px;line-height:1.8;color:var(--forest);direction:rtl}
.refl .b{font-size:13px;color:var(--ink-2);margin-top:8px;line-height:1.65}
.rbox{margin-top:14px;background:#FBF6E6;border:1px solid #EAD9A8;border-radius:var(--rm);
  padding:12px 14px;font-size:12.5px;color:#6B5410;line-height:1.7;text-align:right;direction:rtl;font-family:var(--bn)}
.rbox b{color:var(--gold-deep)}
.ckz{margin-top:auto;padding-top:14px}
.ck{width:100%;border:none;border-radius:var(--rm);padding:14px;font-family:var(--bn);
  font-size:15.5px;font-weight:700;letter-spacing:.04em;background:#E2DBC9;color:#A39B85;cursor:not-allowed;transition:all .2s}
.ck.go{background:linear-gradient(135deg,var(--forest),var(--mid));color:var(--cream);
  cursor:pointer;box-shadow:0 8px 20px -6px rgba(27,67,50,.5)}
.ck.go:hover{filter:brightness(1.07)}
.fb{position:absolute;left:0;right:0;bottom:0;background:var(--ok-bg);border-top:1.5px solid #CBE3CD;
  padding:15px 22px 18px;transform:translateY(105%);transition:transform .35s cubic-bezier(.34,1.4,.5,1);
  z-index:40;border-radius:22px 22px 0 0}
.fb.show{transform:none}
.fb.bad{background:var(--no-bg);border-top-color:#EFC7C2}
.fbr{display:flex;align-items:center;gap:11px}
.stmp{font-family:var(--ar);font-size:30px;color:var(--gold-deep);line-height:1;flex:none;
  opacity:0;transform:scale(2) rotate(-18deg)}
.fb.show .stmp{animation:stmp .5s .1s cubic-bezier(.3,1.4,.5,1) forwards}
@keyframes stmp{to{opacity:1;transform:scale(1) rotate(0)}}
.fb h3{font-size:16px;font-weight:700;color:var(--ok)}
.fb p{font-size:12px;color:#3E6B41;margin-top:1px}
.fb.bad h3{color:var(--no)}
.fb.bad p{color:#8C4A42}
.fb.bad .stmp{color:var(--no)}
.xpp{margin-left:auto;background:var(--gold);color:#fff;font-weight:700;font-size:12.5px;
  border-radius:99px;padding:5px 10px;box-shadow:0 4px 10px -2px rgba(168,123,10,.5);flex:none}
.gnote{margin-top:10px;padding-top:9px;border-top:1px dashed #BCD9BE;font-size:12px;color:#2F5A33;line-height:1.55}
.gnote b{color:var(--ok)}
.nx{margin-top:12px;width:100%;border:none;border-radius:var(--rm);padding:13px;
  font-family:var(--bn);font-size:15px;font-weight:700;cursor:pointer;background:var(--ok);color:#fff}
.nx.bad{background:#C0392B}

/* ── COMPLETE ── */
.cmp{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:20px;text-align:center}
.cstmp{font-family:var(--ar);font-size:58px;color:var(--gold-deep);line-height:1;
  opacity:0;transform:scale(2.2) rotate(-20deg);animation:stmp .6s .15s cubic-bezier(.3,1.4,.5,1) forwards}
.cmp h2{font-size:20px;font-weight:700;color:var(--ink);margin-top:12px}
.cmp .ls{font-size:12.5px;color:var(--ink-2);margin-top:2px}
.cstats{display:flex;gap:9px;margin-top:16px;flex-wrap:wrap;justify-content:center}
.cp{background:var(--card);border:1px solid var(--line);border-radius:var(--rm);padding:10px 15px;box-shadow:var(--shc)}
.cp .n{font-size:18px;font-weight:700;color:var(--forest)}
.cp .l{font-size:10px;color:var(--ink-2);margin-top:1px;letter-spacing:.04em}
.cp.gold{background:#FBF3DE;border-color:#EAD9A8}
.cp.gold .n{color:var(--gold-deep)}
.weak{margin-top:13px;font-size:11.5px;color:var(--ink-2);background:var(--card);
  border:1px dashed var(--line);border-radius:99px;padding:7px 14px}
.weak b{color:var(--gold-deep)}
.duaa{margin-top:16px;background:var(--card);border:1px solid var(--line);border-top:3px solid var(--gold);
  border-radius:18px;padding:14px 17px;max-width:300px;box-shadow:var(--shc)}
.duaa .a{font-family:var(--ar);font-size:25px;line-height:1.7;color:var(--forest);direction:rtl}
.duaa .b{font-size:12px;color:var(--ink-2);margin-top:5px}
.duaa .s{font-size:10px;color:var(--gold-deep);margin-top:4px;letter-spacing:.08em;font-weight:600}

/* ── SRS ── */
.rv{flex:1;display:flex;flex-direction:column;padding:10px 20px 16px}
.rvt{display:flex;align-items:center;gap:11px}
.rvt h2{font-size:16px;font-weight:700;color:var(--ink)}
.rvt span{margin-left:auto;font-size:11.5px;font-weight:600;color:var(--ink-2)}
.rvc{flex:1;margin-top:12px;background:var(--card);border:1px solid var(--line);border-radius:var(--rl);
  box-shadow:var(--shc);display:flex;flex-direction:column;align-items:center;justify-content:center;
  padding:22px 18px;text-align:center;cursor:pointer;position:relative;min-height:0;overflow-y:auto;scrollbar-width:none}
.rvc::-webkit-scrollbar{display:none}
.spill{position:absolute;top:12px;left:14px;font-size:10px;font-weight:600;border-radius:99px;
  padding:3px 9px;border:1px solid}
.spill.new{color:#1565C0;border-color:#9FC4E8;background:#EAF2FB}
.spill.lrn{color:#B45309;border-color:#EAC089;background:#FBF1DF}
.spill.rem{color:var(--ok);border-color:#A8D4AB;background:var(--ok-bg)}
.rvar{font-family:var(--ar);font-size:52px;color:var(--ink);direction:rtl;line-height:1.4}
.rvhint{font-size:11.5px;color:#B9AF97;margin-top:14px}
.rvm{font-size:21px;font-weight:700;color:var(--forest);margin-top:10px}
.rvchips{display:flex;gap:7px;margin-top:10px;flex-wrap:wrap;justify-content:center}
.rvchip{font-size:10.5px;font-weight:600;border-radius:99px;padding:4px 10px;background:#F2EDE1;color:var(--ink-2)}
.rvchip.g{background:#FBF3DE;color:var(--gold-deep)}
.ctx{margin-top:14px;width:100%;background:#FFFDF6;border:1px solid #EAD9A8;border-radius:var(--rm);padding:11px 13px;text-align:right}
.ctx .t{font-size:10px;color:var(--gold-deep);font-weight:700;letter-spacing:.1em;text-align:left}
.ctx .a{font-family:var(--ar);font-size:19px;line-height:1.9;color:var(--gold-deep);direction:rtl;margin-top:5px}
.ctx .b{font-size:11px;color:var(--ink-2);font-style:italic;margin-top:3px;text-align:left}
.rates{display:flex;gap:7px;margin-top:13px}
.rate{flex:1;border:none;border-radius:13px;padding:10px 4px 8px;cursor:pointer;color:#fff;
  font-family:var(--bn);transition:filter .15s}
.rate:hover{filter:brightness(1.1)}
.rate b{display:block;font-size:13px;font-weight:700}
.rate i{display:block;font-style:normal;font-size:9.5px;opacity:.85;margin-top:1px}
.rvdone{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center}

/* ── QURAN ── */
.qh{flex:none;background:linear-gradient(135deg,var(--teal),var(--teal-l));color:var(--cream);
  padding:13px 20px 14px;border-radius:0 0 26px 26px;box-shadow:var(--shp);position:relative;overflow:hidden}
.qh .orn{position:absolute;left:-14px;bottom:-30px;font-family:var(--ar);font-size:112px;
  color:rgba(233,194,91,.12);line-height:1}
.qsa{font-family:var(--ar);font-size:25px;text-align:center;color:var(--gold-l)}
.qsb{text-align:center;font-size:12px;color:rgba(245,240,232,.85);margin-top:1px}
.qm{display:flex;justify-content:center;gap:12px;margin-top:7px;font-size:10px;color:rgba(245,240,232,.65);letter-spacing:.06em}
.qb{padding:15px 18px 96px}
.bism{font-family:var(--ar);font-size:22px;text-align:center;color:var(--mid);margin-bottom:12px;direction:rtl}
.ay{background:var(--card);border:1px solid var(--line);border-radius:var(--rl);
  padding:15px 13px 11px;box-shadow:var(--shc);margin-bottom:12px;position:relative}
.aynum{position:absolute;top:-10px;right:15px;font-family:var(--ar);font-size:12.5px;
  background:var(--cream);border:1px solid var(--gold);color:var(--gold-deep);border-radius:99px;padding:1px 9px;font-weight:700}
.bm{position:absolute;top:-10px;left:14px;border:1px solid var(--line);background:var(--cream);
  color:#B9AF97;border-radius:99px;width:26px;height:22px;font-size:12px;cursor:pointer;display:grid;place-items:center}
.bm.on{color:var(--gold-deep);border-color:var(--gold)}
.ws{display:flex;flex-wrap:wrap;flex-direction:row-reverse;gap:6px;justify-content:center}
.w{border:1px solid transparent;border-radius:11px;padding:5px 8px 4px;cursor:pointer;text-align:center;transition:all .15s;background:transparent}
.w:hover{background:#F2EDE1}
.w.lit{background:#FBF3DE;border-color:var(--gold);box-shadow:0 3px 10px -3px rgba(168,123,10,.35)}
.w .a{font-family:var(--ar);font-size:22px;line-height:1.55;color:var(--ink);display:block;direction:rtl}
.w .b{font-size:10px;color:var(--ink-2);display:block;margin-top:1px}
.w.lit .b{color:var(--gold-deep);font-weight:600}
.w .r{display:none;font-family:var(--ar);font-size:10.5px;color:var(--gold-deep);direction:rtl;margin-top:1px}
.w.lit .r{display:block}
.aybn{margin-top:9px;padding-top:8px;border-top:1px dashed var(--line);font-size:12.5px;color:var(--ink-2);line-height:1.65}
.tafl{margin-top:7px;font-size:11px;font-weight:700;color:var(--teal-l);cursor:pointer;background:none;border:none;font-family:var(--bn);padding:0}
.tafl:hover{text-decoration:underline}
.tafb{margin-top:7px;background:#F4F8F6;border:1px solid #D9E6DF;border-radius:12px;padding:10px 12px;
  font-size:11.5px;color:#33564A;line-height:1.7}
.qa{position:absolute;left:14px;right:14px;bottom:12px;z-index:30;background:var(--forest);
  color:var(--cream);border-radius:var(--rm);padding:9px 13px;display:flex;align-items:center;gap:11px;box-shadow:var(--shp)}
.qp{width:36px;height:36px;border-radius:50%;border:none;cursor:pointer;flex:none;
  background:var(--gold);color:#fff;font-size:12px;display:grid;place-items:center}
.qa h5{font-size:12px;font-weight:600}
.qa .tm{font-size:10px;color:rgba(245,240,232,.6)}
.qtr{height:4px;border-radius:99px;background:rgba(245,240,232,.25);overflow:hidden;margin-top:4px}
.qtr i{display:block;height:100%;background:var(--gold-l);border-radius:99px;transition:width .12s linear}

/* ── CHAT ── */
.ch{flex:1;display:flex;flex-direction:column;min-height:0}
.chh{flex:none;background:linear-gradient(135deg,var(--teal),var(--teal-l));color:#fff;
  padding:11px 18px 13px;display:flex;align-items:center;gap:11px;border-radius:0 0 22px 22px;box-shadow:var(--shp)}
.chav{width:38px;height:38px;border-radius:50%;background:rgba(255,255,255,.18);
  display:grid;place-items:center;font-family:var(--ar);font-size:19px;color:var(--gold-l);position:relative}
.chav i{position:absolute;bottom:0;right:0;width:9px;height:9px;border-radius:50%;background:#5EDB8A;border:2px solid var(--teal)}
.chh h3{font-size:14.5px;font-weight:700}
.chh small{font-size:10.5px;color:rgba(255,255,255,.75);display:block}
.msgs{flex:1;overflow-y:auto;padding:14px 16px;display:flex;flex-direction:column;gap:9px;scrollbar-width:none}
.msgs::-webkit-scrollbar{display:none}
.bub{max-width:80%;border-radius:16px;padding:9px 13px;box-shadow:var(--shc)}
.bub.bot{align-self:flex-start;background:var(--card);border:1px solid var(--line);border-bottom-left-radius:5px}
.bub.me{align-self:flex-end;background:var(--forest);color:var(--cream);border-bottom-right-radius:5px}
.bub .a{font-family:var(--ar);font-size:20px;line-height:1.6;direction:rtl}
.bub.bot .a{color:var(--ink)}
.bub .g{font-size:10.5px;margin-top:2px;color:var(--ink-2)}
.bub.me .g{color:rgba(245,240,232,.7)}
.bub.sys{align-self:center;background:#FBF3DE;border:1px solid #EAD9A8;color:var(--gold-deep);
  font-size:11px;font-weight:600;border-radius:99px;padding:6px 13px;box-shadow:none}
.chips2{flex:none;display:flex;gap:8px;padding:8px 14px;overflow-x:auto;scrollbar-width:none}
.chips2::-webkit-scrollbar{display:none}
.cchip{flex:none;border:1.5px solid var(--teal-l);background:#EAF4F2;color:var(--teal);
  border-radius:99px;padding:8px 14px 6px;cursor:pointer;font-family:var(--ar);font-size:17px;direction:rtl;transition:all .14s}
.cchip:hover{background:var(--teal-l);color:#fff}
.chbar{flex:none;display:flex;align-items:center;gap:10px;padding:8px 16px 12px}
.chbar .fld{flex:1;background:var(--card);border:1px solid var(--line);border-radius:99px;
  padding:11px 16px;font-size:12px;color:#B9AF97}
.mic{width:46px;height:46px;border-radius:50%;border:none;cursor:pointer;flex:none;
  background:linear-gradient(135deg,var(--gold),var(--gold-deep));color:#fff;font-size:17px;
  display:grid;place-items:center;box-shadow:0 6px 16px -4px rgba(168,123,10,.55)}
.mic.rec{animation:mic 1s ease-in-out infinite}
@keyframes mic{0%,100%{box-shadow:0 0 0 0 rgba(212,160,23,.5)}50%{box-shadow:0 0 0 12px rgba(212,160,23,0)}}

/* ── LEADERBOARD ── */
.lb{padding:0 0 20px}
.lbh{background:linear-gradient(135deg,var(--forest),var(--mid));color:var(--cream);
  padding:12px 18px 15px;border-radius:0 0 26px 26px;box-shadow:var(--shp);position:relative;overflow:hidden}
.lbh .orn{position:absolute;right:-8px;top:-18px;font-family:var(--ar);font-size:88px;color:rgba(233,194,91,.13);line-height:1}
.lbh h2{font-size:17px;font-weight:700;margin-top:6px;position:relative}
.lbh p{font-size:11px;color:rgba(245,240,232,.75);margin-top:2px;position:relative}
.lbl{padding:14px 18px 0;display:flex;flex-direction:column;gap:8px}
.lbr{display:flex;align-items:center;gap:11px;background:var(--card);border:1px solid var(--line);
  border-radius:var(--rm);padding:10px 13px;box-shadow:var(--shc)}
.lbr.me{border-color:var(--gold);background:#FFFDF4;box-shadow:0 4px 14px -4px rgba(168,123,10,.3)}
.lbr .rk{width:26px;text-align:center;font-weight:700;font-size:14px;color:var(--ink-2);flex:none}
.lbr .nm{flex:1;font-size:13.5px;font-weight:600;color:var(--ink);min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.lbr.me .nm{color:var(--gold-deep)}
.lbr .xp{font-size:12.5px;font-weight:700;color:var(--forest);flex:none}

/* ── PROFILE ── */
.pf{padding:12px 18px 24px}
.tier{background:linear-gradient(130deg,var(--forest),var(--teal));border-radius:var(--rl);
  color:var(--cream);padding:15px;display:flex;align-items:center;gap:14px;box-shadow:var(--shp);position:relative;overflow:hidden}
.tier .orn{position:absolute;right:-10px;top:-22px;font-family:var(--ar);font-size:88px;color:rgba(233,194,91,.13);line-height:1}
.ring{position:relative;width:66px;height:66px;flex:none}
.ring svg{transform:rotate(-90deg)}
.ring .lv{position:absolute;inset:0;display:grid;place-items:center;font-size:17px;font-weight:700;color:var(--gold-l)}
.tier .eb{font-size:9.5px;letter-spacing:.2em;text-transform:uppercase;color:rgba(245,240,232,.6);font-weight:600}
.tier h3{font-size:17.5px;font-weight:700;margin-top:2px}
.tier p{font-size:11px;color:rgba(245,240,232,.75);margin-top:2px}
.tier p b{color:var(--gold-l)}
.acts{display:flex;gap:8px;margin-top:10px}
.act{flex:1;border:1px solid var(--line);background:var(--card);border-radius:13px;padding:9px 4px;
  font-family:var(--bn);font-size:11px;font-weight:700;color:var(--ink);cursor:pointer;box-shadow:var(--shc);transition:transform .14s}
.act:hover{transform:translateY(-1px)}
.act .i{display:block;font-size:15px;margin-bottom:2px}
.wkc{background:var(--card);border:1px solid var(--line);border-radius:var(--rl);padding:13px 15px;margin-top:11px;box-shadow:var(--shc)}
.wkc h4{font-size:13px;font-weight:700;color:var(--ink);display:flex;align-items:center;gap:6px}
.wkc .fl{color:var(--gold)}
.days{display:flex;justify-content:space-between;margin-top:11px}
.day{display:flex;flex-direction:column;align-items:center;gap:4px;font-size:9.5px;color:var(--ink-2)}
.dot{width:28px;height:28px;border-radius:50%;display:grid;place-items:center;border:1.5px dashed var(--line);font-size:11.5px;color:transparent}
.dot.dn{background:var(--forest);border:none;color:var(--gold-l)}
.dot.fz{background:#E3F2FD;border:none;color:#1976D2}
.dot.td{border:1.5px solid var(--gold);color:var(--gold-deep);background:#FBF3DE}
.bdgs{display:flex;gap:8px;margin-top:11px;flex-wrap:wrap}
.bdg{font-size:11px;font-weight:600;color:var(--gold-deep);background:#FBF3DE;border:1px solid #EAD9A8;border-radius:99px;padding:6px 11px}
.sg{display:grid;grid-template-columns:1fr 1fr;gap:9px;margin-top:11px}
.st{background:var(--card);border:1px solid var(--line);border-radius:var(--rm);padding:11px 13px;box-shadow:var(--shc)}
.st .n{font-size:19px;font-weight:700;color:var(--forest)}
.st .n small{font-size:11px;color:var(--gold-deep);font-weight:600}
.st .l{font-size:10.5px;color:var(--ink-2);margin-top:1px}
.rowc{margin-top:11px;background:var(--card);border:1px solid var(--line);border-radius:var(--rm);
  padding:12px 14px;display:flex;align-items:center;gap:10px;box-shadow:var(--shc);cursor:pointer;font-size:13px;font-weight:600;color:var(--ink)}
.rowc:hover{transform:translateY(-1px)}
.rowc .c{margin-left:auto;color:#C2B89F}
.shov{position:absolute;inset:0;background:rgba(13,34,24,.55);z-index:90;display:flex;
  align-items:center;justify-content:center;padding:24px;backdrop-filter:blur(2px)}
.shc{width:100%;background:linear-gradient(150deg,var(--forest),var(--teal));border-radius:24px;
  padding:24px 20px;text-align:center;color:var(--cream);box-shadow:var(--shp);position:relative;overflow:hidden}
.shc .orn{position:absolute;right:-14px;top:-26px;font-family:var(--ar);font-size:110px;color:rgba(233,194,91,.13);line-height:1}
.shc .g{font-family:var(--ar);font-size:40px;color:var(--gold-l)}
.shc h3{font-size:19px;font-weight:700;margin-top:6px}
.shc .t{font-size:12px;color:var(--gold-l);margin-top:2px}
.shc .row{display:flex;justify-content:center;gap:14px;margin-top:12px;font-size:12px;font-weight:600}
.shc .ft{font-size:10.5px;color:rgba(245,240,232,.65);margin-top:14px;letter-spacing:.06em}
.shbtns{display:flex;gap:9px;margin-top:16px}
.shb{flex:1;border:none;border-radius:13px;padding:11px;font-family:var(--bn);font-size:13px;font-weight:700;cursor:pointer}
.shb.p{background:var(--gold);color:#fff}
.shb.s{background:rgba(255,255,255,.14);color:var(--cream)}

/* ── SETTINGS ── */
.set{padding:12px 18px 24px}
.sh2{font-size:11px;letter-spacing:.14em;text-transform:uppercase;color:var(--gold-deep);font-weight:700;margin:14px 2px 7px}
.srow{background:var(--card);border:1px solid var(--line);border-radius:var(--rm);padding:12px 14px;
  display:flex;align-items:center;gap:10px;box-shadow:var(--shc);margin-bottom:8px}
.srow .ic{font-size:16px;width:24px;text-align:center;flex:none}
.srow .tx{flex:1;min-width:0}
.srow h5{font-size:13px;font-weight:600;color:var(--ink)}
.srow small{font-size:10.5px;color:var(--ink-2);display:block;margin-top:1px}
.sw{width:42px;height:25px;border-radius:99px;background:#D8D0BD;position:relative;cursor:pointer;flex:none;transition:background .2s;border:none}
.sw i{position:absolute;top:3px;left:3px;width:19px;height:19px;border-radius:50%;background:#fff;transition:left .2s;box-shadow:0 1px 3px rgba(0,0,0,.25)}
.sw.on{background:var(--mid)}
.sw.on i{left:20px}
.frz{display:flex;align-items:center;gap:11px;background:#EAF4FB;border:1px solid #C9E2F2;
  border-radius:var(--rm);padding:12px 14px;margin-bottom:8px}
.frz .ic{font-size:20px}
.frz h5{font-size:13px;font-weight:700;color:#1565C0}
.frz small{font-size:10.5px;color:#4A7396;display:block}
.frzb{margin-left:auto;border:none;border-radius:99px;background:#1976D2;color:#fff;
  font-family:var(--bn);font-size:11.5px;font-weight:700;padding:8px 13px;cursor:pointer}
.frzb:disabled{background:#A8C5DC;cursor:default}
.sup{background:linear-gradient(135deg,#3D2E00,#7A5C04);border-radius:var(--rl);padding:16px;
  color:#FFF6DD;box-shadow:var(--shp);position:relative;overflow:hidden;margin-bottom:8px}
.sup .orn{position:absolute;right:-8px;bottom:-24px;font-family:var(--ar);font-size:86px;color:rgba(233,194,91,.15);line-height:1}
.sup h4{font-size:15.5px;font-weight:700;color:var(--gold-l)}
.sup p{font-size:11.5px;color:rgba(255,246,221,.85);margin-top:4px;line-height:1.6;position:relative}
.sup .pr{font-size:19px;font-weight:700;color:#fff;margin-top:8px}
.sup .pr small{font-size:11px;font-weight:600;color:rgba(255,246,221,.7)}
.payb{display:flex;gap:8px;margin-top:11px;position:relative}
.pay{flex:1;border:none;border-radius:12px;padding:10px;font-family:var(--bn);font-size:13px;font-weight:700;color:#fff;cursor:pointer}
.pay.bk{background:#E2136E}
.pay.ng{background:#F6921E}
.ver{text-align:center;font-size:10.5px;color:#B9AF97;margin-top:14px}

@media(max-width:480px){
  .ta{padding:12px 8px}
  .mark .a{font-size:30px}
  .phone{height:min(790px,calc(100vh - 150px));border-radius:44px}
  .ps{border-radius:36px}
}
@media(prefers-reduced-motion:reduce){.ta *{animation:none!important;transition:none!important}}
`;

/* ── data ──────────────────────────────────────────────────── */

const bn = (n) => String(n).replace(/\d/g, (d) => "০১২৩৪৫৬৭৮৯"[d]);

const TRACKS = {
  quranic: {
    name: "কুরআনিক আরবি", sub: "কুরআনের শব্দ ও ব্যাকরণ", ar: "قُرْآنِيَّة",
    grad: "linear-gradient(135deg,#1B4332,#2E7D52)", bar: "linear-gradient(90deg,#1B4332,#4CAF82)",
    prog: 45, count: "৯/২০ পাঠ", eyebrow: "কুরআনিক ট্র্যাক",
    unit: "ইউনিট ১ · সালাহর শব্দভাণ্ডার", unitAr: "مُفْرَدَاتُ الصَّلَاةِ",
  },
  conv: {
    name: "কথা আরবি", sub: "দৈনন্দিন কথোপকথন", ar: "مُحَادَثَة",
    grad: "linear-gradient(135deg,#0D4A4A,#1A8080)", bar: "linear-gradient(90deg,#0D4A4A,#1A8080)",
    prog: 22, count: "৩/১৪ পাঠ", eyebrow: "কথোপকথন ট্র্যাক",
    unit: "ইউনিট ১ · সালাম ও পরিচয়", unitAr: "التَّحِيَّةُ وَالتَّعَارُف",
  },
};

const TYPE_LABEL = { mc: "বাছাই", tb: "বাক্য গঠন", fib: "শূন্যস্থান", dd: "মিলকরণ", tf: "সত্য-মিথ্যা" };

const CONV_Q = [
  { type: "mc", k: "সঠিক উত্তর বেছে নিন", kc: "#4F46E5", q: "অর্থ কী?", ar: "مَا اسْمُكَ؟", tr: "mā ismuka?",
    opts: ["আপনার নাম কী?", "আপনি কোথায় থাকেন?", "আপনার বয়স কত?", "আপনি কেমন আছেন?"], correct: 0, audio: true,
    note: "মা (কী) + اسْم (নাম) + ـكَ (তোমার) — সম্বোধনে শেষে ك যুক্ত হয়।" },
  { type: "tb", k: "বাক্য তৈরি করুন", kc: "#0D4A4A", prompt: '"আপনি কেমন আছেন?"',
    bank: ["حَالُكَ", "بِخَيْرٍ", "كَيْفَ", "اِسْمِي"], correct: "كَيْفَ حَالُكَ",
    note: "প্রশ্নবোধক كَيْفَ (কেমন) সবসময় বাক্যের শুরুতে বসে।" },
  { type: "fib", k: "শূন্যস্থান পূরণ করুন", kc: "#B45309", sent: ["أَنَا", "_", "خَيْرٍ"],
    opts: ["بِ", "فِي", "مِنْ"], correct: 0, gloss: '"আমি ভালো আছি"',
    note: "بِخَيْرٍ-এ অব্যয় بِ পরের শব্দের সাথে জুড়ে লেখা হয়।" },
  { type: "dd", k: "শব্দ মিলিয়ে দিন", kc: "#7C3AED",
    pairs: [["سَلَام", "শান্তি"], ["اِسْم", "নাম"], ["أَخ", "ভাই"], ["بَيْت", "ঘর"]],
    note: "এই বিশেষ্যগুলোর শেষ হরকত বাক্যে অবস্থান অনুযায়ী বদলায়।" },
  { type: "tf", k: "সত্য না মিথ্যা?", kc: "#4338CA", stAr: "شُكْرًا", st: 'অর্থ "ধন্যবাদ"', correct: true,
    note: "উত্তরে বলা হয় عَفْوًا — অর্থাৎ 'কিছু মনে করবেন না'।" },
];

const QURANIC_Q = [
  { type: "mc", k: "শুনুন ও বেছে নিন", kc: "#0284C7", q: "সঠিক অর্থ বেছে নিন", ar: "سُجُودٌ", tr: "sujūd",
    opts: ["রুকু করা", "সিজদা করা", "দাঁড়ানো", "বসা"], correct: 1, audio: true,
    note: "سُجُود একটি মাসদার (ক্রিয়ামূল) — ধাতু س-ج-د। কুরআনে ৯২ বার।" },
  { type: "mc", k: "ধাতু পরিবার", kc: "#1B6B3A", q: "س-ج-د ধাতু থেকে কোন শব্দটি এসেছে?", arOpts: true,
    opts: ["مَسْجِد", "سَمَاء", "قَلَم", "كِتَاب"], correct: 0,
    note: "مَسْجِد = সিজদার স্থান। শুরুর مَـ স্থান বোঝায় (ইসমু যারফ)।" },
  { type: "fib", k: "আয়াত পূরণ করুন", kc: "#2E7D32", sent: ["وَاسْجُدْ", "وَ", "_"],
    opts: ["اقْتَرِبْ", "اذْهَبْ", "اقْرَأْ"], correct: 0, gloss: '"সিজদা করুন এবং নৈকট্য লাভ করুন" — আলাক ১৯',
    note: "সিজদার সাথে নৈকট্য — এ আয়াতে তিলাওয়াতের সিজদাও রয়েছে।" },
  { type: "reflect", k: "তাদাব্বুর", kc: "#7B4F00", ar: "وَاسْجُدْ وَاقْتَرِب",
    b: '"সিজদা করুন এবং (আল্লাহর) নৈকট্য লাভ করুন।" — সূরা আলাক ১৯',
    rf: "রাসূলুল্লাহ ﷺ বলেছেন: বান্দা সিজদারত অবস্থায় তার রবের সবচেয়ে নিকটে থাকে। — সহীহ মুসলিম" },
];

const DD_R = [2, 0, 3, 1];

const AYAHS = [
  { num: "١", taf: "বিসমিল্লাহ দিয়ে শুরু — প্রতিটি কাজ আল্লাহর নামে শুরু করার শিক্ষা। আর-রহমান ও আর-রহীম — দুটিই রহমতের সিফাত, প্রথমটি ব্যাপকতায়, দ্বিতীয়টি স্থায়িত্বে।",
    words: [
      { a: "بِسْمِ", b: "নামে", r: "س-م-و" }, { a: "اللَّهِ", b: "আল্লাহর" },
      { a: "الرَّحْمَٰنِ", b: "পরম করুণাময়", r: "ر-ح-م" }, { a: "الرَّحِيمِ", b: "অতি দয়ালু", r: "ر-ح-م" },
    ], bnT: "পরম করুণাময় অতি দয়ালু আল্লাহর নামে।", src: " — ড. আবু বকর যাকারিয়া" },
  { num: "٢", taf: '"হামদ" শুধু প্রশংসা নয় — ভালোবাসা ও সম্মানসহ প্রশংসা। "রব" অর্থ স্রষ্টা, মালিক, পালনকর্তা ও পরিচালক — সকল জগতের।',
    words: [
      { a: "الْحَمْدُ", b: "সকল প্রশংসা", r: "ح-م-د" }, { a: "لِلَّهِ", b: "আল্লাহরই" },
      { a: "رَبِّ", b: "রব", r: "ر-ب-ب" }, { a: "الْعَالَمِينَ", b: "সকল জগতের", r: "ع-ل-م" },
    ], bnT: "সকল প্রশংসা সৃষ্টিকুলের রব আল্লাহরই।" },
  { num: "٣",
    words: [
      { a: "الرَّحْمَٰنِ", b: "পরম করুণাময়", r: "ر-ح-م" }, { a: "الرَّحِيمِ", b: "অতি দয়ালু", r: "ر-ح-م" },
    ], bnT: "যিনি পরম করুণাময়, অতি দয়ালু।" },
];

const SRS_REV = [
  { ar: "رَحْمَة", m: "রহমত, দয়া", root: "ر-ح-م", fq: "কুরআনে #২৮", pill: ["rem", "স্মরণে আছে"],
    cA: "وَرَحْمَتِي وَسِعَتْ كُلَّ شَيْءٍ", cB: '"আমার রহমত সবকিছু পরিব্যাপ্ত করেছে" — আরাফ ১৫৬' },
  { ar: "كِتَاب", m: "কিতাব, বই", root: "ك-ت-ب", fq: "কুরআনে #৪২", pill: ["lrn", "শেখা হচ্ছে"],
    cA: "ذَٰلِكَ الْكِتَابُ لَا رَيْبَ فِيهِ", cB: '"এই সেই কিতাব, যাতে কোনো সন্দেহ নেই" — বাকারা ২' },
  { ar: "صِرَاط", m: "পথ, রাস্তা", root: "ص-ر-ط", fq: "কুরআনে #৯৬", pill: ["rem", "স্মরণে আছে"],
    cA: "اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ", cB: '"আমাদের সরল পথ দেখান" — ফাতিহা ৬' },
];
const SRS_MEMO = [
  { ar: "نُور", m: "আলো, জ্যোতি", root: "ن-و-ر", fq: "কুরআনে #১১২", pill: ["new", "নতুন"],
    cA: "اللَّهُ نُورُ السَّمَاوَاتِ وَالْأَرْضِ", cB: '"আল্লাহ আসমান ও জমিনের নূর" — নূর ৩৫' },
  { ar: "قَلْب", m: "অন্তর, হৃদয়", root: "ق-ل-ب", fq: "কুরআনে #৮৪", pill: ["new", "নতুন"],
    cA: "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ", cB: '"আল্লাহর স্মরণেই অন্তর প্রশান্ত হয়" — রা\'দ ২৮' },
];
const RATES = [
  { l: "আবার", s: "< ১ মিনিট", c: "#C0392B" }, { l: "কঠিন", s: "১০ মিনিট", c: "#E67E22" },
  { l: "ভালো", s: "১ দিন", c: "#2E7D32" }, { l: "সহজ", s: "৪ দিন", c: "#2471A3" },
];

const CHAT = [
  { bot: { ar: "السَّلَامُ عَلَيْكُمْ وَرَحْمَةُ اللهِ", bn: "আপনার ওপর শান্তি ও আল্লাহর রহমত" },
    chip: { ar: "وَعَلَيْكُمُ السَّلَامُ", bn: "এবং আপনার ওপরও শান্তি" } },
  { bot: { ar: "أَهْلًا وَسَهْلًا! مَا اسْمُكَ؟", bn: "স্বাগতম! আপনার নাম কী?" },
    chip: { ar: "اِسْمِي عَبْدُ اللهِ", bn: "আমার নাম আব্দুল্লাহ" } },
  { bot: { ar: "مَا شَاءَ اللهُ! كَيْفَ حَالُكَ؟", bn: "মাশাআল্লাহ! কেমন আছেন?" },
    chip: { ar: "أَنَا بِخَيْرٍ، الْحَمْدُ لِلّٰهِ", bn: "ভালো আছি, আলহামদুলিল্লাহ" } },
  { bot: { ar: "أَحْسَنْتَ! تَكَلَّمْتَ جَيِّدًا 🌟", bn: "চমৎকার! আপনি খুব সুন্দর বলেছেন" }, chip: null },
];

const LB = [
  { r: "১", n: "হাফিজ_রাজশাহী", xp: "১,২৪০", m: "🥇" },
  { r: "২", n: "তালিবা_ঢাকা", xp: "৬২০", m: "🥈" },
  { r: "৩", n: "আবরার — আপনি", xp: "৪৫০", m: "🥉", me: true },
  { r: "৪", n: "মুতাআল্লিম_৪৭", xp: "৪৩০" },
  { r: "৫", n: "উম্মে_আয়মান", xp: "৩৯০" },
  { r: "৬", n: "আবু_সাঈদ_ctg", xp: "৩১০" },
  { r: "৭", n: "নববী_ছাত্র", xp: "২৬০" },
];

const OB = [
  { q: "আপনি কি আরবি হরফ পড়তে পারেন?", opts: ["হ্যাঁ, সাবলীলভাবে", "ধীরে ধীরে পারি", "এখনো পারি না"] },
  { q: "এই শব্দটির অর্থ কী?", ar: "كِتَاب", opts: ["বই", "কলম", "ঘর", "জানি না"] },
  { q: "প্রতিদিন কত সময় দিতে পারবেন?", opts: ["৫ মিনিট", "১০ মিনিট", "২০+ মিনিট"] },
];

/* ── svg helpers ───────────────────────────────────────────── */

const DoneBead = ({ x, y, label, fill, stars, onClick }) => (
  <g className="bead" onClick={onClick}>
    <circle className="ring" cx={x} cy={y} r="19" fill={fill} />
    <circle cx={x - 6} cy={y - 6} r="5" fill="rgba(255,255,255,.18)" />
    <text x={x} y={y + 5.5} textAnchor="middle" fontSize="14" fill="#E9C25B">✦</text>
    <text className="blab" x={x} y={y + 37} textAnchor="middle">{label}</text>
    {stars && <text className="bstar" x={x} y={y + 50} textAnchor="middle">{stars}</text>}
  </g>
);
const LockBead = ({ x, y, label }) => (
  <g>
    <circle cx={x} cy={y} r="17" fill="#EFEADE" stroke="#D8D0BD" strokeWidth="1.5" />
    <text x={x} y={y + 5} textAnchor="middle" fontSize="11" fill="#A39B85">🔒</text>
    <text className="bsub" x={x} y={y - 25} textAnchor="middle">{label}</text>
  </g>
);
const Tassel = ({ x, y }) => (
  <g opacity=".9">
    <line x1={x} y1={y} x2={x + 20} y2={y + 22} stroke="#C9A23E" strokeWidth="2.5" strokeLinecap="round" />
    <path d={`M ${x + 14} ${y + 20} L ${x + 26} ${y + 20} L ${x + 30} ${y + 46} L ${x + 10} ${y + 46} Z`} fill="#D4A017" />
    <line x1={x + 14} y1={y + 46} x2={x + 12} y2={y + 60} stroke="#A87B0A" strokeWidth="2" />
    <line x1={x + 20} y1={y + 46} x2={x + 20} y2={y + 62} stroke="#A87B0A" strokeWidth="2" />
    <line x1={x + 26} y1={y + 46} x2={x + 28} y2={y + 60} stroke="#A87B0A" strokeWidth="2" />
  </g>
);
const Icon = ({ d }) => (
  <svg width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor"
    strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><path d={d} /></svg>
);
const BOOK = "M4 19.5A2.5 2.5 0 0 1 6.5 17H20 M4 19.5A2.5 2.5 0 0 0 6.5 22H20V2H6.5A2.5 2.5 0 0 0 4 4.5v15z";
const VOICE = "M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z M19 10v2a7 7 0 0 1-14 0v-2 M12 19v4";

/* ════════════════════════════════════════════════════════════ */

export default function TaallamDemo() {
  const [screen, setScreen] = useState("home");
  const [toast, setToast] = useState(null);

  /* onboarding */
  const [obStep, setObStep] = useState(0);
  const [obSel, setObSel] = useState(null);

  /* lesson engine */
  const [lesson, setLesson] = useState(null);
  const [exIdx, setExIdx] = useState(0);
  const [hearts, setHearts] = useState(5);
  const [wrongs, setWrongs] = useState(0);
  const [wrongTypes, setWrongTypes] = useState([]);
  const [result, setResult] = useState(null);
  const [mcSel, setMcSel] = useState(null);
  const [tbAns, setTbAns] = useState([]);
  const [fibSel, setFibSel] = useState(null);
  const [tfSel, setTfSel] = useState(null);
  const [ddL, setDdL] = useState(null);
  const [ddM, setDdM] = useState([]);
  const [ddBad, setDdBad] = useState(null);
  const [aud, setAud] = useState(false);

  /* srs */
  const [srsMode, setSrsMode] = useState("rev");
  const [srsIdx, setSrsIdx] = useState(0);
  const [flip, setFlip] = useState(false);

  /* quran */
  const [lit, setLit] = useState(null);
  const [qrOn, setQrOn] = useState(false);
  const [qrPct, setQrPct] = useState(0);
  const [bms, setBms] = useState([0]);
  const [tafOpen, setTafOpen] = useState(null);

  /* chat */
  const [msgs, setMsgs] = useState([]);
  const [chStep, setChStep] = useState(0);
  const [rec, setRec] = useState(false);
  const msgsRef = useRef(null);

  /* settings / profile */
  const [sChime, setSChime] = useState(true);
  const [sTakbeer, setSTakbeer] = useState(true);
  const [sNotif, setSNotif] = useState(true);
  const [freezes, setFreezes] = useState(2);
  const [shareOpen, setShareOpen] = useState(false);

  const timers = useRef([]);
  const later = (fn, ms) => timers.current.push(setTimeout(fn, ms));
  useEffect(() => () => timers.current.forEach(clearTimeout), []);

  const ping = (m) => { setToast(m); later(() => setToast(null), 2100); };

  /* quran playback */
  useEffect(() => {
    if (!qrOn) return;
    const iv = setInterval(() => {
      setQrPct((p) => { if (p >= 100) { setQrOn(false); setLit(null); return 0; } return p + 1.4; });
    }, 120);
    AYAHS[0].words.forEach((_, i) => later(() => setLit("0-" + i), i * 900 + 200));
    later(() => setLit(null), AYAHS[0].words.length * 900 + 700);
    return () => clearInterval(iv);
  }, [qrOn]);

  /* chat bootstrap + autoscroll */
  useEffect(() => {
    if (screen === "chat" && msgs.length === 0)
      setMsgs([{ who: "bot", ...CHAT[0].bot }]);
  }, [screen, msgs.length]);
  useEffect(() => {
    if (msgsRef.current) msgsRef.current.scrollTop = msgsRef.current.scrollHeight;
  }, [msgs, rec]);

  /* ── lesson logic ── */
  const queue = lesson === "quranic" ? QURANIC_Q : lesson === "conv" ? CONV_Q : [];
  const ex = queue[exIdx];
  const bar = queue.length ? ((exIdx + (result === "right" ? 1 : 0)) / queue.length) * 100 : 0;

  const resetEx = () => {
    setResult(null); setMcSel(null); setTbAns([]); setFibSel(null);
    setTfSel(null); setDdL(null); setDdM([]); setDdBad(null);
  };
  const startLesson = (t) => {
    setLesson(t); setExIdx(0); setHearts(5); setWrongs(0); setWrongTypes([]);
    resetEx(); setScreen("ex");
  };
  const miss = (type) => {
    setHearts((h) => Math.max(0, h - 1)); setWrongs((w) => w + 1);
    setWrongTypes((s) => (s.includes(type) ? s : [...s, type]));
  };
  const check = () => {
    if (!ex || result) return;
    let ok = false;
    if (ex.type === "mc") ok = mcSel === ex.correct;
    if (ex.type === "tb") ok = tbAns.map((i) => ex.bank[i]).join(" ") === ex.correct;
    if (ex.type === "fib") ok = fibSel === ex.correct;
    if (ex.type === "tf") ok = tfSel === ex.correct;
    if (ok) setResult("right"); else { setResult("wrong"); miss(ex.type); }
  };
  const retry = () => { setResult(null); setMcSel(null); setTbAns([]); setFibSel(null); setTfSel(null); };
  const nextEx = () => {
    if (exIdx + 1 < queue.length) { resetEx(); setExIdx(exIdx + 1); }
    else setScreen("complete");
  };
  const pickDD = (side, i) => {
    if (result || ddM.includes(side === "L" ? i : DD_R[i])) return;
    if (side === "L") { setDdL(i); return; }
    if (ddL === null) return;
    const pairIdx = DD_R[i];
    if (pairIdx === ddL) {
      const m = [...ddM, ddL]; setDdM(m); setDdL(null);
      if (m.length === ex.pairs.length) setResult("right");
    } else {
      setDdBad([ddL, i]); miss("dd");
      later(() => { setDdBad(null); setDdL(null); }, 600);
    }
  };
  const closeLesson = () => {
    setScreen(lesson === "quranic" ? "track-quranic" : "track-conv");
    ping("অগ্রগতি সংরক্ষিত ✓");
  };
  const ready =
    ex && ((ex.type === "mc" && mcSel !== null) || (ex.type === "tb" && tbAns.length > 0) ||
      (ex.type === "fib" && fibSel !== null) || (ex.type === "tf" && tfSel !== null));
  const ansText = ex
    ? ex.type === "mc" || ex.type === "fib" ? ex.opts[ex.correct]
      : ex.type === "tb" ? ex.correct
        : ex.type === "tf" ? (ex.correct ? "সত্য" : "মিথ্যা") : ""
    : "";
  const accuracy = Math.round((queue.length / (queue.length + wrongs)) * 100) || 100;
  const xpEarned = queue.length * 10 + (wrongs === 0 ? 15 : 0);

  /* ── srs ── */
  const srsCards = srsMode === "rev" ? SRS_REV : SRS_MEMO;
  const card = srsCards[srsIdx];
  const startSrs = (m) => { setSrsMode(m); setSrsIdx(0); setFlip(false); setScreen("review"); };
  const rate = () => { setFlip(false); setSrsIdx(srsIdx + 1); };

  /* ── chat ── */
  const sendChip = () => {
    const step = CHAT[chStep];
    if (!step || !step.chip) return;
    setMsgs((m) => [...m, { who: "me", ...step.chip }]);
    const nextStep = chStep + 1;
    setChStep(nextStep);
    if (CHAT[nextStep]) later(() => setMsgs((m) => [...m, { who: "bot", ...CHAT[nextStep].bot }]), 750);
  };
  const doMic = () => {
    if (rec) return;
    setRec(true);
    later(() => {
      setRec(false);
      setMsgs((m) => [...m, { who: "sys", bn: "🎙 উচ্চারণ মূল্যায়ন: ৯২% — মাখরাজ চমৎকার ✓" }]);
    }, 1700);
  };

  const navOn = (id) =>
    screen === id ||
    (id === "home" && (screen.startsWith("track") || screen === "onboard")) ||
    (id === "profile" && (screen === "settings" || screen === "leaderboard"));

  const heartsRow = (
    <span className="hearts">{[0, 1, 2, 3, 4].map((i) => (
      <span key={i} className={"hrt" + (i < hearts ? "" : " off")}>♥</span>))}</span>
  );

  const JUMPS = [
    ["অনবোর্ডিং", () => { setObStep(0); setObSel(null); setScreen("onboard"); }],
    ["হোম", () => setScreen("home")],
    ["কথা-পাঠ", () => startLesson("conv")],
    ["কুরআনিক পাঠ", () => startLesson("quranic")],
    ["রিভিউ", () => startSrs("rev")],
    ["মুখস্থ", () => startSrs("memo")],
    ["কুরআন রিডার", () => setScreen("quran")],
    ["মুহাদাসা AI", () => setScreen("chat")],
    ["লিডারবোর্ড", () => setScreen("leaderboard")],
    ["প্রোফাইল", () => setScreen("profile")],
    ["সেটিংস", () => setScreen("settings")],
  ];

  /* ════════ render ════════ */
  return (
    <div className="ta">
      <style>{CSS}</style>
      <div className="bgpat" /><div className="bgglow" />

      <div className="mark">
        <span className="a">تَعَلَّمْ</span>
        <span className="l">Ta'allam · Sahih Arabic</span>
      </div>

      <div className="phone"><div className="ps">
        <div className="notch" />
        <div className="sbar"><span>৯:৪১</span><span>۞</span></div>
        <div className={"toast" + (toast ? " show" : "")}>{toast || ""}</div>

        <div className="body">

          {/* ═══ ONBOARDING ═══ */}
          <section className={"scr" + (screen === "onboard" ? " on" : "")}>
            <div className="ob">
              <div className="ob-logo">تَعَلَّمْ</div>
              <div className="ob-eyebrow">স্তর নির্ণয় কুইজ</div>
              <div className="ob-dots">{[0, 1, 2].map((i) => <i key={i} className={i < obStep ? "f" : ""}></i>)}</div>
              {obStep < 3 ? (
                <>
                  <div className="ob-card">
                    <h2>{OB[obStep].q}</h2>
                    {OB[obStep].ar && <div className="ob-ar">{OB[obStep].ar}</div>}
                  </div>
                  <div className="ob-opts">
                    {OB[obStep].opts.map((o, i) => (
                      <button key={i} className={"ob-opt" + (obSel === i ? " sel" : "")}
                        onClick={() => {
                          setObSel(i);
                          later(() => { setObSel(null); setObStep(obStep + 1); }, 380);
                        }}>{o}</button>
                    ))}
                  </div>
                  <div style={{ marginTop: "auto", fontSize: 11, color: "#B9AF97" }}>প্রশ্ন {bn(obStep + 1)}/৩</div>
                </>
              ) : (
                <div className="ob-res">
                  <div className="ob-star">✦</div>
                  <h2>আপনার স্তর: শিক্ষানবিস</h2>
                  <p>সুপারিশ: <b style={{ color: "var(--forest)" }}>কুরআনিক ট্র্যাক</b><br />সালাহর শব্দভাণ্ডার থেকে শুরু করুন</p>
                  <button className="bigbtn" onClick={() => setScreen("home")}>বিসমিল্লাহ — শুরু করুন</button>
                </div>
              )}
            </div>
          </section>

          {/* ═══ HOME ═══ */}
          <section className={"scr" + (screen === "home" ? " on" : "")}>
            <div className="hh">
              <div className="av">আ</div>
              <div className="chips">
                <div className="chip fl"><span className="i">🔥</span>১২</div>
                <div className="chip xp"><span className="i">✦</span>৪৫০ XP</div>
              </div>
            </div>
            <div className="greet">
              <div className="dl">শুক্রবার · ২৬ যিলহজ ১৪৪৭</div>
              <h1>জুমু'আ মুবারাকাহ, আবরার</h1>
              <p>⚡ <b>দিনের প্রথম পাঠে ২× XP</b> — মাগরিবের আগে ৫ মিনিট দিন</p>
            </div>

            <div className="tcard" onClick={() => setScreen("track-quranic")}>
              <div className="tch" style={{ background: TRACKS.quranic.grad }}>
                <span className="tcbig">{TRACKS.quranic.ar}</span>
                <div className="tcic"><Icon d={BOOK} /></div>
                <div className="tct"><h3>{TRACKS.quranic.name}</h3><small>{TRACKS.quranic.sub}</small></div>
              </div>
              <div className="tcb">
                <div className="tcbar"><i style={{ width: TRACKS.quranic.prog + "%", background: TRACKS.quranic.bar }} /></div>
                <span>{TRACKS.quranic.count}</span><span className="c">›</span>
              </div>
            </div>

            <div className="tcard" onClick={() => setScreen("track-conv")}>
              <div className="tch" style={{ background: TRACKS.conv.grad }}>
                <span className="tcbig">{TRACKS.conv.ar}</span>
                <div className="tcic"><Icon d={VOICE} /></div>
                <div className="tct"><h3>{TRACKS.conv.name}</h3><small>{TRACKS.conv.sub}</small></div>
              </div>
              <div className="tcb">
                <div className="tcbar"><i style={{ width: TRACKS.conv.prog + "%", background: TRACKS.conv.bar }} /></div>
                <span>{TRACKS.conv.count}</span><span className="c">›</span>
              </div>
            </div>

            <div className="wk">
              <div className="r1">
                <h4>সাপ্তাহিক XP · ৪৫০/৬০০</h4>
                <span className="lb" onClick={() => setScreen("leaderboard")}>লিডারবোর্ড #৩ ›</span>
              </div>
              <div className="wkbar"><i /></div>
              <div className="r2">লক্ষ্য পূরণে আর ১৫০ XP — ইনশাআল্লাহ হয়ে যাবে</div>
            </div>

            <div className="srs">
              <div className="srsc m" onClick={() => startSrs("memo")}>
                <div className="srsi">✍️</div>
                <div><h4>মুখস্থ</h4><span>নতুন শব্দ</span></div>
                <div className="srsb">৮</div>
              </div>
              <div className="srsc r" onClick={() => startSrs("rev")}>
                <div className="srsi">↻</div>
                <div><h4>রিভিউ</h4><span>আজ বাকি</span></div>
                <div className="srsb">১৪</div>
              </div>
            </div>
          </section>

          {/* ═══ TRACK: QURANIC ═══ */}
          <section className={"scr" + (screen === "track-quranic" ? " on" : "")}>
            <div className="td" style={{ background: TRACKS.quranic.grad }}>
              <span className="tdbig">{TRACKS.quranic.ar}</span>
              <div className="tdt">
                <button className="back" onClick={() => setScreen("home")}>‹</button>
                <span className="tde">{TRACKS.quranic.eyebrow}</span>
              </div>
              <h2>{TRACKS.quranic.unit}</h2>
              <div className="tds">{TRACKS.quranic.unitAr}</div>
              <div className="tdp"><div className="tdb"><i style={{ width: "45%" }} /></div><span>৯/২০</span></div>
              <div className="uchips">
                <span className="uc on">সালাহ</span>
                <span className="uc lk">শীর্ষ ১০০ শব্দ</span>
                <span className="uc lk">আসমা ও সিফাত</span>
              </div>
            </div>
            <div className="path">
              <svg viewBox="0 0 360 396" xmlns="http://www.w3.org/2000/svg">
                <path d="M 95 28 C 200 28 285 50 285 102 C 285 154 90 132 80 190 C 73 232 150 262 230 262 C 290 262 322 288 308 322"
                  fill="none" stroke="#C9A23E" strokeWidth="2.5" strokeDasharray="1 7" strokeLinecap="round" opacity=".85" />
                <Tassel x={308} y={322} />
                <DoneBead x={95} y={28} label="তাকবীর" stars="★★★" fill="#1B4332" onClick={() => startLesson("quranic")} />
                <DoneBead x={285} y={102} label="কিয়াম" stars="★★☆" fill="#1B4332" onClick={() => startLesson("quranic")} />
                <g className="bead" onClick={() => startLesson("quranic")}>
                  <circle className="pring" cx="80" cy="190" r="30" fill="none" stroke="#D4A017" strokeWidth="2" />
                  <circle className="ring" cx="80" cy="190" r="24" fill="url(#gq)" />
                  <circle cx="72" cy="182" r="6" fill="rgba(255,255,255,.3)" />
                  <text x="80" y="198" textAnchor="middle" fontSize="18" fill="#0D2218" fontFamily="Amiri,serif">س</text>
                  <text className="blab" x="124" y="186" fontWeight="700">সিজদা</text>
                  <text className="bsub" x="124" y="201">পাঠ ১০ · ৪টি অনুশীলন</text>
                </g>
                <g className="cpill" onClick={() => startLesson("quranic")}>
                  <rect x="36" y="224" width="116" height="33" rx="16.5" fill="#1B4332" />
                  <text x="94" y="245" textAnchor="middle" fontFamily="Hind Siliguri,sans-serif" fontSize="13" fontWeight="700" fill="#F5F0E8">চালিয়ে যান →</text>
                </g>
                <LockBead x={230} y={262} label="রুকু" />
                <g>
                  <circle cx="308" cy="322" r="19" fill="#FBF3DE" stroke="#D4A017" strokeWidth="1.5" strokeDasharray="4 4" />
                  <text x="308" y="328" textAnchor="middle" fontSize="15" fill="#A87B0A">★</text>
                  <text className="bsub" x="308" y="295" textAnchor="middle">ইউনিট পরীক্ষা</text>
                </g>
                <defs><radialGradient id="gq" cx=".35" cy=".3" r=".9">
                  <stop offset="0" stopColor="#E9C25B" /><stop offset="1" stopColor="#C9920E" /></radialGradient></defs>
              </svg>
            </div>
          </section>

          {/* ═══ TRACK: CONVERSATIONAL ═══ */}
          <section className={"scr" + (screen === "track-conv" ? " on" : "")}>
            <div className="td" style={{ background: TRACKS.conv.grad }}>
              <span className="tdbig">{TRACKS.conv.ar}</span>
              <div className="tdt">
                <button className="back" onClick={() => setScreen("home")}>‹</button>
                <span className="tde">{TRACKS.conv.eyebrow}</span>
              </div>
              <h2>{TRACKS.conv.unit}</h2>
              <div className="tds">{TRACKS.conv.unitAr}</div>
              <div className="tdp"><div className="tdb"><i style={{ width: "22%" }} /></div><span>৩/১৪</span></div>
            </div>
            <div className="path">
              <svg viewBox="0 0 360 386" xmlns="http://www.w3.org/2000/svg">
                <path d="M 272 30 C 170 30 88 58 88 112 C 88 160 208 148 208 192 C 208 236 292 212 292 252 C 292 296 220 312 148 312"
                  fill="none" stroke="#C9A23E" strokeWidth="2.5" strokeDasharray="1 7" strokeLinecap="round" opacity=".85" />
                <Tassel x={148} y={312} />
                <DoneBead x={272} y={30} label="সালাম" stars="★★★" fill="#0D4A4A" onClick={() => startLesson("conv")} />
                <g className="bead" onClick={() => startLesson("conv")}>
                  <circle className="pring" cx="88" cy="112" r="30" fill="none" stroke="#D4A017" strokeWidth="2" />
                  <circle className="ring" cx="88" cy="112" r="24" fill="url(#gc)" />
                  <circle cx="80" cy="104" r="6" fill="rgba(255,255,255,.3)" />
                  <text x="88" y="120" textAnchor="middle" fontSize="18" fill="#0D2218" fontFamily="Amiri,serif">ك</text>
                  <text className="blab" x="132" y="108" fontWeight="700">পরিচয়</text>
                  <text className="bsub" x="132" y="123">পাঠ ৪ · ৫টি অনুশীলন</text>
                </g>
                <g className="cpill" onClick={() => startLesson("conv")}>
                  <rect x="44" y="146" width="116" height="33" rx="16.5" fill="#0D4A4A" />
                  <text x="102" y="167" textAnchor="middle" fontFamily="Hind Siliguri,sans-serif" fontSize="13" fontWeight="700" fill="#F5F0E8">চালিয়ে যান →</text>
                </g>
                <g>
                  <rect x="190" y="186" width="36" height="20" rx="4" fill="#C9920E" />
                  <rect x="188" y="178" width="40" height="12" rx="6" fill="#E9C25B" />
                  <circle cx="208" cy="190" r="3" fill="#7A5500" />
                  <text className="bsub" x="208" y="224" textAnchor="middle">বোনাস XP</text>
                </g>
                <LockBead x={292} y={252} label="পরিবার" />
                <LockBead x={148} y={312} label="বাজার" />
                <defs><radialGradient id="gc" cx=".35" cy=".3" r=".9">
                  <stop offset="0" stopColor="#E9C25B" /><stop offset="1" stopColor="#C9920E" /></radialGradient></defs>
              </svg>
            </div>
          </section>

          {/* ═══ EXERCISE ═══ */}
          <section className={"scr" + (screen === "ex" ? " on" : "")}>
            <div className="ext">
              <button className="exx" onClick={closeLesson}>✕</button>
              <div className="exp"><i style={{ width: bar + "%" }} /></div>
              {heartsRow}
            </div>

            {ex && (
              <div className="exw">
                <div className="exk" style={{ color: ex.kc }}>{ex.k} · {bn(exIdx + 1)}/{bn(queue.length)}</div>

                {ex.type === "mc" && (
                  <>
                    <h2 className="exq">{ex.q}</h2>
                    {ex.ar && (
                      <>
                        <div className="exword">
                          {ex.audio && (
                            <button className={"abtn" + (aud ? " pl" : "")}
                              onClick={() => { setAud(true); later(() => setAud(false), 1500); }}>
                              <span className="eq"><i /><i /><i /><i /></span>
                            </button>
                          )}
                          <div className="arw">{ex.ar}</div>
                        </div>
                        {ex.tr && <div className="trl">{ex.tr}</div>}
                      </>
                    )}
                    <div className="opts">
                      {ex.opts.map((o, i) => {
                        let c = "opt" + (ex.arOpts ? " arf" : "");
                        if (!result && mcSel === i) c += " sel";
                        if (result) {
                          if (i === ex.correct) c += " ok";
                          else if (i === mcSel) c += " no";
                          else c += " dim";
                        }
                        return <button key={i} className={c} onClick={() => !result && setMcSel(i)}>{o}</button>;
                      })}
                    </div>
                  </>
                )}

                {ex.type === "tb" && (
                  <>
                    <h2 className="exq">আরবিতে বলুন</h2>
                    <div className="prompt"><div className="f">🗨</div><p>{ex.prompt}</p></div>
                    <div className="tbl">
                      {tbAns.map((bi, p) => (
                        <button key={p} className="tok" onClick={() => !result && setTbAns(tbAns.filter((_, j) => j !== p))}>{ex.bank[bi]}</button>
                      ))}
                    </div>
                    <div className="tbh">{tbAns.length === 0 ? "নিচের শব্দে চাপ দিয়ে বাক্য সাজান" : "সরাতে শব্দে চাপ দিন"}</div>
                    <div className="bank">
                      {ex.bank.map((w, i) => (
                        <button key={i} className={"tok" + (tbAns.includes(i) ? " used" : "")}
                          onClick={() => !result && !tbAns.includes(i) && setTbAns([...tbAns, i])}>{w}</button>
                      ))}
                    </div>
                  </>
                )}

                {ex.type === "fib" && (
                  <>
                    <h2 className="exq">শূন্যস্থানে সঠিক শব্দ বসান</h2>
                    <div className="fibs">
                      {ex.sent.map((s, i) =>
                        s === "_" ? <span key={i} className="slot">{fibSel !== null ? ex.opts[fibSel] : "؟"}</span>
                          : <span key={i}>{s}</span>
                      )}
                    </div>
                    <div className="gloss">{ex.gloss}</div>
                    <div className="bank" style={{ marginTop: 16 }}>
                      {ex.opts.map((o, i) => {
                        let c = "tok";
                        if (!result && fibSel === i) c += " used";
                        if (result && i === ex.correct) c = "tok";
                        return (
                          <button key={i} className={c} style={result && i === ex.correct ? { borderColor: "var(--ok)", background: "var(--ok-bg)" } : undefined}
                            onClick={() => !result && setFibSel(i)}>{o}</button>
                        );
                      })}
                    </div>
                  </>
                )}

                {ex.type === "dd" && (
                  <>
                    <h2 className="exq">আরবি ও বাংলা মিলান</h2>
                    <div className="dd">
                      {ex.pairs.map((p, i) => {
                        let c = "ddi ar";
                        if (ddM.includes(i)) c += " mt";
                        else if (ddL === i) c += " sel";
                        if (ddBad && ddBad[0] === i) c += " bad";
                        return <button key={"l" + i} className={c} onClick={() => pickDD("L", i)}>{p[0]}</button>;
                      })}
                    </div>
                    <div className="dd" style={{ marginTop: 10 }}>
                      {DD_R.map((pi, i) => {
                        let c = "ddi bn";
                        if (ddM.includes(pi)) c += " mt";
                        if (ddBad && ddBad[1] === i) c += " bad";
                        return <button key={"r" + i} className={c} onClick={() => pickDD("R", i)}>{ex.pairs[pi][1]}</button>;
                      })}
                    </div>
                    <div className="tbh" style={{ marginTop: 12 }}>আগে আরবি, তারপর তার বাংলা অর্থে চাপ দিন</div>
                  </>
                )}

                {ex.type === "tf" && (
                  <>
                    <h2 className="exq">সত্য না মিথ্যা?</h2>
                    <div className="tfst">
                      <div className="a">{ex.stAr}</div>
                      <p>{ex.st}</p>
                    </div>
                    <div className="tfr">
                      {[true, false].map((v) => {
                        let c = "tfb " + (v ? "t" : "f");
                        if (!result && tfSel === v) c += " sel";
                        if (result) {
                          if (v === ex.correct) c += " ok";
                          else if (v === tfSel) c += " no";
                          else c += " dim";
                        }
                        return <button key={String(v)} className={c} onClick={() => !result && setTfSel(v)}>{v ? "সত্য ✓" : "মিথ্যা ✕"}</button>;
                      })}
                    </div>
                  </>
                )}

                {ex.type === "reflect" && (
                  <>
                    <h2 className="exq">একটু থামুন — চিন্তা করুন</h2>
                    <div className="refl">
                      <div className="a">{ex.ar}</div>
                      <div className="b">{ex.b}</div>
                      <div className="rbox"><b>হাদীস:</b> {ex.rf}</div>
                    </div>
                    <div className="ckz">
                      <button className="ck go" onClick={nextEx}>পড়েছি — পরবর্তী →</button>
                    </div>
                  </>
                )}

                {ex.type !== "reflect" && ex.type !== "dd" && (
                  <div className="ckz">
                    <button className={"ck" + (ready && !result ? " go" : "")}
                      disabled={!ready || !!result} onClick={check}>যাচাই করুন</button>
                  </div>
                )}
              </div>
            )}

            <div className={"fb" + (result ? " show" : "") + (result === "wrong" ? " bad" : "")}>
              {result === "right" ? (
                <>
                  <div className="fbr">
                    <span className="stmp">۞</span>
                    <div><h3>মাশাআল্লাহ! সঠিক</h3>{ex && ex.gloss && <p>{ex.gloss}</p>}</div>
                    <span className="xpp">+১০ XP</span>
                  </div>
                  {ex && ex.note && <div className="gnote"><b>ব্যাকরণ:</b> {ex.note}</div>}
                  <button className="nx" onClick={nextEx}>পরবর্তী →</button>
                </>
              ) : (
                <>
                  <div className="fbr">
                    <span className="stmp">✕</span>
                    <div><h3>সঠিক হয়নি</h3><p>সঠিক উত্তর: {ansText}</p></div>
                  </div>
                  <button className="nx bad" onClick={retry}>আবার চেষ্টা করুন</button>
                </>
              )}
            </div>
          </section>

          {/* ═══ COMPLETE ═══ */}
          <section className={"scr" + (screen === "complete" ? " on" : "")}>
            {screen === "complete" && (
              <div className="cmp">
                <span className="cstmp">۞</span>
                <h2>পাঠ সম্পন্ন!</h2>
                <div className="ls">{lesson ? TRACKS[lesson].unit : ""}</div>
                <div className="cstats">
                  <div className="cp"><div className="n">+{bn(xpEarned)}</div><div className="l">XP · ⚡২× প্রথম পাঠ</div></div>
                  <div className="cp"><div className="n">{bn(accuracy)}%</div><div className="l">সঠিকতা</div></div>
                  {wrongs === 0 && <div className="cp gold"><div className="n">✨ +১৫</div><div className="l">পারফেক্ট রান</div></div>}
                </div>
                {wrongTypes.length > 0 && (
                  <div className="weak">📌 দুর্বল ধরন: <b>{wrongTypes.map((t) => TYPE_LABEL[t]).join(", ")}</b> — রিভিউ ডেকে যোগ হলো</div>
                )}
                <div className="duaa">
                  <div className="a">رَبِّ زِدْنِي عِلْمًا</div>
                  <div className="b">"হে আমার রব! আমার জ্ঞান বৃদ্ধি করে দিন।"</div>
                  <div className="s">সূরা ত্বহা · ১১৪</div>
                </div>
                <button className="bigbtn" style={{ maxWidth: 280 }} onClick={closeLesson}>চালিয়ে যান</button>
              </div>
            )}
          </section>

          {/* ═══ SRS REVIEW / MEMORIZE ═══ */}
          <section className={"scr" + (screen === "review" ? " on" : "")}>
            <div className="rv">
              <div className="rvt">
                <button className="exx" onClick={() => setScreen("home")}>✕</button>
                <h2>{srsMode === "rev" ? "দৈনিক রিভিউ" : "মুখস্থ — নতুন শব্দ"}</h2>
                <span>{card ? `বাকি ${bn(srsCards.length - srsIdx)}/${bn(srsCards.length)}` : ""}</span>
              </div>

              {card ? (
                <>
                  <div className="rvc" onClick={() => !flip && setFlip(true)}>
                    <span className={"spill " + card.pill[0]}>{card.pill[1]}</span>
                    <div className="rvar">{card.ar}</div>
                    {!flip ? (
                      <div className="rvhint">অর্থ দেখতে কার্ডে চাপ দিন</div>
                    ) : (
                      <>
                        <div className="rvm">{card.m}</div>
                        <div className="rvchips">
                          <span className="rvchip" style={{ fontFamily: "var(--ar)", direction: "rtl" }}>ধাতু {card.root}</span>
                          <span className="rvchip g">{card.fq}</span>
                        </div>
                        <div className="ctx">
                          <div className="t">প্রসঙ্গ</div>
                          <div className="a">{card.cA}</div>
                          <div className="b">{card.cB}</div>
                        </div>
                      </>
                    )}
                  </div>
                  {flip && (
                    <div className="rates">
                      {RATES.map((r, i) => (
                        <button key={i} className="rate" style={{ background: r.c }} onClick={rate}>
                          <b>{r.l}</b><i>{r.s}</i>
                        </button>
                      ))}
                    </div>
                  )}
                </>
              ) : (
                <div className="rvdone">
                  <span className="cstmp">۞</span>
                  <h2 style={{ color: "var(--ink)", fontSize: 19, marginTop: 12 }}>
                    {srsMode === "rev" ? "আজকের রিভিউ শেষ!" : "নতুন শব্দ শেখা শেষ!"}
                  </h2>
                  <p style={{ fontSize: 12.5, color: "var(--ink-2)", marginTop: 5 }}>FSRS অনুযায়ী পরবর্তী রিভিউ নির্ধারিত হয়েছে</p>
                  <div className="cstats"><div className="cp"><div className="n">+১৫</div><div className="l">সেশন XP</div></div></div>
                  <button className="bigbtn" style={{ maxWidth: 260 }} onClick={() => setScreen("home")}>হোমে ফিরুন</button>
                </div>
              )}
            </div>
          </section>

          {/* ═══ QURAN READER ═══ */}
          <section className={"scr" + (screen === "quran" ? " on" : "")}>
            <div className="qh">
              <span className="orn">﴿</span>
              <div className="qsa">﴿ سُورَةُ الْفَاتِحَةِ ﴾</div>
              <div className="qsb">সূরা আল-ফাতিহা · শব্দে শব্দে</div>
              <div className="qm"><span>মাক্কী</span><span>✦</span><span>৭ আয়াত</span><span>✦</span><span>QPC হাফস · GTAF</span></div>
            </div>
            <div className="qb">
              <div className="bism">بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ</div>
              {AYAHS.map((ay, ai) => (
                <div className="ay" key={ai}>
                  <span className="aynum">{ay.num}</span>
                  <button className={"bm" + (bms.includes(ai) ? " on" : "")}
                    onClick={() => setBms(bms.includes(ai) ? bms.filter((x) => x !== ai) : [...bms, ai])}>
                    {bms.includes(ai) ? "⚑" : "⚐"}
                  </button>
                  <div className="ws">
                    {ay.words.map((w, wi) => {
                      const k = ai + "-" + wi;
                      return (
                        <button key={k} className={"w" + (lit === k ? " lit" : "")} onClick={() => setLit(lit === k ? null : k)}>
                          <span className="a">{w.a}</span>
                          <span className="b">{w.b}</span>
                          {w.r && <span className="r">{w.r}</span>}
                        </button>
                      );
                    })}
                  </div>
                  <div className="aybn">{ay.bnT}{ay.src && <i style={{ color: "#A39B85" }}>{ay.src}</i>}</div>
                  {ay.taf && (
                    <>
                      <button className="tafl" onClick={() => setTafOpen(tafOpen === ai ? null : ai)}>
                        তাফসীর {tafOpen === ai ? "▴" : "▾"}
                      </button>
                      {tafOpen === ai && <div className="tafb">{ay.taf} <i style={{ color: "#7A958A" }}>— তাফসীরে যাকারিয়া</i></div>}
                    </>
                  )}
                </div>
              ))}
            </div>
            <div className="qa">
              <button className="qp" onClick={() => setQrOn((v) => !v)}>{qrOn ? "❚❚" : "▶"}</button>
              <div style={{ flex: 1, minWidth: 0 }}>
                <h5>মিশারী আল-আফাসী</h5>
                <div className="qtr"><i style={{ width: qrPct + "%" }} /></div>
              </div>
              <span className="tm">১:০৪</span>
            </div>
          </section>

          {/* ═══ MUHADATHAH (AI chat) ═══ */}
          <section className={"scr" + (screen === "chat" ? " on" : "")}>
            <div className="ch">
              <div className="chh">
                <div className="chav">ي<i /></div>
                <div><h3>উস্তায ইউসুফ</h3><small>AI কথোপকথন সঙ্গী · ধীরে কথা বলে</small></div>
              </div>
              <div className="msgs" ref={msgsRef}>
                {msgs.map((m, i) =>
                  m.who === "sys" ? (
                    <div key={i} className="bub sys">{m.bn}</div>
                  ) : (
                    <div key={i} className={"bub " + (m.who === "me" ? "me" : "bot")}>
                      <div className="a">{m.ar}</div>
                      <div className="g">{m.bn}</div>
                    </div>
                  )
                )}
                {rec && <div className="bub sys">🎙 শুনছি… আরবিতে বলুন</div>}
              </div>
              {CHAT[chStep] && CHAT[chStep].chip && (
                <div className="chips2">
                  <button className="cchip" onClick={sendChip}>{CHAT[chStep].chip.ar}</button>
                </div>
              )}
              <div className="chbar">
                <div className="fld">{CHAT[chStep] && CHAT[chStep].chip ? "উত্তর বেছে নিন বা বলুন…" : "মাশাআল্লাহ — কথোপকথন সম্পন্ন ✓"}</div>
                <button className={"mic" + (rec ? " rec" : "")} onClick={doMic}>🎙</button>
              </div>
            </div>
          </section>

          {/* ═══ LEADERBOARD ═══ */}
          <section className={"scr" + (screen === "leaderboard" ? " on" : "")}>
            <div className="lb">
              <div className="lbh">
                <span className="orn">۞</span>
                <div className="tdt" style={{ position: "relative" }}>
                  <button className="back" onClick={() => setScreen("home")}>‹</button>
                  <span className="tde">সাপ্তাহিক প্রতিযোগিতা</span>
                </div>
                <h2>লিডারবোর্ড</h2>
                <p>বেনামী নাম · প্রতি জুমু'আয় রিসেট হয়</p>
              </div>
              <div className="lbl">
                {LB.map((u, i) => (
                  <div key={i} className={"lbr" + (u.me ? " me" : "")}>
                    <span className="rk">{u.m || u.r}</span>
                    <span className="nm">{u.n}</span>
                    <span className="xp">{u.xp} XP</span>
                  </div>
                ))}
              </div>
            </div>
          </section>

          {/* ═══ PROFILE ═══ */}
          <section className={"scr" + (screen === "profile" ? " on" : "")}>
            <div className="pf">
              <div className="tier">
                <span className="orn">۞</span>
                <div className="ring">
                  <svg width="66" height="66" viewBox="0 0 66 66">
                    <circle cx="33" cy="33" r="28" fill="none" stroke="rgba(245,240,232,.18)" strokeWidth="5" />
                    <circle cx="33" cy="33" r="28" fill="none" stroke="#E9C25B" strokeWidth="5"
                      strokeLinecap="round" strokeDasharray="176" strokeDashoffset="50" />
                  </svg>
                  <span className="lv">৪</span>
                </div>
                <div>
                  <div className="eb">লেভেল ৪</div>
                  <h3>তালিবুল ইলম</h3>
                  <p>পরবর্তী স্তর <b>হাফিজুল মুফরাদাত</b> — আর ১৫০ XP</p>
                </div>
              </div>

              <div className="acts">
                <button className="act" onClick={() => setShareOpen(true)}><span className="i">📤</span>শেয়ার</button>
                <button className="act" onClick={() => setScreen("leaderboard")}><span className="i">🏆</span>র‍্যাংকিং</button>
                <button className="act" onClick={() => setScreen("settings")}><span className="i">⚙️</span>সেটিংস</button>
              </div>

              <div className="wkc">
                <h4><span className="fl">🔥</span> ১২ দিনের ধারা · লক্ষ্য ৩০ দিন</h4>
                <div className="days">
                  {[["শনি", "dn"], ["রবি", "dn"], ["সোম", "dn"], ["মঙ্গল", "fz"], ["বুধ", "dn"], ["বৃহ", "dn"], ["শুক্র", "td"]].map(([d, s], i) => (
                    <div className="day" key={i}>
                      <div className={"dot " + s}>{s === "dn" ? "✓" : s === "fz" ? "❄" : s === "td" ? "✦" : ""}</div>{d}
                    </div>
                  ))}
                </div>
              </div>

              <div className="bdgs">
                <span className="bdg">🏆 ২১ দিনের ধারা</span>
                <span className="bdg">✨ ১০ পারফেক্ট রান</span>
                <span className="bdg">📖 ১০০ শব্দ ক্লাব</span>
              </div>

              <div className="sg">
                <div className="st"><div className="n">১২৮</div><div className="l">শব্দ আয়ত্ত</div></div>
                <div className="st"><div className="n">২১ <small>দিন</small></div><div className="l">দীর্ঘতম ধারা</div></div>
                <div className="st"><div className="n">৪৫০</div><div className="l">এই সপ্তাহের XP</div></div>
                <div className="st"><div className="n">৯৪<small>%</small></div><div className="l">সঠিকতার হার</div></div>
              </div>

              <div className="rowc" onClick={() => setScreen("quran")}>🔖 বুকমার্ক · {bn(bms.length)}টি আয়াত<span className="c">›</span></div>
            </div>

            {shareOpen && (
              <div className="shov" onClick={() => setShareOpen(false)}>
                <div className="shc" onClick={(e) => e.stopPropagation()}>
                  <span className="orn">۞</span>
                  <div className="g">تَعَلَّمْ</div>
                  <h3>আবরার</h3>
                  <div className="t">তালিবুল ইলম · লেভেল ৪</div>
                  <div className="row"><span>🔥 ১২ দিন</span><span>✦ ১২৮ শব্দ</span><span>৯৪% সঠিক</span></div>
                  <div className="ft">Ta'allam-এ কুরআনের আরবি শিখছি — আলহামদুলিল্লাহ</div>
                  <div className="shbtns">
                    <button className="shb p" onClick={() => { setShareOpen(false); ping("শেয়ার কার্ড কপি হয়েছে ✓"); }}>শেয়ার করুন</button>
                    <button className="shb s" onClick={() => setShareOpen(false)}>বন্ধ</button>
                  </div>
                </div>
              </div>
            )}
          </section>

          {/* ═══ SETTINGS ═══ */}
          <section className={"scr" + (screen === "settings" ? " on" : "")}>
            <div className="set">
              <div className="tdt">
                <button className="back" style={{ background: "#E9E2D2", color: "var(--ink)" }} onClick={() => setScreen("profile")}>‹</button>
                <h2 style={{ fontSize: 17, color: "var(--ink)", fontWeight: 700 }}>সেটিংস</h2>
              </div>

              <div className="sh2">সাউন্ড</div>
              <div className="srow"><span className="ic">🔔</span>
                <div className="tx"><h5>সঠিক উত্তরের চাইম</h5><small>প্রতিটি সঠিক উত্তরে মৃদু শব্দ</small></div>
                <button className={"sw" + (sChime ? " on" : "")} onClick={() => setSChime(!sChime)}><i /></button>
              </div>
              <div className="srow"><span className="ic">🕌</span>
                <div className="tx"><h5>পাঠ শেষে তাকবীর</h5><small>লেসন সম্পন্ন হলে "আল্লাহু আকবার"</small></div>
                <button className={"sw" + (sTakbeer ? " on" : "")} onClick={() => setSTakbeer(!sTakbeer)}><i /></button>
              </div>

              <div className="sh2">রিমাইন্ডার</div>
              <div className="srow"><span className="ic">🕰</span>
                <div className="tx"><h5>সালাহ-সচেতন নোটিফিকেশন</h5><small>মাগরিবের ৩০ মিনিট পরে মনে করিয়ে দেবে</small></div>
                <button className={"sw" + (sNotif ? " on" : "")} onClick={() => setSNotif(!sNotif)}><i /></button>
              </div>

              <div className="sh2">ধারা সুরক্ষা</div>
              <div className="frz"><span className="ic">❄️</span>
                <div><h5>স্ট্রিক ফ্রিজ · {bn(freezes)}টি আছে</h5><small>একদিন মিস হলেও ধারা অটুট থাকবে</small></div>
                <button className="frzb" disabled={freezes === 0}
                  onClick={() => { setFreezes(freezes - 1); ping("❄ ফ্রিজ সক্রিয় — আজকের ধারা সুরক্ষিত"); }}>
                  ব্যবহার করুন
                </button>
              </div>

              <div className="sh2">সাপোর্টার</div>
              <div className="sup">
                <span className="orn">۞</span>
                <h4>তা'আল্লাম সাপোর্টার হোন</h4>
                <p>বই ২+ এর সম্পূর্ণ কন্টেন্ট আনলক · প্রোফাইলে সাপোর্টার ব্যাজ · প্রকল্পটি সদকায়ে জারিয়া হিসেবে এগিয়ে নিন</p>
                <div className="pr">৩৯৯৳ <small>এককালীন — কোনো সাবস্ক্রিপশন নেই</small></div>
                <div className="payb">
                  <button className="pay bk" onClick={() => ping("ডেমো — bKash গেটওয়ে বেটায় যুক্ত হবে")}>bKash</button>
                  <button className="pay ng" onClick={() => ping("ডেমো — নগদ গেটওয়ে বেটায় যুক্ত হবে")}>নগদ</button>
                </div>
              </div>

              <div className="sh2">অন্যান্য</div>
              <div className="srow"><span className="ic">⟳</span>
                <div className="tx"><h5>অফলাইন-ফার্স্ট সিঙ্ক</h5><small>শেষ সিঙ্ক: এইমাত্র ✓ · অফলাইনেও সব কাজ করে</small></div>
              </div>
              <div className="srow"><span className="ic">🌐</span>
                <div className="tx"><h5>ভাষা: বাংলা</h5><small>English ইন্টারফেস শীঘ্রই আসছে</small></div>
              </div>
              <div className="ver">Ta'allam β 0.9 · Flutter + Supabase · নিয়্যত বিশুদ্ধ রাখুন</div>
            </div>
          </section>

        </div>

        {/* ═══ NAV ═══ */}
        <div className="nav">
          {[
            { id: "home", l: "হোম", i: "⌂" },
            { id: "quran", l: "কুরআন", i: "﴿﴾", q: true },
            { id: "review", l: "রিভিউ", i: "↻", b: "১৪", fn: () => startSrs("rev") },
            { id: "chat", l: "মুহাদাসা", i: "🗨" },
            { id: "profile", l: "প্রোফাইল", i: "✦" },
          ].map((n) => (
            <button key={n.id} className={navOn(n.id) ? "on" : ""}
              onClick={() => (n.fn ? n.fn() : setScreen(n.id))}>
              {n.b && <span className="nbadge">{n.b}</span>}
              <span className={"ni" + (n.q ? " qi" : "")}>{n.i}</span>{n.l}
            </button>
          ))}
        </div>
      </div></div>

      <div className="jumps">
        {JUMPS.map(([l, fn], i) => <button key={i} className="jump" onClick={fn}>{l}</button>)}
      </div>
      <div className="hint">ইনভেস্টর ট্যুর — উপরের যেকোনো স্ক্রিনে সরাসরি যান · সবকিছু ইন্টারঅ্যাকটিভ</div>
    </div>
  );
}