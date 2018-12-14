@set working_directory=%~dp0
@powershell -ExecutionPolicy ByPass -NoProfile -File %working_directory%start.ps1 %*
