local M = {}
local uv = vim.uv;

local ev = uv.new_fs_event();

function M.start(path)
  uv.fs_event_start(ev, path, {}, function(err, file, events)
    vim.schedule(function() vim.cmd(":cgetfile " .. path) end)
  end);
end

function M.stop()
  uv.fs_event_stop(ev)
end

return M;
