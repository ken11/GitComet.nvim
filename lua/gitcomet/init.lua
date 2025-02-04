local M = {}
local curl = require("plenary.curl")

local aws_keys = os.getenv("BEDROCK_KEYS")
local aws_access_key, aws_secret_key, aws_region = aws_keys:match("([^,]+),([^,]+),([^,]+)")
local service = "bedrock-runtime"

M.options = {
    model_id = "anthropic.claude-3-5-sonnet-20240620-v1:0",
    system_prompt = "Gitのコミットメッセージを最適に生成するAIとして振る舞ってください。\n長すぎず短すぎず簡潔にまとめるよう心がけます。",
    max_tokens = 1024
}

local function request_commit_message(diff)
    local payload = {
        system = M.options.system_prompt,
        messages = {
            { role = "user", content = "以下のGitDiffは現在の git diff コマンドの結果です。このGitDiffの内容に基づいて適切なコミットメッセージを考えてください。\n\n<GitDiff>\n" .. diff .. "\n</GitDiff>" }
        },
        max_tokens = M.options.max_tokens
    }

    local response = curl.post("https://" .. service .. "." .. aws_region .. ".amazonaws.com/model/" .. M.options.model_id .. "/invoke", {
        headers = {
            ["Content-Type"] = "application/json"
        },
        body = vim.fn.json_encode(payload),
        raw = { "--sigv4", "aws:amz:" .. aws_region .. ":" .. service, "--user", aws_access_key .. ":" .. aws_secret_key }
    })

    if response and response.body then
        return response.body
    else
        return "Failed to get response"
    end
end

local function get_git_diff()
    local handle = io.popen("git diff --cached")
    if handle then
        local result = handle:read("*a")
        handle:close()
        return result
    else
        return "Failed to get git diff"
    end
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
