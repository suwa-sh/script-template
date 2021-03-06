#!/bin/bash
#set -eux
#==================================================================================================
# セマフォユーティリティ
#
# 前提
#   ・setenv.sh を事前に読み込んでいること
#       ・${DIR_DATA}が事前に設定されていること
#       ・${PATH_PID}が事前に設定されていること
#
# 定義リスト
#   ・semaphore.acquire
#   ・semaphore.release
#==================================================================================================
#--------------------------------------------------------------------------------------------------
# 依存スクリプト読込み
#--------------------------------------------------------------------------------------------------
# ログ出力ユーティリティ
. ${DIR_BIN_LIB}/logging_utils.sh



#--------------------------------------------------------------------------------------------------
# 概要
#   private：現在のロック状態をチェックします。
#            ロック中の場合は、exit ${EXITCODE_ERROR} で処理を終了させます。
#
# 引数
#   なし
#
# 戻り値
#   0: 正常終了
#   6: エラー発生時 ※ exit
#
#--------------------------------------------------------------------------------------------------
function semaphore.local.status_check() {
  #--------------------------------------------------
  # 事前処理
  #--------------------------------------------------
  log.debug_console "${FUNCNAME[0]} $@"
  log.add_indent

  # 引数の数
  if [ $# -ne 0 ]; then
    log.error_console "Usage: ${FUNCNAME[0]}"
    log.remove_indent
    return ${EXITCODE_ERROR}
  fi

  #--------------------------------------------------
  # 本処理
  #--------------------------------------------------
  if [ -f ${PATH_PID} ]; then
    # プロセスファイルが存在する場合
    local _running_process_id=`cat ${PATH_PID} | cut -d ' ' -f 1 | cut -d ':' -f 2`
    local _running_process=`cat ${PATH_PID} | cut -d ' ' -f 2 | cut -d ':' -f 2`
    log.error_console "他の処理を実行中です。実行中のプロセスID：${_running_process_id}、実行中のプロセス：${_running_process}"
    exit ${EXITCODE_ERROR}
  fi

  #--------------------------------------------------
  # 事後処理
  #--------------------------------------------------
  log.remove_indent
  return ${EXITCODE_SUCCESS}
}


#--------------------------------------------------------------------------------------------------
# 概要
#   ${DIR_DATA} 直下にプロセスファイルを作成して、ロック状態にします。
#   既にロック中の場合は、exit ${EXITCODE_ERROR} でプロセスを強制終了します。
#
# 引数
#   ・1: 呼出し元 (シェル名など)
#
# 出力
#   ・${PATH_PID}
#
# 戻り値
#   0: 正常終了
#   6: エラー発生時 ※exit
#
#--------------------------------------------------------------------------------------------------
function semaphore.acquire() {
  #--------------------------------------------------
  # 事前処理
  #--------------------------------------------------
  log.debug_console "${FUNCNAME[0]} $@"
  log.add_indent

  # 引数の数
  if [ $# -ne 1 ]; then
    log.error_console "Usage: ${FUNCNAME[0]} FROM"
    log.remove_indent
    return ${EXITCODE_ERROR}
  fi

  # 呼出し元
  local _from="$1"

  # dataディレクトリの存在チェック
  if [ ! -d ${DIR_DATA} ]; then
    # 存在しない場合
    mkdir -p ${DIR_DATA}
  fi

  #--------------------------------------------------
  # 本処理
  #--------------------------------------------------
  local _ret_code=${EXITCODE_SUCCESS}

  # ロック状態チェック
  semaphore.local.status_check

  # プロセスファイル作成
  log.debug_console "echo \"PID:$$ run:${_from}\" > ${PATH_PID}"
  echo "PID:$$ run:${_from}"                                                                         > ${PATH_PID}
  _ret_code=$?

  # 実行結果チェック
  if [ ${_ret_code} -ne ${EXITCODE_SUCCESS} ]; then
    # 正常終了ではない場合
    log.error_console "プロセスファイルの作成に失敗しました。リターンコード：${_ret_code}"
    _ret_code=${EXITCODE_ERROR}
  fi

  #--------------------------------------------------
  # 事後処理
  #--------------------------------------------------
  log.remove_indent
  return ${_ret_code}
}



#--------------------------------------------------------------------------------------------------
# 概要
#   ${DIR_DATA} 直下のプロセスファイルを削除して、ロックを解除します。
#
# 引数
#   なし
#
# 戻り値
#   0: 正常終了
#   3: プロセスファイルが存在しない場合
#   6: エラー発生時
#
#--------------------------------------------------------------------------------------------------
function semaphore.release() {
  #--------------------------------------------------
  # 事前処理
  #--------------------------------------------------
  log.debug_console "${FUNCNAME[0]} $@"
  log.add_indent

  # 引数の数
  if [ $# -ne 0 ]; then
    log.error_console "Usage: ${FUNCNAME[0]}"
    log.remove_indent
    return ${EXITCODE_ERROR}
  fi

  #--------------------------------------------------
  # 本処理
  #--------------------------------------------------
  local _ret_code=${EXITCODE_SUCCESS}

  # ファイル存在チェック
  if [ -f ${PATH_PID} ]; then
    # プロセスファイルが存在する場合

    # プロセスファイル削除
    log.debug_console "rm -f ${PATH_PID}"
    rm -f ${PATH_PID}
    _ret_code=$?

    # 実行結果チェック
    if [ ${_ret_code} -ne ${EXITCODE_SUCCESS} ]; then
      # 正常終了ではない場合
      log.error_console "プロセスファイルの削除に失敗しました。リターンコード：${_ret_code}、ファイルパス：${PATH_PID}"
      _ret_code=${EXITCODE_ERROR}
    fi

  else
    # プロセスファイルが存在しない場合
    _ret_code=${EXITCODE_WARN}
  fi

  #--------------------------------------------------
  # 事後処理
  #--------------------------------------------------
  log.remove_indent
  return ${_ret_code}
}
