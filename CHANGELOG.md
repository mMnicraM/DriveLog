# Historia zmian

## 0.6.0 — szybkie rozliczenie przejazdu

- Po bezpiecznym zapisie trasy otwiera się krótkie rozliczenie przychodu.
- Data zakończenia, samochód, zmiana i trasa są przypisywane automatycznie.
- Formularz zawiera źródło przychodu, kwotę kursu, napiwek, procent prowizji,
  wyliczoną prowizję i kwotę pozostającą po prowizji.
- Dodano trzy zakończenia: zapis przychodu, przejazd prywatny bez przychodu oraz
  odłożenie rozliczenia na później.
- Aktywną platformę można zmienić bezpośrednio na ekranie Start.
- W Więcej → Platformy i prowizje można zapisać własną prowizję każdej firmy.
- Nierozliczone przejazdy są oznaczone w historii i sygnalizowane na ekranie
  Start oraz w podsumowaniu zmiany.
- Usunięcie powiązanego przychodu ponownie oznacza trasę jako nierozliczoną;
  usunięcie trasy zachowuje sam wpis finansowy bez nieaktualnego powiązania.
- Nowe opcjonalne pola nie zmieniają znaczenia starszych rekordów.
- Dodano testy obliczenia prowizji, ustawień prowizji i powiązania rozliczenia.
- Podniesiono numer kompilacji do 13.

## 0.5.5 — GPS po wygaszeniu ekranu

- Dodano `CLBackgroundActivitySession`, która utrzymuje sesję lokalizacji po
  zablokowaniu ekranu przy zgodzie „Gdy używam aplikacji”.
- Sesja pracy w tle jest przechowywana przez cały czas rejestracji i jawnie
  kończona wraz z trasą.
- Błędy Core Location nie są już pokazywane jako błędy zapisu kopii roboczej.
- Tymczasowy brak pozycji jest ignorowany, a odebranie dostępu do GPS kończy
  rejestrację z czytelnym komunikatem.
- Ekran pokazuje liczbę zapisanych punktów GPS oraz stan pracy w tle.
- Zwiększono dopuszczalną dokładność punktu do 100 m, aby nie odrzucać całego
  śladu przy słabszym sygnale.
- Trasa GPS jest domyślnie zapisywana jako służbowa.
- Pusta trasa nie zapisuje się automatycznie; użytkownik może ją odrzucić albo
  świadomie zachować bez mapy.
- Mapa pokazuje także pojedynczy odebrany punkt GPS.
- Podniesiono numer kompilacji do 12.

## 0.5.4 — przyciski zmiany i GPS

- Cała widoczna powierzchnia przycisku rozpoczęcia/zakończenia zmiany reaguje
  na dotyk, a nie tylko sam napis.
- Przycisk trasy nie jest już pozornie aktywny, gdy brakuje zgody GPS.
- Pierwsze dotknięcie może poprosić o zgodę i automatycznie rozpocząć trasę.
- Po wcześniejszym odrzuceniu zgody aplikacja wyjaśnia problem i prowadzi
  bezpośrednio do ustawień DriveLog.
- Stan zgody jest odświeżany po powrocie z Ustawień iPhone’a.
- Dodano wizualny stan wyłączony wspólnego zielonego przycisku oraz test decyzji
  dla wszystkich stanów autoryzacji lokalizacji.
- Podniesiono numer kompilacji do 11.

## 0.5.3 — awaria GPS i ikona

- Usunięto przyczynę zamykania aplikacji przy rozpoczynaniu trasy: praca GPS
  w tle jest włączana dopiero po potwierdzeniu, że iOS widzi prawidłową tablicę
  UIBackgroundModes z wartością location.
- Jeśli tryb w tle nie jest dostępny, zapis GPS działa w pierwszym planie
  i pokazuje ostrzeżenie zamiast kończyć proces.
- Jawnie oznaczono Background Modes w wygenerowanym projekcie Xcode.
- Dodano test konfiguracji trybu lokalizacji w tle.
- Zastąpiono ucięty plik ikony nowym plikiem 1024 × 1024 bez kanału alfa,
  wygenerowanym z działającej grafiki marki.
- Podniesiono numer kompilacji do 10.

## 0.5.2 — poprawka projektu Xcode

- Włączono automatyczne generowanie Info.plist dla aplikacji i testów.
- Przeniesiono nazwę aplikacji, opisy uprawnień lokalizacji, obsługę pracy GPS
  w tle, ekran startowy i manifest scen do ustawień generowanego Info.plist.
- Usunięto pusty, ręczny Info.plist, który nie był poprawnie przypisany
  do wygenerowanego targetu.
- Podniesiono numer kompilacji do 9.

## 0.5.1 — kandydat stabilizacyjny

- Roboczy zapis aktywnej trasy do osobnego pliku co najwyżej co kilka sekund
  oraz przy przejściu aplikacji do tła.
- Wykrywanie niedokończonej trasy po restarcie: kontynuacja, zakończenie
  i zapis albo świadome odrzucenie.
- Kopia robocza jest usuwana dopiero po udanym zapisie trasy do SwiftData.
- Ekran Start pokazuje ostrzeżenie o trasie wymagającej odzyskania.
- Bezpieczny ekran błędu bazy: bez tworzenia zastępczej pustej bazy.
- Kolejna poprawka przewijania: zwykły VStack, stały dolny margines i odbicie
  przewijania. Nadal wymaga odbioru na docelowym Xcode i urządzeniu.
- Ograniczenie odrzucania segmentów GPS dłuższych niż 2 km między punktami.
- Test kodowania i odtwarzania kopii roboczej trasy.

## 0.5.0 — kandydat testowy

- Stałe etykiety, jednostki i walidacja pól we wszystkich formularzach.
- Wspólny edytor auta; robocza edycja wpisów bez zapisu przy anulowaniu.
- Obsługa błędów zapisu, komunikaty sukcesu i potwierdzenie usuwania.
- Poprawka układu przewijania: LazyVStack i ograniczony pionowy separator.
  Skuteczność wymaga sprawdzenia w aplikacji.
- Filtry okresu/auta, podsumowanie zmiany i opcjonalne powiązania wpisów.
- Jaśniejsze nazwy metryk: saldo i czas jazdy, zamiast obietnicy pełnego zysku.
- Testy regresji oraz szczegółowa lista odbioru i ograniczeń.
- Kompilacji i XCTest tej wersji nie wykonano w środowisku przygotowania.

## 0.4.1

- próbowano poprawić przewijanie przez wyłączenie gestów wykresu; użytkownik
  zgłosił, że ta zmiana nie rozwiązała problemu,
- dodano widoczny wskaźnik przewijania,
- przebudowano ekran Analiza,
- dodano wykres przychodów i kosztów z ostatnich 7 dni,
- dodano wykres trendu dziennego zysku,
- dodano miesięczne karty wyniku, kilometrów, czasu, zysku/km i zysku/h.

## 0.4.0

- dodano wybór aktywnego samochodu,
- aktywne auto jest podpowiadane w formularzach i przy zapisie GPS,
- dodano rozpoczęcie i zakończenie zmiany wraz z licznikiem czasu,
- dodano historię przychodów, tankowań, kosztów oraz zmian,
- dodano edycję i usuwanie zapisanych wpisów,
- dodano mapę śladu GPS ze znacznikiem początku i końca,
- zwiększono dokładność rejestracji GPS do trybu nawigacyjnego.

## 0.3.1

- usunięto nieklikalną strzałkę sugerującą nawigację,
- dodano jednoznaczny status wyniku: „Brak danych”, „Na plusie” lub „Na minusie”.

## 0.3.0

- podłączono wszystkie kafelki „Szybkie akcje” do właściwych formularzy,
- dodano skrót do ręcznego przejazdu,
- dodano banner tras wymagających klasyfikacji,
- usunięto dane konkretnego samochodu z podpowiedzi formularza,
- zwiększono czytelność i powierzchnię dotykową kafelków,
- wykonano przegląd prywatności tekstów interfejsu.

## 0.2.0

- nowy onboarding i dashboard,
- ikona i ekran startowy,
- pełne dane przy dodawaniu pojazdu,
- poprawione formatowanie roku i przebiegu.
