# DriveLog — stan 0.6.0

## Zaimplementowane w kodzie, wymagające odbioru w Xcode

- Stałe etykiety, jednostki, neutralne podpowiedzi i walidacja formularzy.
- Ten sam formularz auta w onboardingu, dodawaniu i edycji; rok bez grupowania.
- Szybkie akcje połączone z formularzami i historia edycji.
- Wybór auta, rejestracja GPS start/stop, mapa i klasyfikacja trasy.
- Rozpoczęcie/zakończenie zmiany, powiązane wpisy i podsumowanie.
- Filtry bieżącego okresu i auta, wykresy ostatnich 7 dni.
- Korekta układu przewijania, jasny/ciemny motyw, ikona i ekran startowy.
- Potwierdzenie usuwania, obsługa błędów zapisu, robocze wartości przy edycji.
- Kopia robocza aktywnej trasy i ekran odzyskiwania po ponownym uruchomieniu.
- Bezpieczne zatrzymanie na ekranie diagnostycznym, jeśli baza się nie otworzy.
- Szybkie rozliczenie kursu powiązane z trasą, autem i zmianą.
- Aktywna platforma, własne stawki prowizji i kolejka nierozliczonych tras.

## Niepotwierdzone

- Kompilacja i XCTest na docelowej wersji Xcode.
- Skuteczność naprawy przewijania na symulatorze i urządzeniu.
- Migracja z poprzedniej bazy i trwałość danych po aktualizacji.
- Zachowanie GPS w tle, uprawnienia, dokładność rzeczywistej trasy.
- Migracja opcjonalnych pól rozliczenia na bazie utworzonej przez 0.5.5.
- Dostępność przy dużym tekście i VoiceOver.

## Następne priorytety

1. Odbiór według TESTING.md i poprawki na podstawie wyników.
2. Eksport danych/kopia zapasowa i testowana migracja bazy.
3. Odbiór i dalsze utwardzenie zapisu aktywnej trasy po przerwaniu procesu.
4. Dopiero później automatyczna jazda, OCR, raporty i synchronizacja.

## Granice funkcjonalne

Saldo nie jest pełnym zyskiem ekonomicznym ani wynikiem podatkowym.
Stare przychody bez auta są uwzględniane tylko w zestawieniu wszystkich aut.
Stare wpisy bez powiązania ze zmianą nie są automatycznie przypisywane.
Jednostka nowych zakupów jest zapisywana; dla starych wynika z aktualnego
napędu auta. PHEV jest na razie obsługiwany jak paliwo, bez osobnego zakupu energii.
Nie ma usuwania pojazdu ze względu na powiązane dane.
