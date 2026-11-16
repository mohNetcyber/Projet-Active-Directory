# ad-corpmsi-lab — Infrastructure Active Directory complète

Bienvenue dans ce laboratoire complet d'Active Directory. Voici l'état du dépôt.

## 📦 Contenu du dépôt

### Fichiers racine
- ✅ **README.md** — Vue d'ensemble complète avec diagrammes ASCII
- ✅ **CHANGELOG.md** — Historique des modifications
- ✅ **LICENSE** — Licence MIT
- ✅ **.gitignore** — Configuration Git (LaTeX, Windows, IDE)

### 📂 Répertoires

#### `scripts/` — Automatisation PowerShell (6 scripts)
- ✅ `setup-ou-users.ps1` — Crée OUs, utilisateurs, groupes
- ✅ `setup-dhcp-scopes.ps1` — Configure étendues DHCP + failover
- ✅ `setup-dns-forwarders.ps1` — Ajoute forwarders DNS + zones inverses
- ✅ `setup-dfs.ps1` — Crée namespace DFS et cibles
- ✅ `setup-ntp.ps1` — Configure NTP sur PDC
- ✅ `fix-dns-gc-records.ps1` — Corrige records DNS Global Catalog

#### `configs/` — Fichiers de configuration
- ✅ `firewall/regles_pfsense.md` — Règles pare-feu complètes
- ✅ `proxy/squid_squidguard.md` — Configuration proxy Squid/SquidGuard
- ✅ `gpo/gpo_policies.md` — Détail des GPOs par département

#### `diagrams/` — Schémas réseau
- ✅ `README.md` — Documentation des diagrammes
- ⏳ `ad_corpmsi.drawio` — Schéma draw.io (à générer)
- ⏳ `ad_corpmsi.png` — Export PNG (à générer)

#### `docs/` — Documentation LaTeX complète (200+ pages)
- ✅ `main.tex` — Fichier principal LaTeX
- ✅ `references.bib` — Bibliographie
- ✅ `images/README.md` — Placeholders pour screenshots

##### `docs/chapters/` — 9 chapitres
- ✅ `01-introduction.tex` — Contexte, objectifs, apprentissages
- ✅ `02-architecture.tex` — Plan IP, VLANs, OUs, VMware
- ✅ `03-pfsense.tex` — Installation, config, règles firewall
- ✅ `04-gpo.tex` — Politiques de groupe détaillées
- ✅ `05-dfs-fichiers.tex` — Serveur fichiers + DFS
- ✅ `06-proxy.tex` — Squid + SquidGuard + SSL MITM
- ✅ `07-ntp.tex` — Configuration NTP/PDC
- ✅ `08-troubleshooting.tex` — Cas d'étude DNS complet
- ✅ `09-ameliorations.tex` — Futures extensions

## 🚀 Démarrage rapide

### 1. Générer la documentation PDF

```bash
cd docs
pdflatex -interaction=nonstopmode main.tex
bibtex main
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex
```

Résultat : `docs/main.pdf` (~180 pages)

### 2. Déployer l'infrastructure

Suivre les étapes dans la documentation LaTeX:
1. **Chapitre 2** — Architecture et VMware
2. **Chapitre 3** — pfSense
3. **Chapitre 2/4** — AD et GPOs
4. Exécuter les scripts PowerShell dans `scripts/`

### 3. Tester

Depuis un poste client, valider :
```powershell
nslookup corpmsi.local 192.168.40.10
gpupdate /force
net view \\corpmsi.local\Partages
```

## 🎯 Compétences développées

Au terme de ce projet, vous maîtriserez :

- ✅ Active Directory (OUs, GPOs, réplication, PSO)
- ✅ Services réseau (DNS, DHCP, NTP, DFS)
- ✅ Pare-feu et segmentation (VLANs, pfSense)
- ✅ Proxy et filtrage (Squid, SquidGuard)
- ✅ Sécurité (BitLocker, GPOs, isolation)
- ✅ Troubleshooting (diagnostique DNS, dcdiag)
- ✅ PowerShell pour automatisation

## 📊 Statistiques du dépôt

| Élément | Nombre |
|---------|--------|
| Fichiers root | 4 |
| Scripts PowerShell | 6 |
| Fichiers config Markdown | 3 |
| Chapitres LaTeX | 9 |
| Lignes de LaTeX | ~2000 |
| Lignes PowerShell | ~800 |
| OUs AD | 6 |
| VLANs | 6 |
| Ports AD documentés | 15+ |

## 📝 Notes importantes

### Prérequis
- VMware Workstation Pro 17+
- Windows Server 2022 ISO
- Windows 11 ISO
- pfSense CE 2.7 ISO
- 32 Go RAM, 100 Go disque

### Temps estimé
- Lecture complète : 8–10 heures
- Déploiement complet : 4–6 heures
- Troubleshooting : variable

### Points critiques
1. **PDC et NTP** — Absolument critique
2. **Secure channel Kerberos** — Foundation de l'AD
3. **Ports pare-feu** — Bloquer 1 port = infrastructure paralysée
4. **DNS zones inverses** — Essential pour dcdiag
5. **Timezone cohérente** — Cause subtile de problèmes

## 🤝 Contribution

Ce projet est open-source (MIT). Contributions bienvenues :

- [ ] Ajouter screenshots/diagrammes
- [ ] Traduire en anglais
- [ ] Ajouter Terraform/Ansible
- [ ] Expander sur haute disponibilité
- [ ] Ajouter configuration SIEM

## 📞 Support

Pour toute question ou problème :

1. Consulter la documentation LaTeX (spécifiquement ch.8 — Troubleshooting)
2. Vérifier les commandes PowerShell dans `/scripts`
3. Référencer les logs : Event Viewer, pfSense dashboard, dcdiag

## 🔗 Références

- [Microsoft AD Documentation](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/)
- [pfSense Documentation](https://docs.netgate.com/)
- [Squid Cache](http://www.squid-cache.org/)
- [Windows Time Service](https://docs.microsoft.com/en-us/windows-server/networking/windows-time-service/)

---

**Créé par** : Équipe IT - MSI Consulting  
**Date** : Mai 2026  
**Licence** : MIT  
**Statut** : ✅ Production (Stable)

*Infrastructure complète d'Active Directory pour laboratoire et apprentissage avancé.*
