#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Configure le namespace DFS et les cibles de dossiers.

.DESCRIPTION
    Ce script crée le namespace DFS (\\corpmsi.local\Partages) et
    lie les dossiers logiques DFS aux cibles physiques sur srv-fichiers01.

.PREREQUISITES
    - Windows Server 2022 avec rôle DFS Namespaces installé
    - srv-dc01 (héberge la racine DFS)
    - srv-fichiers01 (héberge les partages SMB)

.AUTHOR
    Équipe IT - MSI Consulting

.EXAMPLE
    .\setup-dfs.ps1

.NOTES
    Date: Mai 2026
    Domaine: corpmsi.local
    Namespace: \\corpmsi.local\Partages
    Serveur physique: srv-fichiers01 (192.168.40.20)
#>

#Requires -Modules DFSN

param(
    [string]$Domain = "corpmsi.local",
    [string]$FileServer = "srv-fichiers01",
    [string]$FileServerIP = "192.168.40.20",
    [string]$RootPath = "\\$Domain\Partages"
)

$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"

function Write-Log {
    param($Message, $Color = $InfoColor)
    Write-Host $Message -ForegroundColor $Color
}

try {
    Write-Log "`n=== Configuration DFS (Distributed File System) ===" $InfoColor

    # ===== CRÉER LE NAMESPACE RACINE =====
    Write-Log "`n[1/3] Création du namespace racine DFS..." $InfoColor

    try {
        $rootNamespace = Get-DfsnRoot -Path $RootPath -ErrorAction SilentlyContinue
        if (-not $rootNamespace) {
            New-DfsnRoot -Path $RootPath `
                        -TargetPath "\\$FileServer\Partages" `
                        -Type DomainV2 `
                        -Description "Namespace centralisé - corpmsi"
            Write-Log "  ✓ Namespace racine créé : $RootPath" $SuccessColor
        } else {
            Write-Log "  ⊘ Namespace racine existant : $RootPath" $InfoColor
        }
    } catch {
        Write-Log "  ❌ Erreur création namespace : $_" $ErrorColor
    }

    # ===== CRÉER LES DOSSIERS LOGIQUES DFS =====
    Write-Log "`n[2/3] Création de l'arborescence DFS..." $InfoColor

    $Folders = @(
        @{Name = "Direction"; Share = "DIRECTION$"; Description = "Partages Direction"},
        @{Name = "Commercial"; Share = "COMMERCIAL$"; Description = "Partages Commercial"},
        @{Name = "Informatique"; Share = "INFORMATIQUE$"; Description = "Partages IT"},
        @{Name = "RH"; Share = "RH$"; Description = "Partages RH"},
        @{Name = "Comptabilite"; Share = "COMPTABILITE$"; Description = "Partages Comptabilité"},
        @{Name = "Commun"; Share = "COMMUN"; Description = "Partages communs"}
    )

    foreach ($folder in $Folders) {
        $dfsPath = "$RootPath\$($folder.Name)"
        
        try {
            $existing = Get-DfsnFolder -Path $dfsPath -ErrorAction SilentlyContinue
            if (-not $existing) {
                New-DfsnFolder -Path $dfsPath `
                              -TargetPath "\\$FileServer\$($folder.Share)" `
                              -Description $folder.Description
                Write-Log "  ✓ Dossier DFS créé : $($folder.Name)" $SuccessColor
            } else {
                Write-Log "  ⊘ Dossier DFS existant : $($folder.Name)" $InfoColor
            }
        } catch {
            Write-Log "  ⚠️  Erreur création dossier $($folder.Name): $_" $InfoColor
        }
    }

    # ===== ACTIVER L'ÉNUMÉRATION BASÉE SUR L'ACCÈS =====
    Write-Log "`n[3/3] Configuration de l'énumération basée sur l'accès..." $InfoColor

    try {
        Set-DfsnRoot -Path $RootPath `
                    -EnableAccessBasedEnumeration $true
        Write-Log "  ✓ Énumération basée sur l'accès activée" $SuccessColor
    } catch {
        Write-Log "  ⚠️  Erreur activation ABE: $_" $InfoColor
    }

    Write-Log "`n=== Configuration DFS terminée ===" $SuccessColor
    Write-Log "Namespace : $RootPath" $InfoColor
    Write-Log "Dossiers créés : $($Folders.Count)" $InfoColor
    Write-Log "`n⚠️  Assurez-vous que les partages SMB existent sur $FileServer:" $InfoColor
    foreach ($folder in $Folders) {
        Write-Log "    • \\$FileServer\$($folder.Share)" $InfoColor
    }
    Write-Log "`n⚠️  Configurez les permissions NTFS sur chaque partage!" $InfoColor

} catch {
    Write-Log "`n❌ Erreur lors de la configuration DFS: $_" $ErrorColor
    exit 1
}
