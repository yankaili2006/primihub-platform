package com.primihub.biz.constant;

public class SysConstant {
    public static final String SYS_USER_TOKEN_PREFIX = "SU";
    public static final String SYS_COMMON_PUBLIC_KEY_PREFIX = "RK";
    public static final String SYS_COMMON_AUTH_PUBLIC_KEY_PREFIX = "AK";
    public static final String SYS_ORGAN_INFO_NAME = "organ_info.json";
    public static final String SYS_COMPONENTS_INFO_NAME = "components.json";
    public static final String SYS_ORGAN_MARKET_INFO_NAME = "market_info.json";
    public static final String SYS_LOCAL_ORGAN_INFO_LOCK = "sys_local_organ_info_lock";
    public static final Long SYS_USER_PASS_ERRER_NUM = 6L;
    public static final Long SYS_USER_LOGIN_LIMIT_NUM = 12L;
    // 中性化 2026-09-14: 私有部署禁用向厂商 node1.primihub.com 上报组织元数据/公钥/地理坐标。
    // 翻回 true 即恢复出网上报。URL 同时黑洞化，防未来漏网调用回退到厂商域名。
    public static final boolean SYS_COLLECT_ENABLED = false;
    public static final String SYS_COLLECT_BASE_URL = "http://127.0.0.1:9/collect";
    public static final String SYS_COLLECT_URL = SYS_COLLECT_BASE_URL + "/operate/addNode";
    public static final String SYS_COLLECT_KEY = "FkBPowl3QSZi9LukvMId88aoWud0ZVgA";
    public static final String SYS_QUERY_COLLECT_URL = SYS_COLLECT_BASE_URL + "/operate/getNodeList?key=Qg7T3TgGBtYIF2XJOViTgWSuohNnkakU";
}
