# 直接在远端解码凭据并运行 pipeline，避免依赖本地 .oda_llm_* 文件
$ODA_LLM_API_KEY_B64 = "c2stcHJvai1tU0h1R1VZRXhyTHJ4VVlrOGlKNE4zeFN3ck1ELWs1RGxadTdYcWxwb1k4Ul9HZUFFd2ZoSU1MWlpvYzBJZWZqOU1ROE5BOUFrWVQzQmxia0ZKd2VBbk1WbXFZOXplbUp6YTRDLUV5Q1p1TmxxUWg2RmdMb2x2QUF1U2hLYU1NSHA2M0VvdHhGWnhFVDkyTzJETjZzamFLVkhrTUE="
$ODA_LLM_MODEL_B64 = "Z3B0LTRvLW1pbmk="
$HTTP_PROXY_B64 = "aHR0cDovLzEyNy4wLjAuMTo3ODkw"
$HTTPS_PROXY_B64 = "aHR0cDovLzEyNy4wLjAuMTo3ODkw"
$ALL_PROXY_B64 = "c29ja3M1Oi8vMTI3LjAuMC4xOjc4OTA="

$remoteScriptTemplate = @'
set -ex
cd /home/guren/oda_work/oda_demo

echo "__KEY__" | base64 -d > .oda_llm_key.tmp
echo "__MODEL__"  | base64 -d > .oda_llm_model.tmp
ODA_LLM_API_KEY=$(cat .oda_llm_key.tmp)
ODA_LLM_MODEL=$(cat .oda_llm_model.tmp)
rm -f .oda_llm_key.tmp .oda_llm_model.tmp
export ODA_LLM_API_KEY ODA_LLM_MODEL

if [ -n "$ODA_LLM_BASE_URL_B64" ]; then
	echo "$ODA_LLM_BASE_URL_B64" | base64 -d > .oda_llm_base.tmp
	read -r ODA_LLM_BASE_URL < .oda_llm_base.tmp
	export ODA_LLM_BASE_URL
	rm -f .oda_llm_base.tmp
fi

echo "__HTTP__" | base64 -d > .oda_proxy_http.tmp
HTTP_PROXY=$(cat .oda_proxy_http.tmp)
export HTTP_PROXY http_proxy=$HTTP_PROXY
rm -f .oda_proxy_http.tmp

echo "__HTTPS__" | base64 -d > .oda_proxy_https.tmp
HTTPS_PROXY=$(cat .oda_proxy_https.tmp)
export HTTPS_PROXY https_proxy=$HTTPS_PROXY
rm -f .oda_proxy_https.tmp

echo "__ALL__" | base64 -d > .oda_proxy_all.tmp
ALL_PROXY=$(cat .oda_proxy_all.tmp)
export ALL_PROXY all_proxy=$ALL_PROXY
rm -f .oda_proxy_all.tmp

export ODA_FORCE_NEW_RUN=1
./scripts/ubuntu_run_pipeline.sh --api PathCombineW --wine-root /home/guren/wine --stub-mode llm --target-dll kernelbase --target-file path.c
'@

$remoteScript = $remoteScriptTemplate
$remoteScript = $remoteScript.Replace("__KEY__", $ODA_LLM_API_KEY_B64)
$remoteScript = $remoteScript.Replace("__MODEL__", $ODA_LLM_MODEL_B64)
$remoteScript = $remoteScript.Replace("__HTTP__", $HTTP_PROXY_B64)
$remoteScript = $remoteScript.Replace("__HTTPS__", $HTTPS_PROXY_B64)
$remoteScript = $remoteScript.Replace("__ALL__", $ALL_PROXY_B64)

# Normalize to LF and base64 encode
$remoteScriptLf = $remoteScript -replace "`r`n", "`n"
$remoteCmdB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($remoteScriptLf))
$remoteCmd = "bash -lc 'echo $remoteCmdB64 | base64 -d | bash'"

ssh -i C:\Users\Administrator\.ssh\id_ed25519 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null guren@192.168.154.129 "$remoteCmd"
