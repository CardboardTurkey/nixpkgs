{ lib
, pkgs
, fetchFromGitHub
, fetchpatch
, nixosTests
, python3

, plugins ? ps: [] }:

let
  py = python3 // {
    pkgs = python3.pkgs.overrideScope (self: super: {
      django = super.django_4;
    });
  };

  extraBuildInputs = plugins py.pkgs;
in
py.pkgs.buildPythonApplication rec {
    pname = "netbox";
    version = "3.3.9";

    format = "other";

    src = fetchFromGitHub {
      owner = "netbox-community";
      repo = pname;
      rev = "refs/tags/v${version}";
      sha256 = "sha256-KhnxD5pjlEIgISl4RMbhLCDwgUDfGFRi88ZcP1ndMhI=";
    };

    patches = [
      # Allow setting the STATIC_ROOT from within the configuration and setting a custom redis URL
      ./config.patch
      ./graphql-3_2_0.patch
      # fix compatibility ith django 4.1
      (fetchpatch {
        url = "https://github.com/netbox-community/netbox/pull/10341/commits/ce6bf9e5c1bc08edc80f6ea1e55cf1318ae6e14b.patch";
        sha256 = "sha256-aCPQp6k7Zwga29euASAd+f13hIcZnIUu3RPAzNPqgxc=";
      })
    ];

    propagatedBuildInputs = with py.pkgs; [
      bleach
      django_4
      django-cors-headers
      django-debug-toolbar
      django-filter
      django-graphiql-debug-toolbar
      django-mptt
      django-pglocks
      django-prometheus
      django-redis
      django-rq
      django-tables2
      django-taggit
      django-timezone-field
      djangorestframework
      drf-yasg
      swagger-spec-validator # from drf-yasg[validation]
      graphene-django
      jinja2
      markdown
      markdown-include
      netaddr
      pillow
      psycopg2
      pyyaml
      sentry-sdk
      social-auth-core
      social-auth-app-django
      svgwrite
      tablib
      jsonschema
    ] ++ extraBuildInputs;

    buildInputs = with py.pkgs; [
      mkdocs-material
      mkdocs-material-extensions
      mkdocstrings
      mkdocstrings-python
    ];

    nativeBuildInputs = [
      py.pkgs.mkdocs
    ];

    postBuild = ''
      PYTHONPATH=$PYTHONPATH:netbox/
      python -m mkdocs build
    '';

    installPhase = ''
      mkdir -p $out/opt/netbox
      cp -r . $out/opt/netbox
      chmod +x $out/opt/netbox/netbox/manage.py
      makeWrapper $out/opt/netbox/netbox/manage.py $out/bin/netbox \
        --prefix PYTHONPATH : "$PYTHONPATH"
    '';

    passthru = {
      # PYTHONPATH of all dependencies used by the package
      pythonPath = python3.pkgs.makePythonPath propagatedBuildInputs;

      tests = {
        inherit (nixosTests) netbox;
      };
    };

    meta = with lib; {
      homepage = "https://github.com/netbox-community/netbox";
      description = "IP address management (IPAM) and data center infrastructure management (DCIM) tool";
      license = licenses.asl20;
      maintainers = with maintainers; [ n0emis raitobezarius ];
    };
  }
