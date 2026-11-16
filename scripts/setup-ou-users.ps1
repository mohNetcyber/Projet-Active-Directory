#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Crée la structure d'Unités Organisationnelles et les utilisateurs/groupes.

.DESCRIPTION
    Ce script crée l'arborescence AD complète pour corpmsi.local avec :
    - 6 OUs (Direction, Commercial, IT, RH, Comptabilité, Serveurs)
    - Utilisateurs de test par département
    - Groupes de sécurité pour les partages

.PREREQUISITES
    - Windows Server 2022 avec AD DS installé
    - Rôle PDC (srv-dc01)
    - Module Active Directory PowerShell

.AUTHOR
    Équipe IT - MSI Consulting

.EXAMPLE
    .\setup-ou-users.ps1

.NOTES
    Date: Mai 2026
    Domaine: corpmsi.local
#>

param(
    [string]$Domain = "corpmsi.local",
    [string]$DomainDN = "DC=corpmsi,DC=local"
)

# Couleurs pour les messages
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"

function Write-Log {
    param($Message, $Color = $InfoColor)
    Write-Host $Message -ForegroundColor $Color
}

try {
    Write-Log "`n=== Création de la structure Active Directory ===" $InfoColor

    # ===== CRÉER LES OUs =====
    Write-Log "`n[1/3] Création des Unités Organisationnelles..." $InfoColor

    $OUs = @(
        @{Name = "Direction"; Path = $DomainDN},
        @{Name = "Commercial"; Path = $DomainDN},
        @{Name = "Informatique"; Path = $DomainDN},
        @{Name = "RH"; Path = $DomainDN},
        @{Name = "Comptabilite"; Path = $DomainDN},
        @{Name = "Serveurs"; Path = $DomainDN}
    )

    foreach ($ou in $OUs) {
        $ouPath = "OU=$($ou.Name),$($ou.Path)"
        
        if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$($ou.Name)'" -ErrorAction SilentlyContinue)) {
            New-ADOrganizationalUnit -Name $ou.Name -Path $ou.Path
            Write-Log "  ✓ OU créée : $($ou.Name)" $SuccessColor
        } else {
            Write-Log "  ⊘ OU existante : $($ou.Name)" $InfoColor
        }
    }

    # ===== CRÉER LES GROUPES DE SÉCURITÉ =====
    Write-Log "`n[2/3] Création des groupes de sécurité..." $InfoColor

    $Groups = @(
        @{Name = "GRP_Direction"; Path = "OU=Direction,$DomainDN"},
        @{Name = "GRP_Commercial"; Path = "OU=Commercial,$DomainDN"},
        @{Name = "GRP_Informatique"; Path = "OU=Informatique,$DomainDN"},
        @{Name = "GRP_RH"; Path = "OU=RH,$DomainDN"},
        @{Name = "GRP_Comptabilite"; Path = "OU=Comptabilite,$DomainDN"}
    )

    foreach ($group in $Groups) {
        if (-not (Get-ADGroup -Filter "Name -eq '$($group.Name)'" -ErrorAction SilentlyContinue)) {
            New-ADGroup -Name $group.Name `
                        -SamAccountName $group.Name `
                        -GroupCategory Security `
                        -GroupScope Global `
                        -Path $group.Path `
                        -Description "Groupe de sécurité - $($group.Name)"
            Write-Log "  ✓ Groupe créé : $($group.Name)" $SuccessColor
        } else {
            Write-Log "  ⊘ Groupe existant : $($group.Name)" $InfoColor
        }
    }

    # ===== CRÉER LES UTILISATEURS =====
    Write-Log "`n[3/3] Création des utilisateurs de test..." $InfoColor

    $Users = @(
        @{Name = "alice.dupont"; Dept = "Direction"; Group = "GRP_Direction"; OU = "OU=Direction,$DomainDN"},
        @{Name = "bob.martin"; Dept = "Commercial"; Group = "GRP_Commercial"; OU = "OU=Commercial,$DomainDN"},
        @{Name = "charlie.bernard"; Dept = "Commercial"; Group = "GRP_Commercial"; OU = "OU=Commercial,$DomainDN"},
        @{Name = "david.laurent"; Dept = "IT"; Group = "GRP_Informatique"; OU = "OU=Informatique,$DomainDN"},
        @{Name = "eve.moreau"; Dept = "RH"; Group = "GRP_RH"; OU = "OU=RH,$DomainDN"},
        @{Name = "frank.petit"; Dept = "RH"; Group = "GRP_RH"; OU = "OU=RH,$DomainDN"},
        @{Name = "grace.roux"; Dept = "Comptabilité"; Group = "GRP_Comptabilite"; OU = "OU=Comptabilite,$DomainDN"},
        @{Name = "henry.blanc"; Dept = "Comptabilité"; Group = "GRP_Comptabilite"; OU = "OU=Comptabilite,$DomainDN"}
    )

    $DefaultPassword = ConvertTo-SecureString -AsPlainText "P@ssw0rd123" -Force

    foreach ($user in $Users) {
        $samAccount = $user.Name.Replace(".", "")
        
        if (-not (Get-ADUser -Filter "SamAccountName -eq '$samAccount'" -ErrorAction SilentlyContinue)) {
            New-ADUser -SamAccountName $samAccount `
                       -UserPrincipalName "$($user.Name)@$Domain" `
                       -Name $user.Name `
                       -GivenName ($user.Name.Split(".")[0]) `
                       -Surname ($user.Name.Split(".")[1]) `
                       -Enabled $true `
                       -Path $user.OU `
                       -AccountPassword $DefaultPassword `
                       -ChangePasswordAtLogon $true `
                       -Department $user.Dept
            
            # Ajouter l'utilisateur au groupe
            Add-ADGroupMember -Identity $user.Group -Members $samAccount
            
            Write-Log "  ✓ Utilisateur créé : $($user.Name) (groupe: $($user.Group))" $SuccessColor
        } else {
            Write-Log "  ⊘ Utilisateur existant : $($user.Name)" $InfoColor
        }
    }

    Write-Log "`n=== Structure Active Directory créée avec succès ===" $SuccessColor
    Write-Log "Domaine: $Domain" $InfoColor
    Write-Log "OUs créées: 6" $InfoColor
    Write-Log "Groupes créés: 5" $InfoColor
    Write-Log "Utilisateurs créés: 8" $InfoColor

} catch {
    Write-Log "`n❌ Erreur lors de la création: $_" $ErrorColor
    exit 1
}
