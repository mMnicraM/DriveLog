# DriveLog 0.5.5 — odbiór na Macu

## Status

W tej paczce sprawdzono strukturę plików, format zasobów, składnię skryptu
i obecność połączeń formularzy. Nie wykonano kompilacji, XCTest ani testów
interfejsu: środowisko przygotowania nie ma Xcode ani Swift.
Zmiana przewijania jest kandydatem do poprawki, a nie potwierdzoną naprawą.

## Bezpieczeństwo danych i aktualizacja

- Nie usuwaj poprzedniej aplikacji ani jej bazy w celu aktualizacji.
- Zachowaj poprzedni projekt i kopię urządzenia; ważnych danych nie trzymaj
  wyłącznie w tej testowej aplikacji.
- Najpierw sprawdź aktualizację na kopii środowiska testowego z danymi 0.4.1.
- Pozostaw ten sam identyfikator aplikacji i podpis. Doszły opcjonalne pola:
  powiązanie ze zmianą, auto przychodu i jednostka zakupu. Migracja istniejącej
  bazy wymaga osobnego sprawdzenia — test w pamięci jej nie potwierdza.
- Jeśli pojawi się błąd otwarcia bazy, zachowaj log; nie kasuj danych.

## Kompilacja i testy

1. W katalogu zawierającym project.yml wykonaj: `xcodegen generate`.
2. Otwórz DriveLog.xcodeproj i wybierz schemat DriveLog oraz symulator iPhone.
3. Uruchom Product → Build, następnie Product → Test (⌘U).
4. W zestawie jest łącznie 12 testów: obliczenia, liczby, granice okresów,
   filtrowanie aut, klasyfikacja tras, pusty wynik, zapis powiązania, kopia GPS
   reakcje na każdy stan zgody lokalizacji i domyślną kategorię trasy GPS.
5. Uruchom aplikację przez ⌘R. Sprawdź poniższą listę również na iPhonie.

## Scenariusze ręczne — wymagane przed uznaniem wersji za gotową

- Start: przeciągnij ekran w górę od karty salda i od pustego miejsca.
  Dotrzyj do stopki „DriveLog 0.5.5”, wróć na górę, otwórz każdą szybką akcję.
  Powtórz z małym ekranem i dużym tekstem systemowym. Identyfikatory do
  przyszłych UI tests: dashboard.scroll i dashboard.bottom.
- Formularze: etykiety mają pozostać widoczne po wpisaniu danych.
  Ilość paliwa 10,5 × cena 6,2 = 65,10 zł; jednostki l / zł/l / km.
  Dla auta elektrycznego: kWh / zł/kWh / km. Wypełnij także koszt i przychód.
- Walidacja: puste pola, tekst w liczbie, liczby ujemne, dwa przecinki,
  prowizja większa od przychodu z napiwkami. Zapis zablokowany i wyjaśniony.
  Sprawdź przycisk „Gotowe” nad klawiaturą i dostęp do ostatniego pola.
- Auto: onboarding, dodanie drugiego auta i edycja pokazują ten sam zestaw
  pól. Rok 2009 bez separatora tysięcy. Brak prywatnych danych w podpowiedziach.
- Edycja: zmień kwotę, wybierz Anuluj/wstecz i sprawdź, że stara kwota
  pozostała. Następnie zapisz, zamknij aplikację i sprawdź zapis ponownie.
- Usuwanie: przesuń wpis lub trasę, anuluj, potem potwierdź usunięcie.
- Zmiana: rozpocznij, dodaj przychód i koszt przypisane do zmiany, zakończ.
  Porównaj podsumowanie i historię. Zmiana aktywna powinna pozostać po restarcie.
  Dotknij też pustego miejsca po lewej i prawej stronie napisu na przycisku —
  cały kolorowy prostokąt ma rozpoczynać lub kończyć zmianę.
- Filtry: dzień/tydzień/miesiąc/rok i dwa auta. Stary przychód bez auta jest
  widoczny w „Wszystkie pojazdy”, a nie w wynikach pojedynczego auta.
  Wykresy mają jawnie oznaczony niezależny zakres „Ostatnie 7 dni”.
- GPS: odmowa zgody, wyłączone usługi, brak sygnału, trasa, blokada ekranu,
  zapis i mapa. Wymuś zamknięcie podczas testowej trasy, uruchom ponownie
  i sprawdź kolejno: kontynuowanie, zapis odzyskanej trasy oraz odrzucenie.
  Po zapisie sklasyfikuj trasę. Nie testuj telefonu jako kierowca.
- GPS i zgody: przy pierwszym użyciu wybierz zgodę i sprawdź, że rejestracja
  zaczyna się bez drugiego kliknięcia. Po odmowie przycisk ma prowadzić do
  Ustawień, a po powrocie prawidłowo rozpoznać nową zgodę.
- GPS w tle: zaczekaj na co najmniej dwa zapisane punkty, zablokuj ekran na
  2–3 minuty i przejdź kilkaset metrów. Po odblokowaniu liczba punktów i dystans
  mają być większe, a szczegóły trasy mają pokazać ślad na mapie.
- Nowa trasa GPS ma kategorię „Służbowa”. Trasa bez żadnego punktu nie może
  zapisać się automatycznie; ekran ma pozwolić ją odrzucić.
- Po instalacji sprawdź, czy ekran GPS nie pokazuje pomarańczowego ostrzeżenia
  o pracy tylko w pierwszym planie. Jeśli je pokazuje, trasa nie powinna
  zamknąć aplikacji, ale test z wygaszonym ekranem nie jest jeszcze zaliczony.
- Jasny/ciemny motyw, największy tekst i VoiceOver: etykiety, jednostki,
  przyciski, kontrast i brak uciętych wartości.

## Znane ograniczenia

Aktywna trasa jest zapisywana roboczo, ale mechanizm odzyskiwania nie został
jeszcze sprawdzony na urządzeniu; między zapisami można utracić kilka sekund.
Po wymuszonym zamknięciu iOS nie kontynuuje zbierania punktów aż do wznowienia.
Brak eksportu/kopii w aplikacji, automatycznej detekcji jazdy,
załączników, OCR i synchronizacji. Saldo nie uwzględnia podatków ani amortyzacji;
zakup paliwa jest wydatkiem w dniu zakupu. Czas jazdy to suma służbowych tras,
a czas zmiany to osobna metryka. Trasa przekraczająca granicę okresu jest
przypisana w całości do okresu jej rozpoczęcia.
