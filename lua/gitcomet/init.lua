local M = {}
local curl = require("plenary.curl")

local aws_keys = os.getenv("BEDROCK_KEYS")
local aws_access_key, aws_secret_key, aws_region = aws_keys:match("([^,]+),([^,]+),([^,]+)")
local service = "bedrock"

M.options = {
    model_id = "anthropic.claude-3-5-sonnet-20240620-v1:0",
    system_prompt = "Gitのコミットメッセージを最適に生成するAIとして振る舞ってください。\n長すぎず短すぎず簡潔にまとめるよう心がけます。",
    max_tokens = 1024
}

local function request_commit_message(diff)
    local template = [[
🐛 fix: Bug fixes
🚑 hotfix: Critical bug fixes
✨ add: New features or files
🌟 feat: Feature implementation
🔧 update: Non-bug improvements
⚡ change: Specification-based changes
📖 docs: Documentation updates
🚫 disable: Feature disable
🔥 remove: Deleting files or code
📛 rename: Renaming files
🆙 upgrade: Version upgrades
⏪ revert: Reverting changes
🎨 style: Code formatting & styling
♻️ refactor: Code refactoring
🧪 test: Adding or fixing tests
🛠 chore: Build tools & auto-generated commits
]]

    local payload = {
        anthropic_version = "bedrock-2023-05-31",
        system = M.options.system_prompt,
        messages = {
            { role = "user", content = "以下のGitDiffは現在の git diff コマンドの結果です。このGitDiffの内容に基づいて適切なコミットメッセージを考えてください。\nまた、コミットメッセージはMessageTemplateを参考にして書いてください。\n\n<MessageTemplate>" .. template .. "\n\n<GitDiff>\n" .. diff .. "\n</GitDiff>\n\nコミットメッセージのみを英語で出力してください。" }
        },
        max_tokens = M.options.max_tokens
    }

    local response = curl.post("https://" .. "bedrock-runtime" .. "." .. aws_region .. ".amazonaws.com/model/" .. M.options.model_id .. "/invoke", {
        headers = {
            ["Content-Type"] = "application/json"
        },
        body = vim.fn.json_encode(payload),
        raw = { "--aws-sigv4", "aws:amz:" .. aws_region .. ":" .. service, "--user", aws_access_key .. ":" .. aws_secret_key }
    })

    if response and response.body then
        local decoded = vim.json.decode(response.body)
        if decoded and decoded.content and #decoded.content > 0 then
            return decoded.content[1].text
        end
    end
    return "Failed to get response"
end

local function get_git_diff()
    local handle = io.popen("git diff --cached --stat")
    if handle then
        local stat = handle:read("*a")
        handle:close()

        -- Get a summary of changes
        handle = io.popen("git diff --cached --numstat")
        if handle then
            local numstat = handle:read("*a")
            handle:close()

            -- Parse numstat to get total lines added/removed
            local total_added, total_removed = 0, 0
            for added, removed in numstat:gmatch("(%d+)%s+(%d+)") do
                total_added = total_added + tonumber(added)
                total_removed = total_removed + tonumber(removed)
            end

            local summary = string.format("Total: %d lines added, %d lines removed\n", total_added, total_removed)

            -- If the diff is too large, return only the summary and stats
            if total_added + total_removed > 1000 then
                return summary .. stat
            end
        end

        -- If the diff is not too large, get the full diff
        handle = io.popen("git diff --cached")
        if handle then
            local full_diff = handle:read("*a")
            handle:close()
            return full_diff
        end
    end
    return "Failed to get git diff"
end

function M.generate_commit_message()
    local diff = get_git_diff()
    if diff == "" then
        print("No staged changes found.")
        return
    end

    local commit_message = request_commit_message(diff)
    if commit_message and commit_message ~= "" then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(commit_message, "\n"))
        print("Commit message inserted.")
    else
        print("Failed to generate commit message.")
    end
end

vim.api.nvim_create_user_command("GitComet", M.generate_commit_message, {})

M.setup = function(opts)
    M.options = vim.tbl_extend("force", M.options, opts or {})
end

return M
