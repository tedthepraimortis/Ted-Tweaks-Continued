// ------------------------------------------------------------
// The cause of - and solution to -
// ------------------------------------------------------------

extend class HDPlayerPawn{
	array<HDPickup> OverlayGivers;
	void GetOverlayGivers(out out array<HDPickup> OverlayGivers){
		OverlayGivers.clear();
		for(let item=inv;item!=NULL;item=item.inv){
			let hp=HDPickup(item);
			if(
				!hp
				||!hp.overlaypriority
			)continue;
			bool inserted=false;
			for(int i=0;i<OverlayGivers.size();i++){
				int checkthis=hp.overlaypriority;
				int checkthat=OverlayGivers[i].overlaypriority;
				if(checkthis>=checkthat){
					OverlayGivers.insert(i,hp);
					inserted=true;
					break;
				}
			}
			if(!inserted)OverlayGivers.push(hp);
		}
	}

	//goes through all ammo, checks their lists, dumps if not found
	void PurgeUselessAmmo(bool take=false){
		array<inventory> items;items.clear();
		for(inventory item=inv;item!=null;item=!item?null:item.inv){
			let thisitem=hdpickup(item);
			if(thisitem&&!thisitem.isused())items.push(item);
		}
		int iz=items.size();
		if(!iz)return;
		double aang=angle;
		double ch=20;
		bool multi=iz>1;
		if(multi)angle-=iz*ch*0.5;
		while(items.size()>0){
			if(take)A_TakeInventory(items[0].getclass(),items[0].amount);
			else A_DropInventory(items[0].getclass(),items[0].amount);
			items.delete(0);
			if(multi)angle+=ch;
		}
		if(multi)angle=aang;
	}
}

//Specially handled ammo dropping
extend class HDHandlers{
	//goes through all ammo, checks their lists, dumps if not found
	void PurgeUselessAmmo(hdplayerpawn ppp){
		if(!!ppp)ppp.PurgeUselessAmmo(false);
	}
	//drops one or more units of your selected weapon's ammo
	void DropOne(hdplayerpawn ppp,playerinfo player,int amt){
		if(!ppp||ppp.health<1)return;
		let cw=hdweapon(player.readyweapon);
		if(cw)cw.DropOneAmmo(amt);
		else PurgeUselessAmmo(ppp);
	}
	//strips armour
	void ChangeArmour(hdplayerpawn ppp){
        let inva=HDPickup(ppp.findinventory("GarrisonArmour"));
		let invb=HDPickup(ppp.findinventory("BattleArmour"));
		if(invb){
			if(ppp.CheckStrip(ppp,invb)){
				string msg=(Stringtable.Localize("$ARMOUR_REMOVE")..invb.gettag()..".");
				msg.replace("$TAG_GARRISONARMOUR",Stringtable.Localize("$TAG_GARRISONARMOUR"));
				msg.replace("$TAG_BATTLEARMOUR",Stringtable.Localize("$TAG_BATTLEARMOUR"));
				ppp.A_Log(msg,true);
				ppp.dropinventory(invb);
			}
			return;
		}else if(inva)ppp.UseInventory(inva);
		else ppp.CheckStrip(ppp,ppp);
		ppp.CheckStrip(ppp,ppp,silent:true);
	}
}

