;; defines tax-mode generically

(define-generic-mode tax-mode
  '("#")
  '("income"
    "fed-tax-table"
    "income-adj"
    "fed-income-adj"
    "fed-taxes-paid"
    "fed-deductions"
    "fed-exemptions"
    "fed-credits"
    )
  '(("\\b[0-9]+\\b" . font-lock-constant-face))
  '(".tax")
  nil)
