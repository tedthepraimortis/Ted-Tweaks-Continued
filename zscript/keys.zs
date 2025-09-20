//-------------------------------------------------
// Keys
//-------------------------------------------------
enum HDKeyFlags{
    HDKEY_BLUE=1,
    HDKEY_YELLOW=2,
    HDKEY_RED=4,
}
class KeyLoadoutGiver:HDPickup{
    default{
        -hdpickup.fitsinbackpack
        inventory.maxamount 7;
        hdpickup.refid HDLD_KEY;
        tag "$TAG_KEYS";
    }
    states{
    spawn:TNT1 A 0;stop;
    pickup:
        TNT1 A 0{
            int whichkeys=invoker.amount;
            if(whichkeys&HDKEY_RED)A_GiveInventory("RedCard");
            if(whichkeys&HDKEY_YELLOW)A_GiveInventory("YellowCard");
            if(whichkeys&HDKEY_BLUE)A_GiveInventory("BlueCard");
        }fail;
    }
}
class HDUPKAlwaysGive:HDActor abstract{
    class<inventory> toallplayers;property toallplayers:toallplayers;
    string msgtoall;property msgtoall:msgtoall;
    sound pickupsound;property pickupsound:pickupsound;
    default{
        hdupkalwaysgive.toallplayers "";
        hdupkalwaysgive.msgtoall "";
        radius 8; height 10;
    }
    override void Tick(){
        super.Tick();
        if(!isfrozen()){
            blockthingsiterator it=blockthingsiterator.create(self,36);
            for(int i=0;i<MAXPLAYERS;i++){
                if(!playeringame[i])continue;
                actor itt=players[i].mo;
                if(
                    !!itt
                    &&!!itt.player
                    &&(players[i].cmd.buttons&BT_USE)
                    &&itt.health>0
                    &&distance2dsquared(itt)<(56*56)
                    &&abs((pos.z+height*0.5)-(itt.pos.z+itt.height*0.5))<56
                    &&(
                        special
                        ||!isrepeating(itt)
                    )
                    &&checksight(itt)
                ){
                    OnGrab(itt);
                    A_CallSpecial(special,args[0],args[1],args[2],args[3],args[4]);
                    special=0;
                    break;
                }
            }
        }
    }
    virtual bool IsRepeating(actor other){
        return other.findinventory(toallplayers);
    }
    virtual void OnGrab(actor grabber){
        setstatelabel("grabbed");
        if(toallplayers!=""){
            for(int i=0;i<MAXPLAYERS;i++){
                if(!playeringame[i])continue;
                let ppp=players[i].mo;
                if(
                    ppp
                    &&ppp.isfriend(grabber)  //actually pointless since you have all the keys in DM anyway
                ){
                    ppp.A_GiveInventory(toallplayers);
                    if(msgtoall!="")ppp.A_Log(msgtoall,true);
                }
            }
        }
    }
}
class HDKeyLight:PointLight{
    override void tick(){
        if(!target)destroy();
        else{
            args[3]=(target.frame)?32:8;
            setorigin(target.pos,true);
        }
    }
}
class HDRedKey:HDUPKAlwaysGive replaces RedCard{
    string ltpkmsg;property ltpkmsg:ltpkmsg;
    default{
        hdupkalwaysgive.toallplayers "RedCard";
        hdupkalwaysgive.msgtoall "$PICK_REDKEY";
        hdupkalwaysgive.pickupsound "keys/redcard";
        HDRedKey.ltpkmsg "$PICK_LT_REDKEY";
        height 18;
    }
    override void PostBeginPlay(){
        super.PostBeginPlay();
        if(HDMath.PlayingLotansTomb()){
            msgtoall=ltpkmsg;
        }
        actor lite=spawn("HDKeyLight",pos,ALLOW_REPLACE);
        lite.target=self;
        if(HDYellowKey(self)){
            lite.args[0]=128;
            lite.args[1]=128;
            lite.args[2]=0;
        }else if(HDBlueKey(self)){
            lite.args[0]=64;
            lite.args[1]=64;
            lite.args[2]=128;
        }else{
            lite.args[0]=256;
            lite.args[0]=64;
            lite.args[0]=64;
        }
    }
    states{
    spawn:
        RKEY A 0;
    spawn1:
        #### ABABABAB 2;
        #### ABABABABABABABAB 3;
        #### ABABAB 6;
        ---- A 0 A_Jump(256,"spawn2");
    spawn2:
        ---- A 1{
            frame=!frame?1:0;
            A_SetTics(random(2,30)*3);
        }
        loop;
    grabbed:
        ---- A 0{
            if(target)angle=angleto(target);
            A_StartSound(pickupsound,12);
        }goto spawn1;
    }
}
class HDBlueKey:HDRedKey replaces BlueCard{
    default{
        hdupkalwaysgive.toallplayers "BlueCard";
        hdupkalwaysgive.msgtoall "$PICK_BLUEKEY";
        hdupkalwaysgive.pickupsound "keys/bluecard";
        HDRedKey.ltpkmsg "$PICK_LT_BLUEKEY";
    }
    states{
    spawn:
        BKEY A 0;
        goto spawn1;
    }
}
class HDYellowKey:HDRedKey replaces YellowCard{
    default{
        hdupkalwaysgive.toallplayers "YellowCard";
        hdupkalwaysgive.msgtoall "$PICK_YELLOWKEY";
        hdupkalwaysgive.pickupsound "keys/yellowcard";
        HDRedKey.ltpkmsg "$PICK_LT_YELLOWKEY";
    }
    states{
    spawn:
        YKEY A 0;
        goto spawn1;
    }
}
class HDRedSkull:HDUPK replaces RedSkull{
    default{
        scale 0.6;
		radius 6;
		renderstyle "translucent";
		alpha 0.75;
		missiletype "RedSkull";
		hdupk.pickupmessage "$PICK_REDSKULL";
    }
	override void A_HDUPKGive(){
		picktarget.A_GiveInventory(missilename);
		picktarget.damagemobj(self,self,1,"balefire");
		picktarget.A_Log(pickupmessage,true);
		IsMoving.Give(picktarget,99);
		setstatelabel("effect");
	}
    states{
    spawn:
        RSKU AB 1 light("REDKEY") A_SetTics(random(1,6));
        loop;
    effect:
		#### ABAB 1 bright;
		---- A 0 A_StartSound("brain/cube",666,CHANF_LOCAL);
		#### ##### 1 A_SpawnItemEx("HDSmoke",0,0,0,random(4,0),random(-2,2),random(1,3),0,SXF_NOCHECKPOSITION);
		---- A 0 A_Jump(256,"spawn");
    }
}
class HDBlueSkull:HDRedSkull replaces BlueSkull{
    default{
        missiletype "BlueSkull";
		hdupk.pickupmessage "$PICK_BLUESKULL";
    }
    states{
    spawn:
        BSKU AB 1 light("HEALTHPOTION") A_SetTics(random(1,3));
        loop;
    }
}
class HDYellowSkull:HDRedSkull replaces YellowSkull{
    default{
        missiletype "YellowSkull";
		hdupk.pickupmessage "$PICK_YELLOWSKULL";
    }
    states{
    spawn:
        YSKU AB 1 light("YELLOWKEY") A_SetTics(random(1,3));
        loop;
    }
}


