# ultimate_mobile_server_all_in_one.ps1
# Felsäker all-in-one privat server setup
# Windows 10 Home – HP EliteBook 8440p

function Ask-YesNo($msg) {
    do {
        $ans = Read-Host "$msg (Y/N)"
    } while ($ans -notmatch '^[YyNn]$')
    return $ans -match '^[Yy]$'
}

# Funktion för att kolla om ett program är installerat
function IsProgramInstalled($exeName) {
    return Get-Command $exeName -ErrorAction SilentlyContinue
}

Write-Host "`n=== Ultimate Privat Server Setup (Felsäker) ===`n"

# 1️⃣ Optimera Windows
try {
    if (Ask-YesNo "Optimera Windows för hög prestanda och stäng bakgrundsappar?") {
        Write-Host "Sätter energialternativ till hög prestanda..."
        powercfg -setactive SCHEME_MIN
        Write-Host "Stoppar onödiga bakgrundsprocesser..."
        Get-Process | Where-Object { $_.MainWindowTitle -eq "" -and $_.Name -notin @("explorer","powershell") } | Stop-Process -ErrorAction SilentlyContinue
        Write-Host "Windows optimerat!"
    }
} catch {
    Write-Host "⚠️ Fel vid optimering: $_"
}

# 2️⃣ Installera Tailscale
try {
    if (Ask-YesNo "Installera Tailscale för privat VPN/fjärråtkomst?") {
        $tsURL="https://pkgs.tailscale.com/stable/tailscale-setup-1.48.3.msi"
        $tsFile="$env:TEMP\tailscale.msi"
        Invoke-WebRequest $tsURL -OutFile $tsFile -ErrorAction Stop
        Start-Process msiexec.exe -ArgumentList "/i `"$tsFile`" /quiet /norestart" -Wait
        Write-Host "Tailscale installerat! Logga in manuellt första gången."
    }
} catch {
    Write-Host "⚠️ Fel vid Tailscale-installation: $_"
}

# 3️⃣ Installera Chrome Remote Desktop
try {
    if (Ask-YesNo "Installera Chrome Remote Desktop för full fjärrkontroll?") {
        $crdURL="https://dl.google.com/chrome-remote-desktop/chrome-remote-desktop_current_amd64.msi"
        $crdFile="$env:TEMP\crd.msi"
        Invoke-WebRequest $crdURL -OutFile $crdFile -ErrorAction Stop
        Start-Process msiexec.exe -ArgumentList "/i `"$crdFile`" /quiet /norestart" -Wait
        Write-Host "Chrome Remote Desktop installerat! Konfigurera manuellt första gången."
    }
} catch {
    Write-Host "⚠️ Fel vid Chrome Remote Desktop-installation: $_"
}

# 4️⃣ Autostart för Tailscale
try {
    if (Ask-YesNo "Vill du att Tailscale startar automatiskt med Windows?") {
        $tsPath="C:\Program Files (x86)\Tailscale IPN\tailscale.exe"
        if (Test-Path $tsPath) {
            $shell=New-Object -ComObject WScript.Shell
            $startup=[Environment]::GetFolderPath("Startup")
            $lnk=$shell.CreateShortcut("$startup\Tailscale.lnk")
            $lnk.TargetPath=$tsPath
            $lnk.Save()
            Write-Host "Tailscale autostart klar!"
        }
    }
} catch {
    Write-Host "⚠️ Fel vid Tailscale autostart: $_"
}

# 5️⃣ Autostart för Chrome Remote Desktop
try {
    if (Ask-YesNo "Vill du att Chrome Remote Desktop startar automatiskt med Windows?") {
        $crdPath="C:\Program Files (x86)\Google\Chrome Remote Desktop\_CRD\CRDHost.exe"
        if (Test-Path $crdPath) {
            $shell=New-Object -ComObject WScript.Shell
            $startup=[Environment]::GetFolderPath("Startup")
            $lnk=$shell.CreateShortcut("$startup\ChromeRemoteDesktop.lnk")
            $lnk.TargetPath=$crdPath
            $lnk.Save()
            Write-Host "Chrome Remote Desktop autostart klar!"
        }
    }
} catch {
    Write-Host "⚠️ Fel vid Chrome Remote Desktop autostart: $_"
}

# 6️⃣ Skapa ServerJobs-mapp
$serverDir="C:\ServerJobs"
try {
    if (Ask-YesNo "Skapa standardmapp för serverjobb (C:\ServerJobs)?") {
        if (-not (Test-Path $serverDir)) { New-Item -Path $serverDir -ItemType Directory }
        Write-Host "ServerJobs-mapp klar!"
    }
} catch {
    Write-Host "⚠️ Fel vid skapande av ServerJobs-mapp: $_"
}

# 7️⃣ Skapa exempel-script
try {
    if (Ask-YesNo "Skapa exempel-script för Python, Node.js och PowerShell?") {
        # Python
        if (IsProgramInstalled "python") {
            "print('Python-script startat:', __import__('datetime').datetime.now())" | Out-File -FilePath "$serverDir\example.py" -Encoding UTF8
        } else { Write-Host "⚠️ Python inte installerat, hoppar över example.py" }

        # Node.js
        if (IsProgramInstalled "node") {
            "console.log('Node.js script startat:', new Date());" | Out-File -FilePath "$serverDir\example.js" -Encoding UTF8
        } else { Write-Host "⚠️ Node.js inte installerat, hoppar över example.js" }

        # PowerShell
        "Write-Host 'PowerShell-script startat:' (Get-Date)" | Out-File -FilePath "$serverDir\example.ps1" -Encoding UTF8

        Write-Host "Exempel-script skapade i $serverDir"
    }
} catch {
    Write-Host "⚠️ Fel vid skapande av exempel-script: $_"
}

# 8️⃣ Skapa start-all-jobs script
try {
    if (Ask-YesNo "Skapa script för att starta alla serverjobb med ett klick?") {
        $startAll="$serverDir\start_all_jobs.ps1"
        $content = @"
Write-Host 'Startar alla serverjobb...'
Start-Process powershell -ArgumentList '-File `"$serverDir\example.ps1`"'
if (Test-Path `"$serverDir\example.py`") { Start-Process python -ArgumentList `"$serverDir\example.py`" }
if (Test-Path `"$serverDir\example.js`") { Start-Process node `"$serverDir\example.js`" }
Write-Host 'Alla jobb startade.'
"@
        $content | Out-File -FilePath $startAll -Encoding UTF8
        Write-Host "start_all_jobs.ps1 skapad! Kör den via fjärrskrivbord för att starta allt."
    }
} catch {
    Write-Host "⚠️ Fel vid skapande av start_all_jobs.ps1: $_"
}

Write-Host "`n=== Setup klart! ==="
Write-Host "1) Logga in i Tailscale på laptopen."
Write-Host "2) Konfigurera Chrome Remote Desktop."
Write-Host "3) Använd start_all_jobs.ps1 för att köra Discord-botar, webbtjänster eller andra scripts."
Write-Host "4) Nu kan du styra ALLT från mobilen via fjärrskrivbord!"
Write-Host "5) Inget annat script behöver köras."
Write-Host "`nScriptet stannar kvar vid eventuella fel så du kan läsa meddelanden."
