let
  lock = builtins.fromJSON (builtins.readFile ../flake.lock);
in
  {
    name,
    sources ? {},
  }: {pkgs}:
    pkgs.satyxin.buildPackage {
      inherit name sources;
      src = with lock.nodes."satysfi-${name}".locked;
        pkgs.fetchFromGitHub {
          inherit owner repo rev;
          sha256 = narHash;
        };
    }
