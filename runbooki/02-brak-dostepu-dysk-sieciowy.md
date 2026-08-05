# Użytkownik nie ma dostępu do zmapowanego dysku sieciowego

## Objawy

Po zalogowaniu na stacji Windows 11 w domenie użytkownik nie widzi dysku
sieciowego swojego działu, albo dysk jest widoczny, ale próba otwarcia
kończy się odmową dostępu.

## Możliwe przyczyny

- GPO mapujące dysk nie zostało jeszcze zastosowane na stacji
- użytkownik nie należy do grupy bezpieczeństwa swojego działu
- uprawnienia NTFS na udziale nie obejmują tej grupy
- filtr zabezpieczeń GPO (Security Filtering) nie obejmuje grupy/użytkownika

## Diagnostyka

**1. Sprawdź, które GPO zostały zastosowane na stacji** (na PC-Pracownik01):

```powershell
gpresult /r
```

Jeśli w sekcji "Applied Group Policy Objects" brak GPO mapowania dysków -
przejdź do kroku 3. Jeśli GPO jest zastosowane, ale dysk mimo to nie
działa, przejdź do kroku 2.

**2. Sprawdź przynależność użytkownika do grupy działu** (na DC01):

```powershell
Get-ADPrincipalGroupMembership <login> | Select Name
```

Powinna być widoczna grupa odpowiadająca działowi użytkownika (np.
`GRP-IT`, `GRP-Ksiegowosc`). Jeśli brak - dodaj:

```powershell
Add-ADGroupMember -Identity "GRP-<dzial>" -Members <login>
```

Zmiana członkostwa w grupie wymaga ponownego zalogowania użytkownika, żeby
nowy token dostępu uwzględnił grupę.

**3. Wymuś odświeżenie polityk na stacji zamiast czekać na cykl domyślny:**

```powershell
gpupdate /force
```

**4. Sprawdź uprawnienia NTFS na udziale** (na DC01, we właściwościach
folderu działu -> Security), porównaj z grupą z kroku 2. Grupa musi mieć
minimum uprawnienia Odczyt i wykonanie na poziomie folderu.

## Rozwiązanie

- brak GPO na stacji -> `gpupdate /force`, w skrajnym przypadku restart
  stacji
- brak członkostwa w grupie -> dodanie do grupy + ponowne logowanie
- brak uprawnień NTFS -> uzupełnienie ACL na udziale o właściwą grupę
- GPO nieobjęte filtrem zabezpieczeń -> Group Policy Management -> zakładka
  Scope -> Security Filtering -> dodać grupę/użytkownika