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

# Codice

La prima parte dichiara un po di variabili globali, probabilmente molte di queste, se non tutte, potrebbero essere convertite in locali.

Tutto si apre con un `:do{}`, dove all'interno, scrivo nel log del mikrotik che lo script è in esecuzione.

Successivamente, controllo lo stato delle PPPoE tramite `pppoe-client monitor` che a differenza di `get status` che riporta lo stato abilitato o disabilitato della PPPoE (senza dare indicazioni sullo stato della connettività), con il 
`pppoe-client monitor` abbiamo diversi stati:

- `dialing`
- `verifying password...`
- `connected`
- `disconnected`

Questo è quello che dice il [manuale](https://help.mikrotik.com/docs/display/ROS/PPPoE), in realtà, restituisce anche lo stato di `disabled` quando l'interfaccia è disabilitata.

Per far sì che venga eseguito una sola volta (altrimenti rimarrebbe lì a dirci in che stato è l'interfaccia), viene aggiunto l'argomento `once` che viene subito seguito da `do={set <var> $status}`. Grazie a questo argomento, il monitor viene eseguito solo una volta (come se fosse una "foto", anzichè un "video") e la variabile `<var>` viene riempita con `$status` che è una "variabile di sistema", che  ha al suo interno il valore del monitor appena lanciato.

Con `:set $pingSuccessCount ([/ping interface=$MainPPP count=5 $pingTarget] * 100 / 5)` andiamo a fare un semplice ping dall'interfaccia main all'IP inserito nella variabile `$pingTarget`, e andiamo a mettere il risultato in `$pingSuccessCount`. Se il ping andrà a buon fine, `$pingSuccessCount` sarà uguale a 5, se non andrà a buon fine sarà uguale a 0, moltiplicando tutto per 100 e dividendo per il numero di pacchetti inviati (5) abbiamo il "Success Rate". Questo per evitare che per un solo ping fallito, lo script pensi che non ci sia connettività. 

Con questo blocco

```
:if (($MainPPPStatus="connected") && ($pingSuccessCount>=80)) do={
        :log info "[ppp-failover-script] Nessun problema riscontrato su $MainPPP"
        :set IsInFailoverState "false"
        :error "bye!"
    }
```

Andiamo a fare un controllo con i dati appena recuperati, quindi se la PPPoE Principale è connessa e il Ping è presente (per più dell'80%), scrive nel log che non c'è alcun problema, imposta una variabile di nome `IsInFailoverState` su `false` e esce dallo script; Si, `:error` è l'unico modo che ho trovato per uscire direttamente dallo script, non so se ne avete altri...

Questo è quello che viene eseguito quando tutto funziona correttamente.

Se qualcosa non funziona, si passa all'IF successivo, che verifica i seguenti elementi

- MainPPP in uno stato diverso da `connected`
- BackupPPP in `disabled` (quindi proprio disattivata)
- Ping sotto il 50%

Questo scenario, è esattamente quello che accade quando la PPPoE Principale non funziona.
In questo caso, 
- scrive nel log la non operatività della PPPoE Principale
- procede a disabilitare la PPPoE Principale
- Procede ad abilitare la PPPoE di Backup
- Aspetta il `pppoeWaitTime` definito nella variabile (per far autenticare la PPPoE)
- Fa un Ping

Successivamente (con un altro IF), verifica se l'interfaccia è connessa e il ping presente. Se è così, `IsInFailoverState` diventa `true` altrimenti, se non c'è comunque connettività, riabilita la PPPoE Principale fino al prossimo giro.

**Ipotizzando che la PPPoE Principale cade, e andiamo con quella di Backup, quando torniamo su quella principale, se possiamo tenere attiva solo una PPPoE alla volta?**

Per me, la soluzione è farlo in un orario dove la disconnessione non crea problemi, quindi la notte.

Tramite `RecoverTimeStart` e `RecoverTimeEnd`andiamo a definire questo range di orario.

Ricordi il `IsInFailoverState` definito prima? Viene impostato su `true` solo quando la PPPoE di Backup è attiva e operativa.

Nel momento in cui l'orario del Mikrotik cade, all'interno dell'orario di inizio per il recupero della PPPoE Principale, fino a mezzanotte, e da mezzanotte, fino all'orario di fine, tenta in ripristino, disattivando la PPPoE di Backup e Ri-Attivando la Principale. Per evitare ulteriori spaghetti, lascio il tempo della prossima esecuzione dello script per far salire la PPPoE, dopo 5min (il delta per l'esecuzione dello script), si ripartirà da capo, e se la PPPoE Principale è di nuovo Online, tutto andrà per il meglio. Se non è salita, proseguirà come illustrato, e ripasserà al Backup.



# 🗡️ Problemi
Non sono uno Dev e mai lo sarò, e una sequela di IF e Nested IF lo confermano, ma è anche per questo che è su Github! Ogni aiuto è ben accetto! 


# 🚧 To Do

### 🚧🚧🚧 Forever Under Costruction 🚧🚧🚧

Fatto? | Cosa
:---:| ---
💩| Pulizia Connections VoIP quando avviene il cambio
💩| Forse è meglio usare il netwatch per controllare la connettività?
💩| Trovare un modo migliore di contare i singoli ping verso l'esterno come prova di connettività
💩| Cosa succede se mentre si è in FailOver sulla linea di Backup, va giù anche il Backup?
💩| Magari usare qualche funzione, o comunque evitare una pioggia di IF
✅| Script Funzionante



