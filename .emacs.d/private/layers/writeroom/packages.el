;;; packages.el --- Writeroom Layer packages File for Spacemacs
;;
;; Copyright (c) 2015 fmdkdd
;;
;; Author: fmdkdd
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

;; List of all packages to install and/or initialize. Built-in packages
;; which require an initialization must be listed explicitly in the list.
(setq writeroom-packages
      '(writeroom-mode))

(defun writeroom/init-writeroom-mode ()
  (use-package writeroom-mode
    ;; :commands (writeroom-mode)
    :init
    (evil-leader/set-key "Tw" 'writeroom-mode)
    :config
    (setq writeroom-restore-window-config t
          writeroom-mode-line t
          writeroom-fringes-outside-margins t
          writeroom-extra-line-spacing .25
          writeroom-global-effects '(writeroom-set-alpha
                                     writeroom-set-menu-bar-lines
                                     ;; writeroom-set-sticky
                                     writeroom-set-tool-bar-lines
                                     writeroom-set-vertical-scroll-bars
                                     )))
    )
