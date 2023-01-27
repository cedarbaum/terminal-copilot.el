# terminal-copilot.el

![CI](https://github.com/cedarbaum/terminal-copilot.el/actions/workflows/main.yml/badge.svg)

This package provides integration with the [terminal-copilot](https://github.com/Methexis-Inc/terminal-copilot) program.

## Setup

1. Install [terminal-copilot](https://github.com/Methexis-Inc/terminal-copilot)
    * Ensure you have installed a version after this [commit](https://github.com/Methexis-Inc/terminal-copilot/commit/7e3b518158b187c177da871c7e01dea56ed2407c), which enables the required `--json` flag.
2. Ensure `copilot` is on your `PATH` and visible to Emacs.
    * You can also use the variable `terminal-copilot-executable` to explicitly specify the executable location.
3. Ensure that the `OPENAI_API_KEY` is set within the Emacs `process-environment`.
    * You can also set the variable `terminal-copilot-openai-api-key` to your OpenAI API key. I recommend using a `.authinfo` file for this, as described [here](https://www.gnu.org/software/emacs/manual/html_node/emacs/Authentication.html).

## Usage

There are 2 entry points to `terminal-copilot`:

1. `terminal-copilot-transient`: this command summons a transient which allows you to specify arguments for the `copilot` command.

2. `terminal-copilot`: this command runs `copilot` with no additional arguments.

Either of these commands will then allow you to perform any of the following:

* **Execute:** run the command in a compilation buffer.
* **Execute interactively:** Run the command in a compilation buffer using `comint` mode.
* **Kill ring:** copy the command to the kill ring.
* **Open explainshell:** show the command on [https://explainshell.com/](https://explainshell.com/)
