nstKIDSComponents ;NST - KIDS Utilities ; 07 Apr 2017 10:30 PM
 ;;
 ;;	Author: Nikolay Topalov
 ;;
 ;;	Copyright 2014-2017 Nikolay Topalov
 ;;
 ;;	Licensed under the Apache License, Version 2.0 (the "License");
 ;;	you may not use this file except in compliance with the License.
 ;;	You may obtain a copy of the License at
 ;;
 ;;	http://www.apache.org/licenses/LICENSE-2.0
 ;;
 ;;	Unless required by applicable law or agreed to in writing, software
 ;;	distributed under the License is distributed on an "AS IS" BASIS,
 ;;	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 ;;	See the License for the specific language governing permissions and
 ;;	limitations under the License.
 ;;
 Q
 ;
 ;##### Split a major build to mini builds and export them.
 ; 
 ; Creates mini builds with one KIDS component in it.
 ; User is prompted to enter a build (master build). 
 ; The master build includes all components (RPCs, DDs, routines) and KIDS comments. 
 ; User has to provide as well an export directory where the KIDS files will be exported.
 ; DDs, RPCs, etc. are exported to subfolder \KIDS_Components\ and the routines to subfolder \Routines\
 ; 
 ; The mini KIDS builds naming convention is patch*suffix*componentIEN.
 ;
 ; e.g.,
 ;
 ; If the master build selected is MAG*3.0*106, then the mini builds for RPCs are named MAG*3.0*106*RPC*nnn,
 ; where nnn is the IEN of the RPC in REMOTE PROCEDURE file (#8994). The exported file name is RPC_abcd.KID,
 ; where abcd is the RPC name.
 ; The mini builds for DDs are named MAG*3.0*106*DD*fff where fff is the FileMan file number.
 ; The exported file name is DD_fff.KID where fff is the FileMan file number.
 ;
 ; The file names of the routines are routineName.m or routineName.RTN, where "routineName" is the routine name.
 ; 
 ; When pDeleteOnly flag is set to 1 the split function only deletes the mini builds.
 ;
 ; Input Parameters
 ; ================
 ; pDeleteOnly = 0|1 - only delete mini builds for a major build
 ;
split(pDeleteOnly) ;
 S pDeleteOnly=$G(pDeleteOnly)
 N DIC,I,Y,X
 N buildIEN,buildName,miniBuildName
 N componentName,componentsPath,routinesPath,exportPath,file,suffix,tmp
 N builds,cnt,ien,RY
 ;
 ; get build to split
 S DIC="^XPD(9.6,",DIC(0)="AEMQZ" D ^DIC I Y'>0 Q
 S buildName=$P(Y,"^",2) ; major build name e.g., MAG*3.0*106
 S buildIEN=+Y ; major build IEN e.g., 5896
 ;
 ; split data dictionaries
 S cnt=0 ; mini builds counter
 S file=""  ; FileMan file number
 F  S file=$O(^XPD(9.6,buildIEN,4,"B",file)) Q:file=""  D
 . S suffix="DD*"_file ; mini builds name suffix
 . S miniBuildName=buildName_"*"_suffix  ; e.g., MAG*3.0*106*DD*2006.15
 . D deleteBuild(.RY,miniBuildName) ; delete the mini build
 . Q:pDeleteOnly   ; just delete the mini build, do not export
 . D createBuildDD(.RY,buildIEN,file,miniBuildName)  ; create a mini build definition for a DD
 . I '$$isOK^nstKIDSUtil2(RY) W !,RY Q  ; check for error and quit
 . S cnt=cnt+1
 . S builds(cnt)=$$getResultValue^nstKIDSUtil2(RY)_U_miniBuildName_U_U_0  ; e.g., 7905^MAG*3.0*106*DD*2006.1^^0
 . Q
 ;
 ; Create mini builds for Kernel components (routines are excluded)
 F file=.4,.401,.402,.403,.5,.84,3.6,3.8,9.2,19,19.1,101,409.61,771,870,8989.51,8989.52,8994 D
 . S componentName=""
 . F  S componentName=$O(^XPD(9.6,buildIEN,"KRN",file,"NM","B",componentName)) Q:componentName=""  D
 . . S ien=$O(^XPD(9.6,buildIEN,"KRN",file,"NM","B",componentName,""))
 . . Q:$P(^XPD(9.6,buildIEN,"KRN",file,"NM",ien,0),"^",3)=1  ; skip delete at site. It will be included in the build manifest
 . . S tmp=$S((file=.4)!(file=.401)!(file=.402):$P(componentName,"    ",1),1:componentName)
 . . S ien=$$componentIEN^nstKIDSUtil1(file,tmp)
 . . I 'ien W !,componentName," DOES NOT EXIST IN FILE #"_file Q
 . . S suffix=$$suffix^nstKIDSUtil1(file)_ien  ; KEY*123
 . . S miniBuildName=buildName_"*"_suffix
 . . D deleteBuild(.RY,miniBuildName) ; delete the mini build
 . . Q:pDeleteOnly   ; delete only the mini build, do not export
 . . D createBuildComponent(.RY,buildIEN,file,componentName,miniBuildName)  ; create a mini build definition for a Kernel component
 . . I '$$isOK^nstKIDSUtil2(RY) W !,RY Q  ; check for error and quit
 . . S cnt=cnt+1
 . . S builds(cnt)=$$getResultValue^nstKIDSUtil2(RY)_U_miniBuildName_U_U_0  ; e.g., 7905^MAG*3.0*106*DD*2006.1^^0
 . . Q
 . Q
 Q:pDeleteOnly  ; quit if delete only flag is set
 ;
 S exportPath=$$getPath^nstKIDSUtil2() ; get path of the export
 Q:exportPath=""
 ;
 S componentsPath=$$DEFDIR^%ZISH(exportPath_"KIDS_Components")
 D transportComponents^nstKIDSComponents(.builds,componentsPath)  ; export Kernel components
 ;
 S routinesPath=$$DEFDIR^%ZISH(exportPath_"Routines")
 D transportRoutines^nstKIDSComponents(buildIEN,routinesPath,1) ; export routines
 ;
 Q
 ;
 ;+++++ Delete a build by build name 
 ;
 ; Input Parameters
 ; ================
 ; pBuildName = Name of the build to be deleted
 ;
 ; Return Value
 ; ============= 
 ; RY = 0 
deleteBuild(RY,pBuildName) ; Delete a build by build name
 K RY
 N X,DA,DIK
 D FIND^DIC(9.6,"","@;IX","PQ",pBuildName,"1","B","","","X")
 I $D(X("DILIST","1",0)) D
 . ; delete the record
 . S DIK=$$ROOT^DILFD(9.6)
 . S DA=+X("DILIST","1",0)
 . D ^DIK
 . Q 
 S RY=$$ok^nstKIDSUtil2()
 Q
 ;
 ;
 ;+++++ Create a new record in BUILD file (#9.6) for a Data Dictionary
 ;
 ; Input Parameters
 ; ================
 ; pBuildIEN      = Master build IEN
 ; pFile          = FileMan file to be included in the mini build
 ; pMiniBuildName = mini build name
 ; 
 ; Return Values
 ; =============
 ; if error RY = failure status ^ Error message^
 ; if success RY = success status ^^ mini build IEN
 ;  
createBuildDD(RY,pBuildIEN,pFile,pMiniBuildName) ; create a new record in BUILD file (#9.6) for a DD
 K RY
 N iens,FDA,NIEN,NXE,miniBuildIEN,tmp
 ;
 D createBuild^nstKIDSComponents(.RY,pBuildIEN,pMiniBuildName)
 Q:'$$isOK^nstKIDSUtil2(RY) ; check for error and quit
 S miniBuildIEN=$$getResultValue^nstKIDSUtil2(RY)
 ;
 ; Add the file to the new mini build
 K FDA,NIEN,NXE
 S iens="+1,"_miniBuildIEN_","
 S FDA(9.64,iens,.01)=pFile
 S NIEN(1)=pFile
 ;
 D UPDATE^DIE("S","FDA","NIEN","NXE")
 ;
 I $D(NXE("DIERR")) D  Q
 . N DA,DIK
 . D MSG^DIALOG("A",.tmp,245,5,"NXE")
 . S RY=$$setResultError^nstKIDSUtil2("Error adding to BUILD file (#9.6) "_tmp(1)) Q
 . ; delete data
 . S DIK=$$ROOT^DILFD(9.6)
 . S DA=miniBuildIEN
 . D ^DIK
 . Q
 ;
 ; Merge all DD from the major to the mini build
 M ^XPD(9.6,miniBuildIEN,4,"APDD",pFile)=^XPD(9.6,pBuildIEN,4,"APDD",pFile)
 M ^XPD(9.6,miniBuildIEN,4,pFile)=^XPD(9.6,pBuildIEN,4,pFile)
 ; 
 S RY=$$setOKValue^nstKIDSUtil2(miniBuildIEN)  ; set the new mini build IEN and quit
 Q
 ;
 ;+++++ Create a new record in BUILD file (#9.6) for a Kernel component
 ;
 ; Input Parameters
 ; ================
 ; pBuildIEN      = Master build IEN
 ; pFile          = Kernel component file (e.g. for  RPC - 8994, Options - 19, Security key - 19.1 etc.)
 ; pComponentName = Component name that needs to have a new mini build
 ; pMiniBuildName = mini build name
 ; 
 ; Return Values
 ; =============
 ; if error RY = failure status ^ Error message^
 ; if success RY = success status ^^ mini build IEN
 ;
createBuildComponent(RY,pBuildIEN,pFile,pComponentName,pMiniBuildName) ;  create a new record in BUILD file (#9.6) for a Kernel component
 K MAGRY
 N componentIEN,iens,FDA,NIEN,NXE,miniBuildIEN
 N OPTIEN
 ;
 D createBuild^nstKIDSComponents(.RY,pBuildIEN,pMiniBuildName)
 Q:'$$isOK^nstKIDSUtil2(RY) ; check for error and quit
 S miniBuildIEN=$$getResultValue^nstKIDSUtil2(RY)
 ;
 K FDA,NIEN,NXE
 S iens="+1,"_pFile_","_miniBuildIEN_","
 S FDA(9.68,iens,.01)=pComponentName
 D UPDATE^DIE("S","FDA","NIEN","NXE")
 ;
 I $D(NXE("DIERR")) D  Q
 . N DIK,DA
 . D MSG^DIALOG("A",.tmp,245,5,"NXE")
 . S RY=$$setResultError^nstKIDSUtil2("Error adding to BUILD file (#9.6) "_tmp(1)) Q
 . ; delete data
 . S DIK=$$ROOT^DILFD(9.6)
 . S DA=miniBuildIEN
 . D ^DIK
 . Q
 ;
 S componentIEN=$O(^XPD(9.6,pBuildIEN,"KRN",pFile,"NM","B",pComponentName,""))
 M ^XPD(9.6,miniBuildIEN,"KRN",pFile,"NM",NIEN(1))=^XPD(9.6,pBuildIEN,"KRN",pFile,"NM",componentIEN)
 S RY=$$setOKValue^nstKIDSUtil2(miniBuildIEN)  ; set the new mini build IEN and quit
 Q
 ;
 ;+++++ Create a new record in BUILD file (#9.6)
 ;
 ; Input Parameters
 ; ================
 ; pbuildIEN      = Master build IEN
 ; pMiniBuildName = mini build name
 ; 
 ; Return Values
 ; =============
 ; if error RY = failure status ^ Error message^
 ; if success RY = success status ^^ mini build IEN
createBuild(RY,pBuildIEN,pMiniBuildName)
 K RY
 N iens,FDA,NIEN,NXE,miniBuildIEN,tmp
 S iens="?+1,"
 ;
 S FDA(9.6,iens,.01)=pMiniBuildName ; Build Name
 S FDA(9.6,iens,.02)=$P($$NOW^XLFDT,".") ; DATE DISTRIBUTED
 S FDA(9.6,iens,1)=$$GET1^DIQ(9.6,pBuildIEN,1,"I")  ; PACKAGE FILE LINK
 S FDA(9.6,iens,2)=0 ; 0 - Single package TYPE
 S FDA(9.6,iens,5)=$$GET1^DIQ(9.6,pBuildIEN,5,"I")  ; TRACK PACKAGE NATIONALLY
 ;
 D UPDATE^DIE("S","FDA","NIEN","NXE")
 ;
 I $D(NXE("DIERR")) D  Q
 . D MSG^DIALOG("A",.tmp,245,5,"NXE")
 . S RY=$$setResultError^nstKIDSUtil2("Error adding to BUILD file (#9.6) "_tmp(1)) Q
 . Q
 S miniBuildIEN=NIEN(1)    ; IEN of the new record (mini build)
 D NEW^XPDE(miniBuildIEN)  ; populate default values for the new mini build
 S RY=$$setOKValue^nstKIDSUtil2(miniBuildIEN)  ; set the new mini build IEN and quit
 Q
 ;
 ;+++++ Transport each build in BLDS array to a file
 ;
 ; Input Parameters
 ; ================
 ; pBuilds     = Array with builds IEN in BUILD file (#9.6)
 ; pExportPath = Export path
transportComponents(pBuilds,pExportPath) ; Transport each build in BLDS array to a file
 I $G(pExportPath)="" W !,"Error: Export path is not provided" Q
 ;
 N DIRUT,DIR,POP,Y,X
 N XPDH,XPDT
 N cnt,buildIEN
 ;
 D makeDirectory^nstKIDSUtil2(pExportPath) ; make a directory
 ;
 S DIR(0)="F^3:80",DIR("A")="Header Comment",DIR("?")="Enter a comment between 3 and 80 charaters."
 D ^DIR I $D(DIRUT) S POP=1 Q
 S XPDH=Y
 ;
 S cnt=""
 F  S cnt=$O(pBuilds(cnt)) Q:cnt=""  D
 . S buildIEN=$P(pBuilds(cnt),"^")
 . K XPDT
 . S XPDT=1
 . S XPDT(1)=pBuilds(cnt)   ; Build IEN in file BUILD (#9.6)
 . S XPDT("DA",buildIEN)=1  ; Build IEN
 . D exportBuild(.XPDT,XPDH,pExportPath)
 . L -^XPD(9.6,buildIEN)
 . Q
 Q
 ;
 ;+++++ Export a mini KIDS build
 ;       
 ; Input Parameters
 ; ================
 ; XPDT        = Array with build IEN
 ; XPDH        = KIDS header comment
 ; pExportPath = Export path
 ;
exportBuild(XPDT,XPDH,pExportPath) ; Export a mini KIDS build
 N fileName,suffix
 N PRFXIEN,PRFXNM,FIL,%ZIS,POP,IOP,%,X,Y
 N XPDA,XPDGREF,XPDERR,XPDFMSG,XPDGP,XPDH1,XPDHD,XPDNM,XPDSEQ,XPDSIZ,XPDSIZA,XPDTP,XPDVER
 N XMDUN,XMDUZ,XMZ
 ;
 ; The code below is a copy from XPDT routine
 F XPDT=1:1:XPDT S XPDA=XPDT(XPDT),XPDNM=$P(XPDA,U,2) D  G:$D(XPDERR) ABORT^XPDT
 . S suffix=$P(XPDNM,"*",$L(XPDNM,"*")-1,$L(XPDNM,"*"))  ; get suffix e.g., KEY*123
 . S fileName=$$exportNameBySuffix^nstKIDSUtil1(suffix) ; get build file name  KEY_MAG_CAPTURE
 . S:fileName="" fileName=$TR(XPDNM,".","_")_".KID"
 . S FIL=$TR(pExportPath_fileName,"*","_")
 . D ^%ZISC
 . S %ZIS="",%ZIS("HFSNAME")=FIL,%ZIS("HFSMODE")="W",IOP="HFS"
 . S (XPDSIZ,XPDSIZA)=0
 . S XPDSEQ=1
 . D ^%ZIS I POP W !!,"**Incorrect Host File name** -> ",%ZIS("HFSNAME"),!,$C(7) Q
 . ;write date and comment header
 . S XPDHD="KIDS Distribution saved on "_$$HTE^XLFDT($H)
 . U IO W $$SUM^XPDT(XPDHD),!,$$SUM^XPDT(XPDH),!
 . S XPDFMSG=1 ; Do not Send mail to forum of routines in HFS.
 . ;U IO(0) is to insure I am writing to the terminal
 . U IO(0)
 .W !?5,XPDNM,"..." S XPDGREF="^XTMP(""XPDT"","_+XPDA_",""TEMP"")"
 .;if using current transport global, run pre-transp routine and quit
 .I $P(XPDA,U,3) S XPDA=+XPDA D PRET^XPDT Q
 .;if package file link then set XPDVER=version number^package name
 .S XPDA=+XPDA,XPDVER=$S($P(^XPD(9.6,XPDA,0),U,2):$$VER^XPDUTL(XPDNM)_U_$$PKG^XPDUTL(XPDNM),1:"")
 .;Inc the Build number
 .S $P(^XPD(9.6,XPDA,6.3),U)=$G(^XPD(9.6,XPDA,6.3))+1
 .K ^XTMP("XPDT",XPDA)
 .;GLOBAL PACKAGE
 .I $D(XPDGP) D  S XPDT=1 Q
 ..;can't send global package in packman message
 ..I $G(XPDTP) S XPDERR=1 Q
 ..;verify global package
 ..I '$$GLOPKG^XPDV(XPDA) S XPDERR=1 Q
 ..;get Environment check and Post Install routines
 ..F Y="PRE","INIT" I $G(^XPD(9.6,XPDA,Y))]"" S X=^(Y) D
 ...S ^XTMP("XPDT",XPDA,Y)=X,X=$P(X,U,$L(X,U)),%=$$LOAD^XPDTA(X,"0^")
 ..D BLD^XPDTC,PRET^XPDT
 .F X="DD^XPDTC","KRN^XPDTC","QUES^XPDTC","INT^XPDTC","BLD^XPDTC" D @X Q:$D(XPDERR)
 .D:'$D(XPDERR) PRET^XPDT
 . ;
 . D GO^XPDT
 Q
 ;
 ;+++++  Export routines included in a build (patch)
 ;       (for internal use)  
 ;       
 ; Input Parameters
 ; ================
 ; pBuildIEN     = the IEN of a record in BUILD file (#9.6) 
 ; pExportPath   = the export directory
 ; pExportFormat = the export format
 ;                   0 - Cache %RO (not implemented)
 ;                   1 - plain text
 ;
transportRoutines(pBuildIEN,pExportPath,pExportFormat) ; Export routines included in a build (patch)  
 N DIC,Y,X
 N routine,routines
 ;
 I pBuildIEN'>0 D  ; If pBuildIEN is not defined prompt user to provide a build 
 . S DIC="^XPD(9.6,",DIC(0)="AEMQZ" D ^DIC I Y'>0 Q
 . S pBuildIEN=+Y ; build IEN
 . Q
 ;
 S pExportFormat=$G(pExportFormat,1) ; Set default export format
 I (pExportFormat'=1) W !,"Export format ",pExportFormat," is not implemented yet" Q  ; quit
 ;
 D makeDirectory^nstKIDSUtil2(pExportPath) ; make a directory
 ;
 S routine=""
 F  S routine=$O(^XPD(9.6,pBuildIEN,"KRN",9.8,"NM","B",routine)) Q:routine=""  D
 . S ien=$O(^XPD(9.6,pBuildIEN,"KRN",9.8,"NM","B",routine,""))
 . Q:$P(^XPD(9.6,pBuildIEN,"KRN",9.8,"NM",ien,0),"^",3)=1  ; skip delete at site. It will be included in the build manifest
 . S routines(routine)=""
 . Q
 I pExportFormat=1 D exportRoutinesPlain(.routines,pExportPath) ; export the routines
 Q
 ;
 ;+++++ Output routines in plain format
 ;
 ; Input Parameters
 ; ================
 ; .pRoutines   = array with routine names
 ;  pExportPath = export directory
exportRoutinesPlain(pRoutines,pExportPath)  ;
 N IO
 N DIF,II,SRC,X,XCNP,routine
 N %ZIS,XPDSIZ,XPDSIZA,XPDSEQ,POP
 ;
 S routine=""
 F  S routine=$O(pRoutines(routine)) Q:routine=""  D
 . S %ZIS="",%ZIS("HFSNAME")=pExportPath_routine_".m",%ZIS("HFSMODE")="W",IOP="HFS"
 . S (XPDSIZ,XPDSIZA)=0
 . S XPDSEQ=1
 . D ^%ZIS I POP W !!,"**Incorrect Host File name** -> ",pExportPath_routine_".m",!,$C(7) Q
 . U IO
 . K SRC 
 . S DIF="SRC(",XCNP=0  ; 02/06/2014 Use VistA call to load the routine in SCR variable
 . S X=routine
 . X ^%ZOSF("LOAD")
 . S II=""
 . F  S II=$O(SRC(II)) Q:II=""  S X=$G(SRC(II,0)) W:II'=1 ! W X ; Print a line
 . D ^%ZISC
 . U 0
 . Q
 Q
 ;
exportRoutinesPlainNamespace(pNamespace,pExportPath) 
 N X,routines
 S X=pNamespace
 F  S X=$O(^DIC(9.8,"B",X)) Q:X'[pNamespace  S routines(X)="" 
 D exportRoutinesPlain(.routines,pExportPath)  ;
 Q