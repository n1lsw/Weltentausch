$module = Get-InstalledModule -Name dotenv
$modulePath = $module.InstalledLocation
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
Import-Module "$modulePath\dotenv.psm1"

$envFilePath = "C:\Users\Nils\Desktop\weltentausch\.env"
Set-DotEnv $envFilePath

$TOKEN = ${env:$TOKEN}
$CHANNEL_ID = ${env:$CHANNEL_ID}
$DOWNLOAD_PATH = ${env:$DOWNLOAD_PATH}
$local_file_fwl = ${env:$local_file_fwl}
$local_file_db = ${env:$local_file_db}

$upload = @($local_file_fwl, $local_file_db)
$header = @{
    "Authorization" = "Bot $token"
}


## Download a file from a Discord channel OR get date of last message
function FileFromDiscord {
    param (
        [string]$channelId,
        [string]$messageId,
        [string]$downloadPath,
        [bool]$date,
        $header
    )

    $message = Invoke-WebRequest -Uri "https://discord.com/api/v9/channels/$channelId/messages/$messageId" -Headers $header -UserAgent ""
    $message = ConvertFrom-Json $message.Content        

    if ($message) {
        foreach ($attachment in $message.attachments) {
            $url = $attachment.url
            $file_name = $attachment.filename
            if ($date -eq $false) {
                $filePath = Join-Path -Path $DOWNLOAD_PATH -ChildPath $file_name
                Invoke-WebRequest -Uri $url -Headers $header -OutFile $filePath -UserAgent ""
                if ([System.IO.File]::Exists($filePath)) {
                    Write-Host "$($file_name) wurde unter $($downloadPath) gespeichert."
                }
                else {
                    Write-Warning "Der Download hat nicht funktioniert"
                }
            }
            else { 
                return $message.timestamp 
            }
        }
    }
    else {
        Write-Host "Keine Datei zum Herunterladen"
    }
}

## Upload a file to a discord channel
function FileToDiscord {
    param (
        [string]$channelId,
        [array]$local_file,
        $header
    )

    $fieldName = @('file[0]', 'file[1]')
    $url = "https://discord.com/api/v9/channels/$channelId/messages"
    $fileStream = @()
    $fileName = @()
    $fileContent = @()
    $stringContent = @("Ich habe diese Spielstände gefunden")
    
    try {
        Add-Type -AssemblyName 'System.Net.Http'

        $client = New-Object System.Net.Http.HttpClient
        $content = New-Object System.Net.Http.MultipartFormDataContent

        $stringContent = New-Object System.Net.Http.StringContent($stringContent)
        $content.Add($stringContent, "content")

        for ($i = 0; $i -lt $local_file.Length; $i++) {
            $fileStream = [System.IO.File]::OpenRead($local_file[$i])
            $fileName = [System.IO.Path]::GetFileName($local_file[$i])
            $fileContent = New-Object System.Net.Http.StreamContent($fileStream)
            $currentFieldName = $fieldName[$i]  
            $content.Add($fileContent, $currentFieldName, $fileName)
        }

        # Write-Host $content
        $client.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue('Bot', $token)
        Write-host "Dateien werden hochgeladen..."
        $result = $client.PostAsync($url, $content).Result
        $result.EnsureSuccessStatusCode()
    }
    catch {
        throw $_.Exception.message
    }
}

## Check if local files exist
function check_files {
    param(
        [array]$upload
    )
    foreach ($item in $upload) {
        if ([System.IO.File]::Exists($item)) {
            Write-Host "$item gefunden"
        } 
        else {
            Write-Host "Eine oder mehrere Dateien auf deinem PC oder auf Discord fehlen"
            Exit
        }
    }
    return $true
} 


## Get Id of last message
function get_last_message {
    param (
        [string]$channelId,
        $header
    )
    $message_id = Invoke-WebRequest -Uri "https://discord.com/api/v9/channels/$channelId/messages" -Headers $header -UserAgent ""
    if ($message_id) {
        $message_id = ConvertFrom-Json $message_id.Content        
        return $message_id[0].id    
    }
    else {
        Write-Host "Failed to get message id"
    }
}

## Call the function 
$last_message_id = get_last_message -channelId $CHANNEL_ID -header $header

## Get date of last message and modification date of local file
$remote_date = FileFromDiscord -channelId $CHANNEL_ID -messageId $last_message_id -downloadPath $DOWNLOAD_PATH -date $true -header $header
$remote_date = [datetime]::ParseExact($remote_date, "yyyy-MM-ddTHH:mm:ss.ffffffzzz", $null)

if (check_files -upload $upload) {
    $local_date = (Get-Item $local_file_fwl).LastWriteTime
    Write-Host "remote" $remote_date.GetType() $remote_date "local" $local_date.GetType() $local_date
}

## For development
# FileToDiscord -channelId $CHANNEL_ID -local_file $upload -header $header
# Exit

## Compare date of remote and local file and act accordingly (upload / download)
function sync {
    param(
        [string]$remote_date,
        [string]$local_date
    )
    if ($remote_date -gt $local_date) {
        $confirmation = Read-Host "`n Discord Datum $remote_date `n "Dein Datum" $local_date `n`n Die Dateien werden von Discord heruntergeladen - Fortfahren?"
        if ($confirmation -eq 'y') {
            FileFromDiscord -channelId $CHANNEL_ID -messageId $last_message_id -downloadPath $DOWNLOAD_PATH -date $false -header $header
        }
        else {
            Exit
        }
    }
    elseif ($remote_date -lt $local_date) {
        $confirmation = Read-Host "`n Discord Datum $remote_date `n "Dein Datum" $local_date `n`n Die Dateien werden nach Discord hochgeladen - Fortfahren?"
        if ($confirmation -eq 'y') {
            FileToDiscord -channelId $CHANNEL_ID -local_file $upload -header $header
        }
        else {
            Exit
        } 
    }  
    else {
        Write-Host "Remote and local have the same last modified time"
    }
}
## Call the final function
sync -remote_date $remote_date -local_date $local_date

Write-Host "Press any key to continue . . ."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

## TODO Build this later
# check if files are present before downloading or uploading
# loading_bar

## TODO check this 
# Portal names are human readable in the original files but not after being uploaded. In the game the names work though





