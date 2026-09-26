;;; early-init --- early init emacs file  -*- lexical-binding: t; -*-

;;; Commentary:
;;; Code:

(message "early-init.el")

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(setq server-client-instructions nil)
(setq frame-inhibit-implied-resize t)

(setq package-enable-at-startup nil)
(setq use-package-verbose t)
(setq use-package-compute-statistics t)
(add-to-list 'initial-frame-alist '(font . "Iosevka Term-19"))
(add-to-list 'default-frame-alist '(font . "Iosevka Term-19"))

;; Defer GC during startup, restore afterwards
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)
(add-hook 'emacs-startup-hook
  (lambda ()
    (setq gc-cons-threshold (* 16 1024 1024)
          gc-cons-percentage 0.1)))

;; Disable file-name-handler during startup (speeds up file loading)
(defvar my/file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
  (lambda ()
    (setq file-name-handler-alist my/file-name-handler-alist)))

(provide 'early-init)
;;; early-init.el ends here

