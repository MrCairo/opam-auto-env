;;; opam-auto-env.el --- Automatically find and use opam environment -*- lexical-binding: t -*-

;; Copyright (C) 2024 Mitch Fisher <MrCairo@committed-code.com>
;; Version: 0.0.1
;; Package-Requires: ((emacs "28.1") (tuareg "3.0.1"))
;; URL: https://github.com/MrCairo/opam-auto-env
;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;; 02110-1301, USA.

;;; Commentary:

;; opam-auto-env, by calling the function interactive function
;; `opam-auto-env-set`, will automatically setup the OPAM environment
;; variables. This is done only if a `_opam` or `.opam` sub-directory exists in
;; the current working directory. If one of the opam signature directories
;; exist, opam-auto-env will execute a shell command, "eval $(opam env)" and
;; then set the Emacs environment variables for OPAM accordingly. If neither of
;; the signature directorie exist, then the current OPAM environment (if there
;; is one) is left unchanged. The signature directories are searched in the
;; order they appear in the customizable list, `opam-auto-env-dirnames`.

;;; Code:

(defgroup opam-auto-env-mode nil
  "Autmatic switcher of opam environment."
  :prefix "opam-auto-env-"
  :group 'opam-auto-env)

(defcustom opam-auto-env-sig-dirnames
  (list "_opam" ".opam")
  "The signature directory names that OPAM can use to identify
it's environment."
  :type '(repeat string))

(defvar opam-auto-env-current nil
  "The current OPAM environment directory.")

(defun opam-auto-env--locate-env
  (base-directory dirname)
  "Search for a sub-directory name in the base directory.
If the sub-directory name is found, the full path to the base
Search for a venv that matches VENV-DIRNAME
from BASE-DIRECTORY.  The behavior is similar to
`locate-dominating-file'."
  (when-let ((parent-dir (locate-dominating-file base-directory dirname)))
    (expand-file-name
      (concat (file-name-as-directory parent-dir) dirname))))

(defun opam-auto-env--locate-envs
  (base-directory sig-dirnames)
  "Search for a venv directory from venv directories.
Search for VENV-DIRNAMES from BASE-DIRECTORY.
The behavior is similar to `locate-dominating-file'.
The priority is same as the order of VENV-DIRNMAES.
Return a path of the venv directory or nil."
  (seq-some #'identity
    (mapcar
      (lambda (dirname)
	(opam-auto-env--locate-env base-directory dirname))
      sig-dirnames)))

(defun opam-auto-env-set ()
  "Search for a venv directory and activate it."
  (interactive)
  (when-let* ((opam-env-dir (opam-auto-env--locate-envs
			      default-directory
			      opam-auto-env-sig-dirnames))
	       (match (not (equal opam-env-dir opam-auto-env-current))))
    (opam-auto-env--set-env opam-env-dir)))

(defun opam-auto-env--set-env (env-dir)
  "Set the Emacs environment variables based upon the returned $(opam env)."
  (setq opam-auto-env-curr-dir default-directory)
  (cd env-dir)
  (setq-default opam-auto-env-current env-dir)
  (let*
    ((all
       (shell-command-to-string
	 (format "eval $(opam env); echo -n \"%s|%s|%s|%s|%s\""
	   "${OPAM_SWITCH_PREFIX}"
	   "${CAML_LD_LIBRARY_PATH}"
	   "${OCAML_TOPLEVEL_PATH}"
	   "${OPAM_LAST_ENV}"
	   "${PATH}")))
      (env-list (split-string all "|"))
      (prefix (nth 0 env-list))
      (lib-path (nth 1 env-list))
      (toplevel (nth 2 env-list))
      (last-env (nth 3 env-list))
      (path (nth 4 env-list)))
    (setenv "OPAM_SWITCH_PREFIX" prefix)
    (setenv "CAML_LD_LIBRARY_PATH" lib-path)
    (setenv "OCAML_TOPLEVEL_PATH" toplevel)
    (setenv "PATH" path)
    (setenv "OPAM_LAST_ENV" last-env))
  (when-let* ( (dir-list (split-string (getenv "PATH") ":")))
    (setq-default exec-path dir-list))
  (cd opam-auto-env-curr-dir))

(provide 'opam-auto-env)
;;; opam-auto-env.el ends here
