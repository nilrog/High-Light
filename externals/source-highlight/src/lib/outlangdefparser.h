/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton interface for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     BEGIN_T = 258,
     END_T = 259,
     DOC_TEMPLATE_T = 260,
     STYLE_TEMPLATE_T = 261,
     STYLE_SEPARATOR_T = 262,
     BOLD_T = 263,
     ITALICS_T = 264,
     UNDERLINE_T = 265,
     COLOR_T = 266,
     BG_COLOR_T = 267,
     FIXED_T = 268,
     NOTFIXED_T = 269,
     COLORMAP_T = 270,
     DEFAULT_T = 271,
     ONESTYLE_T = 272,
     TRANSLATIONS_T = 273,
     EXTENSION_T = 274,
     ANCHOR_T = 275,
     REFERENCE_T = 276,
     INLINE_REFERENCE_T = 277,
     POSTLINE_REFERENCE_T = 278,
     POSTDOC_REFERENCE_T = 279,
     KEY = 280,
     STRINGDEF = 281,
     REGEXDEF = 282,
     LINE_PREFIX_T = 283
   };
#endif
/* Tokens.  */
#define BEGIN_T 258
#define END_T 259
#define DOC_TEMPLATE_T 260
#define STYLE_TEMPLATE_T 261
#define STYLE_SEPARATOR_T 262
#define BOLD_T 263
#define ITALICS_T 264
#define UNDERLINE_T 265
#define COLOR_T 266
#define BG_COLOR_T 267
#define FIXED_T 268
#define NOTFIXED_T 269
#define COLORMAP_T 270
#define DEFAULT_T 271
#define ONESTYLE_T 272
#define TRANSLATIONS_T 273
#define EXTENSION_T 274
#define ANCHOR_T 275
#define REFERENCE_T 276
#define INLINE_REFERENCE_T 277
#define POSTLINE_REFERENCE_T 278
#define POSTDOC_REFERENCE_T 279
#define KEY 280
#define STRINGDEF 281
#define REGEXDEF 282
#define LINE_PREFIX_T 283




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
#line 49 "./outlangdefparser.yy"
{
  int tok ; /* command */
  bool booloption ;
  const std::string * string ; /* string : id, ... */
  int flag ;
}
/* Line 1489 of yacc.c.  */
#line 112 "outlangdefparser.h"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif

extern YYSTYPE outlangdef_lval;

