;; packages.el --- writer layer packages file for Spacemacs.
;; Copyright (c) 2012-2016 Sylvain Benner & Contributors

;; Author:  <Macke@DESKTOP-JABLQRF>
;; URL: https://github.com/syl20bnr/spacemacs

;; This file is not part of GNU Emacs.

;; License: GPLv3

;; Commentary:

;; See the Spacemacs documentation and FAQs for instructions on how to implement
;; a new layer:

;;   SPC h SPC layers RET


;; Briefly, each package to be installed or configured by this layer should be
;; added to `writer-packages'. Then, for each package PACKAGE:

;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `writer/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `writer/pre-init-PACKAGE' and/or
;;   `writer/post-init-PACKAGE' to customize the package as it is loaded.

;; Code:
;; TODO: Toggle word wrap
;; TODO: Reinstall flyspell

(defconst writer-packages
  '(helm-dictionary
    writegood-mode
    hl-sentence
    flycheck

    highlight-indent-guides

    ;; flyspell ; redundant?

    ;; helm-bibtex
    ;; typo -> typography layer
    ;; diction

    ;; pandoc
    ;; org-mode
    ;; latex
    ))


;; TODO: This is not supposed to be in this layer
(defun writer/init-highlight-indent-guides ()
  (use-package highlight-indent-guides
    :defer t
    :init
    (add-hook 'prog-mode-hook 'highlight-indent-guides-mode)
    :config
    (setq-default highlight-indent-guides-method 'character
                  ;; tab chars | ┆ ┊
                  highlight-indent-guides-character ?\┊
                  highlight-indent-guides-auto-enabled nil)
    (set-face-foreground 'highlight-indent-guides-character-face "#2e2e3a")

    ;; Paren
    (setq-default show-paren-delay 0.1)
    (set-face-foreground 'show-paren-match "green")
    )
  )


;; TODO: Install 64 bit java
;; TODO: Ignore rules langtool (Create variable list)
;; TODO: markdown-mdl (must install ruby)
(defun writer/post-init-flycheck ()
  "TODO: Docstring"

    ;;
    ;; Grammar Linters
    ;;

    (flycheck-define-checker writer/proselint
        "A linter for prose.

        See url: url"
        :command ("proselint" source-inplace)
        :error-patterns
        ((warning line-start
                  (file-name) ":"
                  line ":"
                  column ": "
                  (id (one-or-more (not (any " "))))
                  (message)
                  line-end))
        :modes (text-mode markdown-mode gfm-mode)
      )

    (flycheck-define-checker writer/langtool
      "A Grammar checker for various languages

      See url: url"
      :command ("java"
                "-d64"
                "-jar"
                ;; "-Xmx400" ;; NOTE: Turn on this if out of memory crashes occur
                "c:/tools/global/cmder/vendor/LanguageTool/languagetool-commandline.jar"
                ;; (option "-l" flycheck-langtool-current-language)
                source)
      :error-parser flycheck-parse-langtool
      :modes (text-mode markdown-mode gfm-mode)
      :next-checkers ((warning . writer/proselint))
      )

    ;; Add new checkers to flychekcers
    (dolist (item '(writer/proselint writer/langtool))
      (add-to-list 'flycheck-checkers item))

    ;; Add modes to flycheck global mode and set local settings
    (dolist (mode '(text-mode markdown-mode gfm-mode))
      (spacemacs/add-flycheck-hook mode)
      (add-hook (intern (format "%s-hook" (symbol-name mode)))
                ;; the langtool checker is slow, so we don't want it to run
                ;; automatically, the popup message is quite verbose and might
                ;; need some extra time on screen. This is all experimental
                ;; still and will probably change after usage.
                (lambda ()
                  (setq flycheck-checker 'writer/langtool
                        flycheck-check-syntax-automatically '(save
                                                              idle-change
                                                              mode-enable)
                        flycheck-idle-change-delay 2.5
                        flycheck-pos-tip-timeout 10)))
      )
    )



;; TODO: highlight
;; If in comment block don't hl
(defun writer/init-hl-sentence ()
  (use-package hl-sentence
    :config
    (set-face-attribute 'hl-sentence-face nil
                        :foreground "white")
    (add-hook 'text-mode-hook #'hl-sentence-mode)
    (add-hook 'markdown-mode-hook #'hl-sentence-mode)))


;; TODO: implement change database function
(defun writer/init-helm-dictionary ()
  (use-package helm-dictionary
    :init
    (setq-default helm-dictionary-database
                  (concat (configuration-layer/get-layer-path 'writer)
                          "local/de-en.txt"))))

;; TODO: No error message, only visible queues.
(defun writer/init-writegood-mode ()
  (use-package writegood-mode
    :defer t
    :init
    (add-hook 'markdown-mode-hook #'writegood-mode)
    (add-hook 'text-mode-hook #'writegood-mode)
    ))

;; TODO: Add flyspell back
;; TODO: Add idle timer to rerun checker async
;; TODO: No spellcheck should be perfomred by flyspell (Disable rules ID)
;; TODO: flyspell-prog-mode, take inspiration to get langtool to check only commnents.
;; (defun writer/init-langtool ()
;;   (use-package langtool
;;     :init
;;     (setq-default langtool-language-tool-jar "c:/tools/global/cmder/vendor/LanguageTool/languagetool-commandline.jar")
;;     :config
;;     (setq langtool-autoshow-message-function 'langtool-autoshow-detail-popup
;;           langtool-autoshow-idle-delay 0.5))
;;   )

;; TODO: flyspell is inconsistent
;; TODO: fix formatting
;; (defun writer/post-init-flyspell ()
;;   (add-to-list 'exec-path "c:/Program Files (x86)/Aspell/bin")
;;   (setq ispell-program-name "aspell")
;;   (setq ispell-personal-dictionary "c:/Program Files (x86)/Aspell/dict")
;;   (setq flyspell-issue-message-flag nil)
;;   )
;;; packages.el ends here
