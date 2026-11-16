# Configuration — Proxy Squid + SquidGuard

Résumé de la configuration proxy pour filtrage d'accès Internet.

Pour le détail complet, voir : [Proxy Squid/SquidGuard](../../docs/chapters/06-proxy.tex)

## Vue d'ensemble

```
Postes clients (V10, V20, V50, V60)
        ↓ HTTP/HTTPS (port 80/443)
[pfSense — Squid Transparent Port 3128]
        ↓ intercept + SSL MITM
[SquidGuard — Filtrage URL + Blacklist UT1]
        ↓ Approuvé ?
[Internet]
```

## Étapes principales

### 1. Certificat CA pour SSL MITM

```
System → Certificate Manager → CAs
Créer : Proxy-CA-corpmsi (RSA 2048, SHA256, 10 ans)
Exporter .crt → Déployer via GPO
```

### 2. Installation Squid

```
System → Package Manager → Installer squid
Services → Squid Proxy → Activer
Interfaces écoutées : V10 Direction, V20 Commercial, V50 RH, V60 Comptabilité
Mode Transparent : oui
Port : 3128
SSL Port : 3129 (MITM)
```

### 3. Installation SquidGuard

```
System → Package Manager → Installer squidguard
Services → SquidGuard → Activer
Blacklist URL : https://dsi.ut-capitole.fr/blacklists/download/blacklists.tar.gz
Cliquer Download (attendre 5–10 min)
```

### 4. Règles NAT (port forward)

Pour chaque interface contrôlée :

```
Firewall → NAT → Port Forward

Port 80 → 127.0.0.1:3128 (HTTP → Squid)
Port 443 → 127.0.0.1:3129 (HTTPS → Squid SSL)
```

### 5. ACLs par VLAN

| VLAN | WL_Autorise | Social | Mail | Chat | Adult | Adult | Download | Défaut |
|------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| Direction | ✅ whitelist | allow | allow | allow | deny | deny | deny | allow |
| Commercial | ✅ whitelist | allow | allow | allow | deny | deny | deny | allow |
| RH | ✅ whitelist | deny | deny | deny | deny | deny | deny | allow |
| Comptabilité | ✅ whitelist | deny | deny | deny | deny | deny | deny | **deny** |
| IT | (bypass proxy) | (libre) | (libre) | (libre) | (libre) | (libre) | (libre) | (libre) |

## Catégories UT1 disponibles

- adult, mixed_adult, lingerie (pornographie)
- gambling, arjel (jeux d'argent)
- dating (sites rencontres)
- audio-video, radio (streaming)
- games (jeux en ligne)
- social_networks, chat, webmail (communications)
- download, warez, filehosting (téléchargements)
- hacking, malware, phishing, cryptojacking (menaces)
- vpn, doh, redirector (contournement)
- Et 20+ autres...

## Page de blocage personnalisée

```bash
# Créer /usr/local/www/blocked.html
# Affichée quand un site est bloqué

HTML personnalisé avec logo corpmsi
```

## Whitelist manuelle (WL_Autorise)

Sites toujours autorisés :

```
microsoft.com
office.com
office365.com
windowsupdate.com
google.com
googleapis.com
paypal.com
stripe.com
kaspersky.com
avast.com
attijariwafabank.com
```

## Troubleshooting

| Problème | Diagnostic | Solution |
|----------|-----------|----------|
| Proxy ne filtre pas | `curl -x 127.0.0.1:3128 http://test.com` | Vérifier mode transparent + NAT |
| Erreurs SSL | Certificat = autorite originale | Deployer CA via GPO |
| Blacklist vide | `ls /var/squidGuard/blacklists/` vide | Re-télécharger + redémarrer SquidGuard |
| Certains sites passent | ACL mal configurée | Vérifier l'ordre des rules (whitelist en premier) |

## Cache Squid

```
Cache Replacement Policy : heap LFUDA
Disk Cache : 2048 MB
Memory Cache : 256 MB
Maximum Object Size : 512 MB
```

## Métriques à surveiller

```
Logs Squid : /var/log/squid/access.log
Logs SquidGuard : /var/log/squidGuard/squidGuard.log

Requêtes bloquées :
  tail -f /var/log/squidGuard/squidGuard.log | grep BLOCK
```

---

*Configuration proxy complète pour corpmsi.local — Mai 2026*
