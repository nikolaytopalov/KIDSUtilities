nstKIDSUtil1 ;NST - KIDS Utilities ; 16 May 2014 10:30 PM
 ;;
 ;;	Author: Nikolay Topalov
 ;;
 ;;	Copyright 2014 Nikolay Topalov
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
componentIEN(pFile,pComponentName) ; return IEN of a component by FileMan file number and component name
 N ien,root
 S root=$$ROOT^DILFD(pFile,,1)
 S ien=$O(@root@("B",pComponentName,""))
 Q ien
 ;
suffix(pFile) ; return suffix for the mini builds by file number
 I pFile=19.1 Q "KEY*" ; Security Key
 I pFile=19 Q "OPT*" ; Option
 I pFile=.4  Q "TPRNT*" ; Print Template
 I pFile=.401 Q "TSORT*" ; Sort Template
 I pFile=.402 Q "TINPT*" ; Input Template
 I pFile=.403 Q "FRM*"  ; FORM
 I pFile=.5 Q "FUN*"  ; Function
 I pFile=.84 Q "DIALOG*" ;Dialogue
 I pFile=3.6 Q "BLT*" ; BULLETIN
 I pFile=3.8 Q "MAIL*" ; Mail Group
 I pFile=9.2 Q "HLP*"  ; HELP FRAME
 I pFile=9.8 Q "RTN" ; ROUTINE
 I pFile=101 Q "PROT*" ; PROTOCOL
 I pFile=409.61 Q "LST*" ; LIST TEMPLATE
 I pFile=771 Q "HL7APP*" ; HL7 Application parameter
 I pFile=870 Q "HL7LL*" ; HL Logical Link
 I pFile=8989.51 Q "PARAMDEF*" ; PARAMETER DEFINITION
 I pFile=8989.52 Q "PARAMTMP*" ; PARAMETER TEMPLATE
 I pFile=8994 Q "RPC*" ; RPCs
 Q ""
 ;
exportNameBySuffix(pSuffix) ; Get export file name by patch name
 ; pSuffix = in format: XYZ*ien,
 ;          where XYZ is the type of the component 
 ;          and ien is the IEN of the component in the corresponding component file
 ;          e.g.,  KEY*567    
 N componentName,fileName,ien,type
 ;
 S type=$P(pSuffix,"*",1)  ; e.g. KEY*567 -> KEY
 S ien=$P(pSuffix,"*",2) ; e.g., KEY*567 -> 567
 ;
 S fileName=""
 ; routines exception
 I type="RTN" D  Q fileName
 . S fileName=$P(pSuffix,"*",2,99)_".RTN"
 . Q
 I type="DD" D
 . S fileName="DD_"_$P(pSuffix,"*",2,99)
 . Q
 I type="TPRNT" D
 . S componentName=$P(^DIPT(ien,0),"^")
 . S fileName="TPRNT_"_componentName
 . Q
 I type="TSORT" D
 . S componentName=$P(^DIBT(ien,0),"^")
 . S fileName="TSORT_"_componentName
 . Q
 I type="TINPT" D
 . S componentName=$P(^DIE(ien,0),"^")
 . S fileName="TINPT_"_componentName
 . Q
 I type="DIALOG" D
 . S componentName=$P(^DI(.84,ien,0),"^")
 . S fileName="DIALOG_"_componentName
 . Q
 I type="MAIL" D
 . S componentName=$P(^XMB(3.8,ien,0),"^")
 . S fileName="MAIL_"_componentName
 . Q
 I type="OPT" D
 . S componentName=$P(^DIC(19,ien,0),"^")
 . S fileName="OPT_"_componentName
 . Q
 I type="KEY" D
 . S componentName=$P(^DIC(19.1,ien,0),"^")
 . S fileName="KEY_"_componentName
 . Q
 I type="PROT" D
 . S componentName=$P(^ORD(101,ien,0),"^")
 . S fileName="PROT_"_componentName
 . Q
 I type="HL7APP" D
 . S componentName=$P(^HL(771,ien,0),"^")
 . S fileName="HL7APP_"_componentName
 . Q
 I type="HL7LL" D
 . S componentName=$P(^HLCS(870,ien,0),"^")
 . S fileName="HL7LL_"_componentName
 . Q
 I type="PARAMDEF" D
 . S componentName=$P(^XTV(8989.51,ien,0),"^")
 . S fileName="PARAMDEF_"_componentName
 . Q
 I type="PARAMTMP" D
 . S componentName=$P(^XTV(8989.52,ien,0),"^")
 . S fileName="PARAMTMP_"_componentName
 . Q
 I type="RPC" D
 . S componentName=$P(^XWB(8994,ien,0),"^")
 . S fileName="RPC_"_componentName
 . Q
 ;
 I fileName="" Q ""
 ;
 Q $TR(fileName," /.*","____")_".KID"
 ;
 ; #### Return export file name
 ;
 ; Input parameters
 ; ================
 ;
 ; pFile          = FileMan number (e.g. 8994)
 ; pComponentName = Component name (e.g. XWB EGCHO STRING)
 ;
exportName(pFile,pComponentName) ; return export file name
 N tmp,ien,suffix
 I pFile=9.8 Q $$exportNameBySuffix^nstKIDSUtil1("RTN*"_pComponentName)  ; Routine (e.g. XWBZ1.RTN)
 I pFile="DD" Q $$exportNameBySuffix^nstKIDSUtil1("DD*"_pComponentName)  ; Data dictionary
 ;
 ; Strip blanks for files .4, .401, .402
 S tmp=$S((pFile=.4)!(pFile=.401)!(pFile=.402):$P(pComponentName,"    ",1),1:pComponentName)
 S ien=$$componentIEN^nstKIDSUtil1(pFile,tmp)
 I 'ien D  Q "Error"
 . U IO(0)
 . W !,pComponentName," DOES NOT EXIST IN FILE #"_pFile
 . U IO
 . Q
 S suffix=$$suffix^nstKIDSUtil1(pFile)_ien  ; KEY*123
 Q $$exportNameBySuffix^nstKIDSUtil1(suffix)
 ;
 ; #### Return component name
 ;
 ; Input parameters
 ; ================
 ;
 ; pFile          = FileMan number (e.g. 8994)
 ; pComponentName = Component name (e.g. XWB EGCHO STRING)
 ;
componentName(pFile,pComponentName) ; return component name
 ; Strip blanks for files .4, .401, .402
 N tmp
 S tmp=$S((pFile=.4)!(pFile=.401)!(pFile=.402):$P(pComponentName,"    ",1),1:pComponentName)
 Q tmp