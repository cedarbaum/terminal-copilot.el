;;; terminal-copilot.el --- Emacs integration with Terminal-copilot -*- lexical-binding: t; coding: utf-8 -*-

;; Copyright (C) 2023 Sam Cedarbaum

;; Author: Sam Cedarbaum (scedarbaum@gmail.com)
;; Keywords: terminals copilot gpt openai
;; Homepage: https://github.com/cedarbaum/terminal-copilot.el
;; Version: 0.1
;; Package-Requires: ((emacs "28.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Emacs integration with Terminal-copilot.

;;; Code:

(require 'transient)

(defconst terminal-copilot-output-buffer-name
  "*terminal-copilot-output*" "The name of the terminal copilot output buffer.")
(defconst terminal-copilot-error-buffer-name
  "*terminal-copilot-error*" "The name of the terminal copilot error buffer.")

(defcustom terminal-copilot-openai-api-key nil
  "OpenAI API key."
  :type 'string
  :group 'terminal-copilot)

(defcustom terminal-copilot-executable "copilot"
  "Copilot executable."
  :type 'string
  :group 'terminal-copilot)

;;;###autoload
(transient-define-prefix terminal-copilot-transient ()
  "Terminal copilot transient."
  ["Arguments"
   ("-a" "Enable inclusion of aliases" "--alias")
   ("-v" "Increase output verbosity" "--verbose")
   ("-g" "Include Git context" "--git")
   ("-h" "Include terminal history" "--history")
   ("-c" "The number of commands to request" "--count=")]
  ["Actions"
   ("d" "Describe command" terminal-copilot--exec)])

;;;###autoload
(defun terminal-copilot ()
  "Run terminal copilot with no arguments."
  (interactive)
  (terminal-copilot--exec))

;; https://stackoverflow.com/questions/23299314/finding-the-exit-code-of-a-shell-command-in-elisp
(defun terminal-copilot--process-exit-code-and-output (program &rest args)
  "Run PROGRAM with ARGS and return the exit code and output in a list."
  (with-temp-buffer
    (list (apply 'call-process program nil (current-buffer) nil args)
          (buffer-string))))

(defun terminal-copilot--write-to-read-only-buffer (name text)
  "Write TEXT to a new or existing read-only buffer NAME."
  (let* ((buffer (get-buffer-create name)))
    (with-current-buffer buffer
      (read-only-mode t)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert text)))))

(defun terminal-copilot--exec (&optional args)
  "Run terminal copilot with ARGS."
  (interactive
   (list (transient-args 'terminal-copilot-transient)))
  (let* ((args                 (if args (cons "--json" args) '("--json")))
         (process-environment  (if terminal-copilot-openai-api-key
                                   `(,(concat "OPENAI_API_KEY="
                                              terminal-copilot-openai-api-key)
                                     . ,process-environment)
                                 process-environment))
         (command              (read-string "Describe command: "))
         (exit-code-and-output (apply 'terminal-copilot--process-exit-code-and-output
                                      terminal-copilot-executable command args))
         (exit-code            (car exit-code-and-output))
         (output               (car (last exit-code-and-output))))
    (if (eq exit-code 0)
        (let* ((split-output    (split-string output "\n"))
               (filtered-output (seq-filter (lambda (line)
                                              (string-match-p "[^[:blank:]\n]" line))
                                            split-output))
               (json-str        (car (last filtered-output)))
               (parsed-output   (json-parse-string json-str
                                                   :array-type 'list
                                                   :object-type 'hash-table))
               (cmds            (gethash "commands" parsed-output))
               (num-cmds        (length cmds)))
          (when (member "--verbose" args)
            (terminal-copilot--write-to-read-only-buffer
             terminal-copilot-output-buffer-name
             output))
          (if (> num-cmds 1)
              (let* ((selected-cmd (completing-read "Select command: " cmds nil t)))
                (terminal-copilot--dispatch-cmd selected-cmd))
            (terminal-copilot--dispatch-cmd (car cmds))))
      (message "terminal copilot failed with code %d, see buffer %s"
               exit-code terminal-copilot-error-buffer-name)
      (terminal-copilot--write-to-read-only-buffer
       terminal-copilot-error-buffer-name
       output))))

(defun terminal-copilot--dispatch-cmd (cmd)
  "Dispatch the CMD."
  (let* ((prompt (format "Action for '%s': " cmd))
         (action (completing-read prompt '("Execute"
                                           "Execute interactively"
                                           "Kill ring"
                                           "Open explainshell") nil t)))
    (cond
     ((string= action "Execute") (compile cmd))
     ((string= action "Execute interactively") (compile cmd t))
     ((string= action "Kill ring") (kill-new cmd))
     ((string= action "Open explainshell")
      (browse-url (url-encode-url (format "https://explainshell.com/explain?cmd=%s" cmd)))))))

(provide 'terminal-copilot)
;;; terminal-copilot.el ends here
