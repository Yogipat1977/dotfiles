-- Track background jobs (shared across the config)
local typst_jobs = {}

-----------------------------------------------------------------
-- Cursor-following sync: Neovim cursor → Zathura page (D-Bus)
-- Typst has no SyncTeX, so we approximate the page from the
-- line-position ratio and use Zathura's D-Bus GotoPage API.
-----------------------------------------------------------------
local sync_timer = nil
local page_cache = {} -- pdf_path → { pages = N, mtime = last_modified }

--- Refocus Neovim after D-Bus touches Zathura (Hyprland/Wayland)
local function refocus_neovim()
  vim.system({ "hyprctl", "dispatch", "focuswindow", "pid:" .. vim.fn.getpid() })
end

--- Get total page count of a PDF (cached, refreshes when file changes)
local function get_pdf_pages(pdf_path)
  local stat = vim.uv.fs_stat(pdf_path)
  if not stat then return nil end

  local cached = page_cache[pdf_path]
  if cached and cached.mtime == stat.mtime.sec then
    return cached.pages
  end

  local out = vim.fn.system("pdfinfo " .. vim.fn.shellescape(pdf_path) .. " 2>/dev/null")
  local pages = tonumber(out:match("Pages:%s*(%d+)"))
  if pages and pages > 0 then
    page_cache[pdf_path] = { pages = pages, mtime = stat.mtime.sec }
    return pages
  end
  return nil
end

--- Send D-Bus GotoPage to the tracked Zathura instance
local function sync_cursor_to_zathura()
  local file = vim.fn.expand("%:p")
  local jobs = typst_jobs[file]
  if not jobs or not jobs.zathura then return end

  -- Get Zathura PID for D-Bus addressing
  local ok, pid = pcall(vim.fn.jobpid, jobs.zathura)
  if not ok or not pid then return end

  local pdf = vim.fn.expand("%:p:r") .. ".pdf"
  local total_pages = get_pdf_pages(pdf)
  if not total_pages or total_pages <= 1 then return end

  local cur_line   = vim.fn.line(".")
  local total_lines = vim.fn.line("$")

  -- Map line ratio → page (0-indexed for D-Bus)
  local page = math.floor(((cur_line - 1) / total_lines) * total_pages)
  page = math.max(0, math.min(total_pages - 1, page))

  -- Skip if we're already on this page
  if jobs.last_page == page then return end
  jobs.last_page = page

  -- D-Bus GotoPage, then immediately refocus Neovim
  vim.system({
    "dbus-send", "--session", "--type=method_call",
    string.format("--dest=org.pwmt.zathura.PID-%d", pid),
    "/org/pwmt/zathura",
    "org.pwmt.zathura.GotoPage",
    string.format("uint32:%d", page),
  }, {}, function()
    vim.schedule(refocus_neovim)
  end)
end

--- Debounced wrapper (250 ms after cursor stops)
local function schedule_sync()
  if sync_timer then
    sync_timer:stop()
    sync_timer:close()
  end
  sync_timer = vim.uv.new_timer()
  sync_timer:start(250, 0, vim.schedule_wrap(function()
    sync_cursor_to_zathura()
    if sync_timer then
      sync_timer:close()
      sync_timer = nil
    end
  end))
end

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
    -- Auto-save .typ files (event-driven + fallback timer)
    -----------------------------------------------------------------
    -- Primary: save on text change and when leaving insert mode
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
      pattern = "*.typ",
      callback = function()
        if vim.bo.modified then
          vim.cmd("silent! update")
        end
      end,
    })

    -- Fallback: 1-second timer catches any missed saves
    local autosave_timer = vim.uv.new_timer()
    autosave_timer:start(1000, 1000, vim.schedule_wrap(function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf)
          and vim.bo[buf].buftype == ""
          and vim.api.nvim_buf_get_name(buf):match("%.typ$")
          and vim.bo[buf].modified then
          vim.api.nvim_buf_call(buf, function()
            vim.cmd("silent! update")
          end)
        end
      end
    end))

    -----------------------------------------------------------------
    -- Cursor-following autocmd (only fires when TypstPDF is active)
    -----------------------------------------------------------------
    vim.api.nvim_create_augroup("TypstZathuraSync", { clear = true })
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      group = "TypstZathuraSync",
      pattern = "*.typ",
      callback = function()
        local file = vim.fn.expand("%:p")
        if typst_jobs[file] and typst_jobs[file].zathura then
          schedule_sync()
        end
      end,
    })

    -----------------------------------------------------------------
    -- :TypstPDF  –  live-compile and preview in Zathura
    --   • starts `typst watch <file>` in the background
    --   • opens Zathura on the output PDF (Zathura auto-reloads)
    --   • cursor movement auto-scrolls Zathura to the right page
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

      -- Wait for initial compile, open Zathura, then refocus Neovim
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
        -- Refocus Neovim after Zathura window appears
        vim.defer_fn(refocus_neovim, 600)
      end, 500)
    end, { desc = "Compile Typst to PDF and preview in Zathura (with cursor follow)" })

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
    -- Cleanup all jobs + timers when Neovim exits
    -----------------------------------------------------------------
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        if autosave_timer then
          autosave_timer:stop()
          autosave_timer:close()
        end
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
