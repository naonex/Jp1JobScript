#!/bin/bash
echo "*** JP1ジョブグループエクスポート ***"
echo "Rev.2019.07.16"

# 実行shの階層に移動
shDir=`dirname $0`
cd $shDir

# 実行時間をセット
exeTime=`date '+%Y%m%dT%H%M%S'`
# ログ出力設定
scriptName=`basename $0 .sh`
mkdir -p log
logFile=log/${scriptName}_${exeTime}.log

#出力先設定
outJobGroopDir=${scriptName}_${exeTime}

# 対象ジョブグループリストを読み込む
DATA=`cat targetJobGroopList.txt`
while read targetJobGroop
do
    echo $targetJobGroop | tee -a $logFile

    # 対象ジョブグループ以下のジョブグループ名を取得しループ
    for target in `sudo /opt/jp1ajs2/bin/ajsname -R -G ${targetJobGroop}`
    do
        # ジョブグループ定義出力先作成※${target}は先頭に/を含むので区切らない
        jobGroopDir=`dirname $target`
        mkdir -p ${outJobGroopDir}${jobGroopDir}
        # ジョブグループ定義出力
        sudo /opt/jp1ajs2/bin/ajsprint -G ${target} > ${outJobGroopDir}${target}.txt
        # コマンドの戻り値判定
        if [ ${PIPESTATUS[0]} == 0 ]; then
            echo "$target エクスポート完了" | tee -a $logFile
        else
            echo "$target エクスポート失敗" | tee -a $logFile
        fi
    done
done << FILE
$DATA
FILE
