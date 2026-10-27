Import-Module ActiveDirectory

# Sciezka wzgledem lokalizacji skryptu zamiast na sztywno
$csvPath = Join-Path $PSScriptRoot "uzytkownicy.csv"
$uzytkownicy = Import-Csv -Path $csvPath

# Haslo startowe pobierane interaktywnie, nie zapisane w kodzie
$hasloDomyslne = Read-Host "Podaj haslo startowe dla nowych kont" -AsSecureString

foreach ($u in $uzytkownicy) {

    $ouPath = "OU=$($u.Dzial),OU=Dzialy,DC=firma,DC=local"
    $nazwaWyswietlana = "$($u.Imie) $($u.Nazwisko)"

    # Ponowne uruchomienie skryptu nie konczy sie bledami dla istniejacych kont
    if (Get-ADUser -Filter "SamAccountName -eq '$($u.Login)'") {
        Write-Host "Pominieto: $($u.Login) juz istnieje" -ForegroundColor Yellow
        continue
    }

    try {
        New-ADUser `
            -Name $nazwaWyswietlana `
            -GivenName $u.Imie `
            -Surname $u.Nazwisko `
            -SamAccountName $u.Login `
            -UserPrincipalName "$($u.Login)@firma.local" `
            -Path $ouPath `
            -AccountPassword $hasloDomyslne `
            -Enabled $true `
            -ChangePasswordAtLogon $true `
            -Description $u.Stanowisko

        Write-Host "Utworzono: $nazwaWyswietlana ($($u.Login)) w OU: $($u.Dzial)" -ForegroundColor Green
    }
    catch {
        Write-Host "BLAD przy $($u.Login): $_" -ForegroundColor Red
    }
}