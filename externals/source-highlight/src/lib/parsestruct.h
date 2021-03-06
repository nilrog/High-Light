//
// C++ Interface: parsestruct
//
// Description: 
//
//
// Author: Lorenzo Bettini <http://www.lorenzobettini.it>, (C) 2004
//
// Copyright: See COPYING file that comes with this distribution
//
//

#ifndef PARSESTRUCT_H
#define PARSESTRUCT_H

#include <string>

struct ParseStruct
{
  const std::string path;
  const std::string file_name;
  unsigned int line;
  unsigned int pos;
  
  ParseStruct(const std::string &pa, const std::string &name) : 
      path(pa), file_name(name), line(1), pos(0) {}
};

#endif // PARSESTRUCT_H
