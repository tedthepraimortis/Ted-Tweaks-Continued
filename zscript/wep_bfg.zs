// ------------------------------------------------------------
// BFG9k
// ------------------------------------------------------------
class BFG9K:HDCellWeapon{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "BFG 9k"
		//$Sprite "BFUGA0"

		+hdweapon.hinderlegs
		weapon.selectionorder 91;
		weapon.slotnumber 7;
		weapon.slotpriority 1;
		weapon.kickback 200;
		weapon.bobrangex 0.4;
		weapon.bobrangey 1.1;
		weapon.bobspeed 1.8;
		scale 0.7;
		hdweapon.barrelsize 32,3.5,7;
		hdweapon.refid HDLD_BFG;
		tag "$TAG_BFG9000";
		inventory.pickupmessage "$PICKUP_BFG9000";
	}
	override string getobituary(actor victim,actor inflictor,name mod,bool playerattack){
		String msg=Stringtable.Localize("OB_BFG9000");
		if(bplayingid)msg=("OB_BFG9000ID");
		return msg;
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	//BFG9k.Spark(self,4);
	//BFG9k.Spark(self,4,gunheight()-2);
	static void Spark(actor caller,int sparks=1,double sparkheight=10){
		actor a;vector3 spot;
		vector3 origin=caller.pos+(0,0,sparkheight);
		double spp;double spa;
		for(int i=0;i<sparks;i++){
			spp=caller.pitch+frandom(-20,20);
			spa=caller.angle+frandom(-20,20);
			spot=random(32,57)*(cos(spp)*cos(spa),cos(spp)*sin(spa),-sin(spp));
			a=caller.spawn("BFGSpark",origin+spot,ALLOW_REPLACE);
			a.vel+=caller.vel*0.9-spot*0.03;
		}
	}
	actor ShootBall(actor inflictor,actor source){
		inflictor.A_StartSound("weapons/bfgfwoosh",CHAN_WEAPON,CHANF_OVERLAP);
		weaponstatus[BFGS_CHARGE]=0;
		weaponstatus[BFGS_BATTERY]=0;
		weaponstatus[BFGS_CRITTIMER]=0;
		if(random(0,7))weaponstatus[0]&=~BFGF_DEMON;

		vector3 ballvel=(cos(inflictor.pitch)*(cos(inflictor.angle),sin(inflictor.angle)),-sin(inflictor.pitch));

		vector3 spawnpos=(inflictor.pos.xy,inflictor.pos.z+inflictor.height*0.8)+ballvel*6;
		if(inflictor.viewpos)spawnpos+=inflictor.viewpos.offset;

		let bbb=spawn("BFGBallTail",spawnpos);
		if(bbb){
			bbb.target=source;
			bbb.pitch=inflictor.pitch;
			bbb.angle=inflictor.angle;
			bbb.vel=inflictor.vel+ballvel*4.;
		}
		bbb=spawn("BFGBalle",spawnpos);
		if(bbb){
			bbb.target=source;
			bbb.master=source;
			bbb.pitch=inflictor.pitch;
			bbb.angle=inflictor.angle;
			bbb.vel=inflictor.vel+ballvel*bbb.speed;
		}
		return bbb;
	}
	override bool IsBeingWorn(){return weaponstatus[0]&BFGF_STRAPPED;}
	override inventory CreateTossable(int amt){
		if(
			weaponstatus[0]&BFGF_STRAPPED
			&&weaponstatus[BFGS_CRITTIMER]<1
		){
			if(
				owner
				&&owner.player
				&&owner.player.readyweapon==self
			)owner.player.setpsprite(PSP_WEAPON,findstate("togglestrap"));
			return null;
		}
		return super.CreateTossable(amt);
	}
	override void tick(){
		super.tick();

		if(!owner)return;
		if(owner.health<1){
			weaponstatus[0]&=~BFGF_STRAPPED;
			if(
				weaponstatus[BFGS_CRITTIMER]>0
			)owner.A_DropInventory(getclass());
		}else if(
			!owner.player
			||(
				owner.player.readyweapon!=self
				&&!NullWeapon(owner.player.readyweapon)
			)
		)weaponstatus[0]&=~BFGF_STRAPPED;
	}
	override void doeffect(){
		let hdp=hdplayerpawn(owner);
		if(hdp){
			//droop downwards
			if(
				!hdp.gunbraced
				&&!!hdp.player
				&&hdp.player.readyweapon==self
				&&hdp.strength
				&&hdp.pitch<10
				&&!(weaponstatus[0]&BFGF_STRAPPED)
			)hdp.A_MuzzleClimb((
				frandom(-0.06,0.06),
				frandom(0.1,clamp(1-pitch,0.08/hdp.strength,0.12))
			),(0,0),(0,0),(0,0));
		}
		super.doeffect();
	}
	override double gunmass(){
		return 15
		+(weaponstatus[BFGS_CHARGE]>=0?1:0)
		+(weaponstatus[BFGS_BATTERY]>=0?1:0)
		+(weaponstatus[0]&BFGF_STRAPPED?0:4);
	}
	override double weaponbulk(){
		double blx=(weaponstatus[0]&BFGF_STRAPPED)?400:240;
		return blx
			+(weaponstatus[BFGS_CHARGE]>=0?ENC_BATTERY_LOADED:0)
			+(weaponstatus[BFGS_BATTERY]>=0?ENC_BATTERY_LOADED:0)
		;
	}
	override string,double getpickupsprite(){return "BFUGA0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawbattery(-54,-4,sb.DI_SCREEN_CENTER_BOTTOM,reloadorder:true);
			sb.drawnum(hpl.countinv("HDBattery"),-46,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		int bffb=hdw.weaponstatus[BFGS_BATTERY];
		if(bffb>0)sb.drawwepnum(bffb,20,posy:-10);
		else if(!bffb)sb.drawstring(
			sb.mamountfont,"000000",
			(-16,-14),sb.DI_TEXT_ALIGN_RIGHT|sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
			Font.CR_DARKGRAY
		);
		bffb=hdw.weaponstatus[BFGS_CHARGE];
		if(bffb>0)sb.drawwepnum(bffb,20);
		else if(!bffb)sb.drawstring(
			sb.mamountfont,"000000",
			(-16,-7),sb.DI_TEXT_ALIGN_RIGHT|sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
			Font.CR_DARKGRAY
		);

		if(hdw.weaponstatus[0]&BFGF_STRAPPED){
			sb.drawrect(-26,-17,10,1);
			sb.drawrect(-24,-20,8,1);
			sb.drawrect(-21,-23,5,1);
		}
	}
	override string gethelptext(){
		LocalizeHelp();
		return
		LWPHELP_FIRE..StringTable.Localize("$BFGWH_FIRE")
		..LWPHELP_ALTFIRE..StringTable.Localize("$BFGWH_ALTFIRE")
		..LWPHELP_RELOAD..StringTable.Localize("$BFGWH_RELOAD")
		..LWPHELP_ALTRELOAD..StringTable.Localize("$BFGWH_ALTRELOAD")
		..LWPHELP_UNLOADUNLOAD
		..LWPHELP_USE.."+"..LWPHELP_UNLOAD..StringTable.Localize("$BFGWH_USEPUNL")
		;
	}
	override void consolidate(){
		CheckBFGCharge(BFGS_BATTERY);
		CheckBFGCharge(BFGS_CHARGE);
	}
	states{
	altfire:
	togglestrap:
		#### A 3{
			A_WeaponBusy();
			if(invoker.weaponstatus[0]&BFGF_STRAPPED){
				A_SetTics(6);
				A_StartSound("weapons/bfgclick",8);
			}
		}
		#### A 1 offset(0,WEAPONTOP+1);
		#### A 1 offset(0,WEAPONTOP+2);
		#### A 1 offset(0,WEAPONTOP+4);
		#### A 1 offset(0,WEAPONTOP+12);
		#### A 1 offset(0,WEAPONTOP+20);
		#### A 1 offset(0,WEAPONTOP+30);
		#### A 1 offset(0,WEAPONTOP+38);
		#### A 4{
			invoker.weaponstatus[0]^=BFGF_STRAPPED;
			if(invoker.weaponstatus[0]&BFGF_STRAPPED){
				A_SetTics(6);
				A_StartSound("weapons/bfgclick",8,CHANF_OVERLAP);
				invoker.bobrangex=invoker.default.bobrangex*0.4;
				invoker.bobrangey=invoker.default.bobrangey*0.4;
			}else{
				invoker.bobrangex=invoker.default.bobrangex;
				invoker.bobrangey=invoker.default.bobrangey;
			}
			A_StartSound("weapons/bfglock",8);
			A_AddBlackout(196,96,72);
		}
		#### A 1 offset(0,WEAPONTOP+38);
		#### A 1 offset(0,WEAPONTOP+30);
		#### A 1 offset(0,WEAPONTOP+22);
		#### A 1 offset(0,WEAPONTOP+11);
		#### A 1 offset(0,WEAPONTOP+7);
		#### A 1 offset(0,WEAPONTOP+4);
		#### A 1 offset(0,WEAPONTOP+2);
		#### A 1 offset(0,WEAPONTOP+1);
		goto nope;
	ready:
		BFGG A 1{
			A_CheckIdSprite("B9KGA0","BFGGA0");
			if(invoker.weaponstatus[BFGS_CRITTIMER]>0)setweaponstate("shoot");
			A_WeaponReady(WRF_ALL);
		}goto readyend;
	select0:
		B9KG A 0{
			if(!countinv("NulledWeapon"))invoker.weaponstatus[0]&=~BFGF_STRAPPED;
			invoker.weaponstatus[0]&=~BFGF_DROPCHARGE;
		}
		BFGG C 0 A_CheckIdSprite("B9KGA0","BFGGA0");
		goto select0bfg;
	deselect0:
		BFGG C 0 A_CheckIdSprite("B9KGA0","BFGGA0");
		---- A 0 A_JumpIf(
			invoker.weaponstatus[0]&BFGF_STRAPPED
			&&!countinv("NulledWeapon")
			,"togglestrap"
		);
		goto deselect0bfg;
	althold:
		stop;
	flash:
		B9KF B 3 bright{
			A_CheckIdSprite("B9KFA0","BFGFA0",PSP_FLASH);
			A_Light1();
			HDFlashAlpha(0,true);
		}
		#### A 2 bright{
			A_Light2();
			HDFlashAlpha(200);
		}
		#### A 2 bright HDFlashAlpha(128);
		goto lightdone;

	fire:
		#### C 0 {invoker.weaponstatus[BFGS_TIMER]=0;}
	hold:
		#### C 0{
			if(
				invoker.weaponstatus[BFGS_CHARGE]>=20
				&& invoker.weaponstatus[BFGS_BATTERY]>=20
			)return resolvestate("chargeend");
			else if(
				invoker.weaponstatus[BFGS_CHARGE]>BFGC_MINCHARGE
				||invoker.weaponstatus[BFGS_BATTERY]>BFGC_MINCHARGE
			)return resolvestate("charge");
			return resolvestate("nope");
		}
	charge:
		#### B 0{
			if(
				PressingReload()
				||invoker.weaponstatus[BFGS_BATTERY]<0
				||(
					invoker.weaponstatus[BFGS_CHARGE]>=20
					&&invoker.weaponstatus[BFGS_BATTERY]>=20
				)
			)setweaponstate("nope");
		}
		#### B 6{
			invoker.weaponstatus[BFGS_TIMER]++;
			if(invoker.weaponstatus[BFGS_TIMER]>4){
				invoker.weaponstatus[BFGS_TIMER]=0;
				if(invoker.weaponstatus[BFGS_BATTERY]<20){
					invoker.weaponstatus[BFGS_BATTERY]++;
				}
				else if(invoker.weaponstatus[BFGS_CHARGE]<20)invoker.weaponstatus[BFGS_CHARGE]++;
				if(!random(0,60))invoker.weaponstatus[0]|=BFGF_DEMON;
			}
			if(health<40){
				A_SetTics(2);
				if(health>16)damagemobj(invoker,self,1,"internal");
			}else if(invoker.weaponstatus[BFGS_BATTERY]==20)A_SetTics(2);
			A_WeaponBusy(false);
			A_StartSound("weapons/bfgcharge",CHAN_WEAPON);
			BFG9k.Spark(self,1,gunheight()-2);
			A_WeaponReady(WRF_NOFIRE);
		}
		#### B 0{
			if(invoker.weaponstatus[BFGS_CHARGE]==20 && invoker.weaponstatus[BFGS_BATTERY]==20)
			A_Refire("shoot");
			else A_Refire();
		}
		loop;
	chargeend:
		#### B 1{
			BFG9k.Spark(self,1,gunheight()-2);
			A_StartSound("weapons/bfgcharge",(invoker.weaponstatus[BFGS_TIMER]>6)?CHAN_AUTO:CHAN_WEAPON);
			A_WeaponReady(WRF_ALLOWRELOAD|WRF_NOFIRE|WRF_DISABLESWITCH);
			A_SetTics(max(1,6-int(invoker.weaponstatus[BFGS_TIMER]*0.3)));
			invoker.weaponstatus[BFGS_TIMER]++;
		}
		#### B 0{
			if(invoker.weaponstatus[BFGS_TIMER]>14)A_Refire("shoot");
			else A_Refire("chargeend");
		}goto ready;
	shoot:
		#### B 0{
			invoker.weaponstatus[BFGS_TIMER]=0;
			invoker.weaponstatus[BFGS_CRITTIMER]=15;
			A_StartSound("weapons/bfgf",CHAN_WEAPON);
			hdmobai.frighten(self,512);
		}
		#### B 3{
			invoker.weaponstatus[BFGS_CRITTIMER]--;
			A_StartSound("weapons/bfgcharge",random(9005,9007));
			BFG9k.Spark(self,1,gunheight()-2);
			let ct=invoker.weaponstatus[BFGS_CRITTIMER];
			if(ct<=1){
				invoker.weaponstatus[BFGS_CRITTIMER]=0;
				player.setpsprite(PSP_WEAPON,invoker.findstate("reallyshoot"));
			}else if(ct<5)A_SetTics(1);
			else if(ct<10)A_SetTics(2);
		}wait;
	reallyshoot:
		#### A 8{
			A_AlertMonsters();
			hdmobai.frighten(self,1024);
		}
		#### B 2{
			A_ZoomRecoil(0.2);
			A_GunFlash();
			invoker.ShootBall(self,self);
		}
		#### B 0 A_JumpIf(invoker.weaponstatus[0]&BFGF_STRAPPED,"recoilstrapped");
		#### B 6 A_ChangeVelocity(-2,0,3,CVF_RELATIVE);
		#### C 6{
			A_MuzzleClimb(
				1,3,
				-frandom(0.8,1.2),-frandom(2.4,4.6),
				-frandom(1.8,2.8),-frandom(6.4,9.6),
				1,2
			);
			if(!random(0,5))DropInventory(invoker);
		}goto nope;
	recoilstrapped:
		#### BBBB 1 A_ChangeVelocity(-0.3,0,0.06,CVF_RELATIVE);
		#### CCCC 1{
			A_MuzzleClimb(
				0.1,0.2,
				-frandom(0.08,0.1),-frandom(0.2,0.3),
				-frandom(0.18,0.24),-frandom(0.6,0.8),
				0.1,0.15
			);
		}goto nope;

	reload:
		#### A 0{
			if(
				invoker.weaponstatus[BFGS_BATTERY]>=20
				||!countinv("HDBattery")
				||(
					invoker.weaponstatus[BFGS_CHARGE]<BFGC_MINCHARGE
					&&HDMagAmmo.NothingLoaded(self,"HDBattery")
				)
			)setweaponstate("nope");
			else invoker.weaponstatus[BFGS_LOADTYPE]=BFGC_RELOADMAX;
		}goto reload1;
	altreload:
	reloadempty:
		#### A 0{
			if(
				!countinv("HDBattery")
			)setweaponstate("nope");
			else invoker.weaponstatus[BFGS_LOADTYPE]=BFGC_ONEEMPTY;
		}goto reload1;
	unload:
		#### A 0{
			if(pressinguse()){
				if(
					!(invoker.weaponstatus[0]&BFGF_STRAPPED)
					&&invoker.weaponstatus[BFGS_BATTERY]>=0
					&&pressingunload()
					&&(
						invoker.weaponstatus[BFGS_CHARGE]<20
						||invoker.weaponstatus[BFGS_BATTERY]<20
					)&&(
						invoker.weaponstatus[BFGS_CHARGE]>BFGC_MINCHARGE
						||invoker.weaponstatus[BFGS_BATTERY]>BFGC_MINCHARGE
					)
				){
					invoker.weaponstatus[0]|=BFGF_DROPCHARGE;
					DropInventory(invoker);
				}
				setweaponstate("nope");
				return;
			}
			invoker.weaponstatus[BFGS_LOADTYPE]=BFGC_UNLOADALL;
		}goto reload1;
	reload1:
		#### A 4;
		#### C 2 offset(0,36) A_MuzzleClimb(0,0.4,0,0.8,wepdot:false);
		#### C 2 offset(0,38) A_MuzzleClimb(0,0.8,0,1.,wepdot:false);
		#### C 4 offset(0,40){
			A_MuzzleClimb(0,1,0,1,0,1,0,0.8,wepdot:false);
			A_StartSound("weapons/bfgclick2",8);
		}
		#### C 2 offset(0,41){
			A_StartSound("weapons/bfgopen",8);

			A_MuzzleClimb(-0.1,0.8,-0.05,0.5,wepdot:false);
			if(invoker.weaponstatus[BFGS_BATTERY]>=0){
				HDMagAmmo.SpawnMag(self,"HDBattery",invoker.weaponstatus[BFGS_BATTERY]);
				invoker.weaponstatus[BFGS_BATTERY]=-1;
				A_SetTics(3);
			}
		}
		#### C 2 offset(0,42){
			if(invoker.weaponstatus[BFGS_CHARGE]>=0){
				HDMagAmmo.SpawnMag(self,"HDBattery",invoker.weaponstatus[BFGS_CHARGE]);
				invoker.weaponstatus[BFGS_CHARGE]=-1;
				A_SetTics(4);
			}

			if(invoker.weaponstatus[0]&BFGF_DEMON){
				invoker.weaponstatus[0]&=~BFGF_DEMON;
				class<actor> shard="BFGNecroShard";
				if(!random(0,3))A_FireProjectile("YokaiSpawner");
				for(int i=0;i<5;i++){
					A_FireProjectile(shard,random(170,190),spawnofs_xy:random(-20,20));
				}
			}
			A_MuzzleClimb(-0.05,0.4,-0.05,0.2,wepdot:false);
		}
		#### C 4 offset(0,42){
			if(invoker.weaponstatus[BFGS_LOADTYPE]==BFGC_UNLOADALL)setweaponstate("reload3");
			else A_StartSound("weapons/pocket",9);
		}
		#### C 12 offset(0,43);
	insertbatteries:
		#### C 12 offset(0,42)A_StartSound("weapons/bfgbattout",8);
		#### C 10 offset(0,36)A_StartSound("weapons/bfgbattpop",8);
		#### C 0{
			let mmm=hdmagammo(findinventory("HDBattery"));
			if(
				!mmm
				||mmm.amount<1
				||(
					invoker.weaponstatus[BFGS_BATTERY]>=0
					&&invoker.weaponstatus[BFGS_CHARGE]>=0
				)
			){
				setweaponstate("reload3");
				return;
			}
			int batslot=(
				invoker.weaponstatus[BFGS_BATTERY]<0
				&&invoker.weaponstatus[BFGS_CHARGE]<0
			)?BFGS_CHARGE:BFGS_BATTERY;
			if(invoker.weaponstatus[BFGS_LOADTYPE]==BFGC_ONEEMPTY){
				invoker.weaponstatus[BFGS_LOADTYPE]=BFGC_RELOADMAX;
				mmm.LowestToLast();
				invoker.weaponstatus[batslot]=mmm.TakeMag(false);
			}else{
				invoker.weaponstatus[batslot]=mmm.TakeMag(true);
			}
		}
		#### C 0 A_JumpIf(
				!countinv("HDBattery")
				||invoker.weaponstatus[BFGS_BATTERY]>=0
			,
			"reload3"
		);
		loop;
	reload3:
		#### C 12 offset(0,38) A_StartSound("weapons/bfgopen",8);
		#### C 16 offset(0,37) A_StartSound("weapons/bfgclick2",8);
		#### C 2 offset(0,38);
		#### C 2 offset(0,36);
		#### A 2 offset(0,34);
		#### A 12;
		goto ready;

	user3:
		#### A 0 A_MagManager("HDBattery");
		goto ready;

	spawn:
		BFUG A -1 nodelay{
			if(invoker.weaponstatus[BFGS_CRITTIMER]>0)invoker.setstatelabel("bwahahahaha");
			else if(invoker.weaponstatus[0]&BFGF_DROPCHARGE)invoker.setstatelabel("dropcharge");
		}
	bwahahahaha:
		BFUG A 3{
			invoker.weaponstatus[BFGS_CRITTIMER]--;
			A_StartSound("weapons/bfgcharge",CHAN_AUTO);
			BFG9k.Spark(self,1,6);
			if(invoker.weaponstatus[BFGS_CRITTIMER]<=1){
				invoker.weaponstatus[BFGS_CRITTIMER]=0;
				invoker.setstatelabel("heh");
			}else if(invoker.weaponstatus[BFGS_CRITTIMER]<10)A_SetTics(2);
			else if(invoker.weaponstatus[BFGS_CRITTIMER]<5)A_SetTics(1);
		}wait;
	heh:
		BFUG A 8;
		BFUG A 4{
			invoker.A_StartSound("weapons/bfgfwoosh",CHAN_AUTO);
			invoker.weaponstatus[BFGS_CRITTIMER]=0;
			invoker.weaponstatus[BFGS_CHARGE]=0;invoker.weaponstatus[BFGS_BATTERY]=0;
			invoker.ShootBall(invoker,invoker.lastenemy);
		}
		BFUG A 0{
			invoker.A_ChangeVelocity(-cos(pitch)*4,0,sin(pitch)*4,CVF_RELATIVE);
		}goto spawn;

	dropcharge:
		BFUG A 6{
			if(
				(
					invoker.weaponstatus[BFGS_BATTERY]>=20
					&&invoker.weaponstatus[BFGS_CHARGE]>=20
				)
				||invoker.weaponstatus[BFGS_BATTERY]<0
			){
				invoker.weaponstatus[0]&=~BFGF_DROPCHARGE;
				invoker.setstatelabel("spawn");
				return;
			}
			invoker.weaponstatus[BFGS_TIMER]++;
			if (invoker.weaponstatus[BFGS_TIMER]>3){
				invoker.weaponstatus[BFGS_TIMER]=0;
				if(invoker.weaponstatus[BFGS_BATTERY]<20){
					invoker.weaponstatus[BFGS_BATTERY]++;
				}
				else invoker.weaponstatus[BFGS_CHARGE]++;
				if(!random(0,60))invoker.weaponstatus[0]|=BFGF_DEMON;
			}
			if(invoker.weaponstatus[BFGS_BATTERY]==20)A_SetTics(5);
			invoker.A_StartSound("weapons/bfgcharge",CHAN_VOICE);
			BFG9k.Spark(invoker,1,gunheight()-2);
		}loop;
	}

	override void postbeginplay(){
		super.postbeginplay();
		if(owner&&owner.player&&owner.player.readyweapon==self)weaponstatus[0]|=BFGF_STRAPPED;
	}
	override void InitializeWepStats(bool idfa){
		weaponstatus[BFGS_CHARGE]=20;
		weaponstatus[BFGS_BATTERY]=20;
		weaponstatus[BFGS_TIMER]=0;
		weaponstatus[BFGS_CRITTIMER]=0;
		if(idfa){
			weaponstatus[0]&=~BFGF_DEMON;
		}else weaponstatus[0]=0;
	}
}
enum bfg9kstatus{
	BFGF_STRAPPED=1,
	BFGF_DEMON=2,
	BFGF_DROPCHARGE=4,

	BFGS_STATUS=0,
	BFGS_CHARGE=1,
	BFGS_BATTERY=2,
	BFGS_TIMER=3,
	BFGS_LOADTYPE=4,
	BFGS_CRITTIMER=5,

	BFGC_MINCHARGE=6,

	BFGC_RELOADMAX=0, //dump everything and load as much as possible
	BFGC_UNLOADALL=1, //dump everything
	BFGC_ONEEMPTY=2, //dump everything and load one empty, one good
};

class BFGSpark:HDActor{
	default{
		+nointeraction +forcexybillboard +bright
		radius 0;height 0;
		renderstyle "add";alpha 0.1; scale 0.16;
	}
	states{
	spawn:
		BFE2 DDDDDDDDDD 1 bright nodelay A_FadeIn(0.1);
		BFE2 D 1 A_FadeOut(0.3);
		wait;
	}
}
class BFGNecroShard:Actor{
	default{
		+ismonster +float +nogravity +noclip +lookallaround +nofear +forcexybillboard +bright
		radius 0;height 0;
		scale 0.16;renderstyle "add";
		speed 24;
	}
	states{
	spawn:
		BFE2 A 0 nodelay{
			A_GiveInventory("ImmunityToFire");
			A_SetGravity(0.1);
		}
	spawn2:
		BFE2 AB 1{
			A_Look();
			A_Wander();
		}loop;
	see:
		BFE2 D 1{
			A_Wander();
			A_SpawnProjectile("BFGSpark",0,random(-24,24),random(-24,24),2,random(-14,14));
			if(!random(0,3))vel.z+=random(-4,8);
			if(alpha<0.2)setstatelabel("see2");
		}
		BFE2 A 1 bright A_Wander();
		BFE2 B 1 bright{
			A_Wander();
			A_FadeOut(0.1);
		}
		loop;
	see2:
		TNT1 AAA 0 A_Wander();
		TNT1 A 5{
			A_VileChase();
			A_SpawnItemEx("BFGSpark",random(-4,4),random(-4,4),random(28,36),random(4,6),random(-1,1),random(-6,6),random(0,360),SXF_NOCHECKPOSITION,200);
		}
		loop;
	heal:
		TNT1 A 1{
			bshootable=true;
			A_Die();
		}wait;
	death:
		BFE2 AAAAAAA 0 A_SpawnItemEx("BFGSpark",random(-4,4),random(-4,4),random(28,36),random(4,6),random(-1,1),random(-6,6),random(0,360),SXF_NOCHECKPOSITION);
		BFE2 AAAA 1 A_SpawnItemEx("BFGSpark",random(-4,4),random(-4,4),random(28,36),random(4,6),random(-1,1),random(-6,6),random(0,360),SXF_NOCHECKPOSITION);
		stop;
	}
}
class BFGShard:BFGNecroShard{
	states{
	see2:
		TNT1 A 0;
		stop;
	}
}


class BFGBalle:HDFireball{
	int ballripdmg;
	bool freedoom;
	default{
		-notelestomp +telestomp
		+skyexplode +forceradiusdmg +ripper -noteleport +notarget
		+bright
		decal "HDBFGLightning";
		renderstyle "add";
		damagefunction(ballripdmg);
		seesound "weapons/plasmaf";
		deathsound "weapons/bfgx";
		obituary "$OB_MPBFG_BOOM";
		alpha 0.9;
		height 6;
		radius 6;
		speed 6;
		gravity 0;
	}
	void A_BFGBallZap(){
		if(pos.z-floorz<12)vel.z+=1;
		else if(ceilingz-pos.z<19)vel.z-=1;

		for(int i=0;i<10;i++){
			A_SpawnParticle(freedoom?"55 88 ff":"55 ff 88",
				SPF_RELATIVE|SPF_FULLBRIGHT,
				35,frandom(4,8),0,
				frandom(-8,8),frandom(-8,8),frandom(0,8),
				frandom(-1,1),frandom(-1,1),frandom(1,2),
				-0.1,frandom(-0.1,0.1),-0.05
			);
		}

		vector2 oldaim=(angle,pitch);
		blockthingsiterator it=blockthingsiterator.create(self,2048);
		while(it.Next()){
			actor itt=it.thing;
			if(
				(itt.bismonster||itt.player)
				&&itt!=target
				&&itt.health>0
				&&target.ishostile(itt)
				&&checksight(itt)
			){
				A_Face(itt,0,0);
				A_CustomRailgun((0),0,"",freedoom?"55 88 ff":"55 ff 88",
					RGF_CENTERZ|RGF_SILENT|RGF_NOPIERCING|RGF_FULLBRIGHT,
					0,50.0,"BFGPuff",0,0,2048,18,0.2,1.0
				);
				doordestroyer.destroydoor(self,maxwidth:64,range:2048);
				break;
			}
		}
		angle=oldaim.x;pitch=oldaim.y;
	}
	void A_BFGBallSplodeZap(){
		blockthingsiterator it=blockthingsiterator.create(self,2048);
		while(it.Next()){
			actor itt=it.thing;
			if(
				(itt.bismonster||itt.player)
				&&itt!=target
				&&itt.health>0
				&&!target.isfriend(itt)
				&&!target.isteammate(itt)
				&&checksight(itt)
			){
				A_Face(itt,0,0);
				int hhh=min(itt.health,4096);
				for(int i=0;i<hhh;i+=1024){
					A_CustomRailgun((0),0,"",freedoom?"55 88 ff":"55 ff 88",
						RGF_CENTERZ|RGF_SILENT|RGF_NOPIERCING|RGF_FULLBRIGHT,
						0,50.0,"BFGPuff",3,3,2048,18,0.2,1.0
					);
				}
			}
		}
	}
	void A_BFGScrew(bool tail=false){
		A_Corkscrew();
		if(tail){
			let ttt=spawn("BFGBallTail",pos,ALLOW_REPLACE);
			if(ttt){
				ttt.target=target;
				ttt.vel=vel*0.2;
			}
		}
	}
	states{
	spawn:
		TNT1 A 0 nodelay{
			A_BFGSpray();
			ballripdmg=1;
			let hdp=hdplayerpawn(target);
			if(hdp){
				pitch=hdp.gunpitch;
				angle=hdp.gunangle;
			}else if(
				!!target
				&&IsMoving.Count(target)>=6
			){
				pitch+=frandom(-3,3);
				angle+=frandom(-1,1);
			}
			freedoom=(Wads.CheckNumForName("ID",0)==-1);
		}
		BFS1 AB 2 A_SpawnItemEx("BFGBallTail",0,0,0,vel.x*0.2,vel.y*0.2,vel.z*0.2,0,168,0);
		BFS1 A 0{
			ballripdmg=random(500,1000);
			bripper=false;
		}
		goto spawn2;
	spawn2:
		BFS1 AB 1 A_BFGScrew();
		BFS1 A 1 A_BFGScrew(true);
		BFS1 BA 1 A_BFGScrew();
		BFS1 B 1 A_BFGScrew(true);
		---- A 0 A_BFGBallZap();
		loop;
	death:
		BFE1 A 2;
		BFE1 B 2 A_Explode(160,512,0);
		BFE1 BB 2{doordestroyer.destroydoor(self,maxwidth:128,range:96);}
		BFE1 B 2{
			doordestroyer.destroydoor(self,maxwidth:128,range:96);
			DistantQuaker.Quake(self,
				6,100,16384,10,256,512,128
			);
			DistantNoise.Make(self,"world/bfgfar");
		}
		TNT1 AAAAA 0 A_SpawnItemEx("HDSmokeChunk",random(-2,0),random(-3,3),random(-2,2),random(-5,0),random(-5,5),random(0,5),random(100,260),SXF_TRANSFERPOINTERS|SXF_NOCHECKPOSITION,16);
		TNT1 AAAAA 0 A_SpawnItemEx("BFGBallRemains",-1,0,-12,0,0,0,SXF_TRANSFERPOINTERS|SXF_NOCHECKPOSITION,16);
		BFE1 CCCC 2 A_BFGBallSplodeZap();
		BFE1 CCC 0 A_SpawnItemEx("HDSmoke",random(-4,0),random(-3,3),random(0,4),random(-1,1),random(-1,1),random(1,3),0,SXF_TRANSFERPOINTERS|SXF_NOCHECKPOSITION,16);
		BFE1 DEF 6;
		BFE1 F 3 A_FadeOut(0.1);
		wait;
	}
}
class BFGBallRemains:IdleDummy{
	string pcol;
	states{
	spawn:
		TNT1 A 0 nodelay{
			pcol=(Wads.CheckNumForName("ID",0)==-1)?"55 88 ff":"55 ff 88";
			stamina=0;
		}
	spawn2:
		TNT1 AAAA 1 A_SpawnParticle(
			pcol,SPF_FULLBRIGHT,35,
			size:frandom(1,8),0,
			frandom(-16,16),frandom(-16,16),frandom(0,8),
			frandom(-1,1),frandom(-1,1),frandom(1,2),
			frandom(-0.1,0.1),frandom(-0.1,0.1),-0.05
		);
		TNT1 A 0 A_SpawnItemEx("HDSmoke",random(-3,3),random(-3,3),random(-3,3),random(-1,1),random(-1,1),random(1,3),0,SXF_TRANSFERPOINTERS|SXF_NOCHECKPOSITION);
		TNT1 A 0{stamina++;}
		TNT1 A 0 A_JumpIf(stamina<10,"spawn2");
		TNT1 AAAAAA 2 A_SpawnParticle(
			pcol,SPF_FULLBRIGHT,35,
			size:frandom(1,8),0,
			frandom(-16,16),frandom(-16,16),frandom(0,8),
			frandom(-1,1),frandom(-1,1),frandom(1,2),
			frandom(-0.1,0.1),frandom(-0.1,0.1),-0.05
		);
		stop;
	}
}
class BFGBallTail:IdleDummy{
	default{
		+forcexybillboard
		scale 0.8;renderstyle "add";
	}
	states{
	spawn:
		BFS1 AB 2 bright A_FadeOut(0.2);
		loop;
	}
}
class BFGPuff:IdleDummy{
	string pcol;
	default{
		-invisible +forcexybillboard +bloodlessimpact
		+noblood +alwayspuff -allowparticles +puffonactors +puffgetsowner +forceradiusdmg
		+hittracer
		renderstyle "add";
		damagetype "BFGBallAttack";
		scale 0.8;
		obituary "$OB_MPBFG_BOOM";
	}
	states{
	spawn:
		BFE2 A 1 bright nodelay{
			pcol=(Wads.CheckNumForName("ID",0)==-1)?"55 88 ff":"55 ff 88";
			if(target)target=target.target;
			A_StartSound("misc/bfgrail",9005);
		}
		BFE2 A 3 bright{
			A_Explode(random(196,320),320,0);

			//teleport victim
			if(
				tracer
				&&tracer!=target
				&&!tracer.player
				&&!tracer.special
				&&(
					!tracer.bismonster
					||tracer.health<1
				)
				&&!random(0,3)
			){
				spawn("TeleFog",tracer.pos,ALLOW_REPLACE);

				vector3 teleportedto=(0,0,0);

				thinkeriterator mobfinder=thinkeriterator.create("HDMobBase");
				actor mo;
				int ccc=level.killed_monsters;
				while(mo=HDMobBase(mobfinder.next())){
					if(ccc<1)break;
					if(mo.health>0)continue;
					ccc--;
					setz(mo.spawnpoint.z);
					if(checkmove(mo.spawnpoint.xy)){
						teleportedto=mo.spawnpoint;
						break;
					}
				}

				if(teleportedto==(0,0,0))teleportedto=(
					frandom(-20000,20000),
					frandom(-20000,20000),
					frandom(-20000,20000)
				);

				tracer.setorigin(teleportedto,false);
				tracer.setz(clamp(tracer.pos.z,tracer.floorz,max(tracer.floorz,tracer.ceilingz-tracer.height)));
				tracer.vel=(frandom(-10,10),frandom(-10,10),frandom(10,20));
				spawn("TeleFog",tracer.pos,ALLOW_REPLACE);
			}
		}
		BFE2 ABCDE 1 bright{
			A_FadeOut(0.05);
			A_SpawnParticle(
				pcol,SPF_FULLBRIGHT,35,
				size:frandom(1,8),0,
				frandom(-16,16),frandom(-16,16),frandom(0,8),
				frandom(-1,1),frandom(-1,1),frandom(1,2),
				frandom(-0.1,0.1),frandom(-0.1,0.1),-0.05
			);
		}
		TNT1 A 0 A_SpawnItemEx("BFGNecroShard",0,0,10,10,0,0,random(0,360),SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS,254);
		stop;
	}
}


//cell weapons get charged by BFG
extend class HDWeapon{
	bool CheckBFGCharge(int whichws){
		if(
			!owner
			||weaponstatus[whichws]<0
		)return false;
		bool chargeable=false;
		let bfug=bfg9k(owner.findinventory("bfg9k"));
		if(!bfug)return false;
		if(
			bfug.weaponstatus[BFGS_BATTERY]>BFGC_MINCHARGE
			||bfug.weaponstatus[BFGS_CHARGE]>BFGC_MINCHARGE
		)chargeable=true;
		if(!chargeable&&owner.findinventory("HDBattery")){
			let batts=HDBattery(owner.findinventory("HDBattery"));
			for(int i=0;i<batts.amount;i++){
				if(batts.mags[i]>=BFGC_MINCHARGE){
					chargeable=true;
					break;
				}
			}
		}
		if(!chargeable&&owner.FindInventory("HDBackpack",true)){
			let bp=HDBackpack(owner.FindInventory("HDBackpack",true));
			StorageItem bat=bp.Storage.find('hdbattery');
			if (bat){
				for(int i=0;i<bat.amounts.size();i++){
					if(bat.amounts[i]>=BFGC_MINCHARGE){
						chargeable=true;
						break;
					}
				}
			}
		}
		if(chargeable)weaponstatus[whichws]=20;
		return chargeable;
	}
}


//until we scriptify the bossbrain properly...
class BFGAccelerator:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			thinkeriterator it=thinkeriterator.create("BFG9k");
			actor bff;
			while(
				bff=inventory(it.Next())
			){
				let bfff=BFG9k(Bff);
				if(bfff){
					int which=randompick(BFGS_BATTERY,BFGS_CHARGE);
					bfff.weaponstatus[which]=min(bfff.weaponstatus[which]+1,20);
				}
			}
		}stop;
	}
}

