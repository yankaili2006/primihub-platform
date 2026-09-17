package com.primihub.biz.filter;

import com.primihub.biz.entity.sys.po.WhitelistAccessLog;
import com.primihub.biz.entity.sys.po.WhitelistConfig;
import com.primihub.biz.repository.primarydb.sys.WhitelistPrimarydbRepository;
import com.primihub.biz.service.sys.WhitelistService;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Date;

/**
 * 白名单访问日志过滤器：把每个 HTTP 请求写入 whitelist_access_log。
 *
 * 只记录、不拦截 —— 放行逻辑（enableWhitelist/defaultPolicy）不在此处，
 * 本过滤器永远调用 chain.doFilter，且自身任何异常都不影响业务请求。
 *
 * 开关：whitelist_config 的 enableAccessLog 显式为 "true" 才记录（60s 缓存）；
 * 配置行缺失/读库失败一律视为关闭，保证存量部署（表可能不存在）零行为变化。
 */
@Slf4j
@Component
@WebFilter(filterName = "whitelistAccessLogFilter", urlPatterns = {"/*"})
public class WhitelistAccessLogFilter implements Filter {

    private static final String CONFIG_KEY_ENABLE = "enableAccessLog";
    private static final long CONFIG_CACHE_MS = 60_000L;

    @Autowired
    private WhitelistService whitelistService;

    @Autowired
    private WhitelistPrimarydbRepository whitelistPrimarydbRepository;

    private volatile boolean cachedEnabled = false;
    private volatile long cachedAt = 0L;

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        if (!(request instanceof HttpServletRequest) || !isAccessLogEnabled()) {
            chain.doFilter(request, response);
            return;
        }
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        // 容器 healthcheck 每 ~10s 打一轮 /healthConnection，纯噪音不入日志
        String uri = httpRequest.getRequestURI();
        if (uri != null && uri.endsWith("/healthConnection")) {
            chain.doFilter(request, response);
            return;
        }
        long start = System.currentTimeMillis();
        Exception failure = null;
        try {
            chain.doFilter(request, response);
        } catch (IOException | ServletException | RuntimeException e) {
            failure = e;
            throw e;
        } finally {
            record(httpRequest, response, failure, System.currentTimeMillis() - start);
        }
    }

    private void record(HttpServletRequest request, ServletResponse response,
                        Exception failure, long costMs) {
        try {
            int status = response instanceof HttpServletResponse
                    ? ((HttpServletResponse) response).getStatus() : 0;
            WhitelistAccessLog entry = new WhitelistAccessLog();
            entry.setAccessIp(resolveClientIp(request));
            entry.setAccessUrl(truncate(request.getRequestURI(), 500));
            entry.setRequestMethod(truncate(request.getMethod(), 10));
            entry.setUserId(parseUserId(request.getHeader("userId")));
            entry.setUserAgent(truncate(request.getHeader("User-Agent"), 500));
            entry.setRequestParams(truncate(request.getQueryString(), 2000));
            entry.setResponseCode(status);
            entry.setResponseTime(costMs);
            entry.setAccessTime(new Date());
            if (failure != null) {
                entry.setAccessResult("ERROR");
                entry.setFailReason(truncate(failure.getClass().getSimpleName()
                        + ": " + failure.getMessage(), 500));
            } else if (status >= 400) {
                entry.setAccessResult("ERROR");
                entry.setFailReason("HTTP " + status);
            } else {
                entry.setAccessResult("SUCCESS");
            }
            whitelistService.recordAccessLog(entry);
        } catch (Exception e) {
            log.debug("写访问日志失败(不影响业务)", e);
        }
    }

    private boolean isAccessLogEnabled() {
        long now = System.currentTimeMillis();
        if (now - cachedAt < CONFIG_CACHE_MS) {
            return cachedEnabled;
        }
        boolean enabled = false;
        try {
            WhitelistConfig config =
                    whitelistPrimarydbRepository.selectWhitelistConfigByKey(CONFIG_KEY_ENABLE);
            enabled = config != null && "true".equalsIgnoreCase(config.getConfigValue());
        } catch (Exception e) {
            // 表不存在/库不可达 → 视为关闭；缓存结果避免每请求都打一次失败查询
            log.debug("读取 {} 配置失败，访问日志保持关闭", CONFIG_KEY_ENABLE, e);
        }
        cachedEnabled = enabled;
        cachedAt = now;
        return enabled;
    }

    private String resolveClientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (StringUtils.isNotBlank(forwarded) && !"unknown".equalsIgnoreCase(forwarded)) {
            return truncate(forwarded.split(",")[0].trim(), 64);
        }
        String realIp = request.getHeader("X-Real-IP");
        if (StringUtils.isNotBlank(realIp) && !"unknown".equalsIgnoreCase(realIp)) {
            return truncate(realIp.trim(), 64);
        }
        return truncate(request.getRemoteAddr(), 64);
    }

    private Long parseUserId(String header) {
        if (StringUtils.isBlank(header)) {
            return null;
        }
        try {
            return Long.valueOf(header.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private String truncate(String value, int max) {
        if (value == null) {
            return null;
        }
        return value.length() <= max ? value : value.substring(0, max);
    }
}
