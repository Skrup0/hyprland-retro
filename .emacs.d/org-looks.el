;;; -*- lexical-binding: t; -*-

(defvar-local my/org-looks--top-drawers nil)

(defun my/org-looks-top-drawers-end ()
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-min))
      (while (and (looking-at org-drawer-regexp)
                  (not (string-equal (upcase (match-string 1)) "END"))
                  (re-search-forward "^[ \t]*:END:[ \t]*$" nil t))
        (forward-line 1))
      (and (> (point) (point-min)) (point)))))

(defun my/org-looks-hide-top-drawers ()
  (let ((end (my/org-looks-top-drawers-end))
        (ov my/org-looks--top-drawers))
    (cond ((not end)
           (when ov (delete-overlay ov))
           (setq my/org-looks--top-drawers nil))
          ((and ov (overlay-buffer ov))
           (unless (= (overlay-end ov) end)
             (move-overlay ov (point-min) end)))
          (t
           (setq ov (make-overlay (point-min) end))
           (overlay-put ov 'invisible 'my/org-looks)
           (overlay-put ov 'display "")
           (overlay-put ov 'priority 100)
           (setq my/org-looks--top-drawers ov)))
    (when (and end (< (point) end) (>= end (point-min)) (<= end (point-max)))
      (goto-char end))))

(defun my/org-looks-concealed-h (&rest _)
  (when (derived-mode-p 'org-mode)
    (if my/org--concealed
        (progn
          (unless (and (listp buffer-invisibility-spec)
                       (memq 'my/org-looks buffer-invisibility-spec))
            (add-to-invisibility-spec 'my/org-looks))
          (my/org-looks-hide-top-drawers)
          (add-hook 'post-command-hook #'my/org-looks-hide-top-drawers nil t))
      (remove-from-invisibility-spec 'my/org-looks)
      (when my/org-looks--top-drawers
        (delete-overlay my/org-looks--top-drawers)
        (setq my/org-looks--top-drawers nil))
      (remove-hook 'post-command-hook #'my/org-looks-hide-top-drawers t))))
(advice-add 'my/org-set-concealed :after #'my/org-looks-concealed-h)

(define-advice org-invisible-p (:around (fn &optional pos folding-only) my/org-looks)
  (if (eq (get-char-property (or pos (point)) 'invisible) 'my/org-looks)
      (org-fold-folded-p (or pos (point)))
    (funcall fn pos folding-only)))

(defface my/org-byline
  '((t :inherit org-headline-done :height 0.85 :weight normal :underline nil)) nil
  :group 'org-faces)

(defun my/org-looks-match-keyword (limit)
  (let ((case-fold-search t))
    (re-search-forward
     "^\\(#\\+\\(title\\|author\\|date\\|filetags\\):[ \t]*\\)\\(.*\\)$" limit t)))

(defun my/org-looks-title-setup ()
  (font-lock-add-keywords
   nil
   '((my/org-looks-match-keyword
      (1 '(face nil invisible my/org-looks))
      (3 (unless (string-equal (downcase (match-string 2)) "title")
           'my/org-byline)
         prepend)))
   t))
(add-hook 'org-mode-hook #'my/org-looks-title-setup)

(with-eval-after-load 'org
  (set-face-attribute 'org-document-title nil :height 1.9 :weight 'bold))

(defconst my/org-looks-heading-prefixes
  (mapcar (pcase-lambda (`(,face . ,share))
            (concat (propertize " " 'face face
                                'display `((raise ,share) (space :width 0)))
                    (propertize " " 'face face
                                'display `((raise ,(- share)) (space :width 0)))))
          '((org-level-1 . 0.33) (org-level-2 . 0.27) (org-level-3 . 0.18))))

(defun my/org-looks-heading-space-setup ()
  (setq-local font-lock-extra-managed-props
              (cons 'line-prefix font-lock-extra-managed-props))
  (font-lock-add-keywords
   nil
   '(("^\\(\\*\\{1,3\\}\\) .*"
      (0 (list 'face nil 'line-prefix
               (nth (- (match-end 1) (match-beginning 1) 1)
                    my/org-looks-heading-prefixes)))))
   t))
(add-hook 'org-mode-hook #'my/org-looks-heading-space-setup)

(setq org-ellipsis " ▾")
(with-eval-after-load 'org
  (set-face-attribute 'org-ellipsis nil :foreground 'unspecified
                      :inherit 'org-headline-done :underline nil :height 0.8))

(with-eval-after-load 'org-modern
  (setq org-modern-table t
        org-modern-table-vertical 1))

(define-advice org-modern--pre-redisplay (:after (&rest _) my/org-looks)
  (unless (stringp (cadr org-modern--table-overline))
    (setf (cadr org-modern--table-overline) t)))

(defun my/org-looks-see-through (image)
  (let* ((bg (face-background 'default nil t))
         (rgb (color-values bg)))
    (if (and rgb (eq (car-safe image) 'image))
        (append image `(:background ,bg :mask (heuristic ,rgb)))
      image)))

(define-advice org--make-preview-overlay (:after (beg end &rest _) my/org-looks)
  (dolist (ov (overlays-in beg end))
    (when (eq (overlay-get ov 'org-overlay-type) 'org-latex-overlay)
      (overlay-put ov 'display
                   (my/org-looks-see-through (overlay-get ov 'display))))))

(define-advice svg-tag-make (:filter-return (image) my/org-looks)
  (my/org-looks-see-through image))
