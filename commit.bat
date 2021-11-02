if %cd%==%cd:~,3% echo 当前目录已经是%cd:~,1%盘的根目录！&goto end
set work_path=Dir
echo "-----------"
git add .
git commit -m "cron  commit"
git push