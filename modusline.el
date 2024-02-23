;;; modusline.el --- A fast and simple mode-line for `evil-mode' users

;; Author: Ernest van der Linden  <hello@ernestoz.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.4") (evil "1.2.14"))
;; Keywords: line, convenience, evil
;; URL: https://github.com/ernstvanderlinden/emacs-modusline


;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the MIT License.

;; MIT License
;;
;; Copyright (c) 2024 Ernest M. van der Linden
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; `modusline' provides a lightweight and fast mode-line designed specifically
;; for users of evil-mode.

;; Similar and more advanced evil mode-line packages: 
;; - `Powerline'
;; - `Spaceline' :derived from Powerline
;; - `Doom-modeline' :derived from Powerline

;; Similar package to hide minor-modes from mode-line:
;; - `Diminish'

;;; Usage:

;; To enable modusline, simply add the following to your Emacs configuration:

;; (require 'modusline)
;; (modusline-mode 1)

;; You can customize hidden minor modes by setting `modusline-hidden-minor-modes'.
;; Example:
;;
;; (setq modusline-hidden-minor-modes
;;   '(modusline-mode
;;     aggressive-indent-mode
;;     auto-revert-mode
;;     magit-auto-revert-mode
;;     undo-tree-mode
;;     visual-line-mode
;;     yas-minor-mode
;;     smartparens-mode
;;     which-key-mode
;;     org-indent-mode
;;     indent-mode)

;; Available custom faces:
;;
;;   modusline-modified-face
;;   modusline-unmodified-face
;;   modusline-evil-normal-face
;;   modusline-evil-insert-face
;;   modusline-evil-visual-face
;;   modusline-evil-replace-face
;;   modusline-evil-emacs-face
;;   modusline-evil-syntax-face

;; To toggle mode on and off:
;;
;; M-x modusline-mode

;;; Code:

(require 'evil)

(defgroup modusline nil
  "Customization group for modusline."
  :group 'convenience
  :prefix "modusline-")

;; Define faces for (un)modified
(defface modusline-modified-face
  '((t (:weight bold)))
  "Face for mode line modified indicator."
  :group 'modusline)
(defface modusline-unmodified-face
  '((t (:weight bold)))
  "Face for mode line unmodified indicator."
  :group 'modusline)

;; Define faces for each Evil state
(defface modusline-evil-normal-face
  '((t :background "DarkGoldenrod2" :foreground "black" :inherit 'mode-line))
  "Face for Evil Normal state."
  :group 'modusline)
(defface modusline-evil-insert-face
  '((t :background "chartreuse3" :foreground "black" :inherit 'mode-line))
  "Face for Evil Insert state."
  :group 'modusline)
(defface modusline-evil-visual-face
  '((t :background "gray" :foreground "black" :inherit 'mode-line))
  "Face for Evil Visual state."
  :group 'modusline)
(defface modusline-evil-replace-face
  '((t :background "red" :foreground "black" :inherit 'mode-line))
  "Face for Evil Replace state."
  :group 'modusline)
(defface modusline-evil-emacs-face
  '((t :background "SkyBlue2" :foreground "black" :inherit 'mode-line))
  "Face for Evil Emacs state."
  :group 'modusline)
(defface modusline-evil-syntax-face
'((t :background "Black" :foreground "white" :inherit 'mode-line))
"Face for Evil Syntax state."
:group 'modusline)

(defvar modusline-hidden-minor-modes '(modusline-mode)
  "List of minor modes to exclude from the mode line.")

(defvar modusline--modified-text "modified")
(defvar modusline--unmodified-text "")

(defvar modusline--default-mode-line-format 
  (default-value 'mode-line-format))

(defun modusline-visible-minor-modes ()
  "Returns a string of minor modes, excluding `modusline-hidden-minor-modes'."
  (format-mode-line
   (delq nil
         (mapcar (lambda (mm)
                   (let ((mode (car mm)))
                     (unless (member mode modusline-hidden-minor-modes)
                       mm)))
                 minor-mode-alist))))

(defun modusline--show-mode-line ()
  (setq-default 
   mode-line-format
   '((:eval (modusline-evil-state-indicator)) "%e" mode-line-front-space
     (:propertize ("" mode-line-mule-info mode-line-client 
                   mode-line-modified mode-line-remote)
                  display (min-width (5.0)))
     mode-line-frame-identification
     mode-line-buffer-identification "   "
     mode-line-position
     (:eval (modusline-visible-minor-modes))
     (:eval (propertize 
             (concat 
              " "
              (if (buffer-modified-p) 
                  modusline--modified-text 
                modusline--unmodified-text))
             'face (if (buffer-modified-p) 
                       'modusline-modified-face 
                     'modusline-unmodified-face)))
     (vc-mode vc-mode) "  "
     mode-line-misc-info
     ;; right align
     (:eval (propertize 
             " " 'display 
             `(space 
               :align-to 
               (- right 
                  ,(string-width 
                    (format-mode-line 
                     '(:eval (modusline-evil-state-indicator)))) -1))))
     (:eval (modusline-evil-state-indicator))
     )))

(defun modusline--backup-mode-line-format ()
  "Backup the original mode-line format."
  (setq modusline--default-mode-line-format (default-value 'mode-line-format)))
(defun modusline--restore-mode-line-format ()
  "Restore the original mode-line format."
  (setq-default mode-line-format modusline--default-mode-line-format))

(defun modusline--enable ()
  "Enable ModusLine."
  (advice-add 'evil-refresh-mode-line 
              :override #'modusline-evil-refresh-mode-line)
  (modusline--backup-mode-line-format)
  (modusline--show-mode-line))
(defun modusline--disable ()
  "Disable ModusLine."
  (advice-remove 'evil-refresh-mode-line 
                 #'modusline-evil-refresh-mode-line)
  (modusline--restore-mode-line-format))

;; override `evil-refresh-mode-line' when is active.
(defun modusline-evil-refresh-mode-line (&optional state)
  "Override of `evil-refresh-mode-line' when minor-mode is active."
  (force-mode-line-update t))
;; DISABLED: We simply do not include this in the mode-line-format var.
;; (setq evil-mode-line-tag nil)

(defun modusline-evil-state-indicator ()
  "Returns a formatted string with the current evil state with a face."
  (let ((face (cl-case evil-state
                (normal 'modusline-evil-normal-face)
                (insert 'modusline-evil-insert-face)
                (visual 'modusline-evil-visual-face)
                (replace 'modusline-evil-replace-face)
                (emacs 'modusline-evil-emacs-face)
                (syntax 'modusline-evil-syntax-face)
                (t 'mode-line))))
    (propertize 
     (format " %s " (upcase (symbol-name evil-state))) 'face face)))

;;;###autoload
(define-minor-mode modusline-mode
  "Toggle ModusLine mode."
  :global t
  :group 'modusline
  :lighter " ModusLine"
  (if modusline-mode
      (modusline--enable)
    (modusline--disable)))

(provide 'modusline)

;;; modusline.el ends here
