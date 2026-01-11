package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

/**
 * 白名单访问日志表
 */
@Data
public class WhitelistAccessLog {
    /**
     * 日志ID
     */
    private Long id;

    /**
     * 白名单ID
     */
    private Long whitelistId;

    /**
     * 访问IP
     */
    private String accessIp;

    /**
     * 访问URL
     */
    private String accessUrl;

    /**
     * 请求方法
     */
    private String requestMethod;

    /**
     * 访问结果：SUCCESS-成功，DENIED-拒绝，ERROR-异常
     */
    private String accessResult;

    /**
     * 失败原因
     */
    private String failReason;

    /**
     * 用户ID
     */
    private Long userId;

    /**
     * User-Agent
     */
    private String userAgent;

    /**
     * 请求参数
     */
    private String requestParams;

    /**
     * 响应码
     */
    private Integer responseCode;

    /**
     * 响应时间(ms)
     */
    private Long responseTime;

    /**
     * 访问时间
     */
    private Date accessTime;
}
