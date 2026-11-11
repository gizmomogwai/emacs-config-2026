;;; init --- My emacs config -*- lexical-binding: t; coding: utf-8; -*-

;;; Commentary:
;; - elpaca
;; - most custom stuff in use-package :custom

;;; Code:
;; start elpaca installer from https://github.com/progfolio/elpaca#installer
(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                        :ref nil :depth 1 :inherit ignore
                        :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                        :build (:not elpaca-activate)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
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
;; end elpaca installer from https://github.com/progfolio/elpaca#installer
(setq use-package-verbose t)
(setq use-package-compute-statistics t)

(require 'cl-lib)

(elpaca elpaca-use-package (elpaca-use-package-mode))

;; begin emacs
(use-package emacs
  :demand t

  :bind (
          ([f7] . consult-flycheck)
          ([remap move-beginning-of-line] . smarter-move-beginning-of-line)
          )
  
  :custom-face
  (fill-column-indicator ((t (:weight semilight :foreground "#773838"))))

  :custom
  ;; vertico
  (context-menu-mode t)
  (enable-recursive-minibuffers t)
  (read-extended-command-predicate #'command-completion-default-include-p)
  (minibuffer-prompt-properties
    '(read-only t cursor-intangible t face minibuffer-prompt))
  (read-file-name-completion-ignore-case t)
  (read-buffer-completion-ignore-case t)
  (completion-ignore-case t)
  ;; vertico end
  (bidi-inhibit-bpa t) ;; performance
  (blink-cursor-mode nil)
  (column-number-mode t)
  (display-fill-column-indicator t)
  (display-fill-column-indicator-character ?|)
  (enable-recursive-minibuffers t) ;; minibuffer
  (fast-but-imprecise-scrolling t) ;; performance
  (ffap-machine-p-known 'reject) ;; performance
  (fill-column 120)
  (frame-inhibit-implied-resize t) ;; performance
  (global-auto-revert-mode t)
  (global-display-fill-column-indicator-mode t)
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

  :hook
  (elpaca-after-init . (lambda () (message "Emacs loaded in %s" (emacs-init-time))))
  (prog-mode . (lambda () (setq show-trailing-whitespace t)))

  :config
  (kill-buffer "*scratch*")

  ;; Disable bidi (might improve display performance)
  (setq-default bidi-paragraph-direction 'left-to-right
    bidi-paragraph-direction 'left-to-right)

  (defvar emacs-var-directory (expand-file-name "var/" user-emacs-directory) "Base directory for saving data")
  (setq auto-save-list-file-prefix (expand-file-name "auto-save/save-" emacs-var-directory))
  (setq backup-directory-alist `(("." . ,(concat emacs-var-directory "backup"))))
  (setq lock-file-name-transforms '(("\\`/.*/\\([^/]+\\)\\'" "/var/tmp/\\1" t)))
  ;; Customize: not used, settings live in this file. Throwaway file, so answers like "always allow" don't edit init.el.
  (setq custom-file (make-temp-file "emacs-custom-" nil ".el"))
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

  (defun apply-ansi-colors ()
    "Colorize buffer with ansi escape codes."
    (interactive)
    (ansi-color-apply-on-region (point-min) (point-max)))

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

  (defun switch-to-flycheck-list-errors ()
    "Focus flycheck error list."
    (interactive)
    (flycheck-list-errors)
    (pop-to-buffer "*Flycheck errors*"))

  (defun kill-current-buffer (arg)
    "Kill the current buffer without asking."
    (interactive "P")
    (if arg
      (call-interactively 'kill-buffer)
      (kill-buffer)))

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
  (defun open-init-file ()
    "Open the emacs init file"
    (interactive)
    (find-file user-init-file)
    )
  (defun jj-or-git-status ()
    "Use either `majutsu-log or `magit-status depending if jj is available."
    (interactive)
    (if (locate-dominating-file (buffer-file-name) ".jj") (majutsu-log) (magit-status)))
  ) ;; end emacs

(use-package files
  :ensure nil
  :custom
  (require-final-newline t)

  (find-file-visit-truename t)
  )

(use-package calendar
  :ensure nil
  :defer t
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
  :config (load-theme 'zenburn t))

(use-package transient
  :ensure t
  :defer t
  )

(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status)
  )

(use-package git-timemachine
  :ensure (git-timemachine :type git :host nil :repo "https://codeberg.org/pidu/git-timemachine")
  :after (magit)
  )

;;(use-package exec-path-from-shell
;;  :ensure t
;;  :demand t
;;  :config
;;  (exec-path-from-shell-initialize)
;;  )

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
	  (cons 'rust-mode (lambda (&rest _)
                       ;; pinned toolchains (rust-toolchain.toml) often lack the component; the rustup shim then loops
                       (call-process "rustup" nil nil nil "component" "add" "rust-analyzer")
                       (list "rust-analyzer" :initializationOptions (list :check (list :command "clippy")
                                                                          :cargo (list :features "all")
                                                                          ))))
    )
  )

(use-package eglot-x
  :ensure (eglot-x :type git :host github :repo "nemethf/eglot-x")
  :after (eglot)
  :custom
  (eglot-report-progress nil)
  :config (eglot-x-setup)
  )
(use-package mpc-mode
  :ensure nil ;; builtin
  :bind (
          :map mpc-mode-map
          ([?\r] . mpc-play-at-point)))

;; configure org mode
(use-package org
  :ensure nil
  :hook (org-mode . turn-on-auto-fill)
  :custom
  (org-ditaa-default-exec-mode "ditaa")
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
       (ditaa . t)
       )
    )
  (org-link-set-parameters "tel" :export #'org-tel-export)
  )

(use-package undo-tree
  :ensure t
  :hook (elpaca-after-init . global-undo-tree-mode)
  :custom
  (undo-tree-history-directory-alist
    (list
      '(".*" . "~/tmp/undo-tree"))
    )
  )

(use-package tff
  :ensure (tff :type git :host github :repo "gizmomogwai/tff")
  :bind
  (
    ("C-1" . tff)
    ))

;; https://github.com/minad/vertico
(use-package vertico
  :ensure t
  :custom
   (vertico-scroll-margin 0) ;; Different scroll margin
   (vertico-count 10) ;; Show more candidates
   (vertico-resize nil) ;; Grow and shrink the Vertico minibuffer
   (vertico-cycle t) ;; Enable cycling for `vertico-next/previous'
  :hook (elpaca-after-init . vertico-mode))
(use-package consult
  :ensure t
  :defer t)
(use-package consult-flycheck
  :ensure t
  :after (consult flycheck))
(use-package savehist
  :init
  (savehist-mode))
;; Named workspaces: open buffers and window layout, saved with desktop.el.
;; M-x workspace-save / workspace-open, or from the shell: emacs --workspace NAME
(use-package desktop
  :ensure nil
  :demand t
  :custom
  (desktop-load-locked-desktop 'check-pid)
  (desktop-file-name-format 'tilde) ;; store ~/... paths, portable between machines
  :config
  (defvar workspace-directory (expand-file-name "workspaces/" emacs-var-directory)
    "One subdirectory per workspace, each holding a desktop file.")
  (defvar workspace-current nil "Name of the workspace opened or saved last.")
  (defvar workspace-buffers nil "Buffers restored by the last `workspace-open'.")
  (defvar-local workspace-buffer-comment nil "Comment shown next to this buffer in `workspace-switch-buffer'.")
  (add-to-list 'desktop-locals-to-save 'workspace-buffer-comment)
  ;; Allow it as file-local variable without a prompt, e.g. -*- workspace-buffer-comment: "startup tweaks" -*-
  (put 'workspace-buffer-comment 'safe-local-variable #'stringp)

  (defun workspace-comment-buffer (comment)
    "Set COMMENT for the current buffer. Saved with the next `workspace-save'."
    (interactive (list (read-string "Comment: " workspace-buffer-comment)))
    (setq workspace-buffer-comment (unless (string-empty-p comment) comment)))

  (defun workspace-names ()
    (when (file-directory-p workspace-directory)
      (directory-files workspace-directory nil directory-files-no-dot-files-regexp)))

  (defun workspace-save (name)
    "Save open buffers and window layout as workspace NAME."
    (interactive (list (completing-read "Save workspace: " (workspace-names) nil nil nil nil workspace-current)))
    (let ((directory (file-name-as-directory (expand-file-name name workspace-directory))))
      (make-directory directory t)
      (let ((file (desktop-full-file-name directory)))
        (when (file-exists-p file)
          (unless (or (equal name workspace-current) (yes-or-no-p (format "Overwrite workspace %s? " name)))
            (user-error "Not saved"))
          ;; Replaces desktop's own "Desktop file is more recent" question.
          (setq desktop-file-modtime (file-attribute-modification-time (file-attributes file)))))
      (desktop-save directory t)
      (setq workspace-current name)
      (message "Saved workspace %s" name)))

  (defun workspace-open (name)
    "Open workspace NAME, replacing the current buffers and window layout."
    (interactive (list (completing-read "Open workspace: " (workspace-names) nil t)))
    (let ((directory (file-name-as-directory (expand-file-name name workspace-directory))))
      (unless (file-exists-p (desktop-full-file-name directory))
        (user-error "No workspace named %s" name))
      ;; desktop-read does nothing while this Emacs holds the lock of the desktop loaded last.
      (when desktop-dirname
        (desktop-release-lock))
      ;; Collect exactly the buffers desktop restores, not ones modes create on the side (e.g. *direnv*).
      (let* ((restored nil)
              (collect (lambda (buffer) (when (bufferp buffer) (push buffer restored)) buffer)))
        (advice-add 'desktop-create-buffer :filter-return collect)
        (unwind-protect (desktop-read directory)
          (advice-remove 'desktop-create-buffer collect))
        (setq workspace-buffers (nreverse restored)))
      (setq workspace-current name)
      ;; Timer, so the selector also works at startup and after the name prompt closed.
      (run-at-time 0 nil #'workspace-switch-buffer)))

  (defun workspace-switch-buffer ()
    "Switch to a buffer of the workspace opened last."
    (interactive)
    (let* ((entries
             (mapcar (lambda (buffer)
                       ;; desktop restores its saved value after the file is opened; the file's own comment wins.
                       (cons (or (alist-get 'workspace-buffer-comment (buffer-local-value 'file-local-variables-alist buffer))
                               (buffer-local-value 'workspace-buffer-comment buffer)
                               "")
                         (buffer-name buffer)))
               (seq-filter #'buffer-live-p workspace-buffers)))
            ;; By comment, buffers without one last, then by name.
            (entries (sort entries
                       (lambda (a b)
                         (cond ((string-empty-p (car a)) (and (string-empty-p (car b)) (string< (cdr a) (cdr b))))
                           ((string-empty-p (car b)) t)
                           ((string= (car a) (car b)) (string< (cdr a) (cdr b)))
                           (t (string< (car a) (car b)))))))
            (width (apply #'max 0 (mapcar (lambda (entry) (string-width (car entry))) entries)))
            (candidates
              (mapcar (lambda (entry)
                        (cons (concat (propertize (string-pad (car entry) width) 'face 'font-lock-comment-face)
                                (if (> width 0) "  " "")
                                (cdr entry))
                          (cdr entry)))
                entries))
            ;; Keep this order; vertico would otherwise sort by history and length.
            (table (lambda (string predicate action)
                     (if (eq action 'metadata)
                       '(metadata (display-sort-function . identity) (cycle-sort-function . identity))
                       (complete-with-action action candidates string predicate)))))
      (unless candidates
        (user-error "No buffers from a workspace"))
      (switch-to-buffer
        (cdr (assoc (completing-read (format "Buffer in %s: " workspace-current) table nil t) candidates)))))

  ;; Wait for elpaca, so major modes of restored files are available.
  (add-to-list 'command-switch-alist
    (cons "--workspace"
      (lambda (_switch)
        (let ((name (pop command-line-args-left)))
          (if elpaca-after-init-time
            (workspace-open name)
            (add-hook 'elpaca-after-init-hook (lambda () (workspace-open name)) t)))))))

(use-package recentf
  :hook (elpaca-after-init . recentf-mode)
  :custom
  (recentf-max-saved-items 150))
;; https://github.com/oantolin/orderless
(use-package orderless
  :ensure t
  :after (vertico)
  :custom
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch))
  ;; (orderless-component-separator #'orderless-escapable-split-on-space)
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil) ;; Disable defaults, use our settings
  (completion-pcm-leading-wildcard t)) ;; Emacs 31: partial-completion behaves like substring
;; https://github.com/minad/marginalia
(use-package marginalia
  :ensure t
  :bind (:map minibuffer-local-map
         ("M-A" . marginalia-cycle))
  :hook (minibuffer-setup . marginalia-mode))
;; https://github.com/oantolin/embark
(use-package embark
  :ensure t
  :bind
  (("C-." . embark-act)
   ("C-;" . embark-dwim)
   ("C-h B" . embark-bindings))
  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

(use-package embark-consult
  :ensure t
  :after (embark consult))

;; ctrl-w catches the current line
(use-package whole-line-or-region
  :ensure t
  :hook (elpaca-after-init . whole-line-or-region-global-mode))

;; nice to see some graphs
(use-package eplot
  :ensure (eplot :type git :host github :repo "larsmagne/eplot")
  :defer t
  )

;; basics like tabs, spaces for editing
(use-package editorconfig
  :ensure t
  :hook (prog-mode . editorconfig-mode))

;; emacs package dev
(use-package package-lint
  :ensure t
  :defer t)
(use-package ecukes
  :ensure t
  :defer t)


(use-package key-chord
  :ensure t
  :hook (elpaca-after-init . key-chord-mode)
  :config
  ;;(key-chord-define-global "FF" 'helm-projectile)
  (key-chord-define-global "uu" 'undo-tree-visualize)
  (key-chord-define-global "xx" 'consult-mode-command)
  (key-chord-define-global "BB" 'beginning-of-buffer)
  (key-chord-define-global "BE" 'end-of-buffer)
  (key-chord-define-global "bb" 'consult-buffer)
  (key-chord-define-global "BR" 'kill-current-buffer)
  (key-chord-define-global "bw" 'save-buffer)
  (key-chord-define-global "CC" 'comment-line)
  (key-chord-define-global "GS" 'jj-or-git-status)
  (key-chord-define-global "GG" 'consult-goto-line)
  (key-chord-define-global "gg" 'consult-ripgrep)
  (key-chord-define-global "LL" 'projectile-layout-project)
  (key-chord-define-global "yy" 'consult-yank-from-kill-ring)
  (key-chord-define-global "TT" 'tff)
  (key-chord-define-global "NN" 'other-window)
  (key-chord-define-global "UU" 'xref-find-references)
  )

(use-package move-text
  :ensure t
  :hook (elpaca-after-init . move-text-default-bindings)
  )

;; goto last change
(use-package goto-chg
  :ensure t
  :defer t)

(use-package which-key
  :ensure t
  :config (which-key-mode 1)
  )

(use-package deadgrep
  :ensure (deadgrep :type git :host github :repo "Wilfred/deadgrep")
  :defer t
  )

(use-package projectile
  :ensure t
  :hook (elpaca-after-init . projectile-mode)
  :config
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
(use-package posframe
  :ensure t)

;; TODO
(use-package company
  :ensure t
  :hook (prog-mode . company-mode)
  )

(use-package json-mode
  :ensure t
  :defer t
  )


(use-package haml-mode
  :ensure t
  :defer t
  )

(use-package yaml-pro
  :ensure t
  :defer t
  )

(use-package markdown-mode
  :ensure t
  :mode "\\.md\\'"
  )

(use-package markdown-toc
  :ensure t
  :after (markdown-mode)
  )

(use-package plantuml-mode
  :ensure t
  :mode ("\\.puml\\'" "\\.plantuml\\'")
  :config
  (plantuml-set-output-type "png")
  )

(use-package graphviz-dot-mode
  :ensure t
  :mode ("\\.dot\\'" "\\.gv\\'")
  )

(use-package ztree
  :ensure t
  :defer t)

(use-package yasnippet
  :ensure t
  :hook (prog-mode . yas-minor-mode)
  :init
  (add-hook 'eglot-managed-mode-hook (lambda ()
                                       (add-to-list 'company-backends
                                         '(company-capf :with company-yasnippet))))
  )

(use-package yasnippet-snippets
  :ensure t
  :after (yasnippet))


(use-package hydra
  :ensure t)

(use-package projectile-hydra
  :preface (provide 'projectile-hydra)
  :after (hydra projectile key-chord)
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

(defun projectile-layout-project ()
  "Format a project."
  (interactive)
  (message "layouting project of type %s in %s" (projectile-project-type) (projectile-project-root))
  (pcase (projectile-project-type)
    ('dlang (shell-command "~/bin/d run dfmt -- -i . && ~/bin/d run importsort-d -- --ignore-case --inplace --recursive ."))
    )
  )

;; use outline-indent-minor-mode instead
;;(use-package yafolding
;;  :ensure (yafolding :type git :host github :repo "vindarel/yafolding.el")
;;  :after (hydra)
;;  :config
;;  (defhydra yafolding-hydra (:color blue :columns 3)
;;    "Fold code based on indentation levels."
;;    ("t" yafolding-toggle-element "toggle element")
;;    ("s" yafolding-show-element "show element")
;;    ("h" yafolding-hide-element "hide element")
;;    ("T" yafolding-toggle-all "toggle all")
;;    ("S" yafolding-show-all "show all")
;;    ("H" yafolding-hide-all "hide all")
;;    ("p" yafolding-hide-parent-element "hide parent element")
;;    ("i" yafolding-get-indent-level "get indent level")
;;    ("g" yafolding-go-parent-element "go parent element"))
;;  (global- set-key (kbd "C-c f") 'yafolding-hydra/body)
;;  )

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

(use-package nxml-mode
  :ensure nil
  :defer t
  :custom
  (nxml-slash-auto-complete-flag t)
  )

(use-package eldoc-box
  :ensure t
  :hook (prog-mode . eldoc-box-hover-mode))

(use-package jinx
  :ensure t
  :defer t)

(use-package minimap
  :ensure t
  :defer t)
(use-package eat
  :ensure t
  :defer t)
(use-package newsticker
  :ensure nil
  :defer t
  :custom
  (newsticker-url-list '(("Emacs News" "https://sachachua.com/blog/category/emacs-news/feed" nil nil nil))))


(use-package flycheck
  :ensure t
  :hook
  (elpaca-after-init . (lambda () (progn (message "Enabling global-flycheck-mode") (global-flycheck-mode 1) (global-flycheck-annotate-mode 1) (global-flycheck-eglot-mode 1))))
  )

(use-package outline-indent
  :ensure t

  :after (undo-tree)

  :custom
  (outline-indent-ellipsis " ▼")
  (outline-blank-line t)

  :bind
  (
    ("C-+" . outline-indent-open-fold)
    ("C--" . outline-indent-close-fold)
    ("C-*" . outline-indent-open-folds)
    ("C-<tab>" . outline-indent-toggle-fold)
    :map undo-tree-map
    ("C-_" . outline-indent-close-folds)
    )

  :hook
  (prog-mode . (lambda () (outline-indent-minor-mode)))
  )

(use-package indent-bars
  :ensure t
  :hook
  (prog-mode . indent-bars-mode)
  )

;;(use-package jj-mode
;;  :ensure (jj-mode :type git :host github :repo "bolivier/jj-mode.el")
;;  :defer t)
(use-package majutsu
  :ensure (majutsu :type git :host github :repo "0WD0/majutsu")
  :defer t)


(use-package direnv
  :ensure t
  :config
    (direnv-mode))

(use-package org-kanban
  :ensure (org-kanban :type git :host github :repo "gizmomogwai/org-kanban")
  :after (org))

(use-package typst-ts-mode
  :ensure (:type git :host codeberg :repo "meow_king/typst-ts-mode" :branch "main")
  :mode "\\.typ\\'"
  :custom
  (typst-ts-watch-options "--open")
  (typst-ts-mode-grammar-location (expand-file-name "tree-sitter/libtree-sitter-typst.so" user-emacs-directory))
  (typst-ts-mode-enable-raw-blocks-highlight t)
  :config
  (keymap-set typst-ts-mode-map "C-c C-c" #'typst-ts-tmenu)
  (add-to-list 'eglot-server-programs
	  (cons 'typst-ts-mode (list "tinymist"))))

(use-package typst-preview
  :after (typst-ts-mode)
  :ensure (typst-preview :type git :host github :repo "havarddj/typst-preview.el"))

(use-package nix-mode
  :ensure t
  :mode "\\.nix\\'")

(provide 'init)

;;; init.el ends here

;; Local Variables:
;; workspace-buffer-comment: "emacs"
;; End:
