:global MainPPP "pppoe-ftth-dimensione"
:global BackupPPP "pppoe-fwa-dimensione"
:global pingTarget "8.8.8.8"
:global pppoeWaitTime 10s
:global RecoverTimeStart "22:00:00"
:global RecoverTimeEnd "08:00:00"
###########################
:global IsInFailoverState

:global CheckMainPPPStatus do={/interface pppoe-client monitor $MainPPP once do={:set MainPPPStatus $status}};
:global CheckBackupPPPStatus do={/interface pppoe-client monitor $BackupPPP once do={:set BackupPPPStatus $status}};
:global pingSuccessCountMain do={([/ping interface=$MainPPP count=5 $pingTarget] * 100 / 5)};
:global pingSuccessCountBackup do={([/ping interface=$BackupPPP count=5 $pingTarget] * 100 / 5)};

:do {
    :log info "[ppp-failover-script] Controllo connettività"

    $CheckMainPPPStatus;
    #:log info "Stato di $MainPPP: $MainPPPStatus"
    $CheckBackupPPPStatus;
    #:log info "Stato di $BackupPPP: $BackupPPPStatus"
   
    
    

    $pingSuccessCountMain;
    #:log info "pingSuccessCountMain: $pingSuccessCountMain%"
    $pingSuccessCountBackup;
    #:log info "pingSuccessCountBackup: $pingSuccessCountBackup%"


    ## Caso 1: La WAN Principale Operativa e Ping Presente, loggo ed esco subito.

    :if (($MainPPPStatus="connected") && ($pingSuccessCountMain>=80)) do={
        :log info "[ppp-failover-script] Nessun problema riscontrato su $MainPPP"
        :set IsInFailoverState "false"
        :error "bye!"
    }
    
    ## Caso 2: La WAN Principale Disconnessa, Ping Assente, Tento il Recupero sulla WAN di Backup.

    :if (($MainPPPStatus!="connected") && ($BackupPPPStatus="disabled") && ($pingSuccessCount<=50)) do={
        :log warning "[ppp-failover-script] Rilevata $MainPPP non operativa. Procedo ad attivare il FailOver su $BackupPPP"
        /interface pppoe-client disable $MainPPP
        /interface pppoe-client enable $BackupPPP
        :log warning "[ppp-failover-script] $BackupPPP in Attivazione. Attendo $pppoeWaitTime prima di Continuare"
        :delay $pppoeWaitTime;
        
        $CheckMainPPPStatus;
        
        $CheckBackupPPPStatus;
        
        $pingSuccessCountBackup;

    }

    ## Caso 3: La WAN di Backup Operativa, Ping Presente, segnalo il FailOver ma vado avanti.       
    
    :if (($BackupPPPStatus="connected") && ($pingSuccessCountBackup>=80)) do={
        :log info "[ppp-failover-script] $BackupPPP Connessa e Online."
        :set IsInFailoverState "true"
    } else={
            ## DEBUG
            # :log warning "Stato della PPP Principale: $MainPPPStatus"
            # :log warning "Ping dalla PPP Principale: $pingSuccessCountMain"

            # :log warning "Stato della PPP di Backup: $BackupPPPStatus"
            # :log warning "Ping dalla PPP di Backup: $pingSuccessCountBackup"

            :log error "[ppp-failover-script] $BackupPPP non Operativa, lo stato dell'interfaccia è $BackupPPPStatus. Riabilito $MainPPP fino al prossimo run"
            /interface pppoe-client disable $BackupPPP
            /interface pppoe-client enable $MainPPP
            
            :delay $pppoeWaitTime;
            
            $CheckMainPPPStatus;
        
            $CheckBackupPPPStatus;
            
            :set IsInFailoverState "false"
        }
    

    :if ($IsInFailoverState="true" && $MainPPPStatus="disabled") do={
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
