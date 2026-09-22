# Architektura DriveLog

## Założenia

- iOS 17+, Xcode 16+, tryb języka Swift 5.9, SwiftUI, SwiftData.
- Local-first: dane finansowe i historia tras pozostają na urządzeniu.
- Lekkie usługi: GPS w LocationService, agregacja raportów w Analytics;
  walidacja formularzy i proste podsumowania pozostają przy widokach.
- Brak backendu w pierwszym wydaniu.

## Moduły

| Moduł | Odpowiedzialność |
|---|---|
| App | start aplikacji, kontener danych, nawigacja |
| Models | pojazdy, trasy, paliwo, koszty i przychody |
| Location | CoreLocation i zapis punktów przejazdu |
| Analytics | koszt, wynik, wynik/km i wynik/h |
| Features | ekrany podzielone według funkcji |
| SharedUI | formatowanie i współdzielone komponenty |

## Dane

Modele odnoszą się do pojazdu i zmiany przez UUID. Nie są to relacje SwiftData:
spójność przypisań jest kontrolowana w formularzach, a usuwanie pojazdów
i zmian jest niedostępne. Migracja do CloudKit wymaga osobnego projektu.
Punkty GPS są kodowane jako Data we wpisie trasy dopiero przy zakończeniu.
Nie ma jeszcze trwałego zapisu aktywnej sesji ani odzyskiwania po awarii.

Nowe opcjonalne pola w 0.5 wymagają sprawdzenia migracji z 0.4.1. Edytory
używają wartości roboczych; zapis jest jawny, z obsługą błędu i rollback.
Test zapisu w pamięci nie zastępuje testu trwałości na dysku.

## Kolejność rozwoju

1. Stabilizacja ręcznego GPS na fizycznym iPhonie.
2. Region monitoring + significant-location changes + heurystyka detekcji jazdy.
3. Tryb zmiany i klasyfikacja przejazdów.
4. PDF/CSV, potem XLSX.
5. VisionKit OCR z obowiązkową weryfikacją użytkownika.
6. CloudKit i migracje schematu.
7. StoreKit 2, trial i paywall.

## Ważne ograniczenie iOS

iOS nie gwarantuje ciągłego wykonywania dowolnego kodu w tle. Automatyczna detekcja musi łączyć Core Motion, znaczące zmiany lokalizacji i zwykłe aktualizacje GPS uruchamiane dopiero po wykryciu prawdopodobnej jazdy. Funkcję trzeba testować na fizycznym urządzeniu w różnych stanach baterii oraz po restarcie aplikacji.

## Prywatność

- brak zewnętrznego serwera,
- brak analityki zawierającej współrzędne,
- możliwość usunięcia wpisów,
- prośba o lokalizację dopiero przed rejestrowaniem,
- eksport i synchronizacja zostaną dodane jako świadome działania użytkownika.
