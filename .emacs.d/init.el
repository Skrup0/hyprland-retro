;;; -*- lexical-binding: t; -*-

(with-eval-after-load 'package
  (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t))

(setq use-package-always-ensure t
      package-install-upgrade-built-in t)

(define-advice use-package-ensure-elpa (:before-until (name args &rest _) skip-active)
  (let ((pkg (car args)))
    (memq (if (eq pkg t) (use-package-as-symbol name) pkg) package-activated-list)))

(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file 'noerror 'nomessage)

(setq backup-directory-alist `(("." . ,(locate-user-emacs-file "backups/")))
      auto-save-file-name-transforms `((".*" ,(locate-user-emacs-file "auto-saves/") t))
      backup-by-copying t
      version-control t
      kept-new-versions 5
      kept-old-versions 2
      delete-old-versions t)

(recentf-mode 1)

(setq password-cache-expiry nil
      auth-sources nil)

(defun my/make-unwritable-editable ()
  (when (and buffer-file-name (not (file-writable-p buffer-file-name)))
    (setq buffer-read-only nil)))
(add-hook 'find-file-hook #'my/make-unwritable-editable)

(defun my/sudo-write-file ()
  (when (and buffer-file-name (not (file-writable-p buffer-file-name)))
    (write-region (point-min) (point-max) (concat "/sudo::" buffer-file-name))
    (set-buffer-modified-p nil)
    (message "Saved via sudo: %s" buffer-file-name)
    t))
(add-hook 'write-file-functions #'my/sudo-write-file)

(use-package sudo-edit :commands sudo-edit)

(advice-add 'display-startup-echo-area-message :override #'ignore)

(setq read-process-output-max (* 1024 1024)
      process-adaptive-read-buffering nil
      redisplay-skip-fontification-on-input t
      fast-but-imprecise-scrolling t
      inhibit-compacting-font-caches t)

(add-to-list 'custom-theme-load-path (locate-user-emacs-file "themes/"))
(load-theme 'noctalia t)

(set-face-attribute 'default nil :family "Terminus" :height 120 :weight 'bold)
(set-face-attribute 'tab-line nil :background 'unspecified :inherit 'default)

(setq-default mode-line-format nil)
(setq use-dialog-box nil)
(tooltip-mode -1)

(setq display-line-numbers-type 'visual)
(global-display-line-numbers-mode 1)

(setq-default indent-tabs-mode nil
              tab-width 2
              truncate-lines t)

(setq scroll-margin 10
      scroll-conservatively 101
      scroll-preserve-screen-position t
      undo-limit 400000
      undo-strong-limit 3000000
      undo-outer-limit 48000000
      kill-ring-max 100)

(electric-pair-mode 1)
(keymap-global-set "<escape>" #'keyboard-escape-quit)

(setq confirm-kill-processes nil)
(advice-add 'server-kill-emacs-query-function :override #'always)

(defvar my/indent-step 2)

(defun my/insert-tab ()
  (interactive)
  (if indent-tabs-mode
      (insert "\t")
    (insert (make-string (- my/indent-step (% (current-column) my/indent-step))
                         ?\s))))

(keymap-global-set "TAB" #'my/insert-tab)

(defvar-keymap my/notes-map
  "f" #'org-roam-node-find
  "i" #'org-roam-node-insert
  "b" #'org-roam-buffer-toggle
  "s" #'consult-org-roam-search
  "r" #'org-roam-node-random
  "d" #'org-roam-dailies-goto-today
  "g" #'org-roam-ui-mode
  "n" #'org-toggle-narrow-to-subtree
  "p" #'yank-media
  "t" #'org-pomodoro
  "a" #'my/org-srs-card
  "c" #'my/org-srs-cloze
  "R" #'my/org-srs-review)
(keymap-global-set "C-c n" my/notes-map)
(autoload 'org-toggle-narrow-to-subtree "org" nil t)

(defun my/scroll-up-center ()
  (interactive)
  (evil-scroll-up nil)
  (evil-scroll-line-to-center nil))

(defun my/scroll-down-center ()
  (interactive)
  (evil-scroll-down nil)
  (evil-scroll-line-to-center nil))

(defun my/find-file-home ()
  (interactive)
  (affe-find "~"))

(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil)
  :config
  (evil-mode 1)
  (evil-set-undo-system 'undo-redo)
  (setq-default evil-shift-width 2)

  (evil-define-key '(normal visual) 'global
    "j" #'evil-previous-visual-line
    "k" #'evil-next-visual-line
    "J" #'evil-backward-paragraph
    "K" #'evil-forward-paragraph
    "H" #'undefined
    "L" #'undefined
    (kbd "C-j") #'my/scroll-up-center
    (kbd "C-k") #'my/scroll-down-center)
  (evil-define-key 'visual 'global
    (kbd "<up>") #'undefined
    (kbd "<down>") #'undefined
    (kbd "<left>") #'undefined
    (kbd "<right>") #'undefined)
  (evil-define-key 'normal 'global
    "U" #'evil-redo
    (kbd "C-f") #'consult-line
    (kbd "C-d") #'my/find-file-home
    (kbd "C-r") #'consult-recent-file
    (kbd "SPC a") #'org-agenda
    (kbd "SPC c") #'org-capture
    (kbd "SPC n") my/notes-map
    (kbd "SPC s") #'ace-jump-files-buffers
    (kbd "SPC x") #'kill-current-buffer)
  (evil-define-key 'visual 'global
    (kbd "SPC n") my/notes-map))

(use-package vertico
  :custom
  (vertico-count 15)
  (vertico-resize t)
  :init
  (vertico-mode 1))

(use-package hotfuzz
  :defer t
  :init
  (setq completion-styles '(hotfuzz basic)
        completion-category-defaults nil
        completion-category-overrides nil
        completion-ignore-case t))

(use-package consult :defer t)

(defvar my/fd-command
  (concat "fd --type f --hidden --no-ignore --color=never --threads 12"
          " --exclude .git --exclude node_modules --exclude target"
          " --exclude .cargo --exclude .rustup --exclude .cache"
          " --exclude __pycache__ --strip-cwd-prefix"))

(use-package affe
  :commands affe-find
  :config
  (setq affe-find-command my/fd-command))

(use-package fzf
  :commands (fzf fzf-find-file)
  :custom
  (fzf/position-bottom t)
  (fzf/window-height 15)
  (fzf/args "-x --print-query --algo=v1 --margin=1,0")
  (fzf/find-command my/fd-command))

(defvar my/buffer-counter 0)
(defvar-local my/buffer-index nil)
(put 'my/buffer-index 'permanent-local t)

(defun my/record-buffer-order ()
  (unless my/buffer-index
    (setq my/buffer-index (setq my/buffer-counter (1+ my/buffer-counter)))))
(add-hook 'buffer-list-update-hook #'my/record-buffer-order)

(use-package ace-jump-buffer
  :commands ace-jump-files-buffers
  :init
  (setq avy-keys '(?s ?a ?d ?f ?g ?h ?j ?k ?l)
        ajb-sort-function
        (lambda (a b)
          (< (or (buffer-local-value 'my/buffer-index a) most-positive-fixnum)
             (or (buffer-local-value 'my/buffer-index b) most-positive-fixnum))))
  :config
  (make-ace-jump-buffer-function "files"
    (string-prefix-p "*" (buffer-name buffer))))

(load (locate-user-emacs-file "dashboard") nil 'nomessage)

(use-package dashboard
  :demand t
  :custom
  (dashboard-startup-banner 'logo)
  (dashboard-items nil)
  :config
  (dashboard-setup-startup-hook)
  (when (daemonp)
    (dashboard-insert-startupify-lists)))

(defun my/dashboard-in-new-frame ()
  (when (member (buffer-name) '("*scratch*" "*Messages*"))
    (unless (get-buffer dashboard-buffer-name)
      (dashboard-insert-startupify-lists))
    (switch-to-buffer dashboard-buffer-name)))
(add-hook 'server-after-make-frame-hook #'my/dashboard-in-new-frame)

(use-package indent-bars
  :hook ((prog-mode conf-mode) . indent-bars-mode)
  :init
  (setq indent-bars-starting-column 0
        indent-bars-pattern "."
        indent-bars-pad-frac 0.33
        indent-bars-display-on-blank-lines nil)
  :config
  (define-advice indent-bars--window-font-space-width (:override (&optional win) buffer-font)
    (with-selected-window (or win (selected-window))
      (string-pixel-width " " (current-buffer)))))

(defun my/indent-bars-text ()
  (setq-local indent-bars-spacing-override my/indent-step)
  (indent-bars-mode 1))
(add-hook 'text-mode-hook #'my/indent-bars-text)

(defun my/wrap-prefix-function (beg end)
  (goto-char end)
  (unless (bolp) (forward-line 1))
  (setq end (point))
  (goto-char beg)
  (forward-line 0)
  (setq beg (point))
  (remove-text-properties beg end '(wrap-prefix nil))
  (while (< (point) end)
    (looking-at "\\([ \t]*\\)\\(\\(?:[-+*]\\|[0-9]+[.)]\\)[ \t]+\\)?")
    (let ((prefix (match-string 1))
          (bullet (match-string 2)))
      (when (and bullet (string-empty-p prefix) (eq (char-after) ?*))
        (setq bullet nil))
      (when (string-search "\t" prefix)
        (setq prefix (make-string (current-indentation) ?\s)))
      (when bullet
        (setq prefix
              (concat prefix
                      (propertize " " 'display
                                  `(space :width (,(string-pixel-width
                                                    bullet (current-buffer))))))))
      (unless (string-empty-p prefix)
        (put-text-property (point) (pos-eol) 'wrap-prefix prefix)))
    (forward-line 1))
  `(jit-lock-bounds ,beg . ,end))

(define-minor-mode my/wrap-prefix-mode nil
  :lighter nil
  (if my/wrap-prefix-mode
      (progn
        (add-hook 'jit-lock-functions #'my/wrap-prefix-function 'append t)
        (jit-lock-register #'my/wrap-prefix-function))
    (jit-lock-unregister #'my/wrap-prefix-function)
    (with-silent-modifications
      (save-restriction
        (widen)
        (remove-text-properties (point-min) (point-max) '(wrap-prefix nil))))))

(defun my/wrap-prefix-follow-visual-line ()
  (my/wrap-prefix-mode (if visual-line-mode 1 -1)))
(add-hook 'visual-line-mode-hook #'my/wrap-prefix-follow-visual-line)

(setq org-todo-keywords
      '((sequence "TODO(t)" "IN-PROGRESS(i!)" "WAITING(w!)"
                  "|" "DONE(d!)" "CANCELLED(c!)"))
      org-log-done 'time
      org-log-into-drawer t
      org-auto-align-tags nil
      org-blank-before-new-entry '((heading . nil) (plain-list-item . nil))
      org-startup-with-link-previews t
      org-image-actual-width 600
      org-yank-image-save-method "images/"
      image-cache-eviction-delay 300
      org-startup-with-latex-preview t
      org-preview-latex-default-process 'dvisvgm
      org-preview-latex-image-directory (locate-user-emacs-file "ltximg/"))

(with-eval-after-load 'org
  (setq org-startup-indented nil)
  (org-babel-do-load-languages 'org-babel-load-languages
                               '((latex . t) (maxima . t)))
  (setq org-format-latex-options
        (plist-put (copy-sequence org-format-latex-options)
                   :background "Transparent"))
  (dolist (face '(org-level-1 org-level-2 org-level-3 org-level-4
                  org-level-5 org-level-6 org-level-7 org-level-8
                  org-default org-document-title org-document-info
                  org-drawer org-table))
    (set-face-foreground face 'unspecified))
  (set-face-attribute 'org-level-1 nil :height 1.5 :weight 'bold)
  (set-face-attribute 'org-level-2 nil :height 1.3 :weight 'bold)
  (set-face-attribute 'org-level-3 nil :height 1.15 :weight 'bold)
  (set-face-attribute 'org-level-4 nil :height 1.0 :weight 'bold)

  (evil-define-key 'normal org-mode-map
    (kbd "SPC l") #'org-latex-preview)
  (evil-define-key 'insert org-mode-map
    (kbd "TAB") #'my/org-tab
    (kbd "<tab>") #'my/org-tab
    (kbd "<backtab>") #'my/org-backtab
    (kbd "RET") #'my/org-return
    [remap delete-backward-char] #'my/org-backspace))

(defun my/org-mode-setup ()
  (face-remap-add-relative 'default :family "CMU Serif" :height 120)
  (setq-local header-line-format " ")
  (face-remap-add-relative 'header-line
                           :height 2.0
                           :background (face-attribute 'default :background)
                           :foreground (face-attribute 'default :background)
                           :box nil :underline nil :overline nil)
  (display-line-numbers-mode -1)
  (visual-line-mode 1)
  (kill-local-variable 'paragraph-start)
  (kill-local-variable 'paragraph-separate)
  (org-fold-hide-drawer-all)
  (my/org-shade-drawers)
  (add-hook 'after-save-hook #'my/org-shade-drawers nil t)
  (my/org-manual-indent-setup)
  (my/org-conceal-setup)
  (require 'org-roam))
(add-hook 'org-mode-hook #'my/org-mode-setup)
(add-hook 'org-mode-hook #'turn-on-org-cdlatex)

(defun my/org-shade-drawers ()
  (remove-overlays (point-min) (point-max) 'my/drawer t)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^[ \t]*:\\([A-Za-z]+\\):[ \t]*$" nil t)
      (unless (string-equal (upcase (match-string 1)) "END")
        (let ((start (line-beginning-position)))
          (when (re-search-forward "^[ \t]*:END:[ \t]*$" nil t)
            (let ((ov (make-overlay start (1+ (line-end-position)))))
              (overlay-put ov 'face '(:background "#161616" :extend t))
              (overlay-put ov 'my/drawer t))))))))

(use-package evil-org
  :hook (org-mode . evil-org-mode)
  :config
  (evil-org-set-key-theme '(navigation insert textobjects additional calendar))
  (evil-define-key 'normal 'evil-org-mode
    "o" #'my/org-open-below
    "O" #'my/org-open-above)
  (evil-define-key 'visual 'evil-org-mode
    (kbd "TAB") #'my/org-indent-region-right
    (kbd "<tab>") #'my/org-indent-region-right
    (kbd "<backtab>") #'my/org-indent-region-left
    "L" #'my/org-indent-region-right
    "H" #'my/org-indent-region-left))

(setq org-cycle-emulate-tab nil
      org-src-preserve-indentation t
      evil-org-special-o/O '(table-row))

(defun my/org-indent-step-h ()
  (when (derived-mode-p 'org-mode)
    (setq-local my/indent-step 4)))
(add-hook 'text-mode-hook #'my/org-indent-step-h -50)

(defun my/org-manual-indent-setup ()
  (when (bound-and-true-p org-indent-mode)
    (org-indent-mode -1))
  (electric-indent-local-mode -1)
  (setq-local evil-auto-indent nil))

(defun my/org-indent-line (n)
  (beginning-of-line)
  (if (looking-at "^\\(\\*+\\)\\( +\\)")
      (let* ((space-beg (match-beginning 2))
             (space-end (match-end 2))
             (space-len (- space-end space-beg)))
        (if (> n 0)
            (progn (goto-char space-end) (insert (make-string n ?\s)))
          (let ((remove (min (- n) (max 0 (1- space-len)))))
            (when (> remove 0)
              (delete-region (- space-end remove) space-end)))))
    (if (> n 0)
        (insert (make-string n ?\s))
      (let* ((bol (point))
             (existing (progn (skip-chars-forward " \t") (- (point) bol)))
             (remove (min (- n) existing)))
        (when (> remove 0)
          (delete-region bol (+ bol remove)))))))

(defun my/org-indent-region (n)
  (let* ((beg (region-beginning))
         (end (region-end))
         (end (if (and (> end beg) (save-excursion (goto-char end) (bolp)))
                  (1- end)
                end)))
    (save-excursion
      (goto-char beg)
      (dotimes (_ (1+ (- (line-number-at-pos end) (line-number-at-pos beg))))
        (my/org-indent-line n)
        (forward-line 1))))
  (setq deactivate-mark nil))

(defun my/org-indent-region-right ()
  (interactive)
  (my/org-indent-region my/indent-step))

(defun my/org-indent-region-left ()
  (interactive)
  (my/org-indent-region (- my/indent-step)))

(defun my/org-tab ()
  (interactive)
  (cond ((org-at-table-p)
         (org-table-justify-field-maybe)
         (call-interactively #'org-table-next-field)
         (setq this-command 'org-cycle))
        ((org-try-cdlatex-tab))
        (t (my/insert-tab))))
(evil-declare-change-repeat 'my/org-tab)

(defun my/org-backtab ()
  (interactive)
  (save-excursion (my/org-indent-line (- my/indent-step))))

(defun my/org-backspace ()
  (interactive)
  (let ((col (current-column)))
    (if (and (> col 0)
             (not (use-region-p))
             (save-excursion (skip-chars-backward " ") (bolp)))
        (delete-char (- (1+ (% (1- col) my/indent-step))))
      (call-interactively #'evil-delete-backward-char-and-join))))

(defun my/org-blank-line-p ()
  (save-excursion (beginning-of-line) (looking-at-p "[ \t]*$")))

(defun my/org-return ()
  (interactive)
  (if (org-at-table-p)
      (progn (call-interactively #'org-return)
             (setq this-command 'org-return))
    (let ((indent (current-indentation)))
      (when (my/org-blank-line-p)
        (delete-region (line-beginning-position) (line-end-position)))
      (newline nil t)
      (indent-line-to indent))))

(defun my/org-open-below (count)
  (interactive "P")
  (let ((indent (current-indentation)))
    (evil-org-open-below count)
    (unless (org-at-table-p) (indent-line-to indent))))

(defun my/org-open-above (count)
  (interactive "P")
  (let ((indent (current-indentation)))
    (evil-org-open-above count)
    (unless (org-at-table-p) (indent-line-to indent))))

(defun my/org-drop-blank-indent-h ()
  (when (and (derived-mode-p 'org-mode) (my/org-blank-line-p))
    (delete-region (line-beginning-position) (line-end-position))))
(add-hook 'evil-insert-state-exit-hook #'my/org-drop-blank-indent-h)

(use-package org-modern
  :defer t
  :config
  (setq org-modern-star nil
        org-modern-hide-stars nil
        org-modern-timestamp nil
        org-modern-todo nil
        org-modern-tag nil
        org-modern-priority nil
        org-modern-table nil
        org-modern-checkbox '((?X . "") (?- . "󰡖") (?\s . ""))
        org-modern-block-name nil
        org-modern-block-fringe 8
        org-modern-internal-target nil
        org-modern-radio-target nil
        org-modern-horizontal-rule t
        org-modern-list '((?- . "•") (?* . "•"))
        org-modern-progress nil))

(use-package svg-tag-mode
  :defer t
  :config
  (setq svg-tag-tags
        `(("^\\*+ \\(TODO\\)"        . ((lambda (_) (svg-tag-make "TODO"        :face 'org-todo :inverse t))))
          ("^\\*+ \\(IN-PROGRESS\\)" . ((lambda (_) (svg-tag-make "IN-PROGRESS" :face 'warning  :inverse t))))
          ("^\\*+ \\(WAITING\\)"     . ((lambda (_) (svg-tag-make "WAITING"     :face 'warning  :inverse t))))
          ("^\\*+ \\(DONE\\)"        . ((lambda (_) (svg-tag-make "DONE"        :face 'org-done :inverse t))))
          ("^\\*+ \\(CANCELLED\\)"   . ((lambda (_) (svg-tag-make "CANCELLED"   :face 'error    :inverse t))))
          ("^\\*+.*\\(:[A-Z][A-Z0-9_]+:\\)" . ((lambda (tag) (svg-tag-make tag :beg 1 :end -1 :inverse t))))
          ("\\[#A\\]" . ((lambda (_) (svg-tag-make "#A" :face 'error   :inverse t))))
          ("\\[#B\\]" . ((lambda (_) (svg-tag-make "#B" :face 'warning :inverse t))))
          ("\\[#C\\]" . ((lambda (_) (svg-tag-make "#C" :face 'success :inverse t))))
          ("\\(:[A-Za-z][A-Za-z0-9_@#%]*:\\)" . ((lambda (tag) (svg-tag-make tag :beg 1 :end -1 :face 'default :inverse nil)))))))

(defvar-local my/org--concealed nil)

(defun my/org-set-concealed (flag)
  (setq flag (and flag t))
  (unless (eq flag my/org--concealed)
    (setq my/org--concealed flag)
    (if flag
        (progn (add-to-invisibility-spec 'my/org-stars)
               (add-to-invisibility-spec '(org-link)))
      (remove-from-invisibility-spec 'my/org-stars)
      (remove-from-invisibility-spec '(org-link)))
    (svg-tag-mode (if flag 1 -1))
    (org-modern-mode (if flag 1 -1))
    (if flag (org-link-preview-region) (org-link-preview-clear))))

(define-advice org-invisible-p (:around (fn &optional pos folding-only) my/org-stars)
  (if (eq (get-text-property (or pos (point)) 'invisible) 'my/org-stars)
      (org-fold-folded-p (or pos (point)))
    (funcall fn pos folding-only)))

(defun my/org-conceal-setup ()
  (font-lock-add-keywords nil '(("^\\*+ " 0 '(face nil invisible my/org-stars))) t)
  (my/org-set-concealed t))

(defun my/org-reveal-h ()
  (when (derived-mode-p 'org-mode)
    (my/org-set-concealed nil)))

(defun my/org-conceal-h ()
  (when (and (derived-mode-p 'org-mode)
             (not (memq evil-next-state '(insert visual))))
    (my/org-set-concealed t)))

(add-hook 'evil-insert-state-entry-hook #'my/org-reveal-h)
(add-hook 'evil-visual-state-entry-hook #'my/org-reveal-h)
(add-hook 'evil-insert-state-exit-hook #'my/org-conceal-h)
(add-hook 'evil-visual-state-exit-hook #'my/org-conceal-h)

(use-package org-fragtog
  :hook (org-mode . org-fragtog-mode))

(load (locate-user-emacs-file "org-looks") nil 'nomessage)

(defun my/org-roam-prompt-directory ()
  (let* ((root (expand-file-name org-roam-directory))
         (dirs (mapcar (lambda (d) (file-relative-name d root))
                       (seq-filter #'file-directory-p
                                   (directory-files-recursively root "" t))))
         (dirs (seq-remove (lambda (d)
                             (string-match-p "\\(?:\\`\\|/\\)\\(?:\\.\\|images\\'\\)" d))
                           dirs))
         (chosen (completing-read "Directory: " (cons "." dirs))))
    (make-directory (expand-file-name chosen root) t)
    (if (string= chosen ".") "" (file-name-as-directory chosen))))

(use-package org-roam
  :commands org-roam-buffer-toggle
  :init
  (setq org-roam-directory "~/Documents/notes"
        org-roam-completion-everywhere t
        org-roam-node-display-template
        (concat "${title:*} " (propertize "${tags:20}" 'face 'org-tag))
        org-roam-capture-templates
        '(("d" "default" plain "%?"
           :target (file+head "%(my/org-roam-prompt-directory)%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+TITLE: ${title}\n#+AUTHOR: %(user-login-name)\n#+DATE: %U\n#+FILETAGS: %^{FILETAGS}\n-----\n")
           :unnarrowed t)))
  :config
  (org-roam-db-autosync-mode 1))

(defun my/org-roam-include-node-p ()
  (not (and (org-at-heading-p)
            (save-excursion
              (re-search-forward "^[ \t]*:SRSITEMS:[ \t]*$"
                                 (save-excursion (outline-next-heading) (point))
                                 t)))))
(setq org-roam-db-node-include-function #'my/org-roam-include-node-p)

(use-package consult-org-roam
  :defer t
  :init
  (with-eval-after-load 'org-roam
    (consult-org-roam-mode 1)))

(use-package org-roam-ui
  :commands org-roam-ui-mode
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t))

(setq org-agenda-window-setup 'only-window)

(defun my/org-refresh-agenda-files (&rest _)
  (setq org-agenda-files
        (cons (locate-user-emacs-file "todos.org")
              (directory-files-recursively "~/Documents/notes/" "\\.org\\'"))))
(advice-add 'org-agenda :before #'my/org-refresh-agenda-files)

(defun my/org-agenda-clean-unvisited-buffers (&rest _)
  (let ((visible (mapcar #'window-buffer (window-list))))
    (dolist (file (org-agenda-files))
      (let ((buf (get-file-buffer file)))
        (when (and buf (not (memq buf visible)) (not (buffer-modified-p buf)))
          (kill-buffer buf))))))
(advice-add 'org-agenda-goto :after #'my/org-agenda-clean-unvisited-buffers)
(advice-add 'org-agenda-switch-to :after #'my/org-agenda-clean-unvisited-buffers)

(defun my/org-capture-schedule-deadline ()
  (let* ((sched (when (y-or-n-p "Add schedule? ")
                  (format-time-string "<%Y-%m-%d %a %H:%M>"
                                      (org-read-date t t nil "Schedule"))))
         (dead (when (y-or-n-p "Add deadline? ")
                 (format-time-string "<%Y-%m-%d %a %H:%M>"
                                     (org-read-date t t nil "Deadline")))))
    (concat
     (when sched (concat "SCHEDULED: " sched (unless dead "\n")))
     (when (and sched dead) " ")
     (when dead (concat "DEADLINE: " dead "\n")))))

(setq org-capture-templates
      (let ((todos (locate-user-emacs-file "todos.org"))
            (tmpl "*** TODO [#%^{Priority|C|A|B}] %?\n%(my/org-capture-schedule-deadline)-----"))
        `(("d" "Diary" entry
           (file+headline ,(locate-user-emacs-file "diary.org") "Diary\n-----\n")
           "*** %<%A, %d %B %Y> :%^{Mood|happy|sad|neutral}:\n%?\n-----"
           :prepend t :empty-lines-after 1)
          ("t" "Todo")
          ("ts" "General" entry (file+headline ,todos "General :general:")
           ,tmpl :prepend t :empty-lines-after 1)
          ("ta" "Studies" entry (file+headline ,todos "Studies :studies:")
           ,tmpl :prepend t :empty-lines-after 1)
          ("td" "Life" entry (file+headline ,todos "Life :life:")
           ,tmpl :prepend t :empty-lines-after 1)
          ("tf" "Tech" entry (file+headline ,todos "Tech :tech:")
           ,tmpl :prepend t :empty-lines-after 1))))

(defun my/todos-tags ()
  (with-current-buffer (find-file-noselect (locate-user-emacs-file "todos.org"))
    (mapcar #'car (org-get-buffer-tags))))

(defun my/org-capture-ask-tag ()
  (when (string-prefix-p "t" (plist-get org-capture-plist :key))
    (org-set-tags (completing-read "Tag: " (my/todos-tags)))))
(add-hook 'org-capture-before-finalize-hook #'my/org-capture-ask-tag)

(use-package auctex :defer t)

(use-package cdlatex
  :hook (LaTeX-mode . cdlatex-mode)
  :config
  (add-to-list 'cdlatex-math-symbol-alist '(?m ("$$ ? $$"))))

(use-package company
  :hook (after-init . global-company-mode))

(use-package company-math
  :defer t
  :init
  (setq company-math-allow-latex-symbols-in-faces t)
  (with-eval-after-load 'company
    (add-to-list 'company-backends
                 '(company-math-symbols-latex company-latex-commands))))

(use-package org-pomodoro :defer t)

(use-package org-srs
  :defer t
  :init
  (setq org-srs-item-confirm #'my/org-srs-confirm
        org-srs-review-new-items-per-day 100
        org-srs-review-max-reviews-per-day 1000
        org-srs-review-cache-p t)
  :config
  (org-srs-ui-header-line-mode 1)
  (add-hook 'org-srs-item-before-review-hook #'my/org-srs-review-keys-on)
  (add-hook 'org-srs-review-after-rate-hook #'my/org-srs-save)
  (add-hook 'org-srs-review-finish-hook #'my/org-srs-review-done)
  (cl-defmethod org-srs-query-function ((source (head my/files)))
    (lambda (predicate)
      (cl-loop for file in (cdr source)
               nconc (org-srs-query-file predicate file)))))

(defun my/org-srs-card ()
  (interactive)
  (require 'org-srs)
  (org-id-get-create)
  (org-srs-item-new-interactively 'card))

(defun my/org-srs-cloze ()
  (interactive)
  (require 'org-srs)
  (org-srs-item-cloze-dwim)
  (deactivate-mark)
  (save-excursion
    (org-back-to-heading-or-point-min)
    (org-srs-item-cloze-update 1)))

(defun my/org-srs-file-counts (file)
  (cl-flet ((count ()
              (goto-char (point-min))
              (let ((new 0) (due 0) (cards 0))
                (while (re-search-forward org-srs-log-latest-timestamp-regexp nil t)
                  (cl-incf cards)
                  (cond ((save-excursion (forward-line -2) (looking-at-p "[ \t]*|-"))
                         (cl-incf new))
                        ((time-less-p (org-srs-timestamp-time (match-string 2)) nil)
                         (cl-incf due))))
                (and (> cards 0) (list new due)))))
    (if-let* ((buffer (find-buffer-visiting file)))
        (with-current-buffer buffer
          (org-with-wide-buffer (count)))
      (with-temp-buffer
        (insert-file-contents file)
        (count)))))

(defun my/org-srs-choose-deck (counts)
  (let* ((root (file-name-as-directory (expand-file-name org-roam-directory)))
         (dir root))
    (catch 'files
      (while t
        (let* ((files (seq-filter (lambda (file) (string-prefix-p dir file))
                                  (mapcar #'car counts)))
               (folders (sort (seq-uniq
                               (mapcan (lambda (file)
                                         (let ((rel (file-relative-name file dir)))
                                           (and (string-search "/" rel)
                                                (list (car (split-string rel "/"))))))
                                       files))
                              #'string<))
               (annotate
                (lambda (deck)
                  (let ((under (if (equal deck "All") dir
                                 (file-name-as-directory (expand-file-name deck dir))))
                        (new 0) (due 0))
                    (pcase-dolist (`(,file ,n ,d) counts)
                      (when (string-prefix-p under file)
                        (cl-incf new n)
                        (cl-incf due d)))
                    (format "%s%d new  %d due"
                            (propertize " " 'display '(space :align-to 24)) new due))))
               (choice
                (and folders
                     (completing-read
                      (if (equal dir root) "Deck: "
                        (format "Deck (%s): " (file-relative-name dir root)))
                      (lambda (string pred action)
                        (if (eq action 'metadata)
                            `(metadata (display-sort-function . identity)
                                       (annotation-function . ,annotate))
                          (complete-with-action action (cons "All" folders) string pred)))
                      nil t))))
          (if (member choice '(nil "" "All"))
              (throw 'files files)
            (setq dir (file-name-as-directory (expand-file-name choice dir)))))))))

(defvar my/org-srs-review-buffers nil)

(defvar my/org-srs-review-origin nil)

(defun my/org-srs-review ()
  (interactive)
  (require 'org-srs)
  (require 'org-roam)
  (when (org-srs-reviewing-p)
    (user-error "Already reviewing (q stops)"))
  (let ((counts (seq-keep (lambda (file)
                            (when-let* ((count (my/org-srs-file-counts file)))
                              (cons file count)))
                          (org-roam-list-files))))
    (unless counts
      (user-error "No flashcards yet (SPC n a makes one)"))
    (let ((files (my/org-srs-choose-deck counts)))
      (setq my/org-srs-review-buffers (buffer-list)
            my/org-srs-review-origin (current-buffer))
      (org-srs-review-start (cons 'my/files files)))))

(defun my/org-srs-review-cleanup ()
  (when my/org-srs-review-buffers
    (dolist (buffer (buffer-list))
      (unless (or (memq buffer my/org-srs-review-buffers)
                  (not (buffer-file-name buffer))
                  (buffer-modified-p buffer)
                  (get-buffer-window buffer t))
        (kill-buffer buffer)))
    (setq my/org-srs-review-buffers nil)))

(defun my/org-srs-review-done ()
  (run-at-time 0 nil (lambda ()
                       (when (buffer-live-p my/org-srs-review-origin)
                         (switch-to-buffer my/org-srs-review-origin))
                       (my/org-srs-review-cleanup))))

(defun my/org-srs-review-quit ()
  (interactive)
  (org-srs-review-quit)
  (my/org-srs-save)
  (my/org-srs-review-cleanup))

(defun my/org-srs-save ()
  (when (and buffer-file-name (buffer-modified-p))
    (let ((save-silently t))
      (save-buffer))))

(defun my/org-srs-confirm (&rest args)
  (apply #'org-srs-item-confirm-command args)
  (message "RET shows the answer"))

(defun my/org-srs-duration (seconds)
  (cond ((< seconds 3600) (format "%dm" (max 1 (round seconds 60))))
        ((< seconds 86400) (format "%dh" (round seconds 3600)))
        ((< seconds (* 30 86400)) (format "%dd" (round seconds 86400)))
        ((< seconds (* 365 86400)) (format "%.1fmo" (/ seconds 2592000.0)))
        (t (format "%.1fy" (/ seconds 31536000.0)))))

(defun my/org-srs-reveal ()
  (interactive)
  (when (org-srs-item-confirm-pending-p)
    (org-srs-item-confirm-command))
  (let ((intervals (ignore-errors
                     (org-srs-item-with-current org-srs-review-item
                       (when (org-srs-table-goto-column 'rating)
                         (org-srs-stats-intervals))))))
    (message "%s"
             (mapconcat
              (pcase-lambda (`(,key ,rating ,face))
                (let ((seconds (plist-get intervals rating)))
                  (propertize (format "%s %s%s" key (substring (symbol-name rating) 1)
                                      (if seconds (concat " " (my/org-srs-duration seconds)) ""))
                              'face face)))
              '((1 :again error) (2 :hard warning) (3 :good success) (4 :easy homoglyph))
              "    "))))

(define-minor-mode my/org-srs-review-mode nil
  :lighter nil
  (when (bound-and-true-p svg-tag-mode)
    (cursor-sensor-mode (if my/org-srs-review-mode -1 1)))
  (evil-normalize-keymaps))

(evil-define-minor-mode-key 'normal 'my/org-srs-review-mode
  (kbd "RET") #'my/org-srs-reveal
  "1" #'org-srs-review-rate-again
  "2" #'org-srs-review-rate-hard
  "3" #'org-srs-review-rate-good
  "4" #'org-srs-review-rate-easy
  "u" #'org-srs-review-undo
  "q" #'my/org-srs-review-quit)

(defun my/org-srs-review-keys-on (&rest _)
  (my/org-srs-review-mode 1)
  (org-srs-review-add-hook-once 'org-srs-review-continue-hook
                                (lambda () (my/org-srs-review-mode -1))))

(use-package eglot
  :ensure nil
  :hook ((c-mode c-ts-mode) . eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs
               '((c-mode c-ts-mode) . ("clangd" "--clang-tidy"
                                       "--completion-style=detailed"
                                       "--header-insertion=never"))))

(use-package markdown-mode
  :mode "\\.md\\'"
  :hook (markdown-mode . markdown-toggle-markup-hiding)
  :custom
  (markdown-fontify-code-blocks-natively t))

(use-package visual-fill-column
  :hook (org-mode . visual-fill-column-mode)
  :custom
  (visual-fill-column-width 70)
  (visual-fill-column-center-text t))

(use-package jinx
  :hook ((org-mode markdown-mode) . jinx-mode)
  :config
  (evil-define-key 'normal jinx-mode-map (kbd "zz") #'jinx-correct))

(use-package rainbow-mode
  :hook (css-mode html-mode sass-mode web-mode))

(use-package qml-mode
  :mode "\\.qml\\'"
  :config
  (setq qml-indent-dist 2
        js-indent-level 2))

(use-package vterm :defer t)

(use-package shell-pop
  :bind ("C-c t" . shell-pop)
  :config
  (setopt shell-pop-window-position "bottom"
          shell-pop-full-span nil
          shell-pop-window-size 30
          shell-pop-autocd-to-working-dir nil
          shell-pop-shell-type '("vterm" "*vterm*" (lambda () (vterm)))))

(defvar my/studybar-file (expand-file-name "~/.config/quickshell/emacs/studybar.el"))

(defun my/idle-load (items)
  (when items
    (run-with-idle-timer
     (time-add (or (current-idle-time) 0) 0.5) nil
     (lambda ()
       (let ((item (car items)))
         (with-demoted-errors "Idle load: %S"
           (if (symbolp item) (require item) (load item t t))))
       (my/idle-load (cdr items))))))

(add-hook 'emacs-startup-hook
          (lambda ()
            (my/idle-load (list my/studybar-file
                                'org-roam 'evil-org 'org-modern 'svg-tag-mode))))
