#!/usr/bin/env python3
"""真实 LLM 客户端（OpenAI 兼容）。

目标：把 LLM 调用从 demo/脚本里抽出来，方便在 pipeline 中复用。

约定：
- 走 OpenAI Python SDK（v1+）的 Chat Completions：client.chat.completions.create
- 支持 OpenAI 兼容服务（例如自建网关/Azure OpenAI compatible proxy），通过 base_url 指定。

配置（环境变量）：
- ODA_LLM_API_KEY        必填（也可用 OPENAI_API_KEY 兼容）
- ODA_LLM_MODEL          必填（例如 gpt-4o-mini / gpt-4.1 / 或你的私有模型名）
- ODA_LLM_BASE_URL       可选（OpenAI 兼容 endpoint；不填走官方默认）
- ODA_LLM_TEMPERATURE    可选（默认 0.2）
- ODA_LLM_MAX_TOKENS     可选（默认 2000）

说明：
- 不在代码里打印或回显 key。
- 如果未安装 openai 库，会抛出 ImportError；由上层脚本决定如何处理。
"""

from __future__ import annotations

import base64
import json
import os
import re
import time
from pathlib import Path
from dataclasses import dataclass
from typing import Any, Dict, Optional


@dataclass
class LLMConfig:
    api_key: str
    model: str
    base_url: str = ""
    temperature: float = 0.2
    max_tokens: int = 2000
    retries: int = 2
    timeout_s: float = 30.0


def _load_local_config() -> dict:
    def parse_from_text(text: str) -> dict:
        def extract(name: str) -> str:
            pattern = rf'^\s*{re.escape(name)}\s*=\s*(["\"])\s*(.*?)\s*\1'
            match = re.search(pattern, text, flags=re.MULTILINE | re.DOTALL)
            if not match:
                return ""
            value = match.group(2).replace("\r", "").replace("\n", "")
            return value.strip()

        return {
            "api_key": extract("ODA_LLM_API_KEY"),
            "model": extract("ODA_LLM_MODEL"),
            "base_url": extract("ODA_LLM_BASE_URL"),
            "temperature": extract("ODA_LLM_TEMPERATURE"),
            "max_tokens": extract("ODA_LLM_MAX_TOKENS"),
        }

    try:
        from . import local_llm_config  # type: ignore

        return {
            "api_key": getattr(local_llm_config, "ODA_LLM_API_KEY", ""),
            "model": getattr(local_llm_config, "ODA_LLM_MODEL", ""),
            "base_url": getattr(local_llm_config, "ODA_LLM_BASE_URL", ""),
            "temperature": getattr(local_llm_config, "ODA_LLM_TEMPERATURE", ""),
            "max_tokens": getattr(local_llm_config, "ODA_LLM_MAX_TOKENS", ""),
        }
    except Exception:
        local_path = Path(__file__).with_name("local_llm_config.py")
        if not local_path.exists():
            return {}
        return parse_from_text(local_path.read_text(encoding="utf-8", errors="ignore"))


def load_llm_config_from_env() -> LLMConfig:
    def decode_b64_env(name: str) -> str:
        raw = os.environ.get(name)
        if not raw:
            return ""
        try:
            return base64.b64decode(raw).decode("utf-8")
        except Exception:
            return ""

    local_cfg = _load_local_config()

    api_key = os.environ.get("ODA_LLM_API_KEY") or os.environ.get("OPENAI_API_KEY")
    if not api_key:
        api_key = decode_b64_env("ODA_LLM_API_KEY_B64")
    if not api_key:
        api_key = local_cfg.get("api_key", "")

    model = os.environ.get("ODA_LLM_MODEL")
    if not model:
        model = decode_b64_env("ODA_LLM_MODEL_B64")
    if not model:
        model = local_cfg.get("model", "")

    base_url = os.environ.get("ODA_LLM_BASE_URL", "").strip()
    if not base_url:
        base_url = str(local_cfg.get("base_url", "")).strip()

    if not api_key:
        raise ValueError("Missing env: ODA_LLM_API_KEY (or OPENAI_API_KEY)")
    if not model:
        raise ValueError("Missing env: ODA_LLM_MODEL")

    temperature_s = os.environ.get("ODA_LLM_TEMPERATURE", "")
    if not temperature_s:
        temperature_s = str(local_cfg.get("temperature", "0.2"))
    max_tokens_s = os.environ.get("ODA_LLM_MAX_TOKENS", "")
    if not max_tokens_s:
        max_tokens_s = str(local_cfg.get("max_tokens", "2000"))

    try:
        temperature = float(temperature_s)
    except Exception as e:
        raise ValueError(f"Invalid ODA_LLM_TEMPERATURE={temperature_s!r}: {e}")

    try:
        max_tokens = int(max_tokens_s)
    except Exception as e:
        raise ValueError(f"Invalid ODA_LLM_MAX_TOKENS={max_tokens_s!r}: {e}")

    retries_s = os.environ.get("ODA_LLM_RETRIES", "2")
    timeout_s = os.environ.get("ODA_LLM_TIMEOUT", "30")
    try:
        retries = max(0, int(retries_s))
    except Exception as e:
        raise ValueError(f"Invalid ODA_LLM_RETRIES={retries_s!r}: {e}")
    try:
        timeout = max(1.0, float(timeout_s))
    except Exception as e:
        raise ValueError(f"Invalid ODA_LLM_TIMEOUT={timeout_s!r}: {e}")

    return LLMConfig(
        api_key=str(api_key),
        model=str(model),
        base_url=base_url,
        temperature=temperature,
        max_tokens=max_tokens,
        retries=retries,
        timeout_s=timeout,
    )


def _classify_exception(exc: BaseException) -> str:
    text = f"{type(exc).__name__}: {exc}".lower()
    if "invalid api key" in text or "401" in text or "unauthorized" in text:
        return "auth_failed"
    if "rate limit" in text or "429" in text:
        return "rate_limited"
    if "timeout" in text:
        return "timeout"
    if "proxy" in text or "tunnel" in text:
        return "proxy_error"
    if "network is unreachable" in text or "connecterror" in text:
        return "network_unreachable"
    if "connection error" in text:
        return "connection_error"
    if "invalid request" in text or "400" in text:
        return "invalid_request"
    return "unknown_error"


def _proxy_snapshot() -> Dict[str, str]:
    # capture both upper/lowercase variants since some shells/tools only set one side
    keys = [
        "HTTP_PROXY",
        "HTTPS_PROXY",
        "ALL_PROXY",
        "NO_PROXY",
        "http_proxy",
        "https_proxy",
        "all_proxy",
        "no_proxy",
    ]
    return {k: os.environ.get(k, "") for k in keys if os.environ.get(k)}


class OpenAICompatLLM:
    """OpenAI 兼容 LLM client，提供 generate(prompt)->str 接口给 ODAGenerator 用。"""

    def __init__(self, cfg: LLMConfig):
        from openai import OpenAI  # type: ignore

        # 使用独立环境变量，避免污染全局配置
        if cfg.base_url:
            self._client = OpenAI(api_key=cfg.api_key, base_url=cfg.base_url)
        else:
            self._client = OpenAI(api_key=cfg.api_key)

        self._cfg = cfg

    def generate(
        self,
        prompt: str,
        *,
        system: Optional[str] = None,
        diag_path: Optional[Path] = None,
        request_tag: str = "generate",
    ) -> str:
        system_msg = system or "你是一个符号执行和程序分析专家。"
        attempts = []
        last_exc: Optional[BaseException] = None
        force_json = os.environ.get("ODA_LLM_JSON", "") in {"1", "true", "True"}

        for attempt in range(self._cfg.retries + 1):
            started = time.time()
            try:
                kwargs = {
                    "model": self._cfg.model,
                    "messages": [
                        {"role": "system", "content": system_msg},
                        {"role": "user", "content": prompt},
                    ],
                    "temperature": self._cfg.temperature,
                    "max_tokens": self._cfg.max_tokens,
                }
                if force_json:
                    kwargs["response_format"] = {"type": "json_object"}

                resp = self._client.chat.completions.create(
                    **kwargs,
                )
                content = resp.choices[0].message.content or ""
                attempts.append(
                    {
                        "attempt": attempt + 1,
                        "status": "success",
                        "elapsed_s": round(time.time() - started, 3),
                    }
                )
                if diag_path:
                    _write_diag(
                        diag_path,
                        self._build_diag_payload(request_tag, attempts, "success"),
                    )
                return content
            except BaseException as exc:
                last_exc = exc
                category = _classify_exception(exc)
                attempts.append(
                    {
                        "attempt": attempt + 1,
                        "status": "error",
                        "category": category,
                        "message": str(exc),
                        "elapsed_s": round(time.time() - started, 3),
                    }
                )
                if category in {"auth_failed", "invalid_request"}:
                    break
                if attempt < self._cfg.retries:
                    time.sleep(min(2 ** attempt, 4))

        if diag_path:
            _write_diag(
                diag_path,
                self._build_diag_payload(request_tag, attempts, "failed"),
            )
        if last_exc is not None:
            raise last_exc
        raise RuntimeError("LLM generation failed without exception details")

    def _build_diag_payload(self, request_tag: str, attempts: list, status: str) -> Dict[str, Any]:
        return {
            "request": request_tag,
            "status": status,
            "model": self._cfg.model,
            "base_url": self._cfg.base_url or "default",
            "temperature": self._cfg.temperature,
            "max_tokens": self._cfg.max_tokens,
            "retries": self._cfg.retries,
            "timeout_s": self._cfg.timeout_s,
            "proxy": _proxy_snapshot(),
            "attempts": attempts,
        }


def _write_diag(path: Path, data: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
