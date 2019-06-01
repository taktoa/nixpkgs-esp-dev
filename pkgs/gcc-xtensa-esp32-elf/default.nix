{ stdenv, fetchurl, fetchFromGitHub, runCommand,
  crosstool-ng-xtensa, wget, which, autoconf, libtool, automake, texinfo,
  python27Packages, file
}:

let
  gmpTarball = fetchurl {
    url    = "https://gmplib.org/download/gmp/gmp-6.0.0a.tar.xz";
    sha256 = "0r5pp27cy7ch3dg5v0rsny8bib1zfvrza6027g2mp5f6v8pd6mli";
  };
  mpfrTarball = fetchurl {
    url    = "https://ftp.gnu.org/gnu/mpfr/mpfr-3.1.3.tar.xz";
    sha256 = "05jaa5z78lvrayld09nyr0v27c1m5dm9l7kr85v2bj4jv65s0db8";
  };
  islTarball = fetchurl {
    url    = "http://isl.gforge.inria.fr/isl-0.14.tar.xz";
    sha256 = "00zz0dcxvbna2fqqqv37sqlkqpffb2js47q7qy7p184xh414y15i";
  };
  mpcTarball = fetchurl {
    url    = "https://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz";
    sha256 = "1hzci2zrrd7v3g1jk35qindq05hbl0bhjcyyisq9z209xb3fqzb1";
  };
  expatTarball = fetchurl {
    url    = "https://github.com/libexpat/libexpat/releases/download/R_2_1_0/expat-2.1.0.tar.gz";
    sha256 = "11pblz61zyxh68s5pdcbhc30ha1b2vfjd83aiwfg4vc15x3hadw2";
  };
  ncursesTarball = fetchurl {
    url    = "https://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.0.tar.gz";
    sha256 = "0q3jck7lna77z5r42f13c4xglc7azd19pxfrjrpgp2yf615w4lgm";
  };
  binutilsTarball = fetchurl {
    url    = "https://ftp.gnu.org/gnu/binutils/binutils-2.25.1.tar.gz";
    sha256 = "1z335dm8pv33ildpnik35q7xi8bmcj28fzmc6v5zl4isn4vhm942";
  };
  gccTarball = fetchurl {
    url    = "https://ftp.gnu.org/gnu/gcc/gcc-5.2.0/gcc-5.2.0.tar.gz";
    sha256 = "0sipsqll3z06bd84mrhygij8c5al05rc6s0hnyv2dvpbvsrz3ww7";
  };
  newlibTarball = fetchurl {
    url    = "ftp://sourceware.org/pub/newlib/newlib-2.2.0.tar.gz";
    sha256 = "1gimncxzq663l4gp8zd89ynfzhk2q802mcaiyjpr2xbkn1ix5bgq";
  };
  gdbTarball = fetchurl {
    url    = "https://ftp.gnu.org/pub/gnu/gdb/gdb-7.10.tar.xz";
    sha256 = "1a08c9svaihqmz2mm44il1gwa810gmwkckns8b0y0v3qz52amgby";
  };

  tarballs = runCommand "tarballs" {} ''
    mkdir -pv "$out"
    cp -v ${gmpTarball}        "$out/gmp-6.0.0a.tar.xz"
    cp -v ${mpfrTarball}       "$out/mpfr-3.1.3.tar.xz"
    cp -v ${islTarball}        "$out/isl-0.14.tar.xz"
    cp -v ${mpcTarball}        "$out/mpc-1.0.3.tar.gz"
    cp -v ${expatTarball}      "$out/expat-2.1.0.tar.gz"
    cp -v ${ncursesTarball}    "$out/ncurses-6.0.tar.gz"
    cp -v ${binutilsTarball}   "$out/binutils-2.25.1.tar.gz"
    cp -v ${gccTarball}        "$out/gcc-5.2.0.tar.gz"
    cp -v ${newlibTarball}     "$out/newlib-2.2.0.tar.gz"
    cp -v ${gdbTarball}        "$out/gdb-7.10.tar.xz"
  '';
in

stdenv.mkDerivation rec {
  name = "gcc-${targetTriple}";
  targetTriple = "xtensa-esp32-elf";

  nativeBuildInputs = [
    autoconf
    libtool
    automake
    wget
    which
    texinfo
    python27Packages.python
    file
    crosstool-ng-xtensa
  ];

  phases = [ "configurePhase" "buildPhase" ];

  # https://github.com/jcmvbkbc/crosstool-NG/issues/48
  hardeningDisable = [ "format" ];

  configurePhase = ''
    ${crosstool-ng-xtensa}/bin/ct-ng ${targetTriple}

    # Put toolchain in $out.
    sed -r -i.org "s%CT_PREFIX_DIR=.*%CT_PREFIX_DIR=\"$out\"%" .config

    # Increase the verbosity of crosstool-NG.
    sed -r -i.org "s%CT_LOG_LEVEL_MAX=.*%CT_LOG_LEVEL_MAX=ALL%" .config
    sed -r -i.org "s%CT_LOG_PROGRESS_BAR=.*%CT_LOG_PROGRESS_BAR=n%" .config
    sed -r -i.org "s%# CT_LOG_ALL is not set%CT_LOG_ALL=y%" .config
    sed -r -i.org "s%# CT_LOG_EXTRA is not set%CT_LOG_EXTRA=y%" .config

    sed -r -i.org "s%CT_LOCAL_TARBALLS_DIR=.*%CT_LOCAL_TARBALLS_DIR=${tarballs}%" .config
  '';

  buildPhase = ''
    ${crosstool-ng-xtensa}/bin/ct-ng build
  '';
}
