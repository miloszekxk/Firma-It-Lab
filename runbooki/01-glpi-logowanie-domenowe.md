# Użytkownik nie może zalogować się do GLPI kontem domenowym

## Objawy

Użytkownik podaje login i hasło domenowe na stronie logowania GLPI (źródło:
`Active Directory firma.local`), otrzymuje błąd uwierzytelnienia. Logowanie
lokalnym kontem GLPI (`glpi`, `tech`) działa poprawnie.

## Możliwe przyczyny

- konto użytkownika nie zostało jeszcze zsynchronizowane z AD do GLPI
- błędne hasło lub konto zablokowane w AD
- awaria połączenia LDAP między `srv-helpdesk` a `DC01`
- konto serwisowe `glpi-bind` wygasło lub zmieniono mu hasło w AD

## Diagnostyka

**1. Sprawdź, czy konto istnieje w AD i nie jest zablokowane** (na DC01):

```powershell
Get-ADUser <login> -Properties LockedOut, Enabled, PasswordExpired
```

Jeśli `LockedOut : True` - odblokuj:

```powershell
Unlock-ADAccount <login>
```

**2. Sprawdź, czy konto jest zaimportowane do GLPI** (Administration -> Users,
albo z linii poleceń na `srv-helpdesk`):

```bash
sudo -u www-data php /var/www/html/glpi/bin/console glpi:user:list \
  --search=<login>
```

Jeśli konta brak - uruchom ręczną synchronizację (patrz README, Etap 3):

```bash
sudo -u www-data php bin/console ldap:synchronize_users \
  --only-create-new --ldap-server-id=1 --no-interaction
```

**3. Sprawdź test połączenia LDAP w GLPI** (Setup -> Authentication -> LDAP
directories -> Test). Jeśli test się nie powiedzie, sprawdź dostępność DC01
z poziomu `srv-helpdesk`:

```bash
ldapsearch -x -H ldap://192.168.1.10 -D "glpi-bind@firma.local" \
  -W -b "OU=Dzialy,DC=firma,DC=local" "(sAMAccountName=<login>)"
```

Błąd `Invalid credentials` na tym etapie wskazuje na problem z kontem
`glpi-bind` (hasło zmienione lub wygasłe w AD) - nie z kontem użytkownika.

## Rozwiązanie

- konto zablokowane w AD -> odblokuj (`Unlock-ADAccount`)
- konto niezsynchronizowane -> ręczna synchronizacja LDAP
- `glpi-bind` nieprawidłowe -> zresetuj hasło konta serwisowego w AD i
  zaktualizuj w GLPI (Setup -> Authentication -> LDAP directories -> RootDN
  Password)
- hasło użytkownika wygasłe -> użytkownik zmienia hasło na stacji Windows
  (`Ctrl+Alt+Del -> Zmień hasło`) przed kolejną próbą logowania do GLPI