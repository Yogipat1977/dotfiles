
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2") 
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true

-- persistent undo
local undodir = vim.fn.stdpath("data") .. "/undo"
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir)
end

vim.opt.undofile = true
vim.opt.undodir = undodir
