# pppoe-failover-script
Un Semplice Script per il Failover tra due PPPoE-Client su Mikrotik 7.x


## Funzionamento

Lo script essenzialmente verifica due elementi:

- Ping verso un host esterno alla rete
- Lo stato del PPPoE Client

Su questa base, esegue delle azioni, tenendo a mente che considera un PPPoE-Client il Principale (nella maggior parte dei casi la Fibra) e un PPPoE-Client come Secondario (nella maggior parte dei casi una connessione FWA).

Nel momento in cui il Ping o lo Stato del PPPoE-Client sono anomali, esegue un azione di failover, disabilitando il Client Principale, e passa al Secondario.



