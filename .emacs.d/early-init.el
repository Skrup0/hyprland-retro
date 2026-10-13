;;; -*- lexical-binding: t; -*-

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024)
                  gc-cons-percentage 0.1)))
(add-function :after after-focus-change-function
              (lambda () (unless (frame-focus-state) (garbage-collect))))

(let ((handlers file-name-handler-alist))
  (setq file-name-handler-alist nil)
  (add-hook 'emacs-startup-hook
            (lambda ()
              (setq file-name-handler-alist
                    (delete-dups (append file-name-handler-alist handlers))))))

(setq-default inhibit-redisplay t
              inhibit-message t)
(add-hook 'window-setup-hook
          (lambda ()
            (setq-default inhibit-redisplay nil
                          inhibit-message nil)
            (redisplay)))

(setq frame-inhibit-implied-resize t
      frame-resize-pixelwise t)
(setq default-frame-alist
      (append '((menu-bar-lines . 0)
                (tool-bar-lines . 0)
                (vertical-scroll-bars)
                (horizontal-scroll-bars)
                (left-fringe . 8)
                (right-fringe . 0)
                (alpha-background . 70)
                (font . "Terminus-12:weight=bold"))
              default-frame-alist))
(setq menu-bar-mode nil
      tool-bar-mode nil
      scroll-bar-mode nil)

(setq package-quickstart t)

(setq inhibit-startup-screen t
      inhibit-startup-buffer-menu t
      initial-scratch-message nil)

(when (featurep 'native-compile)
  (setq native-comp-async-report-warnings-errors 'silent
        native-comp-jit-compilation t))
