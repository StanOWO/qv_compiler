LEX=flex
YACC=bison
CC=g++
OBJECT=main
YACCNAME=11130038-parser
LEXNAME=11130038-scanner

$(OBJECT): lex.yy.o ${YACCNAME}.tab.o main.o
		$(CC) main.o lex.yy.o ${YACCNAME}.tab.o -o $(OBJECT)

lex.yy.o: lex.yy.c ${YACCNAME}.tab.h main.h
		$(CC) -c lex.yy.c

${YACCNAME}.tab.o: ${YACCNAME}.tab.c main.h
		$(CC) -c ${YACCNAME}.tab.c

${YACCNAME}.tab.c ${YACCNAME}.tab.h: ${YACCNAME}.y
		$(YACC) -d ${YACCNAME}.y

lex.yy.c: ${LEXNAME}.l
		$(LEX) ${LEXNAME}.l

main.o: main.cpp
		$(CC) -c main.cpp

clean:
		@del -f $(OBJECT) *.o lex.yy.c ${YACCNAME}.tab.h ${YACCNAME}.tab.c main.exe
