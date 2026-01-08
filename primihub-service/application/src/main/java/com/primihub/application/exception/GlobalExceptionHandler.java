package com.primihub.application.exception;

import com.primihub.biz.entity.base.BaseResultEntity;
import com.primihub.biz.entity.base.BaseResultEnum;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * 全局异常处理器
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * 处理缺少请求头异常（如userId）
     * 当用户未登录或token失效时，某些接口会因为缺少userId请求头而返回400错误
     * 这里统一处理，返回友好的错误信息
     */
    @ExceptionHandler(MissingRequestHeaderException.class)
    public BaseResultEntity handleMissingRequestHeaderException(MissingRequestHeaderException e) {
        String headerName = e.getHeaderName();
        log.warn("缺少请求头: {}, 参数类型: {}", headerName, e.getParameter().getParameterType());

        // 如果缺少的是userId请求头，说明用户未登录或token失效
        if ("userId".equals(headerName)) {
            return new BaseResultEntity(BaseResultEnum.TOKEN_INVALIDATION, "请先登录");
        }

        // 其他请求头缺失
        return new BaseResultEntity(BaseResultEnum.LACK_OF_PARAM, "缺少必需的请求头: " + headerName);
    }

    /**
     * 处理其他未捕获的异常
     */
    @ExceptionHandler(Exception.class)
    public BaseResultEntity handleException(Exception e) {
        log.error("系统异常: ", e);
        return new BaseResultEntity(BaseResultEnum.FAILURE, "系统异常: " + e.getMessage());
    }
}
