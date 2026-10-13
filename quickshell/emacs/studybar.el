;;; -*- lexical-binding: t; -*-

(require 'server)
(require 'json)
(require 'org)
(require 'org-clock)

(defgroup studybar nil nil
  :group 'org)

(defcustom studybar-qs-config (expand-file-name "~/.config/quickshell") nil
  :type 'directory)

(defcustom studybar-save-after-clock-out t nil
  :type 'boolean)

(defcustom studybar-review-command
  (if (fboundp 'my/org-srs-review) #'my/org-srs-review #'org-srs-review-start) nil
  :type 'function)

(defcustom studybar-review-clock
  (cons (locate-user-emacs-file "todos.org") "Flashcards") nil
  :type '(choice (const :tag "Don't clock reviews" nil)
                 (cons file string)))

(unless (server-running-p)
  (server-start))

(defvar studybar--seq 0)

(defvar studybar--push-timer nil)

(defvar studybar--clock-before-review nil)

(defun studybar--state ()
  (let ((state (bound-and-true-p org-pomodoro-state))
        (end (bound-and-true-p org-pomodoro-end-time)))
    `((state . ,(if state (substring (symbol-name state) 1) "none"))
      (end . ,(if end (float-time end) 0))
      (count . ,(or (bound-and-true-p org-pomodoro-count) 0))
      (frequency . ,(or (bound-and-true-p org-pomodoro-long-break-frequency) 4))
      (clocking . ,(if (org-clocking-p) t :json-false))
      (task . ,(or (and (org-clocking-p) org-clock-current-task) ""))
      (clockStart . ,(if (org-clocking-p) (float-time org-clock-start-time) 0))
      (file . ,(or (and (org-clocking-p) (buffer-file-name (org-clocking-buffer))) ""))
      (reviewClock . ,(if studybar--clock-before-review t :json-false)))))

(defun studybar-push (&optional event)
  (setq studybar--seq (1+ studybar--seq))
  (let ((json (json-encode `((event . ,(or event "update"))
                             (seq . ,studybar--seq)
                             ,@(studybar--state)))))
    (ignore-errors
      (call-process "qs" nil 0 nil "ipc" "--path" studybar-qs-config
                    "call" "study" "update" json)))
  t)

(defun studybar-push-soon (&rest _)
  (unless studybar--push-timer
    (setq studybar--push-timer
          (run-at-time 0.1 nil (lambda ()
                                 (setq studybar--push-timer nil)
                                 (studybar-push))))))

(defun studybar--save-clocked-buffer ()
  (when (and studybar-save-after-clock-out buffer-file-name)
    (let ((buffer (current-buffer)))
      (run-at-time 0.2 nil (lambda ()
                             (when (and (buffer-live-p buffer) (buffer-modified-p buffer))
                               (with-current-buffer buffer
                                 (save-buffer)))
                             (studybar-push-soon))))))

(dolist (hook '(org-clock-in-hook org-clock-out-hook org-clock-cancel-hook))
  (add-hook hook #'studybar-push-soon))
(add-hook 'org-clock-out-hook #'studybar--save-clocked-buffer)

(with-eval-after-load 'org-pomodoro
  (dolist (hook '(org-pomodoro-started-hook org-pomodoro-finished-hook
                  org-pomodoro-killed-hook org-pomodoro-break-finished-hook
                  org-pomodoro-overtime-hook))
    (add-hook hook #'studybar-push-soon)))

(defun studybar--cards-changed ()
  (studybar-push "cards"))

(add-hook 'kill-emacs-hook (lambda () (studybar-push "bye")))
(if after-init-time
    (studybar-push "hello")
  (add-hook 'emacs-startup-hook (lambda () (studybar-push "hello"))))

(defun studybar--review-heading ()
  (pcase-let ((`(,file . ,heading) studybar-review-clock))
    (with-current-buffer (find-file-noselect file)
      (org-with-wide-buffer
       (or (org-find-exact-headline-in-buffer heading)
           (progn
             (goto-char (point-max))
             (unless (bolp) (insert "\n"))
             (insert "* " heading "\n")
             (copy-marker (line-beginning-position 0))))))))

(defun studybar--review-clocked-p ()
  (and studybar-review-clock
       (org-clocking-p)
       (equal org-clock-current-task (cdr studybar-review-clock))
       (file-equal-p (buffer-file-name (org-clocking-buffer))
                     (car studybar-review-clock))))

(defun studybar--review-started ()
  (when (and studybar-review-clock (not (studybar--review-clocked-p)))
    (setq studybar--clock-before-review
          (if (org-clocking-p) (copy-marker org-clock-hd-marker) t))
    (org-with-point-at (studybar--review-heading)
      (org-clock-in))))

(defun studybar--review-ended ()
  (let ((before studybar--clock-before-review))
    (setq studybar--clock-before-review nil)
    (when (and before (studybar--review-clocked-p))
      (if (and (markerp before) (marker-buffer before))
          (org-with-point-at before
            (org-clock-in))
        (org-clock-out)))))

(defun studybar--review-quit (&rest _)
  (unless (org-srs-reviewing-p)
    (studybar--review-ended)))

(with-eval-after-load 'org-srs
  (add-hook 'org-srs-review-after-rate-hook #'studybar--cards-changed 90)
  (add-hook 'org-srs-review-start-hook #'studybar--review-started)
  (add-hook 'org-srs-review-finish-hook #'studybar--review-ended)
  (advice-add 'org-srs-review-quit :after #'studybar--review-quit))

(defun studybar--find (file heading)
  (or (org-find-exact-headline-in-buffer heading (find-file-noselect file))
      (user-error "Study bar: no heading %S in %s" heading file)))

(defun studybar--capture-frame-p (&optional frame)
  (member "studybar-capture" (list (frame-parameter frame 'name)
                                   (frame-parameter frame 'title))))

(defun studybar--frame ()
  (or (car (filtered-frame-list (lambda (f) (and (frame-visible-p f)
                                                 (display-graphic-p f)
                                                 (not (studybar--capture-frame-p f))))))
      (make-frame)))

(defun studybar-start (file heading)
  (require 'org-pomodoro)
  (when (org-pomodoro-active-p)
    (org-pomodoro-kill))
  (when (and org-pomodoro-last-clock-in org-pomodoro-expiry-time (org-pomodoro-expires-p))
    (setq org-pomodoro-count 0))
  (setq org-pomodoro-last-clock-in (current-time))
  (org-with-point-at (studybar--find file heading)
    (org-clock-in))
  (org-pomodoro-start :pomodoro)
  t)

(defun studybar-resume ()
  (require 'org-pomodoro)
  (setq org-pomodoro-last-clock-in (current-time))
  (org-clock-in-last)
  (org-pomodoro-start :pomodoro)
  t)

(defun studybar-switch (file heading)
  (org-with-point-at (studybar--find file heading)
    (org-clock-in))
  t)

(defun studybar-stop ()
  (when (and (featurep 'org-pomodoro) (org-pomodoro-active-p))
    (org-pomodoro-kill))
  (when (org-clocking-p)
    (org-clock-out))
  t)

(defun studybar-open (file heading)
  (let ((marker (studybar--find file heading)))
    (select-frame-set-input-focus (studybar--frame))
    (pop-to-buffer-same-window (marker-buffer marker))
    (goto-char marker)
    (org-reveal)
    (org-fold-show-entry))
  t)

(defun studybar-agenda ()
  (select-frame-set-input-focus (studybar--frame))
  (org-agenda nil "a")
  t)

(defun studybar-review ()
  (select-frame-set-input-focus (studybar--frame))
  (run-at-time 0 nil (lambda ()
                       (set-buffer (window-buffer))
                       (condition-case err
                           (call-interactively studybar-review-command)
                         (user-error (message "%s" (error-message-string err))))))
  t)

(defun studybar-capture ()
  (let ((frame (or (seq-find #'studybar--capture-frame-p (frame-list))
                   (make-frame '((name . "studybar-capture") (width . 90) (height . 20))))))
    (select-frame-set-input-focus frame)
    (run-at-time 0 nil (lambda ()
                         (select-frame-set-input-focus frame)
                         (condition-case nil
                             (org-capture)
                           ((error quit) (studybar--close-capture-frame frame))))))
  t)

(defun studybar--close-capture-frame (&optional frame)
  (let ((frame (or frame (selected-frame))))
    (if (or (daemonp)
            (seq-some (lambda (f) (and (not (eq f frame)) (frame-visible-p f)))
                      (frame-list)))
        (delete-frame frame)
      (save-some-buffers t)
      (kill-emacs))))

(defun studybar--capture-done ()
  (when (studybar--capture-frame-p)
    (studybar--close-capture-frame)))

(add-hook 'org-capture-after-finalize-hook #'studybar--capture-done)

(provide 'studybar)
