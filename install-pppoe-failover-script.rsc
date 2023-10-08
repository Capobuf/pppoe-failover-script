/system script 
add name="pppoe-failover-script" source={/tool fetch url="https://raw.githubusercontent.com/Capobuf/pppoe-failover-script/main/pppoe-failover-script.rsc" mode=https /import file-name=pppoe-failover-script; /file remove blacklist.rsc}
/system scheduler
add interval=5m name="pppoe-failover-script" start-date=Jan/01/2000 start-time=00:05:00
/file remove install.rsc