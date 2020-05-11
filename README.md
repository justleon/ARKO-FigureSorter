# [PL]ARKO-FigureSorter
Sortowanie figur w języku assemblera do użytku w symulatorze MARS oraz program C++ z funkcją assemblerową INTELa.  
Powyzszy program pobiera dane z 32-bitowego pliku BMP w postaci headera i tablicy pikseli.  
Na podstawie tablicy pikseli znajduje figury oraz oblicza ich obwody. Następnie zgodnie z zebranymi danymi ustawia figury w kolejności od najmniejszego obwodu, do największego i zapisuje wynik w nowym pliku BMP o tych samych wymiarach.
UWAGA: Wersja na MIPS korzysta z plików 32bitowych z kanałem alpha i schematem kolorów, program C++ natomiast z plików 32bitowych BEZ kanału alpha i schematu kolorów.  

**Ograniczenia:**  
* w pliku wejściowym powinno znaleźć sie maksymalnie 5 figur
* szerokość obrazka jest zawsze większa od sumy szerokości figur + trzeba uwzględnić przerwy między igurami w postaci 3 pikseli
* sugerowane jest, aby zadna z figur nie była styczna z krawędzią obrazu, innymi słowy zaleca się zostawienie min 1 piksela przerwy między krawędzią, a figurą

Miłej zabawy

