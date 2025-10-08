// ------------------------------------------------------------
// Stuff related to player turning
// ------------------------------------------------------------
const HDCONST_JITTERHEALTH=33;
extend class HDPlayerPawn{
    vector2 muzzleclimb1;
    vector2 muzzleclimb2;
    vector2 muzzleclimb3;
    vector2 muzzleclimb4;
    vector2 wepbobrecoil1;
    vector2 wepbobrecoil2;
    vector2 wepbobrecoil3;
    vector2 wepbobrecoil4;
    vector2 muzzledrift;

    bool muzzlehit;
    bool totallyblocked;
    enum muzzleblock{
        MB_TOP=1,
        MB_BOTTOM=2,
        MB_LEFT=4,
        MB_RIGHT=8,
    }

    double lastpitch,lastangle;
    void TurnCheck(bool notpredicting,weapon readyweapon){

        //abort if rolling or teleporting
        if(
            teleported
            ||fallroll
            ||realpitch>90
            ||realpitch<-90
        ){
            if(teleported)feetangle=angle;
            return;
        }


        //find things that scale input
        double turnscale=1.;

        //reduced turning while supported.
        if(
            isFocussing
            &&!IsMoving.Count(self)
        ){
            double aimscale=hd_aimsensitivity.GetFloat();
            if(aimscale>1.)aimscale=0.1;
            if(!gunbraced)aimscale+=(1.-aimscale)*0.3;
            else aimscale=min(aimscale,hd_bracesensitivity.GetFloat());
            turnscale*=clamp(aimscale,0.05,HDCONST_MAXFOCUSSCALE);
        }
        //reduced turning while crouched.
        else if(player.crouchfactor<0.7){
            int absch=max(abs(player.cmd.yaw),abs(player.cmd.pitch));
            if(absch>(8*65536/360)){
                turnscale*=0.6;
            }
        }
        //reduced turning while stunned.
        //all randomizing and inertia effects are in TurnCheck.
        if(stunned)turnscale*=0.3;

        //process input
        double anglechange=clamp((360./65536.)*player.cmd.yaw,-40,40);
        double pitchchange=-(360./65536.)*player.cmd.pitch;

        //abort if turn hijacked
        if(
            reactiontime>0
        ){
            anglechange=0;
            pitchchange=0;
        }

        //don't do anything that could seriously change between tics
        //ultimately we might be fored to just "return" on these
        if(!notpredicting){
            angle+=anglechange;
            pitch+=pitchchange;
            UpdateCrossbob(); // for network situations
            return;
        }



        //does anyone even use this?
        if(player.turnticks){
            player.turnticks--;
            anglechange+=(180./TURN180_TICKS);
        }


        //set lookscale and fov
        if(readyweapon)readyweapon.lookscale=turnscale;
        player.fov=player.desiredfov*recoilfov;




        //process muzzle climb
        pitchchange+=muzzleclimb1.y;
        anglechange+=muzzleclimb1.x;

        muzzleclimb1=muzzleclimb2;
        muzzleclimb2=muzzleclimb3;
        muzzleclimb3=muzzleclimb4;
        muzzleclimb4=(0,0);




        //get weapon size
        double driftamt=0;
        double barrellength=0;
        double barrelwidth=0;
        double barreldepth=0;
        bool notnull=!NullWeapon(readyweapon);
        let wp=HDWeapon(readyweapon);
        if(wp){
            driftamt=max(0.4,wp.gunmass());
            barrellength=wp.barrellength;
            barrelwidth=wp.barrelwidth;
            barreldepth=wp.barreldepth;
        }


        //inertia adjustments for other things
        if(stunned){
            driftamt*=frandom(3,5);
        }
        if(
            notnull
            &&HDWeapon.IsBusy(self)
        ){
            barrellength=radius+1.4;
            barrelwidth*=2;
            driftamt=min(driftamt*1.5,20);
        }




        //muzzle inertia
        //how much to scale movement
        double decelproportion=min((0.05-(0.02*strength))*driftamt,0.99);
        double driftproportion=0.05*driftamt;

        //apply to weapon
        vector2 apch=(anglechange,-pitchchange)*driftamt*(0.05+0.05*(1.-strength));
        if(
            isFocussing
            ||(wp&&wp.breverseguninertia)
        )apch=-apch;
        wepbobrecoil1+=apch*0.1;
        wepbobrecoil2+=apch*0.2;
        wepbobrecoil3+=apch*0.4;
        wepbobrecoil4+=apch*0.6;

        //make changes based on velocity
        vector3 muzzlevel=lastvel-vel;

        //apply crouch
        muzzlevel.z-=(lastheight-height)*0.3;

        //determine velocity-based drift
        muzzlevel.xy=rotatevector(muzzlevel.xy,-angle);

        muzzledrift+=(muzzlevel.y,muzzlevel.z)*driftproportion;


        //screw things up even more
        if(stunned){
            vector2 muzzleclimbstun=(anglechange,pitchchange)*frandom(0,0.3);
            anglechange+=muzzleclimbstun.x;
            pitchchange+=muzzleclimbstun.y;
            muzzleclimb1+=muzzleclimbstun;
            muzzleclimb2+=muzzleclimbstun;
            muzzleclimb3+=muzzleclimbstun;
        }


        //apply the drift
        wepbobrecoil1+=muzzledrift;
        muzzledrift*=decelproportion;
        wepbobrecoil2+=muzzledrift;


        LowHealthJitters();


        //weapon collision
        double highheight=player.viewheight;
        if(viewpos)highheight+=viewpos.offset.z;
        double testangle=angle;
        double testpitch=pitch;
        vector3 posbak=pos;

        setxyz(posbak+vel);

        //check for super-collision preventing only aligned sights
        flinetracedata bigcoll;
        if(
            !barehanded
            &&linetrace(
                testangle,max(barrellength,HDCONST_MINEYERANGE),
                testpitch,
                flags:TRF_NOSKY|TRF_ABSOFFSET,
                offsetz:highheight,
                offsetforward:viewpos.offset.x,
                offsetside:viewpos.offset.y,
                data:bigcoll
            )
            &&(
                !bigcoll.hitactor
                ||(
                    bigcoll.hitactor.bsolid
                    &&!bigcoll.hitactor.bnoclip
                )
            )
        ){
            highheight=height*0.7;
            nocrosshair=12;
            if(pitch>=4){
                wepbobrecoil1.y+=3;
                wepbobrecoil2.y+=3;
                wepbobrecoil3.y+=3;
                wepbobrecoil4.y+=3;
            }
        }

        gunpitch=pitch+wepbob.y;
        gunangle=angle-wepbob.x;

        gunorigin=(!viewpos?(0,0):viewpos.offset.xy,highheight);
        gunpos=gunorigin+
            hdmath.rotatevec3d(
                (HDCONST_GUNPOSOFFSET,0,-1.5),
                gunangle,
                gunpitch
            )
        ;
        gunorigin+=hdmath.rotatevec3d(
            (0,0,-1.5),
            gunangle,
            gunpitch
        );
        highheight=min(highheight,gunpos.z+barreldepth*0.5);

        barrellength-=(radius*0.6*player.crouchfactor);


        //and now uh do stuff
        int muzzleblocked=0;

        double distleft=barrellength;;
        double distright=barrellength;;
        double disttop=barrellength;
        double distbottom=barrellength;

        flinetracedata ltl;
        flinetracedata ltr;
        flinetracedata ltt;
        flinetracedata ltb;



        //top
        vector3 bgps=gunorigin+hdmath.rotatevec3d((0,0,0.5),gunangle,gunpitch);
        linetrace(
            gunangle,barrellength,gunpitch,flags:TRF_NOSKY|TRF_ABSOFFSET,
            offsetz:bgps.z,
            offsetforward:bgps.x,
            offsetside:bgps.y,
            data:ltt
        );
        if(
            ltt.hittype!=Trace_CrossingPortal
            &&!(ltt.hitactor&&(
                ltt.hitactor.bnonshootable
                ||!ltt.hitactor.bsolid
            ))
        ){
            disttop=ltt.distance;
            if(ltt.distance<barrellength)muzzleblocked|=MB_TOP;
        }

        //bottom
        vector3 gps=bgps+hdmath.rotatevec3d((0,0,-barreldepth),gunangle,gunpitch);
        linetrace(
            gunangle,barrellength,gunpitch,flags:TRF_NOSKY|TRF_ABSOFFSET,
            offsetz:gps.z,
            offsetforward:gps.x,
            offsetside:gps.y,
            data:ltb
        );
        if(
            ltb.hittype!=Trace_CrossingPortal
            &&!(ltb.hitactor&&(
                ltb.hitactor.bnonshootable
                ||!ltb.hitactor.bsolid
            ))
        ){
            distbottom=ltb.distance;
            if(ltb.distance<barrellength)muzzleblocked|=MB_BOTTOM;
        }


        //left
        double halfbd=-barreldepth*0.5;
        gps=bgps+hdmath.rotatevec3d((0,-barrelwidth,halfbd),gunangle,gunpitch);
        linetrace(
            gunangle,barrellength,gunpitch,flags:TRF_NOSKY|TRF_ABSOFFSET,
            offsetz:gps.z,
            offsetforward:gps.x,
            offsetside:gps.y,
            data:ltl
        );
        if(
            ltl.hittype!=Trace_CrossingPortal
            &&!(ltl.hitactor&&(
                ltl.hitactor.bnonshootable
                ||!ltl.hitactor.bsolid
            ))
        ){
            distleft=ltl.distance;
            if(ltl.distance<barrellength)muzzleblocked|=MB_LEFT;
        }

        //right
        gps=bgps+hdmath.rotatevec3d((0,barrelwidth,halfbd),gunangle,gunpitch);
        linetrace(
            gunangle,barrellength,gunpitch,flags:TRF_NOSKY|TRF_ABSOFFSET,
            offsetz:gps.z,
            offsetforward:gps.x,
            offsetside:gps.y,
            data:ltr
        );
        if(
            ltr.hittype!=Trace_CrossingPortal
            &&!(ltr.hitactor&&(
                ltr.hitactor.bnonshootable
                ||!ltr.hitactor.bsolid
            ))
        ){
            distright=ltr.distance;
            if(ltr.distance<barrellength)muzzleblocked|=MB_RIGHT;
        }


        //debug: show where the lines have gone
        if(hd_debug>2){
            HDF.Particle(self,"orange",ltt.hitlocation,1);
            HDF.Particle(self,"red",ltb.hitlocation,1);
            HDF.Particle(self,"red",ltl.hitlocation,1);
            HDF.Particle(self,"red",ltr.hitlocation,1);
            HDF.Particle(self,"green",pos+gunpos,1);
            HDF.Particle(self,"grey",pos+gunorigin,1);
        }


        UpdateCrossbob(); // Do again if necessary for smoother interpolation


        //totally caught
        totallyblocked=muzzleblocked==MB_TOP|MB_BOTTOM|MB_LEFT|MB_RIGHT;


        if(!(player.cheats&(CF_NOCLIP2|CF_NOCLIP))){

            //set angles
            int crouchdir=0;
            if(
                player.crouchfactor<1
                &&player.crouchfactor>0.5
            ){
                crouchdir=player.crouching;
                if(!crouchdir)crouchdir=(player.cmd.buttons&BT_CROUCH)?-1:1;
            }
            bool mvng=(crouchdir || (vel dot vel) > 0.25);
            bool hitsnd=(max(abs(anglechange),abs(pitchchange))>1);


            if(
                muzzleblocked
                &&notnull
            ){

                if(totallyblocked){
                    vector2 cv=angletovector(pitch,
                        clamp(barrellength-disttop,0,barrellength)*0.005);
                    A_ChangeVelocity(-cv.x,0,0,CVF_RELATIVE);
                }

                if(distleft!=distright){
                    double aac=abs(anglechange);
                    anglechange+=clamp(
                        -anglechange*0.1,
                        (muzzleblocked&MB_RIGHT)?-0.1:-aac,
                        (muzzleblocked&MB_LEFT)?0.1:aac
                    );
                    if(mvng){
                        double agc=(distleft>distright)?1:(distright>distleft)?-1:0;
                        if(agc){
                            anglechange=agc;
                            muzzleclimb1.x+=agc*0.3;
                            muzzleclimb2.x+=agc*0.2;
                            muzzleclimb3.x+=agc*0.1;
                            muzzleclimb4.x+=agc*0.04;
                        }
                    }
                }

                if(
                    disttop!=distbottom
                    ||(muzzleblocked&MB_BOTTOM)
                    ||(muzzleblocked&MB_TOP)
                ){
                    double aac=abs(pitchchange);
                    if(aac<4){
                        pitchchange=clamp(pitchchange,
                            (muzzleblocked&MB_TOP)?-0.1:-aac,
                            (muzzleblocked&MB_BOTTOM)?0.1:aac
                        );
                    }
                    else pitchchange+=clamp(
                        -pitchchange*0.1,
                        (muzzleblocked&MB_TOP)?-0.1:-aac,
                        (muzzleblocked&MB_BOTTOM)?0.1:aac
                    );
                    if(mvng){
                        double agc=(
                            (crouchdir>0&&pitch>0)
                            ||distbottom>disttop
                        )?1:(
                            (crouchdir<0&&pitch<0)
                            ||disttop>distbottom
                        )?-1:0;
                        if(agc){
                            pitchchange=agc*3;
                            muzzleclimb1.y+=agc*0.8;
                            muzzleclimb2.y+=agc*0.4;
                            muzzleclimb3.y+=agc*0.2;
                            muzzleclimb4.y+=agc*0.1;
                        }
                    }
                }

                if(
                    (anglechange>0&&(muzzleblocked&MB_LEFT))
                    ||(anglechange<0&&(muzzleblocked&MB_RIGHT))
                    ||(pitchchange>0&&(muzzleblocked&MB_BOTTOM))
                    ||(pitchchange<0&&(muzzleblocked&MB_TOP))
                ){
                    isfocussing=true;
                    gunbraced=true;
                }
            }

            //bump
            if(muzzleblocked>=4){
                muzzlehit=false;
            }else if(!muzzlehit){
                if(hitsnd)A_StartSound("weapons/guntouch",8,CHANF_OVERLAP,0.6);
                muzzlehit=true;
                gunbraced=true;
            }
        }


        setxyz(posbak);



        //feet angle
        double fac=deltaangle(feetangle,angle);
        if(abs(fac)>(player.crouchfactor<0.7?30:50)){
            vel+=rotatevector((0,fac>0?0.1:-0.1),angle);
            IsMoving.Give(self,2);
            feetangle=angle+anglechange;
            PlayRunning();

            //if on appropriate terrain, easier to quench a fire
            if(player.crouchfactor<0.7){
                A_SetInventory("HDFireDouse",countinv("HDFireDouse")+(
                    HDMath.CheckDirtTexture(self)?7
                    :HDMath.CheckLiquidTexture(self)?6
                    :3
                ));
            }
        }


        //move pivot point a little ahead of the player's view if braced
        anglechange=normalize180(anglechange);
        if(
            !teleported
            &&!incapacitated
            &&player.onground
            &&gunbraced
            &&!barehanded
            &&isFocussing
        ){
            double aac=abs(anglechange);
			if(aac>0.05){
                double aad=angle+anglechange+90;
                vector2 mvec=(cos(aad),sin(aad))*(-0.7*heightmult*anglechange);
				if(max(abs(mvec.x),abs(mvec.y))>radius){
					gunbraced=false;
				}else trymove(self.pos.xy+mvec,false);
            }
        }



        //reset blocked check for a fresh start
        totallyblocked=false;

        //this and the predicting equivalent above should, ideally, be the ONLY
        //places where HD should be changing the player pitch and angle.
        if(multiplayer){
            angle+=anglechange;
            pitch+=pitchchange;
        }else{
            A_SetPitch(pitch+pitchchange,SPF_INTERPOLATE);
            A_SetAngle(angle+anglechange,SPF_INTERPOLATE);
        }
    }

    //calculate ideal crosshair position - hud will handle interpolation
    void UpdateCrossbob() {
        if(!viewpos)return;

        lastcrossbob=crossbob;

        crossbob.x=
            -deltaangle(angle,gunangle)
            *cos(pitch)
            *320./player.fov
        ;
        crossbob.y=
            (gunpitch-pitch)
            *200./player.fov
        ;
    }

    void LowHealthJitters(){
        if(
            beatmax<10||
            fatigue>20||
            bloodpressure>20||
            health<HDCONST_JITTERHEALTH
        ){
            double jitter=clamp(0.01*fatigue,0.3,6.);
            if(!JitterScale) JitterScale = CVar.GetCVar('hdp_lowhealth_jitters', self.player);

            if(gunbraced && JitterScale.GetBool())jitter=0.05;
            else if(health<20 && JitterScale.GetBool())jitter=1;

            if(JitterScale.GetBool())wepbobrecoil1+=(frandom(-jitter,jitter),frandom(-jitter,jitter));
            if(JitterScale.GetBool())muzzleclimb1+=(frandom(-jitter,jitter),frandom(-jitter,jitter));
        }
    }

    //used for all sorts of things...
    void A_MuzzleClimb(vector2 mc1,vector2 mc2,vector2 mc3,vector2 mc4,bool wepdot=false){
        double mult=1.;
        if(gunbraced)mult=0.2;
        else if(IsMoving.Count(self))mult=1.6;
        if(stunned)mult*=1.6;
        if(
            wepdot
            &&strength<1.8
        )mult*=(2.-strength);
        if(!mult)return;
        if(mult!=1.){
            mc1*=mult;
            mc2*=mult;
            mc3*=mult;
            mc4*=mult;
        }
        muzzleclimb1+=mc1;
        muzzleclimb2+=mc2;
        muzzleclimb3+=mc3;
        muzzleclimb4+=mc4;

        //if *actually* for muzzle climb, throw off the weapon a bit
        if(wepdot){
            mult*=0.2;
            wepbobrecoil1+=(mc1.x,mc1.y*2)*mult;
            wepbobrecoil2+=(mc2.x,mc2.y*2)*mult;
            wepbobrecoil3+=(mc3.x,mc3.y*2)*mult;
            wepbobrecoil4+=(mc4.x,mc4.y*2)*mult;
        }
    }
}


