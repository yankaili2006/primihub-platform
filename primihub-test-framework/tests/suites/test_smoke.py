import pytest
import time
import logging

logger = logging.getLogger(__name__)

pytestmark = pytest.mark.smoke


class TestHealthCheck:
    def test_health_endpoint(self, api_client):
        resp = api_client.health_check()
        assert resp.get("code") == 0

    def test_server_reachable(self, api_client):
        s = time.time()
        resp = api_client._make_request("GET", "/test/healthConnection")
        elapsed = time.time() - s
        assert resp.get("code") == 0
        assert elapsed < 5, f"Health check too slow: {elapsed:.2f}s"


class TestLogin:
    def test_login_success(self, api_client, admin_credentials):
        resp = api_client.login(admin_credentials["username"], admin_credentials["password"])
        assert resp.get("code") == 0
        assert resp.get("result", {}).get("token") is not None
        assert resp.get("result", {}).get("userId") is not None

    def test_login_failure(self, api_client):
        resp = api_client.login("nonexistent", "wrong_password")
        assert resp.get("code") != 0

    def test_login_returns_permissions(self, api_client, admin_credentials):
        resp = api_client.login(admin_credentials["username"], admin_credentials["password"])
        result = resp.get("result", {})
        grant_list = result.get("grantAuthRootList", [])
        assert len(grant_list) > 0, "No permissions returned"
        assert any(a.get("authType") == 1 for a in grant_list)

    def test_logout(self, api_client, admin_credentials):
        api_client.login(admin_credentials["username"], admin_credentials["password"])
        assert api_client.token is not None
        resp = api_client.logout()
        assert resp.get("code") == 0
        assert api_client.token is None


class TestUserManagement:
    def test_get_user_list(self, authed_client):
        resp = authed_client.get_user_list(page=1, page_size=10)
        assert resp.get("code") == 0
        result = resp.get("result", {})
        assert "list" in result or isinstance(result, list)

    def test_get_admin_user(self, authed_client):
        resp = authed_client.get_user_by_account("admin")
        assert resp.get("code") == 0
        user = resp.get("result", {})
        assert user.get("userAccount") == "admin"
        assert user.get("userId") is not None

    def test_create_and_delete_user(self, authed_client):
        ts = int(time.time())
        user_data = {
            "userAccount": f"testuser_{ts}",
            "userName": f"测试用户_{ts}",
            "userPassword": "Test@123456",
            "userPhone": f"138{ts % 10000000000:010d}"[:11],
            "userEmail": f"test_{ts}@example.com",
        }
        resp = authed_client.create_user(user_data)
        assert resp.get("code") == 0, f"Create user failed: {resp}"
        user_id = resp.get("result", {}).get("userId")
        if user_id:
            del_resp = authed_client.delete_user([user_id])
            assert del_resp.get("code") == 0

    def test_freeze_and_unfreeze_user(self, authed_client, user_id):
        freeze_resp = authed_client.freeze_user(user_id)
        assert freeze_resp.get("code") == 0
        unfreeze_resp = authed_client.unfreeze_user(user_id)
        assert unfreeze_resp.get("code") == 0


class TestOrganManagement:
    def test_get_organ_list(self, authed_client):
        resp = authed_client.get_organ_list()
        assert resp.get("code") == 0
        organs = resp.get("result", [])
        assert isinstance(organs, list)
        if organs:
            org = organs[0]
            assert org.get("organId") is not None
            assert org.get("organName") is not None


class TestResourceManagement:
    def test_get_resource_list(self, authed_client):
        resp = authed_client.get_resource_list(page=1, page_size=10)
        assert resp.get("code") == 0
        result = resp.get("result", {})
        if isinstance(result, dict):
            assert "list" in result
        elif isinstance(result, list):
            pass

    def test_api_response_format(self, authed_client):
        resp = authed_client.get_resource_list(page=1, page_size=10)
        assert "code" in resp
        assert "msg" in resp
        assert resp["code"] == 0


class TestSystemApis:
    def test_swagger_api_docs(self, api_client):
        resp = api_client._make_request("GET", "/v2/api-docs")
        assert resp.get("code") == 0 or "swagger" in str(resp).lower()

    def test_get_homepage(self, authed_client):
        resp = authed_client._make_request("GET", "/sys/organ/getHomepage")
        assert resp.get("code") == 0

    def test_get_auth_list(self, authed_client):
        resp = authed_client._make_request("GET", "/sys/oauth/getAuthList")
        assert resp.get("code") == 0
        result = resp.get("result", [])
        assert isinstance(result, list)
