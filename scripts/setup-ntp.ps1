#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Configure le serveur NTP sur le PDC.

.DESCRIPTION
    Cet script configure srv-dc01 (PDC) comme serveur NTP fiable pour
    le domaine corpmsi.local en utilisant les pools NTP publics.

.PREREQUISITES
    - Windows Server 2022 avec rôle PDC FSMO
    - srv-dc01
    - Service W32Time actif

.AUTHOR
    Équipe IT - MSI Consulting

.EXAMPLE
    .\setup-ntp.ps1

.NOTES
    Date: Mai 2026
    Domaine: corpmsi.local
    PDC: srv-dc01
    Pools NTP: 0.pool.ntp.org, 1.pool.ntp.org
#>

param(
    [string[]]$NTPServers = @("0.pool.ntp.org", "1.pool.ntp.org"),
    [string]$Domain = "corpmsi.local"
)

$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"

function Write-Log {
    param($Message, $Color = $InfoColor)
    Write-Host $Message -ForegroundColor $Color
}

try {
    Write-Log "`n=== Configuration NTP pour srv-dc01 (PDC) ===" $InfoColor

    # Vérifier que la machine est bien un DC
    Write-Log "`n[Vérification] Vérification du rôle PDC..." $InfoColor
    
    try {
        $dcInfo = Get-ADDomainController -Discover -Service PrimaryDC -ForceDiscover -ErrorAction SilentlyContinue
        if ($dcInfo) {
            Write-Log "  ✓ C'est un PDC pour le domaine : $($dcInfo.Domain)" $SuccessColor
        }
    } catch {
        Write-Log "  ⚠️  Impossible de vérifier le rôle PDC (peut être sur un autre serveur)" $InfoColor
    }

    # ===== CONFIGURER LES SOURCES NTP =====
    Write-Log "`n[1/3] Configuration des sources NTP..." $InfoColor

    $ntpPeerList = ($NTPServers | ForEach-Object { "$_,0x9" }) -join ' '
    
    # Appliquer la configuration NTP via reg add
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
    
    # Supprimer les pairs existants
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" `
            /v NtpServer `
            /t REG_SZ `
            /d "$ntpPeerList" `
            /f
    
    Write-Log "  ✓ Sources NTP configurées:" $SuccessColor
    foreach ($server in $NTPServers) {
        Write-Log "    • $server" $SuccessColor
    }

    # ===== ACTIVER LE MODE MANUEL =====
    Write-Log "`n[2/3] Activation du mode synchronisation manuel..." $InfoColor

    reg add "HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" `
            /v Type `
            /t REG_SZ `
            /d NTP `
            /f

    reg add "HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Config" `
            /v AnnounceFlags `
            /t REG_DWORD `
            /d 5 `
            /f

    # Définir ce serveur comme fiable (Stratum 2)
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" `
            /v Reliable `
            /t REG_SZ `
            /d "YES" `
            /f

    Write-Log "  ✓ Serveur configuré comme source NTP fiable (Stratum 2)" $SuccessColor

    # ===== REDÉMARRER LE SERVICE =====
    Write-Log "`n[3/3] Redémarrage du service W32Time..." $InfoColor

    try {
        Stop-Service W32Time -Force
        Start-Service W32Time
        Write-Log "  ✓ Service W32Time redémarré" $SuccessColor
    } catch {
        Write-Log "  ❌ Erreur redémarrage W32Time: $_" $ErrorColor
    }

    # Attendre la synchronisation
    Write-Log "`n  Attente de la synchronisation (10 secondes)..." $InfoColor
    Start-Sleep -Seconds 10

    # ===== VÉRIFIER LA CONFIGURATION =====
    Write-Log "`n=== Vérification de la configuration ===" $InfoColor

    try {
        $source = w32tm /query /source
        Write-Log "  ✓ Source NTP actuelle : $source" $SuccessColor
    } catch {
        Write-Log "  ⚠️  Impossible de requêter la source" $InfoColor
    }

    try {
        $status = w32tm /query /status
        Write-Log "  Status W32Time:" $InfoColor
        Write-Log "$status" $SuccessColor
    } catch {
        Write-Log "  ⚠️  Impossible de requêter le status" $InfoColor
    }

    # Afficher les peers configurés
    Write-Log "`n  Peers NTP configurés:" $InfoColor
    $peers = w32tm /query /peers
    if ($peers) {
        Write-Log "$peers" $SuccessColor
    } else {
        Write-Log "  ⚠️  Aucun peer affiché (synchronisation en cours...)" $InfoColor
    }

    Write-Log "`n=== Configuration NTP terminée ===" $SuccessColor
    Write-Log "Serveur: PDC (srv-dc01)" $InfoColor
    Write-Log "Sources: $($NTPServers -join ', ')" $InfoColor
    Write-Log "`n💡 Conseil: Attendez 5–10 minutes pour que la synchronisation se stabilise." $InfoColor

} catch {
    Write-Log "`n❌ Erreur lors de la configuration NTP: $_" $ErrorColor
    exit 1
}
