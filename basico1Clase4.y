%{
#include<stdlib.h>
#include<stdio.h>
#include<math.h>
#include<string.h>
#include<ctype.h>
/*prototipos de funcion*/
int yylex();
void yyerror(char *s);
int localizaSimbolo(char *lexema,int token);
int generaCodigo(int op,int a1,int a2,int a3);
void imprimeTablaCodigo();
void interpretaCodigo();
int genTemp();
int nSim=0;
int cx=-1;
int nVarTemp=1;
/*estructuras*/
typedef struct{
        int op;
        int a1;
        int a2;
        int a3;
}TipoTC;

typedef struct{
        char nombre[100];
        int token;
        double valor;
}TipoTS;
TipoTC TCodigo[100];
TipoTS tablaSimbolos[100];
char lexema[100];
%}
%token  SI  IGUAL  PARDER
%token ID MIENTRAS NUMBER IMPRIMIR IMPRIME
%token SUMAR MULTIPLICAR RESTAR ASIGNAR COMPIGUAL COMPMAYOR COMPMENOR SALTARF SALTAR
%%

programa: /*cabeceras prototipos*/ listainst;
listainst: listainst instr  | instr  ;
instr :  asignacion ';'  | seleccion  | iteracion  |impresion ';';
impresion: IMPRIME '(' ID { $$=localizaSimbolo(lexema,ID);  } PARDER  {generaCodigo(IMPRIMIR,$4,'-','-');};


asignacion:ID { $$=localizaSimbolo(lexema,ID);} IGUAL expr  {generaCodigo(ASIGNAR,$2,$4,'-');} ; 



iteracion: MIENTRAS '(' { $$=cx+1;} condicion PARDER  {generaCodigo(SALTARF,$4,'?','-') ;$$=cx;}  bloque   {generaCodigo(SALTAR,$3,'-','-') ;} {TCodigo[$6].a2=cx+1;}   ;



seleccion:SI '(' condicion PARDER {generaCodigo(SALTARF,$3,'?','-') ;$$=cx;}  bloque {TCodigo[$5].a2=cx+1;} ;
bloque: '{' listainst '}' | instr ;




condicion: expr IGUAL expr {int i=genTemp(); generaCodigo(COMPIGUAL,i,$1,$3);$$=i;};
condicion: expr  '<'  expr {int i=genTemp(); generaCodigo(COMPMENOR,i,$1,$3);$$=i;};
condicion: expr  '>'  expr {int i=genTemp(); generaCodigo(COMPMAYOR,i,$1,$3);$$=i;};




expr    : expr '+' term {int i=genTemp();generaCodigo(SUMAR,i,$1,$3);$$=i;};
expr    : expr '-' term  {int i=genTemp();generaCodigo(RESTAR,i,$1,$3);$$=i;} ;
expr    :  term  {$$=$1;};   ; 
term    : term '*' factor {int i=genTemp();generaCodigo(MULTIPLICAR,i,$1,$3);$$=i;} ;
term    : factor {$$=$1;};
factor  : NUMBER { $$=localizaSimbolo(lexema,NUMBER);  }  ;
factor  : ID { $$=localizaSimbolo(lexema,ID);  }  ;

factor: '(' expr ')'   ;


%%

void imprimeTablaCodigo(){
        int i;
        printf("Tabla Codigo\n");
        for(i=0;i<=cx;i++ ){
                printf("%d\t%d\t%d\t%d\n",TCodigo[i].op,TCodigo[i].a1,TCodigo[i].a2,TCodigo[i].a3);
        }

}

void interpretaCodigo(){
        int i;int op,a1, a2, a3;
        printf("Tabla Codigo\n");
        for(i=0;i<=cx;i++ ){
                a1=TCodigo[i].a1;
                a2=TCodigo[i].a2;
                a3=TCodigo[i].a3;
                op=TCodigo[i].op;
                if(op==SUMAR){
                        tablaSimbolos[a1].valor=tablaSimbolos[a2].valor+tablaSimbolos[a3].valor;
                       
                }
                if(op==ASIGNAR){
                        tablaSimbolos[a1].valor = tablaSimbolos[a2].valor ;

                }
                if(op==COMPIGUAL){
                        tablaSimbolos[a1].valor=(tablaSimbolos[a2].valor==tablaSimbolos[a3].valor);
                }
                if(op==SALTARF){
                        if(!tablaSimbolos[a1].valor)
                                i=a2-1;
                }
                if(op==SALTAR){
                        i=a1-1;
                }
                if(op==COMPMENOR){
                        tablaSimbolos[a1].valor=(tablaSimbolos[a2].valor<tablaSimbolos[a3].valor);
                }
                if(op==IMPRIMIR){
                        
                        printf("%lf\n",tablaSimbolos[a1].valor);
                }
        }


}

int genTemp(){
        int pos;        
        char t[10];
        sprintf(t,"_T%d",nVarTemp++);
        pos=localizaSimbolo(t,ID);
        return pos;
        
}

int generaCodigo(int op,int a1,int a2,int a3){
        cx++;
        TCodigo[cx].op=op;
        TCodigo[cx].a1=a1;
        TCodigo[cx].a2=a2;
        TCodigo[cx].a3=a3;

  
 
}
void imprimeTablaSimbolos(){
        int i;
        printf("Tabla Simbolos\n");
        for(i=0;i<nSim;i++ ){
                printf("%d\t%s\t%d\t%lf\n",i, tablaSimbolos[i].nombre,tablaSimbolos[i].token,tablaSimbolos[i].valor);
        }

}
int localizaSimbolo(char *lexema,int token){

        int i;
        for(i=0;i<nSim;i++ ){
                if(!strcmp(tablaSimbolos[i].nombre,lexema)){
                        return i;                
                }        
        }
        
        strcpy(tablaSimbolos[nSim].nombre,lexema);
        tablaSimbolos[nSim].token=token;
        if(token == NUMBER){
                        tablaSimbolos[nSim].valor=atof(lexema);
        }
        else{ 
                tablaSimbolos[nSim].valor=0.0;
        }
        nSim++;
        return nSim-1;
}
void yyerror(char *s){
	fprintf(stderr,"%s\n",s);
}



int yylex(){
	char c;int i;
	while((c=getchar())==' ');/*permitirme ignorar blancos*/
	/*if (c=='\n') return CAMBIOLINEA;*/
	if(isalpha(c)){
		i=0;
		do{
			lexema[i++]=c;
			c=getchar();
		}while(isalnum(c));
		ungetc(c,stdin);
		lexema[i++]='\0';
		if(!strcmp(lexema,"if")) return SI; /*espalreservada*/
                if(!strcmp(lexema,"while")) return MIENTRAS; /*espalreservada*/
                if(!strcmp(lexema,"printf")) return IMPRIME; /*espalreservada*/
		return ID;

	}
	if(isdigit(c)){ 
		//scanf("%d",&yylval);
		i=0;
		do{
			lexema[i++]=c;
			c=getchar();
		}while(isdigit(c));
		ungetc(c,stdin);
		lexema[i++]='\0';
		return NUMBER;
	}
	if(c=='\n'){
		return 0;
	}
	if(c=='='){
		return IGUAL;
	}
        if(c==')'){
		return PARDER;
	}
	
	return c;
}

int main(){
	if(!yyparse()){
		printf("cadena válida\n");
		imprimeTablaSimbolos();
		imprimeTablaCodigo();
                interpretaCodigo();
                imprimeTablaSimbolos();
	}
	else{
		printf("cadena inválida\n");	
	}
}

