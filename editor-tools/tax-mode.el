;; tax mode definition

;; tax-mode will font lock section keywords and numeric constants


(defvar tax-section-keywords
  '("income"
    "fed-tax-table"
    "income-adj"
    "fed-income-adj"
    "fed-income-taxes-paid"
    "fed-deductions"
    "fed-exemptions"
    "fed-credits"
    "fed-extra-income-taxes"
    "fed-other-taxes-paid"
    "fed-exemption-factor"))

(defvar tax-font-lock-expr
  ;; use constant face for numbers
  '(("\\b[0-9]+\\b" . font-lock-constant-face)))

(defvar tax-font-lock-keywords
  (cons (regexp-opt tax-section-keywords 'words) tax-font-lock-expr))

(defvar tax-mode-syntax-table nil
  "Syntax table for `tax-mode'.")

(if tax-mode-syntax-table
    ()
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?# "<\n" st) ;; pound is the start of a comment
    (modify-syntax-entry ?\n ">#" st) ;; newline is the end of a comment
    (modify-syntax-entry ?~ "." st) ;; tilda is a punctuation mark
    (modify-syntax-entry ?- "_" st) ;; dash is an symbol constituent
    (setq tax-mode-syntax-table st)
    ))


(defun tax-mode ()
  "Major mode for editing tax files"
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'tax-mode)
  (setq mode-name "taxes")
  (set-syntax-table tax-mode-syntax-table)
  (set (make-local-variable 'comment-start) "#")
  (set (make-local-variable 'comment-start-skip) "#+\\s-*")
  (set (make-local-variable 'font-lock-defaults)
       '(tax-font-lock-keywords))
  (run-hooks 'tax-mode-hook))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.tax\\'" . tax-mode))