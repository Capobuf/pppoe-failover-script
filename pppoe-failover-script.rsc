:global MainPPP "pppoe-ftth-dimensione"
:global BackupPPP "pppoe-fwa-dimensione"
:global pingTarget "8.8.8.8"
:global pppoeWaitTime 10s
:global RecoverTimeStart "22:00:00"
:global RecoverTimeEnd "08:00:00"
###########################
:global IsInFailoverState
:global pingSuccessCount

:do {
    :log info "[ppp-failover-script] Controllo connettività"

    #Controllo quale interfaccia è abilitata
    :global MainPPPStatus 
    /interface pppoe-client monitor $MainPPP once do={:set MainPPPStatus $status}
    #:log info "Stato di $MainPPP: $MainPPPStatus"

    :global BackupPPPStatus
    /interface pppoe-client monitor $BackupPPP once do={:set BackupPPPStatus $status}
    #:log info "Stato di $BackupPPP: $BackupPPPStatus"

    :set $pingSuccessCount [/ping interface=$MainPPP count=5 $pingTarget]
    #:log info "pingSuccessCount: $pingSuccessCount"

    :if (($MainPPPStatus="connected") && ($pingSuccessCount=5)) do={
        :log info "[ppp-failover-script] Nessun problema riscontrato su $MainPPP"
        :set IsInFailoverState "false"
        :error "bye!"
    }
        
    :if (($MainPPPStatus!="connected") && ($BackupPPPStatus="disabled") && ($pingSuccessCount!=5)) do={
        :log error "[ppp-failover-script] $MainPPP non operativa. Procedo ad attivare il FailOver su $BackupPPP"
        /interface pppoe-client disable $MainPPP
        /interface pppoe-client enable $BackupPPP
        :log warning "[ppp-failover-script] $BackupPPP in Attivazione..."
        :delay $pppoeWaitTime
        :set $pingSuccessCount [/ping interface=$BackupPPP count=5 $pingTarget]
        }
        
    :if (($BackupPPPStatus="connected") && ($pingSuccessCount=5)) do={
        :log info "[ppp-failover-script] $BackupPPP Connessa e Online."
        :set IsInFailoverState "true"
    } else={
            :log error "[ppp-failover-script] Tentantivo di migrazione su $BackupPPP fallito, lo stato dell'interfaccia è $BackupPPPStatus. Riabilito $MainPPP fino al prossimo run"
            /interface pppoe-client disable $BackupPPP
            /interface pppoe-client enable $MainPPP
            :set IsInFailoverState "false"
            }
    }

    :if (IsInFailoverState="true" && $MainPPPStatus="disabled") do={
        :global getTime [:totime [/system clock get time]]
        :set $RecoverTimeStart [:totime $RecoverTimeStart]
        :set $RecoverTimeEnd [:totime $RecoverTimeEnd]

        :if (($RecoverTimeStart<=$getTime) && ($getTime>=00:00:00) || ($RecoverTimeEnd>=$getTime) && ($getTime>=00:00:00)) do={
            :log warning "[ppp-failover-script] Tento il Ripristino di $MainPPP entro l'orario consentito: $RecoverTimeStart - $RecoverTimeEnd"
            /interface pppoe-client disable $BackupPPP
            /interface pppoe-client enable $MainPPP
            :log warning "[ppp-failover-script]$MainPPP in Attivazione, controllo al prossimo run"
            } else={
                :log warning "[ppp-failover-script] Attualmente attiva la linea di Backup: $BackupPPP - prossimo tentativo per $MainPPP tra le $RecoverTimeStart e $RecoverTimeEnd"
            }
    }
    }