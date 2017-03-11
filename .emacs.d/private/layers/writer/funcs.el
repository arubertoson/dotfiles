(defconst langtool-output-regexp
  (eval-when-compile
    (concat
     "^[0-9]+\\.) Line \\([0-9]+\\), column \\([0-9]+\\), Rule ID: \\(.*\\)\n"
     "Message: \\(.*\\)\n"
     "\\(?:Suggestion:\\(.*\\)\n\\)?"
     ;; As long as i can read
     ;; src/dev/de/danielnaber/languagetool/dev/wikipedia/OutputDumpHandler.java
     "\\(\\(?:.*\\)\n\\(?:[ ^]+\\)\\)\n"
     "\n?"                              ; last result have no new-line
     )))

(defun assoc-recursive (alist &rest keys)
  "Recursively find KEYs in ALIST."
  (while keys
    (setq alist (cdr (assoc (pop keys) alist))))
  alist)

;; Guard
(when (configuration-layer/package-usedp 'flycheck)


  (defun flycheck-parse-langtool (output checker buffer)

    "Parse the langtool output for necessary data."
    (setq flycheck-langtool-fixes nil)

    (let (last-match filename errors)
      (setq last-match 0)

      ;; Get filename string initially as it is only visible at the top
      (string-match "Working on \\(.*\\)...\n" output 0)
      (setq filename (match-string 1 output))

      ;; Find matching errors
      (while (string-match langtool-output-regexp output last-match)
        ;; TODO: refactor extract
        (let ((line (flycheck-string-to-number-safe (match-string 1 output)))
              (column (flycheck-string-to-number-safe (match-string 2 output)))
              (rule-id (match-string 3 output))
              ;; (message (match-string 4 output))
              (message (concat (match-string 4 output)
                               (format "\n\nSuggestions: %s" (match-string 5 output))))
              (suggestions (match-string 5 output))
               ;; (concat (match-string 4 output)
               ;;                 (format "\n\n%s" (match-string 6 output))))
              )
          ;; (format "\nSuggestions: %s" (match-string 5 output))
              ;; (suggestions (match-string 5 output))
              ;; (example (match-string 6 output)))
          ;; Store suggestion fixes in association list

          ;; Store suggestions with line and column
          (setq flycheck-langtool-fixes (append (list :line line
                                                      :column column
                                                      :fixes: suggestions)
                                                flycheck-langtool-fixes))

          ;; Create flycheck struct object and push it into list
          (push (flycheck-error-new-at
                 line
                 column
                  'error
                  message
                  :id rule-id
                  :checker checker
                  :buffer buffer
                  :filename filename)
                errors))
        ;; NOTE: end refector extract
        (setq last-match (match-end 0)))
      (nreverse errors))
    )


  (defun flycheck-langtool-select-lang (lang)
    "Select langtool checker LANGUAGE for current buffer"
    (interactive
     (if current-prefix-arg
         (list nil)
       (list (completing-read "Select Language: " flycheck-langtool--available-languages))
         )
     )
    (if (member lang flycheck-langtool--available-languages)
        (setq flycheck-langtool-current-language lang)
      (user-error "%S is not a supported language." lang)
      )
    )

  (defun flycheck-langtool-error-fix ()
    (interactive)
    (let (err buffer eline ecolumn)
      ;; (setq err (car-safe (flycheck-overlays-at (point))))

      (setq err (overlay-get (car-safe (flycheck-overlays-at (point)))
                             'flycheck-error))
      ;; NOTE: TEMP
      (setq buffer (get-buffer-create "*TEMP*"))
      (setq eline (flycheck-error-line err))
      (setq ecolumn (flycheck-error-column err))

      (print "error fix" buffer)
      (dolist (fix flycheck-langtool-fixes)
        ;; (print fix buffer)
        (let (line column fixes)
          (setq fline (getf fix :line))
          (setq fcolumn (getf fix :column))
          ;; (setq fixes (split-string (s-trim-left (getf fix :fixes))))

          (print fline buffer)
          (print fcolumn buffer)
          ;; (print (getf fix :fixes) buffer)
           ;; (print (s-trim-left (getf fix :fixes)) buffer)

          )

        ;; (let (line column fixes)
        ;;   (setq line (getf fix :line))
        ;;   (setq column (getf fix :column))
        ;;   (setq fixes (getf fix :fixes))

          ;; (print (getf (fix) :line) buffer)
          ;; (print column buffer)
          ;; (print fixes buffer)
          )
        )

    )
)
