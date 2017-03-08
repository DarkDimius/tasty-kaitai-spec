This repo contains a specification of TASTY that can be used to generate TASTY parsers for multiple programming languages, including 
C++, Python, Ruby, Java, Javascript, PHP, Perl, etc...
It's based on Kaitai struct http://kaitai.io/ , see there for a full list of languages.

Provided are two parsers: tasty_eager and tasty_lazy.
The first one parses the entire tasty file at once.
Second is better used if you only need to read small part of TASTY(e.g. top level signatures).

You can see it in practive without compiling at kaitai web ide: https://kt.pe/kaitai_struct_webide/
After upploading a TASTY file and a ksy-file you should be able to navigate it in the UI.
