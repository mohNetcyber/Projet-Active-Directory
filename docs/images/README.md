# Images et captures

Ce dossier contiendra les captures d'écran et images de référence pour la documentation LaTeX.

## Images requises

### Architecture et diagrammes

- [x] `network-topology.png` — Topologie réseau complète avec les 6 VLANs
- [x] Lan Segment.png` — Configuration Des Lan Segment
	![[Lan Segment.png]]
	- [x] `pfsense-interfaces.png` — Interfaces pfSense (em0–em6)
	![[pfSense-Interfaces.png]]

### pfSense

- [x] `pfsense-setup-wizard.png` — Assistant de configuration
- [x] `pfsense-firewall-rules.png` — Tableau de règles firewall
	![[WAN Rules.png]]
	![[Serveurs Rules.png]]
	![[Informatiques Rules.png]]
	![[DIR-RH-COMM Rules.png]]
	![[Comptabilte Rules.png]]

- [x] `pfsense-dhcp-relay.png` — Configuration DHCP Relay
	![[DHCP Relay.png]]
- [x] `pfsense-nat-rules.png` — Règles NAT pour proxy
	![[NAT Rules.png]]

### Active Directory

- [x] `aduc-ou-structure.png` — Structure des OUs complète
	![[Structure-OU.png]]
- [x] `gpo-policy-editor.png` — Éditeur de stratégie de groupe
	![[GPO Management.png]]
- [x] `dfs-namespace.png` — Namespace DFS dans DFS Management
	![[DFS Management.png]]

### Proxy

- [x] `squid-configuration.png` — Configuration Squid dans pfSense
	![[Squid Config general.png]]
- [x] `squidguard-acl.png` — ACLs SquidGuard par VLAN
	
- [x] `blocked-page.png` — Page de blocage personnalisée
	![[Page de bloquage.png]]

### DNS / DHCP

- [x] `dns-manager.png` — DNS Manager avec zones
	![[DNS Manager.png]]
- [x] `dhcp-scopes.png` — Étendues DHCP configurées
	![[Scope DHCP.png]]

### Troubleshooting

- [ ] `dcdiag-output.png` — Résultat dcdiag avant correction
- [ ] `dcdiag-fixed.png` — Résultat dcdiag après correction
- [ ] `nslookup-gc-records.png` — Vérification des records GC

## Format

- **Format**: PNG
- **Résolution**: 1024×768 minimum
- **Compression**: PNG compressé (sans perte)
- **Aspect**: Captures pures (sans annotations)

## Utilisation dans LaTeX

Les images sont référencées dans les fichiers `chapters/*.tex` avec le pattern :

```latex
\begin{figure}[H]
    \centering
    \fbox{\parbox{0.85\linewidth}{\centering\vspace{2cm}
    \textit{[Screenshot: DESCRIPTION]}\vspace{2cm}}}
    \caption{CAPTION}
    \label{fig:LABEL}
\end{figure}
```

Remplacer progressivement par `\includegraphics[width=0.9\linewidth]{images/image.png}` quand disponible.

---

*Placeholders pour captures d'écran — Mai 2026*
