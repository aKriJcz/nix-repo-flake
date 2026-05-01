# pkgs/perl/default.nix
# Collects all per-file Perl package extension functions into a list.
# Add a new line here whenever you add a new .nix file above.
[
  (import ./extension.nix)
  # (import ./SomeOtherGroup.nix { })
]
