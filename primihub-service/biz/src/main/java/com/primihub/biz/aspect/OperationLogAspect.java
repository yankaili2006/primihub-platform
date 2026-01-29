package com.primihub.biz.aspect;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.sys.po.SysOperationLog;
import com.primihub.biz.service.sys.SysOperationLogService;
import lombok.extern.slf4j.Slf4j;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;
import java.lang.reflect.Method;
import java.util.Date;

/**
 * 操作日志切面
 * 自动拦截Controller的增删改操作并记录日志
 */
@Aspect
@Component
@Slf4j
public class OperationLogAspect {

    @Autowired
    private SysOperationLogService operationLogService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * 拦截所有Controller的POST/PUT/DELETE方法
     */
    @Around("execution(* com.primihub.application.controller..*.*(..)) && " +
            "(@annotation(org.springframework.web.bind.annotation.PostMapping) || " +
            "@annotation(org.springframework.web.bind.annotation.PutMapping) || " +
            "@annotation(org.springframework.web.bind.annotation.DeleteMapping))")
    public Object around(ProceedingJoinPoint joinPoint) throws Throwable {
        long startTime = System.currentTimeMillis();

        // 获取请求信息
        ServletRequestAttributes attributes =
            (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes == null) {
            return joinPoint.proceed();
        }

        HttpServletRequest request = attributes.getRequest();

        // 构建日志对象
        SysOperationLog operationLog = new SysOperationLog();
        operationLog.setUserId(getUserId(request));
        operationLog.setUserName(getUserName(request));
        operationLog.setRequestMethod(request.getMethod());
        operationLog.setRequestUrl(request.getRequestURI());
        operationLog.setIpAddress(getIpAddress(request));
        operationLog.setUserAgent(request.getHeader("User-Agent"));
        operationLog.setCreatedTime(new Date());

        // 获取方法参数（JSON格式）
        try {
            Object[] args = joinPoint.getArgs();
            if (args != null && args.length > 0) {
                // 过滤掉HttpServletRequest/HttpServletResponse等不需要序列化的参数
                StringBuilder paramsBuilder = new StringBuilder();
                for (Object arg : args) {
                    if (arg != null &&
                        !(arg instanceof HttpServletRequest) &&
                        !(arg instanceof javax.servlet.http.HttpServletResponse) &&
                        !(arg instanceof org.springframework.web.multipart.MultipartFile)) {
                        try {
                            String json = objectMapper.writeValueAsString(arg);
                            if (paramsBuilder.length() > 0) {
                                paramsBuilder.append(", ");
                            }
                            paramsBuilder.append(json);
                        } catch (Exception e) {
                            paramsBuilder.append(arg.toString());
                        }
                    }
                }
                operationLog.setRequestParams(paramsBuilder.toString());
            }
        } catch (Exception e) {
            log.warn("解析请求参数失败", e);
        }

        // 推断操作类型和模块
        operationLog.setOperationType(inferOperationType(request.getMethod()));
        operationLog.setOperationModule(inferOperationModule(request.getRequestURI()));
        operationLog.setOperationDesc(inferOperationDesc(joinPoint));

        Object result = null;
        try {
            // 执行目标方法
            result = joinPoint.proceed();

            // 记录成功信息
            operationLog.setIsSuccess(1);
            if (result instanceof BaseResultEntity) {
                BaseResultEntity baseResult = (BaseResultEntity) result;
                operationLog.setResponseCode(String.valueOf(baseResult.getCode()));
                operationLog.setResponseMsg(baseResult.getMsg());
            }

        } catch (Exception e) {
            // 记录异常信息
            operationLog.setIsSuccess(0);
            operationLog.setExceptionMsg(e.getMessage());
            operationLog.setResponseCode("500");
            operationLog.setResponseMsg("系统异常");
            throw e;
        } finally {
            // 计算耗时并异步保存日志
            operationLog.setOperationTime(System.currentTimeMillis() - startTime);
            operationLog.setUpdatedTime(new Date());

            // 异步记录日志（不影响主业务）
            operationLogService.recordOperationLog(operationLog);
        }

        return result;
    }

    /**
     * 从请求头获取用户ID
     */
    private Long getUserId(HttpServletRequest request) {
        String userIdStr = request.getHeader("userId");
        if (userIdStr != null && !userIdStr.isEmpty()) {
            try {
                return Long.parseLong(userIdStr);
            } catch (NumberFormatException e) {
                return null;
            }
        }
        return null;
    }

    /**
     * 从请求头获取用户名
     */
    private String getUserName(HttpServletRequest request) {
        String userName = request.getHeader("userName");
        return userName != null && !userName.isEmpty() ? userName : "未知用户";
    }

    /**
     * 获取真实IP地址
     */
    private String getIpAddress(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("Proxy-Client-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("WL-Proxy-Client-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("HTTP_CLIENT_IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("HTTP_X_FORWARDED_FOR");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }
        // 对于多个代理的情况，第一个IP为客户端真实IP
        if (ip != null && ip.contains(",")) {
            ip = ip.substring(0, ip.indexOf(",")).trim();
        }
        return ip;
    }

    /**
     * 根据请求方法推断操作类型
     */
    private Integer inferOperationType(String method) {
        if ("POST".equalsIgnoreCase(method)) {
            return 1; // 新增
        } else if ("PUT".equalsIgnoreCase(method)) {
            return 2; // 修改
        } else if ("DELETE".equalsIgnoreCase(method)) {
            return 3; // 删除
        }
        return null;
    }

    /**
     * 根据请求URI推断操作模块
     */
    private String inferOperationModule(String uri) {
        if (uri == null || uri.isEmpty()) {
            return "未知模块";
        }

        // 提取模块名称（通常在第二段路径中）
        String[] parts = uri.split("/");
        if (parts.length >= 2) {
            String module = parts[1];
            // 简单映射
            switch (module) {
                case "user":
                case "sys":
                    return "用户管理";
                case "project":
                    return "项目管理";
                case "resource":
                    return "资源管理";
                case "model":
                    return "模型管理";
                case "psi":
                    return "PSI管理";
                case "pir":
                    return "PIR管理";
                case "task":
                    return "任务管理";
                case "data":
                    return "数据管理";
                default:
                    return module;
            }
        }

        return "未知模块";
    }

    /**
     * 根据方法信息推断操作描述
     */
    private String inferOperationDesc(ProceedingJoinPoint joinPoint) {
        try {
            MethodSignature signature = (MethodSignature) joinPoint.getSignature();
            Method method = signature.getMethod();
            String methodName = method.getName();

            // 根据方法名推断操作描述
            if (methodName.contains("save") || methodName.contains("add") || methodName.contains("insert")) {
                return "保存数据";
            } else if (methodName.contains("update") || methodName.contains("edit") || methodName.contains("modify")) {
                return "更新数据";
            } else if (methodName.contains("delete") || methodName.contains("remove")) {
                return "删除数据";
            } else if (methodName.contains("login")) {
                return "用户登录";
            } else if (methodName.contains("logout")) {
                return "用户登出";
            } else {
                return methodName;
            }
        } catch (Exception e) {
            return "未知操作";
        }
    }
}
