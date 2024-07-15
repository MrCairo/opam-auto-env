# opam-auto-env

## Abstract
opam-auto-env will set the OPAM environment variables as if `eval $(opam env)` is called - which, in fact, it is called
if an opam directory named `_opam` or `.opam` is found withing the current directory or within it's parent directories.
If one is found, then the `opam env` command is called via the Emacs `shell-command-to-string` function. If none are
found, then the existing `opam` environment (if one existed) is left unchanged.

The resulting environment variables returned from `opam env` are then set into the current Emacs session, including the
PATH, which is copied over to the `exec-path` list. This is important to note since anything custom in the `exec-path`
list that wasn't already in the current shell's path, will be lost.

## Installation and Usage
You can enable opam-auto-env below.

If installing via `elpaca`:
```
(use-package opam-auto-mode
  :ensure (:host github :repo "MrCairo/opam-auto-env"))
```

Standard installation:

```
(use-package opam-auto-mode
  :ensure t
  :hook
  ((tuareg-mode . opam-auto-env-set)
    (dune-mode . opam-auto-env-set)))
```

To get fancy, you could also download and install `opam` if it isn't already installed using the
`:ensure-system-package` option.

```
(let
  ((installer "bash -c \"sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh) --version 2.2.0\""))
  (use-package opam-auto-mode
    :ensure t
    :ensure-system-package (opam . installer)))
```

Using any of the configurations above, when a file is opened in the `dune-mode` or `tuareg-mode` to become active, the
`opam` environment in Emacs will also be automatically updated. It is also possible to manually run the interactive
`opam-auto-env-set` function and it will search and possibly set the `opam` environment based upon the current buffer's
directory (not necessarily the file loaded).

The default `opam` signature directory names searched for are located in the customizable variable list 
`opam-auto-env-sig-dirnames`. The directories are searched for in the order they appear in this list.

The current operating `opam` environment directory can be found by either inspecting the `OPAM_SWITCH_PREFIX`
environment variable or by inspecting the package `opam-auto-env-current` variable.
