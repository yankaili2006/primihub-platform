package com.primihub.biz.entity.sys.po;

import lombok.Data;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Date;

/**
 * 合作方管理实体类
 * 管理我方主动合作的节点(outbound)
 */
@Data
public class NodeCooperationParty implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键ID
     */
    private Long id;

    /**
     * 合作方节点ID
     */
    private String organId;

    /**
     * 合作方节点名称
     */
    private String organName;

    /**
     * 合作方网关地址
     */
    private String organGateway;

    /**
     * 合作类型: project(项目合作), resource_sharing(资源共享), compute(算力), data_exchange(数据交换)
     */
    private String cooperationType;

    /**
     * 合作开始时间
     */
    private Date startDate;

    /**
     * 合作结束时间
     */
    private Date endDate;

    /**
     * 合作协议文件路径
     */
    private String agreementFilePath;

    /**
     * SLA在线率目标(%)
     */
    private BigDecimal slaUptimeTarget;

    /**
     * SLA响应时间(毫秒)
     */
    private Integer slaResponseTime;

    /**
     * 健康评分(0-100)
     */
    private Integer healthScore;

    /**
     * 已发送数据量
     */
    private Long dataSentCount;

    /**
     * 已接收数据量
     */
    private Long dataReceivedCount;

    /**
     * 最后活动时间
     */
    private Date lastActivityTime;

    /**
     * 合作状态: 0=待确认, 1=进行中, 2=已过期, 3=已终止
     */
    private Integer cooperationStatus;

    /**
     * 是否我方发起: 0=否, 1=是
     */
    private Integer initiatedByUs;

    /**
     * 创建人ID
     */
    private Long createdBy;

    /**
     * 创建人姓名
     */
    private String createdByName;

    /**
     * 删除标记(0-未删除 1-已删除)
     */
    private Integer isDel;

    /**
     * 创建时间
     */
    private Date createDate;

    /**
     * 更新时间
     */
    private Date updateDate;
}
