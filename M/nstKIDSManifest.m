nstKIDSManifest ;NST - KIDS Utilities - KIDS build manifest ; 01 May 2014 10:30 PM
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
 ;##### This utility creates a KIDS build manifest. 
 ; The KIDS build manifest is an XML file that is used by KIDSAssembler.
 ; You can use KIDSAssembler to create KIDS distribution.
 ;
 ;
 ; Input Parameters
 ; ================
 ;   .pBuild
 ;  [ pBuild("buildIEN")   ]  = IEN in BUILD file (#9.6)
 ;  [ pBuild("name")       ]  = patch install name (e.g. MAG*3.0*106)
 ;  [ pBuild("patchName")  ]  = patch name (e.g. KIDS Build Manifest)
 ;
 ; Return value
 ; ============
 ; RY - 0|-1 ^ error message
 ;
createManifest(RY,pBuild) ; Generate XML build definition
 K RY
 ;
 N index,textBuild,textComponents
 N buildIEN,buildName,buildAttributes  ; Build IEN, Name and Attributes
 N exportPath,exportFileName  ; Export path and file name
 ;
 S textBuild="build"
 S textComponents="components"
 ;
 D getBuild^nstKIDSManifest(.RY,.pBuild)    ; get build IEN and name
 I '$$isOK^nstKIDSUtil2(RY) Q  ; quit if build is not provided
 S buildIEN=$$getResultValue^nstKIDSUtil2(RY)
 S pBuild("buildIEN")=buildIEN
 ;
 ; Get export file path
 S exportPath=$$getPath^nstKIDSUtil2() ; Get path of the export
 I exportPath="" D  Q
 . S RY=$$setResultError^nstKIDSUtil2("Export path is not provided.")
 . Q
 ;
 D makeDirectory^nstKIDSUtil2(exportPath)  ; make a file system directory
 ;
 ; Open the build manifest file
 N %ZIS,POP
 D ^%ZISC
 S exportFileName=$TR(exportPath_pBuild("name"),"*.","__")_".xml"
 S %ZIS="",%ZIS("HFSNAME")=exportFileName,%ZIS("HFSMODE")="W",IOP="HFS"
 D ^%ZIS
 I POP D  Q
 . S RY=$$setResultError^nstKIDSUtil2("Incorrect Host File name ",%ZIS("HFSNAME"))
 . W !!,"**Incorrect Host File name** -> ",%ZIS("HFSNAME"),!,$C(7)
 . Q
 ;
 U IO
 ;
 D getBuildAttributes(.pBuild,.buildAttributes)  ; get build attributes
 ;
 ; Write the build manifest
 ;
 W $$XMLHDR^MXMLUTL(),!       ; XML header
 ;
 W !,"<",textBuild            ; begin build
 D writeBuildAttributes^nstKIDSManifest(.buildAttributes)
 W ">"
 ;
 D writeRequiredBuilds^nstKIDSManifest(buildIEN)     ; write required builds 
 ;
 W !,"<",textComponents,">"   ; begin components
 ;
 D writeDataDictionaries^nstKIDSManifest(buildIEN)   ; write Data Dictionaris 
 ;
 D writeKernelComponents^nstKIDSManifest(buildIEN)   ; write Kernel components 
 ;
 W !,"</",textComponents,">"  ; end components
 ;
 W !,"</",textBuild,">"       ; end build
 ;
 D ^%ZISC  ; Close the file
 ;
 W !,"Build manifest "_exportFileName_" has been created."
 S RY=$$setOKValue^nstKIDSUtil2(exportFileName)
 Q
 ;
 ; Get build IEN and attributes
 ; 
 ; Input parameters
 ; ================
 ;  .pBuild
 ; [ pBuild("buildIEN") ] = build IEN
 ; [ pBuild("name")     ] = patch install name, e.g., MAG*3.0*106
 ;
 ; Return value
 ; ============
 ; .RY =     0 ^  ^ Build IEN
 ;       or -1 ^ Error message
 ;
 ; Updated values of pBuild("buildIEN") and pBuild("name")
 ;
getBuild(RY,pBuild) ;
 N buildIEN,buildName
 ;
 S buildIEN=+$G(pBuild("buildIEN"))
 S buildName=$G(pBuild("name"))
 I 'buildIEN,buildName'="" D
 . S buildIEN=+$O(^XPD(9.6,"B",buildName,""))
 . Q
 ;
 I buildIEN'>0 D
 . N DIC,I,Y,X
 . S DIC="^XPD(9.6,",DIC(0)="AEMQZ" D ^DIC I Y'>0 Q
 . S buildIEN=+Y ; build IEN
 . S buildName=$P(Y,"^",2)  ; e.g. MAG*3.0*106
 . Q
 I buildIEN'>0 D  Q
 . S RY=$$setResultError^nstKIDSUtil2("Build is not defined. Verify install name.")
 . Q
 ;
 S pBuild("name")=buildName
 S RY=$$setOKValue^nstKIDSUtil2(buildIEN)
 Q
 ;
 ;+++++ Get build attributes as defined in BUILD file (#9.6)
 ;
 ; Input Parameters
 ; ================
 ;  .pBuild
 ;   pBuild("buildIEN") = build IEN
 ; [ pBuild("exportPath") ]  = export path of the XML file
 ; [ pBuild("patchName")  ]  = patch name (e.g. KIDS Build Manifest)
 ; [ pBuild("name")       ]  = patch install name (e.g. MAG*3.0*106)
 ; 
 ; Return values
 ; =============
 ;  .pAttribute = array with build attributes as defined in BUILD file (#9.6)
 ;
getBuildAttributes(pBuild,pAttribute)  ; get build attributes
 N buildIEN,buildName,buildPatch,buildPatchName,cnt
 N packageIEN,packageVersion,packageVersionIEN
 ;
 S buildIEN=$G(pBuild("buildIEN"))
 Q:buildIEN'>0
 ; 
 S buildName=$G(pBuild("name"))
 S:buildName="" buildName=$P(^XPD(9.6,buildIEN,0),"^",1)  ; e.g., install name (e.g. MAG*3.0*106)
 ;
 S buildPatch=$P(buildName,"*",3)  ; e.g., MAG*3.0*106
 ;
 S buildPatchName=$G(pBuild("patchName"))
 S:buildPatchName="" buildPatchName=$G(^XPD(9.6,buildIEN,1,1,0))  ; Get the first line from the description of the patch e.g., "Version 3.0 Patch 106 - Teledermatology"
 ;
 ; Set build attributes
 S cnt=0
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("name",buildName)
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("patch",buildPatch)
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("patchName",buildPatchName)
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("envCheckRoutine",$$GET1^DIQ(9.6,buildIEN,913))
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("deleteEnvCheckRoutine",$$GET1^DIQ(9.6,buildIEN,913.1))
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("preInstallRoutine",$$GET1^DIQ(9.6,buildIEN,916))
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("deletePreInstalltRoutine",$$GET1^DIQ(9.6,buildIEN,916.1))
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("postInstallRoutine",$$GET1^DIQ(9.6,buildIEN,914))
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("deletePostInstallRoutine",$$GET1^DIQ(9.6,buildIEN,914.1))
 S packageIEN=$$GET1^DIQ(9.6,buildIEN,1,"I")
 S packageVersion=$$GET1^DIQ(9.4,packageIEN,13)  ; current verision
 S packageVersionIEN=$O(^DIC(9.4,454,22,"B",packageVersion,""))
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("packageName",$$GET1^DIQ(9.6,buildIEN,1,"E"))
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("packageNumber",packageIEN)
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("packageVersion",$$GET1^DIQ(9.4,packageIEN,13))
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("packagePrefix",$$GET1^DIQ(9.4,packageIEN,1,"E")) 
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("packageDateDestributed",$$GET1^DIQ(9.49,packageVersionIEN_","_packageIEN,1,"I"))
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("alphaBetaTesting",$$GET1^DIQ(9.6,buildIEN,20))
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("installationMessage",$$GET1^DIQ(9.6,buildIEN,21))
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("addressForUsageReporting",$$GET1^DIQ(9.6,buildIEN,22))
 S cnt=cnt+1,pAttribute(cnt)=$$attribute("xmlns","http://va.gov/VistA/kids/manifest")
 Q
 ;
 ; pBuildAttributes = build attributes array
writeBuildAttributes(pBuildAttributes) ; write build attributes
 N index
 S index=""
 F  S index=$O(pBuildAttributes(index)) Q:index=""  D
 . W !,pBuildAttributes(index)
 . Q
 Q
 ;
 ; pBuildIEN = Build IEN
writeRequiredBuilds(pBuildIEN) ; Write Required Builds
 N action,comment,element,ien,iens,patch
 ;
 S element="requiredBuild"
 W !,"<",element,"s",">"
 ;
 ; Print a comment for "ACTION" field
 D FIELD^DID(9.611,1,"","POINTER","comment")  ; get internal and external values of "ACTION" field
 W !,"<!-- action= ",comment("POINTER")," -->"
 ;
 S patch=""
 F  S patch=$O(^XPD(9.6,pBuildIEN,"REQB","B",patch)) Q:patch=""  D
 . S ien=$O(^XPD(9.6,pBuildIEN,"REQB","B",patch,""))
 . S iens=ien_","_pBuildIEN_","
 . S action=$$GET1^DIQ(9.611,iens,1,"I")
 . W !,"<",element
 . W $$attribute("name",patch)
 . W $$attribute("action",action)
 . W "/>"
 . Q
 W !,"</",element,"s",">"
 Q
 ;
 ; pBuildIEN = Build IEN
writeDataDictionaries(pBuildIEN) ; Write Data Dictionaries
 N componentName,file,exportFileName
 ;
 S componentName=$$componentName^nstKIDSManifest("DD")  ; Data Dictionary record name
 ;
 W !,"<","dataDictionaries",">"
 S file=""
 F  S file=$O(^XPD(9.6,pBuildIEN,4,"B",file)) Q:file=""  D
 . S exportFileName=$$exportName^nstKIDSUtil1("DD",file)
 . W !,"<",componentName
 . W $$attribute^nstKIDSManifest("name",file)
 . W $$attribute^nstKIDSManifest("export",exportFileName)
 . W "/>"
 . Q 
 W !,"</","dataDictionaries",">"  ; End Data Dictionary
 Q
 ;
 ; pBuildIEN = Build IEN
writeKernelComponents(pBuildIEN) ; Write Kernel components 
 N component,componentName,exportFileName,file
 ;
 F file=9.8,8994,19,19.1,.4,.401,.402,.403,.5,.84,3.6,3.8,9.2,101,409.61,771,870,8989.51,8989.52 D
 . S componentName=$$componentName^nstKIDSManifest(file)
 . W !,"<",componentName_"s",">"
 . S component=""
 . F  S component=$O(^XPD(9.6,pBuildIEN,"KRN",file,"NM","B",component)) Q:component=""  D
 . . S exportFileName=$$exportName^nstKIDSUtil1(file,component)
 . . W !,"<",componentName
 . . W $$attribute^nstKIDSManifest("name",component)
 . . W $$attribute^nstKIDSManifest("export",exportFileName)
 . . W "/>"
 . . Q
 . W !,"</",componentName_"s",">"
 . Q
 Q
 ;
attribute(pAttributeName,pAttributeValue)  ;  return attribute pair "name"="value"
 N QT
 S QT=$C(34)  ; quote "
 Q " "_pAttributeName_"="_QT_$$SYMENC^MXMLUTL(pAttributeValue)_QT ; #IA 4153 supported
 ;
componentName(pFile) ; return Kernel component name by FileMan file number
 I pFile="DD" Q "dataDictionary" ; special check for Data Dictionary
 I pFile=.4  Q "printTemplate"  ; PRINT TEMPLATE
 I pFile=.401 Q "sortTemplate"  ; SORT TEMPLATE
 I pFile=.402 Q "inputTemplate" ; INPUT Template
 I pFile=.403 Q "form"     ; FORM
 I pFile=.5 Q "function"   ; FUNCTION
 I pFile=.84 Q "dialog"    ; DIALOG
 I pFile=3.6 Q "bulletin"  ; BULLETIN
 I pFile=3.8 Q "mailGroup" ; MAIL GROUP
 I pFile=9.2 Q "helpFrame" ; HELP FRAME
 I pFile=9.8 Q "routine"
 I pFile=19 Q "option"          ; OPTION
 I pFile=19.1 Q "securityKey"   ; SECURITY KEY
 I pFile=101 Q "protocol"       ; PROTOCOL
 I pFile=409.61 Q "templateList" ; LIST TEMPLATE
 I pFile=771 Q "hl7Application"  ; HL7 APPLICATION PARAMETER
 I pFile=870 Q "hl7LogicalLink"  ; HL LOGICAL LINK
 I pFile=8989.51 Q "parameterDefinition" ; PARAMETER DEFINITION
 I pFile=8989.52 Q "parameterTemplate"   ; PARAMETER TEMPLATE
 I pFile=8994 Q "rpc" ; RPC
 Q "undefined"