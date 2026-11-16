# Historique des modifications

## 2026-05-23

- **Diagnostique complet du projet** : correction des erreurs DNS et configuration finale
  - Diagnostic DNS : correction des records manquants sur srv-dc02
  - Diagnostic de réplication : succès complet
  - Diagnostic du service netlogon : validation
  - Diagnostic des services : tous fonctionnels
  - Diagnostic des rôles FSMO : validation sur srv-dc01 et srv-dc02

## 2026-05-22

- **Configuration DFS (Distributed File System)**
  - Installation du rôle DFS sur srv-dc01
  - Création de la racine de namespace (\\corpmsi.local\Partages)
  - Création de l'arborescence DFS complète par département
  - Liaison des dossiers physiques (srv-fichiers01) aux cibles DFS
  - Activation de l'énumération basée sur l'accès (access-based enumeration)
  - Configuration des permissions NTFS par groupe AD

- **Configuration PSO (Password Settings Objects)**
  - PSO pour administrateurs IT (politique stricte)
  - PSO pour employés (politique normale)
  - PSO pour services temporaires (politique spécifique)

## 2026-05-20

- **Configuration des GPO**
  - GPO-PasswordPolicy : politique de mot de passe et verrouillage de compte
  - GPO-BaseSecurity : pare-feu Windows, Windows Defender, SMBv1 désactivé, AutoRun USB désactivé, verrouillage écran
  - GPO-Bitlocker : chiffrement AES-256 avec sauvegarde dans AD

- **Déploiement du serveur de fichiers (srv-fichiers01)**
  - Ajout au domaine
  - Création de partages SMB par département
  - Création du dossier Logiciels centralisé

- **Configuration des GPO départementales**
  - GPO-Comptabilite : blocage des ports USB (USBSTOR)
  - GPO-Informatique : accès panel de contrôle, gestionnaire tâches, configuration WSUS, Block Inheritance

- **Synchronisation NTP**
  - Serveur PDC (srv-dc01) configuré comme serveur NTP fiable
  - Utilisation des pools publics NTP (0.pool.ntp.org, 1.pool.ntp.org)

## 2026-05-18

- **Configuration des GPO de domaine**
  - GPO-PasswordPolicy : 24 password history, 90 days max, 45 days min, 10 chars minimum, complexité activée
  - GPO-BaseSecurity : pare-feu domaine, privé et public, Windows Defender forcé actif, SMBv1 désactivé

## 2026-05-16

- **Configuration DNS**
  - DNS directs pour les ressources AD
  - DNS inverses (reverse lookup zones)
  - Forwarders : 8.8.8.8 (Google) et 1.1.1.1 (Cloudflare)

- **Configuration DHCP**
  - Serveur DHCP sur srv-dc01 pour attribution dynamique des IPs
  - Réservations statiques pour les serveurs
  - Failover DHCP entre srv-dc01 et srv-dc02 (mode Hot Standby)

## 2026-05-15

- **Configuration de pfSense**
  - Adresses IP pour toutes les machines
  - Promotion des serveurs en Domain Controllers
  - Création de la forêt et réplication AD
  - Création des OUs et utilisateurs/groupes
  - Ajout de la workstation (PC-BUR01) au domaine

## 2026-05-13

- **Configuration initiale**
  - Téléchargement et installation des logiciels nécessaires
  - Création des réseaux virtuels (NAT et VMnet2-6) dans VMware Workstation Pro
  - Installation des machines Windows (Servers et Workstation)
  - Installation de pfSense

---

## Format

Ce fichier suit le format [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
