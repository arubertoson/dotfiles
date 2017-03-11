;;; packages.el --- clang-tools layer packages file for Spacemacs.
;;
;; Copyright (c) 2012-2016 Sylvain Benner & Contributors
;;
;; Author:  <Macke@DESKTOP-JABLQRF>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

;;; Commentary:

;; See the Spacemacs documentation and FAQs for instructions on how to implement
;; a new layer:
;;
;;   SPC h SPC layers RET
;;
;;
;; Briefly, each package to be installed or configured by this layer should be
;; added to `clang-tools-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `clang-tools/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `clang-tools/pre-init-PACKAGE' and/or
;;   `clang-tools/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(setq clang-tools-packages
  '(
    clang-format
    (clang-rename :location local)
  ))

(defun clang-tools/init-clang-rename ()
  (use-package clang-rename
    :if c-c++-enable-clang-support))

(defun clang-tools/post-init-clang-rename ()
  (spacemacs/set-leader-keys-for-major-mode 'c++-mode
    "cr" 'clang-rename))


(defun clang-tools/post-init-clang-format ()
  (spacemacs/set-leader-keys-for-major-mode 'c++-mode
    "cf" 'clang-format
    "cF" 'clang-format-buffer))


;;; packages.el ends here
