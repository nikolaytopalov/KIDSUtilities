nstKIDSUtil2 ;NST - KIDS Utilities ; 01 May 2014 10:30 PM
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
getPath() ; Get export path
 N POP,DTOUT,DUOUT,Y,X,DIR,DIRUT
 ;
 ; Get export path
 S DIR(0)="F^3:245",DIR("A")="Enter export path",DIR("?")="Enter a path to output package(s).",POP=0
 D ^DIR I $D(DTOUT)!$D(DUOUT) S POP=1 Q ""
 ;if no path, then quit
 Q:Y="" ""
 Q $$DEFDIR^%ZISH(Y)  ; format the path
 ;
makeDirectory(pPath) ; create a directory in the file system
 N mkDir
 I ^%ZOSF("OS")["GT.M" D  Q
 . ZSYSTEM "mkdir "_pPath_" 2>/dev/null"
 . Q
 S mkDir="D $ZF(-1,""mkdir "_pPath_""")"
 X mkDir
 Q
 ;
ok() ; Success status
 Q 0
 ;
failed() ; failure status
 Q -1
 ;
resultDelimiter() ; result delimiter
 Q "^"
 ;
resultDataPiece() ; returns the piece number where the result data value is stored
 Q 3
 ;
isOK(RY) ; Returns 0 (failed) or 1 (success): check if the first piece of RY is success
 Q +RY=$$ok()
 ;
getResultValue(RY) ; returns data value in RY string
 Q $P(RY,$$resultDelimiter(),$$resultDataPiece())
 ;
setResultValue(RY,pValue) ; set pValue in RY data piece
 S $P(RY,$$resultDelimiter(),$$resultDataPiece())=pValue
 Q
 ;
setOKValue(pValue) ; set OK result and value
 N result
 S result=$$ok()
 D setResultValue(.result,pValue)
 Q result
 ;
setResultError(pValue) ; set error result and value
 Q $$failed()_$$resultDelimiter()_pValue