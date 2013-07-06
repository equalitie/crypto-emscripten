gcrypt and otr in javascript
===================================================

A build script to compile [GNU Libgcrypt][1] and [Off-the-Record Messaging][2] using the awsome [Emscripten][3] cross-compiler.

[1]: http://www.gnu.org/software/libgcrypt/ "gcrypt"
[2]: http://www.cypherpunks.ca/otr/ "OTR"
[3]: http://emscripten.org "Emscripten"


#### PublicKey crypto boosters

The most compute intensive of libgcrypt's *mpi* functions are overidden with a javascript implementation using [bigint.js][4] for a significant performance boost of the public key crypto.
*   _gcry_mpi_mod
*   _gcry_mpi_powm
*   _gcry_mpi_invm
*   _gcry_mpi_mulpowm

#### A cryptographically secure pseudo-random number generator (CSPRNG)

The */dev/random* and */dev/urandom* virtual devices provide a stream of random bytes from generated using salsa20 seeded from crypto.getRandomValues(), based off Arlo's [OTR javascript library][5]
[4]: http://leemon.com/crypto/BigInt.html "BigInt"
[5]: https://github.com/arlolra/otr "OTR"

#### Building
[Setup Emscripten](https://github.com/kripken/emscripten/wiki/Tutorial) on your system. 

Run the build script (it will try to find emscripten in the following locations; *path specified on the command line*, *EMSCRIPTEN_ROOT* environment variable, and finally in from the config file *~/.emscripten*.)
This will configure and compile the libraries into llvm bitcode.

      ./build-libs.sh "/path/to/emscripten"

We can now compile C code that links to these libraries into javascript.

      make libotr-test
      node tests/libotr-test

To build the libgcrypt tests:

      make tests-fastmpi

run a libgcrypt test:
   
      node tests/basic-fast.js --verbose

See Also

- *[OTR4-em][7]* Off the Record Messaging npm module.
- *[otrTalk][8]* P2P Off the Record chat application.

[7]: https://github.com/mnaamani/otr4-em
[8]: https://github.com/mnaamani/node-otr-talk

