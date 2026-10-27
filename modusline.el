;;; modusline.el --- A fast and simple mode-line for vimacs's vim mode

;; Author: Ernest van der Linden  <hello@ernestoz.com>
;; Version: 0.2.0
;; Package-Requires: ((emacs "24.4"))
;; Keywords: line, convenience
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
;; for users of vimacs's vim mode (`vimacs-vim-mode'): its state at the left.

;; Similar and more advanced mode-line packages:
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
;;   modusline-normal-face
;;   modusline-insert-face
;;   modusline-visual-face
;;   modusline-replace-face
;;   modusline-emacs-face
;;   modusline-syntax-face
;;   modusline-syntax-visual-face

;; To toggle mode on and off:
;;
;; M-x modusline-mode

;;; Code:

(defgroup modusline nil
  "Customization group for modusline."
  :group 'convenience
  :prefix "modusline-")

(defface modusline-mode-face
  '((t (:weight bold)))
  "Face for mode line. to avoid theme error?"
  :group 'modusline)

;; Define faces for (un)modified
(defface modusline-modified-face
  '((t (:weight bold)))
  "Face for mode line modified indicator."
  :group 'modusline)
(defface modusline-unmodified-face
  '((t (:weight bold)))
  "Face for mode line unmodified indicator."
  :group 'modusline)

;; Define faces for each state of the vim mode
(defface modusline-normal-face
  '((t :background "DarkGoldenrod2" :foreground "black" :inherit 'mode-line))
  "Face for the vim mode's normal state."
  :group 'modusline)
(defface modusline-insert-face
  '((t :background "chartreuse3" :foreground "black" :inherit 'mode-line))
  "Face for the vim mode's insert state."
  :group 'modusline)
(defface modusline-visual-face
  '((t :background "gray" :foreground "black" :inherit 'mode-line))
  "Face for the vim mode's visual state."
  :group 'modusline)
(defface modusline-replace-face
  '((t :background "red" :foreground "black" :inherit 'mode-line))
  "Face for the vim mode's replace state."
  :group 'modusline)
(defface modusline-emacs-face
  '((t :background "SkyBlue2" :foreground "black" :inherit 'mode-line))
  "Face for the vim mode's Emacs state."
  :group 'modusline)
(defface modusline-syntax-face
'((t :background "Black" :foreground "white" :inherit 'mode-line))
"Face for the vim mode's syntax state."
:group 'modusline)
(defface modusline-syntax-visual-face
  '((t :background "gray30" :foreground "white" :inherit 'mode-line))
  "Face for the vim mode's syntax-visual state."
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
   '((:eval (modusline-state-indicator)) "%e" mode-line-front-space
     (:propertize ("" mode-line-mule-info mode-line-client 
                   mode-line-modified mode-line-remote)
                  display (min-width (5.0)))
     mode-line-frame-identification
     ;; Replace standard buffer identification with our custom one
     (:eval (modusline--buffer-identification)) "   "
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
     "  "
     (:eval (propertize (format-mode-line mode-name)
                        'face 'modusline-mode-face)))))

(defun modusline--backup-mode-line-format ()
  "Backup the original mode-line format."
  (setq modusline--default-mode-line-format (default-value 'mode-line-format)))
(defun modusline--restore-mode-line-format ()
  "Restore the original mode-line format."
  (setq-default mode-line-format modusline--default-mode-line-format))

(defun modusline--enable ()
  "Enable ModusLine."
  (modusline--backup-mode-line-format)
  (modusline--show-mode-line))
(defun modusline--disable ()
  "Disable ModusLine."
  (modusline--restore-mode-line-format))

(defun modusline--get-relative-path ()
  "Get the relative path of the current buffer's file.
Returns 'directory/filename' format, showing only the immediate parent directory.
Handles both regular files and dired buffers."
  (cond
   ;; For dired buffers
   ((derived-mode-p 'dired-mode)
    (let* ((current-dir (expand-file-name default-directory))
           (parent-dir (file-name-nondirectory
                        (directory-file-name current-dir)))
           (grand-parent-dir (file-name-nondirectory
                              (directory-file-name
                               (file-name-directory
                                (directory-file-name current-dir))))))
      (if (string= parent-dir "")
          "/" ; We're at root
        (concat grand-parent-dir "/" parent-dir))))
   
   ;; For regular files
   (buffer-file-name
    (let* ((filename (file-name-nondirectory buffer-file-name))
           (directory (file-name-directory buffer-file-name))
           (parent-dir (when directory 
                         (file-name-nondirectory 
                          (directory-file-name directory)))))
      (if parent-dir
          (concat parent-dir "/" filename)
        filename)))
   
   ;; For other buffers (no file)
   (t (buffer-name))))

(defun modusline--buffer-identification ()
  "Return formatted string for buffer identification."
  (let ((path (modusline--get-relative-path)))
    (propertize path
                'face 'mode-line-buffer-id
                'help-echo (or buffer-file-name default-directory))))

(defun modusline-state-indicator ()
  "The vim mode's state (vimacs's `vimacs-vim-mode'), in its face; nil
where the mode is off."
  (let ((state (and (bound-and-true-p vimacs-vim-mode)
                    (bound-and-true-p vimacs-vim-state))))
    (when state
      (let ((face (cl-case state
                    (normal 'modusline-normal-face)
                    (insert 'modusline-insert-face)
                    ((visual visual-line visual-block) 'modusline-visual-face)
                    (replace 'modusline-replace-face)
                    (emacs 'modusline-emacs-face)
                    (syntax 'modusline-syntax-face)
                    (syntax-visual 'modusline-syntax-visual-face))))
        ;; No pad on the left: the mode line's first character lines up
        ;; with the echo area's below it.
        (propertize
         (format "%s " (upcase (subst-char-in-string ?- ?\s (symbol-name state))))
         'face face)))))

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
