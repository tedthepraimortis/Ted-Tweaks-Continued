// ------------------------------------------------------------
// H.E.R.P. Robot
// ------------------------------------------------------------

/*
	+DONTFACETALKER disables horizontal scan.
*/

const HERP_CONTROLRANGE=DERP_CONTROLRANGE*1.6;
class HERPLeg:Actor{
	default{
		+flatsprite +nointeraction +noblockmap
	}
	vector3 relpos;
	double oldfloorz;
	override void Tick(){
		if(!master){destroy();return;}
		binvisible=oldfloorz!=floorz;
		setorigin(master.pos+relpos,true);
		oldfloorz=floorz;
	}
	states{
	spawn:
		HLEG A -1;
		stop;
	}
}

class HERPScanDot:Actor{
	default{
		+nointeraction
		+invisible
		+bright
		renderstyle "add";
		radius 0;height 0;
	}
	override void Tick(){
		let mst=master;
		if(
			!mst
			||mst.health<1
		){
			destroy();
			return;
		}
		binvisible=stamina<1;
		if(
			!binvisible
			&&!(level.time&(1|2|4|8|16|32))
		){
			hdmobai.frighten(self,128,mst,HDMobAI.FRIGHT_HOSTILEONLY);
		}
		if(stamina>0)stamina--;
	}
	states{
	spawn:
		BLOD A -1;
		stop;
	}
}

class HERPBot:HDUPK{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "H.E.R.P. Robot"
		//$Sprite "HERPA1"
		+ismonster +noblockmonst +friendly +standstill +nofear
		+shootable +ghost +noblood +dontgib
		+missilemore //on/off
		+nobouncesound
		height 9;radius 7;mass 400;health 200;
		damagefactor "hot",0.7;
		damagefactor "cold",0.7;
		obituary "$OB_HERP";
		hdupk.pickupmessage ""; //just use the spawned one
		hdupk.pickupsound "";
		tag "$TAG_HERP";
		scale 0.8;
	}
	//it is now canon: the mag and seal checkers are built inextricably into the AI.
	//if you tried to use a jailbroken mag, the whole robot just segfaults.
	int ammo[3]; //the mag being used: -1-51, -1 no mag, 0 empty, 51 sealed, >100  dirty
	int battery; //the battery, -1-20
	double startangle;
	double startpitch;
	bool scanright;
	int botid;
	override bool cancollidewith(actor other,bool passive){return other.bmissile||HDPickerUpper(other);}
	override bool ongrab(actor other){
		if(ishostile(other)){
			bmissilemore=false;
			setstatelabel("off");
		}
		return true;
	}
	override void Die(actor source,actor inflictor,int dmgflags){
		super.Die(source,inflictor,dmgflags);
		if(self)bsolid=true;
	}
	override void Tick(){
		if(
			pos.z+vel.z<floorz+12
		){
			vel.z=0;
			setz(floorz+12);
			bnogravity=true;
		}else bnogravity=pos.z-floorz<=12;
		if(bnogravity)vel.xy*=getfriction();
		super.tick();
	}
	override void postbeginplay(){
		super.postbeginplay();
		startangle=angle;
		startpitch=pitch;
		scanright=false;
		if(!master){
			ammo[0]=51;
			ammo[1]=51;
			ammo[2]=51;
			battery=20;
		}
		bool gbg;actor lll;
		[gbg,lll]=A_SpawnItemEx(
			"HERPLeg",xofs:-7,zofs:-12,
			angle:0,
			flags:SXF_NOCHECKPOSITION|SXF_SETMASTER
		);
		HERPLeg(lll).relpos=lll.pos-pos;
		lll.pitch=-60;
		[gbg,lll]=A_SpawnItemEx(
			"HERPLeg",xofs:-7,zofs:-12,
			angle:-120,
			flags:SXF_NOCHECKPOSITION|SXF_SETMASTER
		);
		HERPLeg(lll).relpos=lll.pos-pos;
		lll.pitch=-60;
		[gbg,lll]=A_SpawnItemEx(
			"HERPLeg",xofs:-7,zofs:-12,
			angle:120,
			flags:SXF_NOCHECKPOSITION|SXF_SETMASTER
		);
		HERPLeg(lll).relpos=lll.pos-pos;
		lll.pitch=-60;
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(
			!!source
			&&(
				!inflictor
				||source==inflictor
			)
			&&source.health>0
			&&source.bismonster
			&&source.bcanusewalls
			&&(
				source.instatesequence(source.curstate,source.resolvestate("melee"))
				||source.instatesequence(source.curstate,source.resolvestate("meleekick"))
			)
		){
			target=source;
			setz(target.pos.z+target.height*0.7);
			if(!instatesequence(curstate,resolvestate("give")))setstatelabel("give");
			return -1;
		}
		return super.damagemobj(inflictor,source,damage,mod,flags,angle);
	}
	void herpbeep(string snd="herp/beep",double vol=1.){
		A_StartSound(snd,CHAN_VOICE);
		if(
			master
			&&master.player
			&&master.player.readyweapon is "HERPController"
		)master.A_StartSound(snd,CHAN_WEAPON,volume:0.4);
	}
	void message(string msg){
		if(master)master.A_Log("\cd[HERP"..(botid?"(\cj"..botid.."\cd)":"").."]\cj  "..msg,true);
	}
	actor scandot;
	actor GetScanDot(){
			if(!scandot){
			let scdt=spawn("HERPScanDot",pos);
			scdt.master=self;
			scandot=scdt;
		}
		return scandot;
	}
	void scanturn(){
		if(battery<1){
			message(Stringtable.Localize("$HERP_NOBATTERY"));
			setstatelabel("nopower");
			return;
		}
		if(health<1){
			A_Die();
			setstatelabel("death");
			return;
		}
		if(!bmissilemore){
			setstatelabel("off");
			return;
		}
		if(bmissileevenmore){
			setstatelabel("inputready");
			return;
		}
		if(!random(0,8192))battery--;
		A_ClearTarget();
		//shoot 5 lines for at least some z-axis awareness
		actor a;int b;int c=-2;
		while(
			c<=1
		){
			c++;
			//shoot a line out
			flinetracedata hlt;
			linetrace(
				angle,4096,c+pitch,
				flags:TRF_NOSKY,
				offsetz:9.5,
				data:hlt
			);
			if(
				c==0
				&&hlt.hittype!=Trace_HitNone
				&&hlt.distance>0
			){
					let sc=GetScanDot();
				if(!!sc){
					bool interp=true;
					if(sc.binvisible){
						interp=false;
						sc.binvisible=false;
					}
					sc.SetOrigin(hlt.hitlocation,interp);
					sc.stamina=1;
				}
			}
			//if the line hits a valid target, go into shooting state
			actor hitactor=hlt.hitactor;
			if(
				hitactor
				&&isHostile(hitactor)
				&&hitactor.bshootable
				&&!hitactor.bnotarget
				&&!hitactor.bnevertarget
				&&(hitactor.bismonster||hitactor.player)
				&&(!hitactor.player||!(hitactor.player.cheats&CF_NOTARGET))
				&&hitactor.health>random((hitactor.vel==(0,0,0))?0:-10,5)
				&&hitactor.checksight(self)
			){
				target=hitactor;
				setstatelabel("ready");
				message(Stringtable.Localize("$HERP_ENEMY"));
				if(hd_debug)A_Log(string.format("HERP targeted %s",hitactor.getclassname()));
				return;
			}
		}
		//if nothing, keep moving (add angle depending on scanright)
		if(!bdontfacetalker){
			A_StartSound("herp/crawl",CHAN_BODY,volume:0.2);
			A_SetAngle(angle+(scanright?-3:3),SPF_INTERPOLATE);
		}else if(angle!=startangle){
			A_SetAngle(angle+clamp(deltaangle(angle,startangle),-4,4),SPF_INTERPOLATE);
			A_StartSound("herp/crawl",CHAN_BODY,volume:0.4);
		}
		//if anglechange is too far, start moving the other way
		double chg=deltaangle(angle,startangle);
		if(abs(chg)>35){
			bool changed=scanright;
			if(chg<0)scanright=true;
			else scanright=false;
			if(scanright!=changed)setstatelabel("postbeep");
		}
		//drift back into home pitch
		if(pitch!=startpitch){
			A_SetPitch(pitch+clamp(startpitch-pitch,-2,2),SPF_INTERPOLATE);
		}
	}
	actor A_SpawnPickup(){
		let hu=HERPUsable(spawn("HERPUsable",pos,ALLOW_REPLACE));
		if(hu){
			hu.angle=angle;
			hu.translation=translation;
			if(health<1)hu.weaponstatus[0]|=HERPF_BROKEN;
			hu.weaponstatus[HERP_MAG1]=ammo[0];
			hu.weaponstatus[HERP_MAG2]=ammo[1];
			hu.weaponstatus[HERP_MAG3]=ammo[2];
			hu.weaponstatus[HERP_BATTERY]=battery;
			hu.weaponstatus[HERP_BOTID]=botid;
		}
		destroy();
		return hu;
	}
	states{
	spawn:
		HERP A 0;
	spawn2:
		HERP A 0 A_JumpIfHealthLower(1,"dead");
		HERP A 10 A_ClearTarget();
	idle:
		HERP A 2 scanturn();
		wait;
	postbeep:
		HERP A 6 herpbeep("herp/beep");
		goto idle;
	inputwaiting:
		HERP A 4;
		HERP A 0{
			if(!master){
				setstatelabel("spawn");
				return;
			}
			herpbeep("herp/beep");
			message(Stringtable.Localize("$HERP_ESTABLISHING"));
			A_SetTics(random(10,min(350,int(0.3*distance3d(master)))));
		}
		HERP A 20{
			if(master){
				bmissileevenmore=true;
				herpbeep("herp/beepready");
				message(Stringtable.Localize("$HERP_CONNECTED"));
			}else{
				setstatelabel("inputabort");
				return;
			}
		}
	inputready:
		HERP A 1 A_JumpIf(
			!master
			||!master.player
			||!(master.player.readyweapon is "HERPController")
		,"inputabort");
		wait;
	inputabort:
		HERP A 4{bmissileevenmore=false;}
		HERP A 2 herpbeep("herp/beepready");
		HERP A 20 message(Stringtable.Localize("$HERP_DISCONNECTED"));
		goto spawn;
	ready:
		HERP A 12 A_StartSound("weapons/vulcanup",CHAN_BODY,CHANF_OVERLAP);
		HERP AAA 1 herpbeep("herp/beepready");
	aim:
		HERP A 1 A_StartSound("herp/crawl",CHAN_BODY,volume:0.4);
		HERP A 1 A_FaceTarget(3.,3.,0,0,FAF_TOP,-4);
		HERP A 0 A_JumpIf(
			!!target
			&&absangle(angle,angleto(target))<1.
		,"shoot");
		loop;
	shoot:
		HERP B 2 bright light("SHOT"){
			int currammoraw=ammo[0];
			int currammo=currammoraw%100;
			int currammo1=ammo[1]%100;
			int currammo2=ammo[2]%100;
			if(
				(
					currammo<1
					&&currammo1<0
					&&currammo2<0
				)||(
					currammoraw>100
					&&!random(0,7)
				)
			){
				message(Stringtable.Localize("$HERP_NOMAG"));
				if(currammoraw>100&&!random(0,3))ammo[0]--;
				bmissilemore=random(0,15);
				setstatelabel("off");
				return;
			}
			if(currammo<1&&currammo1>=0){
				setstatelabel("swapmag");
				return;
			}
			//deplete 1 round plus break seal
			if(currammo==51)currammo=49;else{
				currammo=max(currammo-1,0);
				if(currammoraw>100)currammo+=100;
			}
			ammo[0]=currammo;
			A_StartSound("herp/shoot",CHAN_WEAPON,CHANF_OVERLAP);
			HDBulletActor.FireBullet(self,"HDB_426",zofs:6,spread:1,distantsound:"world/herpfar");
		}
		HERP C 2{
			angle-=frandom(0.6,0.8);
			pitch-=frandom(1.2,1.8);
			if(bfriendly)A_AlertMonsters(0,AMF_TARGETEMITTER);
			else A_AlertMonsters();
		}
		HERP A 0{
			if(ammo[0]<1){
				setstatelabel("swapmag");
			}else if(
				target
				&&target.health>random(-10,5)
			){
				flinetracedata herpline;
				linetrace(
					angle,4096,pitch,
					offsetz:12,
					data:herpline
				);
				if(herpline.hitactor!=target){
					if(checksight(target))setstatelabel("aim");
					else target=null;
				}else setstatelabel("shoot");
			}
		}goto idle;
	swapmag:
		HERP A 3{
			int nextmag=ammo[1];
			if(
				nextmag<1
				||nextmag==100
				||(nextmag>100&&!random(0,3))
			){
				message(Stringtable.Localize("$HERP_NOMAG"));
				A_StartSound("weapons/vulcandown",8,CHANF_OVERLAP);
				setstatelabel("off");
			}else{
				int currammo=ammo[0];
				if(currammo>=0){
					let mmm=hd4mmag(spawn("hd4mmag",(pos.xy,pos.z-6)));
					mmm.mags.clear();mmm.mags.push(max(0,currammo));
					double angloff=angle+100;
					mmm.vel=(cos(angloff),sin(angloff),1)*frandom(0.7,1.3)+vel;
				}
				ammo[0]=ammo[1];
				ammo[1]=ammo[2];
				ammo[2]=-1;
			}
		}goto idle;
	nopower:
		HERP A -1;
	off:
		HERP A 10;
		HERP A 0{
			if(
				!bmissilemore
				||(
					ammo[0]%100<1
					&&ammo[1]%100<1
					&&ammo[2]%100<1
				)
			)setstatelabel("off");
		}goto idle;
	give:
		---- A 0{
			let hu=A_SpawnPickup();
			if(hu){
				hu.translation=self.translation;
				grabthinker.grab(target,hu);
			}
			let ctr=HERPController(target.findinventory("HERPController"));
			if(ctr)ctr.UpdateHerps(false);
		}stop;
	death:
		HERP A 0{
			if(ammo[0]>=0)ammo[0]=random(0,ammo[0]+randompick(0,0,0,100));
			if(ammo[1]>=0)ammo[1]=random(0,ammo[1]+randompick(0,0,0,100));
			if(ammo[2]>=0)ammo[2]=random(0,ammo[2]+randompick(0,0,0,100));
			battery=min(battery,random(-1,20));
			if(battery<0){
				A_GiveInventory("Heat",1000);
				ammo[0]=min(ammo[0],0);
				ammo[1]=min(ammo[1],0);
				ammo[2]=min(ammo[2],0);
			}
			A_NoBlocking();
			A_StartSound("world/shotgunfar",CHAN_BODY,CHANF_OVERLAP,0.4);
		}
		HERP A 1 A_StartSound("weapons/bigcrack",15);
		HERP A 1 A_StartSound("weapons/bigcrack",16);
		HERP A 1 A_StartSound("weapons/bigcrack",17);
		HERP AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 A_SpawnItemEx("HugeWallChunk",frandom(-6,6),frandom(-6,6),frandom(0,6), vel.x+frandom(-6,6),vel.y+frandom(-6,6),vel.z+frandom(1,8),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		HERP A 0{
			A_StartSound("weapons/vulcandown",CHAN_WEAPON,CHANF_OVERLAP);
			string yay="";
			switch(random(0,8)){
			case 0:
				yay=Stringtable.Localize("$HERP_NOBATTERY");break;
			case 1:
				yay=Stringtable.Localize("$HERP_BADMAG");break;
			case 2:
				yay=Stringtable.Localize("$HERP_NOINTERFACE");break;
			case 3:
				yay=Stringtable.Localize("$HERP_SYSTEMRESTART");break;
			case 4:
				yay=Stringtable.Localize("$HERP_TAMPEREDSYSTEM");break;
			case 5:
				yay=Stringtable.Localize("$HERP_FORMATC");break;
			case 6:
				yay=Stringtable.Localize("$HERP_DEVMODE");break;
			case 7:
				yay=Stringtable.Localize("$HERP_OBJECTNOTMAPPED");break;
			case 8:
				yay=Stringtable.Localize("$HERP_SEGMENTATIONFAULT");break;
			}
			if(!random(0,3))yay="\cg"..yay;
			message(yay);
		}
		HERP AAA 1 A_SpawnItemEx("HDSmoke",frandom(-2,2),frandom(-2,2),frandom(-2,2), vel.x+frandom(-2,2),vel.y+frandom(-2,2),vel.z+frandom(1,4),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		HERP AAA 3 A_SpawnItemEx("HDSmoke",frandom(-2,2),frandom(-2,2),frandom(-2,2), vel.x+frandom(-2,2),vel.y+frandom(-2,2),vel.z+frandom(1,4),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		HERP AAA 9 A_SpawnItemEx("HDSmoke",frandom(-2,2),frandom(-2,2),frandom(-2,2), vel.x+frandom(-2,2),vel.y+frandom(-2,2),vel.z+frandom(1,4),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
	dead:
		HERP A -1 A_SpawnPickup();
		stop;
	}
}
class EnemyHERP:HERPBot{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "H.E.R.P. Robot (Hostile)"
		//$Sprite "HERPA1"
		-friendly
		translation "112:120=152:159","121:127=9:12";
	}
}
class BrokenHERP:HERPBot{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "H.E.R.P. Robot (Broken)"
		//$Sprite "HERPA1"
		translation "112:120=152:159","121:127=9:12";
	}
	override void postbeginplay(){
		super.postbeginplay();
		A_Die("spawndead");
	}
	states{
	spawn:
		HERP A -1;
		stop;
	death.spawndead:
		HERP A -1{
			ammo[0]=random(0,ammo[0]+randompick(0,0,0,100));
			ammo[1]=random(0,ammo[1]+randompick(0,0,0,100));
			ammo[2]=random(0,ammo[2]+randompick(0,0,0,100));
			battery=min(battery,random(-1,20));
			if(battery<0){
				ammo[0]=0;ammo[1]=0;ammo[2]=0;
			}
			A_NoBlocking();
			A_SpawnPickup();
		}stop;
	}
}
class HERPUsable:HDWeapon{
	default{
		//$Category "Items/Hideous Destructor"
		//$Title "H.E.R.P. Robot (Pickup)"
		//$Sprite "HERPA1"
		+weapon.wimpy_weapon
		+weapon.no_auto_switch
		+inventory.invbar
		+hdweapon.droptranslation
		+hdweapon.fitsinbackpack
		inventory.amount 1;
		inventory.maxamount 1;
		inventory.icon "HERPEX";
		inventory.pickupsound "misc/w_pkup";
		inventory.pickupmessage "$PICKUP_DERP";
		tag "$TAG_HERP";
		hdweapon.refid HDLD_HERPBOT;
		weapon.selectionorder 1015;
		hdweapon.ammo1 "HD4mMag",1;
		hdweapon.ammo2 "HDBattery",1;
	}
	override string pickupmessage(){
		string msg=Super.Pickupmessage();
		if(weaponstatus[0]&HERPF_BROKEN)return msg..Stringtable.Localize("$PICKUP_HERP_BROKEN");
		return msg;
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override double gunmass(){
		double amt=9+weaponstatus[HERP_BATTERY]<0?0:1;
		if(weaponstatus[1]>=0)amt+=3.6;
		if(weaponstatus[2]>=0)amt+=3.6;
		if(weaponstatus[3]>=0)amt+=3.6;
		if(owner&&owner.player.cmd.buttons&BT_ZOOM)amt*=frandom(3,4);
		return amt;
	}
	override double weaponbulk(){
		double enc=ENC_HERP;
		for(int i=1;i<4;i++){
			if(weaponstatus[i]>=0)enc+=max(ENC_426MAG*0.2,weaponstatus[i]*ENC_426*0.8);
		}
		if(
			owner
			&&owner.player.cmd.buttons&BT_ZOOM
			&&owner.player.readyweapon==self
		)enc*=2;
		return enc;
	}
	override int getsbarnum(int flags){
		let ssbb=HDStatusBar(statusbar);
		if(ssbb&&weaponstatus[0]&HERPF_BROKEN)ssbb.savedcolour=Font.CR_DARKGRAY;
		return weaponstatus[HERP_BOTID];
	}
	override void InitializeWepStats(bool idfa){
		weaponstatus[HERP_BATTERY]=20;
		weaponstatus[1]=51;
		weaponstatus[2]=51;
		weaponstatus[3]=51;
	}
	action void A_ResetBarrelSize(){
		invoker.weaponstatus[HERP_YOFS]=100;
		invoker.barrellength=0;
		invoker.barrelwidth=0;
		invoker.barreldepth=0;
		invoker.bobspeed=2.4;
		invoker.bobrangex=0.2;
		invoker.bobrangey=0.8;
	}
	action void A_RaiseBarrelSize(){
		invoker.barrellength=25;
		invoker.barrelwidth=3;
		invoker.barreldepth=3;
		invoker.bobrangex=4;
		invoker.bobrangey=4;
	}
	states{
	select:
		TNT1 A 0 A_ResetBarrelSize();
		goto super::select;
	ready:
		TNT1 A 0 A_JumpIf(pressingzoom(),"raisetofire");
		TNT1 A 1 A_HERPWeaponReady();
		goto readyend;
	user3:
		TNT1 A 0 A_MagManager("HD4mMag");
		TNT1 A 1 A_WeaponReady(WRF_NOFIRE);
		goto nope;
	unload:
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[1]<0
			&&invoker.weaponstatus[2]<0
			&&invoker.weaponstatus[3]<0,"altunload");
		TNT1 A 0{invoker.weaponstatus[0]|=HERPF_UNLOADONLY;}
		//fallthrough to unloadmag
	unloadmag:
		TNT1 A 14;
		TNT1 A 5 A_UnloadMag();
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&HERPF_UNLOADONLY,"reloadend");
		goto reloadend;
	reload:
		TNT1 A 0 A_JumpIf(HD4mMag.NothingLoaded(self,"HD4mMag"),"nope");
		TNT1 A 14 A_StartSound("weapons/pocket",9);
		TNT1 A 5 A_LoadMag();
		goto reloadend;
	altreload:
		TNT1 A 0 A_JumpIf(pressinguse()||pressingzoom(),"altunload");
		TNT1 A 0{
			if(HDBattery.NothingLoaded(self,"HDBattery"))setweaponstate("nope");
			else invoker.weaponstatus[0]&=~HERPF_UNLOADONLY;
		}goto unloadbattery;
	altunload:
		TNT1 A 0{invoker.weaponstatus[0]|=HERPF_UNLOADONLY;}
		//fallthrough to unloadbattery
	unloadbattery:
		TNT1 A 20;
		TNT1 A 5 A_UnloadBattery();
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&HERPF_UNLOADONLY,"reloadend");
	reloadbattery:
		TNT1 A 14 A_StartSound("weapons/pocket",9);
		TNT1 A 5 A_LoadBattery();
	reloadend:
		TNT1 A 6;
		goto ready;
	spawn:
		HERP A -1;
		stop;
	//for manual carry-firing
	raisetofire:
		TNT1 A 8 A_StartSound("herp/crawl",8,CHANF_OVERLAP,1.);
		HERG A 1 offset(0,80) A_StartSound("herp/beepready",8,CHANF_OVERLAP);
		HERG A 1 offset(0,60);
		HERG A 1 offset(0,50) A_RaiseBarrelSize();
		HERG A 1 offset(0,40);
		HERG A 1 offset(0,34);
	readytofire:
		HERG A 1{
			if(pressingzoom()){
				if(pressingfire())setweaponstate("directfire");
				if(pitch<10&&!gunbraced())A_MuzzleClimb(frandom(-0.1,0.1),frandom(0.,0.1));
			}else{
				setweaponstate("lowerfromfire");
			}
		}
		HERG A 0 A_ReadyEnd();
		loop;
	directfire:
		HERG A 2{
			if(invoker.weaponstatus[HERP_BATTERY]<1){
				setweaponstate("directfail");
				return;
			}
			if(
				invoker.weaponstatus[0]&HERPF_BROKEN
				&&random(0,7)
			){
				A_SetTics(random(1,10));
				return;
			}
			int currammo=invoker.weaponstatus[1];
			bool dirtymag=currammo>100;
			currammo%=100;
			//check ammo and cycle mag if necessary
			if(
				!currammo
				||(
					dirtymag
					&&!random(0,63)
				)
			){
				let mmm=hd4mmag(spawn("hd4mmag",(pos.xy,pos.z+height-20)));
				mmm.mags.clear();mmm.mags.push(max(0,currammo%100));
				double angloff=angle+100;
				mmm.vel=(cos(angloff),sin(angloff),1)*frandom(0.7,1.3)+vel;
				invoker.weaponstatus[1]=-1;
			}
			if(
				invoker.weaponstatus[1]<0
			){
				invoker.weaponstatus[1]=invoker.weaponstatus[2];
				invoker.weaponstatus[2]=invoker.weaponstatus[3];
				invoker.weaponstatus[3]=-1;
				int curmag=invoker.weaponstatus[1];
				if(
					curmag>0
					&&curmag<51
				)invoker.weaponstatus[1]+=100;
				return;
			}
			//deplete ammo and fire
			if(currammo==51)currammo=49;else{
				currammo=max(0,currammo-1);
				if(dirtymag)currammo+=100;
			}
			invoker.weaponstatus[1]=currammo;
			A_Overlay(PSP_FLASH,"directflash");
		}
		HERG B 2;
		HERG A 0 A_JumpIf(!pressingzoom(),"lowerfromfire");
		HERG A 0 A_Refire("directfire");
		goto readytofire;
	directflash:
		HERF A 1 bright{
			HDFlashAlpha(-16);
			HDBulletActor.FireBullet(
				self,"HDB_426",zofs:height-12,
				spread:1,
				distantsound:"world/herpfar"
			);
			A_StartSound("herp/shoot",CHAN_WEAPON,CHANF_OVERLAP);
			A_AlertMonsters();
			A_ZoomRecoil(max(0.95,1.-0.05*min(invoker.weaponstatus[ZM66S_AUTO],3)));
			A_MuzzleClimb(
				frandom(-0.2,0.2),frandom(-0.4,0.2),
				frandom(-0.4,0.4),frandom(-0.6,0.4),
				frandom(-0.4,0.4),frandom(-1.,0.6),
				frandom(-0.8,0.8),frandom(-1.6,0.8)
			);
		}stop;
	directfail:
		HERG # 1 A_WeaponReady(WRF_NONE);
		HERG # 0 A_JumpIf(pressingfire(),"directfail");
		goto readytofire;
	lowerfromfire:
		HERG A 1 offset(0,34) A_ClearRefire();
		HERG A 1 offset(0,40) A_StartSound("herp/beepready",8);
		HERG A 1 offset(0,50);
		HERG A 1 offset(0,60);
		HERG A 1 offset(0,80)A_ResetBarrelSize();
		TNT1 A 1 A_StartSound("herp/crawl",8);
		TNT1 A 1 A_JumpIf(pressingfire()||pressingaltfire(),"nope");
		goto select;
	readytorepair:
		TNT1 A 1{
			if(!pressingfire())setweaponstate("nope");
			else if(PressingReload()){
				if(invoker.weaponstatus[HERP_BATTERY]>=0){
					message(Stringtable.Localize("$HERP_DAMAGEDBEYONDFUNCTION"));
				}else setweaponstate("repairbash");
			}
		}
		wait;
	repairbash:
		TNT1 A 10 A_RepairAttempt();
		TNT1 A 0 A_JumpIf(!(invoker.weaponstatus[0]&HERPF_BROKEN),"nope");
		goto readytorepair;
	}
	action void Message(string msg){
		int botid=invoker.weaponstatus[HERP_BOTID];
		A_Log("\cd[HERP"..(botid?"(\cj"..botid.."\cd)":"").."]\cj  "..msg,true);
	}
	action void A_LoadMag(){
		let magg=HD4mMag(findinventory("HD4mMag"));
		if(!magg)return;
		for(int i=1;i<4;i++){
			if(invoker.weaponstatus[i]<0){
				int toload=magg.takemag(true);
				if(toload!=51)toload+=100;
				invoker.weaponstatus[i]=toload;
				break;
			}
		}
	}
	action void A_UnloadMag(){
		bool unsafe=(player.cmd.buttons&BT_USE)||(player.cmd.buttons&BT_ZOOM);
		for(int i=3;i>0;i--){
			int thismag=invoker.weaponstatus[i];
			if(thismag<0)continue;
			if(unsafe||!thismag||thismag>50){
				invoker.weaponstatus[i]=-1;
				if(thismag>100)thismag%=100;
				if(thismag>51)thismag%=50;
				if(pressingunload()||pressingreload()){
					HD4mMag.GiveMag(self,"HD4mMag",thismag);
					A_StartSound("weapons/pocket",9);
					A_SetTics(20);
				}else HD4mMag.SpawnMag(self,"HD4mMag",thismag);
				break;
			}
		}
	}
	action void A_LoadBattery(){
		if(invoker.weaponstatus[4]>=0)return;
		let batt=HDBattery(findinventory("HDBattery"));
		if(!batt)return;
		int toload=batt.takemag(true);
		invoker.weaponstatus[4]=toload;
		A_StartSound("weapons/vulcopen1",8,CHANF_OVERLAP);
	}
	action void A_UnloadBattery(){
		int batt=invoker.weaponstatus[4];
		if(batt<0)return;
		if(pressingunload()||pressingreload()){
			HDBattery.GiveMag(self,"HDBattery",batt);
			A_StartSound("weapons/pocket",9);
			A_SetTics(20);
		}else HDBattery.SpawnMag(self,"HDBattery",batt);
		invoker.weaponstatus[4]=-1;
	}
	action void A_HERPWeaponReady(){
		if(invoker.amount<1){
			invoker.goawayanddie();
			return;
		}
		if(pressingfire()){
			int yofs=invoker.weaponstatus[HERP_YOFS];
			yofs=max(yofs+12,yofs*3/2);
			if(yofs>100)A_DeployHERP();
			invoker.weaponstatus[HERP_YOFS]=yofs;
		}else invoker.weaponstatus[HERP_YOFS]=invoker.weaponstatus[HERP_YOFS]*2/3;
		if(pressingfiremode()){
			int inputamt=(GetMouseY(true)>>4);
			inputamt+=(justpressed(BT_ATTACK)?1:justpressed(BT_ALTATTACK)?-1:0);
			invoker.weaponstatus[HERP_BOTID]=clamp(
				invoker.weaponstatus[HERP_BOTID]-inputamt,0,63
			);
		}else if(justpressed(BT_ALTATTACK)){
			if(pressinguse())invoker.weaponstatus[0]^=HERPF_STATIC;
			else invoker.weaponstatus[0]^=HERPF_STARTOFF;
			A_StartSound("weapons/fmswitch",8,CHANF_OVERLAP);
		}else A_WeaponReady(WRF_NOFIRE|WRF_ALLOWRELOAD|WRF_ALLOWUSER1|WRF_ALLOWUSER3|WRF_ALLOWUSER4);
	}
	action void A_DeployHERP(){
		if(invoker.weaponstatus[0]&HERPF_BROKEN){
			setweaponstate("readytorepair");
			return;
		}
		if(invoker.weaponstatus[4]<1){
			message(Stringtable.Localize("$HERP_NOPOWER"));
			setweaponstate("nope");
			return;
		}
		actor hhh;int iii;
		[iii,hhh]=A_SpawnItemEx("HERPBot",5,0,height-16,
			2.5*cos(pitch),0,-2.5*sin(pitch),
			0,SXF_NOCHECKPOSITION|SXF_TRANSFERTRANSLATION
			|SXF_TRANSFERPOINTERS|SXF_SETMASTER
		);
		hhh.A_StartSound("misc/w_pkup",5);
		hhh.vel+=vel;hhh.angle=angle;
		let hhhh=HERPBot(hhh);
		hhhh.startangle=angle;
		hhhh.ammo[0]=invoker.weaponstatus[1];
		hhhh.ammo[1]=invoker.weaponstatus[2];
		hhhh.ammo[2]=invoker.weaponstatus[3];
		hhhh.battery=invoker.weaponstatus[4];
		hhhh.botid=invoker.weaponstatus[HERP_BOTID];
		hhhh.bmissilemore=(!invoker.weaponstatus[0]&HERPF_STARTOFF);
		hhhh.bdontfacetalker=invoker.weaponstatus[0]&HERPF_STATIC;
		Message("Deployed.");
		A_GiveInventory("HERPController");
		HERPController(findinventory("HERPController")).UpdateHerps(false);
		dropinventory(invoker);
		invoker.GoAwayAndDie();
		return;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		int batt=hdw.weaponstatus[4];
		//bottom status bar
		for(int i=2;i<4;i++){
			if(hdw.weaponstatus[i]>=0)sb.drawrect(-11-i*4,-15,3,2);
		}
		sb.drawwepnum(hdw.weaponstatus[1]%100,50,posy:-10);
		bool herpon=!(hdw.weaponstatus[0]&HERPF_STARTOFF);
		sb.drawstring(
			sb.pnewsmallfont,herpon?((hdw.weaponstatus[0]&HERPF_STATIC)?"STATIC":"ON"):"OFF",(-30,-30),
			sb.DI_TEXT_ALIGN_RIGHT|sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
			herpon?Font.CR_GREEN:Font.CR_DARKRED
		);
		if(!batt)sb.drawstring(
			sb.mamountfont,"00000",(-16,-8),
			sb.DI_TEXT_ALIGN_RIGHT|sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
			Font.CR_DARKGRAY
		);else if(batt>0)sb.drawwepnum(batt,20);
		if(barrellength>0)return;
		int yofs=weaponstatus[HERP_YOFS];
		if(yofs<70){
			vector2 bob=hpl.wepbob*0.2;
			bob.y+=yofs;
			sb.drawimage("HERPA7A3",(10,14)+bob,
				sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER|sb.DI_TRANSLATABLE,
				scale:(2,2)
			);
			for(int i=1;i<4;i++){
				int bbb=hdw.weaponstatus[i];
				if(bbb==51)sb.drawimage("ZMAGA0",(-20,i*10)+bob,
					sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					scale:(2,2)
				);else if(bbb>=0)sb.drawbar(
					(bbb>=100?"ZMAGBROWN":"ZMAGNORM"),"ZMAGGREY",
					bbb%100,50,
					(-20,i*10)+bob,-1,
					sb.SHADER_VERT,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
				);
			}
			if(batt>=0){
				string batsprite;
				if(batt>13)batsprite="CELLA0";
				else if(batt>6)batsprite="CELLB0";
				else batsprite="CELLC0";
				sb.drawimage(batsprite,(0,30)+bob,
					sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
				);
			}
		}
	}
	override string gethelptext(){
		return
		((weaponstatus[0]&HERPF_BROKEN)?
		(LWPHELP_FIRE.."+"..LWPHELP_RELOAD.." (hold)  Repair\n"):(LWPHELP_FIRE.."  Deploy\n"))
		..LWPHELP_ALTFIRE.."  Cycle modes\n"
		..LWPHELP_FIREMODE.."+"..LWPHELP_UPDOWN.."  Set BotID\n"
		..LWPHELP_RELOAD.."  Reload mag\n"
		..LWPHELP_ALTRELOAD.."  Reload battery\n"
		..LWPHELP_UNLOAD.."  Unload mag\n"
		..LWPHELP_USE.."+"..LWPHELP_ALTRELOAD.."  Unload battery\n"
		..LWPHELP_USE.."+"..LWPHELP_UNLOAD.."  Unload partial mag\n"
		..LWPHELP_ZOOM.."  Manual firing"
		;
	}
	static int backpackrepairs(actor owner,hdbackpack bp){
		if(!owner||!bp)return 0;
		StorageItem si=bp.Storage.Find('herpusable');
		int fixbonus=0;
		if (si){
			for(int i=0;si.Amounts.Size()>0&&i<si.Amounts[0];){
				if (si.WeaponStatus[HDWEP_STATUSSLOTS*i]&HERPF_BROKEN){
					if (!random(0,7-fixbonus)){
						//fix
						si.WeaponStatus[HDWEP_STATUSSLOTS*i]&=~HERPF_BROKEN;
						if (fixbonus>0)fixbonus--;
						owner.A_Log(Stringtable.Localize("$HERP_REPAIRPACK"),true);
					}else if(!random(0,7)){
						fixbonus++;
						//delete and restart
						bp.Storage.RemoveItem(si,null,null,index:i);
						i=0;
						owner.A_Log(Stringtable.Localize("$HERP_REPAIRPACK_FAIL"),true);
						continue;
					}
				}
				i++;
			}
		}
		return fixbonus;
	}
	action void A_RepairAttempt(){
		if(!invoker.RepairAttempt())return;
		if(!(invoker.weaponstatus[0]&HERPF_BROKEN))A_SetHelpText();
		A_MuzzleClimb(
			frandom(-1.,1.),frandom(-1.,1.),
			frandom(-1.,1.),frandom(-1.,1.),
			frandom(-1.,1.),frandom(-1.,1.),
			frandom(-1.,1.),frandom(0.,1.)
		);
	}
	bool RepairAttempt(){
		if(!owner)return false;
		int failchance=40;
		int spareindex=-1;
		//find spares, whether to cannibalize or copy
		let spw=spareweapons(owner.findinventory("spareweapons"));
		if(spw){
			for(int i=0;i<spw.weapontype.size();i++){
				if(
					spw.weapontype[i]==getclassname()
					&&spw.GetWeaponValue(i,0)&HERPF_BROKEN
				){
					if(spareindex==-1)spareindex=i;
					failchance=min(10,failchance-5);
					break;
				}
			}
		}
		if(!random(0,failchance)){
			weaponstatus[0]&=~HERPF_BROKEN;
			owner.A_StartSound("herp/repair",CHAN_WEAPON);
			owner.A_Log(Stringtable.Localize("$HERP_REPAIRED"),true);
			//destroy one spare
			if(
				spareindex>=0
				&&!random(0,3)
			){
				spw.weaponbulk.delete(spareindex);
				spw.weapontype.delete(spareindex);
				spw.weaponstatus.delete(spareindex);
				owner.A_Log(Stringtable.Localize("$HERP_CANNIBALIZED"),true);
			}
		}else owner.A_StartSound("herp/repairtry",CHAN_WEAPONBODY,CHANF_OVERLAP,
			volume:frandom(0.6,1.),pitch:frandom(0.7,1.4)
		);
		return true;
	}
	override void consolidate(){
		if(!owner)return;
		int fixbonus=backpackrepairs(owner,hdbackpack(owner.FindInventory("HDBackpack",true)));
		let spw=spareweapons(owner.findinventory("spareweapons"));
		if(spw){
			for(int i=0;i<spw.weapontype.size();i++){
				if(spw.weapontype[i]!=getclassname())continue;
				array<string>wpst;wpst.clear();
				spw.weaponstatus[i].split(wpst,",");
				int wpstint=wpst[0].toint();
				if(
					wpstint&HERPF_BROKEN
				){
					if(!random(0,max(0,7-fixbonus))){
						if(fixbonus>0)fixbonus--;
						wpstint&=~HERPF_BROKEN;
						owner.A_Log(Stringtable.Localize("$HERP_REPAIRBROKEN"),true);
						string newwepstat=spw.weaponstatus[i];
						newwepstat=wpstint..newwepstat.mid(newwepstat.indexof(","));
						spw.weaponstatus[i]=newwepstat;
					}else if(!random(0,7)){
						//delete
						fixbonus++;
						spw.weaponbulk.delete(i);
						spw.weapontype.delete(i);
						spw.weaponstatus.delete(i);
						owner.A_Log(Stringtable.Localize("$HERP_REPAIRBROKEN_FAIL"),true);
						//go back to start
						i=0;
						continue;
					}
				}
			}
		}
		if(
			(weaponstatus[0]&HERPF_BROKEN)
			&&!random(0,7-fixbonus)
		){
			weaponstatus[0]&=~HERPF_BROKEN;
			owner.A_Log(Stringtable.Localize("$HERP_FIELDREPAIRS"),true);
		}
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			if(owner.countinv("FourMilAmmo"))owner.A_DropInventory("FourMilAmmo",50);
			else{
				owner.angle-=10;
				owner.A_DropInventory("HD4mMag",1);
				owner.angle+=20;
				owner.A_DropInventory("HDBattery",1);
				owner.angle-=10;
			}
		}
	}
	override void ForceBasicAmmo(){
		owner.A_TakeInventory("FourMilAmmo");
		owner.A_TakeInventory("HD4mMag");
		owner.A_GiveInventory("HD4mMag",3);
		owner.A_TakeInventory("HDBattery");
		owner.A_GiveInventory("HDBattery");
	}
}
enum HERPNum{
	HERP_MAG1=1,
	HERP_MAG2=2,
	HERP_MAG3=3,
	HERP_BATTERY=4,
	HERP_BOTID=5,
	HERP_YOFS=6,
	HERPF_STARTOFF=1,
	HERPF_UNLOADONLY=2,
	HERPF_BROKEN=4,
	HERPF_STATIC=8,
}
extend class HDHandlers{
	void HackHERP(hdplayerpawn ppp,int cmd,int tag,int cmd2){
		let hpu=HERPController(ppp.findinventory("HERPController"));
		if(
			hpu
			&&ppp.player
			&&ppp.player.readyweapon==hpu
			&&hpu.herps.size()>0
			//check these here since the command can be called in the console at any time
			&&hpu.weaponstatus[HERPS_INDEX]>=0
			&&hpu.weaponstatus[HERPS_INDEX]<hpu.herps.size()
			&&hpu.herps[hpu.weaponstatus[HERPS_INDEX]]
			&&hpu.herps[hpu.weaponstatus[HERPS_INDEX]].battery>0
			&&!hpu.herps[hpu.weaponstatus[HERPS_INDEX]].bmissilemore
		)hpu.setownerweaponstate("hack");
		else ppp.A_Log(Stringtable.Localize("$HERP_NOCONTROLLER"),true);
	}
	void SetHERP(hdplayerpawn ppp,int botcmd,int botcmdid,int achange){
		let herpinv=HERPUsable(ppp.findinventory("HERPUsable"));
		int botid=herpinv?herpinv.weaponstatus[HERP_BOTID]:1;
		//set HERP tag number with -#
		if(botcmd<0){
			if(!herpinv)return;
			herpinv.weaponstatus[HERP_BOTID]=-botcmd;
			ppp.A_Log(string.format(Stringtable.Localize("$HERP_NEXTTAG"),-botcmd),true);
			return;
		}
		//give actual commands
		bool anybots=false;
		int affected=0;
		bool badcommand=true;
		ThinkerIterator it=ThinkerIterator.Create("HERPBot");
		actor bot=null;
		while(bot=HERPBot(it.Next())){
			anybots=true;
			let herp=HERPBot(bot);
			if(
				herp
				&&herp.master==ppp
				&&herp.health>0
				&&(
					!botcmdid||
					botcmdid==herp.botid
				)
			){
				if(botcmd==1){
					badcommand=false;
					if(
						herp.battery<1
						||(
							herp.ammo[0]<1
							&&herp.ammo[1]<1
							&&herp.ammo[2]<1
						)
					){
						ppp.A_Log(string.format(Stringtable.Localize("$HERP_EMPTY"),herp.pos.x,herp.pos.y),true);
					}else{
						affected++;
						herp.bmissilemore=true;
					}
				}
				else if(botcmd==2){
					affected++;
					badcommand=false;
					herp.bmissilemore=false;
				}
				else if(botcmd==3){
					if(!achange){
						ppp.A_Log(string.format(Stringtable.Localize("$HERP_NOANGLECHANGE")),true);
					}else{
						badcommand=false;
						affected++;
						int anet=int((herp.startangle+achange))%360;
						if(anet<0)anet+=360;
						herp.startangle=anet;
						herp.setstatelabel("off");
						ppp.A_Log(string.format(Stringtable.Localize("$HERP_NOWFACING"),herp.pos.x,herp.pos.y,hdmath.cardinaldirection(anet)),true);
					}
				}
				else if(botcmd==4){
					affected++;
					badcommand=false;
					herp.bdontfacetalker=!herp.bdontfacetalker;
				}
				else if(botcmd==123){
					badcommand=false;
					ppp.A_Log(string.format(Stringtable.Localize("$HERP_FACING"),
						herp.pos.x,herp.pos.y,
						hdmath.cardinaldirection(herp.startangle),
						herp.botid,
						herp.bmissilemore?Stringtable.Localize("$HERP_ACTIVE"):Stringtable.Localize("$HERP_INACTIVE")
					),true);
				}
				else{
					badcommand=true;
					break;
				}
			}
		}
		if(
			!badcommand
			&&botcmd!=123
		){
			string verb=Stringtable.Localize("$HERP_VHACKED");
			if(botcmd==HERPC_ON)verb=Stringtable.Localize("$HERP_VON");
			else if(botcmd==HERPC_OFF)verb=Stringtable.Localize("$HERP_VOFF");
			else if(botcmd==HERPC_DIRECTED)verb=Stringtable.Localize("$HERP_VDIRECTED");
			else if(botcmd==HERPC_SCANTOG)verb=Stringtable.Localize("$HERP_VSCANTOG");
			ppp.A_Log(string.format(
				Stringtable.Localize("$HERP_TAG1"),affected,affected==1?"":"s",
				botcmdid?string.format(Stringtable.Localize("$HERP_TAG2"),botcmdid):"",
				verb
			),true);
		}else if(badcommand)ppp.A_Log(string.format(Stringtable.Localize("$HERP_BADCOMMAND1"),anybots?"":Stringtable.Localize("$HERP_BADCOMMAND2"),botid),true);
	}
}
class HERPController:HDWeapon{
	default{
		+inventory.invbar
		+weapon.wimpy_weapon
		+nointeraction
		+hdweapon.droptranslation
		inventory.icon "HERPA5";
		weapon.selectionorder 1013;
		tag "H.E.R.P. interface";
	}
	array<herpbot> herps;
	herpbot UpdateHerps(bool resetindex=true){
		herps.clear();
		if(!owner)return null;
		ThinkerIterator herpfinder=thinkerIterator.Create("HERPBot");
		herpbot mo;
		while(mo=HERPBot(herpfinder.Next())){
			if(
				mo.master==owner
				&&mo.battery>0
			)herps.push(mo);
		}
		if(resetindex)weaponstatus[HERPS_INDEX]=0;
		if(!herps.size()){
			if(
				owner
				&&owner.player
				&&owner.player.readyweapon==self
			){
				owner.A_Log(Stringtable.Localize("$HERP_NODEPLOYED"),true);
				owner.A_SelectWeapon("HDFist");
			}
			GoAwayAndDie();
			return null;
		}
		herpbot ddd=herps[0];
		return ddd;
	}
	static void GiveController(actor caller){
		caller.A_SetInventory("HERPController",1);
		caller.findinventory("HERPController").binvbar=true;
		let ddc=HERPController(caller.findinventory("HERPController"));
		ddc.updateherps(false);
		if(ddc&&!ddc.herps.size())caller.dropinventory(ddc);
	}
	int NextHerp(){
		int newindex=weaponstatus[HERPS_INDEX]+1;
		if(newindex>=herps.size())newindex=0;
		if(weaponstatus[HERPS_INDEX]!=newindex){
			owner.A_Log(Stringtable.Localize("$HERP_NEXTLIST"),true);
			weaponstatus[HERPS_INDEX]=newindex;
		}
		return newindex;
	}
	override inventory CreateTossable(int amt){
		if(
			(herps.size()&&herps[NextHerp()])
			||updateherps(false)
		)return null;
		if(self)return weapon.createtossable(amt);
		return null;
	}
	override string gethelptext(){
		if(!herps.size())return "ERROR";
		weaponstatus[HERPS_INDEX]=clamp(weaponstatus[HERPS_INDEX],0,herps.size()-1);
		let herpcam=herps[weaponstatus[HERPS_INDEX]];
		if(!herpcam)return "ERROR";
		if(
			herpcam.health<1
			||herpcam.battery<1
		)return LWPHELP_DROP.."  Next H.E.R.P.";
		bool connected=(herpcam.bmissileevenmore);
		bool turnedon=(herpcam.bmissilemore);
		bool staystill=(herpcam.bdontfacetalker);
		if(connected)return
		LWPHELP_FIREMODE.."  Hold to pilot and:\n"
		.."  "..LWPHELP_FIRESHOOT
		..LWPHELP_ALTRELOAD.."  Set home angle\n"
		..LWPHELP_ALTFIRE.."  Turn "..(turnedon?"Off":"On").."\n"
		..LWPHELP_ZOOM.."  "..(staystill?"Enable":"Disable").." Horizontal Scan\n"
		..LWPHELP_RELOAD.."  Disconnect manual mode\n"
		..LWPHELP_DROP.."  Next H.E.R.P."
		;
		return
		LWPHELP_RELOAD.."  Connect manual mode\n"
		..LWPHELP_ALTFIRE.."  Turn "..(turnedon?"Off":"On").."\n"
		..LWPHELP_ZOOM.."  "..(staystill?"Enable":"Disable").." Horizontal Scan\n"
		..LWPHELP_DROP.."  Next H.E.R.P."
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		if(
			!herps.size()
			||weaponstatus[HERPS_INDEX]>=herps.size()
		)return;
		let herpcam=herps[weaponstatus[HERPS_INDEX]];
		if(!herpcam)return;
		bool dead=herpcam.health<1;
		bool nobat=dead||!herpcam.bmissilemore||herpcam.battery<1;
		int scaledyoffset=46;
		name ctex=nobat?"HDXHCAM1BLANK":"HDXCAM_HERP";
		if(!nobat)texman.setcameratotexture(herpcam,ctex,60);
		sb.drawimage(
			ctex,(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
			scale:nobat?(1,1):((0.25/1.2),0.25)
		);
		sb.drawimage(
			"tbwindow",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
		);
		if(!dead)sb.drawimage(
			"redpxl",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.4,scale:(2,2)
		);
		sb.drawnum(dead?0:max(0,herpcam.ammo[0]%100),
			24+bob.x,22+bob.y,sb.DI_SCREEN_CENTER,Font.CR_RED,0.4
		);
		int cmd=dead?0:herpcam.battery;
		sb.drawnum(cmd,
			24+bob.x,32+bob.y,sb.DI_SCREEN_CENTER,cmd>10?Font.CR_OLIVE:Font.CR_BROWN,0.4
		);
		if(!herpcam.bdontfacetalker)sb.drawstring(
			sb.psmallfont,"<>",
			(bob.x-24,64+bob.y),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_CENTER,Font.CR_DARKGRAY,alpha:0.4
		);
		string hpst1="\cxAUTO",hpst2="press \cdreload\cu for manual";
		if(nobat){
			hpst1="\cuOFF";
			hpst2="press \cdaltfire\cu to turn on";
		}else if(herpcam.bmissileevenmore){
			hpst1="\cyMANUAL";
			hpst2=(owner.player.cmd.buttons&BT_FIREMODE)?"":"hold \cdfiremode\cu to steer";
		}
		sb.drawstring(
			sb.psmallfont,hpst1,
			(bob.x-29,21+bob.y),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_LEFT,alpha:0.3,scale:(0.4,0.8)
		);
		if(hpl.hd_helptext.getbool()){
			sb.drawstring(
				sb.psmallfont,hpst2,
				(0,80),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_CENTER,Font.CR_DARKGRAY,alpha:0.6
			);
		}
	}
	states{
	select:
		TNT1 A 10;
		goto super::select;
	ready:
		TNT1 A 1{
			A_SetHelpText();
			if(
				!invoker.herps.size()
				||invoker.weaponstatus[HERPS_INDEX]>=invoker.herps.size()
			){
				invoker.updateherps();
				return;
			}
			A_WeaponReady(WRF_NOFIRE|WRF_ALLOWUSER3);
			herpbot ddd=invoker.herps[invoker.weaponstatus[HERPS_INDEX]];
			if(!ddd){
				if(ddd=invoker.updateherps())A_Log("H.E.R.P. not found. Resetting list.",true);
				return;
			}
			int bt=player.cmd.buttons;
			if(
				ddd.health<1
				||ddd.distance3d(self)>frandom(0.9,1.1)*HERP_CONTROLRANGE
			)return;
			if(justpressed(BT_ALTATTACK)){
				ddd.bmissilemore=!ddd.bmissilemore;
				ddd.herpbeep();
			}

			if(justpressed(BT_ZOOM)){
				ddd.bdontfacetalker=!ddd.bdontfacetalker;
				ddd.herpbeep();
			}
			if(
				ddd.bmissileevenmore
				&&ddd.bmissilemore
			){
				if(justpressed(BT_RELOAD)){
					ddd.setstatelabel("inputabort");
				}else if(bt&BT_FIREMODE){
					if(
						bt&BT_ATTACK
						&&!invoker.weaponstatus[HERPS_TIMER]
						&&ddd.ammo[0]>0
					){
						invoker.weaponstatus[HERPS_TIMER]+=4;
						ddd.setstatelabel("shoot");
					}
					int yaw=clamp(GetMouseX(true)>>5,-10,10);
					if(!yaw)yaw=clamp(-player.cmd.sidemove,-10,10);
					int ptch=clamp(GetMouseY(true)>>5,-10,10);
					if(!ptch)ptch=clamp(player.cmd.forwardmove,-10,10);
					if(yaw||ptch){
						ddd.A_StartSound("herp/crawl",CHAN_BODY);
						ddd.pitch=clamp(ddd.pitch-clamp(ptch,-10,10),-60,60);
						ddd.angle+=clamp(yaw,-DERP_MAXTICTURN,DERP_MAXTICTURN);
						ddd.startpitch=ddd.pitch;
					}
				}
				if(justpressed(BT_USER1)){
					ddd.startangle=ddd.angle;
					ddd.herpbeep();
					A_Log("Home angle set.",true);
				}
			}else if(justpressed(BT_RELOAD)){
				ddd.setstatelabel("inputwaiting");
			}
			if(!invoker.bweaponbusy&&hdplayerpawn(self))hdplayerpawn(self).nocrosshair=0;
			if(invoker.weaponstatus[HERPS_TIMER]>0)invoker.weaponstatus[HERPS_TIMER]--;
		}goto readyend;
	user3:
		---- A 0 A_MagManager("HD4mMag");
		goto ready;
	hack:
		---- A 5 A_Log("Fetching nearby devices...",true);
		---- AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 1 A_WeaponReady(WRF_NOFIRE|WRF_ALLOWUSER3);
		---- AAAAAAAAAAAAAAAAAAA 1 A_WeaponMessage("\cj"..random(1000,9999).." "..random(1000,9999),10);
		---- A 0{
			if(random(0,3))invoker.HackNearbyHerps();
			A_StartSound("herp/beep",CHAN_WEAPON);
		}
		goto nope;
	spawn:
		TNT1 A 0;
		stop;
	}
	//attempt to use the controller to connect to another H.E.R.P.
	bool HackNearbyHerps(){
		if(!owner||!herps.size())return false;
		ThinkerIterator herpfinder=thinkerIterator.Create("HERPBot");
		herpbot mo;
		while(mo=HERPBot(herpfinder.Next())){
			if(
				mo.master!=owner
				&&mo.distance3d(owner)<frandom(0.9,1.1)*HERP_CONTROLRANGE
			){
				let opponent=mo.master;
				int hackable=1;
				if(mo.checksight(owner))hackable+=3;
				if(
					!opponent
					||!mo.checksight(opponent)
					||mo.distance3d(opponent)>(HERP_CONTROLRANGE*0.6)
				)hackable+=4;
				if(random(0,hackable)){
					mo.master=owner;
					if(opponent){
						let opcon=HERPController(opponent.findinventory("HERPController"));
						if(opcon)opcon.updateherps(false);
						mo.message("Operational fault. Please check your manual for proper maintenance. (ERR-4fd92-00B) Power low.");
					}
					owner.A_Log("H.E.R.P. connected.",true);
					mo.bmissilemore=false;
					if(owner.player)mo.bfriendly=true;else mo.bfriendly=owner.bfriendly;
					mo.A_StartSound("herp/hacked",69420);
					updateherps();
					return true;
				}else{
					owner.A_Log("Connection error. H.E.R.P. not found or credentials expired. Please email vendor technical support for assistance.",true);
					mo.target=owner;
					mo.message("IFF system alert: enemy pattern recognized.");
					mo.startangle=mo.angleto(owner);
					mo.bmissilemore=true;
					return false;
				}
			}
		}
		owner.A_Log("H.E.R.P. remote login attempt failed.",true);
		return false;
	}
}
enum HERPControllerNums{
	HERPS_INDEX=1,
	HERPS_AMMO=2,
	HERPS_MODE=3,
	HERPS_TIMER=4,
	
	HERPC_ON=1,
	HERPC_OFF=2,
	HERPC_DIRECTED=3,
	HERPC_SCANTOG=4,
}