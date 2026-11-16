# Laboratoire Active Directory — MSI Consulting (corpmsi.local)

> Infrastructure complète d'Active Directory en entreprise simulée, déployée sur VMware Workstation Pro avec pfSense, pour apprentissage avancé des services Microsoft.

![Status](https://img.shields.io/badge/Status-Active-success)
![License](https://img.shields.io/badge/License-MIT-blue)
![Platform](https://img.shields.io/badge/Platform-Windows%20Server%202022%20%2F%20pfSense-0078d4)
![Documentation](https://img.shields.io/badge/Documentation-LaTeX-ff69b4)

---

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture réseau](#architecture-réseau)
3. [Pile technique](#pile-technique)
4. [Configuration des VLANs](#configuration-des-vlans)
5. [Plan d'adressage](#plan-dadressage)
6. [Structure du dépôt](#structure-du-dépôt)
7. [Démarrage rapide](#démarrage-rapide)
8. [Documentation complète](#documentation-complète)
9. [Auteur & Licence](#auteur--licence)

---

## Vue d'ensemble

**ad-corpmsi-lab** est une infrastructure Active Directory d'entreprise complète, simulée dans un environnement de laboratoire isolé. Le projet couvre l'intégralité de la stack Microsoft d'administration réseau, avec une emphase particulière sur la sécurité, l'isolation réseau (VLANs) et les opérations réelles.

### Objectifs pédagogiques

- ✅ Maîtriser le déploiement et la configuration d'Active Directory (2 DCs)
- ✅ Configurer les services critiques : DNS, DHCP, NTP, DFS
- ✅ Implémenter les politiques de groupe (GPO) par département
- ✅ Segmenter le réseau avec pfSense (6 VLANs + pare-feu)
- ✅ Déployer un proxy filtrant (Squid + SquidGuard) avec inspection SSL
- ✅ Gérer les partages de fichiers centralisés (SMB + DFS)
- ✅ Diagnostiquer et résoudre les problèmes AD courants

---

## Architecture réseau

```
┌──────────────────────────────────────────────────────────────────┐
│                       Internet / WAN                              │
└─────────────────────────────────┬────────────────────────────────┘
                                  │
                         ┌────────────────────┐
                         │    pfSense CE      │
                         │  192.168.40.1/24   │
                         │  (Firewall/Router) │
                         └────────────────────┘
                                  │
            ┌─────────────────────┼─────────────────────┐
            │                     │                     │
    ┌───────────────┐     ┌──────────────┐     ┌────────────────┐
    │ VLAN 40       │     │  VLAN 10     │     │   VLAN 30      │
    │  SERVEURS     │     │  DIRECTION   │     │ INFORMATIQUE   │
    │192.168.40.0/24│     │192.168.10.0/24│   │192.168.30.0/24 │
    │               │     │              │     │                │
    │ • srv-dc01    │     │ • 5 postes   │     │ • Postes IT    │
    │   (192.168.   │     │   (DHCP)     │     │ • Accès total  │
    │    40.10)     │     │              │     │                │
    │               │     └──────────────┘     └────────────────┘
    │ • srv-dc02    │
    │   (192.168.   │     ┌──────────────┐     ┌────────────────┐
    │    40.11)     │     │  VLAN 20     │     │   VLAN 50      │
    │               │     │  COMMERCIAL  │     │      RH        │
    │ • srv-fichiers│     │192.168.20.0/24│   │192.168.50.0/24 │
    │   (192.168.   │     │              │     │                │
    │    40.20)     │     │ • 3 postes   │     │ • 2 postes     │
    │               │     │   (statique) │     │   (DHCP)       │
    └───────────────┘     └──────────────┘     └────────────────┘
                                                         │
                                          ┌──────────────────────┐
                                          │   VLAN 60            │
                                          │  COMPTABILITÉ        │
                                          │192.168.60.0/24       │
                                          │                      │
                                          │ • 2 postes           │
                                          │   (DHCP)             │
                                          │ • Isolation maximale │
                                          └──────────────────────┘
```

---

## Pile technique

| Outil | Version | Rôle |
|-------|---------|------|
| **VMware Workstation Pro** | 17.x | Hyperviseur |
| **Windows Server 2022** | Std Edition | OS pour DC + serveurs |
| **Windows 11** | 22H2 | Workstation clients |
| **pfSense CE** | 2.7.x | Pare-feu/Routeur/DHCP Relay |
| **Active Directory Domain Services** | 2022 | Annuaire d'entreprise |
| **DNS Server** | 2022 | Résolution de noms (corpmsi.local) |
| **DHCP Server** | 2022 | Attribution IP dynamique |
| **DFS (Distributed File System)** | 2022 | Partages centralisés |
| **Squid** | 6.x | Proxy applicatif transparent |
| **SquidGuard** | 1.4.x | Filtrage URL / Blacklist UT1 |
| **OpenSSL** | 3.x | SSL/TLS MITM pour inspection |

---

## Configuration des VLANs

| VLAN ID | Nom | Réseau | Passerelle | DHCP | Objectif |
|---------|-----|--------|-----------|------|----------|
| 10 | Direction | 192.168.10.0/24 | 192.168.10.1 | Oui | Direction générale |
| 20 | Commercial | 192.168.20.0/24 | 192.168.20.1 | Non | Équipe ventes |
| 30 | Informatique | 192.168.30.0/24 | 192.168.30.1 | Oui | Équipe IT (accès total) |
| 40 | Serveurs | 192.168.40.0/24 | 192.168.40.1 | Non | DCs, NAS, serveurs |
| 50 | RH | 192.168.50.0/24 | 192.168.50.1 | Oui | Ressources Humaines |
| 60 | Comptabilité | 192.168.60.0/24 | 192.168.60.1 | Oui | Finance (isolation max) |

---

## Plan d'adressage

### Serveurs fixes (VLAN 40 — Serveurs)

| Hôte | IP | Rôle |
|------|-----|------|
| srv-dc01 | 192.168.40.10 | DC principal, DNS, DHCP, PDC, NTP |
| srv-dc02 | 192.168.40.11 | DC secondaire, DNS, Global Catalog |
| srv-fichiers01 | 192.168.40.20 | Serveur de fichiers (partages SMB + DFS) |
| pfSense | 192.168.40.1 | Passerelle de tous les VLANs |

### Postes clients (DHCP par VLAN)

| VLAN | Plage DHCP |
|------|------------|
| Direction (V10) | 192.168.10.100 – 150 |
| Commercial (V20) | Statiques uniquement |
| Informatique (V30) | 192.168.30.100 – 150 |
| RH (V50) | 192.168.50.100 – 150 |
| Comptabilité (V60) | 192.168.60.100 – 150 |

---

## Structure du dépôt

```
ad-corpmsi-lab/
├── README.md                              ← Ce fichier
├── LICENSE                                ← Licence MIT
├── CHANGELOG.md                           ← Historique des modifications
├── .gitignore                             ← Configuration Git
│
├── diagrams/                              ← Diagrammes d'architecture
│   ├── README.md
│   ├── ad_corpmsi.drawio                  ← Schéma complet (draw.io)
│   └── ad_corpmsi.png                     ← Export PNG du schéma
│
├── configs/                               ← Fichiers de configuration
│   ├── firewall/
│   │   └── regles_pfsense.md              ← Règles de pare-feu complètes
│   ├── proxy/
│   │   └── squid_squidguard.md            ← Configuration proxy Squid/SquidGuard
│   └── gpo/
│       └── gpo_policies.md                ← Détail des GPOs
│
├── scripts/                               ← Scripts PowerShell/CMD
│   ├── setup-ou-users.ps1                 ← Création OUs et utilisateurs
│   ├── setup-dhcp-scopes.ps1              ← Configuration étendues DHCP + failover
│   ├── setup-dns-forwarders.ps1           ← Forwarders DNS et zones inverses
│   ├── setup-dfs.ps1                      ← Namespace DFS et cibles
│   ├── setup-ntp.ps1                      ← Serveur NTP sur PDC
│   └── fix-dns-gc-records.ps1             ← Correction DNS Global Catalog
│
└── docs/                                  ← Documentation LaTeX complète
    ├── main.tex                           ← Fichier principal
    ├── references.bib                     ← Bibliographie
    ├── images/
    │   └── README.md                      ← Placeholders pour captures
    └── chapters/
        ├── 01-introduction.tex            ← Contexte & objectifs
        ├── 02-architecture.tex            ← Plan IP, VLANs, OUs, VMware
        ├── 03-pfsense.tex                 ← Installation & règles pare-feu
        ├── 04-gpo.tex                     ← Toutes les GPOs détaillées
        ├── 05-dfs-fichiers.tex            ← Serveur fichiers + DFS
        ├── 06-proxy.tex                   ← Squid + SquidGuard + SSL
        ├── 07-ntp.tex                     ← Configuration NTP/PDC
        ├── 08-troubleshooting.tex         ← Cas d'étude DNS complet
        └── 09-ameliorations.tex           ← Futures améliorations
```

---

## Démarrage rapide

### Prérequis

- **VMware Workstation Pro** 17.x ou supérieur
- **Windows Server 2022** (ISO d'installation)
- **Windows 11** (ISO d'installation)
- **pfSense CE 2.7** (ISO d'installation)
- Minimum **32 Go de RAM** sur la machine hôte
- Minimum **100 Go d'espace disque**

### 1. Lire la documentation

La documentation **complète** est disponible en **format LaTeX** dans `/docs/`.

Pour générer le PDF (Linux/macOS/Windows) :

```bash
cd docs
pdflatex -interaction=nonstopmode main.tex
bibtex main
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex
```

Vous obtiendrez `docs/main.pdf` (~150 pages).

### 2. Suivre le déploiement étape par étape

1. **Créer les réseaux VMware** (configuration_vlan_pfsense.md)
   - 6 réseaux host-only (VMnet1–VMnet6) pour les VLANs
   - 1 réseau NAT (VMnet0) pour l'accès Internet

2. **Déployer pfSense** (docs/chapters/03-pfsense.tex)
   - Installer pfSense CE sur une VM avec 8 cartes réseau
   - Configurer les interfaces (em0 = WAN, em1–em6 = VLANs)
   - Configurer les règles de pare-feu et DHCP Relay

3. **Déployer Windows Servers** (docs/chapters/02-architecture.tex)
   - Installer srv-dc01 et srv-dc02
   - Promouvoir en Domain Controllers
   - Configurer DNS, DHCP, DFS, NTP

4. **Exécuter les scripts PowerShell** (scripts/)
   ```powershell
   .\setup-ou-users.ps1
   .\setup-dhcp-scopes.ps1
   .\setup-dns-forwarders.ps1
   .\setup-dfs.ps1
   .\setup-ntp.ps1
   ```

5. **Appliquer les GPOs** (docs/chapters/04-gpo.tex)
   - Créer les OUs par département
   - Configurer les GPOs de sécurité, password policy, BitLocker

6. **Déployer le proxy** (docs/chapters/06-proxy.tex)
   - Installer Squid + SquidGuard sur pfSense
   - Configurer l'inspection SSL MITM
   - Télécharger les blacklists UT1

---

## Documentation complète

### Format LaTeX

Chaque chapitre dans `/docs/chapters/` est auto-contenu et bien structuré :

- **01-introduction.tex** — Contexte du projet, compétences développées
- **02-architecture.tex** — Diagrammes réseaux, IP, VLANs, OUs AD
- **03-pfsense.tex** — Installation de pfSense, règles firewall, NAT, DHCP Relay
- **04-gpo.tex** — Toutes les GPOs : Password Policy, Security, BitLocker, departements
- **05-dfs-fichiers.tex** — Serveur fichiers, partages SMB, namespace DFS, permissions NTFS
- **06-proxy.tex** — Squid, SquidGuard, CA SSL MITM, blacklists, ACLs par VLAN
- **07-ntp.tex** — Configuration NTP sur PDC, synchronisation horloge
- **08-troubleshooting.tex** — Cas d'étude complet DNS, dcdiag, commandes de diagnostic
- **09-ameliorations.tex** — RPC restreint, NAT/Internet, pfBlockerNG, Suricata, OpenVPN

### Format Markdown

Les fichiers dans `/configs/` offrent un résumé rapide de chaque composant :

- [regles_pfsense.md](configs/firewall/regles_pfsense.md) — Tableaux de règles firewall
- [squid_squidguard.md](configs/proxy/squid_squidguard.md) — Configuration proxy et ACLs
- [gpo_policies.md](configs/gpo/gpo_policies.md) — Détail des politiques de groupe

---

## Points clés du projet

### Sécurité

✅ **Segmentation réseau** : 6 VLANs isolés les uns des autres  
✅ **Pare-feu stateful** : pfSense bloque le trafic non autorisé  
✅ **Filtrage URL** : SquidGuard + Blacklist UT1 Toulouse  
✅ **Chiffrement BitLocker** : Disques des postes clients  
✅ **Politique de mot de passe stricte** : 90 jours, complexité, 10 caractères  

### Redondance

✅ **2 Domain Controllers** : Réplication AD complète  
✅ **DHCP Failover** : Hot Standby entre srv-dc01 et srv-dc02  
✅ **DNS Secondaire** : srv-dc02 assume le rôle en cas de défaillance  
✅ **DFS Namespace** : Transparence des partages centralisés  

### Production-Ready

✅ **Inspection SSL MITM** : Détection des malwares HTTPS  
✅ **Audit avancé** : Logs des connexions et modifications AD  
✅ **NTP Stratified** : Synchronisation temps critique pour Kerberos  
✅ **RPC Restreint** : Ports 60000–60099 au lieu de 49152–65535  

---

## Diagnostic et dépannage

### Commandes usuelles

```powershell
# Diagnostic complet AD
dcdiag /test:replications
dcdiag /test:netlogons
dcdiag /test:services
dcdiag /test:fsmocheck

# Vérifier la réplication
repadmin /replsummary

# Synchronisation NTP
w32tm /query /source
w32tm /stripchart /computer:srv-dc01 /samples:3

# Tests réseau
Test-NetConnection -ComputerName 8.8.8.8 -Port 53
Resolve-DnsName corpmsi.local -Server 192.168.40.10

# Vérifier les baux DHCP
Get-DhcpServerv4Lease -ScopeId 192.168.10.0
```

### Problèmes courants et solutions

| Problème | Symptôme | Solution |
|----------|----------|----------|
| Pas d'accès DHCP | Clients en APIPA | Vérifier DHCP Relay pfSense sur le port 67 |
| DNS ne résout pas | nslookup échoue | Vérifier les forwarders et reverse zones |
| GPO non appliquée | Stratégies manquantes | Exécuter `gpupdate /force` sur le poste |
| Replication échouée | dcdiag FAIL | Vérifier le secure channel : `nltest /dsregdns` |
| Port RPC fermé | Connexion refusée | Vérifier les restrictions (60000–60099) |

Pour une résolution complète d'un cas réel, voir [docs/chapters/08-troubleshooting.tex](docs/chapters/08-troubleshooting.tex).

---

## Améliorations futures

Le projet prévoit d'ajouter :

- **RPC sur ports restreints** (60000–60099 fixés)
- **Accès Internet sécurisé** (NAT + proxy obligatoire)
- **pfBlockerNG** (blocage DNS de domaines malveillants)
- **Suricata IDS/IPS** (détection d'attaques Active Directory)
- **OpenVPN** (accès sécurisé au domaine en télétravail)
- **Monitoring SIEM** (centralisation des logs)

Voir [docs/chapters/09-ameliorations.tex](docs/chapters/09-ameliorations.tex) pour détails.

---

## Auteur & Licence

**Créé par** : Équipe IT - MSI Consulting  
**Date** : Mai 2026  
**Licence** : [MIT License](LICENSE)

Ce projet est libre d'utilisation, modification et distribution selon les termes de la licence MIT.

---

**Dernière mise à jour** : 2026-05-23  
**Statut du projet** : ✅ En production (stable)  
**Documentation** : ✅ Complète (200+ pages LaTeX)  
**Scripts** : ✅ Prêts au déploiement
