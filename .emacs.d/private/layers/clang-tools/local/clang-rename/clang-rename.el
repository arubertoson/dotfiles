
;;; clang-rename.el --- Renames every occurrence of a symbol found at <offset>.  -*- lexical-binding: t; -*-

;; Keywords: tools, c

;;; Commentary:

;; To install clang-rename.el make sure the directory of this file is in your
;; `load-path' and add
;;
;;   (require 'clang-rename)
;;
;; to your .emacs configuration.

;;; Code:

;; TODO: 

(defgroup clang-rename nil
  "Integration with clang-rename"
  :group 'c)

(defcustom clang-rename-binary "clang-rename"
  "Path to clang-rename executable."
  :type '(file :must-match t)
  :group 'clang-rename)


(defvar clang-rename-buffer "*clang-rename*"
  "clang-rename buffer")


(defun clang-rename--command (new-name)
  "Format string argument used to execute clang-rename"
  (format "%S %S %S -pl %s %s" clang-rename-binary
      (format "-offset=%d" (clang-rename--bufferpos-to-filepos
                            (or (car (bounds-of-thing-at-point 'symbol))
                                (point))
                            'exact))
      (format "-new-name=%s" new-name)
      (format "%S %S %S" "-i" (buffer-file-name) "--")
      (mapconcat 'shell-quote-argument extra-flags " ")
      )
  )


(defun clang-rename--fail ()
  "On failed rename display output message to clang-rename buffer"
  (let ((message (format-message "%s had the event %s" process event)))
    (with-current-buffer clang-rename-buffer
      (insert ?\n ?\n message)
      )
    (popwin:display-buffer "*clang-rename*")
    )
  )

(defun clang-rename--success ()
  "On successful rename kill output buffer and refresh file buffers"
  (kill-buffer clang-rename-buffer)
  (revert-buffer :ignore-auto :noconfirm
                 :preserve-modes))

(defun clang-process-status (process event)
  "Callback function that delegates depending on exit code"
  (if (not (eq (process-exit-status process) 0))
      (clang-rename--fail)
    (clang-rename--success)))

;;;###autoload
(defun clang-rename (new-name)
  (interactive "sEnter new name: ")
  (save-some-buffers :all)

  ;; stand alone undo buffer
  (undo-boundary)
  
  (let ((output-buffer (get-buffer-create clang-rename-buffer)))
    ;; Empty clang-rename buffer
    (with-current-buffer output-buffer
      (erase-buffer))

    ;; Create a sentinel to track exit codes and events.
    (set-process-sentinel (start-process-shell-command "clang-rename"
                                                       clang-rename-buffer
                                                       (clang-rename--command new-name))
                          'clang-process-status)))


(defalias 'clang-rename--bufferpos-to-filepos
  (if (fboundp 'bufferpos-to-filepos)
      'bufferpos-to-filepos
    ;; Emacs 24 doesn’t have ‘bufferpos-to-filepos’, simulate it using
    ;; ‘position-bytes’.
    (lambda (position &optional _quality _coding-system)
      (1- (position-bytes position)))))


(provide 'clang-rename)

;;; clang-rename.el ends here
