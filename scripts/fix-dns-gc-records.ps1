#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Corrige les records DNS manquants du Global Catalog sur srv-dc02.

.DESCRIPTION
    Ce script résout le problème de records DNS Global Catalog manquants
    en créant manuellement les A records et SRV records dans la zone
    _msdcs.corpmsi.local. C'est un fix pour le problème rencontré lors
    de l'audit DNS complet du projet.

.PREREQUISITES
    - Windows Server 2022 avec rôle DNS installé sur srv-dc01
    - srv-dc02 doit être un Global Catalog
    - Domaine: corpmsi.local

.AUTHOR
    Équipe IT - MSI Consulting

.EXAMPLE
    .\fix-dns-gc-records.ps1

.NOTES
    Date: Mai 2026
    Domaine: corpmsi.local
    Basé sur: Cas d'étude du troubleshooting DNS (Problèmes-Solutions.md)
    Problème: Records _ldap._tcp.gc._msdcs manquants sur srv-dc02
#>

param(
    [string]$Domain = "corpmsi.local",
    [string]$DomainDN = "DC=corpmsi,DC=local",
    [string]$DCName = "srv-dc02",
    [string]$DCIPAddress = "192.168.40.11"
)

$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

function Write-Log {
    param($Message, $Color = $InfoColor)
    Write-Host $Message -ForegroundColor $Color
}

try {
    Write-Log "`n=== Correction des records DNS Global Catalog ===" $InfoColor
    Write-Log "Domaine: $Domain" $InfoColor
    Write-Log "DC cible: $DCName ($DCIPAddress)" $InfoColor

    # ===== PRÉREQUIS =====
    Write-Log "`n[Vérification] Prérequis..." $InfoColor

    # Vérifier que srv-dc02 est bien un Global Catalog
    try {
        $dcInfo = Get-ADDomainController -Identity $DCName -ErrorAction SilentlyContinue
        if ($dcInfo.IsGlobalCatalog) {
            Write-Log "  ✓ $DCName est un Global Catalog" $SuccessColor
        } else {
            Write-Log "  ❌ $DCName n'est PAS un Global Catalog!" $ErrorColor
            Write-Log "  Exécutez cette commande sur le serveur :" $InfoColor
            Write-Log "    Set-ADDomainController -Identity $DCName -IsGlobalCatalog \$true" $WarningColor
            exit 1
        }
    } catch {
        Write-Log "  ⚠️  Impossible de vérifier le rôle GC (vérifier manuellement)" $WarningColor
    }

    # ===== CRÉER LES RECORDS A =====
    Write-Log "`n[1/3] Création du record A pour Global Catalog..." $InfoColor

    $gcZoneName = "_msdcs.$Domain"
    $gcName = "gc"

    try {
        $existingRecord = Get-DnsServerResourceRecord -ZoneName $gcZoneName `
                                                     -Name $gcName `
                                                     -ErrorAction SilentlyContinue | Where-Object { $_.RecordType -eq "A" }
        
        if (-not $existingRecord) {
            Add-DnsServerResourceRecordA -ZoneName $gcZoneName `
                                        -Name $gcName `
                                        -IPv4Address $DCIPAddress `
                                        -TimeToLive (10 * 60)  # 10 minutes
            
            Write-Log "  ✓ Record A créé : gc IN A $DCIPAddress" $SuccessColor
        } else {
            Write-Log "  ⊘ Record A existant" $InfoColor
        }
    } catch {
        Write-Log "  ❌ Erreur création record A: $_" $ErrorColor
    }

    # ===== CRÉER LES RECORDS SRV =====
    Write-Log "`n[2/3] Création des records SRV pour Global Catalog..." $InfoColor

    # _ldap._tcp.gc._msdcs.corpmsi.local
    $srvName = "_ldap._tcp.gc"
    $srvTarget = "$DCName.$Domain"
    $srvPort = 3268
    $srvPriority = 0
    $srvWeight = 100

    try {
        $existingSRV = Get-DnsServerResourceRecord -ZoneName $gcZoneName `
                                                  -Name $srvName `
                                                  -ErrorAction SilentlyContinue | Where-Object { $_.RecordType -eq "SRV" }
        
        if (-not $existingSRV) {
            Add-DnsServerResourceRecord -Srv `
                                       -ZoneName $gcZoneName `
                                       -Name $srvName `
                                       -DomainName $srvTarget `
                                       -Priority $srvPriority `
                                       -Weight $srvWeight `
                                       -Port $srvPort `
                                       -TimeToLive (10 * 60)
            
            Write-Log "  ✓ Record SRV créé : _ldap._tcp.gc IN SRV $srvPriority $srvWeight $srvPort $srvTarget" $SuccessColor
        } else {
            Write-Log "  ⊘ Record SRV existant" $InfoColor
        }
    } catch {
        Write-Log "  ❌ Erreur création record SRV: $_" $ErrorColor
    }

    # ===== VÉRIFIER LES RECORDS =====
    Write-Log "`n[3/3] Vérification des records DNS..." $InfoColor

    try {
        $aRecords = Get-DnsServerResourceRecord -ZoneName $gcZoneName -Name "gc" -ErrorAction SilentlyContinue
        if ($aRecords) {
            Write-Log "  ✓ Records A dans zone $gcZoneName :" $SuccessColor
            $aRecords | ForEach-Object { Write-Log "    • $($_.Name) → $($_.RecordData.IPv4Address)" $SuccessColor }
        }
    } catch {
        Write-Log "  ⚠️  Impossible de vérifier les records A" $WarningColor
    }

    try {
        $srvRecords = Get-DnsServerResourceRecord -ZoneName $gcZoneName -Name "_ldap._tcp.gc" -ErrorAction SilentlyContinue
        if ($srvRecords) {
            Write-Log "  ✓ Records SRV dans zone $gcZoneName :" $SuccessColor
            $srvRecords | ForEach-Object { 
                Write-Log "    • $($_.Name) → $($_.RecordData.DomainName):$($_.RecordData.Port)" $SuccessColor 
            }
        }
    } catch {
        Write-Log "  ⚠️  Impossible de vérifier les records SRV" $WarningColor
    }

    # ===== TESTER AVEC DCDIAG =====
    Write-Log "`n=== Tests de validation ===" $InfoColor

    Write-Log "`n⚠️  Exécutez ces commandes pour valider la correction:" $WarningColor
    Write-Log "    dcdiag /test:dns" $InfoColor
    Write-Log "    dcdiag /test:replications" $InfoColor
    Write-Log "    nslookup -type=SRV _ldap._tcp.gc._msdcs.$Domain" $InfoColor
    Write-Log "    nslookup -type=A gc._msdcs.$Domain" $InfoColor

    Write-Log "`n=== Correction DNS terminée ===" $SuccessColor

} catch {
    Write-Log "`n❌ Erreur lors de la correction DNS: $_" $ErrorColor
    exit 1
}
