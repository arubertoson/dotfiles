(defvar flycheck-langtool-ignore-rules nil
  "List of rules to ignore when invoking langtools checker.")

(defvar-local flycheck-langtool-fixes nil
  "A assoc list of all fixes in the current buffer")

;; (cl-defstruct (flycheck-langtools-fix
;;                (:constructor flycheck-langtool-fix-new-at (line
;;                                                            column
;;                                                            fixes))))
;;   "Structure representing a list of fixes for error found."

(defvar flycheck-langtool-current-language "en-US"
  "The active language langtool will work with")

(defvar flycheck-langtool-mothertounge nil
  "The mother tounge of user.")

(defconst flycheck-langtool--available-languages '("en-US" "de-DE" "de-DE-x-simple-language" "sv")
  "Supported languages")
