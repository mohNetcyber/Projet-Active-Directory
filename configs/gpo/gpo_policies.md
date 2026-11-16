# Configuration — Politiques de groupe (GPOs)

Récapitulatif des GPOs déployées sur corpmsi.local.

Pour le détail complet et captures, voir : [Group Policy Objects](../../docs/chapters/04-gpo.tex)

## GPOs au niveau du domaine

### GPO-PasswordPolicy

**Appliquée sur** : Racine du domaine

| Paramètre | Valeur | Justification |
|-----------|--------|---------------|
| Password history | 24 mots de passe | Empêche réutilisation immédiate |
| Max age | 90 jours | Force changement régulier |
| Min age | 45 jours | Empêche changement trop fréquent |
| Min length | 10 caractères | Sécurité suffisante |
| Complexity required | Oui | Majuscule, minuscule, chiffre, symbole |
| Store with reversible encryption | Non | Les mots de passe restent hashés |

**Account Lockout Policy** :

| Paramètre | Valeur |
|-----------|--------|
| Lockout threshold | 5 tentatives |
| Lockout duration | 30 minutes |
| Lockout counter reset | 30 minutes |

### GPO-BaseSecurity

**Appliquée sur** : Tous les postes

Firewall Windows activé :
- ✅ Domain profile
- ✅ Private profile
- ✅ Public profile

Windows Defender :
- ✅ Force activation (disable toggle désactivé)
- ✅ Real-time protection enabled

Sécurité réseau :
- ✅ SMBv1 désactivé (Network → Lanman Workstation)
- ✅ AutoRun USB désactivé (AutoPlay Policies)
- ✅ Screen saver timeout : 10 min
- ✅ Screen saver password : oui

### GPO-Bitlocker

**Appliquée sur** : Postes sensibles

| Paramètre | Valeur |
|-----------|--------|
| Encryption method | AES 256 |
| Drive encryption type | Used space only |
| Startup authentication | TPM + PIN (si pas TPM) |
| Save recovery key | Active Directory |

---

## GPOs par département

### GPO-Direction

*(Héritée de BaseSecurity + PasswordPolicy)*

- Accès Internet proxy (filtrage SquidGuard)
- Social networks : allowed
- Video streaming : denied
- File download : denied

### GPO-Commercial

*(Héritée de BaseSecurity + PasswordPolicy)*

- Accès Internet proxy (filtrage SquidGuard)
- Social networks : allowed
- Email access : allowed
- File download : denied
- Isolation VLAN V20

### GPO-RH

*(Héritée de BaseSecurity + PasswordPolicy + Bitlocker)*

**Blocage USB (USBSTOR)** :
```
Registre : HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR
Valeur : start = 4 (désactiver)
```

- Internet proxy (très restrictif)
- Social networks : denied
- Email access : denied
- File download : denied
- Isolation VLAN V50
- Chiffrage BitLocker obligatoire

### GPO-Comptabilite

*(Héritée de BaseSecurity + PasswordPolicy + Bitlocker)*

**Blocage USB** : oui (idem RH)

**Internet** :
- HTTP/HTTPS proxy (très restrictif)
- HTTPS only (pas HTTP)
- Tous les téléchargements bloqués

- Email access : allowed (banque seulement via whitelist)
- Social networks : blocked
- Isolation VLAN V60
- Chiffrage BitLocker obligatoire

### GPO-Informatique

*(Block Inheritance activé pour ignorer les politiques parents)*

**Libertés accordées** :
- ✅ Accès panel de configuration complet
- ✅ Gestionnaire de tâches accessible
- ✅ Ligne de commande (PowerShell) débloquée
- ✅ Installation logiciels (avec restrictions Admin)

**Contrôles** :
- ✅ WSUS obligatoire (mises à jour depuis srv-dc01:8530)
- ✅ Windows Defender toujours actif
- ✅ Firewall Windows toujours actif
- ✅ Internet proxy désactivé (accès direct)

### GPO-Serveurs

**Appliquée sur** : OU=Serveurs (DC, NAS)

- ❌ Print Spooler service disabled (DCs n'impriment pas)
- ✅ Firewall Windows enabled
- ✅ Advanced audit logging
  - Authentification Kerberos
  - Modification objets AD
  - Accès fichiers critiques
- ✅ Event log retention : 7 jours minimum

---

## PSO (Password Settings Objects)

Permet plusieurs politiques de mot de passe dans le même domaine :

| Groupe | Min Length | Max Age | History | Lockout Threshold |
|--------|:-:|:-:|:-:|:-:|
| IT Admins | 15 | 60 j | 24 | 3 |
| Utilisateurs | 10 | 90 j | 24 | 5 |
| Temp Services | 12 | 30 j | 10 | 5 |

**Déploiement** :
```
ADAC → Password Settings Container → New Password Setting
```

---

## Héritage et ordre d'application

```
Domain (PasswordPolicy)
  ├── BaseSecurity (tous les postes)
  │
  ├── OU=Direction
  │   └── hérite BaseSecurity + PasswordPolicy
  │
  ├── OU=Commercial
  │   └── hérite BaseSecurity + PasswordPolicy
  │
  ├── OU=RH
  │   ├── hérite BaseSecurity + PasswordPolicy + Bitlocker
  │   └── GPO-RH (USB bloqué)
  │
  ├── OU=Comptabilite
  │   ├── hérite BaseSecurity + PasswordPolicy + Bitlocker
  │   └── GPO-Comptabilite (USB bloqué, HTTPS only)
  │
  ├── OU=Informatique
  │   ├── Block Inheritance = oui
  │   └── GPO-Informatique seule (pas d'héritage)
  │
  └── OU=Serveurs
      └── GPO-Serveurs (Spooler off, audit on)
```

## Vérification de l'application

```powershell
# Forcer la mise à jour des GPOs
gpupdate /force

# Voir les GPOs appliquées
gpresult /h report.html

# Lister les GPOs d'une OU
Get-GPOReport -All -ReportType Html -Path ./report.html

# Tester une GPO spécifique
Get-GPResultantSetOfPolicy -ComputerName PC-BUR01 -ReportType Html
```

---

*Politiques de groupe pour corpmsi.local — Mai 2026*
