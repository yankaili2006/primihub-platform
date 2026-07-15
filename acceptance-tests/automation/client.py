#!/usr/bin/env python3
"""
PrimihubClient — authenticated API client for the PrimiHub platform webconsole.

Replicates the webconsole's auth handshake so automation can drive the *real*
backend (not file-existence guesses):

  1. GET  {api}/sys/common/getValidatePublicKey   -> {publicKey, publicKeyName}
  2. RSA-encrypt the password (JSEncrypt == RSA/PKCS1 v1.5) with publicKey
  3. POST {api}/sys/user/login  (form-encoded, captchaVerification='' on first try)
  4. On code 121 / (109 && result>3): solve the AJ-Captcha slide block and retry.

Every request injects timestamp/nonce/token (mirrors src/utils/request.js) and
sends the `token` + `userId` headers. Uses only the stdlib for HTTP; RSA uses
whichever of cryptography / pycryptodome / rsa is installed.

Config via env (see automation/config.py defaults):
  PRIMIHUB_WEB_URL   e.g. http://<vm-ip>:30811   (webconsole origin)
  PRIMIHUB_API_BASE  default /prod-api
  PRIMIHUB_USER      default admin
  PRIMIHUB_PASS      default primihub123
"""
from __future__ import annotations

import base64
import json
import os
import random
import ssl
import time
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Optional

DEFAULT_WEB_URL = os.environ.get("PRIMIHUB_WEB_URL", "http://100.64.0.25:30811")
DEFAULT_API_BASE = os.environ.get("PRIMIHUB_API_BASE", "/prod-api")
DEFAULT_USER = os.environ.get("PRIMIHUB_USER", "admin")
DEFAULT_PASS = os.environ.get("PRIMIHUB_PASS", "primihub123")

TOKEN_CACHE = Path(os.environ.get(
    "PRIMIHUB_TOKEN_CACHE",
    str(Path.home() / ".cache" / "primihub-func" / "token.json"),
))


class PrimihubError(RuntimeError):
    """Raised when the platform returns a non-zero business code we can't handle."""

    def __init__(self, code: Any, msg: str, path: str = "") -> None:
        self.code = code
        self.msg = msg
        super().__init__(f"[code={code}] {msg} ({path})")


# ---------------------------------------------------------------------------
# RSA (JSEncrypt-compatible: RSA/ECB/PKCS1v1.5, public key is base64 X.509 DER)
# ---------------------------------------------------------------------------

def _pem_from_b64(pub_b64: str) -> str:
    pub_b64 = pub_b64.strip()
    if "BEGIN PUBLIC KEY" in pub_b64:
        return pub_b64
    body = "\n".join(pub_b64[i:i + 64] for i in range(0, len(pub_b64), 64))
    return f"-----BEGIN PUBLIC KEY-----\n{body}\n-----END PUBLIC KEY-----\n"


def rsa_encrypt(plaintext: str, public_key_b64: str) -> str:
    """Encrypt with PKCS1 v1.5, return base64 — matching frontend JSEncrypt."""
    pem = _pem_from_b64(public_key_b64)
    data = plaintext.encode("utf-8")

    # Backend 1: cryptography
    try:
        from cryptography.hazmat.primitives.asymmetric import padding
        from cryptography.hazmat.primitives.serialization import load_pem_public_key
        key = load_pem_public_key(pem.encode())
        ct = key.encrypt(data, padding.PKCS1v15())
        return base64.b64encode(ct).decode()
    except Exception:
        pass

    # Backend 2: pycryptodome
    try:
        from Crypto.Cipher import PKCS1_v1_5
        from Crypto.PublicKey import RSA
        key = RSA.import_key(pem)
        ct = PKCS1_v1_5.new(key).encrypt(data)
        return base64.b64encode(ct).decode()
    except Exception:
        pass

    # Backend 3: rsa
    try:
        import rsa as _rsa
        key = _rsa.PublicKey.load_pkcs1_openssl_pem(pem.encode())
        ct = _rsa.encrypt(data, key)
        return base64.b64encode(ct).decode()
    except Exception as e:  # pragma: no cover
        raise PrimihubError(
            "no-rsa-backend",
            "need one of: cryptography / pycryptodome / rsa "
            f"(pip install cryptography) — last error: {e}",
        )


class PrimihubClient:
    def __init__(
        self,
        web_url: str = DEFAULT_WEB_URL,
        user: str = DEFAULT_USER,
        password: str = DEFAULT_PASS,
        api_base: str = DEFAULT_API_BASE,
        timeout: int = 20,
    ) -> None:
        self.web_url = web_url.rstrip("/")
        self.api = api_base if api_base.startswith("/") else "/" + api_base
        self.user = user
        self.password = password
        self.timeout = timeout
        self.token: str = ""
        self.user_id: Optional[Any] = None
        self.sys_user: dict[str, Any] = {}
        self._ctx = ssl.create_default_context()
        self._ctx.check_hostname = False
        self._ctx.verify_mode = ssl.CERT_NONE

    # -- low-level ----------------------------------------------------------
    def _url(self, path: str) -> str:
        if path.startswith("http"):
            return path
        if not path.startswith("/"):
            path = "/" + path
        return f"{self.web_url}{self.api}{path}"

    def _headers(self) -> dict[str, str]:
        h = {"Accept": "application/json"}
        if self.token:
            h["token"] = self.token
        if self.user_id is not None:
            h["userId"] = str(self.user_id)
        return h

    def _envelope(self) -> dict[str, Any]:
        return {
            "timestamp": int(time.time() * 1000),
            "nonce": random.randint(1, 1000),
            "token": self.token or "",
        }

    def _open(self, req: urllib.request.Request) -> dict[str, Any]:
        try:
            with urllib.request.urlopen(req, timeout=self.timeout, context=self._ctx) as r:
                raw = r.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            raw = e.read().decode("utf-8", "replace")
        except Exception as e:
            raise PrimihubError("net", str(e), req.full_url)
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            raise PrimihubError("non-json", raw[:200], req.full_url)

    def get(self, path: str, params: Optional[dict] = None, show: bool = True) -> dict[str, Any]:
        q = dict(params or {})
        q.update(self._envelope())
        url = self._url(path) + ("&" if "?" in path else "?") + urllib.parse.urlencode(q)
        req = urllib.request.Request(url, headers=self._headers(), method="GET")
        return self._open(req)

    def post_form(self, path: str, data: Optional[dict] = None) -> dict[str, Any]:
        body = dict(data or {})
        body.update(self._envelope())
        # doseq=True so list fields (e.g. roleIdList=[1000,1001]) serialise as
        # repeated params, which Spring binds to a List<> @RequestParam.
        payload = urllib.parse.urlencode(body, doseq=True).encode()
        h = self._headers()
        h["Content-Type"] = "application/x-www-form-urlencoded"
        req = urllib.request.Request(self._url(path), data=payload, headers=h, method="POST")
        return self._open(req)

    def post_json(self, path: str, data: Optional[dict] = None) -> dict[str, Any]:
        # For @RequestBody endpoints the business object IS the body; the
        # timestamp/nonce/token envelope rides in the query string (same as GET),
        # not merged into the JSON object.
        url = self._url(path)
        url += ("&" if "?" in url else "?") + urllib.parse.urlencode(self._envelope())
        payload = json.dumps(data or {}).encode()
        h = self._headers()
        h["Content-Type"] = "application/json;charset=UTF-8"
        req = urllib.request.Request(url, data=payload, headers=h, method="POST")
        return self._open(req)

    # -- auth ---------------------------------------------------------------
    def get_public_key(self) -> tuple[str, str]:
        res = self.get("/sys/common/getValidatePublicKey", show=False)
        r = res.get("result") or {}
        return r.get("publicKey", ""), r.get("publicKeyName", "")

    def login(self, use_cache: bool = True, captcha: str = "") -> str:
        if use_cache and self._load_cached_token():
            # validate the cached token with a cheap authed call
            if self._token_valid():
                return self.token
        # Primary: plaintext /user/login. This is the canonical login endpoint
        # documented by primihub-deploy and is robust against RSA public-key
        # drift on /sys/user/login (which can reject an otherwise-correct
        # password when the served publicKey no longer matches the backend key).
        # Attempted at most once (no captcha loop) so it can't trip the
        # 5-strike account lockout.
        if not captcha:
            try:
                res = self.post_form("/user/login", {
                    "userAccount": self.user,
                    "userPassword": self.password,
                })
                if res.get("code") == 0 and (res.get("result") or {}).get("token"):
                    return self._store_login(res["result"])
            except PrimihubError:
                pass  # fall through to the RSA path below
        public_key, key_name = self.get_public_key()
        if not public_key:
            raise PrimihubError("no-pubkey", "getValidatePublicKey returned empty publicKey")
        enc_pw = rsa_encrypt(self.password, public_key)
        form = {
            "userAccount": self.user,
            "userPassword": enc_pw,
            "validateKeyName": key_name,
            "captchaVerification": captcha,
        }
        res = self.post_form("/sys/user/login", form)
        code = res.get("code")
        if code == 0:
            return self._store_login(res["result"])
        # captcha required after repeated attempts
        if code in (121, 109) and not captcha:
            cv = self.solve_captcha()
            if cv:
                return self.login(use_cache=False, captcha=cv)
        raise PrimihubError(code, res.get("msg", "login failed"), "/sys/user/login")

    def _store_login(self, result: dict[str, Any]) -> str:
        self.token = result.get("token", "")
        self.sys_user = result.get("sysUser", {}) or {}
        self.user_id = self.sys_user.get("userId") or self.sys_user.get("id")
        self._save_cached_token()
        return self.token

    def _token_valid(self) -> bool:
        try:
            res = self.get("/sys/user/getUserInfo", show=False)
            return res.get("code") == 0
        except PrimihubError:
            return False

    # -- captcha (AJ-Captcha slide block) fallback --------------------------
    def solve_captcha(self) -> str:
        """Best-effort AJ-Captcha slide solve. Returns captchaVerification or ''.

        Requires Pillow + numpy for gap detection and pycryptodome for the AES
        step. Clean first-logins normally skip captcha entirely, so this is only
        exercised after repeated failures; if deps are missing we return '' and
        let the caller surface a clear error.
        """
        try:
            from .captcha import solve_slide  # lazy import, optional deps
        except Exception:
            try:
                from captcha import solve_slide  # type: ignore
            except Exception:
                return ""
        try:
            return solve_slide(self)
        except Exception:
            return ""

    # -- token cache --------------------------------------------------------
    def _cache_key(self) -> str:
        return f"{self.web_url}|{self.user}"

    def _load_cached_token(self) -> bool:
        try:
            data = json.loads(TOKEN_CACHE.read_text())
        except Exception:
            return False
        entry = data.get(self._cache_key())
        if not entry:
            return False
        self.token = entry.get("token", "")
        self.user_id = entry.get("userId")
        self.sys_user = entry.get("sysUser", {})
        return bool(self.token)

    def _save_cached_token(self) -> None:
        try:
            TOKEN_CACHE.parent.mkdir(parents=True, exist_ok=True)
            data = {}
            if TOKEN_CACHE.exists():
                data = json.loads(TOKEN_CACHE.read_text())
            data[self._cache_key()] = {
                "token": self.token,
                "userId": self.user_id,
                "sysUser": self.sys_user,
                "ts": int(time.time()),
            }
            TOKEN_CACHE.write_text(json.dumps(data, ensure_ascii=False, indent=2))
        except Exception:
            pass

    # -- generic + typed helpers -------------------------------------------
    def call(self, path: str, method: str = "get", data: Optional[dict] = None,
             json_body: bool = False) -> dict[str, Any]:
        """Invoke an arbitrary authed endpoint. Auto-logs-in if no token."""
        if not self.token:
            self.login()
        method = method.lower()
        if method == "get":
            return self.get(path, data)
        if json_body:
            return self.post_json(path, data)
        return self.post_form(path, data)

    # Whitelist (module 02) — flagship
    def whitelist_list(self, page_num: int = 1, page_size: int = 10, **kw) -> dict[str, Any]:
        params = {"pageNum": page_num, "pageSize": page_size}
        params.update(kw)
        return self.call("/whitelist/findWhitelistPage", "get", params)

    def whitelist_add(self, type_: str, value: str, description: str = "",
                      status: int = 1) -> dict[str, Any]:
        return self.call("/whitelist/addWhitelist", "post", {
            "type": type_, "value": value, "description": description, "status": status,
        }, json_body=True)

    def whitelist_update(self, wid: Any, type_: str, value: str,
                         description: str = "", status: int = 1) -> dict[str, Any]:
        # updateWhitelist, like addWhitelist, is @RequestBody JSON; carries the id.
        return self.call("/whitelist/updateWhitelist", "post", {
            "id": wid, "type": type_, "value": value,
            "description": description, "status": status,
        }, json_body=True)

    def whitelist_delete(self, wid: Any) -> dict[str, Any]:
        # deleteWhitelist reads `id` as a @RequestParam (form), NOT @RequestBody JSON.
        return self.call("/whitelist/deleteWhitelist", "post", {"id": wid})

    def whitelist_find_value(self, value: str) -> Optional[dict[str, Any]]:
        res = self.whitelist_list(page_num=1, page_size=100, keyword=value)
        rows = ((res.get("result") or {}).get("list")) or []
        for row in rows:
            if str(row.get("value")) == str(value):
                return row
        return None


def ok(res: dict[str, Any]) -> bool:
    return res.get("code") == 0


if __name__ == "__main__":
    # smoke: python3 client.py  -> logs in and prints token + org
    c = PrimihubClient()
    tok = c.login(use_cache=False)
    print(json.dumps({
        "web_url": c.web_url, "token": (tok[:16] + "…") if tok else "",
        "userId": c.user_id, "userAccount": c.sys_user.get("userAccount"),
        "organ": c.sys_user.get("organIdListDesc") or c.sys_user.get("userName"),
    }, ensure_ascii=False, indent=2))
