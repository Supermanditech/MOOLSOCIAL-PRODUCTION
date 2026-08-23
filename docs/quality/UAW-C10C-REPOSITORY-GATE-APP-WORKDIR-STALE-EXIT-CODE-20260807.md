# C10C repository gate invoked from app workdir

The repository memory checker was called through a repository-relative path while the command ran in `apps/mobile`. PowerShell emitted a non-terminating lookup error, and stale native-process exit state yielded a misleading success result; the intended Flutter tests did not run. Repository gates and app tests now run as separate commands in their proper working directories, with terminating script-error handling.
