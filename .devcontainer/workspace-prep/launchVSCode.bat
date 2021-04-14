@ECHO OFF
:BEGIN
REM change directory 
cd  %~dp0
set FLAVOR=all
CLS
ECHO Select you devcontainer flavor:
ECHO 0.  Local build base (conda only)
ECHO 1.  Local build all (conda, db-connect, db-jlab, localspark)
ECHO 2.  Local build db-connect (conda, db-connect)
ECHO 3.  Local build db-jlab (conda, db-jlab)
ECHO 4.  Local build localspark (conda, localspark)
ECHO 5.  Prebuilt base (conda only)
ECHO 6.  Prebuilt all (conda, db-connect, db-jlab, localspark)
ECHO 7.  Prebuilt db-connect (conda, db-connect)
ECHO 8.  Prebuilt db-jlab (conda, db-jlab)
ECHO 9.  Prebuilt localspark (conda, localspark)
ECHO Q.  Quit
CHOICE /N /C:0123456789Q /M "Enter a number(0,1,2,3,4,5,6,7,8 or 9)"%1
IF ERRORLEVEL ==11 GOTO QUIT
IF ERRORLEVEL ==10 GOTO PREBUILT-LOCALSPARK
IF ERRORLEVEL ==9 GOTO PREBUILT-DB-JLAB
IF ERRORLEVEL ==8 GOTO PREBUILT-DB-CONNECT
IF ERRORLEVEL ==7 GOTO PREBUILT-ALL
IF ERRORLEVEL ==6 GOTO PREBUILT-BASE
IF ERRORLEVEL ==5 GOTO BUILD-LOCALSPARK
IF ERRORLEVEL ==4 GOTO BUILD-DB-JLAB
IF ERRORLEVEL ==3 GOTO BUILD-DB-CONNECT
IF ERRORLEVEL ==2 GOTO BUILD-ALL
IF ERRORLEVEL ==1 GOTO BUILD-BASE
IF ERRORLEVEL ==0 GOTO QUIT
GOTO END
:PREBUILT-LOCALSPARK
set FLAVOR=localspark
GOTO PREBUILT-BEGIN
:PREBUILT-DB-JLAB
set FLAVOR=db_jlab
GOTO PREBUILT-BEGIN
:PREBUILT-DB-CONNECT
set FLAVOR=db_connect
GOTO PREBUILT-BEGIN
:PREBUILT-ALL
set FLAVOR=all
GOTO PREBUILT-BEGIN
:PREBUILT-BASE
set FLAVOR=base
GOTO PREBUILT-BEGIN
:BUILD-LOCALSPARK
set FLAVOR=localspark
GOTO BUILD-BEGIN
:BUILD-DB-JLAB
set FLAVOR=db_jlab
GOTO BUILD-BEGIN
:BUILD-DB-CONNECT
set FLAVOR=db_connect
GOTO BUILD-BEGIN
:BUILD-ALL
set FLAVOR=all
GOTO BUILD-BEGIN
:BUILD-BASE
set FLAVOR=base
GOTO BUILD-BEGIN
:PREBUILT-BEGIN
ECHO You have selected workspace-%FLAVOR%-prebuilt
REM Read variables in .env file
for /F "tokens=1* EOL=#" %%A in (..\..\configs\.env) do set %%A
REM Azure login
call az login --tenant %TENANT%
REM Azure Container Registry login
call az acr login --name %ACRNAME%
ECHO Updating prebuilt devcontainer.json
set Command="$input | ForEach-Object { $_ -replace \"\$\{FLAVOR\}\", \"%FLAVOR%\" }"
set CommandRemoveLine="$input | Where-Object { $_ -notmatch \"`\"python.formatting.provider`\": `\"black`\"\" }"
SET BLACK_SUPPORT=
IF %FLAVOR% == db_jlab SET BLACK_SUPPORT=1
IF %FLAVOR% == db_connect SET BLACK_SUPPORT=1
IF %FLAVOR% == localspark SET BLACK_SUPPORT=1
IF %FLAVOR% == all SET BLACK_SUPPORT=1
IF defined BLACK_SUPPORT (
	type .\devcontainer.prep.prebuilt.json | powershell -Command %Command%  > ..\devcontainer.json
) ELSE (
	type .\devcontainer.prep.prebuilt.json | powershell -Command %Command% | powershell -Command %CommandRemoveLine%   > ..\devcontainer.json
)

ECHO Updating prebuilt docker-compose.yml
set Command1="$input | ForEach-Object { $_ -replace \"\$\{FLAVOR\}\", \"%FLAVOR%\" }"
set Command2="$input | ForEach-Object { $_ -replace \"\$\{ACRLOGINSERVER\}\", \"%ACRLOGINSERVER%\" }"
set Command3="$input | ForEach-Object { $_ -replace \"\$\{PREFIX\}\", \"%PREFIX%\" }"
set Command4="$input | ForEach-Object { $_ -replace \"\$\{TAG\}\", \"%TAG%\" }"

type .\docker-compose.prep.prebuilt.yml | powershell -Command %Command1% | powershell -Command %Command2% | powershell -Command %Command3% | powershell -Command %Command4% > ..\docker-compose.yml

set acrresult=
echo Getting the ACR Repository Digest for image %PREFIX%-%FLAVOR%
for /f "tokens=* delims= " %%i in ('az acr repository show-manifests --name %ACRNAME% --repository %PREFIX%-%FLAVOR% --output json --query "([?contains(tags,'latest')].digest)[0]" --output json') do set acrresult=%%i
set acrresult=%acrresult:"=%
echo ACRDigest: '%acrresult%'

set containerID=
echo Getting Container ID associated with the image to remove %ACRLOGINSERVER%/%PREFIX%-%FLAVOR%
for /f "tokens=* delims= " %%i in ('docker container list --all --filter "ancestor=%ACRLOGINSERVER%/%PREFIX%-%FLAVOR%" --format "{{.ID}}"') do set containerID=%%i
echo Local ContainerID: '%containerID%'

set dockerresult=
echo Getting the local Docker Repository Digest for image %PREFIX%-%FLAVOR%
for /f "tokens=* delims= " %%i in ('docker image inspect %ACRLOGINSERVER%/%PREFIX%-%FLAVOR% --format "{{(index .RepoDigests 0)}}"') do set dockerresult=%%i
echo Local Docker Digest: '%dockerresult%'
IF NOT DEFINED dockerresult GOTO CHECK-IMAGE-END
IF NOT DEFINED acrresult GOTO CHECK-IMAGE-END

:CHECK-IMAGE
IF /i "%dockerresult:~-64%" EQU "%acrresult:~-64%" ( 
	echo Local devcontainer image up-to-date
) ELSE (
	IF DEFINED containerID (
		echo Removing container ID: %containerID% to force the update
		docker container rm %containerID%
		echo Removing done
	)
	echo Removing the local devcontainer image %PREFIX%-%FLAVOR% to force the update
	docker image rm -f %ACRLOGINSERVER%/%PREFIX%-%FLAVOR%
	echo Removing done
)

:CHECK-IMAGE-END

GOTO END
:BUILD-BEGIN
ECHO You have selected workspace-%FLAVOR%
REM Read variables in .env file
for /F "tokens=1* EOL=#" %%A in (..\..\configs\.env) do set %%A

IF %FLAVOR% == base GOTO BUILD-IMAGE

set dockerresult=
echo Checking if local base image is already built %PREFIX%-base
for /f "tokens=* delims= " %%i in ('docker image inspect %PREFIX%-base --format "{{(index .RepoTags 0)}}"') do set dockerresult=%%i
echo Local base Tag: '%dockerresult%'
IF DEFINED dockerresult GOTO BUILD-IMAGE

ECHO Updating build docker-compose.yml to build base image
set Command="$input | ForEach-Object { $_ -replace \"\$\{FLAVOR\}\", \"base\" }"
type .\docker-compose.prep.build.yml | powershell -Command %Command%   > ..\docker-compose.yml
ECHO Building base image
docker-compose --project-name data-dev-container_devcontainer -f ..\docker-compose.yml build


:BUILD-IMAGE
ECHO Updating build devcontainer.json
set Command="$input | ForEach-Object { $_ -replace \"\$\{FLAVOR\}\", \"%FLAVOR%\" }"
set CommandRemoveLine="$input | Where-Object { $_ -notmatch \"`\"python.formatting.provider`\": `\"black`\"\" }"
SET BLACK_SUPPORT=
IF %FLAVOR% == db_jlab SET BLACK_SUPPORT=1
IF %FLAVOR% == db_connect SET BLACK_SUPPORT=1
IF %FLAVOR% == localspark SET BLACK_SUPPORT=1
IF %FLAVOR% == all SET BLACK_SUPPORT=1
IF defined BLACK_SUPPORT (
	type .\devcontainer.prep.build.json | powershell -Command %Command%  > ..\devcontainer.json
) ELSE (
	type .\devcontainer.prep.build.json | powershell -Command %Command% | powershell -Command %CommandRemoveLine%   > ..\devcontainer.json
)

ECHO Updating build docker-compose.yml
set Command="$input | ForEach-Object { $_ -replace \"\$\{FLAVOR\}\", \"%FLAVOR%\" }"
type .\docker-compose.prep.build.yml | powershell -Command %Command%  > ..\docker-compose.yml

:END

ECHO Launching VS Code
code ..\..\.

:QUIT


