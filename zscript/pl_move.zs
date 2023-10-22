// ------------------------------------------------------------
// Movement checks.
// ------------------------------------------------------------
const HDCONST_MAXFOCUSSCALE=0.99;
extend class HDPlayerPawn{
	//input is no longer considered in CheckPitch since it's already in HD's TurnCheck.
	override void CheckPitch(){
		if(player.centering){
			if (abs(Pitch)>2.){
				Pitch*=(2./3.);
			}else{
				Pitch=0.;
				player.centering = false;
				if(PlayerNumber()==consoleplayer)LocalViewPitch=0;
			}
		}else pitch=clamp(pitch,player.minpitch,player.maxpitch);
	}
	override void CalcHeight(){
		if(
			CheckFrozen()
			||(incapacitated&&health>0)
		)return;
		super.CalcHeight();
	}
	override void CheckCrouch(bool totallyfrozen){}
	void CrouchCheck(){
		if(CheckFrozen())return;
		let player=self.player;
		UserCmd cmd=player.cmd;
		if(
			CanCrouch() //map settings check intentionally omitted
			&&player.health>0
		){
			int crouchdir=player.crouching;
			if(
				cmd.buttons&BT_JUMP
				&&player.onground
			)crouchdir=1;
			else if(!crouchdir){
				crouchdir=(cmd.buttons&BT_CROUCH)?-1:1;
			}
			else if(cmd.buttons&BT_CROUCH){
				player.crouching=0;
			}
			if(
				crouchdir==1
				&&player.crouchfactor<1
				&&pos.z+height<ceilingz
			){
				CrouchMove(1);
			}
			else if(
				crouchdir==-1
				&&player.crouchfactor>0.5
			){
				CrouchMove(-1);
			}
		}else player.Uncrouch();
		player.crouchoffset=-(viewheight)*(1-player.crouchfactor);
	}
	override void CrouchMove(int direction){
		let player=self.player;
		bool notpredicting=!(player.cheats&CF_PREDICTING);

		//fuck it
		if(!notpredicting)return;

		double defaultheight = FullHeight;
		double savedheight = Height;
		if(savedheight==0)savedheight=defaultheight;
		double crouchspeed = direction*CROUCHSPEED;
		double oldheight = player.viewheight;
		double grav=getgravity();
		double onground=player.onground;

		crouchspeed*=max(
			(health+100)*0.6*strength
			-(direction==1?overloaded*3:overloaded*0.5)
			-(fatigue>20?fatigue*2:fatigue)
			-((stunned&&direction==1)?80:0)
			,20
		)*0.01;

		player.crouchdir=direction;
		player.crouchfactor+=crouchspeed;

		//check whether the move is ok
		Height = defaultheight * player.crouchfactor;

		if(!TryMove(Pos.XY, false, NULL)){
			Height = savedheight;
			if (direction > 0){
				// doesn't fit
				player.crouchfactor -= crouchspeed;
				return;
			}
		}else if(notpredicting){
			if(!(level.time%10))fatigue++;
			bool goingup=direction>0;

			//retract into your centre not just down
			if(!onground){
				addz((savedheight-Height)*0.5);
			}
		}
		Height = savedheight;

		player.crouchfactor = clamp(player.crouchfactor, 0.5, 1.);
		player.viewheight = ViewHeight * player.crouchfactor;
		player.crouchviewdelta = player.viewheight - ViewHeight;

		// Check for eyes going above/below fake floor due to crouching motion.
		CheckFakeFloorTriggers(pos.Z + oldheight, true);

		if(notpredicting)gunbraced=false;
	}

	double realpitch;
	double oldrealpitch;
	int fallroll;

	override void MovePlayer(){
		let player = self.player;
		if(!player)return;
		UserCmd cmd = player.cmd;
		bool notpredicting = !(player.cheats & CF_PREDICTING);

		//update lastpitch and lastangle if teleported
		if(teleported){
			lastpitch=pitch;
			lastangle=angle;
		}

		//cache cvars as necessary
		if(!hd_nozoomlean)cachecvars();


		//set up leaning
		int leanmove=0;
		double leanamt=leaned?(10./(3+overloaded)):0;
		if(notpredicting){
			if(
				hdweapon(player.readyweapon)
			){
				leanamt*=8./max(8.,hdweapon(player.readyweapon).gunmass());
			}
			if(
				cmdleanmove&HDCMD_LEFT
				&&(
					leaned<=0
					||cmdleanmove&HDCMD_RIGHT
				)
			)leanmove--;
			if(
				cmdleanmove&HDCMD_RIGHT
				&&(
					leaned>=0
					||cmdleanmove&HDCMD_LEFT
				)
			)leanmove++;
			if(
				!leanmove
				&&(
					cmdleanmove&HDCMD_STRAFE
					||(
						cmd.buttons&BT_ZOOM
						&&!hd_nozoomlean.getbool()
					)
				)
			){
				if(cmd.sidemove<0&&leaned<=0)leanmove--;
				if(cmd.sidemove>0&&leaned>=0)leanmove++;
				cmd.sidemove=0;
			}
		}


		TurnCheck(notpredicting,player.readyweapon);



		player.onground = (pos.z <= floorz) || bOnMobj || bMBFBouncer || (player.cheats & CF_NOCLIP2);

		// killough 10/98:
		//
		// We must apply thrust to the player and bobbing separately, to avoid
		// anomalies. The thrust applied to bobbing is always the same strength on
		// ice, because the player still "works just as hard" to move, while the
		// thrust applied to the movement varies with 'movefactor'.

				if(movehijacked){
			if(notpredicting)movehijacked=false;
		}else if(
			cmd.forwardmove
			||cmd.sidemove
			||leanmove
		){
			double forwardmove=0;double sidemove=0;
			double bobfactor=0;
			double friction=0;double movefactor=0;
			double fm=0;double sm=0;

			[friction, movefactor] = GetFriction();
			bobfactor = heightmult*(friction<ORIG_FRICTION ? movefactor : ORIG_FRICTION_FACTOR);

			//bobbing adjustments
			if(stunned)bobfactor*=4.;
			else if(cansprint && runwalksprint>0)bobfactor*=1.6;
			else if(runwalksprint<0||mustwalk){
				if(player.crouchfactor==1)bobfactor*=0.4;
				else bobfactor*=0.7;
			}

			if(!player.onground && !bNoGravity && !waterlevel && hd_slowairmovement == true){
				// [RH] allow very limited movement if not on ground.
				movefactor*=level.aircontrol;
				bobfactor*=level.aircontrol;
			}

			//"override double,double TweakSpeeds()"...
			double basespeed=speed*12.;
			if(cmd.forwardmove){
				fm=basespeed;
				if(cmd.forwardmove<0)fm*=-0.8;
			}
			if(cmd.sidemove>0)sm=basespeed;
			else if(cmd.sidemove<0)sm=-basespeed;
			if(!player.morphTics){
				double factor=1.;
				for(let it=Inv;it;it=it.Inv){
					factor *= it.GetSpeedFactor();
				}
				fm*=factor;
				sm*=factor;
			}

			// When crouching, speed <s>and bobbing</s> have to be reduced
			if(CanCrouch() && player.crouchfactor != 1 && runwalksprint>=0){
				fm *= player.crouchfactor;
				sm *= player.crouchfactor;
			}

			if(fm&&sm)movefactor*=HDCONST_ONEOVERSQRTTWO;

			if(heightmult&&heightmult!=1)movefactor/=heightmult;

			//So far we'll stick with modelling people who can still walk.
			//Mobility aids may be added later.
			//What is a wheelchair but an unarmoured mech?
			if(
				strength>1.
				||runwalksprint>=0
			)movefactor*=(0.3*strength+0.7);

			if(!canmovelegs)movefactor*=0.1;

			forwardmove = fm * movefactor * (35 / TICRATE);
			sidemove = sm * movefactor * (35 / TICRATE);

			if(forwardmove){
				Bob(Angle, cmd.forwardmove * bobfactor / 256., true);
				ForwardThrust(forwardmove, Angle);
			}
			if(sidemove){
				let a = Angle - 90;
				Bob(a, cmd.sidemove * bobfactor / 256., false);
				Thrust(sidemove, a);
			}
			if(
				leanmove
				&&notpredicting
				&&!isfrozen()
			){
				bool zrk=countinv("HDZerk")>HDZerk.HDZERK_COOLOFF;
				bool poscmd=leanmove>0;
				let a = Angle - 90;
				leaned=clamp(poscmd?leaned+1:leaned-1,-8,8);
				if(zrk){
					leaned=clamp(poscmd?leaned+1:leaned-1,-8,8);
					leanamt*=2;
				}
				if(!poscmd)leanamt=-leanamt;
				if(abs(leaned)<8){
					TryMove(
						pos.xy+(cos(a),sin(a))*leanamt,
						false
					);
				}
			}

			if(
				notpredicting
				&&(forwardmove||sidemove)
			){
				PlayRunning();
			}

			if(player.cheats & CF_REVERTPLEASE){
				player.cheats &= ~CF_REVERTPLEASE;
				player.camera = player.mo;
			}
		}


		double toroll=-999;


		//undo leaning
		if(notpredicting){
			if(!leanmove&&leaned){
				let a=angle+90;
				if(leaned>0)leaned--;
				else if(leaned<0){
					leaned++;
					leanamt=-leanamt;
				}
				TryMove(
					pos.xy+(cos(a),sin(a))*leanamt,
					false
				);
			}
			toroll=(leaned>0?leaned:-leaned)*leanamt;
		}


		//turn view roll upside down to conform to movement roll
		double arp=abs(realpitch);
		if(
			arp<=270
			&&arp>90
		)toroll=180;
		else if(roll==180)toroll=0;

		if(toroll!=-999)A_SetRoll(toroll,SPF_INTERPOLATE);


		//if done in ticker, fails to show difference during TurnCheck
		lastvel=vel;
	}
	int leaned;
	int cmdleanmove;



	//rolling
	const HDCONST_ROLLMAXSTEPHEIGHT=5.;
	void RollCheck(){
		if(
			fallroll
			||(
				abs(realpitch)>=90
				&&abs(realpitch)<=270
			)
		){
			lastpitch=pitch;
			lastangle=roll==180?(normalize180(angle+180)):angle;
			feetangle=lastangle;
			stunned=max(stunned,15);
			totallyblocked=true;
			double chenc=max(0,overloaded);
			double invchenc=max(0.3,2.0-chenc)*clamp(abs(fallroll>>5),1,20);
			double addrealpitch=clamp(abs(fallroll)+frandom(-4,3)*chenc,10,50);
			vector2 rollpush=(cos(angle),sin(angle))*invchenc*0.3;
			player.crouchfactor=max(player.crouchfactor-0.3,0.5);
			player.crouching=min(player.crouching,0);
			maxstepheight=heightmult*HDCONST_ROLLMAXSTEPHEIGHT;
			if(!(fallroll&(1|2|4)))fatigue++;

			//limit rolls against geometry
			vector2 testrp=(fallroll>0?2:-2)*rollpush;
			bool blocked=!checkmove(pos.xy+testrp);
			if(
				testrp==(0,0)
				||blocked
				||(
					//actually blocked but the checkmove didn't pick it up
					vel.xy==(0,0)
					&&lastvel.xy!=(0,0)
					&&fallroll
				)
			){
				if(blocked)vel.z+=abs(fallroll*0.06);
				fallroll=clamp(fallroll,-10,10);
			}

			//[MC 2021-07-13] as of 4.6.0 there is an unavoidable flicker
			//as some interpolation is forced onto the 180 turn.
			//I am neither able to locate the source in HD nor replicate it
			//outside of HD. This may be related to the interpolation that
			//is being overhauled after 4.6.0 so I don't want to try too hard
			//to work around it.
			//[MC 2021-07-13] Solution 1: do not interpolate pitch while rolling.
			//Solution 2: add a tiny angle change each flip.
			// Note re: 2: the +- direction is IMPORTANT. I have no idea why.

			let didRoll = fallroll;
			if(fallroll>0){
				fallroll--;
				realpitch+=addrealpitch;
				if(realpitch>270){
					realpitch=realpitch-360;
					angle=normalize180(angle+180);
					roll=0;
				}
				if(realpitch>90){
					if(oldrealpitch<=90){
						angle=normalize180(angle+180);
						roll=180;
						if(player.onground)A_StartSound(landsound,CHAN_BODY,CHANF_OVERLAP,volume:0.5,pitch:0.8);
					}
					rollpush=-rollpush;

					A_SetPitch(normalize180(-realpitch+180),SPF_INTERPOLATE);
					A_SetAngle(normalize180(angle+0.0001),SPF_INTERPOLATE);

					fallroll=max(fallroll,5);
				}else{
					A_SetPitch(normalize180(realpitch),SPF_INTERPOLATE);
					A_SetAngle(normalize180(angle-0.0001),SPF_INTERPOLATE);

					//try to face forwards not up
					if(
						!fallroll
						&&realpitch<0
					){
						player.crouching=player.crouchdir; //reset to normal
						double aac=-realpitch*0.18;
						muzzleclimb1.y+=aac;
						muzzleclimb2.y+=aac;
						muzzleclimb3.y+=aac;
						muzzleclimb4.y+=aac;
					}
				}
			}else if(fallroll<0){
				fallroll++;
				realpitch-=addrealpitch;
				if(realpitch<=-270){
					realpitch=realpitch+360;
					angle=normalize180(angle+180);
					roll=0;
				}
				if(realpitch<-90){
					if(oldrealpitch>=-90){
						angle=normalize180(angle+180);
						roll=180;
						if(player.onground)A_StartSound(landsound,CHAN_BODY,CHANF_OVERLAP,volume:0.5,pitch:0.8);
					}

					A_SetPitch(normalize180(-realpitch-180),SPF_INTERPOLATE);
					A_SetAngle(normalize180(angle-0.0001),SPF_INTERPOLATE);

					fallroll=min(fallroll,-5);
				}else{
					rollpush=-rollpush;

					A_SetPitch(normalize180(realpitch),SPF_INTERPOLATE);
					A_SetAngle(normalize180(angle+0.0001),SPF_INTERPOLATE);

					//try to face forwards not down
					if(
						!fallroll
						&&realpitch>0
					){
						player.crouching=player.crouchdir; //reset to normal
						double aac=-realpitch*0.1;
						muzzleclimb1.y+=aac;
						muzzleclimb2.y+=aac;
						muzzleclimb3.y+=aac;
						muzzleclimb4.y+=aac;
					}
				}
			}

			// reset angles after all other thinkers tick
			if(didRoll)new('HDGrossImmerseCompatHack').Init(self);

			//fumble weapon
			let hdw=hdweapon(player.readyweapon);
			if(
				hdw
				&&hdw.bweaponbusy
				&&!random(0,40)
			)Disarm(self);

			oldrealpitch=realpitch;
			if(
				realpitch<=90
				&&realpitch>=-90
			)realpitch=pitch;

			if(player.onground){
				vel.xy+=rollpush;
				A_SetInventory("HDFireDouse",countinv("HDFireDouse")
					+random(
						1,
						(
							HDMath.CheckDirtTexture(self)?12
							:HDMath.CheckLiquidTexture(self)?10
							:6
						)
					)
				);
			}
			return;
		}else{
			fallroll=0;
		}
	}
}

class HDGrossImmerseCompatHack : Thinker{
	double pitch;
	double yaw;
	double roll;

	Actor target;

	void Init(Actor other){
		pitch  = other.pitch;
		yaw    = other.angle;
		roll   = other.roll;

		target = other;
	}

	override void PostBeginPlay(){
		if (target.prev != target.pos){
			target.pitch = pitch;
			target.angle = yaw;
			target.roll  = roll;
		}

		Destroy();
	}
}


extend class HDHandlers{
	//handler for receiving direct button lean input
	void Lean(hdplayerpawn ppp,int dir){
		if(!ppp.player)return;
		int cmdleanmove=ppp.cmdleanmove;
		if(dir==999){
			cmdleanmove|=HDCMD_STRAFE;
		}else if(dir==99){
			cmdleanmove&=~HDCMD_RIGHT;
		}else if(dir==-99){
			cmdleanmove&=~HDCMD_LEFT;
		}else if(dir==1){
			cmdleanmove|=HDCMD_RIGHT;
		}else if(dir==-1){
			cmdleanmove|=HDCMD_LEFT;
		}else cmdleanmove=0;
		ppp.cmdleanmove=cmdleanmove;
	}
}
enum leanmovecmd{
	HDCMD_STRAFE=1,
	HDCMD_LEFT=2,
	HDCMD_RIGHT=4,
}


