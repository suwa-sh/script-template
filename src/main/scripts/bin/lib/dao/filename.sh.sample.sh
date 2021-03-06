#!/bin/bash
#set -eux
#==================================================================================================
# @対象ファイル論理名@ 操作ユーティリティ
#
# 前提
#   ・setenv.sh を事前に読み込んでいること
#       ・${@対象ファイルパス定数@}が事前に設定されていること
#   ・ファイル形式
#       ・フォーマット: CSV形式
#          ・括り文字   : "
#          ・エスケープ : "
#          ・必ず括るか : false
#       ・文字コード  : utf8
#       ・改行コード  : LF
#   ・ファイルレイアウト
#       カラム名1 カラム名2
#
# 定義リスト
#   ・@対象ファイル物理名@ .find_all
#   ・@対象ファイル物理名@ .find_by_@カラム名@
#   ・@対象ファイル物理名@ .get_@カラム名@
#
#==================================================================================================
#--------------------------------------------------------------------------------------------------
# 依存スクリプト読込み
#--------------------------------------------------------------------------------------------------
# 共通ユーティリティ
. ${DIR_BIN_LIB}/common_utils.sh
# ログ出力ユーティリティ
. ${DIR_BIN_LIB}/logging_utils.sh



#--------------------------------------------------------------------------------------------------
# 概要
#   全行を返します。
#
# 前提
#   なし
#
# 引数
#   なし
#
# 標準出力
#   全行リスト
#
# 戻り値
#   0: 正常終了
#   6: 異常終了
#
#--------------------------------------------------------------------------------------------------
function @対象ファイル物理名@ .find_all() {
  #--------------------------------------------------
  # 事前処理
  #--------------------------------------------------
  # 引数の数
  if [ $# -ne 0 ]; then
    log.error_console "Usage: ${FUNCNAME[0]}"
    return ${EXITCODE_ERROR}
  fi

  # TODO ファイルの存在確認 を local functionに切り出す！
  if [ ! -f ${@対象ファイルパス定数@} ]; then
    log.error_console "${@対象ファイルパス定数@} が存在しません。"
    return ${EXITCODE_ERROR}
  fi


  #--------------------------------------------------
  # 本処理
  #--------------------------------------------------
  cat ${@対象ファイルパス定数@}                                                                    | # @対象ファイル論理名@ から
  _except_comment_row                                                                              | # コメント行を除外
  _except_empty_row                                                                                | # 空行を除外
  _trim                                                                                            | # トリム
  sort                                                                                               # ソート


  #--------------------------------------------------
  # 事後処理
  #--------------------------------------------------
  return ${EXITCODE_SUCCESS}
}



#--------------------------------------------------------------------------------------------------
# 概要
#   指定の@カラム名@に一致する行を出力します
#
# 前提
#   なし
#
# 引数
#   ・$1: @カラム名@
#
# 標準出力
#   マッチするする行リスト
#
# 戻り値
#   0: 正常終了
#   6: 異常終了
#
#--------------------------------------------------------------------------------------------------
function @対象ファイル物理名@.find_by_@カラム名@() {
  #--------------------------------------------------
  # 事前処理
  #--------------------------------------------------
  # 引数の数
  if [ $# -ne 1 ]; then
    log.error_console "Usage: ${FUNCNAME[0]} @カラム名@"
    return ${EXITCODE_ERROR}
  fi

  # TODO ファイルの存在確認 を local functionに切り出す！

  # @カラム名@
  local _value="$1"


  #--------------------------------------------------
  # 本処理
  #--------------------------------------------------
  local _before_IFS=$IFS
  IFS=$'\n'

  for _cur_row in `@対象ファイル物理名@.find_all`; do
    local _cur_value=`echo ${_cur_row} | @対象ファイル物理名@.get_@カラム名@`
    if [ "${_cur_value}" = "${_value}" ]; then
      echo ${_cur_row}
    fi
  done

  IFS=${_before_IFS}


  #--------------------------------------------------
  # 事後処理
  #--------------------------------------------------
  return ${EXITCODE_SUCCESS}
}



#--------------------------------------------------------------------------------------------------
# 概要
#   パイプで渡された行データから、@カラム名@を返します
#
# 前提
#   なし
#
# 引数
#   なし
#
# 標準出力
#   @カラム名@
#
#--------------------------------------------------------------------------------------------------
function @対象ファイル物理名@.get_@カラム名@() {
  cat -                                                                                            | # 標準入力から
  ${DIR_BIN_LIB}/Parsrs/parsrc.sh                                                                  | # CSVをパース
  grep ^"1 @カラム番号@"                                                                           | # @カラム名@の行のみに絞り込み
  cut -d ' ' -f 3-                                                                                 | # 値を抽出
  _trim                                                                                              # トリム

  return ${EXITCODE_SUCCESS}
}
