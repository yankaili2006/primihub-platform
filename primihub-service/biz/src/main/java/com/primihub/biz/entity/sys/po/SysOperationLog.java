package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.util.Date;

/**
 * 系统操作日志实体类
 */
@Data
public class SysOperationLog {

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
     * 操作模块（如：用户管理、项目管理）
     */
    private String operationModule;

    /**
     * 操作描述
     */
    private String operationDesc;

    /**
     * 请求方法：POST/PUT/DELETE
     */
    private String requestMethod;

    /**
     * 请求URL
     */
    private String requestUrl;

    /**
     * 请求参数（JSON格式）
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
     * 是否删除：0=否，1=是
     */
    private Integer isDel;

    /**
     * 创建时间
     */
    private Date createdTime;

    /**
     * 更新时间
     */
    private Date updatedTime;
}
