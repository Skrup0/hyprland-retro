;;; -*- lexical-binding: t; -*-

(require 'dashboard)

(defvar dashboard-study-goal 240)

(defvar dashboard-scan-script (expand-file-name "~/.config/quickshell/scripts/org-scan.sh"))

(defface dashboard-bios-dim '((t :inherit font-lock-comment-face :slant normal)) nil
  :group 'dashboard)
(defface dashboard-bios-title '((t :inherit font-lock-function-name-face)) nil
  :group 'dashboard)
(defface dashboard-bios-value '((t :inherit font-lock-keyword-face :weight bold)) nil
  :group 'dashboard)
(defface dashboard-bios-warn '((t :inherit font-lock-builtin-face)) nil
  :group 'dashboard)

(defconst dashboard--bios-width 58)

(defun dashboard--bios-row (label value &optional face field)
  (let* ((lead (- 24 (length label)))
         (room (- dashboard--bios-width 2 24 1))
         (value (truncate-string-to-width value room nil ?\s)))
    (concat (propertize "│  " 'face 'dashboard-bios-dim)
            label " "
            (propertize (make-string (- lead 2) ?.) 'face 'dashboard-bios-dim) " "
            (propertize value 'face (or face 'dashboard-bios-value) 'dashboard-bios field)
            (propertize " │" 'face 'dashboard-bios-dim) "\n")))

(defun dashboard--bios-blank ()
  (propertize (concat "│" (make-string dashboard--bios-width ?\s) "│\n")
              'face 'dashboard-bios-dim))

(defun dashboard--os ()
  (with-temp-buffer
    (or (and (ignore-errors (insert-file-contents "/etc/os-release"))
             (re-search-forward "^PRETTY_NAME=[\"']?\\([^\"'\n]*\\)" nil t)
             (match-string 1))
        "GNU/Linux")))

(defun dashboard-insert-bios ()
  (let* ((title (format " GNU EMACS %s " emacs-version))
         (head "Welcome back!")
         (system (format "%s %s" (dashboard--os) (car (split-string system-configuration "-"))))
         (start (point)))
    (insert
     (propertize "┌─" 'face 'dashboard-bios-dim)
     (propertize title 'face 'dashboard-bios-title)
     (propertize (concat (make-string (- dashboard--bios-width (length title) 1) ?─) "┐\n")
                 'face 'dashboard-bios-dim)
     (dashboard--bios-blank)
     (propertize "│  " 'face 'dashboard-bios-dim)
     (propertize head 'face 'dashboard-bios-title)
     (string-pad system (- dashboard--bios-width 4 (length head)) nil t)
     (propertize "  │\n" 'face 'dashboard-bios-dim)
     (dashboard--bios-blank)
     (dashboard--bios-row "Native Compilation" (if (native-comp-available-p) "ENABLED" "DISABLED"))
     (dashboard--bios-row "Packages" (format "%d LOADED" (length package-activated-list)))
     (dashboard--bios-row "Startup Time" (or (emacs-init-time "%.2fs") "..."))
     (dashboard--bios-row "Flashcards Due" "DETECTING..." 'dashboard-bios-dim 'cards)
     (dashboard--bios-row "Studied Today" "DETECTING..." 'dashboard-bios-dim 'study)
     (dashboard--bios-row "Study Streak" "DETECTING..." 'dashboard-bios-dim 'streak)
     (dashboard--bios-row "Open Tasks" "DETECTING..." 'dashboard-bios-dim 'tasks)
     (dashboard--bios-blank)
     (propertize (concat "└" (make-string dashboard--bios-width ?─) "┘\n")
                 'face 'dashboard-bios-dim))
    (dashboard-center-text start (point))
    (run-with-timer 0.1 nil #'dashboard--bios-scan)))

(defun dashboard--bios-set (field value face)
  (when-let* ((buffer (get-buffer dashboard-buffer-name)))
    (with-current-buffer buffer
      (save-excursion
        (goto-char (point-min))
        (when-let* ((match (text-property-search-forward 'dashboard-bios field t)))
          (let* ((beg (prop-match-beginning match))
                 (end (prop-match-end match))
                 (new (apply #'propertize
                             (truncate-string-to-width value (- end beg) nil ?\s)
                             (text-properties-at beg)))
                 (inhibit-read-only t))
            (put-text-property 0 (length new) 'face face new)
            (delete-region beg end)
            (goto-char beg)
            (insert new)))))))

(defun dashboard--streak (clocked)
  (let* ((now (decode-time))
         (noon (encode-time (list 0 0 12 (decoded-time-day now) (decoded-time-month now)
                                  (decoded-time-year now) nil -1 nil)))
         (studied (lambda (days-ago)
                    (>= (or (alist-get (intern (format-time-string
                                                "%F" (time-subtract noon (* days-ago 86400))))
                                       clocked)
                            0)
                        dashboard-study-goal)))
         (today (funcall studied 0))
         (days-ago (if today 0 1)))
    (while (funcall studied days-ago)
      (setq days-ago (1+ days-ago)))
    (cons (if today days-ago (1- days-ago)) today)))

(defun dashboard--tasks-text (tasks)
  (let* ((today (format-time-string "%F"))
         (late 0) (due 0))
    (seq-doseq (task tasks)
      (when-let* ((deadline (alist-get 'deadline task)))
        (let ((day (format-time-string "%F" deadline)))
          (cond ((string< day today) (setq late (1+ late)))
                ((string= day today) (setq due (1+ due)))))))
    (list (concat (format "%d OPEN" (length tasks))
                  (and (> late 0) (format ", %d LATE" late))
                  (and (> due 0) (format ", %d DUE TODAY" due)))
          (if (> (+ late due) 0) 'dashboard-bios-warn 'dashboard-bios-value))))

(defun dashboard--bios-fill (data)
  (let* ((cards (alist-get 'cards data))
         (due (alist-get 'review cards))
         (minutes (alist-get (intern (format-time-string "%F")) (alist-get 'clocked data)))
         (hm (lambda (m) (format "%dh%02d" (/ m 60) (% m 60)))))
    (if (not cards)
        (dashboard--bios-set 'cards "NOT FOUND" 'dashboard-bios-dim)
      (dashboard--bios-set 'cards (format "%d OF %d" due (alist-get 'total cards))
                           (if (> due 0) 'dashboard-bios-warn 'dashboard-bios-value)))
    (if (not data)
        (dolist (field '(study streak tasks))
          (dashboard--bios-set field "NOT FOUND" 'dashboard-bios-dim))
      (dashboard--bios-set 'study (format "%s / %s" (funcall hm (or minutes 0))
                                          (funcall hm dashboard-study-goal))
                           (if (>= (or minutes 0) dashboard-study-goal)
                               'dashboard-bios-value 'dashboard-bios-warn))
      (let ((streak (dashboard--streak (alist-get 'clocked data))))
        (dashboard--bios-set 'streak (format "%d DAY%s" (car streak) (if (= (car streak) 1) "" "S"))
                             (if (cdr streak) 'dashboard-bios-value 'dashboard-bios-warn)))
      (apply #'dashboard--bios-set 'tasks (dashboard--tasks-text (alist-get 'tasks data))))))

(defun dashboard--bios-scan ()
  (if (not (file-readable-p dashboard-scan-script))
      (dashboard--bios-fill nil)
    (let ((out (generate-new-buffer " *dashboard-bios-scan*"))
          (err (generate-new-buffer " *dashboard-bios-scan-err*")))
      (make-process
       :name "dashboard-bios-scan" :buffer out :stderr err :noquery t :connection-type 'pipe
       :command (list "bash" dashboard-scan-script)
       :sentinel (lambda (proc _event)
                   (unless (process-live-p proc)
                     (dashboard--bios-fill
                      (and (eq (process-exit-status proc) 0)
                           (with-current-buffer out
                             (goto-char (point-min))
                             (ignore-errors
                               (json-parse-buffer :object-type 'alist :null-object nil)))))
                     (let ((kill-buffer-query-functions nil))
                       (kill-buffer out)
                       (kill-buffer err))))))))

(defun dashboard-center-vertically ()
  (let ((half (/ (count-lines (point-min) (point-max)) 2.0)))
    (save-excursion
      (goto-char (point-min))
      (insert "\n"
              (propertize " " 'display `(space :ascent 100
                                               :height (- (0.5 . text) (,(1+ half) . height))))
              "\n"))))

(setq dashboard-startupify-list '(dashboard-insert-bios
                                  dashboard-insert-newline
                                  dashboard-insert-footer
                                  dashboard-center-vertically)
      dashboard-center-content t)
