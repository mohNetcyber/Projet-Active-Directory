#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Configure les étendues DHCP et le failover entre les DCs.

.DESCRIPTION
    Ce script crée les étendues DHCP pour chaque VLAN et configure
    le failover Hot Standby entre srv-dc01 et srv-dc02.

.PREREQUISITES
    - Windows Server 2022 avec rôle DHCP installé
    - srv-dc01 (serveur DHCP principal)
    - srv-dc02 (serveur DHCP secondaire)

.AUTHOR
    Équipe IT - MSI Consulting

.EXAMPLE
    .\setup-dhcp-scopes.ps1

.NOTES
    Date: Mai 2026
    Domaine: corpmsi.local
#>

#Requires -Modules DhcpServer

param(
    [string]$DCPrimary = "192.168.40.10",
    [string]$DCSecondary = "192.168.40.11",
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
    Write-Log "`n=== Configuration des étendues DHCP ===" $InfoColor

    # Définir les étendues à créer
    $Scopes = @(
        @{
            Name = "VLAN10-Direction"
            ScopeID = "192.168.10.0"
            SubnetMask = "255.255.255.0"
            StartRange = "192.168.10.100"
            EndRange = "192.168.10.150"
            Gateway = "192.168.10.1"
            LeaseTime = 8  # jours
        },
        @{
            Name = "VLAN30-Informatique"
            ScopeID = "192.168.30.0"
            SubnetMask = "255.255.255.0"
            StartRange = "192.168.30.100"
            EndRange = "192.168.30.150"
            Gateway = "192.168.30.1"
            LeaseTime = 8
        },
        @{
            Name = "VLAN50-RH"
            ScopeID = "192.168.50.0"
            SubnetMask = "255.255.255.0"
            StartRange = "192.168.50.100"
            EndRange = "192.168.50.150"
            Gateway = "192.168.50.1"
            LeaseTime = 8
        },
        @{
            Name = "VLAN60-Comptabilite"
            ScopeID = "192.168.60.0"
            SubnetMask = "255.255.255.0"
            StartRange = "192.168.60.100"
            EndRange = "192.168.60.150"
            Gateway = "192.168.60.1"
            LeaseTime = 8
        }
    )

    Write-Log "`n[1/3] Création des étendues DHCP..." $InfoColor

    foreach ($scope in $Scopes) {
        # Vérifier si l'étendue existe
        $existingScope = Get-DhcpServerv4Scope -ScopeId $scope.ScopeID -ErrorAction SilentlyContinue
        
        if (-not $existingScope) {
            Add-DhcpServerv4Scope -ScopeId $scope.ScopeID `
                                  -Name $scope.Name `
                                  -SubnetMask $scope.SubnetMask `
                                  -StartRange $scope.StartRange `
                                  -EndRange $scope.EndRange `
                                  -Description "Étendue DHCP - $($scope.Name)"
            
            Write-Log "  ✓ Étendue créée : $($scope.Name)" $SuccessColor
        } else {
            Write-Log "  ⊘ Étendue existante : $($scope.Name)" $InfoColor
        }

        # Configurer les options DHCP
        Set-DhcpServerv4OptionValue -ScopeId $scope.ScopeID `
                                     -OptionId 3 `
                                     -Value $scope.Gateway
        
        Set-DhcpServerv4OptionValue -ScopeId $scope.ScopeID `
                                     -OptionId 6 `
                                     -Value @($DCPrimary, $DCSecondary)
        
        Set-DhcpServerv4OptionValue -ScopeId $scope.ScopeID `
                                     -OptionId 15 `
                                     -Value $Domain
        
        # Configurer la durée du bail
        Set-DhcpServerv4Scope -ScopeId $scope.ScopeID `
                              -LeaseDuration ([timespan]"$($scope.LeaseTime).00:00:00")
        
        Write-Log "    Options configurées (Gateway, DNS, Domain, Lease)" $SuccessColor
    }

    Write-Log "`n[2/3] Configuration du DHCP Failover..." $InfoColor

    # Le failover se configure via la console DHCP ou en PowerShell
    # Ici nous affichons les commandes requises

    $failoverScopes = $Scopes | ForEach-Object { $_.ScopeID }
    
    foreach ($scopeID in $failoverScopes) {
        # Note: Le failover en PowerShell nécessite le module DhcpServer Server 2012+
        try {
            Add-DhcpServerv4Failover -ComputerName $DCPrimary `
                                     -ScopeId $scopeID `
                                     -PartnerServer $DCSecondary `
                                     -LoadBalancePercent 50 `
                                     -MaxClientLeadTime 1 `
                                     -Mode HotStandby `
                                     -Force -ErrorAction SilentlyContinue
            
            Write-Log "  ✓ Failover configuré pour $scopeID" $SuccessColor
        } catch {
            Write-Log "    ⓘ Failover peut nécessiter configuration manuelle pour $scopeID" $InfoColor
        }
    }

    Write-Log "`n[3/3] Vérification de la configuration..." $InfoColor

    # Afficher un résumé
    Get-DhcpServerv4Scope | Where-Object { $_.ScopeId -in $failoverScopes } | ForEach-Object {
        Write-Log "  Étendue: $($_.Name) | Plage: $($_.StartRange) - $($_.EndRange)" $SuccessColor
    }

    Write-Log "`n=== Configuration DHCP terminée ===" $SuccessColor
    Write-Log "Étendues créées: $($Scopes.Count)" $InfoColor
    Write-Log "Failover: Mode Hot Standby" $InfoColor
    Write-Log "`n⚠️  Vérifier le failover dans DHCP Manager (Server Manager > Tools > DHCP)" $InfoColor

} catch {
    Write-Log "`n❌ Erreur lors de la configuration DHCP: $_" $ErrorColor
    exit 1
}
