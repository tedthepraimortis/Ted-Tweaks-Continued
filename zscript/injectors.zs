//-------------------------------------------------
// Stims and berserk
//-------------------------------------------------
class HDDrug:HDDamageHandler{
	default{
		+inventory.undroppable
		inventory.maxamount 1000000;
		HDDamageHandler.priority -1000;
		HDPickup.overlaypriority -1;
	}
    // This is the thing that makes it so you lose all of anything that counts as HDDrug on map change. It's cringe. I'll make it a CVAR. - [Ted]
//	override void PreTravelled(){amount=0;}
    override void PreTravelled(){
        if (hd_mapdrugremoval)
        {
            amount=0;
        }
    }
	override void OwnerDied(){amount=0;}
	states{
	spawn:
		TNT1 A 0;
		stop;
	}
	/*
		There's no prioritization system in place for these
		the way there is for worn items. This is an intentional
		design choice - everything *should* be fighting each other.

		To avoid unintentionally aberrant behaviour,
		make sure no modifications involve setting absolutely or
		clamping the modified value - all things should be done as
		"if more/less than X, do Y".

		Anything that wins out over something else is doing so by
		virtue of faster rate and bigger numbers.
	*/
	virtual void OnHeartbeat(hdplayerpawn hdp){}
	override void Tick(){
		super.Tick();
		if(amount<1)destroy();
	}
}
enum InjectorWeapon{
	INJECTF_SPENT=1,
	INJECTS_AMOUNT=1,
}
class PortableStimpack:HDWeapon{
	string mainhelptext;property mainhelptext:mainhelptext;
	class<actor> spentinjecttype;property spentinjecttype:spentinjecttype;
	class<actor> injecttype;property injecttype:injecttype;

	override string gethelptext(){LocalizeHelp();return LWPHELP_INJECTOR;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		sb.drawimage(
			texman.getname(icon),(-23,-7),
			sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_RIGHT
		);
	}
	override double weaponbulk(){
		return ENC_STIMPACK;
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){
		if(weaponstatus[0]&INJECTF_SPENT)doselect=false;
		return GetSpareWeaponRegular(newowner,reverse,doselect);
	}
	default{
		//$Category "Items/Hideous Destructor/Supplies"
		//$Title "Stimpack"
		//$Sprite "STIMA0"

		scale 0.37;
		inventory.pickupmessage "$PICKUP_STIMPACK";
		inventory.icon "STIMA0";
		tag "$TAG_STIMPACK";
		hdweapon.refid HDLD_STIMPAK;
		+inventory.ishealth
		+inventory.invbar
		+weapon.wimpy_weapon
		+hdweapon.fitsinbackpack
		inventory.pickupSound "weapons/pocket";

		weapon.selectionorder 1003;

		portablestimpack.mainhelptext "$STIMPACK_HELPTEXT";
		portablestimpack.spentinjecttype "SpentStim";
		portablestimpack.injecttype "InjectStimDummy";
	}
	states(actor){
	//don't use a CreateTossable override - we need the throwing stuff
	spawn:
		TNT1 A 1; //DO NOT REMOVE DELAY
		TNT1 A 0{
			if(weaponstatus[0]&INJECTF_SPENT){
				actor aa=spawn(spentinjecttype,pos,ALLOW_REPLACE);
				if(!aa)return;
				aa.target=target;aa.angle=angle;aa.pitch=pitch;aa.vel=vel;
				aa.A_StartSound("misc/stimdrop",CHAN_VOICE);
			}else setstatelabel("spawn2");
		}
		stop;
	spawn2:
		STIM A -1;
		stop;
	}

	action void A_InjectorReachDown(){
		if(hdplayerpawn(self))hdplayerpawn(self).gunbraced=false;
		if(invoker.weaponstatus[0]&INJECTF_SPENT){
			setweaponstate("nope");
			return;
		}
		let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_ONLYFULL);
		if(blockinv){
			A_TakeOffFirst(blockinv.gettag(),2);
			setweaponstate("nope");
			return;
		}
		if(pitch<55){
			A_MuzzleClimb(0,8);
			A_Refire();
			return;
		}
		setweaponstate("inject");
	}

	action void A_InjectorInject(actor agent,actor patient){invoker.InjectorInject(agent,patient);}
	virtual void InjectorInject(actor agent,actor patient){
		patient.A_SetBlend("7a 3a 18",0.1,4);

		let hdp=hdplayerpawn(patient);
		if(hdp){
			hdp.A_StartSound(hdp.medsound,CHAN_VOICE);
			hdp.A_MuzzleClimb((0,2),(0,0),(0,0),(0,0));
		}
		else patient.A_StartSound(patient.painsound,CHAN_VOICE);

		agent.A_StartSound("misc/injection",CHAN_WEAPON,CHANF_OVERLAP);
		weaponstatus[0]|=INJECTF_SPENT;

		A_InjectorEffect(patient);
	}

	action void A_InjectorEffect(actor patient){invoker.InjectorEffect(patient);}
	virtual void InjectorEffect(actor patient){
		actor a=spawn(injecttype,patient.pos,ALLOW_REPLACE);
		a.accuracy=40;a.target=patient;
	}

	states{
	select:
		TNT1 A 8{
			if(DoHelpText())A_WeaponMessage(Stringtable.Localize(invoker.mainhelptext));
			A_StartSound("weapons/pocket",8,CHANF_OVERLAP,volume:0.5);
		}
		goto super::select;
	deselect:
		TNT1 A 0{
			if(invoker.weaponstatus[0]&INJECTF_SPENT){
				DropInventory(invoker);
				return;
			}
		}
		TNT1 A 5 A_StartSound("weapons/pocket",8,CHANF_OVERLAP,volume:0.5);
		TNT1 A 0 A_Lower(999);
		wait;
	ready:
		TNT1 A 0{
			if(invoker.weaponstatus[0]&INJECTF_SPENT)DropInventory(invoker);
		}
		goto super::ready;
	fire:
	hold:
		TNT1 A 1;
		TNT1 A 0 A_InjectorReachDown();
		goto nope;
	inject:
		TNT1 A 1 A_InjectorInject(self,self);
		TNT1 AAAA 1 A_MuzzleClimb(0,-0.5);
		TNT1 A 6;
		goto nope;
	altfire:
		TNT1 A 10;
		TNT1 A 0 A_Refire();
		goto nope;
	althold:
		TNT1 A 8{
			bool helptext=DoHelpText();
			flinetracedata injectorline;
			linetrace(
				angle,42,pitch,
				offsetz:gunheight()-2,
				data:injectorline
			);
			let c=HDPlayerPawn(injectorline.hitactor);
			if(!c){
				let ccc=HDHumanoid(injectorline.hitactor);
				if(
					ccc
					&&invoker.getclassname()=="HDStimpacker"
				){
					if(
						ccc.stunned<100
						||ccc.health<10
					){
						if(helptext)A_WeaponMessage(Stringtable.Localize("$STIMPACK_NONEED"),2);
						return resolvestate("nope");
					}
					invoker.weaponstatus[0]|=INJECTF_SPENT;
					ccc.A_StartSound(ccc.painsound,CHAN_VOICE);
					ccc.stunned=max(0,ccc.stunned>>1);
					return resolvestate("injected");
				}
				if(helptext)A_WeaponMessage(Stringtable.Localize("$STIMPACK_NOTHINGTOBEDONE"));
				return resolvestate("nope");
			}
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_ONLYFULL);
			if(blockinv){
				if(helptext)A_WeaponMessage(Stringtable.Localize("$STIMPACK_TAKEOFFOTHER")..blockinv.gettag()..Stringtable.Localize("$STIMPACK_ELIPSES"));
				return resolvestate("nope");
			}
			if(IsMoving.Count(c)>4){
				bool chelptext=DoHelpText(c);
				if(c.countinv("HDStim")){
					if(chelptext)HDWeapon.ForceWeaponMessage(c,string.format(Stringtable.Localize("$STIMPACK_OVERDOSEPLAYER"),player.getusername()));
					if(helptext)A_WeaponMessage(Stringtable.Localize("$STIMPACK_FIDGETY"));
				}else{
					if(chelptext)HDWeapon.ForceWeaponMessage(c,string.format(Stringtable.Localize("$STIMPACK_STOPSQUIRMING"),player.getusername()));
					if(helptext)A_WeaponMessage(Stringtable.Localize("$STIMPACK_STAYSTILLOTHER"));
				}
				return resolvestate("nope");
			}
			if(
				//because poisoning people should count as friendly fire!
				(teamplay || !deathmatch)&&
				(
					(
						invoker.injecttype=="InjectStimDummy"
						&& c.countinv("HDStim")
					)||
					(
						invoker.injecttype=="InjectZerkDummy"
						&& c.countinv("HDZerk")>HDZerk.HDZERK_COOLOFF
					)
				)
			){
				if(DoHelpText(c))HDWeapon.ForceWeaponMessage(c,string.format(Stringtable.Localize("$STIMPACK_OVERDOSEPLAYER"),player.getusername()));
				if(DoHelpText())A_WeaponMessage(Stringtable.Localize("$STIMPACK_SEEMFIDGETY"));
				return resolvestate("nope");
			}

			//and now...
			A_InjectorInject(self,c);
			return resolvestate("injected");
		}
	injected:
		TNT1 A 8;
		goto nope;
	}
}
class InjectStimDummy:IdleDummy{
	hdplayerpawn tg;
	states{
	spawn:
		TNT1 A 6 nodelay{
			tg=HDPlayerPawn(target);
			if(!tg||tg.bkilled){destroy();return;}
			if(tg.countinv("HDZerk")>HDZerk.HDZERK_COOLOFF)tg.aggravateddamage+=int(ceil(accuracy*0.01*random(1,3)));
		}
		TNT1 A 1{
			if(!target||target.bkilled){destroy();return;}
			HDF.Give(target,"HDStim",HDStim.HDSTIM_DOSE);
		}stop;
	}
}
class HDStim:HDDrug{
	enum StimAmounts{
		HDSTIM_DOSE=400,
		HDSTIM_MAX=480,
	}
	override void doeffect(){
		let hdp=hdplayerpawn(owner);

		double ret=min(0.1,amount*0.003);
		if(hdp.strength<1.+ret)hdp.strength+=0.003;
	}
	override void OnHeartbeat(hdplayerpawn hdp){
		if(amount<1)return;
		int amt=amount;amount--;

		if(amt>HDSTIM_MAX){

			if(hdp.beatcap>max(6,20-(amount>>5)))hdp.beatcap--;

			if(hdp.stunned<10)hdp.stunned+=2;

			if(
				hdp.bloodpressure<50-(hdp.bloodloss>>4)
			)hdp.bloodpressure+=4;

		}else{

			if(hdp.beatcap>30)hdp.beatcap--;

			if(
				hdp.runwalksprint<1
			){
				if(hdp.fatigue>0)hdp.fatigue--;
				if(hdp.stunned>0)hdp.stunned--;
			}

			if(
				hdp.bloodpressure<14-(hdp.bloodloss>>4)
			)hdp.bloodpressure+=3;
		}

		if(
			hdp.beatmax>=HDCONST_MINHEARTTICS+3
			&&hdp.fatigue<=HDCONST_SPRINTFATIGUE
			&&hdp.health<hdp.healthcap+(amt>>4)
			&&random(1,300)<amt
		){
			hdp.givebody(1);
			if(hdp.fatigue>0)hdp.fatigue--;
		}

		if(hd_debug>=4)console.printf("STIM "..amt.."/"..HDSTIM_MAX.."  = "..hdp.strength);
	}
}



class PortableBerserkPack:PortableStimpack{
	default{
		//$Category "Items/Hideous Destructor/Supplies"
		//$Title "Berserk Pack"
		//$Sprite "PSTRA0"

		inventory.pickupmessage "$PICKUP_ZERKPACK";
		inventory.icon "PSTRA0";
		tag "$TAG_ZERKPACK";
		hdweapon.refid HDLD_BERSERK;

		weapon.selectionorder 1002;

		portablestimpack.mainhelptext "$ZERKPACK_MAINHELPTEXT";
		portablestimpack.spentinjecttype "SpentZerk";
		portablestimpack.injecttype "InjectZerkDummy";
	}
	states{
	spawn2:
		PSTR A -1;
		stop;
	}
}
class InjectZerkDummy:InjectStimDummy{
	states{
	spawn:
		TNT1 A 60 nodelay{
			tg=HDPlayerPawn(target);
		}
		TNT1 A 1{
			if(!tg||tg.bkilled){destroy();return;}

			if(tg.countinv("HDStim"))tg.aggravateddamage+=int(ceil(tg.countinv("HDStim")*0.05*random(1,3)));
			else tg.aggravateddamage++;

			let zzz=tg.findinventory("HDZerk");
			if(!zzz||zzz.amount<1){
				tg.A_GiveInventory("HDZerk",HDZerk.HDZERK_MAX);

				if(hdplayerpawn(tg))tg.A_StartSound(hdplayerpawn(tg).xdeathsound,CHAN_VOICE);
				else tg.A_StartSound("*xdeath",CHAN_VOICE);
				HDPlayerPawn.Disarm(self);
				tg.A_SelectWeapon("HDFist");
			}else{
				if(zzz.amount>HDZerk.HDZERK_COOLOFF){
					zzz.amount+=HDZerk.HDZERK_DURATION;
				}else{
					zzz.amount=HDZerk.HDZERK_MAX+(zzz.amount>>5);
				}
				if(hdplayerpawn(tg))tg.A_StartSound(hdplayerpawn(tg).painsound,CHAN_VOICE);
				else tg.A_StartSound("*pain",CHAN_VOICE);
			}
		}stop;
	}
}
class HDZerk:HDDrug{
	enum ZerkAmounts{
		HDZERK_DURATION=TICRATE*60*4,
		HDZERK_COOLOFF=TICRATE*60*5,
		HDZERK_MAX=HDZERK_COOLOFF+HDZERK_DURATION,
		HDZERK_OVER=HDZERK_MAX+HDZERK_COOLOFF,
	}
	override void DisplayOverlay(hdstatusbar sb,hdplayerpawn hpl){
		sb.SetSize(0,320,200);
		sb.BeginHUD(forcescaled:true);
		sb.fill(
			amount<HDZERK_COOLOFF?
				color(min(100,amount>>5)+(hpl.beatcount?random[zerkshit](-1,1):random[zerkshit](-5,5)),0,0,0)
				:color(min(100,(amount-HDZERK_COOLOFF)>>5)+(hpl.beatcount>>2),90,14,12),
			0,0,screen.getwidth(),screen.getheight()
		);
	}
	clearscope static bool IsZerk(actor zerker){
		return zerker.countinv("HDZerk")>HDZerk.HDZERK_COOLOFF;
	}
	override void DoEffect(){
		if(amount<1)return;
		int amt=amount;amount--;

		let hdp=hdplayerpawn(owner);
		if(amt==(HDZERK_COOLOFF+128))hdp.AddBlackout(256,2,4,24);

		bool iszerk=amt>HDZERK_COOLOFF;
		if(
			iszerk
			&&hdp.bloodloss<HDCONST_MAXBLOODLOSS
		){
			if(
				iszerk
				&&hdp.strength<3.
			)hdp.strength+=0.03;

			if(hdp.bloodpressure<40-(hdp.bloodloss>>4))hdp.bloodpressure++;
			if(amt>HDZERK_MAX){
				if(!random(0,7))hdp.damagemobj(hdp,hdp,random(1,5),"bashing",DMG_NO_ARMOR|DMG_NO_PAIN);
				if(!random(0,31))hdp.aggravateddamage++;
				if(hdp.beatcap>random(1,12))hdp.beatcap--;
			}else if(amt>(HDZERK_MAX-(TICRATE<<1))){
				if(hdp.strength<2.)hdp.strength+=0.05;
				hdp.stunned=max(hdp.stunned,10);
				hdp.muzzleclimb1+=(frandom(-2,2),frandom(-2,2));
				hdp.vel+=(frandom(-0.5,0.5),frandom(-0.5,0.5),frandom(-0.5,0.5));
				if(!random(0,3)){
					hdp.givebody(1);
					A_SetBlend("20 0a 0f",0.4,3);

					if(!random(0,int(8-amt*0.0005))){
						if(!random(0,7)){
							hdp.oldwoundcount++;
							if(amount<(HDZERK_MAX-(TICRATE<<2)))hdp.A_StartSound(hdp.painsound,CHAN_VOICE);
						}
						else if(!random(0,7))hdp.aggravateddamage++;
					}

					if(!HDFist(hdp.player.readyweapon)){
						hdp.Disarm(hdp);
						hdp.A_SelectWeapon("HDFist");
					}
				}
			}else if(amt>(HDZERK_MAX-(TICRATE<<3))){
				hdp.muzzleclimb1+=(frandom(-1,1),frandom(-1,1));
				hdp.vel+=(frandom(-0.1,0.1),frandom(-0.1,0.1),frandom(-0.1,0.1));
				if(hdp.fatigue>0)hdp.fatigue-=1;
				if(!random(0,3)){
					hdp.givebody(1);
					if(!HDFist(hdp.player.readyweapon)){
						hdp.Disarm(hdp);
						hdp.A_SelectWeapon("HDFist");
					}
				}
			}else if(iszerk){
				if(hdp.health<(hdp.healthcap<<2))hdp.givebody(1);
				if(hdp.stunned)hdp.stunned=hdp.stunned*4/5;
				if(hdp.fatigue>0&&!(level.time&(1|2)))hdp.fatigue-=1;
				if(hdp.incaptimer)hdp.incaptimer=hdp.incaptimer*14/15;
			}
		}else if(amt==HDZERK_COOLOFF){
			hdp.A_StartSound(hdp.painsound,CHAN_VOICE);
			if(!random(0,4))hdp.aggravateddamage+=random(1,3);
		}else if(amt>0){
			if(
				!countinv("HDStim")
				||!(level.time&(1|2|4))
			){
				if(hdp.stunned<40)hdp.stunned+=3;
				if(hdp.fatigue<HDCONST_SPRINTFATIGUE)hdp.fatigue++;
			}
		}

	}
	override void OnHeartbeat(hdplayerpawn hdp){
		if(amount<1)return;

		bool iszerk=(amount-HDZERK_COOLOFF)>0;

		//fatigue eventually overrides zerk
		if(hdp.fatigue>HDCONST_DAMAGEFATIGUE*1.4)
			hdp.damagemobj(self,hdp,hdp.beatmax+4,"internal");

		if(iszerk){
			hdp.beatmax=clamp(hdp.beatmax,4,14);

			if(!(hdp.beatcount%12)){
				//twitchy
				if(!IsMoving.Count(hdp)){
					if(hdp.floorz>=hdp.pos.z)
						hdp.A_ChangeVelocity(frandom(-2,3),frandom(-2,2),1,CVF_RELATIVE);

					if(!(hdp.player.cmd.buttons&BT_ATTACK))
						hdp.muzzledrift+=(random(-14,14),random(-24,14));
					else hdp.muzzledrift+=(frandom(-2,2),frandom(-3,2));
				}
			}
			if(
				amount<(HDZERK_MAX-(TICRATE<<2))
				&&!random(0,10)
			){
				sound yell=hdp.tauntsound;
				int yellwhich=random(1,100);
				if(yellwhich<20)yell=hdp.gruntsound;
				else if(yellwhich<40)yell=hdp.painsound;
				else if(yellwhich<60)yell=hdp.deathsound;
				else yell=hdp.xdeathsound;
				A_AlertMonsters();
				hdp.bspawnsoundsource=true;
				hdp.A_StartSound(yell,CHAN_VOICE);
			}

		}else if(amount>0){
			if(hdp.beatcap>HDCONST_MINHEARTTICS+random(1,70+countinv("HDStim")))hdp.beatcap--;
		}
	}
}

class SpentStim:HDDebris{
	default{
		translation "176:191=80:95";
		xscale 0.32;yscale 0.28;radius 3;height 3;
		bouncesound "misc/zerkdrop";
	}
	states{
	spawn:
		SYRB A 0;
	spawn2:
		---- A 1{
			A_SetRoll(roll+60,SPF_INTERPOLATE);
		}wait;
	death:
		---- A -1{
			roll=0;
			if(!random(0,1))scale.x*=-1;
		}stop;
	}
}
class SpentZerk:SpentStim{
	default{
		translation "none";
	}
	states{
	spawn:
		SYRB A 0 nodelay A_JumpIf(Wads.CheckNumForName("id",0)==-1,"freed");
		goto spawn2;
	freed:
		PSTR B 0{scale=getdefaultbytype("PortableBerserkPack").scale;}
		goto spawn2;
	}
}
