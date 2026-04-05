-- Track background jobs (shared across the config)
local typst_jobs = {}

return {
  'chomosuke/typst-preview.nvim',
  ft = 'typst',
  version = '1.*',
  build = function()
    require('typst-preview').update()
  end,
  config = function()
    require('typst-preview').setup({
      -- This function ensures that even when you are in /chapters/01_intro.typ,
      -- the previewer knows to render the whole project starting from main.typ
      get_root_file = function()
        return "main.typ"
      end,
      -- Optional: Set the follow mode to 'document' so the preview
      -- scrolls as you move your cursor in Neovim
      follow_cursor = true,
    })

    -----------------------------------------------------------------
    -- Auto-save .typ files on every text change (no :w needed)
    -----------------------------------------------------------------
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      pattern = "*.typ",
      callback = function()
        vim.cmd("silent! update")
      end,
    })

    -----------------------------------------------------------------
    -- :TypstPDF  –  live-compile and preview in Zathura
    --   • starts `typst watch <file>` in the background
    --   • opens Zathura on the output PDF (Zathura auto-reloads)
    -----------------------------------------------------------------
    vim.api.nvim_create_user_command("TypstPDF", function()
      local file = vim.fn.expand("%:p")
      local pdf  = vim.fn.expand("%:p:r") .. ".pdf"

      -- Kill any existing jobs for this file first
      if typst_jobs[file] then
        pcall(vim.fn.jobstop, typst_jobs[file].watch)
        if typst_jobs[file].zathura then
          pcall(vim.fn.jobstop, typst_jobs[file].zathura)
        end
      end

      -- Start typst watch (recompiles on every file change)
      local watch_id = vim.fn.jobstart({ "typst", "watch", file }, {
        on_stderr = function(_, data)
          for _, line in ipairs(data) do
            if line ~= "" then
              vim.schedule(function()
                vim.notify("typst: " .. line, vim.log.levels.WARN)
              end)
            end
          end
        end,
      })

      typst_jobs[file] = { watch = watch_id }
      vim.notify("Typst → Zathura: watching " .. vim.fn.expand("%:t"))

      -- Wait briefly for the initial compile, then open Zathura
      vim.defer_fn(function()
        local zathura_id = vim.fn.jobstart({ "zathura", pdf }, {
          on_exit = function()
            if typst_jobs[file] then
              pcall(vim.fn.jobstop, typst_jobs[file].watch)
              typst_jobs[file] = nil
            end
          end,
        })
        typst_jobs[file].zathura = zathura_id
      end, 500)
    end, { desc = "Compile Typst to PDF and preview in Zathura" })

    -----------------------------------------------------------------
    -- :TypstPDFStop  –  stop watching and close Zathura
    -----------------------------------------------------------------
    vim.api.nvim_create_user_command("TypstPDFStop", function()
      local file = vim.fn.expand("%:p")
      if typst_jobs[file] then
        pcall(vim.fn.jobstop, typst_jobs[file].watch)
        if typst_jobs[file].zathura then
          pcall(vim.fn.jobstop, typst_jobs[file].zathura)
        end
        typst_jobs[file] = nil
        vim.notify("Typst → Zathura: stopped")
      else
        vim.notify("No active Typst watcher for this file", vim.log.levels.INFO)
      end
    end, { desc = "Stop Typst watcher and close Zathura" })

    -----------------------------------------------------------------
    -- Cleanup all jobs when Neovim exits
    -----------------------------------------------------------------
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        for _, jobs in pairs(typst_jobs) do
          pcall(vim.fn.jobstop, jobs.watch)
          if jobs.zathura then
            pcall(vim.fn.jobstop, jobs.zathura)
          end
        end
      end,
    })
  end,
}
