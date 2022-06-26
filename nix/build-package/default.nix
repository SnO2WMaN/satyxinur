{pkgs}: {
  name,
  src,
  sources ? {},
  deps ? [],
}:
pkgs.stdenv.mkDerivation {
  inherit name src deps;
  sources = builtins.toJSON sources;

  dontBuild = true;

  installPhase = ''
    for dep in $(echo $deps | tr ' ' '\n'); do
      if [ -e $dep/lib/satysfi/dist/hash/default-font.satysfi-hash ] && [ ! -e $out/lib/satysfi/dist/hash/default-font.satysfi-hash ]; then
        mkdir -p $out/lib/satysfi/dist/hash
        cat $dep/lib/satysfi/dist/hash/default-font.satysfi-hash > $out/lib/satysfi/dist/hash/default-font.satysfi-hash
      fi

      if [ -e $dep/lib/satysfi/dist/hash/fonts.satysfi-hash ]; then
        mkdir -p $out/lib/satysfi/dist/hash
        target=$out/lib/satysfi/dist/hash/fonts.satysfi-hash
        [[ ! -e $target ]] && touch $target
        merge-hash $dep/lib/satysfi/dist/hash/fonts.satysfi-hash $target | sponge $target
      fi

      if [ -e $dep/lib/satysfi/dist/hash/mathfonts.satysfi-hash ]; then
        mkdir -p $out/lib/satysfi/dist/hash
        target=$out/lib/satysfi/dist/hash/mathfonts.satysfi-hash
        [[ ! -e $target ]] && touch $target
        merge-hash $dep/lib/satysfi/dist/hash/mathfonts.satysfi-hash $target | sponge $target
      fi

      if [ -d $dep/lib/satysfi/dist/fonts ]; then
        mkdir -p $out/lib/satysfi/dist/fonts
        for file in $(find $dep/lib/satysfi/dist/fonts -type f); do
          target=$out/$(realpath --relative-to=$dep $file)
          if [ ! -e $target ]; then
            mkdir -p $out/$(dirname $(realpath --relative-to=$dep $file))
            cp $file $target
          fi
        done
      fi

      if [ -d $dep/lib/satysfi/dist/unidata ]; then
        mkdir -p $out/lib/satysfi/dist/unidata
        for file in $(find $dep/lib/satysfi/dist/fonts -type f); do
          target=$out/$(realpath --relative-to=$dep $file)
          if [ ! -e $target ]; then
            mkdir -p $out/$(dirname $(realpath --relative-to=$dep $file))
            cp $file $target
          fi
        done
      fi

      if [ -d $dep/lib/satysfi/dist/packages ]; then
        mkdir -p $out/lib/satysfi/dist/packages
        for file in $(find $dep/lib/satysfi/dist/packages -type f); do
          target=$out/$(realpath --relative-to=$dep $file)
          if [ ! -e $target ]; then # TODO: if exists, compare
            mkdir -p $out/$(dirname $(realpath --relative-to=$dep $file))
            cp $file $target
          fi
        done
      fi
    done

    for i in $(seq 0 $(($(echo $sources | jq ".files | length") - 1))); do
        mkdir -p $out/lib/satysfi/dist/packages/$name/

        path=`echo $sources | jq -r ".files[$i]"`
        cp $src/$path $out/lib/satysfi/dist/packages/$name/$path
    done

    for i in $(seq 0 $(($(echo $sources | jq ".dirs | length") - 1))); do
        mkdir -p $out/lib/satysfi/dist/packages/$name/

        path=`echo $sources | jq -r ".dirs[$i]"`
        cp -r $src/$path/* $out/lib/satysfi/dist/packages/$name
    done
  '';
  setupHook = pkgs.writeText "setuphook-satysfi-package" ''
    SATYSFI_LIBPATH+=:$1/lib/satysfi
  '';
  buildInputs = with pkgs; [
    jq
    moreutils
    (writers.writePerlBin
      "merge-hash"
      {libraries = with pkgs.perlPackages; [ListMoreUtils];}
      (builtins.readFile ./merge-hash.pl))
  ];
}
