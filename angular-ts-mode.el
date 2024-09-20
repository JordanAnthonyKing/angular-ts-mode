;;; angular-ts-mode.el --- tree-sitter support for HTML  -*- lexical-binding: t; -*-

;; Copyright (C) 2023-2024 Free Software Foundation, Inc.

;; Author     : Theodor Thornhill <theo@thornhill.no>
;; Maintainer : Theodor Thornhill <theo@thornhill.no>
;; Created    : January 2023
;; Keywords   : angular languages tree-sitter

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;

;;; Code:

(require 'treesit)
(require 'sgml-mode)

(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-node-type "treesit.c")

(defcustom angular-ts-mode-indent-offset 2
  "Number of spaces for each indentation step in `angular-ts-mode'."
  :version "29.1"
  :type 'integer
  :safe 'integerp
  :group 'angular)

(defvar angular-ts-mode--indent-rules
  `((angular
     ((parent-is "fragment") column-0 0)
     ((node-is "/>") parent-bol 0)
     ((node-is ">") parent-bol 0)
     ((node-is "end_tag") parent-bol 0)
     ((parent-is "comment") prev-adaptive-prefix 0)
     ((parent-is "element") parent-bol angular-ts-mode-indent-offset)
     ((parent-is "script_element") parent-bol angular-ts-mode-indent-offset)
     ((parent-is "style_element") parent-bol angular-ts-mode-indent-offset)
     ((parent-is "start_tag") parent-bol angular-ts-mode-indent-offset)
     ((parent-is "self_closing_tag") parent-bol angular-ts-mode-indent-offset)

     ;; New rules
     ;; Indent for statement_block and switch_statement nodes
     ((node-is "statement_block") parent-bol angular-ts-mode-indent-offset)
     ((node-is "switch_statement") parent-bol angular-ts-mode-indent-offset)

     ;; Begin block indentation
     ((node-is "{") parent-bol angular-ts-mode-indent-offset)
     
     ;; Branch indentation for closing brace
     ((node-is "}") parent-bol (- angular-ts-mode-indent-offset))
     
     ;; End block indentation
     ((parent-is "statement_block") parent-bol 0)
     ((node-is "}") parent-bol 0)))
  "Tree-sitter indent rules.")

(defvar angular-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'angular
   :override t
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'angular
   :override t
   :feature 'keyword
   '("doctype" @font-lock-keyword-face)

   :language 'angular
   :override t
   :feature 'definition
   '((tag_name) @font-lock-function-name-face)

   :language 'angular
   :override t
   :feature 'string
   '((quoted_attribute_value) @font-lock-string-face)

   :language 'angular
   :override t
   :feature 'property
   '((attribute_name) @font-lock-property-name-face)

   :language 'angular
   :override t
   :feature 'identifier
   '((identifier) @font-lock-variable-name-face)

   :language 'angular
   :override t
   :feature 'pipe_operator
   '((pipe_operator) @font-lock-operator-face)

   :language 'angular
   :override t
   :feature 'string
   '([(string) (static_member_expression)] @font-lock-string-face)

   :language 'angular
   :override t
   :feature 'number
   '((number) @font-lock-number-face)

   :language 'angular
   :override t
   :feature 'pipe_call
   '((pipe_call name: (identifier) @font-lock-function-call-face))

   :language 'angular
   :override t
   :feature 'structural_directive
   '((structural_directive
      "*" @font-lock-keyword-face
      (identifier) @font-lock-keyword-face))

   :language 'angular
   :override t
   :feature 'attribute
   '((attribute
      (attribute_name) @font-lock-property-name-face
      (:match "#.*" @font-lock-property-name-face)))

   :language 'angular
   :override t
   :feature 'binding_name
   '((binding_name
      (identifier) @font-lock-keyword-face))

   :language 'angular
   :override t
   :feature 'event_binding
   '((event_binding
      (binding_name
       (identifier) @font-lock-keyword-face)))

   :language 'angular
   :override t
   :feature 'event_binding
   '((event_binding
      "\"" @font-lock-delimiter-face))

   :language 'angular
   :override t
   :feature 'property_binding
   '((property_binding
      "\"" @font-lock-delimiter-face))

   :language 'angular
   :override t
   :feature 'structural_assignment
   '((structural_assignment
      operator: (identifier) @font-lock-keyword-face))

   :language 'angular
   :override t
   :feature 'member_expression
   '((member_expression
      property: (identifier) @font-lock-property-name-face))

   :language 'angular
   :override t
   :feature 'call_expression
   '((call_expression
      function: (identifier) @font-lock-function-call-face))

   :language 'angular
   :override t
   :feature 'call_expression
   '((call_expression
      function: ((identifier) @font-lock-builtin-face
                 (:match "\$any" @font-lock-builtin-face))))

   :language 'angular
   :override t
   :feature 'pair
   '((pair
      key: ((identifier) @font-lock-builtin-face
            (:match "\$implicit" @font-lock-builtin-face))))

   :language 'angular
   :override t
   :feature 'control_keyword
   '(((control_keyword) @font-lock-keyword-face
     (:match "for\\|empty" @font-lock-keyword-face)))

   :language 'angular
   :override t
   :feature 'control_keyword
   '(((control_keyword) @font-lock-keyword-face
     (:match "if\\|else\\|switch\\|case\\|default" @font-lock-keyword-face)))

   :language 'angular
   :override t
   :feature 'control_keyword
   '(((control_keyword) @font-lock-keyword-face
     (:match "defer\\|placeholder\\|loading" @font-lock-keyword-face)))

   :language 'angular
   :override t
   :feature 'control_keyword
   '(((control_keyword) @font-lock-warning-face
     (:match "error" @font-lock-warning-face)))

   :language 'angular
   :override t
   :feature 'special_keyword
   '((special_keyword) @font-lock-keyword-face)

   :language 'angular
   :override t
   :feature 'boolean
   '(((identifier) @font-lock-builtin-face
     (:match "true\\|false" @font-lock-builtin-face)))

   :language 'angular
   :override t
   :feature 'builtin
   '(((identifier) @font-lock-builtin-face
     (:match "\\(this\\|\\$event\\)" @font-lock-builtin-face)))

   :language 'angular
   :override t
   :feature 'builtin
   '(((identifier) @font-lock-builtin-face
     (:match "null" @font-lock-builtin-face)))

   :language 'angular
   :override t
   :feature 'ternary
   '([(ternary_operator) (conditional_operator)] @font-lock-operator-face)

   :language 'angular
   :override t
   :feature 'bracket
   '(["(" ")" "[" "]" "{" "}" "@"] @font-lock-bracket-face)

   :language 'angular
   :override t
   :feature 'two_way_binding
   '(["[(" ")]"] @font-lock-bracket-face)

   :language 'angular
   :override t
   :feature 'two_way_binding
   '(["{{" "}}"] @font-lock-escape-face)

   :language 'angular
   :override t
   :feature 'inline
   '([";" "." "," "?."] @font-lock-delimiter-face)

   :language 'angular
   :override t
   :feature 'two_way_binding
   '((nullish_coalescing_expression (coalescing_operator) @font-lock-operator-face))

   :language 'angular
   :override t
   :feature 'concatenation_expression
   '((concatenation_expression "+" @font-lock-operator-face))

   :language 'angular
   :override t
   :feature 'icu
   '((icu_clause) @font-lock-operator-face)

   :language 'angular
   :override t
   :feature 'icu
   '((icu_category) @font-lock-keyword-face)

   :language 'angular
   :override t
   :feature 'binary_expression
   '((binary_expression
     ["-" "&&" "+" "<" "<=" "=" "==" "===" "!=" "!=="
      ">" ">=" "*" "/" "||" "%"] @font-lock-operator-face))
  )
  "Tree-sitter font-lock settings for `angular-ts-mode'.")

(defun angular-ts-mode--defun-name (node)
  "Return the defun name of NODE.
Return nil if there is no name or if NODE is not a defun node."
  (when (equal (treesit-node-type node) "tag_name")
    (treesit-node-text node t)))

(defun angular-ts-mode--setup ()
  "Set up `angular-ts-mode' for use with Tree-sitter."
  (unless (treesit-ready-p 'angular)
    (error "Tree-sitter for Angular isn't available"))

  (treesit-parser-create 'angular)

  ;; Indent.
  (setq-local treesit-simple-indent-rules angular-ts-mode--indent-rules)

  ;; Navigation.
  (setq-local treesit-defun-type-regexp "element")
  (setq-local treesit-defun-name-function #'angular-ts-mode--defun-name)

  (setq-local treesit-thing-settings
              `((angular
                 (sexp ,(regexp-opt '("element"
                                      "text"
                                      "attribute"
                                      "value")))
                 (sentence "tag")
                 (text ,(regexp-opt '("comment" "text"))))))

  ;; Font-lock.
  (setq-local treesit-font-lock-settings angular-ts-mode--font-lock-settings)
  (setq-local treesit-font-lock-feature-list
              '((comment keyword definition property string pipe_call pipe_operator
                          structural_directive attribute binding_name event_binding
                          property_binding structural_assignment member_expression
                          call_expression pair control_keyword special_keyword
                          boolean builtin ternary bracket two_way_binding
                          concatenation_expression icu binary_expression)))

  ;; Imenu.
  (setq-local treesit-simple-imenu-settings
              '(("Element" "\\`tag_name\\'" nil nil)))

  ;; TODO:
  ;; Outline minor mode.
  (setq-local treesit-outline-predicate "\\`element\\'")
  ;; `html-ts-mode' inherits from `html-mode' that sets
  ;; regexp-based outline variables.  So need to restore
  ;; the default values of outline variables to be able
  ;; to use `treesit-outline-predicate' above.
   (kill-local-variable 'outline-regexp)
   (kill-local-variable 'outline-heading-end-regexp)
   (kill-local-variable 'outline-level)

  (treesit-major-mode-setup))

;;;###autoload
(define-derived-mode angular-ts-mode html-mode "Angular"
  "Major mode for editing Angular flavoured HTML, powered by tree-sitter."
  :group 'angular
  (angular-ts-mode--setup))

(derived-mode-add-parents 'angular-ts-mode '(angular-mode))

(when (treesit-ready-p 'angular)
  (add-to-list 'auto-mode-alist '("\\.component\\.html\\'" . angular-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.container\\.html\\'" . angular-ts-mode)))

(provide 'angular-ts-mode)

;;; angular-ts-mode.el ends here
