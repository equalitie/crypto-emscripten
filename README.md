gcrypt and otr in javascript
===================================================

A build script to compile [GNU Libgcrypt][1] and [Off-the-Record Messaging][2], and [eQ (n+1)sec][3] library using the awsome [Emscripten][4] cross-compiler.

[1]: http://www.gnu.org/software/libgcrypt/ "gcrypt"
[2]: http://www.cypherpunks.ca/otr/ "OTR"
[3]: https://github.com/equalitie/np1sec
[3]: http://emscripten.org "Emscripten"

### Building the libraries
[Setup Emscripten](http://kripken.github.io/emscripten-site/docs/getting_started/Tutorial.html) on your system. 

Run the build script (it will try to find emscripten in the following locations; *path specified on the command line*, *EMSCRIPTEN_ROOT* environment variable, and finally in from the config file *~/.emscripten*.)
This will configure and compile the libraries into llvm bitcode.

      ./build-libs.sh "/path/to/emscripten"

We can now compile C code that links to these libraries into javascript.

      make libotr-test
      node tests/libotr-test

run a libgcrypt test:
   
      make test run-test

To build and run all the libgcrypt tests:

      make test-all run-test-all

To run the benchmark

      make benchmark.js
      node tests/benchmark.js

See Also

- *[OTR4-em][4]* Off the Record Messaging npm module.
- *[otrTalk][5]* P2P Off the Record chat application.

[4]: https://github.com/mnaamani/otr4-em
[5]: https://github.com/mnaamani/node-otr-talk

