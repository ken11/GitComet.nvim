# GitComet

## 🚀 About GitComet

GitComet is a Neovim plugin designed to generate commit messages at lightning speed—just like a comet! The name "GitComet" is inspired by the speed of a comet and a play on words combining **Commit, and Comment**.

For users who are restricted to using **AWS Amazon Bedrock** for security reasons, GitComet provides an easy way to generate AI-powered commit messages directly in Neovim.

## ✨ Features
- Uses **Amazon Bedrock** (Claude 3.5 Sonnet) to generate commit messages.
- Supports **structured commit message prefixes** (e.g., `🐛 fix:`, `✨ add:`).
- Seamless integration with **Lazy.nvim**.
- Works securely within **AWS environments**.

## 🌍 Environment Variables

GitComet uses the `BEDROCK_KEYS` environment variable to authenticate with AWS Bedrock. This variable should be set in the following format:

```sh
export BEDROCK_KEYS=aws_access_key_id,aws_secret_access_key,aws_region
```

GitComet follows the same convention as [avante.nvim](https://github.com/yetone/avante.nvim) to ensure compatibility with other AI-powered Neovim plugins.

## 📌 How to Use
### Install with lazy.nvim
Add the following configuration to your lazy.nvim setup:

```lua
return {
    "ken11/GitComet.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        require("gitcomet").setup({
          -- add any options here
        })
    end
}
```

### Usage

To ensure Neovim opens automatically when committing, configure Git to use Neovim as the default editor:

```sh
git config --global core.editor "nvim"
```

1. **Stage your changes** using `git add .` or `git add <file>`.
2. **Commit your changes**, which will open Neovim as the editor:
   ```sh
   git commit
   ```
2. **Run the command inside Neovim**:
   ```vim
   :GitComet
   ```
3. **GitComet will generate and insert the commit message** based on the staged changes.
4. **Save and commit**!

Start using GitComet and make your commit messages faster than ever! 🚀
