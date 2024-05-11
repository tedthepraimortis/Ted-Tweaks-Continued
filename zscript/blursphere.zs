//-------------------------------------------------
// Blur Sphere
//-------------------------------------------------
class HDBlurSphere:HDDamageHandler{
	//true +invisible can never be used.
	//shadow will at least cause attacks to happen less often.
	default{
		//$Category "Items/Hideous Destructor/Magic"
		//$Title "Blur Sphere"
		//$Sprite "PINSA0"
		+inventory.invbar
		HDDamageHandler.priority -420;
		HDPickup.overlaypriority -420;
		inventory.pickupmessage "$PICKUP_BLURSPHERE";
		inventory.pickupsound "blursphere/pickup";
		inventory.icon "PINSA0";
		hdpickup.bulk ENC_DERP;
		scale 0.3;
		speed 10;
		tag "$TAG_BLURSPHERE";
	}
	int intensity;
	bool worn;
	override void ownerdied(){
		buntossable=false;
		owner.DropInventory(self);
	}
	states{
	spawn:
		PINS ABCDCB random(1,6);
		PINS A 0 A_CheckSight("see");
		loop;
	see:
		TNT1 AAAAAA 10 A_Wander();
		PINS A 0 A_CheckSight("spawn");
		loop;
	use:
		TNT1 A 0{
			A_AddBlackout(256,72,8,16);
			int lite=cursector.lightlevel;
			if(
				bspawnsoundsource
				||(
					invoker.intensity>0
					&&invoker.intensity<99
				)||lite>random(200,256)
			){
				if(lite>200 && hd_blurspheretextlump == true)
				{

				array<string>msgs;msgs.clear();
					string msg=Wads.ReadLump(Wads.CheckNumForName("blurspheretexts",0));
            		msg.replace("\r", "");
            		msg.split(msgs,"\n");
            		msg=msgs[int(clamp(frandom(0.,1.)*msgs.size(),0,msgs.size()-1))];
					A_Log(msg, true);
				}
				else if (lite>200 && hd_blurspheretextlump == false)
				{
					A_Log(Stringtable.Localize("$BLURSPHERE_ITHURTS"),true);
				}
				else A_Log(Stringtable.Localize("$BLURSPHERE_NOISE"),true);
				if(lite>random(230,300))invoker.amount--;
				return;
			}
			if(!invoker.worn){
				invoker.worn=true;
				A_StartSound("blursphere/use",CHAN_BODY,CHANF_OVERLAP,
					frandom(0.3,0.5),attenuation:8.
				);
			}else{
				invoker.worn=false;
				A_StartSound("blursphere/unuse",CHAN_BODY,CHANF_OVERLAP,frandom(0.3,0.5),attenuation:8.);
			}
		}fail;
	}
	//called from HDPlayerPawn and HDMobBase's DamageMobj
	override int,name,int,double,int,int,int,int HandleDamagePost(
		int damage,
		name mod,
		int flags,
		actor inflictor,
		actor source,
		double towound,
		int toburn,
		int tostun,
		int tobreak,
		int toaggravate
	){
		int badroll=damage*amount-random(0,99);
		if(
			badroll>0
		){
			badroll=max(1,badroll>>4);
			if(
				worn
				&&random(1,255)<damage
			){
				amount-=badroll;
			}else{
				owner.A_DropInventory(getclassname(),badroll);
			}
			if(amount<1){
				destroy();
			}
		}
		if(!self||!owner)return damage,mod,flags,towound,toburn,tostun,tobreak,toaggravate;
		if(
			worn
			&&mod!="internal"
			&&mod!="bleedout"
			&&mod!="maxhpdrain"
			&&mod!="falling"
			&&random(0,owner.cursector.lightlevel)
		)worn=false;
		let hdp=hdplayerpawn(owner);
		if(
			!worn
			&&(
				hdp.incapacitated
				||hdp.stunned>random(0,5*TICRATE)+hdp.cursector.lightlevel
				||(
					mod=="bleedout"
					&&hdp.player
					&&(
						hdp.player.cmd.buttons&BT_SPEED
						||hdp.player.crouchfactor<0.6
					)
					&&random(0,hdp.cursector.lightlevel)<32
				)
			)
		){
			if (hd_blurspheretextlump == true)
			{
            array<string>msgs;msgs.clear();
			string msg=Wads.ReadLump(Wads.CheckNumForName("blurspheretexts",0));
            msg.replace("\r", "");
            msg.split(msgs,"\n");
            msg=msgs[int(clamp(frandom(0.,1.)*msgs.size(),0,msgs.size()-1))];
			hdp.UseInventory(self);
			}
			else
			{
			string msg="";
				switch(random(0,10)){
				case 0:msg=Stringtable.Localize("$BLURSPHERE_ITHURTS");break;
				case 1:msg=Stringtable.Localize("$BLURSPHERE_ANGRY1");break;
				case 2:msg=Stringtable.Localize("$BLURSPHERE_ANGRY2");break;
				case 3:msg=Stringtable.Localize("$BLURSPHERE_ANGRY3");break;
				case 4:msg=Stringtable.Localize("$BLURSPHERE_ANGRY4");break;
				case 5:msg=Stringtable.Localize("$BLURSPHERE_ANGRY5");break;
				case 6:msg=Stringtable.Localize("$BLURSPHERE_HELLO");break;
			}
			if(msg!="")hdp.A_Log(msg,true);
			hdp.UseInventory(self);
			}
		}
		return damage,mod,flags,towound,toburn,tostun,tobreak,toaggravate;
	}
	override void tick(){
		super.tick();
		double frnd=frandom[blur](0.93,1.04);
		scale=(0.3,0.3)*frnd;
		alpha=0.9*frnd;
		if(
			!owner
			||owner.health<1
		)return;
		//there is only one situation where this would be true
		owner.bspecialfiredamage=false;
		int buttons=owner.player?owner.player.cmd.buttons:0;
		int lite=owner.cursector.lightlevel;
		int literand=(
			420
			-lite
		);
		bool lightbad=random(random(0,literand),literand)<amount;
		if(worn){
			bool attacking=
				owner.frame==5 //"F"
				||(
					owner.player
					&&buttons&BT_ATTACK  //only fist has alt be an actual attack
					&&owner.player.readyweapon
					&&!owner.player.readyweapon.bwimpy_weapon
				)
			;
			if(
				attacking
				||lightbad
				||owner.bspawnsoundsource
			){
				intensity=-200;
				worn=false;
				if(
					attacking
					&&random(0,amount>>2+1)
				){
					if(!random(0,7) && hd_blurspheretextlump == true)
					{
					array<string>msgs;msgs.clear();
					string msg=Wads.ReadLump(Wads.CheckNumForName("blurspheretexts",0));
            		msg.replace("\r", "");
            		msg.split(msgs,"\n");
            		msg=msgs[int(clamp(frandom(0.,1.)*msgs.size(),0,msgs.size()-1))];
					owner.A_Log(msg, true);
					}
					else
					{
						owner.A_Log(Stringtable.Localize("$BLURSPHERE_ITHURTS"),true);
					};
					amount--;
					if(amount<1)return;
				}
			}else{
				if(intensity<99)intensity=max(intensity+1,-135);
			}
		}else{
			intensity=max(0,intensity-1);
			if(
				!intensity
				&&lightbad
				&&(
					buttons&(BT_ATTACK|BT_ALTATTACK)
					||!(level.time&(1|2|4|8|16|32))
					||vel dot vel > 50-(amount<<2)
				)
			){
				if(random(0,3))owner.A_Log(Stringtable.Localize("$BLURSPHERE_NO"),true);
				owner.A_DropInventory(getclassname(),random(1,random(1,amount)));
				return;
			}
		}
		bool invi=true;
		if(intensity<random(8,25)){
			owner.a_setrenderstyle(1.,STYLE_Normal);
			invi=false;
		}else{
			//flicker into total invisiblity
			if(
				owner.bshadow
				&&intensity>45
				&&(
					!(buttons&(
						BT_ATTACK
						|BT_ALTATTACK
						|BT_RELOAD
						|BT_UNLOAD
					))
					&&(
						level.time&(1|2|4|8)
						||(owner.vel dot owner.vel < 2.)
					)
				)
			){
				owner.a_setrenderstyle(0.9,STYLE_None);
				owner.bspecialfiredamage=true;
			}else{
				owner.a_setrenderstyle(0.9,STYLE_Fuzzy);
				owner.bspecialfiredamage=(level.time&1);
			}
		}
		//apply result
		owner.bshadow=invi;
		//some feedback
		if(
			lite>=200
			&&!(level.time&(1|2|4|8|16))
			&&!random(0,max(7,(invi?0:1000)-lite))
		){
			if (hd_blurspheretextlump == true)
			{
            array<string>msgs;msgs.clear();
			string msg=Wads.ReadLump(Wads.CheckNumForName("blurspheretexts",0));
            msg.replace("\r", "");
            msg.split(msgs,"\n");
            msg=msgs[int(clamp(frandom(0.,1.)*msgs.size(),0,msgs.size()-1))];
			owner.A_Log(msg,true);
			}
			else
			{
				string msg=Stringtable.Localize("$BLURSPHERE_ITHURTS");
			switch(random(0,10)){
				case 0:msg=Stringtable.Localize("$BLURSPHERE_NOISE");break;
				case 1:msg=Stringtable.Localize("$BLURSPHERE_ANGRY3");break;
				case 2:msg=Stringtable.Localize("$BLURSPHERE_ANGRY5");break;
				case 3:msg=Stringtable.Localize("$BLURSPHERE_ANGRY6");break;
				case 4:msg=Stringtable.Localize("$BLURSPHERE_ANGRY7");break;
			}
			}
			if(random(128,1023)<lite){
				owner.damagemobj(self,owner,1,"hot");
				return;
			}
		}
		//focus redirection powers
		if(
			invi
			&&!(level.time&(1|2|4|8|16))
		){
			flinetracedata blurgaze;
			owner.linetrace(
				owner.angle,4096,owner.pitch,
				offsetz:owner.height*0.9,
				data:blurgaze
			);
			actor aaa=blurgaze.hitactor;
			if(
				aaa
				&&aaa.bismonster
				&&aaa.target==owner
				&&absangle(aaa.angleto(self),aaa.angle)<80
			){
				if(aaa.lastenemy==owner)aaa.lastenemy=null;
				let hdb=hdmobbase(aaa);
				if(hdb){
					vector2 targdir=owner.pos.xy-hdb.pos.xy;
					targdir=angletovector(hdb.angle+frandom(120,240),1024);
					hdb.lasttargetpos.xy=hdb.pos.xy+targdir;
				}else{
					aaa.A_ClearTarget();
				}
			}
		}
	}
	override void DetachFromOwner(){
		owner.bshadow=false;
		owner.bspecialfiredamage=false;
		owner.a_setrenderstyle(1.,STYLE_Normal);
		if(worn){
			worn=false;
			owner.damagemobj(self,owner,random(1,3),"balefire");
		}
		intensity=0;
		owner.A_StartSound("blursphere/drop",CHAN_BODY,volume:frandom(0.3,0.5),attenuation:8.);
		super.detachfromowner();
	}
	override void DisplayOverlay(hdstatusbar sb,hdplayerpawn hpl){
		if(!sb.blurred)return;
		double sclx=(2./1.2);
		double scly=2.;
		name ctex="HDXCAM_BLUR";
		sb.SetSize(0,300,200);
		sb.BeginHUD(forcescaled:true);
		texman.setcameratotexture(hpl,ctex,sb.cplayer.fov*(1.3+0.03*(sin(owner.level.time))));
		bool invis=owner.bspecialfiredamage;
		double camalpha=intensity*(invis?0.01:0.009);
		int ilv=invis?2:5;
		int dif=sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER|sb.DI_ITEM_HCENTER;
		sb.drawimage(
			ctex,(-ilv,0),
			dif,
			alpha:camalpha,
			scale:(sclx,scly)
		);
		camalpha*=0.4;
		sb.drawimage(
			ctex,(ilv,0),
			dif,
			alpha:camalpha*0.6,
			scale:(sclx,scly)
		);
	}
}
//In geometry, a spherical shell is a generalization of an annulus to three dimensions.
class ShellShade:Jackboot{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Shellshade"
		//$Sprite "SPOSA1"
		tag "$TAG_BLURSPHEREZOMBIE";
	}
	override void postbeginplay(){
		super.postbeginplay();
		bshadow=true;
	}
	override void deathdrop(){
		super.deathdrop();
		A_SetRenderStyle(1,STYLE_Normal);
		if(bshadow){
			if(random(0,3))A_DropItem("HDBlurSphere");
			bshadow=false;
		}
	}
	int invisticker;
	override void Tick(){
		super.Tick();
		if(
			isFrozen()
			||!bshadow
		)return;
		if(frame==5)invisticker=8;
		else if(invisticker>0)invisticker--;
		bool invis=!invisticker&&(level.time&(1|2|4));
		if(
			!invisticker
			&&frame<5
			&&(
				abs(vel.x)<2
				&&abs(vel.y)<2
			)
		)invis=true;
		if(invis){
			bspecialfiredamage=true;
			A_SetRenderStyle(0,STYLE_None);
		}else{
			bspecialfiredamage=false;
			A_SetRenderStyle(1,STYLE_Fuzzy);
		}
	}
}
