#  pppoe-failover-script
Un Semplice Script per il Failover tra due PPPoE-Client su Mikrotik 7.x

# 🎱 Perchè?
L'operatore internet Dimensione, offre la possibilità di avere un unico Indirizzo IP su due Tecnologie differenti, ad esempio, Fibra e Antenna WiFi.
Il problema è che è necessario tenere operativa un solo PPPoE-Client la volta. Per questo, questo script, consente di configurare un PPPoE-Client come "Primario" e un PPPoE-Client come "Backup", nel momento in cui qualcosa non va, esegue il passaggio, tenendo un solo PPPoE-Client attivo alla volta.


# ⚙️ Funzionamento

Lo script essenzialmente verifica tre condizioni

- Ping verso un host esterno alla rete
- Lo stato del PPPoE Client Principale
- Lo stato del PPPoE Client di Backup

Su questa base, esegue delle azioni, tenendo a mente che considera un PPPoE-Client il Principale (nella maggior parte dei casi la Fibra) e un PPPoE-Client come Secondario (nella maggior parte dei casi una connessione FWA).

Nel momento in cui il Ping e lo Stato del PPPoE-Client Principali sono anomali, esegue un azione di failover, disabilitando il Client Principale, e passa al Secondario. Se anche il secondario è non funzionante, ritorna sul Principale.

Se il Secondario è funzionante, mantiene attiva la connessione (consentento la connettività) fino a quando, l'orario del Router si trova nel range specificato (normalmente di notte) esegue dei tentativi per riattivare la Linea Principale.


# ☘️ Installazione

## Prima di eseguirlo

Nello script alcune variabili devono essere configurate secondo le nostre esigenze.


| Variabile      | Descrizione | Note |
| ----------- | ----------- | -------------|
| MainPPP|Nome del PPPoE-Client Principale| Solitamente la Fibra       |
| BackupPPP|Nome del PPPoE-Client Secondario | Solitamente la FWA| 
| pppoeWaitTime   | Tempo di attesa necessario alla PPPoE per Autenticarsi non appena attiva.| Solitamente 30s sono più che sufficienti        |
| RecoverTimeStart   | Orario da cui partire con i Tentativi di Ripristino della "MainPPP" | Nel formato HH:MM:SS. Io utilizzo le 21:00:00       |
| RecoverTimeEnd   | Orario in cui Terminare i Tentativi di Ripristino della "MainPPP" | Nel formato HH:MM:SS. Io utilizzo le 08:00:00        |

## 🎉 Il momento più atteso...

Al momento, conviene aprire e copiare e incollare, manualmente nel terminale del Mikrotik, i seguenti comandi:

#### Scarica il File sul Mikrotik
```
/tool fetch url="https://raw.githubusercontent.com/Capobuf/pppoe-failover-script/main/pppoe-failover-script.rsc" mode=https;
```
#### Crea lo Script con il contenuto del file appena scaricato

```
/system script add name=pppoe-failover-script source=[/file get pppoe-failover-script.rsc contents];
```
#### Crea uno Scheduler, che si esegue ogni 5min, a partire da 5min dopo l'avvio del Mikrotik
```
/system scheduler add interval=5m name="schedule-pppoe-failover-script" start-date=Jan/01/2000 start-time=00:05:00 on-event=/system script pppoe-failover-script;
```

# 🗡️ Problemi
Non sono uno Dev e mai lo sarò, e una sequela di IF e Nested IF lo confermano, ma è anche per questo che è su Github! Ogni aiuto è ben accetto! 


# 🚧 To Do

### Forever Under Costruction🚧🚧🚧🚧🚧

Fatto? | Cosa
:---:| ---
💩| Cosa succede se mentre si è in FailOver sulla linea di Backup, va giù anche il Backup?
💩| Magari usare qualche funzione, o comunque evitare una pioggia di IF
✅| Script Funzionante



