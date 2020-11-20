# FACEIT-Demo-Downloader
PowerShell script that download the last x demos 

Originally I wanted to download MM and FACEIT demos, maybe I will add this in the future but its not really working with PowerShell only...

The script will check every user provided in the settings.ini

# How to use the script
1. Get a FACEIT API Key (https://developers.faceit.com/).
2. Download the "Downloader.ps1" and the "settings.ini" and put in one folder.
3. Edit the third line in the "Downloader.ps1" with your Directory (ex. $rootpath = "C:\Users\Bl4CkGuuN\Desktop\FACEIT-Demo-Downloader".
4. Add your SteamID's (seperated in ",") and the API-Key in the "settings.ini". You can also change how many matches the script should check (per SteamID).
5. Run the script with Windows PowerShell.

You can also create a daily task, that start the script in the background

# settings.ini
```
[GENERAL]
User=STEAMID64,STEAMID64
Demos=20

[API]
FACEITAPIKey=<API-KEY>
```
