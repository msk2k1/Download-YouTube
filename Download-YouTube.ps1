[CmdletBinding()]
param (
    [Parameter(mandatory=$true)]
    [string]$Link,

    [Parameter(mandatory=$false)]
    [switch]$AudioALAC,
    [switch]$AudioMP3
)
$ErrorActionPreference = "Stop"

# Verifying necessary programs are accessible
. F:/projects/scripts/Add-Dependency.ps1
Add-Dependency "F:/software" "yt-dlp"
Add-Dependency "F:/software" "ffmpeg"

$link = $link.replace("&","`"&`"")  # fix for yt-dlp error that throws if input URL has &

if($audioALAC) {
    $dirBefore = Get-ChildItem
    yt-dlp $link --output ".\%(title)s - %(id)s.%(ext)s" --extract-audio --audio-format best --restrict-filenames 
    $dirAfter = Get-ChildItem
    $newFiles = (Compare-Object -ReferenceObject $dirBefore -DifferenceObject $dirAfter).inputObject # get all files just created by yt-dlp

    # ALAC conversion
    foreach($i in $newFiles) {
        ffmpeg -i "$($i.Name)" -c:v copy -c:a alac "$($i.BaseName).m4a" -hide_banner
        Remove-Item $i
    }
}
elseif($audioMP3) {
    $dirBefore = Get-ChildItem
    yt-dlp $link --output ".\%(title)s - %(id)s.%(ext)s" --extract-audio --audio-format best --restrict-filenames 
    $dirAfter = Get-ChildItem
    $newFiles = (Compare-Object -ReferenceObject $dirBefore -DifferenceObject $dirAfter).inputObject # get all files just created by yt-dlp

    # MP3 conversion
    foreach($i in $newFiles) {
        ffmpeg -i "$($i.Name)" -b:a 320k -c:v copy -c:a libmp3lame -hide_banner "$($i.BaseName).mp3"
        Remove-Item $i
    }
}
else { 
    yt-dlp $link --output ".\%(title)s - %(id)s.%(ext)s" --format "mp4" --restrict-filenames 
}

[System.Media.SystemSounds]::Exclamation.play()
exit