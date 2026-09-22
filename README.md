# DriveLog 0.5.5 — wersja testowa

Natywny dziennik iOS: pojazdy, trasy, zmiany i saldo przychodów oraz wydatków.

## Uruchomienie na Macu

1. Wymagane: Xcode 16 lub nowszy, iOS 17 lub nowszy, XcodeGen.
2. Rozpakuj do nowego katalogu; zachowaj poprzedni projekt.
3. W Terminalu przejdź do katalogu z project.yml i wykonaj `xcodegen generate`.
   Jeśli brakuje XcodeGen, zainstaluj go samodzielnie przez `brew install xcodegen`
   (wymaga wcześniej zainstalowanego Homebrew).
4. Otwórz DriveLog.xcodeproj. Wybierz schemat DriveLog i konkretny symulator.
5. Product → Build, Product → Test, następnie Run. Do fizycznego iPhone’a
   ustaw swój Team w Signing & Capabilities.
6. Sprawdź scenariusze w TESTING.md, szczególnie przewijanie i migrację danych.

GENERATE_PROJECT.command jest opcjonalnym skrótem tych działań. Jeśli macOS
blokuje jego uruchomienie, nie trzeba wyłączać zabezpieczeń: użyj powyższej
komendy XcodeGen bezpośrednio. Projekt .xcodeproj powstaje lokalnie na Macu.

## Co zmieniono

- Stałe etykiety i jednostki wszystkich pól tekstowych; neutralne podpowiedzi.
- Jeden formularz auta do pierwszego dodania, kolejnych aut i edycji.
- Wpisy finansowe edytowane w kopii roboczej, walidacja i obsługa błędu zapisu.
- Potwierdzenie usunięcia wpisów i tras; komunikat po udanym zapisie.
- Przebudowany układ przewijanego Startu, spójne tło i typografia.
- Bieżący dzień/tydzień/miesiąc/rok, filtr auta, wykresy ostatnich 7 dni.
- Powiązanie wpisów ze zmianą i podsumowanie po zakończeniu oraz w historii.
- Jawne rozróżnienie salda, czasu jazdy i czasu zmiany.
- Testy regresji i instrukcja odbioru.
- Roboczy zapis aktywnej trasy oraz odzyskiwanie po ponownym uruchomieniu.
- Bezpieczny ekran błędu bazy bez automatycznego tworzenia pustych danych.
- Pełne obszary dotykowe przycisków zmiany i jednoznaczna obsługa zgody GPS.
- Utrzymywanie sesji GPS po wygaszeniu ekranu oraz widoczna liczba punktów.

## Ważne

Nie kompilowano tej paczki ani nie uruchamiano XCTest w środowisku przygotowania.
Nie potwierdzono naprawy przewijania ani migracji starej bazy. Nie odinstalowuj
aplikacji w celu aktualizacji; najpierw kopia danych i test aktualizacji.
Szczegóły oraz ograniczenia opisano w TESTING.md i REQUIREMENTS_STATUS.md.
