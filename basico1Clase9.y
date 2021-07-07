%{
#include<stdlib.h>
#include<stdio.h>
#include<math.h>
#include<string.h>
#include<ctype.h>
/*prototipos de funcion*/
int yylex();
void yyerror(char *s);
int localizaSimbolo(char *lexema,int token,int indice);
int generaCodigo(int op,int a1,int a2,int a3,int indice);
void imprimeTablaCodigo();
void interpretaCodigo(int indice);
int genTemp(int indice);
int creacopia(int origen,int destino);
int nSim=0;
FILE* arch;
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

typedef struct{
        char nombre[100];
        double valor_retorno;
        TipoTS tablaSimbolos[100];
        TipoTC TCodigo[100];
        int cx;
        int nSim;
        int nVarTemp;
}TipoFuncion;

int nReg=0;
TipoFuncion TablaFunciones[100];
int nFunc=0;
TipoTC TCodigo[100];
TipoTS tablaSimbolos[100];
char lexema[100];
%}
%token  SI  IGUAL  PARDER DEF MAIN RETURN LLAMADAFUNC
%token ID NUMBER MIENTRAS IMPRIMIR IMPRIME
%token SUMAR MULTIPLICAR RESTAR ASIGNAR COMPIGUAL COMPMAYOR COMPMENOR SALTARF SALTAR
%%
start: {nFunc=1;} programa;


programa: DEF MAIN '(' PARDER '{' {nFunc=0;} listainst '}';
programa: listadefinicionfuncion DEF MAIN '(' PARDER '{' {nFunc=0;nReg++;} listainst '}';



listadefinicionfuncion:  listadefinicionfuncion definicionfuncion | definicionfuncion ;

definicionfuncion: DEF ID '(' listaparams PARDER '{' listainst retorno ';' '}' {nFunc++;nReg++;} ;




retorno: RETURN expr;
listaparams:listaparams ',' ID | ID;
listainst: listainst instr  | instr  ;
instr :  asignacion ';'  | seleccion  | iteracion  |impresion ';'  ;
impresion: IMPRIME '(' ID { $$=localizaSimbolo(lexema,ID,nFunc);  } PARDER  {generaCodigo(IMPRIMIR,$4,'-','-',nFunc);};


asignacion:ID { $$=localizaSimbolo(lexema,ID,nFunc);} IGUAL bloque_asigna  {generaCodigo(ASIGNAR,$2,$4,'-',nFunc);} ;  
bloque_asigna: expr {$$=$1;} | llamadafuncion;
llamadafuncion: ID {$$=localizaSimbolo(lexema,LLAMADAFUNC,nFunc);}'(' listavalores PARDER;
listavalores: listavalores ',' expr | expr ;

iteracion: MIENTRAS '(' { $$=cx+1;} condicion PARDER  {generaCodigo(SALTARF,$4,'?','-',nFunc) ;$$=cx;}  bloque   {generaCodigo(SALTAR,$3,'-','-',nFunc) ;} {TCodigo[$6].a2=cx+1;}   ;



seleccion:SI '(' condicion PARDER {generaCodigo(SALTARF,$3,'?','-',nFunc) ;$$=cx;}  bloque {TCodigo[$5].a2=cx+1;} ;
bloque: '{' listainst '}' | instr ;




condicion: expr IGUAL expr {int i=genTemp(nFunc); generaCodigo(COMPIGUAL,i,$1,$3,nFunc);$$=i;};
condicion: expr  '<'  expr {int i=genTemp(nFunc); generaCodigo(COMPMENOR,i,$1,$3,nFunc);$$=i;};
condicion: expr  '>'  expr {int i=genTemp(nFunc); generaCodigo(COMPMAYOR,i,$1,$3,nFunc);$$=i;};




expr    : expr '+' term {int i=genTemp(nFunc);generaCodigo(SUMAR,i,$1,$3,nFunc);$$=i;};
expr    : expr '-' term  {int i=genTemp(nFunc);generaCodigo(RESTAR,i,$1,$3,nFunc);$$=i;} ;
expr    :  term  {$$=$1;};   ; 
term    : term '*' factor {int i=genTemp(nFunc);generaCodigo(MULTIPLICAR,i,$1,$3,nFunc);$$=i;} ;
term    : factor {$$=$1;};
factor  : NUMBER { $$=localizaSimbolo(lexema,NUMBER,nFunc);  }  ;
factor  : ID { $$=localizaSimbolo(lexema,ID,nFunc);  }  ;
factor: '(' expr ')'   ;


%%

int creacopia(int origen,int destino){
        int i;        
        TablaFunciones[destino].nSim=TablaFunciones[origen].nSim;
        TablaFunciones[destino].cx=TablaFunciones[origen].cx;
        TablaFunciones[destino].nVarTemp=TablaFunciones[origen].nVarTemp;
        TablaFunciones[destino].valor_retorno=TablaFunciones[origen].valor_retorno;
        for(i=0;i<=TablaFunciones[origen].cx;i++ ){
                TablaFunciones[destino].TCodigo[i].a1= TablaFunciones[origen].TCodigo[i].a1;
                TablaFunciones[destino].TCodigo[i].a2= TablaFunciones[origen].TCodigo[i].a2;
                TablaFunciones[destino].TCodigo[i].a3= TablaFunciones[origen].TCodigo[i].a3;
                TablaFunciones[destino].TCodigo[i].op= TablaFunciones[origen].TCodigo[i].op;
        }
        for(i=0;i<=TablaFunciones[origen].nSim;i++ ){
                TablaFunciones[destino].tablaSimbolos[i].token= TablaFunciones[origen].tablaSimbolos[i].token;
                TablaFunciones[destino].tablaSimbolos[i].valor=TablaFunciones[origen].tablaSimbolos[i].valor;
                strcpy(TablaFunciones[destino].tablaSimbolos[i].nombre,TablaFunciones[origen].tablaSimbolos[i].nombre);
        }
}

void imprimeTablaCodigo(){
        int i,indice;
        printf("Tabla Codigo\n");
          for(indice=0;indice<nReg;indice++ ){
                printf("Tabla Codigo funcion %d\n",indice);
                for(i=0;i<=TablaFunciones[indice].cx;i++ ){
                printf("%d\t%d\t%d\t%d\n",TablaFunciones[indice].TCodigo[i].op,TablaFunciones[indice].TCodigo[i].a1,TablaFunciones[indice].TCodigo[i].a2,TablaFunciones[indice].TCodigo[i].a3);
                }
        }

}

void interpretaCodigo(int indice){
        int i;int op,a1, a2, a3;
        printf("Tabla Codigo\n");
        for(i=0;i<=TablaFunciones[indice].cx;i++ ){
                a1=TablaFunciones[indice].TCodigo[i].a1;
                a2=TablaFunciones[indice].TCodigo[i].a2;
                a3=TablaFunciones[indice].TCodigo[i].a3;
                op=TablaFunciones[indice].TCodigo[i].op;
                if(op==SUMAR){
                        TablaFunciones[indice].tablaSimbolos[a1].valor=TablaFunciones[indice].tablaSimbolos[a2].valor+TablaFunciones[indice].tablaSimbolos[a3].valor;
                       
                }
                if(op==ASIGNAR){
                        TablaFunciones[indice].tablaSimbolos[a1].valor = TablaFunciones[indice].tablaSimbolos[a2].valor ;

                }
                if(op==COMPIGUAL){
                        TablaFunciones[indice].tablaSimbolos[a1].valor=(TablaFunciones[indice].tablaSimbolos[a2].valor==TablaFunciones[indice].tablaSimbolos[a3].valor);
                }
                if(op==SALTARF){
                        if(!TablaFunciones[indice].tablaSimbolos[a1].valor)
                                i=a2-1;
                }
                if(op==SALTAR){
                        i=a1-1;
                }
                if(op==COMPMENOR){
                        TablaFunciones[indice].tablaSimbolos[a1].valor=(TablaFunciones[indice].tablaSimbolos[a2].valor<TablaFunciones[indice].tablaSimbolos[a3].valor);
                }
                if(op==IMPRIMIR){
                        
                        printf("%lf\n",TablaFunciones[indice].tablaSimbolos[a1].valor);
                }
        }


}

int genTemp(int indice){
        int pos;        
        char t[10];
        sprintf(t,"_T%d",TablaFunciones[indice].nVarTemp++);
        pos=localizaSimbolo(t,ID,indice);
        return pos;
        
}

int generaCodigo(int op,int a1,int a2,int a3,int indice){
        TablaFunciones[indice].cx++;
        TablaFunciones[indice].TCodigo[TablaFunciones[indice].cx].op=op;
        TablaFunciones[indice].TCodigo[TablaFunciones[indice].cx].a1=a1;
        TablaFunciones[indice].TCodigo[TablaFunciones[indice].cx].a2=a2;
        TablaFunciones[indice].TCodigo[TablaFunciones[indice].cx].a3=a3;

  
 
}
void imprimeTablaSimbolos(){
        int i,indice;
        printf("Tabla Simbolos\n");
        for(indice=0;indice<nReg;indice++ ){
                printf("Tabla Simbolos funcion %d\n",indice);
                for(i=0;i<TablaFunciones[indice].nSim;i++ ){
                printf("%d\t%s\t%d\t%lf\n",i, TablaFunciones[indice].tablaSimbolos[i].nombre,TablaFunciones[indice].tablaSimbolos[i].token,TablaFunciones[indice].tablaSimbolos[i].valor);
                }
        }
}
int localizaSimbolo(char *lexema,int token,int indice){
        
        int i;
        if (token==LLAMADAFUNC){
                for(i=0;i<=nReg;i++ ){
                        printf("HH %s",TablaFunciones[i].nombre);
                        if(!strcmp(TablaFunciones[i].nombre,lexema)){
                                int j=nReg++;
                                creacopia( i,j);
                                return j;
                        }
                }
                yyerror("Función indefinida");
        }        
        else{
                for(i=0;i<TablaFunciones[indice].nSim;i++ ){
                        if(!strcmp(TablaFunciones[indice].tablaSimbolos[i].nombre,lexema)){
                                return i;                
                        }        
                }
                
                strcpy(TablaFunciones[indice].tablaSimbolos[TablaFunciones[indice].nSim].nombre,lexema);
                TablaFunciones[indice].tablaSimbolos[TablaFunciones[indice].nSim].token=token;
                if(token == NUMBER){
                                TablaFunciones[indice].tablaSimbolos[TablaFunciones[indice].nSim].valor=atof(lexema);
                }
                else{ 
                        TablaFunciones[indice].tablaSimbolos[TablaFunciones[indice].nSim].valor=0.0;
                }
                TablaFunciones[indice].nSim++;
                return TablaFunciones[indice].nSim-1;
        }
}
void yyerror(char *s){
	fprintf(stderr,"%s\n",s);
}

int yylex(){
    	char c;int i;
	 while (!feof(arch)){
	    	c=fgetc(arch);
	    	if (c=='\n') continue;
	    	if (c==EOF) return c; 
		if (isspace(c)) continue;
		if(isalpha(c)){
			i=0;
			do{
				lexema[i++]=c;
				c=fgetc(arch);
			}while(isalnum(c));
			ungetc(c,arch);
			lexema[i++]='\0';
			if(!strcmp(lexema,"if")) return SI; /*espalreservada*/
			 
			if(!strcmp(lexema,"while")) return MIENTRAS; 
		 
			if(!strcmp(lexema,"def")) return DEF; 
			if(!strcmp(lexema,"printf")) return IMPRIME; 
			
			if(!strcmp(lexema,"main")) return MAIN;
			if(!strcmp(lexema,"return")) return RETURN;

			return ID;

		}
		if(isdigit(c)){ 
			//scanf("%d",&yylval);
			i=0;
			do{
				lexema[i++]=c;
				c=fgetc(arch);
			}while(isdigit(c));
			ungetc(c,arch);
			lexema[i++]='\0';
			return NUMBER;
		}
		
		if(c=='='){
			return IGUAL;
		}
		if(c==')'){
			return PARDER;
		}
		return c;
	}
}


int main (int argc ,char *argv[] ){
   
    if(argc!=2) {
        printf("Ha olvidado su nombre.\n");
        exit(1); 
    }
    else{
        arch=fopen(argv[1],"r");
        if(!yyparse()){
		printf("cadena válida\n");
		imprimeTablaSimbolos();
		imprimeTablaCodigo();
                interpretaCodigo(0);
                imprimeTablaSimbolos();
	}
	else{
		printf("cadena inválida\n");	
	}
        }
}

