//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//       _   ___     __            __  ___  _                               //
//      | | / (_)___/ /___ _____ _/ / / _ \(_)__ ___ ________ ________      //
//      | |/ / / __/ __/ // / _ `/ / / // / (_-</ _ `/ __/ _ `/ __/ -_)     //
//      |___/_/_/  \__/\_,_/\_,_/_/ /____/_/___/\_, /_/  \_,_/\__/\__/      //
//                                             /___/                        //
//                                                                          //
//                                        _                                 //
//                                        \`*-.                             //
//                                         )  _`-.                          //
//                                        .  : `. .                         //
//                                        : _   '  \                        //
//                                        ; *` _.   `*-._                   //
//                                        `-.-'          `-.                //
//                                          ;       `       `.              //
//                                          :.       .        \             //
//                                          . \  .   :   .-'   .            //
//                                          '  `+.;  ;  '      :            //
//                                          :  '  |    ;       ;-.          //
//                                          ; '   : :`-:     _.`* ;         //
//       Remote System - 160105.1        .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2014 - 2015 Nandana Singh, Jessenia Mocha, Alexei Maven,  //
//  Master Starship, Wendy Starfall, North Glenwalker, Ray Zopf, Sumi Perl, //
//  Kire Faulkes, Zinn Ixtar, Builder's Brewery, Romka Swallowtail et al.   //
// ------------------------------------------------------------------------ //
//  This script is free software: you can redistribute it and/or modify     //
//  it under the terms of the GNU General Public License as published       //
//  by the Free Software Foundation, version 2.                             //
//                                                                          //
//  This script is distributed in the hope that it will be useful,          //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0        //
// ------------------------------------------------------------------------ //
//  This script and any derivatives based on it must remain "full perms".   //
//                                                                          //
//  "Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions   //
//  in Second Life(R), OpenSimulator and the Metaverse.                     //
//                                                                          //
//  If these platforms should allow more fine-grained permissions in the    //
//  future, then "full perms" will mean the most permissive possible set    //
//  of permissions allowed by the platform.                                 //
// ------------------------------------------------------------------------ //
//         github.com/OpenCollar/opencollar/tree/master/src/remote          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

//merged HUD-menu, HUD-leash and HUD-rezzer into here June 2015 Otto (garvin.twine)

string g_sVersion = "160105.1";
string g_sFancyVersion = "¹⁶⁰¹⁰⁵⋅¹";
integer g_iUpdateAvailable;
key g_kWebLookup;

list g_lPartners = [];
list g_lNewPartnerIDs;

//  list of hud channel handles we are listening for, for building lists
list g_lListeners;

string g_sMainMenu = "Main";

//  Notecard reading bits
string  g_sCard = ".partners";
key     g_kCardID = NULL_KEY;
key     g_kLineID;
integer g_iLineNr;

integer g_iListener;
integer g_iCmdListener;
integer g_iChannel = 7;

key g_kUpdater;
integer g_iUpdateChan = -7483210;

//  save cmd here while we give the sub menu to decide who to send it to
string g_sPendingCmd;

//  MESSAGE MAP
integer CMD_TOUCH            = 100;

integer MENUNAME_REQUEST     = 3000;
integer MENUNAME_RESPONSE    = 3001;
integer SUBMENU              = 3002;

integer DIALOG               = -9000;
integer DIALOG_RESPONSE      = -9001;
integer DIALOG_TIMEOUT       = -9002;

integer CMD_UPDATE    = 10001;

string UPMENU          = "BACK";

string g_sListPartners  = "List";
string g_sRemovePartner    = "Remove";
//string list   = "Reload Menu";
string g_sScanPartners     = "Add";
string g_sLoadCard     = "Load";
string g_sPrintPartners    = "Print";
string g_sAllPartners      = "ALL";

list g_lMainMenuButtons = ["MANAGE","Collar","Rezzers","Pose","RLV","Sit","Stand","Leash"];//,"HUD Style"];
list g_lMenus ;

key    g_kRemovedPartnerID;
key    g_kOwner;

//  three strided list of avkey, dialogid, and menuname
key    g_kMenuID;
string g_sMenuType;

integer g_iScanRange        = 20;
integer g_iRLVRelayChannel  = -1812221819;
integer g_iCageChannel      = -987654321;
list    g_lCageVictims;
key     g_kVictimID;
string  g_sRezObject;


/*integer g_iProfiled=1;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}*/

string NameURI(key kID) {
    return "secondlife:///app/agent/"+(string)kID+"/about";
}

integer getPersonalChannel(key kID) {
    integer iChan = -llAbs((integer)("0x"+llGetSubString((string)kID,2,7)) + 1111);
    if (iChan > -10000) iChan -= 30000;
    return iChan;
}

SetCmdListener() {
    llListenRemove(g_iCmdListener);
    g_iCmdListener = llListen(g_iChannel,"",g_kOwner,"");
}

integer InSim(key kID) {
//  check if the AV is logged in and in Sim
    return (llGetAgentSize(kID) != ZERO_VECTOR);
}

SendCmd(key kID, string sCmd) {
    if (InSim(kID)) {
        llRegionSayTo(kID,getPersonalChannel(kID), (string)kID + ":" + sCmd);
    } else {
        llOwnerSay(NameURI(kID)+" is not in this region.");
        //PickPartnerMenu(sCmd);
    }
}

SendAllCmd(string sCmd) {
    integer i;
    for (; i < llGetListLength(g_lPartners); i++) {
        key kID = (key)llList2String(g_lPartners, i);
        if (kID != g_kOwner && InSim(kID)) //Don't expose out-of-sim partners
            SendCmd(kID, sCmd);
    }
}

AddPartner(key kID) {
    if (~llListFindList(g_lPartners,[kID])) return;
    if (kID != NULL_KEY) {//don't register any unrecognised
        g_lPartners+=[kID];//Well we got here so lets add them to the list.
        llOwnerSay("\n\n"+NameURI(kID)+" has been registered.\n");//Tell the owner we made it.
    }
}

RemovePartner(key kID) {
    integer index = llListFindList(g_lPartners,[kID]);
    if (~index) {
        g_lPartners=llDeleteSubList(g_lPartners,index,index);
        if (InSim(kID)) {
            SendCmd(kID, "rm owner "+(string)g_kOwner); // 4.0 command
            SendCmd(kID, "rm trust "+(string)g_kOwner); // 4.0 command
        }
        llOwnerSay(NameURI(kID)+" has been removed from your Owner HUD.");
    }
}

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, string sMenuType) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET,DIALOG,(string)kRCPT+"|"+sPrompt+"|"+(string)iPage+"|"+llDumpList2String(lChoices,"`")+"|"+llDumpList2String(lUtilityButtons,"`"),kID);
    g_kMenuID = kID;
    g_sMenuType = sMenuType;
}

MainMenu(){
    string sPrompt = "\n[http://www.opencollar.at/remote.html OpenCollar Remote] "+g_sFancyVersion;
    if (g_iUpdateAvailable) sPrompt += "\n\nThere is an update available @ [http://maps.secondlife.com/secondlife/Boulevard/50/211/23 The Temple]";
    list lButtons = g_lMainMenuButtons + g_lMenus;
    Dialog(g_kOwner, sPrompt, lButtons, [], 0, g_sMainMenu);
}

ManageMenu() {
    string sPrompt = "\nClick \"Add\" to register your partners!";
    list lButtons = [g_sScanPartners,g_sListPartners,g_sRemovePartner,g_sLoadCard,g_sPrintPartners];
    Dialog(g_kOwner, sPrompt, lButtons, [UPMENU], 0, "ManageMenu");
}

RezzerMenu() {
    Dialog(g_kOwner, "\nMake your choice!\n\nWhen done you will be presented with a list of avatars who can be sat on the thingy.", BuildObjectList(),["BACK"],0,"RezzerMenu");
}

PickPartnerMenu(string sCmd) { // Multi-page menu
    string sPrompt = "\nWho will receive the \""+sCmd+"\" command?";
    list lButtons;
    integer i;
    for (; i < llGetListLength(g_lPartners); i++) {
        if (InSim(llList2Key(g_lPartners,i))) //only show partners you can give commands to
            lButtons += [llList2String(g_lPartners, i)];
    }
    if (!llGetListLength(lButtons)) lButtons = ["-"];
    Dialog(g_kOwner, sPrompt, lButtons, [g_sAllPartners,UPMENU], -1,"PickPartnerMenu");
}

RemovePartnerMenu() {
    Dialog(g_kOwner, "\nWho would you like to remove?\n\nNOTE: This will also revoke your access rights.", g_lPartners, [UPMENU], -1,"RemovePartnerMenu");
}

ConfirmPartnerRemove(key kID) {
    string sPrompt = "\nAre you sure you want to remove "+NameURI(kID)+"?\n\nNOTE: This will also revoke your access rights.";
    Dialog(g_kOwner, sPrompt, ["Yes", "No"], [UPMENU], 0,"RemovePartnerMenu");
}

PickPartnerCmd(string sCmd) {
    integer iLength = llGetListLength(g_lPartners);
    if (!iLength) {
        llOwnerSay("\n\nAdd someone first! I'm not currently managing anyone.\n\nwww.opencollar.at/remote\n");
        return;
    }
    list lNearbyPartners;
    integer i;
    while (i < iLength) {
        key kTemp = llList2Key(g_lPartners,i);
        if (InSim(kTemp))
            lNearbyPartners += kTemp;
        i++;
    }
    iLength = llGetListLength(lNearbyPartners);
    if (iLength > 1) {
        g_sPendingCmd = sCmd;
        PickPartnerMenu(sCmd);
    } else if (iLength == 1) {
        SendCmd(llList2Key(lNearbyPartners,0), sCmd);
    } else
        llOwnerSay("\n\nNone of your partners are nearby.\n");
    lNearbyPartners = [];
}

AddPartnerMenu() {
    string sPrompt = "\nChoose who you want to manage:";
    list lButtons;
    integer index;
    integer iSpaceIndex;
    string sName;
    do {
        lButtons += llList2Key(g_lNewPartnerIDs,index);
    } while (++index < llGetListLength(g_lNewPartnerIDs));
    Dialog(g_kOwner, sPrompt, lButtons, ["ALL",UPMENU], -1,"AddPartnerMenu");
}

RezMenu() {
    string sPrompt = "\nHere is a list of avatars with active RLV relays.\n\nNOTE: If a relay with \"ask mode\" is used they will still have to confirm to be captured.";
    Dialog(g_kOwner, sPrompt, g_lCageVictims, [UPMENU], -1,"RezMenu");
}

StartUpdate() {
    integer pin = (integer)llFrand(99999998.0) + 1;
    llSetRemoteScriptAccessPin(pin);
    llRegionSayTo(g_kUpdater, g_iUpdateChan, "ready|" + (string)pin );
}

list BuildObjectList() {
    list lRezObjects;
    integer i;
    do lRezObjects += llGetInventoryName(INVENTORY_OBJECT,i);
    while (++i < llGetInventoryNumber(INVENTORY_OBJECT));
    return lRezObjects;
}

default {
    state_entry() {
        g_kOwner = llGetOwner();
        g_kWebLookup = llHTTPRequest("https://raw.githubusercontent.com/VirtualDisgrace/Collar/live/web/~remote", [HTTP_METHOD, "GET"],"");
        llSleep(1.0);//giving time for others to reset before populating menu
        if (llGetInventoryKey(g_sCard)) {
            g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
            g_kCardID = llGetInventoryKey(g_sCard);
        }
        g_iListener=llListen(getPersonalChannel(g_kOwner),"",NULL_KEY,""); //lets listen here
        SetCmdListener();

        llMessageLinked(LINK_SET,MENUNAME_REQUEST, g_sMainMenu,"");
        //Debug("started.");
    }
    on_rez(integer iStart) {
        g_kWebLookup = llHTTPRequest("https://raw.githubusercontent.com/VirtualDisgrace/Collar/live/web/~remote", [HTTP_METHOD, "GET"],"");
    }
    
    touch_start(integer iNum) {
        key kID = llDetectedKey(0);
        if ((llGetAttached() == 0)&& (kID==g_kOwner)) {// Dont do anything if not attached to the HUD
            llMessageLinked(LINK_THIS, CMD_UPDATE, "Update", kID);
            return;
        }
        if (kID == g_kOwner) {
//          I made the root prim the "menu" prim, and the button action default to "menu."
            string sButton = (string)llGetObjectDetails(llGetLinkKey(llDetectedLinkNumber(0)),[OBJECT_DESC]);
            if (llSubStringIndex(sButton,"remote")>=0)
                llMessageLinked(LINK_SET, CMD_TOUCH,"hide","");
            else if (sButton == "Menu") MainMenu();
            else PickPartnerCmd(llToLower(sButton));
        }
    }

    listen(integer iChannel, string sName, key kID, string sMessage) {
        if (iChannel == g_iChannel) {
            list lParams = llParseString2List(sMessage, [" "], []);
            string sCmd = llList2String(lParams,0);
            if (sMessage == "menu")
                MainMenu();
            else if (sCmd == "channel") {
                integer iNewChannel = (integer)llList2String(lParams,1);
                if (iNewChannel) {
                    g_iChannel = iNewChannel;
                    SetCmdListener();
                    llOwnerSay("Your new HUD command channel is "+(string)g_iChannel+". Type /"+(string)g_iChannel+"menu to bring up your HUD menu.");
                } else llOwnerSay("Your HUD command channel is "+(string)g_iChannel+". Type /"+(string)g_iChannel+"menu to bring up your HUD menu.");
            }
            else if (llToLower(sMessage) == "help")
                llOwnerSay("\n\nThe manual page can be found [http://www.opencollar.at/remote.html here].\n");
            else if (sMessage == "reset") llResetScript();
        } else if (iChannel == getPersonalChannel(g_kOwner) && llGetOwnerKey(kID) == g_kOwner) {
            if (sMessage == "-.. --- / .... ..- -..") {
                g_kUpdater = kID;
                Dialog(g_kOwner, "\nINSTALLATION REQUEST PENDING:\n\nAn update or app installer is requesting permission to continue. Installation progress can be observed above the installer box and it will also tell you when it's done.\n\nShall we continue and start with the installation?", ["Yes","No"], ["Cancel"], 0, "UpdateConfirmMenu");
            }
        } else if (llGetSubString(sMessage, 36, 40)==":pong") {
            if (!~llListFindList(g_lNewPartnerIDs, [llGetOwnerKey(kID)]) && !~llListFindList(g_lPartners, [llGetOwnerKey(kID)]))
                g_lNewPartnerIDs += [llGetOwnerKey(kID)];
        } else if (iChannel == g_iRLVRelayChannel && llGetSubString(sMessage,0,6) == "locator") {
            if (!~llListFindList(g_lCageVictims, [llGetOwnerKey(kID)])) //prevents double names of avis with more than 1 relay active
                g_lCageVictims += [llGetOwnerKey(kID)];
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_RESPONSE) {
            list lParams = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParams,0) == g_sMainMenu) {
                string sChild = llList2String(lParams,1);
                if (! ~llListFindList(g_lMenus, [sChild]))
                    g_lMenus = llListSort(g_lMenus+=[sChild], 1, TRUE);
            }
            lParams = [];
        }
        else if (iNum == SUBMENU && sStr == "Main") MainMenu();
        else if (iNum == DIALOG_RESPONSE && kID == g_kMenuID) {
            list    lParams = llParseString2List(sStr, ["|"], []);
            string  sMessage    = llList2String(lParams, 1);
            integer i;
            if (g_sMenuType == "ManageMenu") {
                if (sMessage == UPMENU) {
                    MainMenu();
                    return;
                } else if (sMessage == g_sListPartners) { //Lets List out partners
                    //list lTemp;
                    string sText ="\nI'm currently managing:\n";
                    integer iPartnerCount = llGetListLength(g_lPartners);
                    if (iPartnerCount) {
                        i=0;
                        do {
                            if (llStringLength(sText)>950) {
                                llOwnerSay(sText);
                                sText ="";
                            }
                            sText += NameURI(llList2Key(g_lPartners,i))+", " ;
                        } while (++i < iPartnerCount-1);
                        if (iPartnerCount>1)sText += " and "+NameURI(llList2Key(g_lPartners,i));
                        if (iPartnerCount == 1) sText = llGetSubString(sText,0,-3);
                    } else sText += "nobody";
                    llOwnerSay(sText);
                    ManageMenu(); //return to ManageMenu
                } else if (sMessage == g_sRemovePartner) RemovePartnerMenu();
                else if (sMessage == g_sLoadCard) {
                    if (llGetInventoryType(g_sCard) != INVENTORY_NOTECARD) {
                        llOwnerSay("\n\nThe" + g_sCard +" card couldn't be found in my inventory.\n");
                        return;
                    }
                    g_iLineNr = 0;
                    g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
                    ManageMenu();
                } else if (sMessage == g_sScanPartners) {
                     // Ping for auth OpenCollars in the parcel
                     list lAgents = llGetAgentList(AGENT_LIST_PARCEL, []); //scan for who is in the parcel
                     llOwnerSay("Scanning for collars where you have access to.");
                     integer iChannel;
                     for (i=0; i < llGetListLength(lAgents); ++i) {//build a list of who to scan
                        kID = llList2Key(lAgents,i);
                        if (kID != g_kOwner) {
                            if (llGetListLength(g_lListeners) < 60) { // lets not cause "too many listen" error
                                iChannel = getPersonalChannel(kID);
                                g_lListeners += [llListen(iChannel, "", "", "" )] ;
                                llRegionSayTo(kID, iChannel, (string)kID+":ping");
                            }
                        }
                    }
                    llSetTimerEvent(2.0);
                } else if (sMessage == g_sPrintPartners) {
                    if (llGetListLength(g_lPartners)) {
                        string sPrompt = "\n\nEverything below this line can be copied & pasted into a notecard called \".partners\" for backup:\n";
                        llOwnerSay(sPrompt);
                        sPrompt = "\n";
                        for (i=0; i < llGetListLength(g_lPartners); i++) {
                            sPrompt+= "\nid = " + llList2String(g_lPartners, i);
                        }
                        llOwnerSay(sPrompt);
                    } else llOwnerSay("Nothing to print, you need to add someone first.");
                    ManageMenu();
                }
            } else if (g_sMenuType == "RemovePartnerMenu") {
                integer index = llListFindList(g_lPartners, [(key)sMessage]);
                if (sMessage == UPMENU) ManageMenu();
                else if (sMessage == "Yes") {
                    RemovePartner(g_kRemovedPartnerID);
                    ManageMenu();
                } else if (sMessage == "No") ManageMenu();
                else if (~index) {
                    g_kRemovedPartnerID = (key)llList2String(g_lPartners, index);
                    ConfirmPartnerRemove(g_kRemovedPartnerID);
                }
            } else if (g_sMenuType == "PickPartnerMenu") {
                integer index = llListFindList(g_lPartners, [(key)sMessage]);
                if (sMessage == UPMENU) MainMenu();
                else if (sMessage == g_sAllPartners) SendAllCmd(g_sPendingCmd);
                else if (~index) SendCmd(llList2Key(g_lPartners, index), g_sPendingCmd);
            } else if (g_sMenuType == "Main") {
                if (sMessage == "MANAGE") ManageMenu();
                else if (sMessage == "Collar") PickPartnerCmd("menu");
                else if (sMessage == "Rezzers") RezzerMenu();
                else if (sMessage == "HUD Style") llMessageLinked(LINK_SET,SUBMENU,sMessage,kID);
                else if (sMessage == "Sit" || sMessage == "Stand") PickPartnerCmd(llToLower(sMessage)+"now");
                else if (sMessage == "Leash") PickPartnerCmd("leashmenu");
                else if (~llListFindList(g_lMenus,[sMessage])) llMessageLinked(LINK_SET,SUBMENU,sMessage,kID);
                else PickPartnerCmd(llToLower(sMessage));
            } else if (g_sMenuType == "UpdateConfirmMenu") {
                if (sMessage=="Yes") StartUpdate();
                else {
                    llOwnerSay("Installation cancelled.");
                    return;
                }
            } else if (g_sMenuType == "RezzerMenu") {
                    if (sMessage == UPMENU) MainMenu();
                    else { 
                        g_sRezObject = sMessage;
                        llOwnerSay("Scanning for possible \"victims\" within "+(string)g_iScanRange+"m with RLV Relay to sit on your "+g_sRezObject);
                        llSensor("","",AGENT,g_iScanRange,PI);
                    }
                } else if (g_sMenuType == "RezMenu") {
                if (sMessage == UPMENU) {
                    MainMenu();
                    g_lCageVictims = [];
                    return;
                } else {
                    g_kVictimID = (key)sMessage;
                    if (llGetInventoryType(g_sRezObject) == INVENTORY_OBJECT)
                        llRezObject(g_sRezObject,llGetPos() + <3, 3, 1>, ZERO_VECTOR, llGetRot(), 0);
                    else llOwnerSay("\n\nUnable to perform action:\n\nYou do not have any items loaded in your remote.\n");
                    g_lCageVictims = [];
                }
            } else if (g_sMenuType == "AddPartnerMenu") {
                if (sMessage == "ALL") {
                    i=0;
                    key kNewPartnerID;
                    do {
                        kNewPartnerID = llList2Key(g_lNewPartnerIDs,i);
                        if (kNewPartnerID) AddPartner(kNewPartnerID);
                    } while (i++ < llGetListLength(g_lNewPartnerIDs));
                } else if ((key)sMessage)
                    AddPartner(sMessage);
                g_lNewPartnerIDs = [];
                ManageMenu();
            }
        }
    }

    sensor(integer iNumber) {
        g_lCageVictims = [];
        g_lListeners += [llListen(g_iRLVRelayChannel,"","","")];
        integer i;
        do {
            llRegionSayTo(llDetectedKey(i),g_iRLVRelayChannel,"locator,"+(string)llDetectedKey(i)+",!version");
        } while (++i < iNumber);
        llSetTimerEvent(2.0);
    }
    no_sensor(){
        llOwnerSay("nobody found");
    }

//  clear things after ping
    timer() {
        //Debug ("timer expired" + (string)llGetListLength(g_lCageVictims));
        if (llGetListLength(g_lCageVictims)) RezMenu();
        else if (llGetListLength(g_lNewPartnerIDs)) AddPartnerMenu();
        else llOwnerSay("No one is not found");
        llSetTimerEvent(0);
        integer n = llGetListLength(g_lListeners);
        while (n--)
            llListenRemove(llList2Integer(g_lListeners,n));
        g_lListeners = [];
    }

    dataserver(key kRequestID, string sData) {
        if (kRequestID == g_kLineID) {
            if (sData == EOF) { //  notify the owner
                llOwnerSay(g_sCard+" card loaded.");
                return;
            } else if (sData != "") {//  if we are not working with a blank line
                if (llSubStringIndex(sData, "#")) {//  if the line does not begin with a comment
                    integer index = llSubStringIndex(sData, "=");//  find first equal sign
                    if (~index) {//  if line contains equal sign
                        string sName = llToLower(llStringTrim(llGetSubString(sData, 0, index - 1),STRING_TRIM));
                        string sValue = llStringTrim(llGetSubString(sData, index + 1, -1),STRING_TRIM);
                        if (sName == "id") AddPartner((key)sValue);
                    }
                }
            }
            g_kLineID = llGetNotecardLine(g_sCard, ++g_iLineNr);//  read the next line
        }
    }
    
    http_response(key kRequestID, integer iStatus, list lMeta, string sBody) {
        if (kRequestID == g_kWebLookup && iStatus == 200)  {
            if ((float)sBody > (float)g_sVersion) g_iUpdateAvailable = TRUE;
            else g_iUpdateAvailable = FALSE;
        }
    }
    
    object_rez(key kID) {
        llSleep(0.5); // make sure object is rezzed and listens
        llRegionSayTo(kID,g_iCageChannel,"fetch"+(string)g_kVictimID);
    }

    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) {
            if (llGetInventoryKey(g_sCard) != g_kCardID) {
                // the .partners card changed.  Re-read it.
                g_iLineNr = 0;
                if (llGetInventoryKey(g_sCard)) {
                    g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
                    g_kCardID = llGetInventoryKey(g_sCard);
                }
            }
        }
        if (iChange & CHANGED_OWNER) llResetScript();
    }
}
