# Configuration — Règles de pare-feu pfSense

Ce fichier résume les règles pfSense en production pour l'infrastructure corpmsi.local.

Pour le détail complet et les tableaux, voir : [Règles firewall pfsense](../../docs/chapters/03-pfsense.tex)

## Principes

1. **Règles de haut en bas** : la première qui correspond s'applique
2. **État dynamique** : trafic de retour autorisé automatiquement
3. **Blocage inter-VLAN utilisateurs** : isolés les uns des autres
4. **IT libre** : accès total inter-VLAN pour administration
5. **Restriction RPC** : ports 60000–60099 (au lieu de 49152–65535)

## Interfaces

| Interface | VLAN | Réseau | Passerelle |
|-----------|------|--------|-----------|
| em0 | WAN | DHCP/FAI | — |
| em1 | 40 (Serveurs) | 192.168.40.0/24 | 192.168.40.1 |
| em2 | 20 (Commercial) | 192.168.20.0/24 | 192.168.20.1 |
| em3 | 30 (IT) | 192.168.30.0/24 | 192.168.30.1 |
| em4 | 50 (RH) | 192.168.50.0/24 | 192.168.50.1 |
| em5 | 60 (Comptabilité) | 192.168.60.0/24 | 192.168.60.1 |
| em6 | 10 (Direction) | 192.168.10.0/24 | 192.168.10.1 |

## Règles par interface

### WAN (Internet entrant)

```
BLOQUER | RFC1918 (192.168.0.0/8, 172.16.0.0/12, 10.0.0.0/8) entrant
BLOQUER | Bogon networks
BLOQUER | Tout le reste (règle implicite pfSense)
```

### DIRECTION / COMMERCIAL / RH / COMPTABILITE

```
PASSER  | DHCP Relay → srv-dc01, srv-dc02 (ports 67, 68)
PASSER  | DNS → srv-dc01, srv-dc02 (port 53)
PASSER  | Kerberos → Serveurs (port 88)
PASSER  | LDAP / LDAPS → Serveurs (ports 389, 636)
PASSER  | Global Catalog → Serveurs (ports 3268, 3269)
PASSER  | RPC Endpoint Mapper → Serveurs (port 135)
PASSER  | SMB → Serveurs (port 445)
PASSER  | RPC dynamique restreint → Serveurs (ports 60000–60099)
PASSER  | NTP → Internet (port 123)
BLOQUER | Inter-VLAN utilisateurs (192.168.0.0/8 sauf Serveurs)
PASSER  | HTTP/HTTPS → Internet (ports 80, 443)
BLOQUER | Tout le reste
```

### INFORMATIQUE (IT)

```
PASSER  | DHCP Relay → srv-dc01, srv-dc02
PASSER  | DNS → Serveurs
PASSER  | RDP → Tous les serveurs (port 3389)
PASSER  | WinRM → Serveurs (ports 5985, 5986)
PASSER  | SMB → Serveurs (port 445)
PASSER  | Accès TOTAL inter-VLAN vers 192.168.0.0/8
PASSER  | Internet sans restriction
```

### SERVEURS

```
PASSER  | Trafic interne Serveurs ↔ Serveurs
PASSER  | DNS interne / externe (port 53)
PASSER  | Mises à jour Windows (ports 80, 443)
PASSER  | NTP externe (port 123)
BLOCKER | Initié depuis Serveurs vers autres VLANs (sécurité)
```

## Ports AD critiques

| Port | Service | Protocole | Fonction |
|------|---------|-----------|----------|
| 53 | DNS | TCP/UDP | Résolution noms corpmsi.local |
| 88 | Kerberos | TCP/UDP | Authentification domaine |
| 123 | NTP | UDP | Synchronisation horloge |
| 135 | RPC Mapper | TCP | Négociation ports RPC |
| 389 | LDAP | TCP/UDP | Annuaire AD |
| 445 | SMB | TCP | Fichiers, SYSVOL, GPOs |
| 636 | LDAPS | TCP | LDAP chiffré |
| 3268 | Global Catalog | TCP | Recherche forêt AD |
| 3269 | Global Catalog SSL | TCP | GC chiffré |
| 60000–60099 | RPC dynamique | TCP | Replication, DFS, GPO |

## Isolation inter-VLAN

Matrice de flux (✅ = autorisé, ❌ = bloqué) :

|  | V10 Direction | V20 Commercial | V30 IT | V40 Serveurs | V50 RH | V60 Comptabilité |
|--|:-:|:-:|:-:|:-:|:-:|:-:|
| V10 Direction | — | ❌ | ❌ | ✅ | ❌ | ❌ |
| V20 Commercial | ❌ | — | ❌ | ✅ | ❌ | ❌ |
| V30 IT | ✅ | ✅ | — | ✅ | ✅ | ✅ |
| V40 Serveurs | ❌ | ❌ | ✅ | — | ❌ | ❌ |
| V50 RH | ❌ | ❌ | ❌ | ✅ | — | ❌ |
| V60 Comptabilité | ❌ | ❌ | ❌ | ✅ | ❌ | — |

## Troubleshooting

### Vérifier les hits de règles

```
Firewall → Rules → [Interface] → cliquer l'icône "R" pour voir les statistiques
```

### Dépanner une connexion bloquée

```
Diagnostics → Logs → Firewall → filtrer par IP source/destination
```

### Tester une règle

```
Diagnostics → Packet Capture → sélectionner l'interface → filtrer par port
```

---

*Configuration firewall complète pour corpmsi.local — Mai 2026*
