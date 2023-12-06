# Posted by robcirrus on Discord - Chia Network - off-topic on 10/23/2023

# Powershell script to move/replace plot files 

# This will move new plot files from one path to another.
# Set the parameters between the "### Change the parameters between these lines" before running
# It will check the destination-path that it has enough free space to copy a file.
# It will delete one remove-destination-path file based on amount of free buffer space of 4x C0 size plot files
# The free buffer space will help keep destination from thrashing on low space
# Since the deleted file is typically larger than new file, the free buffer space will increase on each
#   file copy pass until it gets to the free buffer size, then it will not delete until it get lower
# Typically this is run on the farmer/harvester with a remote connection to the plotter's shared plot drop drive
# You can copy it to multiple file names and run multiple ones concurrently in their own powershell window

using namespace System.Collections.Generic

### Change the parameters between these lines
# SrcPath is where new plot files to copy from
$SrcPath = "Y:\BBPC5"
# DestPath is the path to copy new plot files to
$DestPath = "K:\BBPC5"
# DestRemovePath is the path to remove old plots from
# this can be same as DestPath
# it will NOT delete compressed plot files, as it won't delete files that have K32-c within the file name
$DestRemovePath = "K:\"

$maxToCopy = 999  # stops after copying this many plots
$keepChecking = $true  # if true, does not stop when SrcPath is empty, keeps checking for new files to drop
$IPG = 0  # this is RoboCopy option to limit IO speed, 0 is full copy speed
# this is a partial string that if the file to delete contains any 
#  portion of this, it will be skipped from deletion
#  set this to "any" (or something that is NOT in the file names) if you want to delete any file in the DestRemovePath.
#  k32-c will skip deleting files that re done with new compressed layout
#  could be k32-c05 to delete all BUT C5 compressed plots
$IgnoreDeleteString = "k32-c"  
### Change the parameters between these lines


if (!(Test-Path -Path $SrcPath -PathType Container)) {
    Write-Host "$SrcPath does not exist..."
    exit
}
if (!(Test-Path -Path $DestPath -PathType Container)) {
    Write-Host "$DestPath does not exist..."
    exit
}
if (!(Test-Path -Path $DestRemovePath -PathType Container)) {
    Write-Host "$DestRemovePath does not exist..."
    exit
}

#prompts used
$Checking = "Checking to move .plot files Ctrl-C to stop"
$Copying = "Copying file..."
$Pausing = "Pausing 60 seconds for next pass..."
$Pausing30 = "Pausing 30 seconds for next pass..."
$Pausing15 = "Pausing 15 seconds for next pass..."
# delete when free space on dest is < $BufferFreeGB, related to 4x C0 files
$BufferFreeGB = 4 * 102

$FillListEveryFile = $true
$FilesCopied = 0

function Get-FreeSpaceGB {
    param ([string]$path);
    $space = (Get-Volume -Filepath $path).SizeRemaining;
    return [Math]::Round(($space / 1GB),2)
}

#return true if it was cancelled with any key...
Function TimedPromptEx($prompt,$secondsToWait) {
    Write-Host -NoNewline $prompt

    $secondsCounter = 0
    $subCounter = 0

    While ($secondsCounter -lt $secondsToWait) {
        if ($host.UI.RawUI.KeyAvailable) {
            $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp,IncludeKeyDown")
            if ($key.KeyDown -eq "True") {
                return $true
            }
        }
        Start-Sleep -Milliseconds 10 
        $subCounter = $subCounter + 10 
        if ($subCounter -eq 1000)
        {
            $secondsCounter++
            $subCounter = 0
            Write-Host -NoNewline "."
        }

    }
    Write-Host ""
    return $false;
}



while ($true)
{
    
    $files = Get-ChildItem -Path $SrcPath -Filter *.plot
    $FileCnt = $files.Length

    # for when count returns some really high number for some reason...
    if ($FileCnt -gt 2000)
    {
        $FileCnt = 1
    }

    Write-Host "Move/Remove $FileCnt .plot Files from $SrcPath to $DestPath..." 

    Foreach  ($file in $files) 
    {
        $FreeGB = Get-FreeSpaceGB($DestPath);
        # only remove file if freespace buffer less than BufferFreeGB
        if ($FreeGB -le $BufferFreeGB)
        {
            # now remove one old one...
            $RemoveFiles = Get-ChildItem -Path $DestRemovePath -Filter *.plot
            Foreach  ($removefile in $RemoveFiles) 
            {
                # skip tose that contain *K32-c* as they are compressed plots...
                if ($removefile.Name.Contains($IgnoreDeleteString)) {
                    continue;  
                }
                Write-Host "Removing 1 plot from $DestRemovePath"
                Remove-Item $removefile.FullName;
                # only do ONE file
                break;
            }
        }

        # now see if there still enough space to copy file
        $FreeGB = Get-FreeSpaceGB($DestPath);
        if ($FreeGB -lt ($File.Length / 1GB))
        {
            Write-Host "Not enough free space on destination...."
            $Pausing15
            Start-Sleep -Seconds 15
            break
        }

        # now see if file name is still availalbe, due to multiple scripts running against same SrcPath
        $filesNow = Get-ChildItem -Path $SrcPath -Filter $file.Name
        if ($filesNow.Length -le 0)
        {
            break
        }

        Write-Host "Moving .plot Files from $SrcPath to $DestPath..." 

        $newFullName=$file.FullName.Replace(".plot",".plot_MOV")
        $newName=$file.Name.Replace(".plot",".plot_MOV")

        Rename-Item -Path $file.FullName -NewName $newFullName

        RoboCopy $SrcPath $DestPath $newName /mov /copy:DAT /w:0 /r:0 /J /TEE /NJH /ndl /A-:SH /IPG:$IPG

        #now rename destination back to .plot
        $DestName = $file.Name.Replace(".plot",".plot_MOV")
        Rename-Item -Path $DestPath\$DestName -NewName $file.Name

        $FilesCopied++

        if (($maxToCopy -gt 0) -and ($FilesCopied -ge $maxToCopy)) {
            break
        }

        $cancelled = TimedPromptEx "Press key to cancel within 2 seconds" 2
        if ($cancelled -eq $true) {
            Write-Host "   Canceling..."
            $keepChecking = $false
            break
        }

        if ($FillListEveryFile -eq $true) {
            break;
        }

    }

    if (($maxToCopy -gt 0) -and ($FilesCopied -ge $maxToCopy)) {
        break
    }

    if (!$keepChecking) {
        break
    }

    if ($FileCnt -gt 0)
    {
        if ($FillListEveryFile -eq $true) {
            continue;
        }
    }

    $Pausing15
    Start-Sleep -Seconds 15
    $Checking

}
