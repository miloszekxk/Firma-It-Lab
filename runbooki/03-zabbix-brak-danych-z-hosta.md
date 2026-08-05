# Zabbix zgłasza brak danych z hosta

## Objawy

Na hoście w Zabbixie (Monitoring -> Hosts) wskaźnik dostępności agenta
świeci na czerwono, albo Latest Data dla hosta nie aktualizuje się mimo
upływu czasu.

## Możliwe przyczyny

- usługa agenta zatrzymana na monitorowanym hoście
- reguła zapory blokująca port 10050 (agent) lub 161 (SNMP)
- niezgodność adresu `Server`/`ServerActive` w konfiguracji agenta z
  adresem `srv-monitor`
- błędny community string SNMP (dotyczy pfSense)

## Diagnostyka

**1. Odpytaj agenta bezpośrednio z `srv-monitor`** - to pokazuje, czy
problem leży po stronie sieci/agenta, zanim zajrzysz w panel:

```bash
zabbix_get -s <adres_hosta> -k agent.ping
```

Brak odpowiedzi (timeout) -> problem sieciowy lub usługa zatrzymana,
przejdź do kroku 2. Odpowiedź `1` -> agent działa, problem leży w
konfiguracji hosta w panelu Zabbixa (nazwa hosta / interfejs), sprawdź
zakładkę Configuration -> Hosts -> Interfaces.

**2. Sprawdź usługę agenta na monitorowanym hoście.**

Windows (DC01):

```powershell
Get-Service Zabbix Agent 2
```

Debian (srv-helpdesk):

```bash
sudo systemctl status zabbix-agent2
```

**3. Sprawdź regułę zapory na porcie 10050** (Windows):

```powershell
Get-NetFirewallRule -DisplayName "Zabbix Agent" | Select Enabled, Direction
```

**4. Dla pfSense (SNMP) sprawdź demon i community string bezpośrednio
z `srv-monitor`:**

```bash
snmpwalk -v2c -c <community> 192.168.1.1 1.3.6.1.2.1.1 2>/dev/null
```

Brak odpowiedzi -> SNMP wyłączony w Services -> SNMP na pfSense, albo
community string w Zabbixie (makro `{$SNMP_COMMUNITY}`) nie zgadza się
z tym ustawionym na firewallu.

## Rozwiązanie

- usługa zatrzymana -> uruchom ponownie (`Start-Service` /
  `systemctl start zabbix-agent2`)
- port zablokowany -> dodaj/włącz regułę zapory na 10050 lub 161
- błędny adres serwera w konfiguracji agenta -> popraw `Server` /
  `ServerActive` w `zabbix_agent2.conf` (Windows: rejestr lub plik konfiguracyjny), zrestartuj usługę
- niezgodny community string -> ujednolić wartość w pfSense i w makrze
  `{$SNMP_COMMUNITY}` w Zabbixie