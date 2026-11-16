#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Configure les forwarders DNS et crée les zones inverses.

.DESCRIPTION
    Ce script ajoute les forwarders DNS (Google, Cloudflare) et crée
    les zones de recherche inversée pour la résolution DNS inverse.

.PREREQUISITES
    - Windows Server 2022 avec rôle DNS installé
    - srv-dc01 (DNS principal)

.AUTHOR
    Équipe IT - MSI Consulting

.EXAMPLE
    .\setup-dns-forwarders.ps1

.NOTES
    Date: Mai 2026
    Domaine: corpmsi.local
    Forwarders: 8.8.8.8 (Google), 1.1.1.1 (Cloudflare)
#>

#Requires -Modules DnsServer

param(
    [string[]]$Forwarders = @("8.8.8.8", "1.1.1.1"),
    [string]$Domain = "corpmsi.local",
    [string]$DomainDN = "DC=corpmsi,DC=local"
)

$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"

function Write-Log {
    param($Message, $Color = $InfoColor)
    Write-Host $Message -ForegroundColor $Color
}

try {
    Write-Log "`n=== Configuration DNS ===" $InfoColor

    # ===== AJOUTER LES FORWARDERS =====
    Write-Log "`n[1/3] Ajout des forwarders DNS..." $InfoColor

    foreach ($forwarder in $Forwarders) {
        $existing = Get-DnsServerForwarder -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -eq $forwarder }
        
        if (-not $existing) {
            Add-DnsServerForwarder -IPAddress $forwarder -PassThru
            Write-Log "  ✓ Forwarder ajouté : $forwarder" $SuccessColor
        } else {
            Write-Log "  ⊘ Forwarder déjà présent : $forwarder" $InfoColor
        }
    }

    # Tester la résolution externe
    Write-Log "`n  Test de résolution externe..." $InfoColor
    try {
        $result = Resolve-DnsName -Name "microsoft.com" -Server 127.0.0.1 -ErrorAction SilentlyContinue
        if ($result) {
            Write-Log "  ✓ Résolution microsoft.com réussie" $SuccessColor
        }
    } catch {
        Write-Log "  ⚠️  Résolution externe échouée (normal sur DC isolé)" $InfoColor
    }

    # ===== CRÉER LES ZONES INVERSES =====
    Write-Log "`n[2/3] Création des zones de recherche inversée..." $InfoColor

    $ReverseZones = @(
        @{Network = "10.168.192.in-addr.arpa"; Description = "V10 - Direction"},
        @{Network = "20.168.192.in-addr.arpa"; Description = "V20 - Commercial"},
        @{Network = "30.168.192.in-addr.arpa"; Description = "V30 - Informatique"},
        @{Network = "40.168.192.in-addr.arpa"; Description = "V40 - Serveurs"},
        @{Network = "50.168.192.in-addr.arpa"; Description = "V50 - RH"},
        @{Network = "60.168.192.in-addr.arpa"; Description = "V60 - Comptabilité"}
    )

    foreach ($zone in $ReverseZones) {
        $existingZone = Get-DnsServerZone -Name $zone.Network -ErrorAction SilentlyContinue
        
        if (-not $existingZone) {
            Add-DnsServerPrimaryZone -Name $zone.Network `
                                     -ReplicationScope Domain `
                                     -PassThru
            Write-Log "  ✓ Zone inverse créée : $($zone.Network) ($($zone.Description))" $SuccessColor
        } else {
            Write-Log "  ⊘ Zone inverse existante : $($zone.Network)" $InfoColor
        }
    }

    # ===== CRÉER LES RECORDS PTR =====
    Write-Log "`n[3/3] Création des enregistrements PTR..." $InfoColor

    $PtrRecords = @(
        @{Zone = "40.168.192.in-addr.arpa"; IPReverse = "10.40.168.192"; FQDN = "srv-dc01.$Domain"},
        @{Zone = "40.168.192.in-addr.arpa"; IPReverse = "11.40.168.192"; FQDN = "srv-dc02.$Domain"},
        @{Zone = "40.168.192.in-addr.arpa"; IPReverse = "20.40.168.192"; FQDN = "srv-fichiers01.$Domain"}
    )

    foreach ($ptr in $PtrRecords) {
        $existing = Get-DnsServerResourceRecord -ZoneName $ptr.Zone `
                                               -Name $ptr.IPReverse `
                                               -ErrorAction SilentlyContinue | Where-Object { $_.RecordType -eq "PTR" }
        
        if (-not $existing) {
            Add-DnsServerResourceRecordPtr -ZoneName $ptr.Zone `
                                           -Name $ptr.IPReverse `
                                           -PtrDomainName $ptr.FQDN `
                                           -PassThru
            Write-Log "  ✓ Record PTR créé : $($ptr.IPReverse) → $($ptr.FQDN)" $SuccessColor
        } else {
            Write-Log "  ⊘ Record PTR existant : $($ptr.IPReverse)" $InfoColor
        }
    }

    Write-Log "`n=== Configuration DNS complète ===" $SuccessColor
    Write-Log "Forwarders configurés: $($Forwarders.Count)" $InfoColor
    Write-Log "Zones inverses créées: 6" $InfoColor
    Write-Log "Records PTR créés: 3" $InfoColor

    # Afficher les forwarders
    Write-Log "`nForwarders actuels:" $InfoColor
    Get-DnsServerForwarder | ForEach-Object { Write-Log "  • $_" $SuccessColor }

} catch {
    Write-Log "`n❌ Erreur lors de la configuration DNS: $_" $ErrorColor
    exit 1
}
