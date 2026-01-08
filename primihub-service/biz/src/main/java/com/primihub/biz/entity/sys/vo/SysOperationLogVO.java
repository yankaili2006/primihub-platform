package com.primihub.biz.entity.sys.vo;

import lombok.Data;
import java.util.Date;

/**
 * 操作日志视图对象
 */
@Data
public class SysOperationLogVO {

    /**
     * 日志ID
     */
    private Long logId;

    /**
     * 操作用户ID
     */
    private Long userId;

    /**
     * 操作用户名
     */
    private String userName;

    /**
     * 操作类型：1=新增，2=修改，3=删除，4=登录，5=登出
     */
    private Integer operationType;

    /**
     * 操作类型描述：新增/修改/删除/登录/登出
     */
    private String operationTypeDesc;

    /**
     * 操作模块
     */
    private String operationModule;

    /**
     * 操作描述
     */
    private String operationDesc;

    /**
     * 请求方法
     */
    private String requestMethod;

    /**
     * 请求URL
     */
    private String requestUrl;

    /**
     * 请求参数（JSON格式）- 详情查看时使用
     */
    private String requestParams;

    /**
     * 响应状态码
     */
    private String responseCode;

    /**
     * 响应消息
     */
    private String responseMsg;

    /**
     * 操作耗时（毫秒）
     */
    private Long operationTime;

    /**
     * IP地址
     */
    private String ipAddress;

    /**
     * 用户代理
     */
    private String userAgent;

    /**
     * 异常信息
     */
    private String exceptionMsg;

    /**
     * 是否成功：0=失败，1=成功
     */
    private Integer isSuccess;

    /**
     * 成功状态描述：成功/失败
     */
    private String isSuccessDesc;

    /**
     * 创建时间
     */
    private Date createdTime;
}
