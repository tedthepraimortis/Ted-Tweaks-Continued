// ------------------------------------------------------------
// With it, on it, in it, whatever.
// ------------------------------------------------------------
class HDMagicShield:HDDamageHandler{
	default{
		+nointeraction +noblockmap

		+quicktoretaliate  //if enabled, regenerate up to maxamount
		-standstill  //if enabled, do not deplete if over maxamount
		+inventory.keepdepleted

		inventory.amount 1;
		inventory.maxamount 1024;
		inventory.icon "BON2A0";

		stamina 0;  //if set, this is the strength of the shield; otherwise use maxamount

		HDDamageHandler.priority 10000;
		+hdpickup.fullcoverage
	}

	override double getbulk(){return bulk;}
	override void AttachToOwner(actor other){
		super.AttachToOwner(other);
		if(hdmobbase(other)){
			int mmm=hdmobbase(other).maxshields;
			if(mmm>0){
				maxamount=mmm;
				amount=mmm;
				buntossable=true;
			}
		}
	}
	override inventory CreateTossable(int amt){
		if(bulk>0)return super.createtossable(amt);
		return null;
	}
	override void OnDrop(actor dropper){
		super.OnDrop(dropper);
		let aaa=HDMagAmmo(spawn("ShieldCore",pos));
		aaa.vel=vel;
		aaa.target=dropper;
		if(dropper){
			aaa.amount=1;
			aaa.mags.clear();
			aaa.mags.push(amount);
			let sss=dropper.findinventory("HDMagicShield");
			if(sss){
				aaa.mags[0]+=sss.amount;
				sss.destroy();
			}
		}
		if(self)destroy();
	}
	static void Deplete(
		actor owner,
		int amount,
		HDMagicShield shields=null,
		bool destroydepleted=false
	){
		if(!shields)shields=HDMagicShield(owner.findinventory("HDMagicShield"));
		if(shields){
			shields.amount-=amount;
			if(shields.amount<1){
				int downto=-64;
				shields.amount=downto;
				if(hd_debug)console.printf(owner.getclassname().." shield broke to "..downto.."!");
				owner.A_StartSound("misc/mobshieldx", CHAN_BODY, CHANF_OVERLAP, 0.75);
				double oradius=owner.radius;
				double oheight=owner.height;
				vector3 ovel=owner.vel;
				for(int i=0;i<10;i++){
					vector3 rpos=owner.pos+(
						frandom(-oradius,oradius),
						frandom(-oradius,oradius),
						frandom(0,oheight)
					);
					actor spk=actor.spawn("ShieldSpark",rpos,ALLOW_REPLACE);
					spk.vel=(frandom(-2,2),frandom(-2,2),frandom(-2,2))+ovel;
				}
				if(destroydepleted)shields.destroy();
			}
		}
	}
	override void DoEffect(){
		if(
			owner.bcorpse
			||owner.health<1
			||owner.isfrozen()
		)return;
		if(accuracy>0)accuracy--;

		if(
			amount<1
			&&(
				maxamount<1
				||(
					owner.player
					&&!bquicktoretaliate
				)
			)
		){
			if(!bquicktoretaliate){
				let aaa=owner.spawn("SpentShield",(owner.pos.xy,owner.pos.z+owner.height*0.8));
				if(aaa){
					aaa.vel=owner.vel+(cos(owner.angle),sin(owner.angle),1.);
				}
			}
			destroy();
			return;
		}

		//replenish shields and handle breaking/unbreaking
		if(
			!bstandstill
			&&amount>maxamount
		)amount--;
		else if(
			amount<maxamount
			&&(
				(
					mass>0
				)||(
					bquicktoretaliate
					&&!(level.time&(1|2|4))
				)
			)
		){
			amount++;
			if(mass>0)mass--;
		}

		if(
			bquicktoretaliate
			&&amount==1
			&&maxamount>1
		){
			if(hd_debug)console.printf(owner.getclassname().." shield restored!");
			FlashSparks(owner);
		}
	}
	static void FlashSparks(actor owner){
		if(!owner)return;
		owner.A_StartSound("misc/mobshieldf",CHAN_BODY,CHANF_OVERLAP,0.75);
		double oradius=owner.radius;
		double oheight=owner.height;
		for(int i=0;i<10;i++){
			vector3 rpos=owner.pos+(
				frandom(-oradius,oradius),
				frandom(-oradius,oradius),
				frandom(0,oheight)
			);
			actor spk=actor.spawn("ShieldSpark",rpos,ALLOW_REPLACE);
			vector3 sv=spk.Vec3To(owner);
			sv.z+=oheight*0.5;
			spk.vel=(sv*(1./50));
		}
	}

	//called from HDPlayerPawn and HDMobBase's DamageMobj
	override int,name,int,double,int,int,int HandleDamage(
		int damage,
		name mod,
		int flags,
		actor inflictor,
		actor source,
		double towound,
		int toburn,
		int tostun,
		int tobreak
	){
		actor victim=owner;
		if(
			!victim
			||(flags&(DMG_NO_FACTOR|DMG_FORCED))
			||amount<1
			||!inflictor
			||(inflictor==victim)
			||(inflictor is "HDBulletActor")
			||mod=="bleedout"
			||mod=="hot"
			||mod=="cold"
			||mod=="maxhpdrain"
			||mod=="internal"
			||mod=="holy"
			||mod=="jointlock"
			||mod=="staples"
		)return damage,mod,flags,towound,toburn,tostun,tobreak;

		if(!stamina)stamina=maxamount;

		int blocked=min(amount>>1,damage,stamina>>1);
		damage-=blocked;
		bool supereffective=(
			mod=="BFGBallAttack"
			||mod=="electrical"
			||mod=="balefire"
		);

		HDMagicShield.Deplete(victim,max(supereffective?(blocked<<2):blocked,1),self);


		if(hd_debug)console.printf("BLOCKED (not bullet)  "..blocked.."    OF  "..damage+blocked..",   "..amount.." REMAIN");


		//spawn shield debris
		vector3 sparkpos;
		if(
			inflictor
			&&inflictor!=source
		)sparkpos=inflictor.pos;
		else if(
			source
		)sparkpos=(
			victim.pos.xy+victim.radius*(source.pos.xy-victim.pos.xy).unit()
			,victim.pos.z+min(victim.height,source.height*0.6)
		);
		else sparkpos=(victim.pos.xy,victim.pos.z+victim.height*0.6);

		int shrd=max(1,blocked>>6);
		for(int i=0;i<shrd;i++){
			actor aaa=victim.spawn("ShieldSpark",sparkpos,ALLOW_REPLACE);
			aaa.vel=(frandom(-3,3),frandom(-3,3),frandom(-3,3));
		}

		//chance to flinch
		if(damage<1){
			if(
				!(flags&DMG_NO_PAIN)
				&&blocked>(victim.spawnhealth()>>3)
				&&random(0,255)<victim.painchance
			)hdmobbase.forcepain(victim);
		}

		return damage,mod,flags,towound,toburn,tostun,tobreak;
	}

	//called from HDBulletActor's OnHitActor
	override double,double OnBulletImpact(
		HDBulletActor bullet,
		double pen,
		double penshell,
		double hitangle,
		double deemedwidth,
		vector3 hitpos,
		vector3 vu,
		bool hitactoristall
	){
		actor victim=owner;
		if(
			!victim
			||!bullet
			||amount<1
		)return pen,penshell;

		if(!stamina)stamina=maxamount;

		double bulletpower=pen*bullet.mass*0.1;
		if(bulletpower<1){
			if(frandom(0,1)<bulletpower)bulletpower=1;
			else bulletpower=0;
		}

		int depleteshield=int(min(bulletpower,amount));


		if(hd_debug)console.printf("BLOCKED  "..depleteshield.."    OF  "..int(bulletpower)..",   "..int(amount-bulletpower).." REMAIN");


		if(depleteshield<=0){
			if(!bulletpower)return 0,penshell;
			return pen,penshell;
		}

		HDMagicShield.Deplete(victim,depleteshield,self);
		spawn("ShieldNeverBlood",bullet.pos,ALLOW_REPLACE);


		victim.vel+=(
			((victim.pos.xy,victim.pos.z+victim.height*0.5)-bullet.pos).unit()
			*depleteshield
			/victim.mass
		);
		victim.angle+=deltaangle(victim.angle,victim.angleto(bullet))*frandom(-0.005,0.03);
		victim.pitch+=frandom(-1.,1.);

		double addpenshell=min(pen,amount,stamina>>3);
		if(addpenshell>0){
			pen-=addpenshell;
			penshell+=addpenshell; //in case anything else uses this value
		}
		return pen,penshell;
	}
	states{
	use:
		TNT1 A 0{
			if(invoker.accuracy>70){
				A_DropInventory(invoker.getclassname());
			}else{
				if(!invoker.accuracy){
					if(
						invoker.amount<invoker.maxamount
						&&invoker.mass>0
					)A_Log(
						"WARNING: shield is not done charging! Aborting now will permanently degrade performance. Double-tap Use to proceed anyway."
					,true);
				}
				invoker.accuracy=80;
			}
		}fail;
	}
}


//standalone puff that replaces blood
class ShieldSpark:IdleDummy{
	default{
		+forcexybillboard +rollsprite +rollcenter
		renderstyle "add";
	}
	override void postbeginplay(){
		super.postbeginplay();
		scale*=frandom(0.2,0.5);
		roll=frandom(0,360);
	}
	states{
	spawn:
		TFOG ABCDEFGHIJ 3 bright A_FadeOut(0.08);
		stop;
	}
}

//dummy item when you don't want anything coming out for blood or puffs
class NullPuff:Actor{
	default{+nointeraction}
	states{spawn:TNT1 A 0;stop;}
}



//pickup item that gives you shields. currently unused.
class ShieldCore:HDMagAmmo{
	default{
		//$Category "Items/Hideous Destructor/"
		//$Title "Shield Core"
		//$Sprite "BON2A0"

		+forcexybillboard
		scale 0.3;

		+inventory.invbar
		+inventory.isarmor
		-hdpickup.droptranslation
		tag "$TAG_SHIELDCORE";
		inventory.icon "BON2A0";
		hdmagammo.maxperunit 1024;
		hdmagammo.magbulk ENC_426MAG;

		inventory.pickupmessage "$PICKUP_SHIELDCORE";
		inventory.pickupsound "misc/i_pkup";
	}
	override bool isused(){return true;}
	override int getsbarnum(int flags){
		int ms=mags.size()-1;
		if(ms<0)return -1000000;
		return mags[ms];
	}
	override double getbulk(){return amount*magbulk;}
	override bool Extract(){return false;}
	override bool Insert(){return false;}
	override void Tick(){
		super.Tick();
		if(accuracy>0)accuracy--;
	}
	action void A_UseShield(){

		//update and cycle
		invoker.syncamount();
		int lastmag=invoker.mags.size()-1;
		if(player.cmd.buttons&BT_USE){
			invoker.mags.insert(0,invoker.mags[lastmag]);
			invoker.mags.pop();
			return;
		}

		//use the existing shield to drop it
		let sss=hdpickup(findinventory("HDMagicShield"));
		if(sss){
			useinventory(sss);
			if(sss)return;
		}

		A_GiveInventory("HDMagicShield");
		sss=hdpickup(findinventory("HDMagicShield"));
		if(sss){
			int togive=invoker.mags[lastmag];
			sss.bstandstill=false;
			sss.bquicktoretaliate=false;
			sss.binvbar=true;
			sss.amount=1;
			sss.maxamount=togive;
			sss.bulk=invoker.magbulk;
			sss.mass=togive-1;
			invoker.mags.pop();
			invoker.amount--;
			if(sss.amount>0)HDMagicShield.FlashSparks(self);
		}
	}
	states{
	spawn:
		BON2 ABCD 1 A_SetTics(random(1,10));
		loop;
	use:
		TNT1 A 0
        {
			// this'll be smarter later as I plan on having it so you can stack shields but not gonna do it now - [ted but stupid]
            if (hd_allowshieldstacking == false) A_UseShield();
            if (hd_allowshieldstacking == true) A_UseShield();
        }
		fail;
	}
}
class SpentShield:HDDebris{
	default{
		scale 0.3;height 3;radius 3;
		bouncesound "misc/fragknock";
	}
	states{
	spawn:
		BON2 E 0;
	spawn2:
		---- A 1{
			A_SetRoll(roll+60,SPF_INTERPOLATE);
		}wait;
	death:
		---- A -1;
		stop;
	}
}
