# SWIG bindings for DyNet

The code in `dynet_swig.i` provides SWIG instructions to wrap salient parts of DyNet for use
in other languages, in particular Java (and Scala).

## Scala Helpers

The code in `src/main/scala` provides helper functions and implicit conversions that 
facilitate using DyNet from Scala.

## Building

To include in the DyNet build, add `-DINCLUDE_SWIG=ON` to the `cmake` command, e.g., run this from
the `build` directory (see [DyNet documentation](http://dynet.readthedocs.io/en/latest/install.html) for general build instructions):

```
build$ cmake .. -DEIGEN3_INCLUDE_DIR=../eigen -DINCLUDE_SWIG=ON
build$ make dynet_swig && make
```

In MacOS, this will create the library files `dynet_swigJNI.jar` and `libdynet_swig.jnilib` in the `build/swig` directory. 
It will then run `sbt assembly` to produce an "uberjar" containing 
both the Dynet bindings and the scala helpers, also in `build/swig`.

If you don't want the Scala helpers (and, in particular, if you
don't have `sbt`) then when you run `cmake` include the additional flag

```
-DINCLUDE_SCALA_HELPERS=OFF
```

If successful, the end of the build should look something like:

```
[ 93%] Building Java objects for dynet_swigJNI.jar
[ 94%] Generating CMakeFiles/dynet_swigJNI.dir/java_class_filelist
[ 95%] Creating Java archive dynet_swigJNI.jar
[ 95%] Built target dynet_swigJNI
[ 96%] Running sbt
...
[info] lots of sbt stuff here
...
[success] Total time: 7 s, completed Jan 11, 2017 1:05:58 PM
[ 96%] Built target scala_helper
[100%] Built target dynet_swig
```

## Running the example

After running `make`, you can run the Scala examples under the `swig` directory with `sbt`:

```
swig$ sbt "runMain edu.cmu.dynet.examples.XorScala" -Dbuildpath=../build/swig
swig$ sbt "runMain edu.cmu.dynet.examples.LinearRegression" -Dbuildpath=../build/swig
```

The Java example takes a couple more steps:

```
swig$ javac -d . -cp ../build/swig/dynet_swigJNI.jar src/main/java/edu/cmu/dynet/examples/XorExample.java
swig$ java -cp .:../build/swig/dynet_swigJNI.jar -Djava.library.path=../build/swig edu.cmu.dynet.examples.XorExample
Running XOR example
[dynet] random seed: 1650744221
[dynet] allocating memory: 512MB
[dynet] memory allocation done.
Dynet initialized!

Computation graphviz structure:
digraph G {
  rankdir=LR;
  nodesep=.05;
  N0 [label="v0 = parameters({8,2}) @ 0x7ff1da8000e0"];
  N1 [label="v1 = parameters({8}) @ 0x7ff1da800260"];
  N2 [label="v2 = parameters({1,8}) @ 0x7ff1da800380"];
  N3 [label="v3 = parameters({1}) @ 0x7ff1da8004f0"];
  N4 [label="v4 = constant({2})"];
  N5 [label="v5 = scalar_constant(0x7ff1d8f12ce8)"];
  N6 [label="v6 = v0 * v4"];
  N0 -> N6;
  N4 -> N6;
  N7 [label="v7 = v6 + v1"];
  N6 -> N7;
  N1 -> N7;
  N8 [label="v8 = tanh(v7)"];
  N7 -> N8;
  N9 [label="v9 = v2 * v8"];
  N2 -> N9;
  N8 -> N9;
  N10 [label="v10 = v9 + v3"];
  N9 -> N10;
  N3 -> N10;
  N11 [label="v11 = || v10 - v5 ||^2"];
  N10 -> N11;
  N5 -> N11;
}

Training...
iter = 0, loss = 0.6974922
iter = 1, loss = 1.4101544E-4
iter = 2, loss = 2.1905963E-8
iter = 3, loss = 3.2875924E-12
iter = 4, loss = 2.220446E-15
iter = 5, loss = 8.881784E-16
iter = 6, loss = 8.881784E-16
iter = 7, loss = 8.881784E-16
iter = 8, loss = 8.881784E-16
iter = 9, loss = 8.881784E-16
iter = 10, loss = 8.881784E-16
iter = 11, loss = 8.881784E-16
iter = 12, loss = 8.881784E-16
iter = 13, loss = 8.881784E-16
iter = 14, loss = 8.881784E-16
iter = 15, loss = 8.881784E-16
iter = 16, loss = 8.881784E-16
iter = 17, loss = 8.881784E-16
iter = 18, loss = 8.881784E-16
iter = 19, loss = 8.881784E-16
iter = 20, loss = 8.881784E-16
iter = 21, loss = 8.881784E-16
iter = 22, loss = 8.881784E-16
iter = 23, loss = 8.881784E-16
iter = 24, loss = 8.881784E-16
iter = 25, loss = 8.881784E-16
iter = 26, loss = 8.881784E-16
iter = 27, loss = 8.881784E-16
iter = 28, loss = 8.881784E-16
iter = 29, loss = 8.881784E-16
```
