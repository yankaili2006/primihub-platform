package com.primihub.biz.entity.sys.po;

import lombok.Data;

import java.io.Serializable;
import java.util.Date;

/**
 * 节点取消合作历史记录实体类
 * 每次取消合作(单个/批量)写入一条快照,支撑「取消合作记录」查询/导出。
 */
@Data
public class NodeCooperationCancelRecord implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 主键ID */
    private Long id;

    /** 原合作方记录ID */
    private Long cooperationId;

    /** 合作方节点ID */
    private String organId;

    /** 合作方节点名称 */
    private String organName;

    /** 合作方网关地址 */
    private String organGateway;

    /** 原合作类型 */
    private String cooperationType;

    /** 原合作开始时间 */
    private Date startDate;

    /** 原合作结束时间 */
    private Date endDate;

    /** 取消原因 */
    private String cancelReason;

    /** 合作时长(如 "45天") */
    private String cooperationDuration;

    /** 操作人ID */
    private Long cancelUserId;

    /** 操作人 */
    private String cancelUserName;

    /** 取消时间 */
    private Date cancelDate;

    /** 是否删除 */
    private Integer isDel;
}
