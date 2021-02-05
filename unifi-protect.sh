#!/bin/bash
##      .SYNOPSIS
##      Grafana Dashboard for Unifi Protect - Using API to InfluxDB Script
## 
##      .DESCRIPTION
##      This Script will query the Unifi API and send the data directly to InfluxDB, which can be used to present it to Grafana. 
##      The Script and the Grafana Dashboard it is provided as it is, and bear in mind you can not open support Tickets regarding this project. It is a Community Project
##	
##      .Notes
##      NAME:  unifi-protect.sh
##      ORIGINAL NAME: unifi-protect.sh
##      LASTEDIT: 04/02/2021
##      VERSION: 1.0
##      KEYWORDS: Unifi, InfluxDB, Grafana
   
##      .Link
##      https://jorgedelacruz.es/
##      https://jorgedelacruz.uk/

# Configurations
##
# Endpoint URL for InfluxDB
InfluxDBURL="http://YOURINFLUXSERVER" #Use https if required
InfluxDBPort="8086" #Default Port
InfluxDB="telegraf" #Default Database
InfluxDBUser="YOURTELEGRAFUSER" #User for Database
InfluxDBPassword="YOURTELEGRAFPASSWORD" #Password for Database

# Endpoint URL for login action
UnifiUsername="YOURUNIFIUSER"
UnifiPassword="YOURUNIFIPASS"
UnifiProtectServer="https://YOURUNIFIPROTECTIP"
CookiePath="/tmp/cookies.txt"

##
# Getting the Cookie into the jar
##
curl -X POST "$UnifiProtectServer/api/auth/login" -H "Content-Type: application/json" --insecure -d '{"username":"'$UnifiUsername'", "password":"'$UnifiPassword'"}' -c "$CookiePath" 2>&1 -k --silent > /dev/null

##
#  Bootstrap Overview. This part will download the needed details from the bootstrap API call
##
UNIFIBOOTSTRAPUrl=$(curl "$UnifiProtectServer/proxy/protect/api/bootstrap" -H 'Cookie: TOKEN=' --cookie $CookiePath --cookie-jar $CookiePath -H 'Upgrade-Insecure-Requests: 1' 2>&1 -k --silent)

    version=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".nvr.version" | awk '{gsub(/ /,"\\ ");print}')    
    mac=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".nvr.mac")    
    host=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".nvr.host")    
    name=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".nvr.name"| awk '{gsub(/ /,"\\ ");print}')
    firmwareVersion=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".nvr.firmwareVersion" | awk '{gsub(/ /,"\\ ");print}')    
    cpu=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".nvr.systemInfo.cpu.averageLoad")    
    temperature=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".nvr.systemInfo.cpu.temperature")    
    memoryavailable=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".nvr.systemInfo.memory.available")    
    memoryfree=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".nvr.systemInfo.memory.free")    
    memorytotal=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".nvr.systemInfo.memory.total")    
    storageavailable=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".nvr.systemInfo.storage.available")
    storagesize=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".nvr.systemInfo.storage.size")
    storageused=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".nvr.systemInfo.storage.used")
    storagetype=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".nvr.systemInfo.storage.type")
    storageinfomodel=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".nvr.systemInfo.storage.devices[0].model"| awk '{gsub(/ /,"\\ ");print}')    
    storageinfohealthy=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".nvr.systemInfo.storage.devices[0].healthy")

    #echo "unifi_protect_overview protecthost=$host,protectname=$name,protectversion=$version,protectmac=$mac,protectfirmware=$firmwareVersion,storage_model=$storageinfomodel,storage_type=$storagetype,storage_health=$storageinfohealthy cpuavg=$cpu,temperature=$temperature,mem_available=$memoryavailable,mem_free=$memoryfree,mem_total=$memorytotal,storage_available=$storageavailable,storage_size=$storagesize,storage_used=$storageused"
    curl -i -XPOST "$InfluxDBURL:$InfluxDBPort/write?precision=s&db=$InfluxDB" -u "$InfluxDBUser:$InfluxDBPassword" --data-binary "unifi_protect_overview,protecthost=$host,protectname=$name,protectversion=$version,protectmac=$mac,protectfirmware=$firmwareVersion,storage_model=$storageinfomodel,storage_type=$storagetype,storage_health=$storageinfohealthy cpuavg=$cpu,temperature=$temperature,mem_available=$memoryavailable,mem_free=$memoryfree,mem_total=$memorytotal,storage_available=$storageavailable,storage_size=$storagesize,storage_used=$storageused"
    

##
#  NVR Cameras - Everything camera related
##
declare -i arraycameras=0
for id in $(echo "$UNIFIBOOTSTRAPUrl" | jq -r '.cameras[].id'); do
    CameraID=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".cameras[$arraycameras].id")
    CameraMAC=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".cameras[$arraycameras].mac")    
    CameraHost=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".cameras[$arraycameras].connectionHost")    
    CameraIP=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".cameras[$arraycameras].host")    
    CameraType=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".cameras[$arraycameras].type" | awk '{gsub(/ /,"\\ ");print}')
    CameraName=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".cameras[$arraycameras].name" | awk '{gsub(/ /,"\\ ");print}')    
    CameraUp=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".cameras[$arraycameras].upSince")    
    CameraSeen=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".cameras[$arraycameras].lastSeen")    
    CameraConnected=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".cameras[$arraycameras].connectedSince")    
    CameraState=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".cameras[$arraycameras].state")
        case $CameraState in
        DISCONNECTED)
            CameraStatus="1"
        ;;
        CONNECTED)
            CameraStatus="2"
        ;;
        esac
    CameraHardware=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".cameras[$arraycameras].hardwareRevision")    
    CameraFirmware=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".cameras[$arraycameras].firmwareVersion")    
    CameraFirmwareBuild=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".cameras[$arraycameras].firmwareBuild")    
    CameraSpeed=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".cameras[$arraycameras].wiredConnectionState.phyRate")    
    CamerarxBytes=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".cameras[$arraycameras].stats.rxBytes")    
    CameratxBytes=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".cameras[$arraycameras].stats.txBytes")
    
    #echo "unifi_protect_cameras,protecthost=$CameraHost,protectname=$name,cameraName=$CameraName,cameraid=$CameraID,cameraIP=$CameraIP,cameraMAC=$CameraMAC,cameraType=$CameraType,camerafirmware=$CameraFirmware,camerafwbuild=$CameraFirmwareBuild cameralastSeen=$CameraSeen,cameraLAN=$CameraSpeed,camerastate=$CameraStatus,camerahardware=$CameraHardware,camerarxbytes=$CamerarxBytes,cameratxbytes=$CameratxBytes"
    curl -i -XPOST "$InfluxDBURL:$InfluxDBPort/write?precision=s&db=$InfluxDB" -u "$InfluxDBUser:$InfluxDBPassword" --data-binary "unifi_protect_cameras,protecthost=$CameraHost,protectname=$name,cameraName=$CameraName,cameraid=$CameraID,cameraIP=$CameraIP,cameraMAC=$CameraMAC,cameraType=$CameraType,camerafirmware=$CameraFirmware,camerafwbuild=$CameraFirmwareBuild cameralastSeen=$CameraSeen,cameraLAN=$CameraSpeed,camerastate=$CameraStatus,camerahardware=$CameraHardware,camerarxbytes=$CamerarxBytes,cameratxbytes=$CameratxBytes"
    
    arraycameras=$arraycameras+1
done

##
#  NVR Security - Last Login, and IP / Not working as expected as not last login for local users, neither up to date
##
#declare -i arrayusers=0
#for id in $(echo "$UNIFIBOOTSTRAPUrl" | jq -r '.users[].id'); do
#    UserID=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".users[$arrayusers].id")
#    UserLastLoginIP=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".users[$arrayusers].lastLoginIp")
#    UserLastLoginTime=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".users[$arrayusers].lastLoginTime")   
#   UserName=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".users[$arrayusers].name" | awk '{gsub(/ /,"\\ ");print}')
#    [[ ! -z "$UserName" ]] || UserName="Null"
#    UserFirstName=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".users[$arrayusers].firstName" | awk '{gsub(/ /,"\\ ");print}')
#    [[ ! -z "$UserFirstName" ]] || UserFirstName="Null"
#    UserLastName=$(echo "$UNIFIBOOTSTRAPUrl" | jq --raw-output ".users[$arrayusers].lastName" | awk '{gsub(/ /,"\\ ");print}')
#    [[ ! -z "$UserLastName" ]] || UserLastName="Null"
    
    #echo "unifi_protect_security protecthost=$host,protectname=$name,userid=$UserID,userIP=$UserLastLoginIP,userTime=$UserLastLoginTime,username=$UserName,userfirstname=$UserFirstName,userlastname=$UserLastName"
#    curl -i -XPOST "$InfluxDBURL:$InfluxDBPort/write?precision=s&db=$InfluxDB" -u "$InfluxDBUser:$InfluxDBPassword" --data-binary "unifi_protect_security,protecthost=$host,protectname=$name,userid=$UserID,userIP=$UserLastLoginIP,username=$UserName,userfirstname=$UserFirstName,userlastname=$UserLastName userLasTime=$UserLastLoginTime"
    
#    arrayusers=$arrayusers+1
#done
