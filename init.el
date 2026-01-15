;;; init --- My emacs config -*- lexical-binding: t; coding: utf-8; -*-

;;; Commentary:
;; - elpaca
;; - most custom stuff in use-package :custom

;;; Code:
(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))
(elpaca elpaca-use-package (elpaca-use-package-mode))


;; begin emacs
(use-package emacs
  :demand t
  :bind
    ()
  :custom
    (bidi-inhibit-bpa t) ;; performance
    (blink-cursor-mode nil)
    (column-number-mode t)
    (enable-recursive-minibuffers t) ;; minibuffer
    (fast-but-imprecise-scrolling t) ;; performance
    (ffap-machine-p-known 'reject) ;; performance
    (fill-column 120)
    (frame-inhibit-implied-resize t) ;; performance
    (global-auto-revert-mode t)
    (global-hl-line-mode t) ;; highlight
    (indent-tabs-mode nil) ;; spaces instead of tabs
    (indicate-empty-lines t) ;; End of buffer behavior
    (inhibit-compacting-font-caches t) ;; performance
    (inhibit-startup-screen t)
    (initial-scratch-message "")
    (kill-whole-line t)
    (line-number-mode t) ;; highlight
    (menu-bar-mode nil)
    (minibuffer-depth-indicate-mode t) ;; minibuffer
    (mouse-yank-at-point t) ;; Copy and Paste
    (ns-alternate-modifier 'none)
    (ns-antialias-text t)
    (ns-auto-hide-menu-bar nil)
    (ns-command-modifier 'meta)
    (pgtk-wait-for-event-timeout 0.001) ;; performance
    (process-adaptive-read-buffering nil) ;; performance
    (read-process-output-max (* 1024 1024)) ;; performance
    (redisplay-skip-fontification-on-input t) ;; performance
    (ring-bell-function 'ignore)
    (save-interprogram-paste-before-kill t) ;; Copy and Paste
    (select-enable-clipboard t) ;; Copy and Paste
    (select-enable-primary t) ;; Copy and Paste
    (show-paren-mode t)
    (tool-bar-mode nil)
    (tooltip-mode nil) ;; Display tooltips in echo area
    (use-short-answers t)
    (visible-bell nil)
    (truncate-lines t)


  :config
      (kill-buffer "*scratch*")
      (add-to-list 'initial-frame-alist '(font . "Iosevka Term-19"))
      (add-to-list 'default-frame-alist '(font . "Iosevka Term-19"))

      ;; Disable bidi (might improve display performance)
      (setq-default bidi-paragraph-direction 'left-to-right
                    bidi-paragraph-direction 'left-to-right)

      (defvar emacs-var-directory (expand-file-name "var/" user-emacs-directory) "Base directory for saving data")
      (setq auto-save-list-file-prefix (expand-file-name "auto-save/save-" emacs-var-directory))
      (setq backup-directory-alist `(("." . ,(concat emacs-var-directory "backup"))))

      ;; Customize
      (setq custom-file (expand-file-name "custom.el" user-emacs-directory))
      (load custom-file t)
      ;; Enable disabled commands
      (setq disabled-command-function nil)

      ;; Ui
      (put 'inhibit-startup-echo-area-message 'saved-value t)
      (setq
        initial-scratch-message ";; Welcome back!!!\n\n"
        inhibit-startup-message t
        inhibit-startup-echo-area-message (user-login-name)
        use-dialog-box nil
        x-gtk-use-system-tooltips nil
        scroll-preserve-screen-position 1
        scroll-margin 3
        scroll-conservatively 101
        inhibit-x-resources t
        frame-resize-pixelwise t)


  ;; Mouse
  (setq mouse-drag-and-drop-region-cross-program t
        mouse-drag-and-drop-region-scroll-margin t
        dnd-indicate-insertion-point t
        dnd-scroll-margin t)


  ;; Popup windows # TODO
  (setq buffer-quit-function #'akermu/quit-window-dwim)
  (defvar akermu/popup-buffer-regexp (rx bos (or "*compilation*"
                                                 " *undo-tree*"
                                                 "*Occur*"
                                                 "*grep*"
                                                 "*Warnings*"
                                                 "*Agenda Commands*"
                                                 "*Compile-Log*"
                                                 " *Org todo*"
                                                 "*Org Select*"
                                                 "*Org Clock*"
                                                 "*Org Links*"
                                                 " *Agenda Commands*"
                                                 "sendmail errors"
                                                 "*GHC Error*"
                                                 "*rustfmt-error*"
                                                 "*xref*"
                                                 "*ggtags-global*")
                                         eos))

  (add-to-list 'display-buffer-alist
               `(,akermu/popup-buffer-regexp
                 (display-buffer-reuse-window
                  display-buffer-in-side-window)
                 (side            . bottom)
                 (window-height   . 0.4)))

  (add-to-list 'display-buffer-alist
               '((major-mode . grep-mode)
                 (display-buffer-reuse-window
                  display-buffer-in-side-window)
                 (side            . bottom)
                 (window-height   . 0.4)))

  (add-to-list 'display-buffer-alist
               '((lambda (&rest _)
                   (eq this-command 'compile-goto-error))
                 (display-buffer-reuse-window
                  display-buffer-use-some-window)
                 (inhibit-same-window . t)))

  (add-to-list 'display-buffer-alist
               `(,(rx bos "CAPTURE-" (* ascii) ".org" eos)
                 (display-buffer-reuse-window
                  display-buffer-in-side-window)
                 (side            . bottom)
                 (window-height   . 0.5)))

  ;; Make other-window not repeatable
  (setq other-window-repeat-map nil)

  (defun akermu/quit-window-dwim ()
    "Quit side windows of the current frame."
    (interactive)
    (if (and (boundp 'eldoc-box--frame) (frame-visible-p eldoc-box--frame))
        (eldoc-box-quit-frame)
      (let (deleted)
        (dolist (window (window-at-side-list) deleted)
          (when (eq 0 (string-match akermu/popup-buffer-regexp
                                    (buffer-name (window-buffer window))))
            (setq deleted t)
            (delete-window window)))
        (unless deleted
          (delete-other-windows))))
    )

  ;; auto update recent files
  (run-at-time t (* 5 60) 'recentf-save-list)

  ;; maximize window on startup
  (toggle-frame-maximized)

  (defun smarter-move-beginning-of-line (arg)
    "Move point back to indentation or beginning of line.
Move point to the first non-whitespace character on this line.
If point is already there, move to the beginning of the line.
Effectively toggle between the first non-whitespace character and
the beginning of the line.
If ARG is not nil or 1, move forward ARG - 1 lines first.  If
point reaches the beginning or end of the buffer, stop there."
    (interactive "^p")
    (setq arg (or arg 1))
    (when (/= arg 1)
      (let ((line-move-visual nil))
        (forward-line (1- arg))))
    (let ((orig-point (point)))
      (back-to-indentation)
      (when (= orig-point (point))
        (move-beginning-of-line 1))))
  (global-set-key [remap move-beginning-of-line] 'smarter-move-beginning-of-line)
  (defun open-init-file ()
    "Open the emacs init file"
    (interactive)
    (find-file user-init-file)
    )
  )
;; end emacs

(use-package files
  :ensure nil
  :custom
    (require-final-newline t)
    (find-file-visit-truename t)
  )

(use-package calendar
  :ensure nil
  :custom
    (calendar-date-style 'iso)
    (calendar-intermonth-header "KW")
    (calendar-intermonth-text
     '(propertize
       (format "%2d"
               (car
                (calendar-iso-from-absolute
                 (calendar-absolute-from-gregorian (list month day year)))))
       'font-lock-face 'calendar-iso-week-face))
    (calendar-today-marker 'calendar-today)
    (calendar-today-visible-hook '(calendar-mark-today))
  )

(use-package zenburn-theme
  :ensure t
  :demand t
  :config (load-theme 'zenburn t)
  )

(use-package transient
  :ensure t
  :demand t
  )

(use-package magit
  :ensure t
  :demand t
  )

(use-package git-timemachine
  :ensure (git-timemachine :type git :host nil :repo "https://codeberg.org/pidu/git-timemachine")
  :after (magit)
  )

(add-hook 'prog-mode-hook (lambda () (setq show-trailing-whitespace t))
  )

(use-package exec-path-from-shell
  :ensure t
  :demand t
  :config
    (exec-path-from-shell-initialize)
  )

(use-package rust-mode
  :ensure t
  :after (eglot)
  :custom
    (exec-path-from-shell-shell-name
      (pcase system-type
        ('darwin "/opt/homebrew/bin/fish")
        )
      )
  :config
    (add-to-list 'eglot-server-programs
		 (cons 'rust-mode (list (format "%s/.cargo/bin/rust-analyzer" (getenv "HOME")) :initializationOptions (:check (:command "clippy"))))
      )
  )

;; configure org mode
(use-package org-mode
  :ensure nil ;; use builtin
  :hook (org-mode . turn-on-auto-fill)
  )

(use-package org-mode-config
  :after (org-mode)
  :config
    (defun org-tel-export (link description format)
      "Export a tel LINK with DESCRIPTION from Org files to FORMAT."
      (let ((desc (or description link)))
        (pcase format
          (`html (format "<a target=\"_blank\" href=\"tel:%s\">%s</a>" link desc))
          )
        )
      )
    (org-babel-do-load-languages 'org-babel-load-languages
                                 '(
                                   (shell . t)
                                   (dot . t)
                                   )
      )
    (org-link-set-parameters "tel" :export #'org-tel-export
      )
  )

(use-package undo-tree
  :ensure t
  :config
    (global-undo-tree-mode)
  :custom
  (undo-tree-history-directory-alist
    (list
      '(".*" . "~/tmp/undo-tree"))
    )
  )

(use-package tff
  :ensure (tff :type git :host github :repo "gizmomogwai/tff")
  :config (global-set-key (kbd "C-1") 'tff))

;; dont like how the fuzzy searching works here
;;(use-package selectrum
;;  :ensure t
;;  :config
;;  (selectrum-mode +1)
;;  )

(use-package helm
  :ensure t
  :config
    (helm-mode +1)
    (global-set-key (kbd "C-x C-f") #'helm-find-files)
    (global-set-key (kbd "M-x") #'helm-M-x)
    ;; show recentf if emacs is started without arguments
    (if (< (length command-line-args) 2)
        (helm-recentf))
    )

(use-package helm-flymake
  :ensure (helm-flymake :type git :host github :repo "emacs-helm/helm-flymake")
  :bind (
     ([f7] . helm-flymake)
   )
  )
(use-package helm-projectile
  :ensure t)

;; ctrl-w catches the current line
(use-package whole-line-or-region
  :ensure t
  :config (whole-line-or-region-global-mode))

;; nice to see some graphs
(use-package eplot
  :ensure (eplot :type git :host github :repo "larsmagne/eplot")
  )

;; basics like tabs, spaces for editing
(use-package editorconfig
  :ensure t
  :config (editorconfig-mode 1))

;; emacs package dev
(use-package package-lint
  :ensure t)
(use-package ecukes
  :ensure t)


(use-package key-chord
  :ensure t
  :config
    ;;(key-chord-define-global "FF" 'helm-projectile)
    (key-chord-define-global "uu" 'undo-tree-visualize)
    (key-chord-define-global "xx" 'helm-M-x)
    (key-chord-define-global "BB" 'beginning-of-buffer)
    (key-chord-define-global "BE" 'end-of-buffer)
    (key-chord-define-global "bb" 'helm-mini)
    (key-chord-define-global "BR" 'kill-buffer)
    (key-chord-define-global "bw" 'save-buffer)
    (key-chord-define-global "CC" 'comment-line)
    (key-chord-define-global "GS" 'magit-status)
    (key-chord-define-global "GG" 'goto-line)
    (key-chord-define-global "LL" 'projectile-layout-project)
    (key-chord-define-global "yy" 'helm-show-kill-ring)
    (key-chord-define-global "TT" 'tff)
    (key-chord-mode 1)
  )

(use-package move-text
  :ensure t
  :config (move-text-default-bindings)
  )

;; goto last change
(use-package goto-chg
  :ensure t)

(use-package which-key
  :ensure t
  :config (which-key-mode 1)
  )

(use-package deadgrep
  :ensure (deadgrep :type git :host github :repo "Wilfred/deadgrep")
  )

(use-package projectile
  :ensure t
  :config
    (projectile-mode 1)
    (projectile-register-project-type
      'dlang
      '("dub.sdl")
        :compile "~/bin/d build"
        :test "~/bin/d test && ~/bin/d run dscanner -- --errorFormat=digitalmars --styleCheck"
        :run "~/bin/d run"
      )
  )

;; TODO
(require 'compile)
(add-to-list 'compilation-error-regexp-alist-alist
             '(d-scanner
               "\\(.*?\\)(\\(.*?\\):\\(.*?\\))\\[\\(.*?\\)\\]:"
               1 2 3 2))
;; TODO

(use-package company
  :ensure t
  :config (global-company-mode 1)
  )

(use-package json-mode
  :ensure t
  )


(use-package haml-mode
  :ensure t
  )

(use-package yaml-mode
  :ensure t
  )

(use-package markdown-mode
  :ensure t
  )

(use-package markdown-toc
  :ensure t
  )

(use-package plantuml-mode
  :ensure t
  :config
    (plantuml-set-output-type "png")
  )

(use-package graphviz-dot-mode
  :ensure t
  )

(use-package ztree
  :ensure t)

;;(use-package yasnippet-snippets
;;  :straight t)
;;
;;(use-package yasnippet
;;  :straight t
;;  :config
;;      (yas-global-mode 1)
;;  )
;;

(use-package hydra
  :ensure t)

(use-package projectile-hydra
  :preface (provide 'projectile-hydra)
  :after (hydra projectile key-chord magit deadgrep)
  :config
    (defhydra projectile-hydra (:columns 4)
      "
Project %(projectile-project-root)" ;; initial newline is needed for %() to work (see https://github.com/abo-abo/hydra?tab=readme-ov-file#awesome-docstring)
      ("b" projectile-compile-project "Build")
      ("c" projectile-invalidate-cache "Clear Cache")
      ("f" projectile-find-file "Find File")
      ("g" deadgrep "Ripgrep")
      ("i" projectile-project-info "Info")
      ("k" projectile-kill-buffers "Kill Buffers")
      ("l" projectile-layout-project "Layout")
      ("o" projectile-multi-occur "Multi Occur")
      ("q" nil "Cancel" color: blue)
      ("r" projectile-run-project "Run")
      ("s" magit-status "Magit")
      ("t" projectile-test-project "Test")
      )
    (key-chord-define-global "PP" 'projectile-hydra/body)
  )

(use-package yafolding
  :ensure (yafolding :type git :host github :repo "vindarel/yafolding.el")
  :after (hydra)
  :config
    (defun projectile-layout-project ()
      "Format a project."
      (interactive)
      (message "layouting project of type %s in %s" (projectile-project-type) (projectile-project-root))
      (pcase (projectile-project-type)
        ('dlang (shell-command "~/bin/d run dfmt -- -i . && ~/bin/d run importsort-d -- --ignore-case --inplace --recursive ."))
        )
      )
    (defhydra yafolding-hydra (:color blue :columns 3)
      "Fold code based on indentation levels."
      ("t" yafolding-toggle-element "toggle element")
      ("s" yafolding-show-element "show element")
      ("h" yafolding-hide-element "hide element")
      ("T" yafolding-toggle-all "toggle all")
      ("S" yafolding-show-all "show all")
      ("H" yafolding-hide-all "hide all")
      ("p" yafolding-hide-parent-element "hide parent element")
      ("i" yafolding-get-indent-level "get indent level")
      ("g" yafolding-go-parent-element "go parent element"))
    (global-set-key (kbd "C-c f") 'yafolding-hydra/body)
    )

;; begin dlang
(c-add-style "my-d-mode"
  '("cc-mode"
     (c-basic-offset . 4)
     (c-offsets-alist
       (arglist-intro . +)
       (arglist-close . 0)
       (substatement-open . 0)
       (statement-cont . +)
       (inline-open . 0)
       (label . +)
       )))

(defun my-d-mode-setup ()
  "Setup indent according to dfmt's defaults."
  (interactive)
  (message "setting up d-mode indents")
  (c-set-style "my-d-mode")
  )

(use-package d-mode
  :ensure t
  :after (eglot)
  :hook
    (d-mode . my-d-mode-setup)
  :config
    (add-to-list 'eglot-server-programs
                 (cons 'd-mode (list (format "%s/.code-d/bin/serve-d" (getenv "HOME"))))
      )
  )
;; end dlang

(use-package flycheck
  :ensure t
  :config (global-flycheck-mode 1)
  :after (exec-path-from-shell)
  )

(use-package flycheck-pos-tip
  :ensure t
  :config
    (with-eval-after-load 'flycheck (flycheck-pos-tip-mode))
  )

(provide 'init)
;;; init.el ends here

