package com.primihub.biz.filter;

import com.alibaba.fastjson.JSON;
import com.primihub.biz.config.base.BaseConfiguration;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import com.primihub.biz.entity.sys.vo.SysUserListVO;
import com.primihub.biz.repository.primaryredis.sys.SysUserPrimaryRedisRepository;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.AntPathMatcher;

import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletRequestWrapper;
import java.io.IOException;
import java.util.*;

@Slf4j
@Component
@WebFilter(filterName = "standaloneAuthFilter", urlPatterns = {"/*"})
public class StandaloneAuthFilter implements Filter {

    @Autowired
    private SysUserPrimaryRedisRepository sysUserPrimaryRedisRepository;

    @Autowired
    private BaseConfiguration baseConfiguration;

    private static final AntPathMatcher MATCHER = new AntPathMatcher();

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        String requestPath = httpRequest.getRequestURI();

        log.debug("StandaloneAuthFilter processing request: {}", requestPath);

        // Check if path is in blacklist (no auth required)
        if (isPathInBlacklist(requestPath)) {
            log.debug("Path {} is in blacklist, skipping auth", requestPath);
            chain.doFilter(request, response);
            return;
        }

        // Get token from request
        String token = getToken(httpRequest);

        if (StringUtils.isBlank(token)) {
            log.warn("No token found for path: {}", requestPath);
            chain.doFilter(request, response);
            return;
        }

        // Validate token and get user info
        try {
            SysUserListVO sysUserListVO = sysUserPrimaryRedisRepository.findUserLoginStatus(token);

            if (sysUserListVO == null) {
                log.warn("Token validation failed for path: {}, token: {}", requestPath, token);
                writeErrorResponse(response, BaseResultEnum.TOKEN_INVALIDATION);
                return;
            }

            // Extend token expiration
            sysUserPrimaryRedisRepository.expireUserLoginStatus(token, sysUserListVO.getUserId());

            // Add userId header to request
            HttpServletRequestWrapper wrapper = new HttpServletRequestWrapper(httpRequest) {
                @Override
                public String getHeader(String name) {
                    if ("userId".equals(name)) {
                        return sysUserListVO.getUserId().toString();
                    }
                    return super.getHeader(name);
                }

                @Override
                public Enumeration<String> getHeaderNames() {
                    Set<String> headerNames = new HashSet<>();
                    Enumeration<String> originalHeaders = super.getHeaderNames();
                    while (originalHeaders.hasMoreElements()) {
                        headerNames.add(originalHeaders.nextElement());
                    }
                    headerNames.add("userId");
                    return Collections.enumeration(headerNames);
                }
            };

            log.debug("Token validated successfully for user: {}", sysUserListVO.getUserId());
            chain.doFilter(wrapper, response);

        } catch (Exception e) {
            log.error("Error validating token for path: {}", requestPath, e);
            chain.doFilter(request, response);
        }
    }

    private String getToken(HttpServletRequest request) {
        // Try to get token from header
        String token = request.getHeader("token");
        if (StringUtils.isNotBlank(token)) {
            return token;
        }

        // Try to get token from parameter
        token = request.getParameter("token");
        return token;
    }

    private boolean isPathInBlacklist(String path) {
        if (baseConfiguration.getTokenValidateUriBlackList() == null) {
            return false;
        }

        for (String pattern : baseConfiguration.getTokenValidateUriBlackList()) {
            if (pattern.contains("*")) {
                if (MATCHER.match(pattern, path)) {
                    return true;
                }
            } else {
                if (pattern.equals(path)) {
                    return true;
                }
            }
        }
        return false;
    }

    private void writeErrorResponse(ServletResponse response, BaseResultEnum resultEnum) throws IOException {
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(JSON.toJSONString(BaseResultEntity.failure(resultEnum)));
    }
}
