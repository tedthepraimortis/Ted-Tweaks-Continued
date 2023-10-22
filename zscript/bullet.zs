// ------------------------------------------------------------
// The Bullet!
// ------------------------------------------------------------
class bltest:HDCheatWep{
	default{
		weapon.slotnumber 1;
		hdweapon.refid "blt";
		tag "bullet sampler (cheat!)";
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc
	){
		double dotoff=max(abs(bob.x),abs(bob.y));
		if(dotoff<10){
			sb.drawimage(
				"rret3",(0,0)+bob*3,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				alpha:0.8-dotoff*0.04,scale:(0.8,0.8)
			);
		}
		sb.drawimage(
			"xh25",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
			scale:(1.6,1.6)
		);
		int airburst=hdw.airburst;
		if(airburst)sb.drawnum(airburst,
			10+bob.x,9+bob.y,sb.DI_SCREEN_CENTER,Font.CR_BLACK
		);
	}
	states{
	fire:
		TNT1 A 0{
			if(player.cmd.buttons&BT_USE)HDBulletActor.FireBullet(self,"HDB_bronto");
			else HDBulletActor.FireBullet(self,"HDB_776");
		}goto nope;
	altfire:
		TNT1 A 0{
			HDBulletActor.FireBullet(self,"HDB_776r");
		}goto nope;
	reload:
		TNT1 A 0{
			HDBulletActor.FireBullet(self,"HDB_426");
		}goto nope;
	user2:
		TNT1 A 0{
			HDBulletActor.FireBullet(self,"HDB_50");
//			HDBulletActor.FireBullet(self,"HDB_00",spread:6,amount:7);
		}goto nope;
	}
}
class HDB_50:HDBulletActor{
	default{
		pushfactor 0.4;
		mass 420;
		speed HDCONST_MPSTODUPT*920;
		accuracy 666;
		stamina 1270;
		woundhealth 10;
		hdbulletactor.hardness 3;
		hdbulletactor.distantsound "world/riflefar";
		hdbulletactor.distantsoundvol 3.;
	}
}
class HDB_426:HDBulletActor{
	default{
		pushfactor 0.4;
		mass 32;
		speed HDCONST_MPSTODUPT*990;
		accuracy 666;
		stamina 426;
		woundhealth 40;
		hdbulletactor.hardness 2;
		hdbulletactor.distantsound "world/riflefar";
	}
}
class HDB_776:HDBulletActor{
	default{
		pushfactor 0.1;
		mass 120;
		speed HDCONST_MPSTODUPT*920;
		accuracy 600;
		stamina 776;
		woundhealth 5;
		hdbulletactor.hardness 4;
		hdbulletactor.distantsound "world/riflefar";
		hdbulletactor.distantsoundvol 2.;
	}
}
class HDB_776r:HDB_776{
	default{
		pushfactor 0.16;
		mass 150;
		speed HDCONST_MPSTODUPT*820;
		accuracy 300;
		woundhealth 4;
		hdbulletactor.hardness 1;
	}
}
class HDB_9:HDBulletActor{
	default{
		pushfactor 0.4;
		mass 80;
		speed HDCONST_MPSTODUPT*350;
		accuracy 300;
		stamina 900;
		woundhealth 10;
		hdbulletactor.hardness 3;
	}
}
class HDB_355:HDBulletActor{
	default{
		pushfactor 0.3;
		mass 99;
		speed HDCONST_MPSTODUPT*355;
		accuracy 355;
		stamina 902;
		woundhealth 15;
		hdbulletactor.hardness 3;
	}
}
class HDB_00:HDBulletActor{
	default{
		pushfactor 0.3;
		mass 25;
		speed HDCONST_MPSTODUPT*500;
		accuracy 200;
		stamina 838;
		woundhealth 3;
		hdbulletactor.hardness 5;
	}
}
class HDB_wad:HDBulletActor{
	default{
		pushfactor 10.;
		mass 12;
		speed HDCONST_MPSTODUPT*200; //presumably most energy is transferred to the shot
		accuracy 0;
		stamina 1900;
		woundhealth 5;
		hdbulletactor.hardness 0; //should we change this to a double...
		translation "AllRed";
	}
	override void gunsmoke(){}
}
class HDB_frag:HDBulletActor{
	default{
		pushfactor 0.7;
		mass 1;
		speed HDCONST_MPSTODUPT*900;
		accuracy 400;
		stamina 300;
		woundhealth 6;
		deathheight 0.2;  //minimum speed factor
		burnheight 0.5;	 //minimum scale factor
		projectilepassheight 3.;  //maximum scale factor
	}
	override void gunsmoke(){}
	override void resetrandoms(){
		double scalefactor=frandom(burnheight,projectilepassheight);
		double pfm=default.pushfactor/scalefactor;
		mass=max(1,int(default.mass*pfm));
		speed=max(1,default.speed*frandom(deathheight,1.));
		accuracy=max(1,int(default.accuracy*frandom(0.3,1.7)));
		stamina=max(1,int(default.stamina*pfm));
		pushfactor=pfm;
	}
}
class HDB_fragRL:HDB_frag{default{pushfactor 1.3;burnheight 0.6;projectilepassheight 5.;}}
class HDB_scrap:HDB_frag{
	default{
		pushfactor 5.;
		mass 30;
		speed HDCONST_MPSTODUPT*140;
		accuracy 100;
		stamina 800;
		woundhealth 20;
		deathheight 0.05;
		burnheight 0.1;
		projectilepassheight 10;
	}
	states{
	spawn:
		DUST A 0;
		---- A 0{
			brollsprite=true;
			roll=frandom(0,360);
			frame=random(0,3);
			scale.x*=randompick(-1,1);
			scale*=frandom(0.1,0.3);
		}
		---- A 1{roll+=20;}
		wait;
		DUST BCD 0;
		stop;
	}
}
class HDB_scrapDB:HDB_scrap{default{burnheight 0.1; projectilepassheight 8.;}}
class HDB_fragBronto:HDB_scrap{default{speed 300; burnheight 0.8; projectilepassheight 4.;}}
class HDB_bronto:HDBulletActor{
	default{
		pushfactor 0.05;
		mass 5000;
		speed HDCONST_MPSTODUPT*420;
		accuracy 600;
		stamina 3700;

		hdbulletactor.distantsound "world/shotgunfar";
		hdbulletactor.distantsoundvol 2.;
		missiletype "HDGunsmoke";
		scale 0.08;translation "128:151=%[1,1,1]:[0.2,0.2,0.2]";
		seesound "weapons/riflecrack";
		obituary "%o played %k's cannon.";
	}
	override double penetration(){
		//The main penetration code doesn't factor in diminishing returns from
		//friction caused by larger projectiles moving through more material.
		//Since only the Brontornis shell is anywhere near big enough
		//for this to make a real difference, it gets its own formula.
		double pen=
			speed
			/(
				(HDCONST_MPSTODUPT*420.*20./40.)  //the *20 assumes base pushfactor 0.05
				*pushfactor
			)
		;
		if(hd_debug>1)console.printf(getclassname().." penetration:  "..pen.."   "..realpos.x..","..realpos.y);
		return pen;
	}
	override actor Puff(){
		vector3 vu=(-cos(pitch)*(cos(angle),sin(angle)),sin(pitch));
		vector3 pv=pos+vu;

		for(int i=0;i<20;i++){
			let bbb=spawn("HugeWallChunk",pv+(frandom(-1,1),frandom(-1,1),frandom(-1,1)));
			bbb.vel=(frandom(-4,4),frandom(-4,4),frandom(-1,4))+vu;
			bbb.scale*=frandom(0.3,1.2);
		}
		let ppp=super.puff();
		if(ppp){
			ppp.A_StartSound("misc/bigbulhol",CHAN_BODY,CHANF_OVERLAP);
		}
		return ppp;
	}
	override void Detonate(){
		if(max(abs(pos.x),abs(pos.y))>=32768)return;

		vector2 facingpoint=(cos(angle),sin(angle));
		setorigin(pos-(2*facingpoint,0),false);

		A_SprayDecal("BrontoScorch",16);
		if(vel==(0,0,0))A_ChangeVelocity(cos(pitch),0,-sin(pitch),CVF_RELATIVE|CVF_REPLACE);
		else vel*=0.01;
		if(tracer){ //warhead damage
			int dmg=random(1600,2000);

			//find the point at which it would pierce the middle
			vector3 hitpoint=pos+vel.unit()*tracer.radius;

			//find the "heart" point on the victim
			vector3 tracmid=(tracer.pos.xy,tracer.pos.z+tracer.height*0.618);

			dmg=int((1.-((hitpoint-tracmid).length()/tracer.radius))*dmg);
			tracer.damagemobj(
				self,target,
				dmg,
				"Piercing",DMG_THRUSTLESS
			);
		}
		doordestroyer.destroydoor(self,128,frandom(24,36),6,dedicated:true);
		A_HDBlast(
			fragradius:256,fragtype:"HDB_fragBronto",
			immolateradius:64,immolateamount:random(4,20),immolatechance:32,
			source:target
		);
		DistantQuaker.Quake(self,3,35,256,12);
		actor aaa=Spawn("WallChunker",pos,ALLOW_REPLACE);
		A_SpawnChunks("BigWallChunk",20,4,20);
		A_SpawnChunks("HDSmoke",4,1,7);
		aaa=spawn("HDExplosion",pos,ALLOW_REPLACE);aaa.vel.z=2;
		distantnoise.make(aaa,"world/rocketfar");
		A_SpawnChunks("HDSmokeChunk",random(3,4),6,12);
		HDMobAI.HDNoiseAlert(target,self);

		bmissile=false;
		bnointeraction=true;
		vel=(0,0,0);
		if(!instatesequence(curstate,findstate("death")))setstatelabel("death");
	}
	override name GetBulletDecal(
		double bulletspeed,
		line hitline,
		int hitpart,
		bool exithole
	){return "BulletChipGiant";}
	override void postbeginplay(){
		super.postbeginplay();
		for(int i=2;i;i--){
			A_SpawnItemEx("TerrorSabotPiece",0,0,0,
				speed*cos(pitch)*0.01,(i==2?3:-3),speed*sin(pitch)*0.01,0,
				SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
			);
		}
	}
}



class HDBulletTracer:LineTracer{
	hdbulletactor bullet;
	actor shooter;
	override etracestatus tracecallback(){
		if(
			results.hittype==TRACE_HitFloor
			||results.hittype==TRACE_HitCeiling
		){
			int skipsize=bullet.tracesectors.size();
			for(int i=0;i<skipsize;i++){
				if(bullet.tracesectors[i]==results.hitsector)return TRACE_Skip;
			}
		}else if(results.hittype==TRACE_HitActor){
			if(
				results.hitactor==bullet
				||(results.hitactor==shooter&&!bullet.bincombat)
			)return TRACE_Skip;
			int skipsize=bullet.traceactors.size();
			for(int i=0;i<skipsize;i++){
				if(
					bullet.traceactors[i]==results.hitactor
					||(
						results.hitactor is "TempShield"
						&&bullet.traceactors[i]==results.hitactor.master
					)
				)return TRACE_Skip;
			}
		}else if(results.hittype==TRACE_HitWall){
			int skipsize=bullet.tracelines.size();
			for(int i=0;i<skipsize;i++){
				if(bullet.tracelines[i]==results.hitline)return TRACE_Skip;
			}
		}
		return TRACE_Stop;
	}
}
class HDBulletActor:HDActor{
	array<line> tracelines;
	array<actor> traceactors;
	array<sector> tracesectors;

	vector3 realpos;

	int hdbulletflags;
	flagdef neverricochet:hdbulletflags,0;

	int hardness;
	property hardness:hardness;

	sound distantsound;
	property distantsound:distantsound;
	double distantsoundvol;
	property distantsoundvol:distantsoundvol;
	double distantsoundpitch;
	property distantsoundpitch:distantsoundpitch;

	enum BulletConsts{
		BULLET_CRACKINTERVAL=64,

		BLT_HITTOP=1,
		BLT_HITBOTTOM=2,
		BLT_HITMIDDLE=3,
		BLT_HITONESIDED=4,
	}
	const BULLET_TERMINALVELOCITY=-HDCONST_MPSTODUPT*100;


	default{
		+noblockmap
		+missile
		+noextremedeath
		+cannotpush
		+dontreflect
		+stoprails
		height 0.1;radius 0.1;
		/*
			speed: 200-1000
			mass: in tenths of a gram
			pushfactor: 0.05-5.0 - imagine it being horizontal speed blowing in the wind
			accuracy: 0,200,200-700 - angle of outline from perpendicular, round deemed to be 200
			stamina: 900, 776, 426, you get the idea
			hardness: 1-5 - 1=pure lead, 5=steel (NOTE: this setting's bullets are (Teflon-coated) steel by default; will implement lead casts "later")
		*/
		hdbulletactor.distantsound "";
		hdbulletactor.distantsoundvol 1.;
		hdbulletactor.distantsoundpitch 1.;
		hdbulletactor.hardness 5;
		pushfactor 0.05;
		mass 160;
		speed 1100;
		accuracy 600;
		stamina 776;
	}
	virtual void resetrandoms(){}
	virtual void gunsmoke(){
		actor gs;
		double j=cos(pitch);
		vector3 vk=(j*cos(angle),j*sin(angle),-sin(pitch));
		j=clamp(speed*max(mass,1)*0.00002,0,5);
		if(frandom(0,1)>j)return;
		for(int i=0;i<j;i++){
			gs=spawn("HDGunSmoke",pos+i*vk,ALLOW_REPLACE);
			gs.pitch=pitch;gs.angle=angle;gs.vel=vk*j;
		}
	}
	virtual name GetBulletDecal(
		double bulletspeed,
		line hitline,
		int hitpart,
		bool exithole
	){
		return bulletspeed>(exithole?400:600)?"BulletChip":"BulletChipSmall";
	}
	override void postbeginplay(){
		resetrandoms();
		super.postbeginplay();
		realpos=pos;
		gunsmoke();
		if(distantsound!="")distantnoise.make(self,distantsound,distantsoundvol,distantsoundpitch);
		scalebullet();
	}
	void scalebullet(){
		if(hd_debug){
			scale=(1.,1.);
			sprite=getspriteindex("BAL1A0");
		}else{
			double scaleamt=(HDCONST_ONEMETRE*0.000005)*stamina;
			scale=(scaleamt,scaleamt);
		}
	}
	virtual double penetration(){ //still juvenile giggling
		double pen=
			(25+hardness)
			*(8000+accuracy)
			*(30+mass)
			*(4000+speed)
			*0.00000021
		;

		double pendenom=200+stamina;

		if(pushfactor>0){
			double pushed=1.+pushfactor;
			pendenom*=pushed*pushed;
		}
		if(pendenom)pen/=pendenom;

		if(hd_debug>1)console.printf(getclassname().." penetration:  "..pen.."   "..realpos.x..","..realpos.y);
		return pen;
	}
	double DecelerationFactor(){return clamp(1.-pushfactor*0.001,0.001,1.);}
	void ApplyDeceleration(){
		double fac=DecelerationFactor();
		vel.xy*=fac;
		if(vel.z>0)vel.z*=fac;
	}
	void ApplyGravity(){
		if(vel.z>BULLET_TERMINALVELOCITY)vel.z-=max(0.001,getgravity());
	}
	static HDBulletActor FireBullet(
		actor caller,
		class<HDBulletActor> type="HDBulletActor",
		double zofs=999, //999=use default
		double xyofs=0,
		double spread=0, //range of random velocity added
		double aimoffx=0,
		double aimoffy=0,
		double speedfactor=0,
		int amount=1,
		sound distantsound="",
		double distantsoundvol=1.,
		double distantsoundpitch=1.
	){
		vector3 ofs=HDMath.GetGunPos(caller);
		if(zofs!=999)ofs.z=zofs;
		HDBulletActor bbb=null;
		do{
			amount--;
			vector3 spawnpos=caller.pos+ofs;
			bbb=HDBulletActor(spawn(type,spawnpos,ALLOW_REPLACE));
			if(bbb.distantsound==""){
				bbb.distantsound=distantsound;
				bbb.distantsoundvol=distantsoundvol;
				bbb.distantsoundpitch=distantsoundpitch;
			}
			if(distantsound!="")distantnoise.make(caller,distantsound,distantsoundvol);
			if(xyofs)bbb.setorigin(bbb.pos+(sin(caller.angle)*xyofs,cos(caller.angle)*xyofs,0),false);

			if(speedfactor>0)bbb.speed*=speedfactor;
			else if(speedfactor<0)bbb.speed=-speedfactor;

			bbb.target=caller;

			if(hdplayerpawn(caller)){
				let hdp=hdplayerpawn(caller);
				bbb.angle=hdp.gunangle;
				bbb.pitch=hdp.gunpitch;

				//pretend all guns are zeroed to hit point of aim at 1 tic
//				bbb.pitch-=atan2(1.5,bbb.default.speed);
			}else{
				bbb.angle+=caller.angle;
				bbb.pitch+=caller.pitch;
			}
			if(aimoffx)bbb.angle+=aimoffx;
			if(aimoffy)bbb.pitch+=aimoffy;

			bbb.vel=caller.vel;
			double forward=bbb.speed*cos(bbb.pitch);
			double side=0;
			double updown=bbb.speed*sin(-bbb.pitch);
			if(spread){
				forward+=frandom(-spread,spread);
				side+=frandom(-spread,spread);
				updown+=frandom(-spread,spread);
			}
			bbb.A_ChangeVelocity(forward,side,updown,CVF_RELATIVE);
		}while(amount>0);
		return bbb;
	}
	states{
	spawn:
		BLET A -1;
		stop;
	death:
		TNT1 A 1;
		stop;
	}
	override void tick(){
		if(isfrozen())return;

		//if(getage()%17)return;  //debug line for when i_timescale isn't appropriate

		if(abs(realpos.x)>32000||abs(realpos.y)>32000){destroy();return;}
		if(
			!bmissile
		){
			bnoteleport=false;
			super.tick();
			return;
		}

		//I COULD put in the work to check for teleportation
		//but it would be a nightmare (bad) for gameplay purposes,
		//and super-slow bullets that can teleport are not really something that actually happens.
		if(!bnoteleport)bnoteleport=true;

		//update position but keep within the sector
		if(
			realpos.xy!=pos.xy
		)setorigin((
			realpos.xy,
			clamp(
				realpos.z,
				getzat(realpos.x,realpos.y,flags:GZF_ABSOLUTEPOS),
				getzat(realpos.x,realpos.y,flags:GZF_ABSOLUTEPOS|GZF_CEILING)-height
			)
		),true);

		tracelines.clear();
		traceactors.clear();
		tracesectors.clear();

		//if in the sky
		if(
			ceilingz<realpos.z
			&&ceilingz-realpos.z<vel.z
		){
			if(
				!(level.time&(1|2|4|8|16|32|64|128))
				&&(vel.xy dot vel.xy < 64.)
				&&!level.ispointinlevel(pos)
			){
				destroy();
				return;
			}
//			bnointeraction=true;
			binvisible=true;
			realpos+=vel;
			ApplyDeceleration();
			ApplyGravity();
			return;
		}
		if(binvisible){
//			bnointeraction=false;
			binvisible=false;
		}

		if(vel==(0,0,0)){
			vel.z-=max(0.01,getgravity()*0.01);
			return;
		}

		hdbullettracer blt=HDBulletTracer(new("HDBulletTracer"));
		if(!blt)return;
		blt.bullet=hdbulletactor(self);
		blt.shooter=target;
		vector3 oldpos=realpos;
		vector3 newpos=oldpos;

		//get speed, set counter
		bool doneone=false;
		double distanceleft=vel.length();
		double curspeed=distanceleft;
		do{
			A_FaceMovementDirection();
			tracer=null;

			//update distanceleft if speed changed
			if(curspeed>speed){
				distanceleft-=(curspeed-speed);
				curspeed=speed;
			}

			double cosp=cos(pitch);
			vector3 vu=vel.unit();
			blt.trace(
				realpos,
				cursector,
				vu,
				distanceleft,
				TRACE_HitSky
			);
			traceresults bres=blt.results;
			sector sectortodamage=null;


			//check distance until clear of target
			if(
				!bincombat
				&&(
					!target||
					bres.distance>target.height
				)
			){
				bincombat=true;
			}


			if(bres.hittype==TRACE_HasHitSky){
				realpos+=vel;
				ApplyDeceleration();
				ApplyGravity();
				newpos=bres.hitpos; //used to spawn crackers later
			}else if(bres.hittype==TRACE_HitNone){
				newpos=bres.hitpos;
				realpos=newpos;
				distanceleft-=max(bres.distance,10.); //safeguard against infinite loops
			}else{
				newpos=bres.hitpos-vu*0.1;
				realpos=newpos;
				distanceleft-=max(bres.distance,10.); //safeguard against infinite loops
				if(bres.hittype==TRACE_HitWall){
					setorigin(realpos,true);  //needed for bulletdie and checkmove

					let hitline=bres.hitline;
					tracelines.push(hitline);

					//get the sector on the opposite side of the impact
					sector othersector;
					if(bres.hitsector==hitline.frontsector)othersector=hitline.backsector;
					else othersector=hitline.frontsector;

					//check if the line is even blocking the bullet
					bool isblocking=(
						!(hitline.flags&line.ML_TWOSIDED) //one-sided
						||(
							//these barriers are not even paper thin
							hitline.flags&(
								line.ML_BLOCKHITSCAN
								|line.ML_BLOCKPROJECTILE
								|line.ML_BLOCKEVERYTHING
							)
						)
						//||bres.tier==TIER_FFloor //3d floor - does not work as of 4.2.0
						||hitline.gethealth()>0
						||( //upper or lower tier, not sky
							(
								(bres.tier==TIER_Upper)
								&&(othersector.gettexture(othersector.ceiling)!=skyflatnum)
							)||(
								(bres.tier==TIER_Lower)
								&&(othersector.gettexture(othersector.floor)!=skyflatnum)
							)
						)
						||!checkmove(bres.hitpos.xy+vu.xy*0.4) //if in any event it won't fit
					);

					// crossing or hitting impact activation line
					let activator = level.missilesActivateImpact? Actor(self) : target;
					hitline.activate(activator,bres.side,SPAC_Impact);

					//if not blocking, pass through and continue
					if(
						!isblocking
						||hitline.special==Line_Horizon
					){
						// crossing projectile line
						hitline.activate(activator,bres.side,SPAC_PCross);

						realpos.xy+=vu.xy*0.2;
						setorigin(realpos,true);
					}else{
						//SPAC_Damage is already handled by the native geometry damage code called in HitGeometry
						HitGeometry(
							hitline,othersector,bres.side,999+bres.tier,vu,
							doneone?bres.distance:999
						);
						if(!self)return;
					}
				}else if(
					bres.hittype==TRACE_HitFloor
					||bres.hittype==TRACE_HitCeiling
				){
					sector hitsector=bres.hitsector;
					tracesectors.push(hitsector);

					setorigin(realpos,true);
					if(
						(
							bres.hittype==TRACE_HitCeiling
							&&(
								hitsector.gettexture(hitsector.ceiling)==skyflatnum
								||ceilingz>pos.z+0.1
							)
						)||(
							bres.hittype==TRACE_HitFloor
							&&(
								hitsector.gettexture(hitsector.floor)==skyflatnum
								||floorz<pos.z-0.1
							)
						)
					)continue;

					HitGeometry(
						null,hitsector,0,
						bres.hittype==TRACE_HitCeiling?SECPART_Ceiling:SECPART_Floor,
						vu,doneone?bres.distance:999
					);
					if(!self)return;
				}else if(bres.hittype==TRACE_HitActor){
					setorigin(realpos,true);
					if(
						bincombat
						||bres.hitactor!=target
					){
						traceactors.push(bres.hitactor);
						onhitactor(bres.hitactor,bres.hitpos,vu);
						if(!self)return;
					}
				}
			}
			doneone=true;


			//find points close to players and spawn crackers
			//also spawn trails if applicable
			if(speed>256){
				vector3 crackpos=newpos;
				vector3 crackinterval=vu*BULLET_CRACKINTERVAL;
				int j=int(max(1,bres.distance*(1./BULLET_CRACKINTERVAL)));
				for(int i=0;i<j;i++){
					crackpos-=crackinterval;
					if(hd_debug>1)A_SpawnParticle("yellow",SPF_RELVEL|SPF_RELANG,
						size:12,
						xoff:crackpos.x-pos.x,
						yoff:crackpos.y-pos.y,
						zoff:crackpos.z-pos.z,
						velx:speed*cos(pitch)*0.001,
						velz:-speed*sin(pitch)*0.001
					);
					if(missilename)spawn(missilename,crackpos,ALLOW_REPLACE);
					bool gotplayer=false;

					bool supersonic=speed>HDCONST_SPEEDOFSOUND;
					double crackvol=(speed*10+(pushfactor*mass))*0.00004;
					double fwooshvol=crackvol*0.32;
					double crackpitch=clamp(speed*0.001,0.9,1.5);

					for(int k=0;!gotplayer && k<MAXPLAYERS;k++){
						if(playeringame[k] && players[k].mo){
							vector3 vvv=players[k].mo.pos-crackpos;  //vec3offset is wrong; portals don't work
							if(
								(vvv dot vvv)<(512*512)
							){
								gotplayer=true;
								actor ccc=spawn("BulletSoundTrail",crackpos,ALLOW_REPLACE);
								double thisvol=crackvol;
								do{
									if(supersonic)ccc.A_StartSound("weapons/bulletcrack",
										CHAN_BODY,CHANF_OVERLAP,volume:clamp(thisvol,0,1),
										attenuation:ATTN_STATIC,pitch:crackpitch
									);
									else ccc.A_StartSound("weapons/subfwoosh",
										CHAN_BODY,CHANF_OVERLAP,volume:clamp(fwooshvol,0,1),
										attenuation:ATTN_STATIC,pitch:crackpitch
									);
									if(thisvol>1)thisvol-=1;
								}while(thisvol>1);
							}
						}
					}
				}
			}
		}while(
			bmissile
			&&distanceleft>0
		);

		//destroy the linetracer just in case it interferes with savegames
		blt.destroy();

		//update velocity
		double pf=min(pushfactor,speed*0.1);
		vel+=(
			frandom(-pf,pf),
			frandom(-pf,pf),
			frandom(-pf,pf)
		);
		//reduce momentum
		ApplyDeceleration();
		ApplyGravity();

		//sometimes bullets will freeze (or at least move imperceptibly slowly)
		//and not react to gravity or anything until touched.
		//i've never been able to isolate the cause of this.
		//this forces a bullet to die if its net movement is less than 1 in all cardinal directions.
		//(note: if a bullet is shot straight up and hangs perfectly still for a tick,
		//it's almost certainly "in the sky" and the below code would not be executed.
		//also consider grav acceleration: 32 speed straight up from height 0: +32+30+27+23+18+12+5-3..)
		if(
			abs(oldpos.x-realpos.x)<1
			&&abs(oldpos.y-realpos.y)<1
			&&abs(oldpos.z-realpos.z)<1
		)bulletdie();

		if(tics>=0)nexttic();
	}
	//set to full stop, unflag as missile, death state
	void bulletdie(){
		vel=(0,0,0);
		bmissile=false;
		setstatelabel("death");
	}
	//when a bullet hits a flat or wall
	//add 999 to "hitpart" to use the tier # instead
	virtual void HitGeometry(
		line hitline,
		sector hitsector,
		int hitside,
		int hitpart,
		vector3 vu,
		double lastdist
	){
		double pen=penetration();
		//TODO: MATERIALS AFFECTING PENETRATION AMOUNT
		//(take these fancy todos with a grain of salt - we may be reaching computational limits)

		setorigin(pos-vu,false);
		if(pen>1)A_SprayDecal(GetBulletDecal(speed,hitline,hitpart,false),4);
		setorigin(pos+vu,false);

		//inflict damage on destructibles
		//GZDoom native first
		int geodmg=int(pen*(1+pushfactor));
		if(hitsector){
			switch(hitpart-999){
			case TIER_Upper:
				hitpart=SECPART_Ceiling;
				break;
			case TIER_Lower:
				hitpart=SECPART_Floor;
				break;
			case TIER_FFloor:
				hitpart=SECPART_3D;
				break;
			default:
				if(hitpart>=999)hitpart=SECPART_Floor;
				break;
			}
			destructible.DamageSector(hitsector,self,geodmg,"piercing",hitpart,pos,false);
		}

		//then windowbuster
		bool dodestroydoor=true;
		if(hitline)destructible.DamageLinedef(hitline,self,geodmg,"piercing",hitpart,pos,false);

		//then doorbuster
		if(dodestroydoor){
			double hlalpha=hitline?hitline.alpha:1.;
			bool ddd=doordestroyer.destroydoor(self,0.01*pen*stamina,frandom(stamina*0.0006,pen*0.00005*stamina),1);

			//windows absorb a lot of energy
			if(
				ddd
				||(
					hitline
					&&hitline.alpha>hlalpha
				)
			){
				double glassmult=min(1.,frandom(0.003,0.006)*mass);
				pen*=glassmult;
				vel*=glassmult;
			}
		}


		puff();


		//in case the puff() detonated or destroyed the bullet
		if(!self||!bmissile)return;


		//everything below this should be ricochet or penetration
		if(pen<1.){
			detonate();
			bulletdie();
			return;
		}


		//see if the bullet ricochets
		bool didricochet=false;
		//TODO: don't ricochet on meat, require much shallower angle for liquids

		//if impact is too steep, randomly fail to ricochet
		double maxricangle=frandom(50,90)-pen-hardness;

		if(hitline){
			//angle of line
			//above plus 180, normalized
			//pick the one closer to the bullet's own angle

			//deflect along the line
			if(lastdist>128){ //to avoid infinite back-and-forth at certain angles
				double aaa1=hdmath.angleto(hitline.v1.p,hitline.v2.p);
				double aaa2=aaa1+180;
				double ppp=angle;

				double abs1=absangle(aaa1,ppp);
				double abs2=absangle(aaa2,ppp);
				double hitangle=min(abs1,abs2);

				if(hitangle<maxricangle){
					didricochet=true;
					double aaa=(abs1>abs2)?aaa2:aaa1;
					vel.xy=rotatevector(vel.xy,deltaangle(ppp,aaa)*frandom(1.,1.05));

					//transfer some of the deflection upwards or downwards
					double vlz=vel.z;
					if(vlz){
						double xyl=vel.xy.length()*frandom(0.9,1.1);
						double xyvlz=xyl+vlz;
						vel.z*=xyvlz/xyl;
						vel.xy*=xyl/xyvlz;
					}
					vel.z+=frandom(-0.01,0.01)*speed;
					vel*=1.-hitangle*0.011;
				}
			}
		}else if(
			hitpart==SECPART_Floor
			||hitpart==SECPART_Ceiling
		){
			bool isceiling=hitpart==SECPART_CEILING;
			double planepitch=0;

			//get the relative pitch of the surface
			if(lastdist>128){ //to avoid infinite back-and-forth at certain angles
				double zdif;
				if(checkmove(pos.xy+vel.xy.unit()*0.5))zdif=getzat(0.5,flags:isceiling?GZF_CEILING:0)-pos.z;
				else zdif=pos.z-getzat(-0.5,flags:isceiling?GZF_CEILING:0);
				if(zdif)planepitch=atan2(zdif,0.5);

				planepitch+=frandom(0.,1.);
				if(isceiling)planepitch*=-1;

				double hitangle=absangle(-pitch,planepitch);
				if(hitangle>90)hitangle=180-hitangle;

				if(hitangle<maxricangle){
					didricochet=true;
					//at certain angles the ricochet should reverse xy direction
					if(hitangle>90){
						//bullet ricochets "backward"
						pitch=planepitch;
						angle+=180;
					}else{
						//bullet ricochets "forward"
						pitch=-planepitch;
					}
					speed*=(1-frandom(0.,0.02)*(7-hardness)-(hitangle*0.003));
					A_ChangeVelocity(cos(pitch)*speed,0,sin(-pitch)*speed,CVF_RELATIVE|CVF_REPLACE);
					vel*=1.-hitangle*0.011;
				}
			}
		}

		//see if the bullet penetrates
		if(!didricochet){
			//calculate the penetration distance
			//if that point is in the map:
			vector3 pendest=pos;
			bool dopenetrate=false; //"dope netrate". sounds pleasantly fast.
			int penunits=0;
			for(int i=0;i<pen;i++){
				pendest+=vu;
				if(
					level.ispointinlevel(pendest)
					//performance???
					//&&pendest.z>getzat(pendest.x,pendest.y,0,GZF_ABSOLUTEPOS)
					//&&pendest.z<getzat(pendest.x,pendest.y,0,GZF_CEILING|GZF_ABSOLUTEPOS)
				){
					dopenetrate=true;
					penunits=i;
					break;
				}
			}
			if(dopenetrate){
				//warp forwards to that distance
				setorigin(pendest,true);
				realpos=pendest;

				//do a REGULAR ACTOR linetrace
				angle-=180;pitch=-pitch;
				flinetracedata penlt;
				LineTrace(
					angle,
					pen+1,
					pitch,
					flags:TRF_THRUACTORS|TRF_ABSOFFSET,
					data:penlt
				);

				//move to emergence point and spray a decal
				setorigin(pendest+vu*0.3,true);
				puff();
				A_SprayDecal(GetBulletDecal(speed,hitline,hitpart,true));
				angle+=180;pitch=-pitch;

				if(penlt.hittype==TRACE_HitActor){
					//if it hits an actor, affect that actor
					onhitactor(penlt.hitactor,penlt.hitlocation,vu);
					if(penlt.hitactor)traceactors.push(penlt.hitactor);
				}

				//reduce momentum, increase tumbling, etc.
				angle+=frandom(-pushfactor,pushfactor)*penunits;
				pitch+=frandom(-pushfactor,pushfactor)*penunits;
				speed=max(0,speed-frandom(-pushfactor,pushfactor)*penunits*10);
				A_ChangeVelocity(cos(pitch)*speed,0,-sin(pitch)*speed,CVF_RELATIVE|CVF_REPLACE);
			}else{
				detonate();
				bulletdie();
				return;
			}
		}

		//update realpos to keep these values in sync
		realpos=pos;

		//warp the bullet
		hardness=max(1,hardness-random(0,random(0,3)));
		stamina=max(1,stamina+random(0,(stamina>>1)));
		scalebullet();
	}

	enum HitActorFlags{
		BLAF_DONTFRAGMENT=1,

		BLAF_ALLTHEWAYTHROUGH=2,
		BLAF_SUCKINGWOUND=4,
	}
	virtual void onhitactor(actor hitactor,vector3 hitpos,vector3 vu,int flags=0){
		if(
			!hitactor.bshootable
			||hitactor.bnonshootable
		)return;
		tracer=hitactor;
		double hitangle=absangle(angle,angleto(hitactor)); //0 is dead centre
		double pen=penetration();

		let hdaa=hdactor(hitactor);
		let hdmb=hdmobbase(hitactor);
		let hdp=hdplayerpawn(hitactor);

		//because radius alone is not correct
		double deemedwidth=hitactor.radius*frandom(1.8,2.);


		//checks for standing character with gaps between feet and next to head
		if(
			abs(pitch)<70&&
			(
				(
					hdmb
					&&hitactor.height>hdmb.liveheight*0.7
				)||hitactor.height>hitactor.default.height*0.7
			)
		){
			//pass over shoulder
			//intended to be somewhat bigger than the visible head on any sprite
			if(
				(
					hdp
					||(
						hdmb&&hdmb.bsmallhead
					)
				)&&(
					0.8<
					min(
						pos.z-hitactor.pos.z,
						pos.z+vu.z*hitactor.radius*0.6-hitactor.pos.z
					)/hitactor.height
				)
			){
				if(hitangle>30.)return;
				deemedwidth*=0.6;
			}
			//randomly pass through putative gap between legs and feet
			if(
				(
					hdp
					||(
						hdmb
						&&hdmb.bbiped
					)
				)
			){
				double aat=angleto(hitactor);
				double haa=hitactor.angle;
				aat=min(absangle(aat,haa),absangle(aat,haa+180));

				haa=max(
					pos.z-hitactor.pos.z,
					pos.z+vu.z*hitactor.radius-hitactor.pos.z
				)/hitactor.height;

				//do the rest only if the shot is low enough
				if(haa<0.35){
					//if directly in front or behind, assume the space exists
					if(aat<7.){
						if(hitangle<7.)return;
					}else{
						//if not directly in front, increase space as you go down
						//this isn't actually intended to reflect any particular sprite
						int whichtick=level.time&(1|2); //0,1,2,3
						if(hitangle<4.+whichtick*(1.-haa))return;
					}
				}
			}
		}



		//determine bullet resistance
		double penshell;
		if(hdaa)penshell=max(hdaa.bulletresistance(hitangle),hdaa.bulletshell(hitpos,hitangle));
		else penshell=0.6;

		bool hitactoristall=hitactor.height>hitactor.radius*2;


		//process all items (e.g. armour) that may affect the bullet
		array<HDDamageHandler> handlers;
		HDDamageHandler.GetHandlers(hitactor,handlers); 
		for(int i = 0; i < handlers.Size(); i++){
			[pen,penshell]=handlers[i].OnBulletImpact(
				self,
				pen,
				penshell,
				hitangle,
				deemedwidth,
				hitpos,
				vu,
				hitactoristall
			);

			//the +canblast stops this so it can be reused in the explosion code
			if(!self||(!bmissile&&!bcanblast))return;
		}

		if(penshell<=0)penshell=0;
		else penshell*=1.-frandom(0,hitangle*0.004);

		if(hd_debug)A_Log("Armour: "..pen.."    -"..penshell.."    = "..pen-penshell.."     "..hdmath.getname(hitactor));

		//apply final armour
		pen-=penshell;

		//deform the bullet
		hardness=max(1,hardness-random(0,random(0,3)));
		stamina=max(1,stamina+random(0,(stamina>>1)));

		//immediate impact
		//highly random
		double tinyspeedsquared=speed*speed*0.000001;
		double impact=tinyspeedsquared*0.2*mass;


		//wounding system requires an int for pen - spread this out a bit
		if(pen<1.)pen=frandom(0,1)<pen;


		//check if going right through the body
		if(pen>deemedwidth-0.02*hitangle)flags|=BLAF_ALLTHEWAYTHROUGH;


		//bullet hits without penetrating
		//abandon all damage after impact, then check ricochet
		if(pen<deemedwidth*0.01){
			//if bullet too soft and/or slow, just die
			if(
				speed<16
				||hardness<random(1,3)
				||!random(0,6)
			){
				detonate();
				bulletdie();
			}

			//randomly deflect
			//if deflected, reduce impact
			if(
				bmissile
				&&hitangle>10
			){
				double dump=clamp(0.011*(90-hitangle),0.01,1.);
				impact*=dump;
				speed*=(1.-dump);
				angle+=frandom(10,25)*randompick(1,-1);
				pitch+=frandom(-25,25);
				A_ChangeVelocity(cos(pitch)*speed,0,sin(-pitch)*speed,CVF_RELATIVE|CVF_REPLACE);
			}


			//apply impact damage
			if(impact>(hitactor.spawnhealth()>>2))hdmobbase.forcepain(hitactor);
			if(hd_debug)console.printf(hitactor.getclassname().." resisted, impact:  "..impact);
			hitactor.damagemobj(self,target,int(impact)<<2,"bashing",DMG_NO_ARMOR);
			if(!bcanblast)bulletdie();
			return;
		}


		//both impact and temp cavity do bashing
		impact+=speed*speed*(
			(flags&BLAF_ALLTHEWAYTHROUGH)?
			0.00006:
			0.00009
		);

		int shockbash=int(max(impact,impact*min(pen,deemedwidth))*(frandom(0.1,0.2)+stamina*0.00001));
		if(hd_debug)console.printf("     "..shockbash.." temp cav dmg");

		if(
			!HDMobBase(hitactor)
			&&!HDPlayerPawn(hitactor)
		)shockbash>>=3;

		//apply impact/tempcav damage
		bnoextremedeath=impact<(hitactor.gibhealth<<3);
		hitactor.damagemobj(self,target,shockbash,"bashing",DMG_THRUSTLESS|DMG_NO_ARMOR);
		if(!hitactor)return;
		bnoextremedeath=true;


		//basic threshold bleeding
		//proportionate to permanent wound channel
		//stamina, pushfactor, hardness
		double channelwidth=
			(
				//if it doesn't bleed, it's probably rigid
				(
					hdmobbase(hitactor)
					&&hdmobbase(hitactor).bdoesntbleed
				)?0.0005:0.00025
			)*stamina
			*frandom(20.,20+pushfactor-hardness)
			+frandom(0.0005,0.005)*stamina
			+frandom(0,0.05)*shockbash
		;

		//reduce momentum, increase tumbling, etc.
		double totalresistance=deemedwidth*((!!hdmb)?hdmb.bulletresistance(hitangle):0.6);
		angle+=frandom(-pushfactor,pushfactor)*totalresistance;
		pitch+=frandom(-pushfactor,pushfactor)*totalresistance;
		speed=max(0,speed-frandom(0,pushfactor)*totalresistance*10);
		A_ChangeVelocity(cos(pitch)*speed,0,-sin(pitch)*speed,CVF_RELATIVE|CVF_REPLACE);

		if(flags&BLAF_ALLTHEWAYTHROUGH)channelwidth*=1.2;
		else{
			detonate();
			bulletdie();
		}


		//add size of channel to damage
		int chdmg=int(max(1,
			channelwidth
			*max(0.1,pen-(hitangle*0.06))
			*0.1
		));

		//see if the bullet may actually gib
		bnoextremedeath=(chdmg<(max(hitactor.spawnhealth(),gibhealth)<<4));
		if(hd_debug)console.printf(hitactor.getclassname().."  wound channel:  "..channelwidth.." x "..pen.."    channel HP damage: "..chdmg);

		//inflict wound
		if(multiplayer&&target&&hitactor.isteammate(target))channelwidth*=teamdamage;
		if(channelwidth>0)hdbleedingwound.inflict(
			hitactor,pen,channelwidth,
			(flags&BLAF_SUCKINGWOUND),
			source:target,
			hitlocation:hitpos
		);

		//evaluate cns hit/critical and apply damage
		if(
			pen>deemedwidth*0.4
			&&hitangle<12+frandom(0,tinyspeedsquared*7+stamina*0.001)
		){
			double mincritheight=hitactor.height*0.6;
			double basehitz=hitpos.z-hitactor.pos.z;
			if(
				basehitz>mincritheight
				||basehitz+pen*vu.z>mincritheight
			){
				if(hd_debug)console.printf("CRIT!");
				int critdmg=int(
					(chdmg+random((stamina>>5),(stamina>>5)+(int(speed)>>6)))
					*(1.+pushfactor*0.3)
				);
				if(bnoextremedeath)critdmg=min(critdmg,hitactor.health+1);
				flags|=BLAF_SUCKINGWOUND;
				pen*=2;
				channelwidth*=2;
				hdmobbase.forcepain(hitactor);
				hitactor.damagemobj(
					self,target,critdmg,"Piercing",
					DMG_THRUSTLESS|DMG_NO_ARMOR
				);
			}
		}else{
			if(frandom(0,pen)>deemedwidth)flags|=BLAF_SUCKINGWOUND;
			hitactor.damagemobj(
				self,target,
				chdmg,
				"Piercing",DMG_THRUSTLESS|DMG_NO_ARMOR
			);
		}

		//spawn entry and exit wound blood
		if(hitactor){
			if(
				!bbloodlessimpact
				&&chdmg>random(0,1)
			){
				class<actor>hitblood;
				bool noblood=hitactor.bnoblood;
				if(noblood)hitblood="FragPuff";else hitblood=hitactor.bloodtype;
				double ath=angleto(hitactor);
				double zdif=pos.z-hitactor.pos.z;
				bool gbg;actor blood;
				[gbg,blood]=hitactor.A_SpawnItemEx(
					hitblood,
					-hitactor.radius,0,zdif,
					angle:ath,
						flags:SXF_ABSOLUTEANGLE|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION|SXF_SETTARGET
				);
				if(blood)blood.vel=-vu*(min(3,0.05*impact))
					+(frandom(-0.6,0.6),frandom(-0.6,0.6),frandom(-0.2,0.4)
				);
				if(!noblood)hitactor.TraceBleedAngle((shockbash>>3),angle+180,-pitch);
				if(flags&BLAF_ALLTHEWAYTHROUGH){
					[gbg,blood]=hitactor.A_SpawnItemEx(
						hitblood,
						hitactor.radius,0,zdif,
						angle:ath+180,
						flags:SXF_ABSOLUTEANGLE|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION|SXF_SETTARGET
					);
					if(blood)blood.vel=vu+(frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.4));
					if(!noblood)hitactor.TraceBleedAngle((shockbash>>3),angle,pitch);
				}
			}
		}


		//fragmentation
		if(!(flags&BLAF_DONTFRAGMENT)&&random(0,100)<woundhealth){
			int fragments=clamp(random(2,(woundhealth>>3)),1,5);
			if(hd_debug)console.printf(fragments.." fragments emerged from bullet");
			while(fragments){
				fragments--;
				let bbb=HDBulletActor(spawn("HDBulletActor",pos));
				bbb.target=target;
				bbb.bincombat=false;
				double newspeed;
				speed*=0.6;
				if(!fragments){
					bbb.mass=mass;
					newspeed=speed;
					bbb.stamina=stamina;
				}else{
					//consider distributing this more randomly between the fragments?
					bbb.mass=max(1,random(1,mass-1));
					bbb.stamina=max(1,random(1,stamina-1));
					newspeed=frandom(0,speed-1);
					mass-=bbb.mass;
					stamina=max(1,stamina-bbb.stamina);
					speed-=newspeed;
				}
				bbb.pushfactor=frandom(0.6,5.);
				bbb.accuracy=random(50,300);
				bbb.angle=angle+frandom(-45,45);
				double newpitch=pitch+frandom(-45,45);
				bbb.pitch=newpitch;
				bbb.A_ChangeVelocity(
					cos(newpitch)*newspeed,0,-sin(newpitch)*newspeed,CVF_RELATIVE|CVF_REPLACE
				);
			}
			bulletdie();
			return;
		}
	}
	virtual void Detonate(){}
	virtual actor Puff(){
		//TODO: virtual actor puff(textureid hittex){}
			//flesh: bloodsplat
			//fluids: splash
			//anything else: puff and add bullet hole

		if(max(abs(pos.x),abs(pos.y))>32000)return null;
		double sp=speed*speed*mass*0.000015;
		if(sp<50)return null;

		let aaa=HDBulletPuff(spawn("HDBulletPuff",pos));
		if(aaa){
			aaa.angle=angle;aaa.pitch=pitch;
			aaa.stamina=int(sp*0.01);
			aaa.scarechance=max(0,20-int(sp*0.001));
			aaa.scale=(1.,1.)*(0.4+0.05*aaa.stamina);
			aaa.target=target;
		}
		return aaa;
	}
}


//trail actors for flyby sounds
class BulletSoundTrail:IdleDummy{
	default{deathheight 0.;}
	states{
	spawn:
		TNT1 A 10;
		TNT1 A 0{
			if(
				!deathheight
				||deathheight>frandom(0,ceilingz-floorz)
			)A_AlertMonsters();
		}stop;
	}
}

extend class HDActor{
	//threshold and overall resistance to gunshots
	//bulletshell() is for whether the bullet goes through
	//bulletresistance() is for how much the bullet gets stopped, warped or redirected once inside
	virtual double bulletshell(
		vector3 hitpos,
		double hitangle
	){
		return 0;
	}
	virtual double bulletresistance(
		double hitangle //abs(bullet.angleto(hitactor),bullet.angle)
	){
		return max(0,frandom(0.8,1.0)-hitangle*0.01);
	}
}