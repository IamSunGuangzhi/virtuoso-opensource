#!/bin/sh
#
#  This file is part of the OpenLink Software Virtuoso Open-Source (VOS)
#  project.
#
#  Copyright (C) 1998-2006 OpenLink Software
#
#  This project is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation; only version 2 of the License, dated June 1991.
#
#  This program is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
#  General Public License for more details.
#
#  You should have received a copy of the GNU General Public License along
#  with this program; if not, write to the Free Software Foundation, Inc.,
#  51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
#
#

list=$1

[ -z "$list" ] && list="default.h"
outname=`echo "$list" | sed 's/.h//g'`
[ -d tmp ] || mkdir tmp
rm -f tmp/*
importh="import_$outname.h"
exportc="export_$outname.c"
importc="import_$outname.c"
rm -f "$importh" "$exportc" "$importc"

#Thus should work but of course it fails with Virtuoso's headers because they're too dirty.
#grep '^#include[[:space:]]*"[[:alnum:]./_-]*"' < $list > tmp/includes_raw.txt
#sort -u < tmp/includes_raw.txt > tmp/includes.txt

#this does not work on Solaris:
#grep '^#include[[:space:]]*"[[:alnum:]./_-]*"' < $list > tmp/includes.txt
grep '^#include[ \t]*"[A-Za-z0-9./_-]*"' < $list > tmp/includes.txt


cat << "EOD" > tmp/process.sh
gen_gate_4_file()
{
  grep 'EXE_EXPORT' < "$1" >> tmp/exports.txt
}

EOD
#this does not work on Solaris:
#sed 's/^#include\([[:space:]]*\)"\([[:alnum:]./_-]*\)"/gen_gate_4_file \2 #/g' < tmp/includes.txt >> tmp/process.sh
sed 's/^#include\([ \t]*\)"\([A-Za-z0-9./_-]*\)"/gen_gate_4_file \2 #/g' < tmp/includes.txt >> tmp/process.sh

chmod a+x tmp/process.sh
tmp/process.sh

#this does not work on Solaris:
#grep '^[[:space:]]*EXE_EXPORT[[:space:]]*([^,)]*,[[:space:]]*[[:alpha:]][[:alnum:]_]*[[:space:]]*,' < tmp/exports.txt > tmp/decls.txt
grep '^[ \t]*EXE_EXPORT[ \t]*([^,)]*,[ ]*[A-Za-z][A-Za-z0-9_]*[ \t]*,' < tmp/exports.txt > tmp/decls.txt

#this does not work on Solaris:
##       \(1-----------\)          \(2-----------\) \(3-----\) \(4-----------\)\(5-----------------------\)\(7-----------\) \(8-\)
#sed 's/^\([[:space:]]*\)EXE_EXPORT\([[:space:]]*\)(\([^,)]*\),\([[:space:]]*\)\([[:alpha:]][[:alnum:]_]*\)\([[:space:]]*\),\(.*\)$/\5@typeof__\5/g' < tmp/decls.txt > tmp/export_names_raw.txt
#       \(1-------\)          \(2-----\) \(3-----\) \(4-----\)\(5--------------------\)\(7-----\) \(8-\)
sed 's/^\([ \t]*\)EXE_EXPORT\([ \t]*\)(\([^,)]*\),\([ ]*\)\([A-Za-z][A-Za-z0-9_]*\)\([ \t]*\),\(.*\)$/\5@typeof__\5/g' < tmp/decls.txt > tmp/export_names_raw.txt

#this does not work on Solaris:
#grep '^[[:space:]]*EXE_EXPORT_TYPED[[:space:]]*([[:space:]]*[[:alpha:]][[:alnum:]_]*[[:space:]]*,[[:space:]]*[[:alpha:]][[:alnum:]_]*[[:space:]]*)' < tmp/exports.txt > tmp/decls_t.txt
grep '^[ \t]*EXE_EXPORT_TYPED[ \t]*([ ]*[A-Za-z][A-Za-z0-9_]*[ \t]*,[ ]*[A-Za-z][A-Za-z0-9_]*[ \t]*)' < tmp/exports.txt > tmp/decls_t.txt

#this does not work on Solaris:
##       \(1-----------\)                \(2-----------\) \(3-----------\)\(4-----------------------\)\(5-----------\) \(6-----------\)\(7-----------------------\)\(8-----------\) \(9-\)
#sed 's/^\([[:space:]]*\)EXE_EXPORT_TYPED\([[:space:]]*\)(\([[:space:]]*\)\([[:alpha:]][[:alnum:]_]*\)\([[:space:]]*\),\([[:space:]]*\)\([[:alpha:]][[:alnum:]_]*\)\([[:space:]]*\))\(.*\)$/\7@\4/g' < tmp/decls_t.txt >> tmp/export_names_raw.txt
#       \(1-----\)                \(2-----\) \(3-----\)\(4--------------------\)\(5-----\) \(6-----\)\(7--------------------\)\(8-----\) \(9-\)
sed 's/^\([ \t]*\)EXE_EXPORT_TYPED\([ \t]*\)(\([ ]*\)\([A-Za-z][A-Za-z0-9_]*\)\([ \t]*\),\([ ]*\)\([A-Za-z][A-Za-z0-9_]*\)\([ \t]*\))\(.*\)$/\7@\4/g' < tmp/decls_t.txt >> tmp/export_names_raw.txt

sort -u < tmp/export_names_raw.txt > tmp/export_names.txt


sed 's/^\(.*\)$/#define \1 (_gate._\1._ptr)/g' < tmp/export_names.txt > tmp/gate_use.txt
sed 's/^\(.*\)$/  struct { typeof__\1 *_ptr; const char *_name; } _\1;/g' < tmp/export_names.txt > tmp/gate_decl.txt
sed 's/^\(.*\)$/  { NULL, "\1" },/g' < tmp/export_names.txt > tmp/gate_idef.txt
sed 's/^\(.*\)$/  { \&\1, "\1" },/g' < tmp/export_names.txt > tmp/gate_edef.txt

sed 's/^\([^@]*\)@\(.*\)$/#define \1 (_gate._\1._ptr)/g' < tmp/export_names.txt > tmp/gate_use.txt
sed 's/^\([^@]*\)@\(.*\)$/  struct { \2 *_ptr; const char *_name; } _\1;/g' < tmp/export_names.txt > tmp/gate_decl.txt
sed 's/^\([^@]*\)@\(.*\)$/  { NULL, "\1" },/g' < tmp/export_names.txt > tmp/gate_idef.txt
sed 's/^\([^@]*\)@\(.*\)$/  { \&\1, "\1" },/g' < tmp/export_names.txt > tmp/gate_edef.txt

# Header for import of gated functions
cat << "EOD" > $importh
#ifndef __gate_import_h_
#define __gate_import_h_
/* This file created automatically by plugin/gen_gate.sh */

/* First we should include all imported header files to define data types of
   arguments and return values */
EOD

cat < tmp/includes.txt >> $importh

cat << "EOD" >> $importh

/* Now we should declare dictionary structure with one member per one imported
   function. At connection time, executable will fill an instance of this
   structure with actual pointers to functions. */
struct _gate_s {
EOD

cat < tmp/gate_decl.txt >> $importh

cat << "EOD" >> $importh
  struct { void *_ptr; const char *_name; } _gate_end;
  };

/* Only one instance of _gate_s will exist, and macro definitions will be used
   to access functions of main executable via members of this instance. */
extern struct _gate_s _gate;

EOD

cat < tmp/gate_use.txt >> $importh

cat << "EOD" >> $importh

#endif
EOD

# Code for import of gated functions
echo '/* This file created automatically by plugin/gen_gate.sh */' > $importc
echo "#include <stdlib.h>" >> $importc
echo "#include \"$importh\"" >> $importc
echo 'struct _gate_s _gate = {' >> $importc
cat < tmp/gate_idef.txt >> $importc
echo '  { NULL, "." } };' >> $importc

# Code for export of gated functions
cat << "EOD" > $exportc
/* This file created automatically by plugin/gen_gate.sh */
#define EXPORT_GATE
#include "exe_export.h"
#include <string.h>

/* First we should include all imported header files to declare names of
   all exported functions */
EOD

cat < tmp/includes.txt >> $exportc

cat << "EOD" >> $exportc

/* Now we should declare dictionary array with one item per one exported
   function. At connection time, executable will fill _gate structures
   of plugins with data from this table. */

struct _gate_export_item_s { void *_ptr; const char *_name; };
typedef struct _gate_export_item_s _gate_export_item_t;

extern _gate_export_item_t _gate_export_data[];

int _gate_export (_gate_export_item_t *tgt)
{
  int err = 0;
  _gate_export_item_t *src = _gate_export_data;
  for (/* no init */; '.' != tgt->_name[0]; tgt++)
    {
      err = -1;
      for (/* no init */; '.' != src->_name[0]; src++)
	{
	  if (strcmp (src->_name, tgt->_name))
	    continue;
	  tgt->_ptr = src->_ptr;
	  err = 0;
	  break;
	}
      if (err)
        break;
    }
  return err;
}

_gate_export_item_t _gate_export_data[] = {
EOD

cat < tmp/gate_edef.txt >> $exportc
echo '  { NULL, "." } };' >> $exportc
