#!/usr/bin/env bash

BEGIN { cachyos = 0; cachyos_v3 = 0; cachyos_core_v3 = 0; cachyos_extra_v3 = 0; err = 1 }
{
  if ($0 == "[options]") {
    print;
    next;
  } else if ($0 == "[cachyos]") {
    cachyos = 1;
  } else if ($0 == "[cachyos-v3]") {
    cachyos_v3 = 1;
  } else if ($0 == "[cachyos-core-v3]") {
    cachyos_core_v3 = 1;
  } else if ($0 == "[cachyos-extra-v3]") {
    cachyos_extra_v3 = 1;
  } else if ($0 == "Architecture = x86_64" || $0 == "Architecture = x86_64 x86_64_v3" || $0 == "Architecture = x86_64 x86_64_v3 x86_64_v4") {
    print "Architecture = auto";
    next;
  }

  if (rm) {
    rm--;
    next;
  }
}

/^\[[^ \[\]]+\]/ {
  if (!cachyos) {
    print "[cachyos]";
    print "Include = /etc/pacman.d/cachyos-mirrorlist";
    print "";
    cachyos = 1;
    err = 0;
  }

  if (!cachyos_v3) {
    print "[cachyos-v3]";
    print "Include = /etc/pacman.d/cachyos-v3-mirrorlist";
    print "";
    cachyos_v3 = 1;
    err = 0;
  }

  if (!cachyos_core_v3) {
    print "[cachyos-core-v3]";
    print "Include = /etc/pacman.d/cachyos-v3-mirrorlist";
    print "";
    cachyos_core_v3 = 1;
    err = 0;
  }

  if (!cachyos_extra_v3) {
    print "[cachyos-extra-v3]";
    print "Include = /etc/pacman.d/cachyos-v3-mirrorlist";
    print "";
    cachyos_extra_v3 = 1;
    err = 0;
  }
}
END {exit err}
1

# vim:set sw=2 sts=2 et:
