# Ponizszy program działa na plikach BMP 32-bitowych, z jednym bajtem przeznaczonym na przezroczystość.
# Header w takim pliku wynosi 122 bajty, każdy piksel zajmuje 4 bajty, czyli tablica pikseli ma (wys x szer x 4) bajtów
# Sugerowane jest zachowanie min jednego piksela przerwy między figurą w pliku przetwarzanym, a krawędzią obrazka
# W pliku BMP może sie znaleźć maksymalnie 5 figur do przeanalizowania.
# Copyright Łukasz "Leon" Pokorzyński, 2020

.data
	header:		.space 124
	
	perimeter:	.word 0, 0, 0, 0, 0	#obwody figur
	figureAddress:	.word 0, 0, 0, 0, 0	#gdzie zaczyna się prostokąt
	height:		.word 0, 0, 0, 0, 0	#wysokość prostokąta
	width:		.word 0, 0, 0, 0, 0	#szerokość prostokąta
	
	import:		.asciiz "/home/leon/Dokumenty/ARKO/input.bmp"	#tu powinna znaleźć sie ścieżka do pliku wsadowego
	output:		.asciiz "/home/leon/Dokumenty/ARKO/out.bmp"	#tu powinna znaleźć sie scieżka do pliku wynikowego
	err:		.asciiz "Wystapil problem przetwarzania!"
	foundFig:	.asciiz "!!! Znalazlem figure, przystepuje do liczenia obwodu.\n"
	finishFig:	.asciiz "DONE Obwod przeliczony, przechodze dalej.\n"
	finishArr:	.asciiz "Tablica pikseli przetworzona. Kreuje plik wyjsciowy.\n"
	bitmap:		.asciiz "Zapisano wynik do: "
	
.text
# licznik figur - header (1 bajt)
# właściwy header zaczyna sie na header + 2 (chodzi o wyrównanie słów)
# rozmiar pliku - header + 4
# offset - header + 12
# szerokość - header + 20
# długość - header + 24

	# Rejestry S ogólnego użytku przez cały program
# $s0	- deskryptor pliku wejściowego / wyjściowego
# $s1	- adres tablicy pikseli wejściowej / wyjściowej
# $s2	- wskaźnik chodzący w tablicy wejściowej / wyjściowej
# $s3	- szerokość
# $s4	- wysokość
# $s5	- współrzędna x
# $s6	- współrzędna y
# $s7	- liczba bajtów na wiersz

main:
	li	$v0, 13			#otwieramy plik wejściowy
	la	$a0, import
	li	$a2, 0
	li	$a1, 0
	syscall
	bltz	$v0, blad
	move 	$s0, $v0		#przenosimy deskryptor
	
	li	$v0, 14
	la	$a0, ($s0)
	la	$a1, header + 2		#ładujemy header do zaalokowanej pamięci
	li	$a2, 122
	syscall
	bltz	$v0, blad
	
	#alokacja pamięci na dane z pliku .bmp
	li	$v0, 9
	lw	$t9, header + 36	#wielkość pliku znajduje się pod header + 36
	la	$a0, ($t9)
	syscall
	move	$s1, $v0		#wskaźnik na zaalokowaną pamięć do $s1
	
	li	$v0, 14
	la	$a0, ($s0)
	la	$a1, ($s1)
	la	$a2, ($t9)		#przekazujemy wielkość pliku
	syscall
	
	#zamykamy plik, mamy juz wszystkie potrzebne dane
	move 	$a0, $t1
	li	$v0, 16
	syscall
	
	#ustawiamy wskaźnik na pierwszy piksel tablicy pikseli
	la	$s2, 0($s1)
	#inicjujemy wartości ważne później do przetwarzania obrazu
	lw	$s3, header + 20	#szerokość
	lw	$s4, header + 24	#długość
	move	$s7, $s3
	add	$s7, $s7, $s7		#wartość do skoku do kolejnego wiersza (do operacji y++)
	add	$s7, $s7, $s7

	# FAZA PRZESZUKIWANIA TABLICY
# $t0 - aktualny piksel
# $t1 - dolna krawędź prostokąta
# $t2 - prawa ---"---
# $t3 - górna ---"---
# $t4 - lewa  ---"---
# $t5 - rejestr na obliczanie obwodu znalezionej figury
# $t6 - adres piksela rozpoczynajacego prostokąt wokół figury (przy zapisie do tablic wartości)

# $t8 - flaga / liczba znalezionych figur (counter)
# $t9 - adres piksela rozpoczynajacęgo obwód
			
findNextPixel:				#szukamy czarnego piksela w tablicy
	lw	$t0, 0($s2)
	beq	$t0, 0xff000000, setUp	#znaleźlismy figurę - przechodzimy do obliczania obwodu
	beq	$t0, 0xff000001, skipPixels #obszar znalezionej figury, pomijamy
	
	addi	$s2, $s2, 4		#idziemy do kolejnego piksela
	addi 	$s5, $s5, 1		#dodajemy 1 do współrzędnej x
	bne	$s5, $s3, findNextPixel
	#jeżeli doszlismy do konca wiersza, zmieniamy go
	move	$s5, $zero
	addi	$s6, $s6, 1
	bne	$s6, $s4, findNextPixel	
	j	createOutput			#skok do zapisu wyniku
	
setUp:
	li	$v0, 4
	la	$a0, foundFig
	syscall
	
	move	$t1, $s6		#zapisujemy współrzędną najbardziej na dół
	move	$t4, $s3		#maksymalne wymiary obrazu do zapisania lewego krańca figury
	la	$t9, 0($s2)		#zapisujemy adres piksela, w którym sie znaleźliśmy
	addi 	$t0, $t0, 1		#odwiedziliśmy piksel - zaznaczmy to
	sw	$t0, 0($s2)		#zapisujemy w tablicy, że został odwiedzony

goRight:
	addi	$s2, $s2, 4
	add	$s5, $s5, 1
	beq	$s2, $t9, saveFigure	#jeżeli trafiliśmy na poczatek obwodu, to konczymy liczenie
	lw	$t0, 0($s2)		#sprawdzamy barwę
	bne	$t0, 0xffffffff, cRight
	addi 	$s2, $s2, -4
	sub	$s5, $s5, 1
	j	goUp
cRight:
	jal	checkPixels
	bne	$t0, 1, cRightFin
	j	goDown
cRightFin:
	lw	$t0, 0($s2)		#odwiedzilismy piksel - zaznaczmy to
	addi 	$t0, $t0, 1
	sw	$t0, 0($s2)
	
	addi	$t5, $t5, 1		#dodajemy 1 do obwodu figury
	
	slt	$t8, $t2, $s5		#sprawdzamy, czy doszlismy dalej na prawo
	beqz	$t8, goRight
	move	$t2, $s5
	j	goRight
	
goUp:
	add	$s2, $s2, $s7
	add	$s6, $s6, 1
	beq	$s2, $t9, saveFigure	#jeżeli trafiliśmy na poczatek obwodu, to konczymy liczenie
	lw	$t0, 0($s2)		#sprawdzamy barwę
	bne	$t0, 0xffffffff, cUp
	sub 	$s2, $s2, $s7
	sub	$s6, $s6, 1
	j	goLeft
cUp:
	jal	checkPixels
	bne	$t0, 1, cUpFin
	j	goRight
cUpFin:
	lw	$t0, 0($s2)		#odwiedzilismy piksel - zaznaczmy to
	addi 	$t0, $t0, 1
	sw	$t0, 0($s2)
	
	addi	$t5, $t5, 1		#dodajemy 1 do obwodu figury
	
	slt	$t8, $t3, $s6		#sprawdzamy czy doszlismy dalej na górę
	beqz	$t8, goUp
	move	$t3, $s6
	j	goUp

goLeft:
	addi	$s2, $s2, -4
	sub	$s5, $s5, 1
	beq	$s2, $t9, saveFigure	#jeżeli trafiliśmy na poczatek obwodu, to konczymy liczenie
	lw	$t0, 0($s2)		#sprawdzamy barwę
	bne	$t0, 0xffffffff, cLeft
	addi 	$s2, $s2, 4
	add	$s5, $s5, 1
	j	goDown
cLeft:
	jal	checkPixels
	bne	$t0, 1, cLeftFin
	j	goUp
cLeftFin:
	lw	$t0, 0($s2)		#odwiedzilismy piksel - zaznaczmy to
	addi 	$t0, $t0, 1
	sw	$t0, 0($s2)
	
	addi	$t5, $t5, 1		#dodajemy 1 do obwodu figury
	
	slt	$t8, $s5, $t4		#sprawdzamy czy doszlismy dalej na lewo
	beqz	$t8, goLeft
	move	$t4, $s5
	j	goLeft

goDown:
	sub	$s2, $s2, $s7
	sub	$s6, $s6, 1
	beq	$s2, $t9, saveFigure	#jeżeli trafiliśmy na poczatek obwodu, to konczymy liczenie
	lw	$t0, 0($s2)		#sprawdzamy barwę
	bne	$t0, 0xffffffff, cDown
	add 	$s2, $s2, $s7
	add	$s6, $s6, 1
	j	goRight
cDown:
	jal	checkPixels
	bne	$t0, 1, cDownFin
	j	goLeft
cDownFin:
	lw	$t0, 0($s2)		#odwiedzilismy piksel - zaznaczmy to
	addi 	$t0, $t0, 1
	sw	$t0, 0($s2)
	
	addi	$t5, $t5, 1		#dodajemy 1 do obwodu figury
					#nie musimy sprawdzać, czy doszlismy niżej, juz mamy zapisaną wartość
	j	goDown
	
checkPixels:				#sprawdzamy po kolei góra, prawo, dół, lewo, jeżeli jest biały sąsiad, to od razu przechodzimy dalej
	add	$s2, $s2, $s7
	lw	$t0, 0($s2)
	sub	$s2, $s2, $s7
	beq	$t0, 0xffffffff, checkFin
	addi	$s2, $s2, 4
	lw	$t0, 0($s2)
	subi	$s2, $s2, 4
	beq	$t0, 0xffffffff, checkFin
	sub	$s2, $s2, $s7
	lw	$t0, 0($s2)
	add	$s2, $s2, $s7
	beq	$t0, 0xffffffff, checkFin
	subi	$s2, $s2, 4
	lw	$t0, 0($s2)
	addi 	$s2, $s2, 4
	beq	$t0, 0xffffffff, checkFin
	addiu 	$t0, $zero, 1
checkFin:
	jr	$ra
	nop
	
saveFigure:
	addi	$t5, $t5, 1		#uzupełniamy, bo nie doliczyliśmy poczatkowego piksela
			
	lb	$t8, header
	add	$t8, $t8, $t8		#zamiast mnożenia używamy dodawania do uzyskania bajtów do przemieszczenia w tablicach
	add	$t8, $t8, $t8
	la	$t0, perimeter		#zapisujemy po kolei wartości wyliczone podczas analizy figury
	add	$t0, $t0, $t8
	sw	$t5, ($t0)
	
	la	$t0, figureAddress	#zapisujemy adres piksela najbardziej na lewo i w dół w prostokacie okalającym figurę
	add	$t0, $t0, $t8
	mul	$t5, $t1, $s7		#sprawdzamy ile bajtów musimy przeskoczyć w górę, obwód jest juz zapisany, wiec wykorzystujemy do tego rejestr $t5
	add	$t6, $s1, $t5		#w $t6 tymczasowo zapisujemy adres znajdowanego piksela
	mul	$t5, $t4, 4
	add	$t6, $t6, $t5
	sw	$t6, ($t0)
	la	$t0, height		#zapisujemy wysokość i szerokośc prostokąta
	add	$t0, $t0, $t8
	sub	$t1, $t3, $t1
	addi	$t1, $t1, 1
	sw	$t1, ($t0)
	la	$t0, width
	add	$t0, $t0, $t8
	sub	$t1, $t2, $t4
	addi	$t1, $t1, 1
	sw	$t1, ($t0)
	
	lb	$t8, header		#zapisujemy licznik figur na pierwszym bajcie header
	addi	$t8, $t8, 1
	sb	$t8, header
	move	$t0, $zero		#dla pewności zerujemy rejestry tymczasowe
	move	$t1, $zero
	move	$t2, $zero
	move	$t3, $zero
	move	$t4, $zero
	move	$t5, $zero
	move	$t6, $zero
	
	li	$v0, 4
	la	$a0, finishFig
	syscall
	
	j	findNextPixel		#przechodzimy do daleszego szukania
	
	# FAZA RYSOWANIA FIGUR
# zamieniamy dane z pliku wejsciowego (adres pliku, wskaźnik chodzący)
# $t6 - bufor
# $t9 - liczba pikseli w pliku

createOutput:
	li	$v0, 4
	la	$a0, finishArr
	syscall
	
	li	$v0, 9			#alokujemy pamięć na plik wyjściowy
	lw	$t0, header + 36
	la	$a0, 0($t0)
	syscall
	move	$s1, $v0		#przenosimy adres początku pliku wyjściowego
	
	mul	$t9, $s3, $s4		#ile pikseli znajduje się w pliku (wys x szer)

	move	$t0, $s1
	move	$t8, $zero
	add	$t1, $zero, 0xffffffff	#kolor biały do wypełniania
fill:					#wypełniamy obraz białym kolorem
	sw	$t1, 0($t0)
	add	$t0, $t0, 4
	add	$t8, $t8, 1
	blt	$t8, $t9, fill

	la	$s2, ($s1)
	add	$s2, $s2, 4
	
# $t0 - 0x7fffffff przy wypełnianiu
# $t1 - wybrany indeks tablicy
# $t2 - max adres
# $t3 - adres aktualny
# $t4 - aktualna liczba reprezentujaca obwód
# $t5 - aktualny indeks tablicy
chooseFigure:				#wybieramy figurę o najmniejszym obwodzie
	lb	$t8, header
	add	$t8, $t8, $t8
	add	$t8, $t8, $t8
	add	$t0, $zero, 0x7fffffff	#najmniejszy spotkany dotychczas obwód - na początek ładujemy największą możliwą wartość
	add	$t1, $zero, $zero	#nr indeksu, pod którym mamy wybrany obwód
	la	$t2, perimeter		#adres maksymalny
	add	$t2, $t2, $t8
	la	$t3, perimeter		#adres aktualny
loop:
	lw	$t4, ($t3)
	bltz	$t4, continue		#jeżeli obwód mniejszy niż zero, to znaczy, że juz przepisalismy figurę
	slt	$t6, $t4, $t0
	beqz	$t6, continue
	move	$t0, $t4
	move	$t1, $t5
continue:
	add	$t3, $t3, 4		#przekakujemy do kolejnej pozycji w tablicy
	add	$t5, $t5, 1		#inkrementujemy indeks
	blt	$t3, $t2, loop
	
	beq	$t0, 0x7fffffff, saveBMP #wszystkie figury zostały przerysowane, nie zmieniła sie wartość najmniejszego obwodu
	add	$t1, $t1, $t1		#zamiast mnożyć dodajemy do siebie dwa razy wartość indeksu
	add	$t1, $t1, $t1
	la	$t0, perimeter		#ustawiamy obwód na -1 - figura zostanie przerysowana
	add	$t0, $t0, $t1
	add	$t2, $zero, -1
	sw	$t2, ($t0)
	
# $t0 - adres aktualnego piksela
# $t1 - adres początkowy figury
# $t2 - max wysokość
# $t3 - aktualna wysokosć
# $t4 - max szerokość
# $t5 - aktualna szerokość
	move	$t8, $t1		#przenosimy zmodyfikowany indeks
	la	$t0, ($s2)
	la	$t5, figureAddress
	add	$t5, $t5, $t8
	lw	$t1, ($t5)
	la	$t5, height
	add	$t5, $t5, $t8
	lw	$t2, ($t5)
	la	$t5, width
	add	$t5, $t5, $t8
	lw	$t4, ($t5)
	add	$t3, $zero, $zero	#zerujemy dla pewności
	add	$t5, $zero, $zero
writeColumn:
	lw	$t6, ($t1)		#ładujemy do bufora liczbe reprezentującą piksel
	bne	$t6, 0xff000001, writePixel	#jeżeli piksel należy do obwodu, to przywracamy całkowicie czarną barwę
	sub	$t6, $t6, 1
writePixel:
	sw	$t6, ($t0)
	add	$t3, $t3, 1
	add	$t0, $t0, $s7
	add	$t1, $t1, $s7
	bne	$t2, $t3, writeColumn

switchColumn:
	mul	$t6, $t2, $s7		#mnożymy maks wysokość razy liczba bajtów na wiersz
	sub	$t0, $t0, $t6		#zmieniamy pozycje wskaźników
	sub	$t1, $t1, $t6
	add	$t0, $t0, 4
	add	$t1, $t1, 4
	add	$t5, $t5, 1		#doliczamy szerokość
	add	$t3, $zero, $zero	#zerujemy wysokość aktualną
	bne	$t4, $t5, writeColumn	#jeżeli nie doszlismy do maks szerokości
	
	add	$t6, $zero, 4		#przesuwamy pointer o 3 piksele - tworzymy przerwę między figurami
	mul	$t6, $t6, 3
	add	$t0, $t0, $t6
	move	$s2, $t0		#zapisujemy aktualne położenie pointera
	move	$t5, $zero		#zerujemy dla pewności
	move	$t6, $zero
	j	chooseFigure
	
	# FAZA ZAPISU DO PLIKU
saveBMP:				#standardowa operacja zapisu pliku BMP
	mul	$t9, $t9, 4		#liczba bajtów zajmowana przez piksele
	li	$v0, 13			#otwieramy plik wyjściowy
	la	$a0, output
	li	$a1, 1
	li	$a2, 0
	syscall
	
	move	$s0, $v0		#przenosimy deskryptor pliku wyjściowego
	
	li	$v0, 15			#zapisujemy header, zostaje taki sam
	move	$a0, $s0
	la	$a1, header + 2
	li	$a2, 122
	syscall
	
	li	$v0, 15			#zapisujemy tablicę pikseli
	move	$a0, $s0
	move	$a1, $s1
	move	$a2, $t9
	syscall
	
	li	$v0, 16			#zamykamy plik
	syscall
	
	li	$v0, 4			#komunikaty o poprawnym zapisie
	la	$a0, bitmap
	syscall
	li	$v0, 4
	la	$a0, output
	syscall
	
	j	exit			#koniec programu

skipPixels:
	addi	$s2, $s2, 4		#idziemy do kolejnego piksela
	addi 	$s5, $s5, 1		#dodajemy 1 do współrzędnej x
	lw	$t0, 0($s2)
	beq	$t0, 0xffffffff, findNextPixel
	j	skipPixels
	
blad:					#coś poszło nie tak przy przetwarzaniu pliku
	li	$v0, 4
	la	$a0, err
	syscall

exit:
	li	$v0, 10
	syscall

