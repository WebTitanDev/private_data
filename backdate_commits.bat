@echo off
setlocal EnableDelayedExpansion

:: ==== CONFIG ====
set "GIT_NAME=WebTitanDev"
set "GIT_EMAIL=devcraft1002@gmail.com"
set "REPO_DIR=historical-contributions"
set "SKIP_COUNT=5"

:: ==== INIT ====
mkdir %REPO_DIR%
cd %REPO_DIR%
git init
git config user.name "%GIT_NAME%"
git config user.email "%GIT_EMAIL%"
type nul > activity.log

:: ==== LOOP THROUGH YEARS AND MONTHS ====
for /L %%Y in (2013,1,2019) do (
  for /L %%M in (1,1,12) do (
    set "YEAR=%%Y"
    set "MONTH=%%M"
    if !MONTH! LSS 10 set "MONTH=0!MONTH!"

    echo Processing !YEAR!-!MONTH!...

    :: Reset counters
    set "days="
    set "validDays="
    set /A count=0

    :: Build a list of all weekdays in this month
    for /L %%D in (1,1,31) do (
      set "DAY=%%D"
      if !DAY! LSS 10 set "DAY=0!DAY!"

      call :IsValidDate !YEAR! !MONTH! !DAY!
      if "!VALID!"=="true" (
        powershell -Command ^
          "$d=[datetime]::ParseExact('%YEAR%-%MONTH%-%DAY%','yyyy-MM-dd',$null); if ($d.DayOfWeek -ne 'Saturday' -and $d.DayOfWeek -ne 'Sunday') { exit 0 } else { exit 1 }"
        if !errorlevel! == 0 (
          set "validDays=!validDays!!DAY! "
          set /A count+=1
        )
      )
    )

    :: Randomly skip 5 days
    for /L %%S in (1,1,%SKIP_COUNT%) do (
      set /A randIdx=!random! %% !count!
      for %%T in (!validDays!) do (
        if !randIdx! == 0 (
          set "skipDay=%%T"
          set "validDays=!validDays:%%T =!"
          set /A count-=1
          goto skip_selected
        )
        set /A randIdx-=1
      )
      :skip_selected
    )

    :: Now commit remaining validDays
    for %%D in (!validDays!) do (
      set "DATE_STR=!YEAR!-!MONTH!-%%D"
      echo Commit on !DATE_STR!
      echo Log for !DATE_STR! >> activity.log

      set "GIT_AUTHOR_DATE=!DATE_STR! 12:00:00"
      set "GIT_COMMITTER_DATE=!DATE_STR! 12:00:00"

      cmd /C "set GIT_AUTHOR_DATE=!GIT_AUTHOR_DATE!&& set GIT_COMMITTER_DATE=!GIT_COMMITTER_DATE!&& git add activity.log && git commit -m \"Commit on !DATE_STR!\" >nul"
    )
  )
)

echo.
echo ✅ Done! You can now push to GitHub.

exit /b

:IsValidDate
:: %1 = year, %2 = month, %3 = day
powershell -Command ^
  "try { [datetime]::ParseExact('%1-%2-%3','yyyy-MM-dd',$null) | Out-Null; exit 0 } catch { exit 1 }"
if %ERRORLEVEL% == 0 (
  set "VALID=true"
) else (
  set "VALID=false"
)
exit /b
