:global MainPPP "pppoe-ftth-dimensione"
:global BackupPPP "pppoe-fwa-dimensione"
:global pingTarget "8.8.8.8"
:global IsInFailoverState
:global pingSuccessCount

:do {
    :log info "[ppp-failover-script] Controllo connettività"

    #Controllo quale interfaccia è abilitata
    :global MainPPPStatus 
    /interface pppoe-client monitor $MainPPP once do={:set MainPPPStatus $status}
    :log info "Stato di $MainPPP: $MainPPPStatus"

    :global BackupPPPStatus
    /interface pppoe-client monitor $BackupPPP once do={:set BackupPPPStatus $status}
    #:log info "Stato di $BackupPPP: $BackupPPPStatus"

    :set $pingSuccessCount [/ping interface=$MainPPP count=5 $pingTarget]
    #:log info "pingSuccessCount: $pingSuccessCount"

    :if (($MainPPPStatus="connected") && ($pingSuccessCount=5) && (IsInFailoverState="false")) do={
        :log info "PPPoE Principale operativa & Ping presente"
        :set IsInFailoverState "false"
        :error "bye!"
    }
        
    :if (($MainPPPStatus!="connected") && ($BackupPPPStatus="disabled") && ($pingSuccessCount!=5)) do={
        :log error "$MainPPP non operativa. Procedo ad attivare il FailOver su $BackupPPP"
        /interface pppoe-client disable $MainPPP
        /interface pppoe-client enable $BackupPPP
        :log warning "$BackupPPP in Attivazione..."
        :delay 30s
        :set $pingSuccessCount [/ping interface=$BackupPPP count=5 $pingTarget]
        } else={
            if (($BackupPPPStatus="connected") && ($pingSuccessCount=5)) do={
                :log info "$BackupPPP attiva e Online."
                :set IsInFailoverState "true"
            } else={
                :log error "Tentantivo di migrazione su $BackupPPP fallito, lo stato dell'interfaccia è $BackupPPPStatus. Torno su $MainPPP"
                /interface pppoe-client disable $BackupPPP
                /interface pppoe-client enable $MainPPP
                :set IsInFailoverState "false"
            }
    }

    :if (IsInFailoverState="true" && $MainPPPStatus="disabled" && $BackupPPPStatus="connected")
        
        :global tt [/system clock get time]
        


    }