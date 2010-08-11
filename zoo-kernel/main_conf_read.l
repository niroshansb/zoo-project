/* pour pouvoir acceder au numero de ligne dans bison */
%option yylineno


%{
//======================================================
/**
Zoo main configuration file parser
**/
//======================================================


#include <string.h>
#include "main_conf_read.tab.h"
static int affichetrace = 0 ;
static int attentionImpossibleDeTrouverXMLDeclapres = 0 ;
static int attentionImpossibleDeTrouverPIapres = 0 ;

%}


/*====================================================*/
/*====================================================*/
/* Les Separateurs xml */
/*====================================================*/
S		[ \t\r\n]+
/*====================================================*/




/*====================================================*/
/* CharRef regle 66 */
/*====================================================*/
CharRef		"&#"[0-9]+";"|"&#x"[0-9a-fA-F]+";"
/*====================================================*/




/*====================================================*/
/*   espaces? '=' espaces?    regle 25  */
/* si on veut pouvoir utiliser S dans bison, */
/* il faut cr�r au moins une autre start condition */
/* comme on n'utilise "egalevolue" que pour version et encoding */
/* il est pr��able de rajouter cette macro */
/*====================================================*/
egalevolue		{S}?"="{S}?
/*====================================================*/




/*====================================================*/
/* Name regle 5 */
/*====================================================*/
/*** Name		[a-zA-Z_:][a-zA-Z0-9.\-_:]* ***/
Name		([_:]|[\x41-\x5A]|[\x61-\x7A]|[\xC0-\xD6]|[\xD8-\xF6]|[\xF8-\xFF])(([\x41-\x5A]|[\x61-\x7A]|[\xC0-\xD6]|[\xD8-\xF6]|[\xF8-\xFF])|[0-9.\-_:])*
/*====================================================*/





/*====================================================*/
/* chardata  regle 14 */
/*====================================================*/
/**chardata	[a-zA-Z0-9_\-.:" "\"\'\\]***/
chardata	[^<]*
/*====================================================*/
attname	[a-zA-Z0-9_\-:]+
attvalue1	[,@a-zA-Z0-9_\-.:" "\"\'/\\]+





/*====================================================*/
/* attvalue regle 10 */
/*====================================================*/
/* attvalue		\"([^"&]|{CharRef})*\"|\'([^'&]|{CharRef})*\' */
/* pas tr� classe mais ca marche . */
attvalue		\"[^"]*\"|\'[^']*\'
/*====================================================*/

virgule	[,]+
whitespace                      [ ]{0,}
whitesp                      [ ]
newline                 [\r\n]|[\n]
newlines                 [\r\n]{1,}|[\n]{1,}










/*====================================================*/
/* initial = de debut a ?> du prolog ; DANSBALISE = dans une balise ; HORSBALISE = hors d'une balise */
/*====================================================*/
%x DANSBALISE HORSBALISE PAIRSTART
/*====================================================*/




%%

"\n" {if (affichetrace==1) printf ("\n\nNEWLINE\n") ; return NEWLINE;}

{newline}+{whitesp}*			{if (affichetrace==1) printf ("\n\nNEWLINE 1\n") ; return NEWLINE;}

<INITIAL,HORSBALISE>"["{attname}"]"             {if (affichetrace==1) printf ("\n\nANID:%s\n",yytext); crlval.chaine=strdup(yytext);crlval.chaine[strlen(crlval.chaine)-1]=0;crlval.chaine+=1;return ANID; }

<INITIAL,HORSBALISE>{attname}             {if (affichetrace==1) printf ("\n\nATT_NAME:%s\n",yytext); crlval.chaine=strdup(yytext); return SPAIR; }

<PAIRSTART,HORSBALISE>{attvalue1}             {if (affichetrace==1) printf ("\n\nATT_VALUE:%s\n",yytext);crlval.chaine=strdup(yytext);BEGIN(INITIAL);return EPAIR;}

<PAIRSTART,INITIAL,HORSBALISE>{whitesp}*"="{whitesp}*             {BEGIN(PAIRSTART);}

<PAIRSTART,INITIAL,HORSBALISE,DANSBALISE>{newline}+{whitesp}*			{if (affichetrace==1) printf ("\n\nNEWLINE 2\n") ; BEGIN(INITIAL); return NEWLINE;}

<INITIAL>"<?"[Xx][Mm][Ll]  { if (attentionImpossibleDeTrouverXMLDeclapres == 1 || attentionImpossibleDeTrouverPIapres == 1) {/* il y a eut un commentaire ou une balise applicative avant la declaration xml */ 	printf("\nerror : a la ligne %d : il y a eut un commentaire ou un PI avant la declaration xml\n",yylineno); exit (10) ; } ; if (affichetrace==1) printf ("\n\nSTARTXMLDECL:%s\n",yytext) ;return STARTXMLDECL;}

<INITIAL>"version"{egalevolue}\"1.0\"|"version"{egalevolue}\'1.0\'  {if (affichetrace==1) printf ("\n\nVERSIONDECL:%s\n",yytext) ;return VERSIONDECL;}
<INITIAL>"version"{egalevolue}\"[^"]*\"|"version"{egalevolue}\'[^']*\'  {/* erreur de version encoding */ 	printf("\nerror : a la ligne %d : la version xml n est pas reconnue : %s\n",yylineno,yytext); exit (9) ; }


<INITIAL>"encoding"{egalevolue}\"[Ii][Ss][Oo]"-8859-1"\"|"encoding"{egalevolue}\'[Ii][Ss][Oo]"-8859-1"\'  {if (affichetrace==1) printf ("\n\nENCODINGDECL:%s\n",yytext) ; return ENCODINGDECL;}
<INITIAL>"encoding"{egalevolue}\"[^"]*\"|"encoding"{egalevolue}\'[^']*\'  {/* erreur de version encoding */ 	printf("\nerror : a la ligne %d : la version d encodage n est pas reconnue : %s\n",yylineno,yytext); exit (8) ; }


<INITIAL>"standalone"{egalevolue}\"yes\"|"standalone"{egalevolue}\'yes\'|"standalone"{egalevolue}\"no\"|"standalone"{egalevolue}\'no\'  {if (affichetrace==1) printf ("\n\nSDDECL:%s\n",yytext) ; return SDDECL;}

<INITIAL>"standalone"{egalevolue}\"[^"]*\"|"standalone"{egalevolue}\'[^']*\'|"standalone"{egalevolue}\"[^"]*\"|"standalone"{egalevolue}\'[^']*\'  {/* erreur de version encoding */ 	printf("\nerror : a la ligne %d : la version standalone n est pas reconnue : %s\n",yylineno,yytext); exit (7) ; }


<INITIAL>"?>"  {if (affichetrace==1) printf ("\n\nENDXMLDECL:%s\n",yytext) ; BEGIN(HORSBALISE);return ENDXMLDECL;}


<DANSBALISE,INITIAL,HORSBALISE>{S}   {if (affichetrace==1) printf ("\n\nS:'%s'\n",yytext) ; }


<HORSBALISE>"<?"[Xx][Mm][Ll]{S}({S}|{chardata})*"?>"|"<?"[Xx][Mm][Ll]"?>"	{if (affichetrace==1) printf ("\n\nPIERROR:%s\n",yytext) ; return PIERROR;}
<INITIAL,HORSBALISE>"<?"([^xX]|([xX][^mM])|([xX][mM][^lL]))({S}|([^?]|("?"[^>])))*"?>"		{attentionImpossibleDeTrouverPIapres=1 ;  if (affichetrace==1) printf ("\n\nPI:%s\n",yytext) ; return PI;}


<INITIAL,HORSBALISE>{newline}*"<"		    {if (affichetrace==1) printf ("\n\nINFCAR:%s\n",yytext) ; BEGIN(DANSBALISE);return INFCAR;}


<DANSBALISE>">"			{if (affichetrace==1) printf ("\n\nSUPCAR:%s\n",yytext) ; BEGIN(HORSBALISE);return SUPCAR;}


<DANSBALISE>"/"		{if (affichetrace==1) printf ("\n\nSLASH:%s\n",yytext) ; return SLASH;}


<DANSBALISE>{egalevolue}			{if (affichetrace==1) printf ("\n\nEq:'%s'\n",yytext) ; return Eq;}


<DANSBALISE>{Name}			{if (affichetrace==1) printf ("\n\nID:%s\n",yytext) ; crlval.s=strdup(yytext);return ID;}


<DANSBALISE>{attvalue}		{if (affichetrace==1) printf ("\n\nATTVALUE:%s\n",yytext) ; return ATTVALUE;}


<INITIAL,HORSBALISE>"<!--"([^-]|"-"[^-])*"-->"		{attentionImpossibleDeTrouverXMLDeclapres=1; }


<INITIAL,DANSBALISE,HORSBALISE>.|\n	{if (affichetrace==1)printf("error : ligne %d : caractere non reconnu '%s'\n",yylineno,yytext); }

%%


int yywrap()
{return 1;}