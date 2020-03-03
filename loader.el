;; PRIVATE: personal information about you
;; (setq user-full-name "Your Name")
;; (setq user-mail-address "your@email.address")

(require 'cl)
(setq tls-checktrust t)

(setq python (or (executable-find "py.exe")
                 (executable-find "python")
                 ))

(let ((trustfile
       (replace-regexp-in-string
        "\\\\" "/"
        (replace-regexp-in-string
         "\n" ""
         (shell-command-to-string (concat python " -m certifi"))))))
  (setq tls-program
        (list
         (format "gnutls-cli%s --x509cafile %s -p %%p %%h"
                 (if (eq window-system 'w32) ".exe" "") trustfile)))
  (setq gnutls-verify-error t)
  (setq gnutls-trustfiles (list trustfile)))

;; Test the settings by using the following code snippet:
;;  (let ((bad-hosts
;;         (loop for bad
;;               in `("https://wrong.host.badssl.com/"
;;                    "https://self-signed.badssl.com/")
;;               if (condition-case e
;;                      (url-retrieve
;;                       bad (lambda (retrieved) t))
;;                    (error nil))
;;               collect bad)))
;;    (if bad-hosts
;;        (error (format "tls misconfigured; retrieved %s ok" bad-hosts))
;;      (url-retrieve "https://badssl.com"
;;                    (lambda (retrieved) t))))

(require 'package)

;; Modern linux installations will fail with TLS erros if 1.3 is not a priority
(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")
(defvar gnu '("gnu" . "https://elpa.gnu.org/packages/"))
(defvar melpa '("melpa" . "https://melpa.org/packages/"))
(defvar melpa-stable '("melpa-stable" . "https://stable.melpa.org/packages/"))
(defvar org-elpa '("org" . "https://orgmode.org/elpa/"))

;; Add marmalade to package repos
(setq package-archives nil)
(add-to-list 'package-archives melpa-stable t)
(add-to-list 'package-archives melpa t)
(add-to-list 'package-archives gnu t)
(add-to-list 'package-archives org-elpa t)

(when (< emacs-major-version 27)
  (package-initialize))

(unless (and (file-exists-p (concat init-dir "elpa/archives/gnu"))
             (file-exists-p (concat init-dir "elpa/archives/melpa"))
             (file-exists-p (concat init-dir "elpa/archives/melpa-stable")))
  (package-refresh-contents))

(defun packages-install (&rest packages)
  (message "running packages-install")
  (mapc (lambda (package)
          (let ((name (car package))
                (repo (cdr package)))
            (when (not (package-installed-p name))
              (let ((package-archives (list repo)))
                (when (< emacs-major-version 27)
                  (package-initialize))
                (package-install name)))))
        packages)
  (when (< emacs-major-version 27)
    (package-initialize))
  (delete-other-windows))

;; Install extensions if they're missing
(defun init--install-packages ()
  (message "Lets install some packages")
  (packages-install
   ;; Since use-package this is the only entry here
   ;; ALWAYS try to use use-package!
   (cons 'use-package melpa)
   ))

(condition-case nil
    (init--install-packages)
  (error
   (package-refresh-contents)
   (init--install-packages)))

;; Always install packages
(require 'use-package-ensure)
(setq use-package-always-ensure t)

;; Always install packages
(require 'use-package-ensure)
(setq use-package-always-ensure t)

(use-package diminish)

(fset 'yes-or-no-p 'y-or-n-p)

(use-package bm
  :demand t

  :init
  ;; restore on load (even before you require bm)
  (setq bm-restore-repository-on-load t)


  :config
  ;; Allow cross-buffer 'next'
  (setq bm-cycle-all-buffers t)

  ;; where to store persistant files
  (setq bm-repository-file (concat user-emacs-directory "/bm-repository"))

  ;; save bookmarks
  (setq-default bm-buffer-persistence t)

  ;; Loading the repository from file when on start up.
  (add-hook 'after-init-hook 'bm-repository-load)

  ;; Saving bookmarks
  (add-hook 'kill-buffer-hook #'bm-buffer-save)

  ;; Saving the repository to file when on exit.
  ;; kill-buffer-hook is not called when Emacs is killed, so we
  ;; must save all bookmarks first.
  (add-hook 'kill-emacs-hook #'(lambda nil
                                 (bm-buffer-save-all)
                                 (bm-repository-save)))

  ;; The `after-save-hook' is not necessary to use to achieve persistence,
  ;; but it makes the bookmark data in repository more in sync with the file
  ;; state.
  (add-hook 'after-save-hook #'bm-buffer-save)

  ;; Restoring bookmarks
  (add-hook 'find-file-hooks   #'bm-buffer-restore)
  (add-hook 'after-revert-hook #'bm-buffer-restore)

  ;; The `after-revert-hook' is not necessary to use to achieve persistence,
  ;; but it makes the bookmark data in repository more in sync with the file
  ;; state. This hook might cause trouble when using packages
  ;; that automatically reverts the buffer (like vc after a check-in).
  ;; This can easily be avoided if the package provides a hook that is
  ;; called before the buffer is reverted (like `vc-before-checkin-hook').
  ;; Then new bookmarks can be saved before the buffer is reverted.
  ;; Make sure bookmarks is saved before check-in (and revert-buffer)
  (add-hook 'vc-before-checkin-hook #'bm-buffer-save)


  :bind (("<f2>" . bm-next)
         ("S-<f2>" . bm-previous)
         ("C-<f2>" . bm-toggle))
  )

(use-package smex)

(use-package counsel
  :bind
  (("M-x" . counsel-M-x)
   ("M-y" . counsel-yank-pop)
   :map ivy-minibuffer-map
   ("M-y" . ivy-next-line)))

(use-package swiper
  :pin melpa-stable
  :diminish ivy-mode

  :bind*
  (("C-s" . swiper)
   ("C-c C-r" . ivy-resume)
   ("C-x C-f" . counsel-find-file)
   ("C-c h f" . counsel-describe-function)
   ("C-c h v" . counsel-describe-variable)
   ("C-c i u" . counsel-unicode-char)
   ("M-i" . counsel-imenu)
   ("C-c g" . counsel-git)
   ("C-c j" . counsel-git-grep)
   ("C-c k" . counsel-ag)
   ;;      ("C-c l" . scounsel-locate)
   )
  :config
  (progn
    (ivy-mode 1)
    (setq ivy-use-virtual-buffers t)
    (define-key read-expression-map (kbd "C-r") #'counsel-expression-history)
    (ivy-set-actions
     'counsel-find-file
     '(("d" (lambda (x) (delete-file (expand-file-name x)))
        "delete"
        )))
    (ivy-set-actions
     'ivy-switch-buffer
     '(("k"
        (lambda (x)
          (kill-buffer x)
          (ivy--reset-state ivy-last))
        "kill")
       ("j"
        ivy--switch-buffer-other-window-action
        "other window")))))

(use-package counsel-projectile
  :config
  (counsel-projectile-mode))

(use-package ivy-hydra )

(global-set-key (kbd "C-x k") 'kill-this-buffer)

(setq mouse-wheel-scroll-amount '(1 ((shift) . 1) ((control) . nil)))
(setq mouse-wheel-progressive-speed nil)

(use-package which-key
  :diminish which-key-mode
  :config
  (which-key-mode))

(use-package projectile
  :bind (("C-c p f" . projectile-find-file)
         ("C-c p p" . projectile-switch-project)
         ("C-c p t" . projectile-find-test-file))
  :config
  (setq projectile-enable-caching t)
  (add-hook 'prog-mode-hook 'projectile-mode))

;;  (custom-set-variables '(epg-gpg-program  "/usr/local/MacGPG2/bin/gpg2"))

(if (or
     (eq system-type 'darwin)
     (eq system-type 'berkeley-unix))
    (setq system-name (car (split-string system-name "\\."))))

(use-package exec-path-from-shell
  :config
  (when (memq window-system '(mac ns x))
  (exec-path-from-shell-initialize)))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(setq mac-option-modifier 'none)
(setq mac-command-modifier 'meta)
(setq ns-function-modifier 'hyper)

;; Backup settings
(defvar --backup-directory (concat init-dir "backups"))

(if (not (file-exists-p --backup-directory))
    (make-directory --backup-directory t))

(setq backup-directory-alist `(("." . ,--backup-directory)))
(setq make-backup-files t               ; backup of a file the first time it is saved.
      backup-by-copying t               ; don't clobber symlinks
      version-control t                 ; version numbers for backup files
      delete-old-versions t             ; delete excess backup files silently
      delete-by-moving-to-trash t
      kept-old-versions 6               ; oldest versions to keep when a new numbered backup is made (default: 2)
      kept-new-versions 9               ; newest versions to keep when a new numbered backup is made (default: 2)
      auto-save-default t               ; auto-save every buffer that visits a file
      auto-save-timeout 20              ; number of seconds idle time before auto-save (default: 30)
      auto-save-interval 200            ; number of keystrokes between auto-saves (default: 300)
      )
  (setq delete-by-moving-to-trash t
        trash-directory "~/.Trash/emacs")

  (setq backup-directory-alist `(("." . ,(expand-file-name
                                          (concat init-dir "backups")))))

(setq ns-pop-up-frames nil)

(defun spell-buffer-dutch ()
  (interactive)
  (ispell-change-dictionary "nederlands")
  (flyspell-buffer))

(defun spell-buffer-english ()
  (interactive)
  (ispell-change-dictionary "en_US")
  (flyspell-buffer))

(use-package ispell
  :config
  (when (executable-find "hunspell")
    (setq-default ispell-program-name "hunspell")
    (setq ispell-really-hunspell t))

  ;; (setq ispell-program-name "aspell"
  ;;       ispell-extra-args '("--sug-mode=ultra"))
  :bind (("C-c N" . spell-buffer-dutch)
         ("C-c e" . spell-buffer-english)))

;;; what-face to determine the face at the current point
(defun what-face (pos)
  (interactive "d")
  (let ((face (or (get-char-property (point) 'read-face-name)
                  (get-char-property (point) 'face))))
    (if face (message "Face: %s" face) (message "No face at %d" pos))))

(use-package ace-window
  :config
  (global-set-key (kbd "C-x o") 'ace-window))

(use-package ace-jump-mode
  :config
  (define-key global-map (kbd "C-c SPC") 'ace-jump-mode))

(setq inhibit-startup-message t)
;;(global-linum-mode)
;;(global-hl-line-mode nil)

(custom-set-faces
 '(line-number-current-line ((t (:inherit default :background "#282635")))))

(setq-default indent-tabs-mode nil)

(defun iwb ()
  "indent whole buffer"
  (interactive)
  (delete-trailing-whitespace)
  (indent-region (point-min) (point-max) nil)
  (untabify (point-min) (point-max)))

(global-set-key (kbd "C-c n") 'iwb)

(electric-pair-mode t)

(use-package all-the-icons)

(use-package all-the-icons-ivy
  :config
  (all-the-icons-ivy-setup))

(when (window-system)
  (use-package doom-themes

    :config
    ;; Global settings (defaults)
    (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
          doom-themes-enable-italic t) ; if nil, italics is universally disabled

    ;; load theme here
    (load-theme 'doom-one t)
    ;; Enable flashing mode-line on errors
    (doom-themes-visual-bell-config)

    ;; Enable custom neotree theme (all-the-icons must be installed!)
    ;;(doom-themes-neotree-config)
    ;; or for treemacs users
    (setq doom-themes-treemacs-theme "doom-colors") ; use the colorful treemacs theme
    (doom-themes-treemacs-config)

    ;; Corrects (and improves) org-mode's native fontification.
    (doom-themes-org-config))

  (set-face-attribute 'default nil :font "Hack-14")
  )

(use-package command-log-mode)

(defun live-coding ()
  (interactive)
  (set-face-attribute 'default nil :font "Hack-18")
  (add-hook 'prog-mode-hook 'command-log-mode)
  ;;(add-hook 'prog-mode-hook (lambda () (focus-mode 1)))
  )

(defun normal-coding ()
  (interactive)
  (set-face-attribute 'default nil :font "Hack-14")
  (add-hook 'prog-mode-hook 'command-log-mode)
  ;;(add-hook 'prog-mode-hook (lambda () (focus-mode 1)))
  )

(eval-after-load "org-indent" '(diminish 'org-indent-mode))

;; http://stackoverflow.com/questions/11679700/emacs-disable-beep-when-trying-to-move-beyond-the-end-of-the-document
(defun my-bell-function ())

(setq ring-bell-function 'my-bell-function)
(setq visible-bell nil)

(use-package request)

;;(add-to-list 'load-path (expand-file-name (concat init-dir "ox-leanpub")))
;;(load-library "ox-leanpub")
;; (add-to-list 'load-path (expand-file-name (concat init-dir "ox-ghost")))
;; (load-library "ox-ghost")
;;; http://www.lakshminp.com/publishing-book-using-org-mode

;;(defun leanpub-export ()
;;  "Export buffer to a Leanpub book."
;;  (interactive)
;;  (if (file-exists-p "./Book.txt")
;;      (delete-file "./Book.txt"))
;;  (if (file-exists-p "./Sample.txt")
;;      (delete-file "./Sample.txt"))
;;  (org-map-entries
;;   (lambda ()
;;     (let* ((level (nth 1 (org-heading-components)))
;;            (tags (org-get-tags))
;;            (title (or (nth 4 (org-heading-components)) ""))
;;            (book-slug (org-entry-get (point) "TITLE"))
;;            (filename
;;             (or (org-entry-get (point) "EXPORT_FILE_NAME") (concat (replace-regexp-in-string " " "-" (downcase title)) ".md"))))
;;       (when (= level 1) ;; export only first level entries
;;         ;; add to Sample book if "sample" tag is found.
;;         (when (or (member "sample" tags)
;;                   ;;(string-prefix-p "frontmatter" filename) (string-prefix-p "mainmatter" filename)
;;                   )
;;           (append-to-file (concat filename "\n\n") nil "./Sample.txt"))
;;         (append-to-file (concat filename "\n\n") nil "./Book.txt")
;;         ;; set filename only if the property is missing
;;         (or (org-entry-get (point) "EXPORT_FILE_NAME")  (org-entry-put (point) "EXPORT_FILE_NAME" filename))
;;         (org-leanpub-export-to-markdown nil 1 nil)))) "-noexport")
;;  (org-save-all-org-buffers)
;;  nil
;;  nil)
;;
;;(require 'request)
;;
;;(defun leanpub-preview ()
;;  "Generate a preview of your book @ Leanpub."
;;  (interactive)
;;  (request
;;   "https://leanpub.com/clojure-on-the-server/preview.json" ;; or better yet, get the book slug from the buffer
;;   :type "POST"                                             ;; and construct the URL
;;   :data '(("api_key" . ""))
;;   :parser 'json-read
;;   :success (function*
;;             (lambda (&key data &allow-other-keys)
;;               (message "Preview generation queued at leanpub.com.")))))

(use-package langtool
  :config (setq langtool-language-tool-server-jar (concat user-emacs-directory "/LanguageTool-4.8/languagetool-server.jar"))
  :bind (("\C-x4w" . langtool-check)
         ("\C-x4W" . langtool-check-done)
         ("\C-x4l" . langtool-switch-default-language)
         ("\C-x44" . langtool-show-message-at-point)
         ("\C-x4c" . langtool-correct-buffer)))

(dolist (hook '(text-mode-hook))
  (add-hook hook (lambda ()
                   (flyspell-mode 1)
                   (visual-line-mode 1)
                   )))

(use-package markdown-mode)

(use-package htmlize)

(defun my/with-theme (theme fn &rest args)
  (let ((current-themes custom-enabled-themes))
    (mapcar #'disable-theme custom-enabled-themes)
    (load-theme theme t)
    (let ((result (apply fn args)))
      (mapcar #'disable-theme custom-enabled-themes)
      (mapcar (lambda (theme) (load-theme theme t)) current-themes)
      result)))

(advice-add #'org-export-to-file :around (apply-partially #'my/with-theme 'doom-one))
(advice-add #'org-export-to-buffer :around (apply-partially #'my/with-theme 'doom-one))

(use-package undo-tree
  :init
  (global-undo-tree-mode)
  :config
  (setq undo-tree-visualizer-diff t)
  (setq undo-tree-visualizer-timestamps t))

(use-package expand-region
  :config
  (global-set-key (kbd "C-=") 'er/expand-region))

(setq-default indent-tabs-mode nil)

(use-package highlight-indent-guides
  :hook ((prog-mode text-mode conf-mode) . highlight-indent-guides-mode)
  :init
  (setq highlight-indent-guides-method 'character)
  :config
  (add-hook 'focus-in-hook #'highlight-indent-guides-auto-set-faces)
  ;; `highlight-indent-guides' breaks in these modes
  (add-hook 'org-indent-mode-hook
    (defun +indent-guides-disable-maybe-h ()
      (when highlight-indent-guides-mode
        (highlight-indent-guides-mode -1)))))

(use-package s)

(use-package hydra)

(use-package hideshow
  :bind (("C->" . my-toggle-hideshow-all)
         ("C-<" . hs-hide-level)
         ("C-;" . hs-toggle-hiding))
  :config
  ;; Hide the comments too when you do a 'hs-hide-all'
  (setq hs-hide-comments nil)
  ;; Set whether isearch opens folded comments, code, or both
  ;; where x is code, comments, t (both), or nil (neither)
  (setq hs-isearch-open t)
  ;; Add more here

  (setq hs-set-up-overlay
        (defun my-display-code-line-counts (ov)
          (when (eq 'code (overlay-get ov 'hs))
            (overlay-put ov 'display
                         (propertize
                          (format " ... <%d> "
                                  (count-lines (overlay-start ov)
                                               (overlay-end ov)))
                          'face 'font-lock-type-face)))))

  (defvar my-hs-hide nil "Current state of hideshow for toggling all.")
       ;;;###autoload
  (defun my-toggle-hideshow-all () "Toggle hideshow all."
         (interactive)
         (setq my-hs-hide (not my-hs-hide))
         (if my-hs-hide
             (hs-hide-all)
           (hs-show-all)))

  (add-hook 'prog-mode-hook (lambda ()
                              (hs-minor-mode 1)
                              )))

(global-prettify-symbols-mode 1)

(use-package paredit
  :diminish paredit-mode
  :config
  (add-hook 'emacs-lisp-mode-hook       #'enable-paredit-mode)
  (add-hook 'eval-expression-minibuffer-setup-hook #'enable-paredit-mode)
  (add-hook 'ielm-mode-hook             #'enable-paredit-mode)
  (add-hook 'lisp-mode-hook             #'enable-paredit-mode)
  (add-hook 'lisp-interaction-mode-hook #'enable-paredit-mode)
  (add-hook 'scheme-mode-hook           #'enable-paredit-mode)
  :bind (("C-c d" . paredit-forward-down))
  )

;; Ensure paredit is used EVERYWHERE!
(use-package paredit-everywhere
  :diminish paredit-everywhere-mode
  :config
  (add-hook 'list-mode-hook #'paredit-everywhere-mode))

(use-package highlight-parentheses
  :diminish highlight-parentheses-mode
  :config
  (add-hook 'emacs-lisp-mode-hook
            (lambda()
              (highlight-parentheses-mode)
              )))

(use-package rainbow-delimiters
  :config
  (add-hook 'lisp-mode-hook
            (lambda()
              (rainbow-delimiters-mode)
              )))

(global-highlight-parentheses-mode)

(use-package yasnippet
  :diminish yas
  :config
  (yas/global-mode 1)
  (add-to-list 'yas-snippet-dirs (concat init-dir "snippets")))

(use-package clojure-snippets)
(use-package java-snippets)

(use-package company
  :bind (("C-c /". company-complete))
  :config
  (global-company-mode)
  )

(use-package magit
  :bind (("C-c m" . magit-status)))

(use-package magit-gitflow
  :config
  (add-hook 'magit-mode-hook 'turn-on-magit-gitflow))

(use-package forge)

(use-package git-timemachine)

;; https://github.com/alphapapa/unpackaged.el#smerge-mode
;; Tipped by Mike Z.
(use-package smerge-mode
  :after hydra
  :config
  (defhydra unpackaged/smerge-hydra
    (:color pink :hint nil :post (smerge-auto-leave))
    "
^Move^       ^Keep^               ^Diff^                 ^Other^
^^-----------^^-------------------^^---------------------^^-------
_n_ext       _b_ase               _<_: upper/base        _C_ombine
_p_rev       _u_pper              _=_: upper/lower       _r_esolve
^^           _l_ower              _>_: base/lower        _k_ill current
^^           _a_ll                _R_efine
^^           _RET_: current       _E_diff
"
    ("n" smerge-next)
    ("p" smerge-prev)
    ("b" smerge-keep-base)
    ("u" smerge-keep-upper)
    ("l" smerge-keep-lower)
    ("a" smerge-keep-all)
    ("RET" smerge-keep-current)
    ("\C-m" smerge-keep-current)
    ("<" smerge-diff-base-upper)
    ("=" smerge-diff-upper-lower)
    (">" smerge-diff-base-lower)
    ("R" smerge-refine)
    ("E" smerge-ediff)
    ("C" smerge-combine-with-next)
    ("r" smerge-resolve)
    ("k" smerge-kill-current)
    ("ZZ" (lambda ()
            (interactive)
            (save-buffer)
            (bury-buffer))
     "Save and bury buffer" :color blue)
    ("q" nil "cancel" :color blue))
  :hook (magit-diff-visit-file . (lambda ()
                                   (when smerge-mode
                                     (unpackaged/smerge-hydra/body)))))

(use-package git-gutter
  :config
  (global-git-gutter-mode +1))

(use-package restclient)

(use-package hl-todo
  :hook (prog-mode . hl-todo-mode)
  :config
  (setq hl-todo-highlight-punctuation ":"
        hl-todo-keyword-faces
        `(("TODO"       warning bold)
          ("FIXME"      error bold)
          ("HACK"       font-lock-constant-face bold)
          ("REVIEW"     font-lock-keyword-face bold)
          ("NOTE"       success bold)
          ("DEPRECATED" font-lock-doc-face bold))))

(use-package cider
    :pin melpa-stable

    :config
    (add-hook 'cider-repl-mode-hook #'company-mode)
    (add-hook 'cider-mode-hook #'company-mode)
    (add-hook 'cider-mode-hook #'eldoc-mode)
;;    (add-hook 'cider-mode-hook #'cider-hydra-mode)
    (add-hook 'clojure-mode-hook #'paredit-mode)
    (setq cider-repl-use-pretty-printing t)
    (setq cider-repl-display-help-banner nil)
    ;;    (setq cider-cljs-lein-repl "(do (use 'figwheel-sidecar.repl-api) (start-figwheel!) (cljs-repl))")

    :bind (("M-r" . cider-namespace-refresh)
           ("C-c r" . cider-repl-reset)
           ("C-c ." . cider-reset-test-run-tests))
    )

  (use-package clj-refactor
    :config
    (add-hook 'clojure-mode-hook (lambda ()
                                   (clj-refactor-mode 1)
                                   ;; insert keybinding setup here
                                   ))
    (cljr-add-keybindings-with-prefix "C-c C-m")
    (setq cljr-warn-on-eval nil)
    :bind ("C-c '" . hydra-cljr-help-menu/body)
    )

;;  (load-library (concat init-dir "cider-hydra.el"))
;;  (require 'cider-hydra)

(use-package web-mode
  :config
  (add-to-list 'auto-mode-alist '("\\.phtml\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.tpl\\.php\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.jsp\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.as[cp]x\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.erb\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.mustache\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.djhtml\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.xhtml?\\'" . web-mode))

  (defun my-web-mode-hook ()
    "Hooks for Web mode."
    (setq web-mode-enable-auto-closing t)
    (setq web-mode-enable-auto-quoting t)
    (setq web-mode-markup-indent-offset 2))

  (add-hook 'web-mode-hook  'my-web-mode-hook))

(use-package less-css-mode)

(use-package emmet-mode
  :config
  (add-hook 'clojure-mode-hook 'emmet-mode)
  (add-hook 'html-mode-hook 'emmet-mode)
  (add-hook 'web-mode-hook 'emmet-mode))

(use-package racer
  :config
  (add-hook 'racer-mode-hook #'company-mode)
  (setq company-tooltip-align-annotations t)
  (setq racer-rust-src-path "/home/arjen/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/src"))

(use-package rust-mode
  :config
  (add-hook 'rust-mode-hook #'racer-mode)
  (add-hook 'racer-mode-hook #'eldoc-mode)
  (setq rust-format-on-save t))

(use-package cargo
  :config
  (setq compilation-scroll-output t)
  (add-hook 'rust-mode-hook 'cargo-minor-mode))

(use-package flycheck-rust
  :config
  (add-hook 'flycheck-mode-hook #'flycheck-rust-setup)
  (add-hook 'rust-mode-hook 'flycheck-mode))

(use-package company-go
  :config
  (setq company-tooltip-limit 20)                      ; bigger popup window
  (setq company-idle-delay .3)                         ; decrease delay before autocompletion popup shows
  (setq company-echo-delay 0)                          ; remove annoying blinking
  (setq company-begin-commands '(self-insert-command)) ; start autocompletion only after typing
  (add-hook 'go-mode-hook (lambda ()
                            (set (make-local-variable 'company-backends) '(company-go))
                            (company-mode))))

(setq-default tab-width 4)

(use-package go-mode
  :bind (("C-c t t" . go-test-current-test)
         ("C-c t p" . go-test-current-project)
         ("C-c t c" . go-test-current-coverage)
         ("C-c t f" . go-test-current-file))
  :config
  (setq gofmt-command "goimports")
  (add-hook 'before-save-hook 'gofmt-before-save))

(use-package go-guru)

(use-package go-errcheck)

;; Yasnippets
(use-package go-snippets)

;; eldoc integration
(use-package go-eldoc)

;; (use-package gocode
;;   )

;; (use-package godef
;;   )

(use-package gotest)

(use-package flycheck-golangci-lint
  :hook (go-mode . flycheck-golangci-lint-setup))

(use-package typescript-mode)

(setq lsp-clients-angular-language-server-command
  '("node"
    "/home/arjen/.nvm/versions/node/v13.7.0/lib/node_modules/@angular/language-server"
    "--ngProbeLocations"
    "/home/arjen/.nvm/versions/node/v13.7.0/lib/node_modules"
    "--tsProbeLocations"
    "/home/arjen/.nvm/versions/node/v13.7.0/lib/node_modules"
    "--stdio"))

;;(use-package treemacs )
(use-package lsp-mode
  ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
  :init (setq lsp-keymap-prefix "C-c l")
  :hook (;; replace XXX-mode with concrete major-mode(e. g. python-mode)
         (java-mode . lsp)
         (javascript-mode . lsp)
         (typescript-mode . lsp)
         (go-mode . lsp)
         (rust-mode . lsp)
         ;; if you want which-key integration
         (lsp-mode . lsp-enable-which-key-integration))
  :commands lsp)

(use-package lsp-java  :after lsp
  :bind (("C-c l r i". lsp-java-add-import))  
  :config
  (add-hook 'java-mode-hook 'lsp)
  (setq lsp-java-server-install-dir (concat user-emacs-directory "/eclipse.jdt.ls/server/"))

  (setq path-to-lombok "/home/arjen/.m2/repository/org/projectlombok/lombok/1.18.10/lombok-1.18.10.jar")

  (setq lsp-java-vmargs
        `("-noverify"
          "-Xmx1G"
          "-XX:+UseG1GC"
          "-XX:+UseStringDeduplication"
          ,(concat "-javaagent:" path-to-lombok)
          ;;,(concat "-Xbootclasspath/a:" path-to-lombok)
          ))

  )

;; optionally
(use-package lsp-ui
  :commands lsp-ui-mode
  :config
  (setq lsp-ui-mode nil)
  (setq lsp-ui-sideline-enable nil)
  (setq lsp-ui-doc-enable nil))


(use-package company-lsp :commands company-lsp)
;; if you are ivy user
(use-package lsp-ivy :commands lsp-ivy-workspace-symbol)
(use-package lsp-treemacs :commands lsp-treemacs-errors-list)

;; optionally if you want to use debugger
(use-package dap-mode
  :after lsp-mode
  :config
  (dap-mode t)
  (setq dap-java-test-runner (concat user-emacs-directory "/junit-platform-console-standalone-1.6.0-RC1.jar"))
  (add-hook 'dap-stopped-hook
            (lambda (arg) (call-interactively #'dap-hydra)))
  )
;; (use-package dap-LANGUAGE) to load the dap adapter for your language

(use-package dap-java
  :ensure nil
  :after (lsp-java))
;;(use-package lsp-java-treemacs :after (treemacs))

(defvar java-project-package-roots (list "java/" "test/" "main/" "src/" 1)
    "A list of relative directories (strings) or depths (integer) used by
  `+java-current-package' to delimit the namespace from the current buffer's full
  file path. Each root is tried in sequence until one is found.

  If a directory is encountered in the file path, everything before it (including
  it) will be ignored when converting the path into a namespace.

  An integer depth is how many directories to pop off the start of the relative
  file path (relative to the project root). e.g.

  Say the absolute path is ~/some/project/src/java/net/lissner/game/MyClass.java
  The project root is ~/some/project
  If the depth is 1, the first directory in src/java/net/lissner/game/MyClass.java
    is removed: java.net.lissner.game.
  If the depth is 2, the first two directories are removed: net.lissner.game.")

  (defun java-current-class ()
    "Get the class name for the current file."
    (interactive)
    (unless (eq major-mode 'java-mode)
      (user-error "Not in a java-mode buffer"))
    (unless buffer-file-name
      (user-error "This buffer has no filepath; cannot guess its class name"))
    (or (file-name-sans-extension (file-name-base (buffer-file-name)))
        "ClassName"))

(defun doom-project-root (&optional dir)
  "Return the project root of DIR (defaults to `default-directory').
Returns nil if not in a project."
  (let ((projectile-project-root (unless dir projectile-project-root))
        projectile-require-project-root)
    (projectile-project-root dir)))

  (defun java-current-package ()
    "Converts the current file's path into a namespace.

  For example: ~/some/project/src/net/lissner/game/MyClass.java
  Is converted to: net.lissner.game

  It does this by ignoring everything before the nearest package root (see
  `+java-project-package-roots' to control what this function considers a package
  root)."
    (unless (eq major-mode 'java-mode)
      (user-error "Not in a java-mode buffer"))
    (let* ((project-root (file-truename (doom-project-root)))
           (file-path (file-name-sans-extension
                       (file-truename (or buffer-file-name
                                          default-directory))))
           (src-root (cl-loop for root in java-project-package-roots
                              if (and (stringp root)
                                      (locate-dominating-file file-path root))
                              return (file-name-directory (file-relative-name file-path (expand-file-name root it)))
                              if (and (integerp root)
                                      (> root 0)
                                      (let* ((parts (split-string (file-relative-name file-path project-root) "/"))
                                             (fixed-parts (reverse (nbutlast (reverse parts) root))))
                                        (when fixed-parts
                                          (string-join fixed-parts "/"))))
                              return it)))
      (when src-root
        (string-remove-suffix "." (replace-regexp-in-string "/" "." src-root)))))

(use-package dockerfile-mode)

;; helper functions
(defun nuke-all-buffers ()
  (interactive)
  (mapcar 'kill-buffer (buffer-list))
  (delete-other-windows))

(setq mac-right-alternate-modifier nil)

;; Customize EWW for dark background
(setq shr-color-visible-luminance-min 80)

(use-package html-to-hiccup

  :config
  ;;(define-key clojure-mode-map (kbd "H-h") 'html-to-hiccup-convert-region)
  )

(defun fc-insert-date (prefix)
  "Insert the current date. With prefix-argument, use ISO format. With
two prefix arguments, write out the day and month name."
  (interactive "P")
  (let ((format (cond
                 ((not prefix) "%Y-%m-%dT%H:%M:%S %Z")
                 ((equal prefix '(4)) "%d.%m.%Y")
                 (t "%A, %d. %B %Y")))
        (system-time-locale "nl_NL"))
    (insert (format-time-string format))))

(use-package counsel-projectile
   :config
   (counsel-projectile-mode +1))

 ;; (use-package ivy
 ;;   :diminish
 ;;   :hook (after-init . ivy-mode)
 ;;   :custom
 ;;   (ivy-display-style nil)
 ;;   (ivy-re-builders-alist '((counsel-rg . ivy--regex-plus)
 ;;                            (counsel-projectile-rg . ivy--regex-plus)
 ;;                            (counsel-ag . ivy--regex-plus)
 ;;                            (counsel-projectile-ag . ivy--regex-plus)
 ;;                            (swiper . ivy--regex-plus)
 ;;                            (t . ivy--regex-fuzzy)))
 ;;   (ivy-use-virtual-buffers t)
 ;;   (ivy-count-format "(%d/%d) ")
 ;;   (ivy-initial-inputs-alist nil)
 ;;   :config
 ;;   (define-key ivy-minibuffer-map (kbd "RET") #'ivy-alt-done)
 ;;   (define-key ivy-minibuffer-map (kbd "<escape>") #'minibuffer-keyboard-quit))

 ;; (use-package swiper
 ;;   :after ivy
 ;;   ;; :custom-face (swiper-line-face ((t (:foreground "#ffffff" :background "#60648E"))))
 ;;   :custom
 ;;   (swiper-action-recenter t)
 ;;   (swiper-goto-start-of-match t))

;; (use-package ivy-posframe
;;    :after ivy
;;    :diminish
;;    :custom
;;    (ivy-posframe-display-functions-alist '((t . ivy-posframe-display-at-frame-top-center)))
;;    (ivy-posframe-height-alist '((t . 20)))
;;    (ivy-posframe-parameters '((internal-border-width . 10)))
;;    (ivy-posframe-width 70)
;;    :config
;;    (ivy-posframe-mode +1))

 ;; (use-package ivy-rich
 ;;   :preface
 ;;   (defun ivy-rich-switch-buffer-icon (candidate)
 ;;     (with-current-buffer
 ;;         (get-buffer candidate)
 ;;       (all-the-icons-icon-for-mode major-mode)))
 ;;   :init
 ;;   (setq ivy-rich-display-transformers-list ; max column width sum = (ivy-poframe-width - 1)
 ;;         '(ivy-switch-buffer
 ;;           (:columns
 ;;            ((ivy-rich-switch-buffer-icon (:width 2))
 ;;             (ivy-rich-candidate (:width 35))
 ;;             (ivy-rich-switch-buffer-project (:width 15 :face success))
 ;;             (ivy-rich-switch-buffer-major-mode (:width 13 :face warning)))
 ;;            :predicate
 ;;            #'(lambda (cand) (get-buffer cand)))
 ;;           counsel-M-x
 ;;           (:columns
 ;;            ((counsel-M-x-transformer (:width 35))
 ;;             (ivy-rich-counsel-function-docstring (:width 34 :face font-lock-doc-face))))
 ;;           counsel-describe-function
 ;;           (:columns
 ;;            ((counsel-describe-function-transformer (:width 35))
 ;;             (ivy-rich-counsel-function-docstring (:width 34 :face font-lock-doc-face))))
 ;;           counsel-describe-variable
 ;;           (:columns
 ;;            ((counsel-describe-variable-transformer (:width 35))
 ;;             (ivy-rich-counsel-variable-docstring (:width 34 :face font-lock-doc-face))))
 ;;           package-install
 ;;           (:columns
 ;;            ((ivy-rich-candidate (:width 25))
 ;;             (ivy-rich-package-version (:width 12 :face font-lock-comment-face))
 ;;             (ivy-rich-package-archive-summary (:width 7 :face font-lock-builtin-face))
 ;;             (ivy-rich-package-install-summary (:width 23 :face font-lock-doc-face))))))
 ;;   :config
 ;;   (ivy-rich-mode +1)
 ;;   (setcdr (assq t ivy-format-functions-alist) #'ivy-format-function-line))

 ;; (use-package prescient
 ;;   :custom
 ;;   (prescient-filter-method '(literal regexp initialism fuzzy))
 ;;   :config
 ;;   (prescient-persist-mode +1))

 ;; (use-package ivy-prescient
 ;;   :after (prescient ivy)
 ;;   :custom
 ;;   (ivy-prescient-sort-commands '(:not swiper counsel-grep ivy-switch-buffer))
 ;;   (ivy-prescient-retain-classic-highlighting t)
 ;;   :config
 ;;   (ivy-prescient-mode +1))

;; visualize color codes https://jblevins.org/log/rainbow-mode
(use-package rainbow-mode)
;;(use-package solaire-mode)

(defun ap/load-doom-theme (theme)
  "Disable active themes and load a Doom theme."
  (interactive (list (intern (completing-read "Theme: "
                                              (->> (custom-available-themes)
                                                   (-map #'symbol-name)
                                                   (--select (string-prefix-p "doom-" it)))))))
  (ap/switch-theme theme)

  (set-face-foreground 'org-indent (face-background 'default)))

(defun ap/switch-theme (theme)
  "Disable active themes and load THEME."
  (interactive (list (intern (completing-read "Theme: "
                                              (->> (custom-available-themes)
                                                   (-map #'symbol-name))))))
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme theme 'no-confirm))

(defun my-org-screenshot ()
  "Take a screenshot into a time stamped unique-named file in the
same directory as the org-buffer and insert a link to this file."
  (interactive)
  (setq filename
        (concat
         (make-temp-name
          (concat (buffer-file-name)
                  "_"
                  (format-time-string "%Y%m%d_%H%M%S_")) ) ".png"))
  (call-process "import" nil nil nil filename)
  (insert (concat "[[" "./" (file-name-nondirectory filename) "]]"))
  (org-display-inline-images))

(use-package org)

(setq org-catch-invisible-edits 'show-and-error)

(require 'org-habit)

(add-to-list 'org-modules 'org-habit)

(use-package org-bullets
  :config
  (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1))))

(setq org-hide-emphasis-markers t)

(setq org-bullets-bullet-list '("✙" "♱" "♰" "☥" "✞" "✟" "✝" "†" "✠" "✚" "✜" "✛" "✢" "✣" "✤" "✥"))
(setq org-ellipsis " ➟ ")

(setq org-todo-keywords '((sequence "TODO(t)" "WAITING(w)" "|" "DONE(d)" "CANCELLED(c)")))


(font-lock-add-keywords 'org-mode
                        '(("^ +\\([-*]\\) "
                           (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

(setq org-link-frame-setup
      (quote
       ((vm . vm-visit-folder-other-frame)
        (vm-imap . vm-visit-imap-folder-other-frame)
        (gnus . org-gnus-no-new-news)
        (file . find-file)
        (wl . wl-other-frame))))

;; From http://www.howardism.org/Technical/Emacs/orgmode-wordprocessor.html
(when (window-system)
  (let* ((variable-tuple (cond ((x-list-fonts "Source Sans Pro") '(:font "Source Sans Pro"))
                               ((x-list-fonts "Lucida Grande")   '(:font "Lucida Grande"))
                               ((x-list-fonts "Verdana")         '(:font "Verdana"))
                               ((x-family-fonts "Sans Serif")    '(:family "Sans Serif"))
                               (nil (warn "Cannot find a Sans Serif Font.  Install Source Sans Pro."))))
         (base-font-color     (face-foreground 'default nil 'default))
         (headline           `(:inherit default :weight bold :foreground ,base-font-color)))

    (custom-theme-set-faces 'user
                            `(org-level-8 ((t (,@headline ,@variable-tuple))))
                            `(org-level-7 ((t (,@headline ,@variable-tuple))))
                            `(org-level-6 ((t (,@headline ,@variable-tuple))))
                            `(org-level-5 ((t (,@headline ,@variable-tuple))))
                            `(org-level-4 ((t (,@headline ,@variable-tuple :height 1.1))))
                            `(org-level-3 ((t (,@headline ,@variable-tuple :height 1.25))))
                            `(org-level-2 ((t (,@headline ,@variable-tuple :height 1.5))))
                            `(org-level-1 ((t (,@headline ,@variable-tuple :height 1.75))))
                            `(org-document-title ((t (,@headline ,@variable-tuple :height 1.5 :underline nil))))))
  )

;; Move to PRIVATE?
(setq org-agenda-files '("~/stack/Notebook"))
(setq org-log-into-drawer t)
(setq org-capture-templates '(("t" "Todo [inbox]" entry
                               (file+headline "~/stack/Notebook/inbox.org" "Tasks")
                               "* TODO %i%?")
                              ("T" "Tickler" entry
                               (file+headline "~/stack/Notebook/tickler.org" "Tickler")
                               "* %i%? \n %U")
                              ("e" "email" entry (file+headline "~/stack/Notebook/inbox.org" "Tasks from Email")
                               "* TODO [#A] %?\nSCHEDULED: %(org-insert-time-stamp (org-read-date nil t \"+0d\"))\n%a\n")))

(setq org-refile-targets '(("~/stack/Notebook/notes.org" :level . 2)
                           ("~/stack/Notebook/tickler.org" :maxlevel . 2)))

(setq org-agenda-custom-commands
      '(("b" "Build fun things" tags-todo "@bft"
         ((org-agenda-overriding-header "BuildFunThings")
          (org-agenda-skip-function #'my-org-agenda-skip-all-siblings-but-first)))))

(defun my-org-agenda-skip-all-siblings-but-first ()
  "Skip all but the first non-done entry."
  (let (should-skip-entry)
    (unless (org-current-is-todo)
      (setq should-skip-entry t))
    (save-excursion
      (while (and (not should-skip-entry) (org-goto-sibling t))
        (when (org-current-is-todo)
          (setq should-skip-entry t))))
    (when should-skip-entry
      (or (outline-next-heading)
          (goto-char (point-max))))))

(defun org-current-is-todo ()
  (string= "TODO" (org-get-todo-state)))

(global-set-key "\C-cf" 'org-store-link)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cc" 'org-capture)
(global-set-key "\C-cb" 'org-iswitchb)

(package-install 'org-plus-contrib)

(require 'ox-html)
(require 'ox-publish)

(add-to-list 'load-path (expand-file-name (concat init-dir "ox-rss")))
(require 'ox-rss)

(setq org-mode-websrc-directory "~/Dropbox/Apps/MobileOrg/website")
(setq org-mode-publishing-directory "~/Dropbox/Apps/MobileOrg/website/_site")

(setq org-html-htmlize-output-type 'css)

(defun my-org-export-format-drawer (name content)
  (concat "<div class=\"drawer " (downcase name) "\">\n"
          "<h6>" (capitalize name) "</h6>\n"
          content
          "\n</div>"))
(setq org-html-format-drawer-function 'my-org-export-format-drawer)

(defun org-mode-blog-preamble (options)
  "The function that creates the preamble top section for the blog.
            OPTIONS contains the property list from the org-mode export."
  (let ((base-directory (plist-get options :base-directory)))
    (org-babel-with-temp-filebuffer (expand-file-name "top-bar.html" base-directory) (buffer-string))))

(defun org-mode-blog-postamble (options)
  "The function that creates the postamble, or bottom section for the blog.
            OPTIONS contains the property list from the org-mode export."
  (let ((base-directory (plist-get options :base-directory)))
    (org-babel-with-temp-filebuffer (expand-file-name "bottom.html" base-directory) (buffer-string))))

(defun org-mode-blog-prepare (options)
  "`index.org' should always be exported so touch the file before publishing."
  (let* (
         (buffer (find-file-noselect (expand-file-name "index.org" org-mode-websrc-directory) t)))
    (with-current-buffer buffer
      (set-buffer-modified-p t)
      (save-buffer 0))
    (kill-buffer buffer)))

;; ;; Options: http://orgmode.org/manual/Publishing-options.html
;; (setq org-publish-project-alist
;;       `(("all"
;;          :components ("site-content" "site-rss" "site-static"))

;;         ("site-content"
;;          :base-directory ,org-mode-websrc-directory
;;          :base-extension "org"
;;          :publishing-directory ,org-mode-publishing-directory
;;          :recursive t
;;          :publishing-function org-html-publish-to-html
;;          :preparation-function org-mode-blog-prepare

;;          :html-head "<link rel=\"stylesheet\" href=\"/css/style.css\" type=\"text/css\" />
;; <link rel=\"stylesheet\" href=\"/css/all.min.css\" type=\"text/css\" />"

;;          :headline-levels      4
;;          :auto-preamble        t
;;          :auto-postamble       nil
;;          :auto-sitemap         t
;;          :sitemap-title        "Build Fun Things"
;;          :section-numbers      nil
;;          :table-of-contents    t
;;          :with-toc             nil
;;          :with-author          nil
;;          :with-creator         nil
;;          :with-tags            nil
;;          :with-smart-quotes    nil

;;          :html-doctype         "html5"
;;          :html-html5-fancy     t
;;          :html-preamble        org-mode-blog-preamble
;;          :html-postamble       org-mode-blog-postamble

;;          :html-head-include-default-style nil
;;          :html-head-include-scripts nil
;;          )

;;         ("site-rss"
;;          :base-directory ,org-mode-websrc-directory
;;          :base-extension "org"
;;          :publishing-directory ,org-mode-publishing-directory
;;          :recursive t
;;          :publishing-function (org-rss-publish-to-rss)
;;          :html-link-home "https://www.buildfunthings.com"
;;          :html-link-use-abs-url t
;;          :exclude ".*"
;;          :include ("feed.org")
;;          )
;;         ("site-static"
;;          :base-directory       ,org-mode-websrc-directory
;;          :base-extension       "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|ttf\\|woff\\|woff2\\|ico\\|webmanifest"
;;          :publishing-directory ,org-mode-publishing-directory
;;          :exclude "_site"
;;          :recursive            t
;;          :publishing-function  org-publish-attachment
;;          )
;;         ))

;; (use-package ox-reveal
;;
;;   :config
;;   (setq org-reveal-root "file:///home/arjen/Documents/BuildFunThings/Security/reveal.js-3.5.0/js/reveal.js"))

(setq mu4e-drafts-folder "/Personal/Drafts")
(setq mu4e-sent-folder   "/Personal/Sent Items")
(setq mu4e-trash-folder  "/Personal/Trash")

;; this is where the install procedure above puts your mu4e
(add-to-list 'load-path "/usr/share/emacs/site-lisp/mu4e")

(require 'mu4e)

;; path to our Maildir directory
(setq mu4e-maildir "~/Maildir")

(setq mu4e-get-mail-command "mbsync -a")
(setq mu4e-view-show-images t)
(setq mu4e-html2text-command "w3m -dump -T text/html")

;; Prevent duplicate UIDs when moving files around
(setq mu4e-change-filenames-when-moving t)

;; This enables unicode chars to be used for things like flags in the message index screens.
;; I've disabled it because the font I am using doesn't support this very well. With this
;; disabled, regular ascii characters are used instead.
                                        ;(setq mu4e-use-fancy-chars t)
;; This enabled the thread like viewing of email similar to gmail's UI.
(setq mu4e-headers-include-related t)
(setq mu4e-attachment-dir  "~/Downloads")
;; This prevents saving the email to the Sent folder since gmail will do this for us on their end.
;;  (setq mu4e-sent-messages-behavior 'delete)
(setq message-kill-buffer-on-exit t)
(when (fboundp 'imagemagick-register-types)
  (imagemagick-register-types))

;; Sometimes html email is just not readable in a text based client, this lets me open the
;; email in my browser.
(add-to-list 'mu4e-view-actions '("View in browser" . mu4e-action-view-in-browser) t)

;; Spell checking ftw.
(add-hook 'mu4e-compose-mode-hook 'flyspell-mode)

;; This hook correctly modifies the \Inbox and \Starred flags on email when they are marked.
;; Without it refiling (archiving) and flagging (starring) email won't properly result in
;; the corresponding gmail action.
(add-hook 'mu4e-mark-execute-pre-hook
          (lambda (mark msg)
            (cond ((member mark '(refile trash)) (mu4e-action-retag-message msg "-\\Inbox"))
                  ((equal mark 'flag) (mu4e-action-retag-message msg "\\Starred"))
                  ((equal mark 'unflag) (mu4e-action-retag-message msg "-\\Starred")))))



(defun my-make-mu4e-context (name address signature trash refile)
  "Return a mu4e context named NAME with :match-func matching
    its ADDRESS in From or CC fields of the parent message. The
    context's `user-mail-address' is set to ADDRESS and its
    `mu4e-compose-signature' to SIGNATURE."
  (lexical-let ((addr-lex address))
    (make-mu4e-context :name name
                       :enter-func (lambda () (mu4e-message "Entering " name  " context"))
                       :vars `((user-mail-address . ,address)
                               (mu4e-compose-signature . ,signature)
                               (mu4e-trash-folder . ,trash)
                               (mu4e-refile-folder . ,refile)
                               (mu4e-sent-folder . ,(concat "/" name "/Sent Items"))
                               (mu4e-drafts-folder . ,(concat "/" name "/Drafts"))
                               )
                       :match-func
                       (lambda (msg)
                         (when msg
                           (or (mu4e-message-contact-field-matches msg :to addr-lex)
                               (mu4e-message-contact-field-matches msg :cc addr-lex)))))))

;; Don't ask for a 'context' upon opening mu4e
(setq mu4e-context-policy 'pick-first)

;; PRIVATE: this function holds private information, it is loaded from
;;          the private org file instead.
;;
;; (setq mu4e-contexts
;;       `( ,(my-make-mu4e-context "ACCOUNTNAME" "your@email.address"
;;                                 "Your Signature")
;;          ))

;; This is a helper to help determine which account context I am in based
;; on the folder in my maildir the email (eg. ~/.mail/nine27) is located in.
(defun mu4e-message-maildir-matches (msg rx)
  (when rx
    (if (listp rx)
        ;; If rx is a list, try each one for a match
        (or (mu4e-message-maildir-matches msg (car rx))
            (mu4e-message-maildir-matches msg (cdr rx)))
      ;; Not a list, check rx
      (string-match rx (mu4e-message-field msg :maildir)))))

;; PRIVATE: this function is replicated to the personal file.
;; (defun choose-msmtp-account ()
;;   (if (message-mail-p)
;;       (save-excursion
;;         (let*
;;             ((from (save-restriction
;;                      (message-narrow-to-headers)
;;                      (message-fetch-field "from")))
;;              (account
;;               (cond
;;                ((string-match "your@emai.address" from) "YOURACCOUNT")
;;                )))
;;
;;           (setq message-sendmail-extra-arguments (list '"-a" account))))))
;; (add-hook 'message-send-mail-hook 'choose-msmtp-account)

;; Configure sending mail.
(setq message-send-mail-function 'message-send-mail-with-sendmail
      sendmail-program "/usr/bin/msmtp")

;; Use the correct account context when sending mail based on the from header.
(setq message-sendmail-envelope-from 'header)

(setq mu4e-view-show-images t
      mu4e-view-image-max-width 800)

  ;; Add a column to display what email account the email belongs to.
(add-to-list 'mu4e-header-info-custom
             '(:account
               :name "Account"
               :shortname "Account"
               :help "Which account this email belongs to"
               :function
               (lambda (msg)
                 (let ((maildir (mu4e-message-field msg :maildir)))
                   (format "%s" (substring maildir 1 (string-match-p "/" maildir 1)))))))

(add-hook 'mu4e-compose-mode-hook #'flyspell-mode)

(setq mu4e-headers-fields
      '((:account . 12)
        (:human-date . 12)
        (:flags . 4)
        (:from . 25)
        (:subject)))


;; Use fancy icons
(setq mu4e-headers-has-child-prefix '("+" . "")
      mu4e-headers-empty-parent-prefix '("-" . "")
      mu4e-headers-first-child-prefix '("\\" . "")
      mu4e-headers-duplicate-prefix '("=" . "")
      mu4e-headers-default-prefix '("|" . "")
      mu4e-headers-draft-mark '("D" . "")
      mu4e-headers-flagged-mark '("F" . "")
      mu4e-headers-new-mark '("N" . "")
      mu4e-headers-passed-mark '("P" . "")
      mu4e-headers-replied-mark '("R" . "")
      mu4e-headers-seen-mark '("S" . "")
      mu4e-headers-trashed-mark '("T" . "")
      mu4e-headers-attach-mark '("a" . "")
      mu4e-headers-encrypted-mark '("x" . "")
      mu4e-headers-signed-mark '("s" . "")
      mu4e-headers-unread-mark '("u" . ""))

(use-package mu4e-maildirs-extension

  :after mu4e
  :config
  (mu4e-maildirs-extension)
  (setq mu4e-maildirs-extension-title nil))

(require 'org-mu4e)

;;store link to message if in header view, not to header query
(setq org-mu4e-link-query-in-headers-mode nil)

(use-package doom-modeline
  :hook (after-init . doom-modeline-mode))

(defun find-first-non-ascii-char ()
  "Find the first non-ascii character from point onwards."
  (interactive)
  (let (point)
    (save-excursion
      (setq point
            (catch 'non-ascii
              (while (not (eobp))
                (or (eq (char-charset (following-char))
                        'ascii)
                    (throw 'non-ascii (point)))
                (forward-char 1)))))
    (if point
        (goto-char point)
        (message "No non-ascii characters."))))

;; Load my personal information
(org-babel-load-file
 (expand-file-name
  "personal-emacs-config/personal.org" init-dir))
