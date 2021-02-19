#!/bin/bash
echo "*** JP1ジョブインポート ***"
echo "Rev.2019.09.06"
echo

# 実行shの階層に移動
shDir=`dirname $0`
cd $shDir

# 実行時間をセット
exeTime=`date '+%Y%m%dT%H%M%S'`
# ログ出力設定
scriptName=`basename $0 .sh`
mkdir -p log
logFile=log/${scriptName}_${exeTime}.log

# configファイルを読み込む
DATA=`cat config.ini`
# 「=」でセパレートしてループ
while IFS== read key val
do
    # 空行はスキップ
    if [ -z "${key}" ]; then continue; fi
    # SECTION判定
    if [[ ${key} == \[*\] ]]; then
        SECTION=${key}; echo $SECTION
        continue
    fi
    # jobGroopセクション
    if [[ ${SECTION} == "[jobGroop]" ]]; then
        echo ${key}=${val}
        declare ${key}=${val}
    fi
done << FILE
$DATA
FILE

# 実行shの階層にあるディレクトリから選択させる※logディレクトリは除外
echo
echo "インポート対象ディレクトリを選択してください"
select importDir in `find -mindepth 1 -maxdepth 1 -type d -not -path "./log"`
do
    # 選択された値の確認
    if [ -z "$importDir" ]; then
        echo "リスト内の数値を選択してください"
        continue
    fi

    echo "JP1の「$jobGroopBase」以下に「$importDir」内の定義をインポートします" | tee -a $logFile
    read -p "よろしいですか？(y/n):" yn
    case "$yn" in 
        [yY] ) echo "続行します" | tee -a $logFile ;; 
        * ) echo "キャンセルします" | tee -a $logFile ; exit ;;
    esac

    # インポート階層以下のファイルを取得しループ
    cd $importDir
    for targetDefineFile in `find -type f`
    do
        # ※ディレクトリ名取得後、先頭のカンマを外す
        defineDir=`dirname $targetDefineFile`; defineDir=${defineDir#\.}
        # dオプション設定（"${jobGroopBase}${defineDir}"が空文字ならdオプション解除）
        dParam="-d ${jobGroopBase}${defineDir}"
        if [ -z "${jobGroopBase}${defineDir}" ]; then dParam=""; fi
        # インポート
        sudo /opt/jp1ajs2/bin/ajsdefine -f $dParam $targetDefineFile 2>&1 | tee -a ../$logFile
        # コマンドの戻り値判定
        if [ ${PIPESTATUS[0]} == 0 ]; then
            echo "$targetDefineFile インポート完了" | tee -a ../$logFile
        else
            echo "$targetDefineFile インポート失敗" | tee -a ../$logFile
        fi
    done

    # select処理を抜ける
	break
done
