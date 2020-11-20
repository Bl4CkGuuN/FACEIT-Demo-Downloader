# Downloading FACEIT Demos

$rootpath = "path\to\folder"
$configpath =  "$rootpath\settings.ini"

Get-Content $configpath | foreach-object -begin {$config=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True) -and ($k[0].StartsWith("#") -ne $True)) { $config.Add($k[0], $k[1]) } }
$config

### Functions ###
Function Write-Log
{
    Param ([string]$logstring)
    $date = Get-Date -Format "dd/MM/yyy HH:mm:ss"
    #Testoutput
    Write-Host $logstring
    #
    $logcontent = $date + ": " + $logstring

    Add-content $Logfile -value $logcontent
}
function Get-FACEIT-Demos([string]$user, [string]$apikey, [int]$democount) {
    $headers = @{
        Authorization="Bearer $apikey"
        Content='application/json'
    }

    #Get Userdata
    Write-Log "Search for FACEIT Player-ID"
    $URI = "https://open.faceit.com/data/v4/players?game=csgo&game_player_id=$user"
    try {
        $GetUserdata = Invoke-RestMethod -Method Get $URI -Headers $headers
        $player_id = $GetUserdata.player_id
        Write-Log "Received Player Info"
        Write-Log "FACEIT Name: $($GetUserdata.nickname)"
        Write-Log "Player-ID: $player_id"
        
        #Get Matches History 
        Write-Log "Search for the last $democount Matches"
        $URI2 = "https://open.faceit.com/data/v4/players/$player_id/history?game=csgo&offset=0&limit=$democount"
        $GetMatchHistory = Invoke-RestMethod -Method Get $URI2 -Headers $headers
        $DemoFoundCount = $GetMatchHistory.items.Count
        Write-Log "Found the last $DemoFoundCount Demos in the Match History"

        foreach($item in $GetMatchHistory.items) {
            $match_id = $item.match_id
            $URI3 = "https://open.faceit.com/data/v4/matches/$match_id"
            $GetMatchInfo = Invoke-RestMethod -Method Get $URI3 -Headers $headers

            if($GetMatchInfo.status -eq "FINISHED") {
                try {
                    $downloaddemo = $false
                    Write-Log "Check if demo is already downloaded"
                    $demoname = $GetMatchInfo.demo_url.split("/") | Select-Object -Last 1
                    $ChildItems = Get-ChildItem $Downloadpath\FACEIT\
                    if($ChildItems.Name -contains $demoname) {
                        $localDemo = $ChildItems | Where-Object {$_.Name -eq $demoname} 
                        $onlineLength = (Invoke-WebRequest "$([string]$GetMatchInfo.demo_url)" -Method Head).Headers.'Content-Length'
                        if($localDemo.Length -ne $onlineLength) {
                            Write-Log "The demofile is corrupted and will be downloaded again"
                            try {
                                Remove-Item $downloadpath\FACEIT\$localDemo -Force 
                                Write-Log "The old demo was removed - $demoname"
                            } catch {
                                Write-Log "The old demo wasn't removed. Abort downloading '$demoname'"
                                $downloaddemo = $false
                            }
                            $downloaddemo = $true
                        } else {
                            $downloaddemo = $false
                        }
                    } else {
                        $downloaddemo = $true
                    }
                    
                    if($downloaddemo) {
                        Write-Log "Downloading Demo: $demoname"
                        Invoke-WebRequest "$([string]$GetMatchInfo.demo_url)" -OutFile "$Downloadpath\$demoname"
                        Write-Log "$demoname successfully downloaded"
                    } else {
                        Write-Log "Die Demo '$demoname' is already downloaded"
                    }
                } catch {
                    Write-Log "Download for '$demoname' failed"
                }
            }
        }
    } catch {
        Write-Log "Can't get the data for $user"
    }
}

function Check-Downloadpath([string]$user) {
    Write-Log "Check if the Download-Path exists '$rootpath\User\$user\..'"
    if(!(Test-Path $rootpath\User\$user)) {
        try {
            New-Item -Path "$rootpath\User\" -Name "$user" -ItemType "directory"
            Write-Log "Path '$rootpath\User\$user' was created successfully"
        } catch {
            Write-Log "ERROR: $rootpath\User\$user can't be created"
        }
    } else {
        Write-Log "The Download-Path already exists"
    }
}

foreach($user in $config.Get_Item("User").split(",").Trim()) {
    $Logfile = "$rootpath\logs\$user.log"
    $Downloadpath = "$rootpath\User\$user\"
    if(!(Test-Path $rootpath\logs)) {
        New-Item -Path "$rootpath" -Name "logs" -ItemType "directory"
    }
    
    Write-Log "--------------------------------------------------------------------"
    Write-Log "Start Demo-Downloader for $user"
    Write-Log "--------------------------------------------------------------------"

    Check-Downloadpath $user
    Get-FACEIT-Demos $user $config.Get_Item("FACEITAPIKey") $config.Get_Item("Demos")

    Write-Log "LOG END"
}
